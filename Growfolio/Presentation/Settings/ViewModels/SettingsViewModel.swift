//
//  SettingsViewModel.swift
//  Growfolio
//
//  View model for settings and user preferences.
//

import Foundation
import SwiftUI

@Observable
final class SettingsViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Loading State
    var isLoading = false
    var isSaving = false
    var error: Error?

    // User Data
    var user: User?
    var settings: UserSettings = UserSettings()
    var notificationSettings: NotificationSettings = .default

    // Sheet Presentation
    var showEditProfile = false
    var showCurrencyPicker = false
    var showThemePicker = false
    var showNotificationSettings = false
    var showAbout = false
    var showDeleteAccountConfirmation = false
    var showSignOutConfirmation = false

    // App Info
    let appVersion = Constants.App.version
    let buildNumber = Constants.App.buildNumber

    // Repository
    private let userRepository: UserRepositoryProtocol
    private let authService: AuthService

    // MARK: - Computed Properties

    var displayName: String {
        user?.displayNameOrEmail ?? "User"
    }

    var email: String {
        user?.email ?? ""
    }

    var initials: String {
        user?.initials ?? "?"
    }

    var subscriptionTier: SubscriptionTier {
        user?.subscriptionTier ?? .free
    }

    var isPremium: Bool {
        user?.canAccessPremiumFeatures ?? false
    }

    var memberSince: String {
        user?.createdAt.displayString ?? "Unknown"
    }

    // MARK: - Initialization

    init(
        userRepository: UserRepositoryProtocol = UserRepository(),
        authService: AuthService = .shared
    ) {
        self.userRepository = userRepository
        self.authService = authService
    }

    // MARK: - Data Loading

    @MainActor
    func loadUserData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Fetch user from API
            user = try await userRepository.fetchCurrentUser()

            // Load settings - combine API data with local preferences
            loadLocalSettings()

        } catch {
            self.error = error
            // Fall back to local settings if API fails
            loadLocalSettings()
        }

        isLoading = false
    }

    private func loadLocalSettings() {
        let defaults = UserDefaults.standard

        settings = UserSettings(
            preferredCurrency: user?.preferredCurrency ?? defaults.string(forKey: Constants.StorageKeys.preferredCurrency) ?? "USD",
            notificationsEnabled: user?.notificationsEnabled ?? true,
            biometricEnabled: user?.biometricEnabled ?? defaults.bool(forKey: Constants.StorageKeys.biometricEnabled),
            timezoneIdentifier: user?.timezoneIdentifier ?? TimeZone.current.identifier,
            theme: AppTheme(rawValue: defaults.string(forKey: Constants.StorageKeys.selectedTheme) ?? "system") ?? .system,
            hapticFeedbackEnabled: true,
            showBalances: true
        )
    }

    // MARK: - Settings Updates

    @MainActor
    func updateCurrency(_ currency: String) async {
        settings.preferredCurrency = currency
        UserDefaults.standard.set(currency, forKey: Constants.StorageKeys.preferredCurrency)
        await saveSettings()
    }

    @MainActor
    func updateTheme(_ theme: AppTheme) {
        settings.theme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: Constants.StorageKeys.selectedTheme)
    }

    @MainActor
    func toggleNotifications(_ enabled: Bool) async {
        settings.notificationsEnabled = enabled
        await saveSettings()
    }

    @MainActor
    func toggleBiometric(_ enabled: Bool) async {
        settings.biometricEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Constants.StorageKeys.biometricEnabled)
        await saveSettings()
    }

    @MainActor
    func updateNotificationSettings(_ newSettings: NotificationSettings) async {
        notificationSettings = newSettings
        await saveSettings()
    }

    @MainActor
    private func saveSettings() async {
        isSaving = true

        do {
            let preferencesUpdate = UserPreferencesUpdate.from(
                settings: settings,
                notifications: notificationSettings
            )
            _ = try await userRepository.updatePreferences(preferencesUpdate)
        } catch {
            self.error = error
        }

        isSaving = false
    }

    // MARK: - Profile Updates

    @MainActor
    func updateDisplayName(_ name: String) async {
        isSaving = true

        do {
            user = try await userRepository.updateProfile(displayName: name)
        } catch {
            self.error = error
        }

        isSaving = false
    }

    // MARK: - Account Actions

    @MainActor
    func signOut() async {
        do {
            try await authService.logout()
            user = nil
            UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        } catch {
            self.error = error
        }
    }

    @MainActor
    func deleteAccount() async {
        do {
            try await userRepository.deleteAccount()
            await signOut()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Currency Options

extension SettingsViewModel {
    static let availableCurrencies: [(code: String, name: String, symbol: String)] = [
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"),
        ("CAD", "Canadian Dollar", "C$"),
        ("AUD", "Australian Dollar", "A$"),
        ("JPY", "Japanese Yen", "¥"),
        ("CHF", "Swiss Franc", "CHF"),
        ("CNY", "Chinese Yuan", "¥"),
        ("INR", "Indian Rupee", "₹"),
        ("MXN", "Mexican Peso", "$"),
    ]
}
