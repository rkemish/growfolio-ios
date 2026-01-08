//
//  Environment.swift
//  Growfolio
//
//  Environment configuration for different build configurations.
//

import Foundation

/// Application environment enumeration
enum AppEnvironment: String, CaseIterable, Sendable {
    case development
    case staging
    case production

    /// Current environment based on build configuration
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }

    /// Base API URL for the current environment
    var apiBaseURL: URL {
        switch self {
        case .development:
            return URL(string: "http://localhost:3000/api")!
        case .staging:
            return URL(string: "https://staging-api.growfolio.app/api")!
        case .production:
            return URL(string: "https://api.growfolio.app/api")!
        }
    }

    /// WebSocket URL for real-time updates
    var websocketURL: URL {
        switch self {
        case .development:
            return URL(string: "ws://localhost:3000/api/v1/ws")!
        case .staging:
            return URL(string: "wss://staging-api.growfolio.app/api/v1/ws")!
        case .production:
            return URL(string: "wss://api.growfolio.app/api/v1/ws")!
        }
    }

    /// Whether verbose logging is enabled
    var isLoggingEnabled: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }

    /// Whether to use mock data
    var useMockData: Bool {
        switch self {
        case .development:
            // In DEBUG, default to mock mode (can be toggled in Settings)
            // Check launch arg first, then UserDefaults, default to true
            if ProcessInfo.processInfo.arguments.contains("--use-mock-data") {
                return true
            }
            if ProcessInfo.processInfo.arguments.contains("--no-mock-data") {
                return false
            }
            return UserDefaults.standard.object(forKey: Constants.StorageKeys.useMockData) as? Bool ?? true
        case .staging, .production:
            return false
        }
    }

    /// Minimum log level for the environment
    var minimumLogLevel: LogLevel {
        switch self {
        case .development:
            return .debug
        case .staging:
            return .info
        case .production:
            return .warning
        }
    }

    /// Analytics enabled state
    var analyticsEnabled: Bool {
        switch self {
        case .development:
            return false
        case .staging, .production:
            return true
        }
    }

    /// Crash reporting enabled state
    var crashReportingEnabled: Bool {
        switch self {
        case .development:
            return false
        case .staging, .production:
            return true
        }
    }

    /// Display name for the environment
    var displayName: String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }

    /// SSL pinning enabled
    var sslPinningEnabled: Bool {
        switch self {
        case .development:
            return false
        case .staging, .production:
            return true
        }
    }

    /// Certificate hashes for SSL pinning
    var certificatePins: [String] {
        switch self {
        case .development:
            return []
        case .staging:
            return ["sha256/staging_certificate_hash_placeholder"]
        case .production:
            return [
                "sha256/primary_certificate_hash_placeholder",
                "sha256/backup_certificate_hash_placeholder"
            ]
        }
    }
}

// MARK: - Log Level

enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Environment Configuration

struct EnvironmentConfiguration: Sendable {
    let environment: AppEnvironment
    let apiBaseURL: URL
    let websocketURL: URL

    static var current: EnvironmentConfiguration {
        let env = AppEnvironment.current
        return EnvironmentConfiguration(
            environment: env,
            apiBaseURL: env.apiBaseURL,
            websocketURL: env.websocketURL
        )
    }
}

// MARK: - Feature Flags

struct FeatureFlags: Sendable {
    nonisolated(unsafe) static var shared = FeatureFlags()

    private init() {}

    /// Whether the AI Insights feature is enabled
    var aiInsightsEnabled: Bool {
        switch AppEnvironment.current {
        case .development, .staging:
            return true
        case .production:
            // Could be controlled by remote config
            return true
        }
    }

    /// Whether family accounts feature is enabled
    var familyAccountsEnabled: Bool {
        true
    }

    /// Whether biometric authentication is enabled
    var biometricAuthEnabled: Bool {
        true
    }

    /// Whether dark mode is supported
    var darkModeSupported: Bool {
        true
    }

    /// Whether push notifications are enabled
    var pushNotificationsEnabled: Bool {
        true
    }

    /// Whether background refresh is enabled
    var backgroundRefreshEnabled: Bool {
        true
    }
}
