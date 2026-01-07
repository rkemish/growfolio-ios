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

    private func getValidToken() async throws -> String {
        if await tokenManager.isTokenExpired {
            throw NetworkError.unauthorized
        }

        if let idToken = await tokenManager.idToken {
            return idToken
        }

        if let accessToken = await tokenManager.accessToken {
            return accessToken
        }

        throw NetworkError.unauthorized
    }

    func clearTokens() async {
        await tokenManager.clearTokens()
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
                print("Body: \(bodyString)")
            }
            print("===============")
        }
        #endif
        return request
    }
}
