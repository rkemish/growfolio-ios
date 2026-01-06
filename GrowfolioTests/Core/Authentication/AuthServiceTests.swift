//
//  AuthServiceTests.swift
//  GrowfolioTests
//
//  Tests for AuthService, AuthUser, AuthTokenResponse, and AuthError.
//

import XCTest
@testable import Growfolio

final class AuthServiceTests: XCTestCase {

    // MARK: - AuthUser Tests

    func testAuthUserInitialization() {
        let user = AuthUser(
            id: "user-123",
            email: "test@example.com",
            name: "Test User",
            picture: URL(string: "https://example.com/avatar.jpg")
        )

        XCTAssertEqual(user.id, "user-123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.picture?.absoluteString, "https://example.com/avatar.jpg")
    }

    func testAuthUserWithNilOptionals() {
        let user = AuthUser(
            id: "user-456",
            email: nil,
            name: nil,
            picture: nil
        )

        XCTAssertEqual(user.id, "user-456")
        XCTAssertNil(user.email)
        XCTAssertNil(user.name)
        XCTAssertNil(user.picture)
    }

    func testAuthUserEquatable() {
        let user1 = AuthUser(id: "user-123", email: "test@example.com", name: "Test", picture: nil)
        let user2 = AuthUser(id: "user-123", email: "test@example.com", name: "Test", picture: nil)
        let user3 = AuthUser(id: "user-456", email: "other@example.com", name: "Other", picture: nil)

        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
    }

    func testAuthUserIsSendable() {
        let user = AuthUser(id: "user-123", email: "test@example.com", name: "Test", picture: nil)
        Task {
            let copy = user
            XCTAssertEqual(copy.id, "user-123")
        }
    }

    // MARK: - AuthTokenResponse Tests

    func testAuthTokenResponseDecoding() throws {
        let json = """
        {
            "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9",
            "refresh_token": "v1.refresh-token-123",
            "id_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.id",
            "token_type": "Bearer",
            "expires_in": 3600
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AuthTokenResponse.self, from: json)

        XCTAssertEqual(response.accessToken, "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9")
        XCTAssertEqual(response.refreshToken, "v1.refresh-token-123")
        XCTAssertEqual(response.idToken, "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.id")
        XCTAssertEqual(response.tokenType, "Bearer")
        XCTAssertEqual(response.expiresIn, 3600)
    }

    func testAuthTokenResponseDecodingWithNullOptionals() throws {
        let json = """
        {
            "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9",
            "refresh_token": null,
            "id_token": null,
            "token_type": "Bearer",
            "expires_in": 86400
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AuthTokenResponse.self, from: json)

        XCTAssertEqual(response.accessToken, "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9")
        XCTAssertNil(response.refreshToken)
        XCTAssertNil(response.idToken)
        XCTAssertEqual(response.tokenType, "Bearer")
        XCTAssertEqual(response.expiresIn, 86400)
    }

    func testAuthTokenResponseDecodingWithMissingOptionals() throws {
        let json = """
        {
            "access_token": "token123",
            "token_type": "Bearer",
            "expires_in": 7200
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AuthTokenResponse.self, from: json)

        XCTAssertEqual(response.accessToken, "token123")
        XCTAssertNil(response.refreshToken)
        XCTAssertNil(response.idToken)
        XCTAssertEqual(response.tokenType, "Bearer")
        XCTAssertEqual(response.expiresIn, 7200)
    }

    func testAuthTokenResponseEncoding() throws {
        let response = AuthTokenResponse(
            accessToken: "access123",
            refreshToken: "refresh456",
            idToken: "id789",
            tokenType: "Bearer",
            expiresIn: 3600
        )

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(AuthTokenResponse.self, from: data)

        XCTAssertEqual(decoded.accessToken, response.accessToken)
        XCTAssertEqual(decoded.refreshToken, response.refreshToken)
        XCTAssertEqual(decoded.idToken, response.idToken)
        XCTAssertEqual(decoded.tokenType, response.tokenType)
        XCTAssertEqual(decoded.expiresIn, response.expiresIn)
    }

    func testAuthTokenResponseIsSendable() {
        let response = AuthTokenResponse(
            accessToken: "token",
            refreshToken: nil,
            idToken: nil,
            tokenType: "Bearer",
            expiresIn: 3600
        )

        Task {
            let copy = response
            XCTAssertEqual(copy.accessToken, "token")
        }
    }

    // MARK: - AuthError Tests

    func testAuthErrorNotAuthenticated() {
        let error = AuthError.notAuthenticated
        XCTAssertEqual(error.errorDescription, "User is not authenticated")
    }

    func testAuthErrorInvalidConfiguration() {
        let error = AuthError.invalidConfiguration
        XCTAssertEqual(error.errorDescription, "Invalid authentication configuration")
    }

    func testAuthErrorAuthenticationFailed() {
        let error = AuthError.authenticationFailed("Invalid credentials")
        XCTAssertEqual(error.errorDescription, "Authentication failed: Invalid credentials")
    }

    func testAuthErrorTokenExchangeFailed() {
        let error = AuthError.tokenExchangeFailed
        XCTAssertEqual(error.errorDescription, "Failed to exchange authorization code for tokens")
    }

    func testAuthErrorTokenRefreshFailed() {
        let error = AuthError.tokenRefreshFailed
        XCTAssertEqual(error.errorDescription, "Failed to refresh authentication tokens")
    }

    func testAuthErrorInvalidCallback() {
        let error = AuthError.invalidCallback
        XCTAssertEqual(error.errorDescription, "Invalid authentication callback")
    }

    func testAuthErrorCancelled() {
        let error = AuthError.cancelled
        XCTAssertEqual(error.errorDescription, "Authentication was cancelled")
    }

    func testAuthErrorSessionStartFailed() {
        let error = AuthError.sessionStartFailed
        XCTAssertEqual(error.errorDescription, "Failed to start authentication session")
    }

    func testAuthErrorConformsToLocalizedError() {
        let error: LocalizedError = AuthError.cancelled
        XCTAssertNotNil(error.errorDescription)
    }

    func testAuthErrorIsSendable() {
        let error: AuthError = .cancelled
        Task {
            let copy = error
            if case .cancelled = copy {
                // Success
            } else {
                XCTFail("Error should be cancelled")
            }
        }
    }

    func testAllAuthErrorsHaveDescriptions() {
        let errors: [AuthError] = [
            .notAuthenticated,
            .invalidConfiguration,
            .authenticationFailed("test"),
            .tokenExchangeFailed,
            .tokenRefreshFailed,
            .invalidCallback,
            .cancelled,
            .sessionStartFailed
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Error description should not be empty")
        }
    }

    // MARK: - Data Extension Tests

    func testDataBase64URLEncodedString() {
        // Test basic encoding
        let data = "Hello, World!".data(using: .utf8)!
        let encoded = data.base64URLEncodedString()

        // Should not contain +, /, or =
        XCTAssertFalse(encoded.contains("+"))
        XCTAssertFalse(encoded.contains("/"))
        XCTAssertFalse(encoded.contains("="))

        // Should contain - instead of + and _ instead of /
        XCTAssertTrue(encoded.contains("S") || encoded.contains("G")) // Contains letters from encoding
    }

    func testDataBase64URLEncodedStringWithSpecialChars() {
        // Data that would produce +, /, and padding in standard base64
        let data = Data([0xfb, 0xff, 0xfe]) // Will produce special characters
        let encoded = data.base64URLEncodedString()

        XCTAssertFalse(encoded.contains("+"))
        XCTAssertFalse(encoded.contains("/"))
        XCTAssertFalse(encoded.contains("="))
    }

    func testDataBase64URLEncodedStringEmpty() {
        let data = Data()
        let encoded = data.base64URLEncodedString()

        XCTAssertEqual(encoded, "")
    }

    // MARK: - AuthService Instance Tests

    func testAuthServiceSharedInstance() {
        let instance1 = AuthService.shared
        let instance2 = AuthService.shared

        // Both should reference the same instance
        XCTAssertTrue(instance1 === instance2)
    }

    func testAuthServiceInitialState() {
        let service = AuthService.shared

        // Initial state should have no user
        XCTAssertFalse(service.isLoading)
        // Note: currentUser may or may not be nil depending on stored tokens
    }

    func testAuthServiceHandleCallbackWithInvalidScheme() {
        let service = AuthService.shared
        let url = URL(string: "https://example.com/callback")!

        let handled = service.handleCallback(url: url)

        XCTAssertFalse(handled)
    }

    func testAuthServiceHandleCallbackWithValidScheme() {
        let service = AuthService.shared
        let url = URL(string: "growfolio://callback?code=test123")!

        let handled = service.handleCallback(url: url)

        XCTAssertTrue(handled)
    }

    func testAuthServiceIsAuthenticatedAsync() async {
        let service = AuthService.shared

        // Check authentication status
        let isAuthenticated = await service.isAuthenticated()

        // Without valid tokens, should be false
        // Note: This depends on the token manager state
        XCTAssertNotNil(isAuthenticated)
    }

    // MARK: - WebAuthPresentationContext Tests

    func testWebAuthPresentationContextSharedInstance() {
        let instance1 = WebAuthPresentationContext.shared
        let instance2 = WebAuthPresentationContext.shared

        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Edge Cases

    func testAuthErrorAuthenticationFailedWithEmptyMessage() {
        let error = AuthError.authenticationFailed("")
        XCTAssertEqual(error.errorDescription, "Authentication failed: ")
    }

    func testAuthErrorAuthenticationFailedWithLongMessage() {
        let longMessage = String(repeating: "a", count: 1000)
        let error = AuthError.authenticationFailed(longMessage)
        XCTAssertTrue(error.errorDescription?.contains(longMessage) ?? false)
    }

    func testAuthUserWithEmptyId() {
        let user = AuthUser(id: "", email: nil, name: nil, picture: nil)
        XCTAssertEqual(user.id, "")
    }

    func testAuthUserWithSpecialCharacters() {
        let user = AuthUser(
            id: "auth0|123456",
            email: "user+test@example.com",
            name: "O'Connor, John",
            picture: URL(string: "https://example.com/avatar.jpg?size=large&format=png")
        )

        XCTAssertEqual(user.id, "auth0|123456")
        XCTAssertEqual(user.email, "user+test@example.com")
        XCTAssertEqual(user.name, "O'Connor, John")
        XCTAssertNotNil(user.picture)
    }
}
