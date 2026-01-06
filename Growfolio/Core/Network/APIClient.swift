//
//  APIClient.swift
//  Growfolio
//
//  Protocol-based async/await API client for network communication.
//

import Foundation

// MARK: - API Client Protocol

/// Protocol defining the API client interface
protocol APIClientProtocol: Sendable {
    /// Execute a request and decode the response
    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T

    /// Execute a request without expecting a response body
    func request(_ endpoint: Endpoint) async throws

    /// Execute a request and return raw data
    func requestData(_ endpoint: Endpoint) async throws -> Data

    /// Upload data with multipart form
    func upload<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        data: Data,
        fileName: String,
        mimeType: String
    ) async throws -> T
}

// MARK: - API Client Implementation

/// Main API client for making network requests
actor APIClient: APIClientProtocol {

    // MARK: - Singleton

    static let shared = APIClient()

    // MARK: - Properties

    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let authInterceptor: AuthInterceptor

    // MARK: - Initialization

    init(
        configuration: URLSessionConfiguration = .default,
        baseURL: URL = AppEnvironment.current.apiBaseURL,
        authInterceptor: AuthInterceptor = AuthInterceptor()
    ) {
        configuration.timeoutIntervalForRequest = Constants.API.requestTimeout
        configuration.timeoutIntervalForResource = Constants.API.uploadTimeout
        configuration.httpMaximumConnectionsPerHost = Constants.API.maxConcurrentRequests
        configuration.waitsForConnectivity = true

        self.session = URLSession(configuration: configuration)
        self.baseURL = baseURL
        self.authInterceptor = authInterceptor

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatters = [
                ISO8601DateFormatter(),
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = Constants.DateFormat.iso8601
                    return formatter
                }(),
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = Constants.DateFormat.dateOnly
                    return formatter
                }()
            ] as [Any]

            for formatter in formatters {
                if let isoFormatter = formatter as? ISO8601DateFormatter,
                   let date = isoFormatter.date(from: dateString) {
                    return date
                }
                if let dateFormatter = formatter as? DateFormatter,
                   let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - APIClientProtocol

    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let data = try await requestData(endpoint)
        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingError(underlyingError: decodingError.localizedDescription)
        }
    }

    func request(_ endpoint: Endpoint) async throws {
        _ = try await requestData(endpoint)
    }

    func requestData(_ endpoint: Endpoint) async throws -> Data {
        let request = try await buildRequest(for: endpoint)
        return try await execute(request: request, endpoint: endpoint)
    }

    func upload<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        data: Data,
        fileName: String,
        mimeType: String
    ) async throws -> T {
        var request = try await buildRequest(for: endpoint)

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let responseData = try await execute(request: request, endpoint: endpoint)
        do {
            return try decoder.decode(T.self, from: responseData)
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingError(underlyingError: decodingError.localizedDescription)
        }
    }

    // MARK: - Private Methods

    private func buildRequest(for endpoint: Endpoint) async throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true) else {
            throw NetworkError.invalidURL
        }

        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout

        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Constants.App.fullVersion, forHTTPHeaderField: "X-App-Version")
        request.setValue("ios", forHTTPHeaderField: "X-Platform")

        // Set custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Set body
        if let body = endpoint.body {
            request.httpBody = body
        }

        // Add authentication if required
        if endpoint.requiresAuthentication {
            request = try await authInterceptor.intercept(request: request)
        }

        return request
    }

    private func execute(request: URLRequest, endpoint: Endpoint, retryCount: Int = 0) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(underlyingError: "Invalid response type")
            }

            try validateResponse(httpResponse, data: data)

            logResponse(httpResponse, data: data, for: request)

            return data
        } catch let urlError as URLError {
            let networkError = NetworkError.from(urlError)

            // Retry if appropriate
            if networkError.isRetryable && retryCount < Constants.API.maxRetryAttempts {
                let delay = Constants.API.retryDelay * Double(retryCount + 1)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await execute(request: request, endpoint: endpoint, retryCount: retryCount + 1)
            }

            throw networkError
        } catch let networkError as NetworkError {
            // Handle token refresh for unauthorized errors
            if networkError == .unauthorized && endpoint.requiresAuthentication && retryCount == 0 {
                do {
                    try await authInterceptor.refreshToken()
                    var refreshedRequest = request
                    refreshedRequest = try await authInterceptor.intercept(request: refreshedRequest)
                    return try await execute(request: refreshedRequest, endpoint: endpoint, retryCount: retryCount + 1)
                } catch {
                    throw networkError
                }
            }
            throw networkError
        }
    }

    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
                .flatMap { TimeInterval($0) }
            throw NetworkError.rateLimited(retryAfter: retryAfter)
        case 400...499:
            let message = extractErrorMessage(from: data)
            throw NetworkError.clientError(statusCode: response.statusCode, message: message)
        case 500...599:
            let message = extractErrorMessage(from: data)
            throw NetworkError.serverError(statusCode: response.statusCode, message: message)
        default:
            throw NetworkError.unknown(underlyingError: "Unexpected status code: \(response.statusCode)")
        }
    }

    private func extractErrorMessage(from data: Data) -> String? {
        if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
            return errorResponse.error.message
        }
        return String(data: data, encoding: .utf8)
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data, for request: URLRequest) {
        #if DEBUG
        if AppEnvironment.current.isLoggingEnabled {
            print("[\(request.httpMethod ?? "?")] \(request.url?.absoluteString ?? "unknown")")
            print("Status: \(response.statusCode)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response: \(jsonString.prefix(500))")
            }
        }
        #endif
    }
}

// MARK: - Paginated Response

/// Generic wrapper for paginated API responses
struct PaginatedResponse<T: Codable & Sendable>: Codable, Sendable {
    let data: [T]
    let pagination: Pagination

    struct Pagination: Codable, Sendable {
        let page: Int
        let limit: Int
        let totalPages: Int
        let totalItems: Int

        var hasNextPage: Bool {
            page < totalPages
        }

        var hasPreviousPage: Bool {
            page > 1
        }
    }
}

// MARK: - API Response

/// Generic wrapper for single-item API responses
struct APIResponse<T: Codable & Sendable>: Codable, Sendable {
    let data: T
    let meta: [String: String]?
}
