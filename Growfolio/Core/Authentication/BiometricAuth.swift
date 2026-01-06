//
//  BiometricAuth.swift
//  Growfolio
//
//  Biometric authentication using Face ID and Touch ID.
//

import Foundation
import LocalAuthentication

// MARK: - Biometric Auth Protocol

/// Protocol for biometric authentication
protocol BiometricAuthProtocol: Sendable {
    var biometricType: BiometricType { get async }
    var isBiometricAvailable: Bool { get async }
    func authenticate(reason: String) async throws -> Bool
}

// MARK: - Biometric Type

enum BiometricType: String, Sendable {
    case none
    case touchID
    case faceID
    case opticID

    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        }
    }

    var systemImageName: String {
        switch self {
        case .none:
            return "lock.slash"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .opticID:
            return "opticid"
        }
    }
}

// MARK: - Biometric Auth Error

enum BiometricAuthError: LocalizedError, Sendable {
    case notAvailable
    case notEnrolled
    case lockout
    case cancelled
    case userFallback
    case failed(String)
    case passcodeNotSet

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings"
        case .lockout:
            return "Biometric authentication is locked. Please use your passcode"
        case .cancelled:
            return "Biometric authentication was cancelled"
        case .userFallback:
            return "User chose to use password instead"
        case .failed(let reason):
            return "Biometric authentication failed: \(reason)"
        case .passcodeNotSet:
            return "Please set a device passcode to use biometric authentication"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notEnrolled:
            return "Go to Settings > Face ID & Passcode to set up biometric authentication"
        case .lockout:
            return "Too many failed attempts. Please unlock your device with your passcode first"
        case .passcodeNotSet:
            return "Go to Settings > Face ID & Passcode to set a passcode"
        default:
            return nil
        }
    }
}

// MARK: - Biometric Auth Service

/// Service for handling biometric authentication
actor BiometricAuth: BiometricAuthProtocol {

    // MARK: - Singleton

    static let shared = BiometricAuth()

    // MARK: - Properties

    private let context: LAContext

    // MARK: - Initialization

    init() {
        self.context = LAContext()
    }

    // MARK: - BiometricAuthProtocol

    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }

    var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate(reason: String = Constants.Auth.biometricPrompt) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        context.localizedCancelTitle = "Cancel"

        var error: NSError?

        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw mapLAError(error)
        }

        // Perform authentication
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let authError as LAError {
            throw mapLAError(authError)
        } catch {
            throw BiometricAuthError.failed(error.localizedDescription)
        }
    }

    // MARK: - Additional Methods

    /// Authenticate with fallback to device passcode
    func authenticateWithPasscodeFallback(reason: String = Constants.Auth.biometricPrompt) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        context.localizedCancelTitle = "Cancel"

        var error: NSError?

        // Check if device owner authentication is available (biometric or passcode)
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw mapLAError(error)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success
        } catch let authError as LAError {
            throw mapLAError(authError)
        } catch {
            throw BiometricAuthError.failed(error.localizedDescription)
        }
    }

    /// Invalidate the current authentication context
    func invalidateContext() {
        context.invalidate()
    }

    /// Check if device has passcode set
    var isPasscodeSet: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    // MARK: - Private Methods

    private func mapLAError(_ error: NSError?) -> BiometricAuthError {
        guard let error = error else {
            return .notAvailable
        }

        switch LAError.Code(rawValue: error.code) {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .userCancel:
            return .cancelled
        case .userFallback:
            return .userFallback
        case .passcodeNotSet:
            return .passcodeNotSet
        case .authenticationFailed:
            return .failed("Authentication did not succeed")
        default:
            return .failed(error.localizedDescription)
        }
    }

    private func mapLAError(_ error: LAError) -> BiometricAuthError {
        switch error.code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        case .userCancel:
            return .cancelled
        case .userFallback:
            return .userFallback
        case .passcodeNotSet:
            return .passcodeNotSet
        case .authenticationFailed:
            return .failed("Authentication did not succeed")
        default:
            return .failed(error.localizedDescription)
        }
    }
}

// MARK: - Biometric Settings Manager

/// Manager for biometric authentication settings
actor BiometricSettingsManager {

    // MARK: - Singleton

    static let shared = BiometricSettingsManager()

    // MARK: - Properties

    private let defaults = UserDefaults.standard
    private let biometricAuth = BiometricAuth.shared

    private var isBiometricEnabledKey: String { Constants.StorageKeys.biometricEnabled }

    // MARK: - Public Methods

    var isBiometricEnabled: Bool {
        defaults.bool(forKey: isBiometricEnabledKey)
    }

    func setBiometricEnabled(_ enabled: Bool) async throws {
        // If enabling, verify biometric is available and authenticate
        if enabled {
            guard await biometricAuth.isBiometricAvailable else {
                throw BiometricAuthError.notAvailable
            }

            // Require authentication to enable biometric
            _ = try await biometricAuth.authenticate(reason: "Enable biometric authentication")
        }

        defaults.set(enabled, forKey: isBiometricEnabledKey)
    }

    /// Check if biometric authentication should be used for app unlock
    func shouldUseBiometricForUnlock() async -> Bool {
        guard isBiometricEnabled else { return false }
        return await biometricAuth.isBiometricAvailable
    }

    /// Perform biometric authentication if enabled
    func authenticateIfEnabled(reason: String = Constants.Auth.biometricPrompt) async throws -> Bool {
        guard isBiometricEnabled else { return true }
        guard await biometricAuth.isBiometricAvailable else { return true }

        return try await biometricAuth.authenticate(reason: reason)
    }
}
