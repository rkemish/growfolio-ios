//
//  MockUserRepository.swift
//  Growfolio
//
//  Mock implementation of UserRepositoryProtocol for demo mode.
//

import Foundation

/// Mock implementation of UserRepositoryProtocol
final class MockUserRepository: UserRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let store = MockDataStore.shared
    private let config = MockConfiguration.shared

    // MARK: - UserRepositoryProtocol

    func fetchCurrentUser() async throws -> User {
        try await simulateNetwork()

        if let user = await store.currentUser {
            return user
        }

        // Initialize if not yet done
        await store.initialize(for: config.demoPersona)
        guard let user = await store.currentUser else {
            throw MockError.entityNotFound(type: "User", id: "current")
        }
        return user
    }

    func updateProfile(displayName: String) async throws -> User {
        try await simulateNetwork()

        guard var user = await store.currentUser else {
            throw MockError.entityNotFound(type: "User", id: "current")
        }

        user = User(
            id: user.id,
            email: user.email,
            displayName: displayName,
            profilePictureURL: user.profilePictureURL,
            preferredCurrency: user.preferredCurrency,
            notificationsEnabled: user.notificationsEnabled,
            biometricEnabled: user.biometricEnabled,
            createdAt: user.createdAt,
            updatedAt: Date(),
            subscriptionTier: user.subscriptionTier,
            subscriptionExpiresAt: user.subscriptionExpiresAt,
            timezoneIdentifier: user.timezoneIdentifier
        )

        await store.updateUser(user)
        return user
    }

    func fetchPreferences() async throws -> UserSettings {
        try await simulateNetwork()

        if let settings = await store.userSettings {
            return settings
        }

        // Return default settings if not set
        let defaultSettings = UserSettings()
        await store.setUserSettings(defaultSettings)
        return defaultSettings
    }

    func updatePreferences(_ preferences: UserPreferencesUpdate) async throws -> UserSettings {
        try await simulateNetwork()

        var settings = await store.userSettings ?? UserSettings()

        if let currency = preferences.defaultCurrency {
            settings = UserSettings(
                preferredCurrency: currency,
                notificationsEnabled: preferences.notificationsEnabled ?? settings.notificationsEnabled,
                biometricEnabled: preferences.biometricEnabled ?? settings.biometricEnabled,
                timezoneIdentifier: settings.timezoneIdentifier,
                theme: preferences.theme.flatMap { AppTheme(rawValue: $0) } ?? settings.theme,
                hapticFeedbackEnabled: settings.hapticFeedbackEnabled,
                showBalances: settings.showBalances
            )
        } else {
            settings = UserSettings(
                preferredCurrency: settings.preferredCurrency,
                notificationsEnabled: preferences.notificationsEnabled ?? settings.notificationsEnabled,
                biometricEnabled: preferences.biometricEnabled ?? settings.biometricEnabled,
                timezoneIdentifier: settings.timezoneIdentifier,
                theme: preferences.theme.flatMap { AppTheme(rawValue: $0) } ?? settings.theme,
                hapticFeedbackEnabled: settings.hapticFeedbackEnabled,
                showBalances: settings.showBalances
            )
        }

        await store.setUserSettings(settings)
        return settings
    }

    func registerDeviceToken(_ token: String) async throws {
        try await simulateNetwork()
        // No-op for mock - just simulate success
    }

    func deleteAccount() async throws {
        try await simulateNetwork()
        await store.reset()
    }

    // MARK: - Private Methods

    private func simulateNetwork() async throws {
        try await config.simulateNetworkDelay()
        try config.maybeThrowSimulatedError()
    }
}
