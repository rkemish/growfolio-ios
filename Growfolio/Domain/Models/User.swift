//
//  User.swift
//  Growfolio
//
//  User domain model.
//

import Foundation
import SwiftUI

/// Represents a user in the Growfolio system
struct User: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier from Apple Sign In
    let id: String

    /// User's email address
    let email: String

    /// User's display name
    var displayName: String?

    /// User's first name
    var firstName: String?

    /// User's last name
    var lastName: String?

    /// User's profile picture URL
    var profilePictureURL: URL?

    /// Alpaca brokerage account ID
    var alpacaAccountId: String?

    /// Family ID if user is part of a family account
    var familyId: String?

    /// User's preferred currency code (e.g., "USD", "EUR")
    var preferredCurrency: String

    /// Whether push notifications are enabled
    var notificationsEnabled: Bool

    /// Whether biometric authentication is enabled
    var biometricEnabled: Bool

    /// Date when the user was created
    let createdAt: Date

    /// Date when the user was last updated
    var updatedAt: Date

    /// User's subscription tier
    var subscriptionTier: SubscriptionTier

    /// Date when the subscription expires (if applicable)
    var subscriptionExpiresAt: Date?

    /// User's timezone identifier
    var timezoneIdentifier: String

    // MARK: - Initialization

    init(
        id: String,
        email: String,
        displayName: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        profilePictureURL: URL? = nil,
        alpacaAccountId: String? = nil,
        familyId: String? = nil,
        preferredCurrency: String = "USD",
        notificationsEnabled: Bool = true,
        biometricEnabled: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        subscriptionTier: SubscriptionTier = .free,
        subscriptionExpiresAt: Date? = nil,
        timezoneIdentifier: String = TimeZone.current.identifier
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.firstName = firstName
        self.lastName = lastName
        self.profilePictureURL = profilePictureURL
        self.alpacaAccountId = alpacaAccountId
        self.familyId = familyId
        self.preferredCurrency = preferredCurrency
        self.notificationsEnabled = notificationsEnabled
        self.biometricEnabled = biometricEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.subscriptionTier = subscriptionTier
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.timezoneIdentifier = timezoneIdentifier
    }

    // MARK: - Computed Properties

    /// User's display name or email as fallback
    var displayNameOrEmail: String {
        displayName ?? email
    }

    /// User's initials for avatar
    var initials: String {
        if let displayName = displayName, !displayName.isEmpty {
            let components = displayName.components(separatedBy: " ")
            let firstInitial = components.first?.first.map(String.init) ?? ""
            let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
            return (firstInitial + lastInitial).uppercased()
        }
        return String(email.prefix(2)).uppercased()
    }

    /// User's timezone
    var timezone: TimeZone {
        TimeZone(identifier: timezoneIdentifier) ?? .current
    }

    /// Whether user has an active subscription
    var hasActiveSubscription: Bool {
        switch subscriptionTier {
        case .free:
            return false
        case .premium, .family:
            guard let expiresAt = subscriptionExpiresAt else { return true }
            return expiresAt > Date()
        }
    }

    /// Whether user can access premium features
    var canAccessPremiumFeatures: Bool {
        subscriptionTier != .free && hasActiveSubscription
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case firstName
        case lastName
        case profilePictureURL = "profilePictureUrl"
        case alpacaAccountId
        case familyId
        case preferredCurrency
        case notificationsEnabled
        case biometricEnabled
        case createdAt
        case updatedAt
        case subscriptionTier
        case subscriptionExpiresAt
        case timezoneIdentifier
    }
}

// MARK: - Subscription Tier

/// User subscription levels
enum SubscriptionTier: String, Codable, Sendable, CaseIterable {
    case free
    case premium
    case family

    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        case .family:
            return "Family"
        }
    }

    var description: String {
        switch self {
        case .free:
            return "Basic features with limited portfolios"
        case .premium:
            return "Full access to all features"
        case .family:
            return "Premium features for the whole family"
        }
    }

    /// Maximum number of portfolios allowed
    var maxPortfolios: Int {
        switch self {
        case .free:
            return 1
        case .premium:
            return 10
        case .family:
            return 25
        }
    }

    /// Maximum number of goals allowed
    var maxGoals: Int {
        switch self {
        case .free:
            return 3
        case .premium:
            return 50
        case .family:
            return 100
        }
    }

    /// Whether DCA automation is available
    var dcaAutomationEnabled: Bool {
        self != .free
    }

    /// Whether AI insights are available
    var aiInsightsEnabled: Bool {
        self != .free
    }

    /// Whether family accounts are available
    var familyAccountsEnabled: Bool {
        self == .family
    }

    /// Maximum number of family members
    var maxFamilyMembers: Int {
        switch self {
        case .free, .premium:
            return 0
        case .family:
            return 5
        }
    }
}

// MARK: - User Settings

/// User-specific settings
struct UserSettings: Codable, Sendable, Equatable {
    var preferredCurrency: String
    var notificationsEnabled: Bool
    var biometricEnabled: Bool
    var timezoneIdentifier: String
    var theme: AppTheme
    var hapticFeedbackEnabled: Bool
    var showBalances: Bool

    init(
        preferredCurrency: String = "USD",
        notificationsEnabled: Bool = true,
        biometricEnabled: Bool = false,
        timezoneIdentifier: String = TimeZone.current.identifier,
        theme: AppTheme = .system,
        hapticFeedbackEnabled: Bool = true,
        showBalances: Bool = true
    ) {
        self.preferredCurrency = preferredCurrency
        self.notificationsEnabled = notificationsEnabled
        self.biometricEnabled = biometricEnabled
        self.timezoneIdentifier = timezoneIdentifier
        self.theme = theme
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.showBalances = showBalances
    }
}

/// App theme options
enum AppTheme: String, Codable, Sendable, CaseIterable {
    case light
    case dark
    case system

    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }

    var description: String {
        switch self {
        case .light:
            return "Always use light mode"
        case .dark:
            return "Always use dark mode"
        case .system:
            return "Match system settings"
        }
    }

    var iconName: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "circle.lefthalf.filled"
        }
    }

    var iconColor: Color {
        switch self {
        case .light:
            return .orange
        case .dark:
            return .indigo
        case .system:
            return .gray
        }
    }
}

// MARK: - User Notification Settings

/// Notification preferences
struct NotificationSettings: Codable, Sendable, Equatable {
    var dcaReminders: Bool
    var goalProgress: Bool
    var portfolioAlerts: Bool
    var marketNews: Bool
    var aiInsights: Bool
    var weeklyDigest: Bool

    init(
        dcaReminders: Bool = true,
        goalProgress: Bool = true,
        portfolioAlerts: Bool = true,
        marketNews: Bool = false,
        aiInsights: Bool = true,
        weeklyDigest: Bool = true
    ) {
        self.dcaReminders = dcaReminders
        self.goalProgress = goalProgress
        self.portfolioAlerts = portfolioAlerts
        self.marketNews = marketNews
        self.aiInsights = aiInsights
        self.weeklyDigest = weeklyDigest
    }

    static var `default`: NotificationSettings {
        NotificationSettings()
    }

    static var allEnabled: NotificationSettings {
        NotificationSettings(
            dcaReminders: true,
            goalProgress: true,
            portfolioAlerts: true,
            marketNews: true,
            aiInsights: true,
            weeklyDigest: true
        )
    }

    static var allDisabled: NotificationSettings {
        NotificationSettings(
            dcaReminders: false,
            goalProgress: false,
            portfolioAlerts: false,
            marketNews: false,
            aiInsights: false,
            weeklyDigest: false
        )
    }
}
