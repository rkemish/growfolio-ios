//
//  MockAuthService.swift
//  GrowfolioTests
//
//  Mock auth service for testing.
//

import Foundation
@testable import Growfolio

/// Mock auth service that returns predefined responses for testing
final class MockAuthService: @unchecked Sendable {

    // MARK: - Configurable Responses

    var isAuthenticatedResult: Bool = true
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var loginCalled = false
    var logoutCalled = false
    var isAuthenticatedCalled = false
    var refreshSessionCalled = false

    // MARK: - Reset

    func reset() {
        isAuthenticatedResult = true
        errorToThrow = nil

        loginCalled = false
        logoutCalled = false
        isAuthenticatedCalled = false
        refreshSessionCalled = false
    }

    // MARK: - Mock Methods

    func login() async throws {
        loginCalled = true
        if let error = errorToThrow { throw error }
    }

    func logout() async throws {
        logoutCalled = true
        if let error = errorToThrow { throw error }
    }

    func isAuthenticated() async -> Bool {
        isAuthenticatedCalled = true
        return isAuthenticatedResult
    }

    func refreshSession() async throws {
        refreshSessionCalled = true
        if let error = errorToThrow { throw error }
    }
}
