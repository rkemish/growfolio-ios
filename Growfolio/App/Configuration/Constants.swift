//
//  Constants.swift
//  Growfolio
//
//  Application-wide constants and configuration values.
//

import Foundation

/// Application-wide constants
enum Constants {

    // MARK: - API Configuration

    enum API {
        /// Current API version
        static let version = "v1"

        /// Default request timeout in seconds
        static let requestTimeout: TimeInterval = 30

        /// Upload request timeout in seconds
        static let uploadTimeout: TimeInterval = 120

        /// Maximum number of retry attempts for failed requests
        static let maxRetryAttempts = 3

        /// Delay between retry attempts in seconds
        static let retryDelay: TimeInterval = 1.0

        /// Maximum concurrent API requests
        static let maxConcurrentRequests = 4

        /// Default page size for paginated requests
        static let defaultPageSize = 20

        /// Maximum page size for paginated requests
        static let maxPageSize = 100
    }

    // MARK: - Cache Configuration

    enum Cache {
        /// Portfolio data cache duration in seconds
        static let portfolioCacheDuration: TimeInterval = 300  // 5 minutes

        /// Stock price cache duration in seconds
        static let stockPriceCacheDuration: TimeInterval = 60  // 1 minute

        /// User profile cache duration in seconds
        static let userProfileCacheDuration: TimeInterval = 3600  // 1 hour

        /// Maximum cache size in bytes
        static let maxCacheSize = 50 * 1024 * 1024  // 50 MB

        /// Cache directory name
        static let cacheDirectoryName = "GrowfolioCache"
    }

    // MARK: - Authentication

    enum Auth {
        /// Token refresh threshold in seconds before expiry
        static let tokenRefreshThreshold: TimeInterval = 300  // 5 minutes

        /// Biometric authentication prompt text
        static let biometricPrompt = "Authenticate to access Growfolio"

        /// Maximum failed login attempts before lockout
        static let maxLoginAttempts = 5

        /// Lockout duration in seconds
        static let lockoutDuration: TimeInterval = 300  // 5 minutes

        /// Keychain service identifier
        static let keychainService = "com.growfolio.app"

        /// Access token keychain key
        static let accessTokenKey = "access_token"

        /// Refresh token keychain key
        static let refreshTokenKey = "refresh_token"

        /// ID token keychain key
        static let idTokenKey = "id_token"
    }

    // MARK: - UI Configuration

    enum UI {
        /// Standard animation duration
        static let animationDuration: TimeInterval = 0.3

        /// Long animation duration
        static let longAnimationDuration: TimeInterval = 0.5

        /// Standard corner radius
        static let cornerRadius: CGFloat = 12

        /// Large corner radius
        static let largeCornerRadius: CGFloat = 20

        /// Standard padding
        static let standardPadding: CGFloat = 16

        /// Compact padding
        static let compactPadding: CGFloat = 8

        /// Maximum content width for iPad
        static let maxContentWidth: CGFloat = 600

        /// Chart default height
        static let chartHeight: CGFloat = 200

        /// Card minimum height
        static let cardMinHeight: CGFloat = 100

        // MARK: - iPad Layout

        /// iPad sidebar width
        static let sidebarWidth: CGFloat = 320

        /// Minimum detail column width
        static let minDetailWidth: CGFloat = 400

        /// Grid column count for compact size class (iPhone)
        static let compactGridColumns = 2

        /// Grid column count for regular size class (iPad)
        static let regularGridColumns = 3
    }

    // MARK: - Validation

    enum Validation {
        /// Minimum goal target amount
        static let minGoalTarget: Decimal = 100

        /// Maximum goal target amount
        static let maxGoalTarget: Decimal = 100_000_000

        /// Minimum DCA amount
        static let minDCAAmount: Decimal = 1

        /// Maximum DCA amount
        static let maxDCAAmount: Decimal = 1_000_000

        /// Minimum portfolio name length
        static let minPortfolioNameLength = 1

        /// Maximum portfolio name length
        static let maxPortfolioNameLength = 50

        /// Maximum goal name length
        static let maxGoalNameLength = 100

        /// Maximum notes length
        static let maxNotesLength = 500
    }

    // MARK: - Date Formats

    enum DateFormat {
        /// ISO 8601 format for API communication
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        /// Date only format
        static let dateOnly = "yyyy-MM-dd"

        /// Display format for dates
        static let displayDate = "MMM d, yyyy"

        /// Display format for date and time
        static let displayDateTime = "MMM d, yyyy 'at' h:mm a"

        /// Short display format
        static let shortDate = "MMM d"

        /// Month and year format
        static let monthYear = "MMMM yyyy"
    }

    // MARK: - Notifications

    enum Notifications {
        /// DCA reminder notification category
        static let dcaReminderCategory = "DCA_REMINDER"

        /// Goal progress notification category
        static let goalProgressCategory = "GOAL_PROGRESS"

        /// Portfolio alert notification category
        static let portfolioAlertCategory = "PORTFOLIO_ALERT"

        /// AI insight notification category
        static let aiInsightCategory = "AI_INSIGHT"
    }

    // MARK: - Analytics Events

    enum Analytics {
        /// User signed in event
        static let signedIn = "user_signed_in"

        /// User signed out event
        static let signedOut = "user_signed_out"

        /// Goal created event
        static let goalCreated = "goal_created"

        /// DCA scheduled event
        static let dcaScheduled = "dca_scheduled"

        /// Portfolio viewed event
        static let portfolioViewed = "portfolio_viewed"

        /// Stock searched event
        static let stockSearched = "stock_searched"

        /// Transaction recorded event
        static let transactionRecorded = "transaction_recorded"
    }

    // MARK: - App Info

    enum App {
        /// App bundle identifier
        static let bundleIdentifier = "com.growfolio.app"

        /// App Store URL
        static let appStoreURL = URL(string: "https://apps.apple.com/app/growfolio/id0000000000")!

        /// Support email
        static let supportEmail = "support@growfolio.app"

        /// Privacy policy URL
        static let privacyPolicyURL = URL(string: "https://growfolio.app/privacy")!

        /// Terms of service URL
        static let termsOfServiceURL = URL(string: "https://growfolio.app/terms")!

        /// Help center URL
        static let helpCenterURL = URL(string: "https://help.growfolio.app")!

        /// Current app version
        static var version: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        }

        /// Current build number
        static var buildNumber: String {
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        }

        /// Full version string
        static var fullVersion: String {
            "\(version) (\(buildNumber))"
        }
    }

    // MARK: - Storage Keys

    enum StorageKeys {
        /// User defaults suite name
        static let suiteName = "group.com.growfolio.app"

        /// Has completed onboarding key
        static let hasCompletedOnboarding = "hasCompletedOnboarding"

        /// Selected theme key
        static let selectedTheme = "selectedTheme"

        /// Biometric auth enabled key
        static let biometricEnabled = "biometricEnabled"

        /// Last sync timestamp key
        static let lastSyncTimestamp = "lastSyncTimestamp"

        /// Preferred currency key
        static let preferredCurrency = "preferredCurrency"

        /// Notification settings key
        static let notificationSettings = "notificationSettings"

        /// Mock mode toggle key
        static let useMockData = "useMockData"
    }
}
