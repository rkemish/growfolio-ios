//
//  AuthServiceTests.swift
//  GrowfolioTests
//
//  Tests for AuthService, AuthUser, and AuthError.
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
            picture: nil
        )

        XCTAssertEqual(user.id, "user-123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertNil(user.picture)
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

    // MARK: - AppleTokenExchangeResponse Tests

    func testAppleTokenExchangeResponseDecoding() throws {
        let json = """
        {
            "user_id": "apple|123456",
            "email": "user@example.com",
            "name": "Test User",
            "alpaca_account_status": "ACTIVE"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(AppleTokenExchangeResponse.self, from: json)

        XCTAssertEqual(response.userId, "apple|123456")
        XCTAssertEqual(response.email, "user@example.com")
        XCTAssertEqual(response.name, "Test User")
        XCTAssertEqual(response.alpacaAccountStatus, "ACTIVE")
    }

    func testAppleTokenExchangeResponseDecodingWithNullOptionals() throws {
        let json = """
        {
            "user_id": "apple|123456",
            "email": null,
            "name": null,
            "alpaca_account_status": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(AppleTokenExchangeResponse.self, from: json)

        XCTAssertEqual(response.userId, "apple|123456")
        XCTAssertNil(response.email)
        XCTAssertNil(response.name)
        XCTAssertNil(response.alpacaAccountStatus)
    }

    // MARK: - AuthError Tests

    func testAuthErrorNotAuthenticated() {
        let error = AuthError.notAuthenticated
        XCTAssertEqual(error.errorDescription, "User is not authenticated")
    }

    func testAuthErrorAuthenticationFailed() {
        let error = AuthError.authenticationFailed("Invalid credentials")
        XCTAssertEqual(error.errorDescription, "Authentication failed: Invalid credentials")
    }

    func testAuthErrorTokenExchangeFailed() {
        let error = AuthError.tokenExchangeFailed
        XCTAssertEqual(error.errorDescription, "Failed to exchange identity token")
    }

    func testAuthErrorIdentityTokenMissing() {
        let error = AuthError.identityTokenMissing
        XCTAssertEqual(error.errorDescription, "Missing identity token")
    }

    func testAuthErrorCancelled() {
        let error = AuthError.cancelled
        XCTAssertEqual(error.errorDescription, "Authentication was cancelled")
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
            .authenticationFailed("test"),
            .tokenExchangeFailed,
            .identityTokenMissing,
            .cancelled
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Error description should not be empty")
        }
    }

    // MARK: - AuthService Instance Tests

    func testAuthServiceSharedInstance() {
        let instance1 = AuthService.shared
        let instance2 = AuthService.shared

        XCTAssertTrue(instance1 === instance2)
    }

    func testAuthServiceInitialState() {
        let service = AuthService.shared

        XCTAssertFalse(service.isLoading)
    }

    func testAuthServiceIsAuthenticatedAsync() async {
        let service = AuthService.shared

        let isAuthenticated = await service.isAuthenticated()

        XCTAssertNotNil(isAuthenticated)
    }
}
