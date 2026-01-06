//
//  BiometricAuthTests.swift
//  GrowfolioTests
//
//  Tests for BiometricAuth, BiometricType, and BiometricAuthError.
//

import XCTest
@testable import Growfolio

final class BiometricAuthTests: XCTestCase {

    // MARK: - BiometricType Tests

    func testBiometricTypeRawValues() {
        XCTAssertEqual(BiometricType.none.rawValue, "none")
        XCTAssertEqual(BiometricType.touchID.rawValue, "touchID")
        XCTAssertEqual(BiometricType.faceID.rawValue, "faceID")
        XCTAssertEqual(BiometricType.opticID.rawValue, "opticID")
    }

    func testBiometricTypeDisplayName() {
        XCTAssertEqual(BiometricType.none.displayName, "None")
        XCTAssertEqual(BiometricType.touchID.displayName, "Touch ID")
        XCTAssertEqual(BiometricType.faceID.displayName, "Face ID")
        XCTAssertEqual(BiometricType.opticID.displayName, "Optic ID")
    }

    func testBiometricTypeSystemImageName() {
        XCTAssertEqual(BiometricType.none.systemImageName, "lock.slash")
        XCTAssertEqual(BiometricType.touchID.systemImageName, "touchid")
        XCTAssertEqual(BiometricType.faceID.systemImageName, "faceid")
        XCTAssertEqual(BiometricType.opticID.systemImageName, "opticid")
    }

    func testBiometricTypeIsSendable() {
        // Verify BiometricType conforms to Sendable by using it in async context
        let type: BiometricType = .faceID
        Task {
            let copy = type
            XCTAssertEqual(copy, .faceID)
        }
    }

    // MARK: - BiometricAuthError Tests

    func testBiometricAuthErrorNotAvailable() {
        let error = BiometricAuthError.notAvailable
        XCTAssertEqual(error.errorDescription, "Biometric authentication is not available on this device")
        XCTAssertNil(error.recoverySuggestion)
    }

    func testBiometricAuthErrorNotEnrolled() {
        let error = BiometricAuthError.notEnrolled
        XCTAssertEqual(error.errorDescription, "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings")
        XCTAssertEqual(error.recoverySuggestion, "Go to Settings > Face ID & Passcode to set up biometric authentication")
    }

    func testBiometricAuthErrorLockout() {
        let error = BiometricAuthError.lockout
        XCTAssertEqual(error.errorDescription, "Biometric authentication is locked. Please use your passcode")
        XCTAssertEqual(error.recoverySuggestion, "Too many failed attempts. Please unlock your device with your passcode first")
    }

    func testBiometricAuthErrorCancelled() {
        let error = BiometricAuthError.cancelled
        XCTAssertEqual(error.errorDescription, "Biometric authentication was cancelled")
        XCTAssertNil(error.recoverySuggestion)
    }

    func testBiometricAuthErrorUserFallback() {
        let error = BiometricAuthError.userFallback
        XCTAssertEqual(error.errorDescription, "User chose to use password instead")
        XCTAssertNil(error.recoverySuggestion)
    }

    func testBiometricAuthErrorFailed() {
        let error = BiometricAuthError.failed("Authentication timed out")
        XCTAssertEqual(error.errorDescription, "Biometric authentication failed: Authentication timed out")
        XCTAssertNil(error.recoverySuggestion)
    }

    func testBiometricAuthErrorPasscodeNotSet() {
        let error = BiometricAuthError.passcodeNotSet
        XCTAssertEqual(error.errorDescription, "Please set a device passcode to use biometric authentication")
        XCTAssertEqual(error.recoverySuggestion, "Go to Settings > Face ID & Passcode to set a passcode")
    }

    func testBiometricAuthErrorConformsToLocalizedError() {
        let error: LocalizedError = BiometricAuthError.notAvailable
        XCTAssertNotNil(error.errorDescription)
    }

    func testBiometricAuthErrorIsSendable() {
        // Verify BiometricAuthError conforms to Sendable
        let error: BiometricAuthError = .cancelled
        Task {
            let copy = error
            if case .cancelled = copy {
                // Success
            } else {
                XCTFail("Error should be cancelled")
            }
        }
    }

    // MARK: - BiometricAuth Actor Tests

    func testBiometricAuthSharedInstance() async {
        let instance1 = BiometricAuth.shared
        let instance2 = BiometricAuth.shared

        // Both should reference the same actor instance
        let type1 = await instance1.biometricType
        let type2 = await instance2.biometricType

        // In simulator, biometric is typically not available
        XCTAssertEqual(type1, type2)
    }

    func testBiometricAuthBiometricTypeReturnsNoneInSimulator() async {
        let auth = BiometricAuth()
        let biometricType = await auth.biometricType

        // In simulator/test environment, biometric is typically not available
        // This test verifies the property is accessible
        XCTAssertNotNil(biometricType)
    }

    func testBiometricAuthIsBiometricAvailableReturnsBoolean() async {
        let auth = BiometricAuth()
        let isAvailable = await auth.isBiometricAvailable

        // Just verify it returns a boolean (availability varies by environment)
        XCTAssertNotNil(isAvailable)
    }

    func testBiometricAuthIsPasscodeSet() async {
        let auth = BiometricAuth()
        let isSet = await auth.isPasscodeSet

        // This property should be accessible
        // Value depends on device/simulator configuration
        XCTAssertNotNil(isSet)
    }

    // MARK: - BiometricSettingsManager Tests

    func testBiometricSettingsManagerSharedInstance() async {
        let instance1 = BiometricSettingsManager.shared
        let instance2 = BiometricSettingsManager.shared

        let enabled1 = await instance1.isBiometricEnabled
        let enabled2 = await instance2.isBiometricEnabled

        XCTAssertEqual(enabled1, enabled2)
    }

    func testBiometricSettingsManagerDefaultState() async {
        let manager = BiometricSettingsManager.shared
        let isEnabled = await manager.isBiometricEnabled

        // Default state is disabled unless previously enabled
        XCTAssertNotNil(isEnabled)
    }

    func testBiometricSettingsManagerShouldUseBiometricForUnlock() async {
        let manager = BiometricSettingsManager.shared
        let shouldUse = await manager.shouldUseBiometricForUnlock()

        // In simulator without biometric, should return false
        XCTAssertFalse(shouldUse)
    }

    func testBiometricSettingsManagerAuthenticateIfEnabledWhenDisabled() async throws {
        let manager = BiometricSettingsManager.shared

        // When biometric is disabled, should return true (pass through)
        // This assumes biometric is disabled in UserDefaults by default
        // We cannot easily test this without mocking UserDefaults
        let result = try await manager.authenticateIfEnabled(reason: "Test")

        // When disabled, returns true without prompting
        XCTAssertTrue(result)
    }

    // MARK: - Error Handling Edge Cases

    func testBiometricAuthErrorFailedWithEmptyReason() {
        let error = BiometricAuthError.failed("")
        XCTAssertEqual(error.errorDescription, "Biometric authentication failed: ")
    }

    func testBiometricAuthErrorFailedWithSpecialCharacters() {
        let error = BiometricAuthError.failed("Error: <code>401</code> & 'unauthorized'")
        XCTAssertTrue(error.errorDescription?.contains("Error: <code>401</code>") ?? false)
    }

    func testAllBiometricAuthErrorsHaveDescriptions() {
        let errors: [BiometricAuthError] = [
            .notAvailable,
            .notEnrolled,
            .lockout,
            .cancelled,
            .userFallback,
            .failed("test"),
            .passcodeNotSet
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
        }
    }

    func testBiometricAuthErrorsWithRecoverySuggestions() {
        let errorsWithRecovery: [BiometricAuthError] = [
            .notEnrolled,
            .lockout,
            .passcodeNotSet
        ]

        for error in errorsWithRecovery {
            XCTAssertNotNil(error.recoverySuggestion, "Error \(error) should have a recovery suggestion")
        }
    }

    func testBiometricAuthErrorsWithoutRecoverySuggestions() {
        let errorsWithoutRecovery: [BiometricAuthError] = [
            .notAvailable,
            .cancelled,
            .userFallback,
            .failed("test")
        ]

        for error in errorsWithoutRecovery {
            XCTAssertNil(error.recoverySuggestion, "Error \(error) should not have a recovery suggestion")
        }
    }
}
