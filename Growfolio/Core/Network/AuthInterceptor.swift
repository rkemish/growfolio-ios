//
//  AuthInterceptor.swift
//  Growfolio
//
//  Authentication interceptor for injecting tokens into API requests.
//

import Foundation

// MARK: - Auth Interceptor Protocol

/// Protocol for request interceptors
protocol RequestInterceptor: Sendable {
    /// Intercept and modify a request before it's sent
    func intercept(request: URLRequest) async throws -> URLRequest
}

// MARK: - Auth Interceptor

/// Interceptor that adds authentication tokens to requests
actor AuthInterceptor: RequestInterceptor {

    // MARK: - Properties

    private let tokenManager: TokenManager
    private var isRefreshing = false
    private var pendingRequests: [CheckedContinuation<String, Error>] = []

    // MARK: - Initialization

    init(tokenManager: TokenManager = TokenManager.shared) {
        self.tokenManager = tokenManager
    }

    // MARK: - RequestInterceptor

    func intercept(request: URLRequest) async throws -> URLRequest {
        let token = try await getValidToken()

        var modifiedRequest = request
        modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return modifiedRequest
    }

    // MARK: - Token Management

    /// Get a valid access token, refreshing if necessary
    private func getValidToken() async throws -> String {
        // Check if we have a valid token
        if let token = await tokenManager.accessToken,
           await !tokenManager.isTokenExpired {
            return token
        }

        // Token needs refresh
        return try await refreshTokenIfNeeded()
    }

    /// Refresh the token, handling concurrent refresh requests
    private func refreshTokenIfNeeded() async throws -> String {
        // If already refreshing, wait for the result
        if isRefreshing {
            return try await withCheckedThrowingContinuation { continuation in
                pendingRequests.append(continuation)
            }
        }

        isRefreshing = true

        do {
            let newToken = try await performTokenRefresh()
            isRefreshing = false

            // Resume all pending requests with the new token
            for continuation in pendingRequests {
                continuation.resume(returning: newToken)
            }
            pendingRequests.removeAll()

            return newToken
        } catch {
            isRefreshing = false

            // Resume all pending requests with the error
            for continuation in pendingRequests {
                continuation.resume(throwing: error)
            }
            pendingRequests.removeAll()

            throw error
        }
    }

    /// Perform the actual token refresh
    private func performTokenRefresh() async throws -> String {
        guard let refreshToken = await tokenManager.refreshToken else {
            throw NetworkError.unauthorized
        }

        let config = EnvironmentConfiguration.current

        // Build refresh token request
        guard let url = URL(string: "https://\(config.auth0Domain)/oauth/token") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "grant_type": "refresh_token",
            "client_id": config.auth0ClientId,
            "refresh_token": refreshToken
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(underlyingError: "Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            // Clear tokens on refresh failure
            await tokenManager.clearTokens()
            throw NetworkError.unauthorized
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        // Store new tokens
        await tokenManager.storeTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken ?? refreshToken,
            idToken: tokenResponse.idToken,
            expiresIn: tokenResponse.expiresIn
        )

        return tokenResponse.accessToken
    }

    /// Public method to trigger token refresh
    func refreshToken() async throws {
        _ = try await refreshTokenIfNeeded()
    }

    /// Clear all tokens (for logout)
    func clearTokens() async {
        await tokenManager.clearTokens()
    }
}

// MARK: - Token Response

/// Response from Auth0 token endpoint
struct TokenResponse: Codable, Sendable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

// MARK: - Additional Interceptors

/// Interceptor for adding custom headers
actor HeaderInterceptor: RequestInterceptor {
    private let headers: [String: String]

    init(headers: [String: String]) {
        self.headers = headers
    }

    func intercept(request: URLRequest) async throws -> URLRequest {
        var modifiedRequest = request
        for (key, value) in headers {
            modifiedRequest.setValue(value, forHTTPHeaderField: key)
        }
        return modifiedRequest
    }
}

/// Interceptor chain for combining multiple interceptors
actor InterceptorChain: RequestInterceptor {
    private let interceptors: [RequestInterceptor]

    init(interceptors: [RequestInterceptor]) {
        self.interceptors = interceptors
    }

    func intercept(request: URLRequest) async throws -> URLRequest {
        var modifiedRequest = request
        for interceptor in interceptors {
            modifiedRequest = try await interceptor.intercept(request: modifiedRequest)
        }
        return modifiedRequest
    }
}

/// Logging interceptor for debugging
actor LoggingInterceptor: RequestInterceptor {
    func intercept(request: URLRequest) async throws -> URLRequest {
        #if DEBUG
        if AppEnvironment.current.isLoggingEnabled {
            print("=== Request ===")
            print("URL: \(request.url?.absoluteString ?? "unknown")")
            print("Method: \(request.httpMethod ?? "unknown")")
            print("Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let body = request.httpBody,
               let bodyString = String(data: body, encoding: .utf8) {
                print("Body: \(bodyString.prefix(1000))")
            }
            print("===============")
        }
        #endif
        return request
    }
}
