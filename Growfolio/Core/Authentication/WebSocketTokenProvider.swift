//
//  WebSocketTokenProvider.swift
//  Growfolio
//
//  Token provider for WebSocket authentication.
//

import Foundation

/// Provides tokens for WebSocket authentication and refresh.
protocol WebSocketTokenProvider: Sendable {
    var tokenManager: TokenManager { get }
    func validToken() async throws -> String
    func refreshToken() async throws -> String
}

extension WebSocketTokenProvider {
    func currentToken() async throws -> String {
        if let idToken = await tokenManager.idToken {
            return idToken
        }
        if let accessToken = await tokenManager.accessToken {
            return accessToken
        }
        throw NetworkError.unauthorized
    }
}

#if !SWIFT_PACKAGE
/// Token provider that refreshes via AuthService when necessary.
@MainActor
final class AuthServiceWebSocketTokenProvider: WebSocketTokenProvider, @unchecked Sendable {

    private let authService: AuthService
    let tokenManager: TokenManager
    private var refreshTask: Task<String, Error>?

    init(
        authService: AuthService = AuthService.shared,
        tokenManager: TokenManager = TokenManager.shared
    ) {
        self.authService = authService
        self.tokenManager = tokenManager
    }

    func validToken() async throws -> String {
        if await tokenManager.isTokenExpired(threshold: 0) {
            return try await refreshToken()
        }
        return try await currentToken()
    }

    func refreshToken() async throws -> String {
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        let task = Task { [weak self] () throws -> String in
            defer { Task { @MainActor in self?.refreshTask = nil } }
            guard let self else { throw NetworkError.unauthorized }
            try await authService.refreshSession()
            return try await currentToken()
        }

        refreshTask = task
        return try await task.value
    }
}
#endif

/// Default WebSocket token provider backed by TokenManager.
final class TokenManagerWebSocketTokenProvider: WebSocketTokenProvider, @unchecked Sendable {

    let tokenManager: TokenManager

    init(tokenManager: TokenManager = TokenManager.shared) {
        self.tokenManager = tokenManager
    }

    func validToken() async throws -> String {
        if await tokenManager.isTokenExpired(threshold: 0) {
            throw NetworkError.unauthorized
        }
        return try await currentToken()
    }

    func refreshToken() async throws -> String {
        if await tokenManager.isTokenExpired(threshold: 0) {
            throw NetworkError.unauthorized
        }
        return try await currentToken()
    }
}

enum WebSocketTokenProviderFactory {
    @MainActor static func makeDefault() -> WebSocketTokenProvider {
        #if SWIFT_PACKAGE
        return TokenManagerWebSocketTokenProvider()
        #else
        return AuthServiceWebSocketTokenProvider()
        #endif
    }
}
