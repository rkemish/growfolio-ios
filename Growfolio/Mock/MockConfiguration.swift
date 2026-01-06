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

    /// Simulate network delay if configured
    func simulateNetworkDelay() async throws {
        if networkDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
    }

    /// Potentially throw a simulated error based on error rate
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
