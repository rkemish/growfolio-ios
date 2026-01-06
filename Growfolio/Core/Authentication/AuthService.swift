//
//  AuthService.swift
//  Growfolio
//
//  Auth0 authentication service for user authentication.
//

import Foundation
import AuthenticationServices

// MARK: - Auth Service Protocol

/// Protocol defining authentication operations
protocol AuthServiceProtocol: Sendable {
    func login() async throws
    func logout() async throws
    func isAuthenticated() async -> Bool
    func refreshSession() async throws
    func handleCallback(url: URL) -> Bool
}

// MARK: - Auth Service

/// Main authentication service using Auth0
@Observable
final class AuthService: AuthServiceProtocol, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = AuthService()

    // MARK: - Properties

    private let tokenManager: TokenManager
    private let config: EnvironmentConfiguration
    private var currentAuthSession: ASWebAuthenticationSession?
    private let callbackScheme = "growfolio"

    // Observable state
    private(set) var isLoading = false
    private(set) var currentUser: AuthUser?
    private(set) var error: AuthError?

    // MARK: - Initialization

    init(
        tokenManager: TokenManager = TokenManager.shared,
        config: EnvironmentConfiguration = .current
    ) {
        self.tokenManager = tokenManager
        self.config = config
    }

    // MARK: - AuthServiceProtocol

    func login() async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        // Build authorization URL
        let authURL = try buildAuthorizationURL()

        // Perform web authentication
        let callbackURL = try await performWebAuthentication(url: authURL)

        // Handle the callback
        try await handleAuthorizationCallback(url: callbackURL)

        // Load user profile
        await loadUserProfile()
    }

    func logout() async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        // Build logout URL
        let logoutURL = buildLogoutURL()

        // Perform logout (fire and forget for logout redirect)
        _ = try? await performWebAuthentication(url: logoutURL, prefersEphemeralSession: true)

        // Clear local state
        await tokenManager.clearTokens()
        await MainActor.run {
            currentUser = nil
            error = nil
        }
    }

    func isAuthenticated() async -> Bool {
        await tokenManager.hasValidTokens
    }

    func refreshSession() async throws {
        guard let refreshToken = await tokenManager.refreshToken else {
            throw AuthError.notAuthenticated
        }

        let tokenResponse = try await performTokenRefresh(refreshToken: refreshToken)

        await tokenManager.storeTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            idToken: tokenResponse.idToken,
            expiresIn: tokenResponse.expiresIn
        )

        await loadUserProfile()
    }

    func handleCallback(url: URL) -> Bool {
        // Handle callback URLs for Auth0
        guard url.scheme == callbackScheme else { return false }
        // The ASWebAuthenticationSession handles the callback automatically
        return true
    }

    // MARK: - Private Methods

    private func buildAuthorizationURL() throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = config.auth0Domain
        components.path = "/authorize"

        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)

        // Store code verifier for token exchange
        UserDefaults.standard.set(codeVerifier, forKey: "auth_code_verifier")

        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.auth0ClientId),
            URLQueryItem(name: "redirect_uri", value: "\(callbackScheme)://callback"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid profile email offline_access"),
            URLQueryItem(name: "audience", value: config.auth0Audience),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        guard let url = components.url else {
            throw AuthError.invalidConfiguration
        }

        return url
    }

    private func buildLogoutURL() -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = config.auth0Domain
        components.path = "/v2/logout"

        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.auth0ClientId),
            URLQueryItem(name: "returnTo", value: "\(callbackScheme)://logout")
        ]

        return components.url!
    }

    @MainActor
    private func performWebAuthentication(
        url: URL,
        prefersEphemeralSession: Bool = false
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error = error {
                    if let authError = error as? ASWebAuthenticationSessionError,
                       authError.code == .canceledLogin {
                        continuation.resume(throwing: AuthError.cancelled)
                    } else {
                        continuation.resume(throwing: AuthError.authenticationFailed(error.localizedDescription))
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: AuthError.invalidCallback)
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            session.prefersEphemeralWebBrowserSession = prefersEphemeralSession
            session.presentationContextProvider = WebAuthPresentationContext.shared

            self.currentAuthSession = session

            if !session.start() {
                continuation.resume(throwing: AuthError.sessionStartFailed)
            }
        }
    }

    private func handleAuthorizationCallback(url: URL) async throws {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AuthError.invalidCallback
        }

        // Check for error in callback
        if let errorCode = components.queryItems?.first(where: { $0.name == "error" })?.value {
            let errorDescription = components.queryItems?.first(where: { $0.name == "error_description" })?.value
            throw AuthError.authenticationFailed(errorDescription ?? errorCode)
        }

        // Exchange code for tokens
        let tokenResponse = try await exchangeCodeForTokens(code: code)

        await tokenManager.storeTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            idToken: tokenResponse.idToken,
            expiresIn: tokenResponse.expiresIn
        )
    }

    private func exchangeCodeForTokens(code: String) async throws -> AuthTokenResponse {
        guard let codeVerifier = UserDefaults.standard.string(forKey: "auth_code_verifier") else {
            throw AuthError.invalidConfiguration
        }

        // Clean up code verifier
        UserDefaults.standard.removeObject(forKey: "auth_code_verifier")

        var components = URLComponents()
        components.scheme = "https"
        components.host = config.auth0Domain
        components.path = "/oauth/token"

        guard let url = components.url else {
            throw AuthError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": config.auth0ClientId,
            "code": code,
            "redirect_uri": "\(callbackScheme)://callback",
            "code_verifier": codeVerifier
        ]

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }

        return try JSONDecoder().decode(AuthTokenResponse.self, from: data)
    }

    private func performTokenRefresh(refreshToken: String) async throws -> AuthTokenResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = config.auth0Domain
        components.path = "/oauth/token"

        guard let url = components.url else {
            throw AuthError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "refresh_token",
            "client_id": config.auth0ClientId,
            "refresh_token": refreshToken
        ]

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.tokenRefreshFailed
        }

        return try JSONDecoder().decode(AuthTokenResponse.self, from: data)
    }

    private func loadUserProfile() async {
        guard let idToken = await tokenManager.idToken,
              let claims = await tokenManager.decodeJWT(idToken) else {
            return
        }

        let user = AuthUser(
            id: claims["sub"] as? String ?? "",
            email: claims["email"] as? String,
            name: claims["name"] as? String,
            picture: (claims["picture"] as? String).flatMap { URL(string: $0) }
        )

        await MainActor.run {
            self.currentUser = user
        }
    }

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncodedString()
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash).base64URLEncodedString()
    }
}

// MARK: - Supporting Types

struct AuthUser: Sendable, Equatable {
    let id: String
    let email: String?
    let name: String?
    let picture: URL?
}

struct AuthTokenResponse: Codable, Sendable {
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

enum AuthError: LocalizedError, Sendable {
    case notAuthenticated
    case invalidConfiguration
    case authenticationFailed(String)
    case tokenExchangeFailed
    case tokenRefreshFailed
    case invalidCallback
    case cancelled
    case sessionStartFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidConfiguration:
            return "Invalid authentication configuration"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for tokens"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication tokens"
        case .invalidCallback:
            return "Invalid authentication callback"
        case .cancelled:
            return "Authentication was cancelled"
        case .sessionStartFailed:
            return "Failed to start authentication session"
        }
    }
}

// MARK: - Web Auth Presentation Context

final class WebAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {
    static let shared = WebAuthPresentationContext()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Get the key window from connected scenes
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}

// MARK: - Data Extension for Base64URL

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - CommonCrypto Import

import CommonCrypto
