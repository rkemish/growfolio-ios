//
//  MockUserRepository.swift
//  GrowfolioTests
//
//  Mock user repository for testing.
//

import Foundation
@testable import Growfolio

/// Mock user repository that returns predefined responses for testing
final class MockUserRepository: UserRepositoryProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    var userToReturn: User?
    var settingsToReturn: UserSettings?
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var fetchCurrentUserCalled = false
    var updateProfileCalled = false
    var lastUpdatedDisplayName: String?
    var fetchPreferencesCalled = false
    var updatePreferencesCalled = false
    var lastUpdatedPreferences: UserPreferencesUpdate?
    var registerDeviceTokenCalled = false
    var lastRegisteredDeviceToken: String?
    var deleteAccountCalled = false

    // MARK: - Reset

    func reset() {
        userToReturn = nil
        settingsToReturn = nil
        errorToThrow = nil

        fetchCurrentUserCalled = false
        updateProfileCalled = false
        lastUpdatedDisplayName = nil
        fetchPreferencesCalled = false
        updatePreferencesCalled = false
        lastUpdatedPreferences = nil
        registerDeviceTokenCalled = false
        lastRegisteredDeviceToken = nil
        deleteAccountCalled = false
    }

    // MARK: - UserRepositoryProtocol Implementation

    func fetchCurrentUser() async throws -> User {
        fetchCurrentUserCalled = true
        if let error = errorToThrow { throw error }
        if let user = userToReturn { return user }
        return User(
            id: "mock-user-id",
            email: "mock@example.com",
            displayName: "Mock User",
            profilePictureURL: nil,
            preferredCurrency: "GBP",
            notificationsEnabled: true,
            biometricEnabled: false,
            createdAt: Date(),
            updatedAt: Date(),
            subscriptionTier: .free,
            subscriptionExpiresAt: nil,
            timezoneIdentifier: "Europe/London"
        )
    }

    func updateProfile(displayName: String) async throws -> User {
        updateProfileCalled = true
        lastUpdatedDisplayName = displayName
        if let error = errorToThrow { throw error }
        if let user = userToReturn { return user }
        return User(
            id: "mock-user-id",
            email: "mock@example.com",
            displayName: displayName,
            profilePictureURL: nil,
            preferredCurrency: "GBP",
            notificationsEnabled: true,
            biometricEnabled: false,
            createdAt: Date(),
            updatedAt: Date(),
            subscriptionTier: .free,
            subscriptionExpiresAt: nil,
            timezoneIdentifier: "Europe/London"
        )
    }

    func fetchPreferences() async throws -> UserSettings {
        fetchPreferencesCalled = true
        if let error = errorToThrow { throw error }
        if let settings = settingsToReturn { return settings }
        return UserSettings(
            preferredCurrency: "GBP",
            notificationsEnabled: true,
            biometricEnabled: false,
            timezoneIdentifier: "Europe/London",
            theme: .system,
            hapticFeedbackEnabled: true,
            showBalances: true
        )
    }

    func updatePreferences(_ preferences: UserPreferencesUpdate) async throws -> UserSettings {
        updatePreferencesCalled = true
        lastUpdatedPreferences = preferences
        if let error = errorToThrow { throw error }
        if let settings = settingsToReturn { return settings }
        return UserSettings(
            preferredCurrency: preferences.defaultCurrency ?? "GBP",
            notificationsEnabled: preferences.notificationsEnabled ?? true,
            biometricEnabled: preferences.biometricEnabled ?? false,
            timezoneIdentifier: "Europe/London",
            theme: preferences.theme.flatMap { AppTheme(rawValue: $0) } ?? .system,
            hapticFeedbackEnabled: true,
            showBalances: true
        )
    }

    func registerDeviceToken(_ token: String) async throws {
        registerDeviceTokenCalled = true
        lastRegisteredDeviceToken = token
        if let error = errorToThrow { throw error }
    }

    func deleteAccount() async throws {
        deleteAccountCalled = true
        if let error = errorToThrow { throw error }
    }
}
