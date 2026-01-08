//
//  MockConfiguration.swift
//  Growfolio
//
//  Central configuration for mock mode behavior.
//

import Foundation

/// Demo persona scenarios for mock data generation
enum DemoPersona: String, CaseIterable, Sendable {
    case newUser
    case activeInvestor
    case familyAccount

    var displayName: String {
        switch self {
        case .newUser:
            return "New User"
        case .activeInvestor:
            return "Active Investor"
        case .familyAccount:
            return "Family Account"
        }
    }

    var description: String {
        switch self {
        case .newUser:
            return "Empty portfolios, no schedules, guided setup"
        case .activeInvestor:
            return "Rich data, multiple portfolios, DCA schedules"
        case .familyAccount:
            return "Family features with shared goals"
        }
    }
}

/// Central configuration for mock mode
@Observable
final class MockConfiguration: @unchecked Sendable {

    // MARK: - Singleton

    static let shared = MockConfiguration()

    // MARK: - Properties

    /// Whether mock mode is explicitly enabled (overrides environment check)
    private var _isEnabled: Bool?

    /// Whether mock mode is active
    var isEnabled: Bool {
        get { _isEnabled ?? AppEnvironment.current.useMockData }
        set { _isEnabled = newValue }
    }

    /// Current demo persona (affects seed data)
    var demoPersona: DemoPersona = .activeInvestor

    /// Simulated network delay in seconds (0 for instant)
    var networkDelay: TimeInterval = 0.3

    /// Error simulation rate (0.0 to 1.0)
    var errorRate: Double = 0

    /// Whether to simulate realistic price fluctuations
    var simulatePriceFluctuations: Bool = true

    // MARK: - Initialization

    private init() {}

    // MARK: - Methods

    /// Reset configuration to defaults
    func reset() {
        _isEnabled = nil
        demoPersona = .activeInvestor
        networkDelay = 0.3
        errorRate = 0
        simulatePriceFluctuations = true
    }

    /// Configure for SwiftUI previews (instant, no errors)
    func configureForPreviews() {
        _isEnabled = true
        networkDelay = 0
        errorRate = 0
    }

    /// Configure for UI testing
    func configureForTesting() {
        _isEnabled = true
        networkDelay = 0.1
        errorRate = 0
    }

    // MARK: - Launch Arguments

    /// Whether UI testing mode is enabled via launch arguments
    private(set) var isUITesting: Bool = false

    /// Whether to reset onboarding state
    private(set) var shouldResetOnboarding: Bool = false

    /// Whether to skip onboarding and go directly to auth
    private(set) var shouldSkipOnboarding: Bool = false

    /// Whether to skip directly to main app (bypass onboarding, auth, KYC)
    private(set) var shouldSkipToMain: Bool = false

    /// Process launch arguments for UI testing support
    /// Call this early in app startup (e.g., AppDelegate.didFinishLaunching)
    func processLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments

        // Check for UI testing mode
        if arguments.contains("--uitesting") {
            isUITesting = true
            configureForTesting()
        }

        // Check for mock mode
        if arguments.contains("--mock-mode") {
            _isEnabled = true
        }

        // Check for onboarding reset
        if arguments.contains("--reset-onboarding") {
            shouldResetOnboarding = true
        }

        // Check for skip onboarding
        if arguments.contains("--skip-onboarding") {
            shouldSkipOnboarding = true
        }

        // Check for skip to main
        if arguments.contains("--skip-to-main") {
            shouldSkipToMain = true
            _isEnabled = true  // Skip to main requires mock mode
        }
    }

    /// Simulate network delay if configured
    /// Makes mock repositories feel more realistic and helps catch race conditions
    func simulateNetworkDelay() async throws {
        if networkDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
    }

    /// Potentially throw a simulated error based on error rate
    /// Useful for testing error handling UI without actually breaking things
    /// errorRate of 0.1 = 10% of requests fail
    func maybeThrowSimulatedError() throws {
        if errorRate > 0 && Double.random(in: 0...1) < errorRate {
            throw MockError.simulatedNetworkError
        }
    }
}

// MARK: - Mock Error

/// Errors that can be thrown by mock implementations
enum MockError: LocalizedError {
    case simulatedNetworkError
    case notImplemented
    case entityNotFound(type: String, id: String)
    case invalidOperation(message: String)

    var errorDescription: String? {
        switch self {
        case .simulatedNetworkError:
            return "Simulated network error"
        case .notImplemented:
            return "This mock method is not yet implemented"
        case .entityNotFound(let type, let id):
            return "\(type) with ID '\(id)' not found"
        case .invalidOperation(let message):
            return message
        }
    }
}
