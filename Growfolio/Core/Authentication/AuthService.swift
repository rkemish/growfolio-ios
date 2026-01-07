//
//  AuthService.swift
//  Growfolio
//
//  Apple Sign In authentication service for user authentication.
//

import AuthenticationServices
import Foundation
import Observation
import UIKit

// MARK: - Auth Service Protocol

/// Protocol defining authentication operations
protocol AuthServiceProtocol: Sendable {
    func login() async throws
    func logout() async throws
    func isAuthenticated() async -> Bool
    func refreshSession() async throws
}

// MARK: - Auth Service

/// Main authentication service using Sign in with Apple
@Observable
final class AuthService: AuthServiceProtocol, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = AuthService()

    // MARK: - Properties

    private let tokenManager: TokenManager
    private let apiClient: APIClientProtocol
    private let signInCoordinator: AppleSignInCoordinator?

    // Observable state
    private(set) var isLoading = false
    private(set) var currentUser: AuthUser?
    private(set) var error: AuthError?

    // MARK: - Initialization

    init(
        tokenManager: TokenManager = TokenManager.shared,
        apiClient: APIClientProtocol = APIClient.shared,
        signInCoordinator: AppleSignInCoordinator? = nil
    ) {
        self.tokenManager = tokenManager
        self.apiClient = apiClient
        self.signInCoordinator = signInCoordinator
    }

    // MARK: - AuthServiceProtocol

    func login() async throws {
        if MockConfiguration.shared.isEnabled {
            await loadMockUser()
            return
        }

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        await MainActor.run { error = nil }

        do {
            let coordinator = await getSignInCoordinator()
            let credential = try await coordinator.signIn(requestedScopes: [.fullName, .email])
            try await handleCredential(credential)
        } catch let authError as AuthError {
            await MainActor.run { error = authError }
            throw authError
        } catch {
            let wrapped = AuthError.authenticationFailed(error.localizedDescription)
            await MainActor.run { self.error = wrapped }
            throw wrapped
        }
    }

    func logout() async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        await tokenManager.clearTokens()
        await MainActor.run {
            currentUser = nil
            error = nil
        }
    }

    func isAuthenticated() async -> Bool {
        if MockConfiguration.shared.isEnabled {
            return true
        }
        return await tokenManager.hasValidTokens
    }

    func refreshSession() async throws {
        if MockConfiguration.shared.isEnabled {
            await loadMockUser()
            return
        }

        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        await MainActor.run { error = nil }

        let coordinator = await getSignInCoordinator()
        let credential = try await coordinator.signIn(requestedScopes: [])
        try await handleCredential(credential)
    }

    // MARK: - Private Methods

    @MainActor
    private func getSignInCoordinator() -> AppleSignInCoordinator {
        if let coordinator = signInCoordinator {
            return coordinator
        }
        // Create a new coordinator on the main actor
        return AppleSignInCoordinator()
    }

    private func loadMockUser() async {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        await MainActor.run { error = nil }

        let store = MockDataStore.shared
        if await store.currentUser == nil {
            await store.initialize(for: MockConfiguration.shared.demoPersona)
        }

        let user = await store.currentUser
        let authUser = AuthUser(
            id: user?.id ?? "mock-user",
            email: user?.email ?? "mock@growfolio.app",
            name: user?.displayNameOrEmail ?? "Mock User",
            picture: user?.profilePictureURL
        )

        await MainActor.run {
            currentUser = authUser
        }
    }

    /// Processes an Apple Sign In credential by exchanging it with the backend and loading the user profile.
    ///
    /// Error Handling Strategy:
    /// - If the identity token is missing, throws immediately (no state change)
    /// - If token exchange fails, clears any stored tokens and re-throws (strict rollback)
    /// - Profile loading is intentionally non-throwing and always succeeds with available data
    ///
    /// This "lenient" approach for profile loading is appropriate because:
    /// 1. Apple only provides user details (name, email) on first sign-in
    /// 2. Subsequent sign-ins have minimal data, so we use fallbacks
    /// 3. The critical authentication step (token exchange) already succeeded
    /// 4. Users remain authenticated and can retry profile fetch if needed
    private func handleCredential(_ credential: ASAuthorizationAppleIDCredential) async throws {
        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.identityTokenMissing
        }

        // Store tokens temporarily for the exchange request
        let expiresIn = await expirationInterval(for: identityToken)
        await tokenManager.storeTokens(
            accessToken: identityToken,
            refreshToken: nil,
            idToken: identityToken,
            expiresIn: expiresIn
        )

        // Exchange identity token with backend - rollback on failure
        let exchangeResponse: AppleTokenExchangeResponse
        do {
            exchangeResponse = try await exchangeIdentityToken(
                identityToken,
                fullName: credential.fullName
            )
        } catch {
            // Strict rollback: clear tokens if backend exchange fails
            await tokenManager.clearTokens()
            throw error
        }

        // Load user profile - intentionally non-throwing (see method docs)
        // At this point, authentication is complete; profile loading uses best-effort data resolution
        await loadUserProfile(
            identityToken: identityToken,
            exchangeResponse: exchangeResponse,
            fullName: credential.fullName,
            email: credential.email
        )
    }

    private func exchangeIdentityToken(
        _ token: String,
        fullName: PersonNameComponents?
    ) async throws -> AppleTokenExchangeResponse {
        let request = AppleTokenExchangeRequest(
            identityToken: token,
            userFirstName: fullName?.givenName,
            userLastName: fullName?.familyName
        )

        do {
            return try await apiClient.request(
                try Endpoints.ExchangeAppleToken(request: request)
            )
        } catch {
            throw AuthError.tokenExchangeFailed
        }
    }

    /// Loads the user profile from available data sources with graceful fallbacks.
    ///
    /// This method is intentionally non-throwing. It resolves user data from multiple sources
    /// in priority order (backend response > JWT claims > Apple credential) and always
    /// produces a valid `AuthUser`. This ensures authentication completes even when
    /// some user details are unavailable (common for repeat sign-ins with Apple).
    ///
    /// - Note: Called after successful token exchange, so authentication state is already valid.
    private func loadUserProfile(
        identityToken: String,
        exchangeResponse: AppleTokenExchangeResponse?,
        fullName: PersonNameComponents?,
        email: String?
    ) async {
        // Extract claims from JWT for fallback data
        let claims = await tokenManager.decodeJWT(identityToken)
        let nameFromToken = claims?["name"] as? String
        let emailFromToken = claims?["email"] as? String

        // Format the name from Apple credential if available
        let formattedName = fullName.flatMap { PersonNameComponentsFormatter().string(from: $0) }

        // Resolve user data with priority: backend > JWT > Apple credential
        let userId = exchangeResponse?.userId ?? (claims?["sub"] as? String ?? "")
        let resolvedEmail = exchangeResponse?.email ?? emailFromToken ?? email
        let name = exchangeResponse?.name ?? nameFromToken ?? formattedName

        let user = AuthUser(
            id: userId,
            email: resolvedEmail,
            name: name,
            picture: nil
        )

        await MainActor.run {
            self.currentUser = user
        }
    }

    private func expirationInterval(for token: String) async -> Int {
        guard let claims = await tokenManager.decodeJWT(token) else {
            return Int(Constants.Auth.tokenRefreshThreshold)
        }

        let expValue = claims["exp"]
        let expTimestamp: TimeInterval?

        if let exp = expValue as? TimeInterval {
            expTimestamp = exp
        } else if let exp = expValue as? Int {
            expTimestamp = TimeInterval(exp)
        } else if let exp = expValue as? String, let expDouble = TimeInterval(exp) {
            expTimestamp = expDouble
        } else {
            expTimestamp = nil
        }

        guard let expTimestamp else {
            return Int(Constants.Auth.tokenRefreshThreshold)
        }

        let now = Date().timeIntervalSince1970
        return max(0, Int(expTimestamp - now))
    }
}

// MARK: - Supporting Types

struct AuthUser: Sendable, Equatable {
    let id: String
    let email: String?
    let name: String?
    let picture: URL?
}

enum AuthError: LocalizedError, Sendable {
    case notAuthenticated
    case authenticationFailed(String)
    case tokenExchangeFailed
    case identityTokenMissing
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .tokenExchangeFailed:
            return "Failed to exchange identity token"
        case .identityTokenMissing:
            return "Missing identity token"
        case .cancelled:
            return "Authentication was cancelled"
        }
    }
}

// MARK: - Apple Sign In Coordinator

@MainActor
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding, @unchecked Sendable {

    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    private var currentController: ASAuthorizationController?

    func signIn(requestedScopes: [ASAuthorization.Scope]) async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = requestedScopes

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.currentController = controller
            controller.performRequests()
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: AuthError.authenticationFailed("Missing Apple credential"))
            return
        }
        finish(with: credential)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled {
            finish(with: AuthError.cancelled)
            return
        }

        finish(with: AuthError.authenticationFailed(error.localizedDescription))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }

    private func finish(with credential: ASAuthorizationAppleIDCredential) {
        continuation?.resume(returning: credential)
        resetState()
    }

    private func finish(with error: Error) {
        continuation?.resume(throwing: error)
        resetState()
    }

    private func resetState() {
        continuation = nil
        currentController = nil
    }
}
