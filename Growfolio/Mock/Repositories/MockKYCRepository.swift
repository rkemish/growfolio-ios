//
//  MockKYCRepository.swift
//  Growfolio
//
//  Mock implementation of KYCRepositoryProtocol for demo mode.
//

import Foundation

/// Mock implementation of KYCRepositoryProtocol
final class MockKYCRepository: KYCRepositoryProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    var submissionResponseToReturn: KYCSubmissionResponse?
    var statusResponseToReturn: KYCSubmissionResponse?
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var submitKYCCalled = false
    var lastSubmittedKYCData: KYCData?
    var lastSubmittedEmail: String?
    var getKYCStatusCalled = false

    // MARK: - Properties

    private let config = MockConfiguration.shared

    // MARK: - Initialization

    init() {
        // Set default responses
        submissionResponseToReturn = KYCSubmissionResponse(
            accountId: "mock_account_123",
            status: .pending,
            message: "KYC submission received and is under review"
        )

        statusResponseToReturn = KYCSubmissionResponse(
            accountId: "mock_account_123",
            status: .approved,
            message: "KYC verification completed successfully"
        )
    }

    // MARK: - Reset

    func reset() {
        submissionResponseToReturn = KYCSubmissionResponse(
            accountId: "mock_account_123",
            status: .pending,
            message: "KYC submission received and is under review"
        )
        statusResponseToReturn = KYCSubmissionResponse(
            accountId: "mock_account_123",
            status: .approved,
            message: "KYC verification completed successfully"
        )
        errorToThrow = nil
        submitKYCCalled = false
        lastSubmittedKYCData = nil
        lastSubmittedEmail = nil
        getKYCStatusCalled = false
    }

    // MARK: - KYCRepositoryProtocol Implementation

    func submitKYC(data: KYCData, email: String) async throws -> KYCSubmissionResponse {
        try await simulateNetwork()

        submitKYCCalled = true
        lastSubmittedKYCData = data
        lastSubmittedEmail = email

        if let error = errorToThrow {
            throw error
        }

        guard let response = submissionResponseToReturn else {
            throw KYCRepositoryError.submissionFailed("Mock response not configured")
        }

        return response
    }

    func getKYCStatus() async throws -> KYCSubmissionResponse {
        try await simulateNetwork()

        getKYCStatusCalled = true

        if let error = errorToThrow {
            throw error
        }

        guard let response = statusResponseToReturn else {
            throw KYCRepositoryError.statusCheckFailed
        }

        return response
    }

    // MARK: - Private Methods

    private func simulateNetwork() async throws {
        try await config.simulateNetworkDelay()
        try config.maybeThrowSimulatedError()
    }
}

// MARK: - Convenience Methods

extension MockKYCRepository {

    /// Configure the mock to simulate a successful KYC submission
    func simulateSuccessfulSubmission(accountId: String = "mock_account_123") {
        submissionResponseToReturn = KYCSubmissionResponse(
            accountId: accountId,
            status: .pending,
            message: "KYC submission received and is under review"
        )
    }

    /// Configure the mock to simulate an approved KYC status
    func simulateApprovedStatus(accountId: String = "mock_account_123") {
        statusResponseToReturn = KYCSubmissionResponse(
            accountId: accountId,
            status: .approved,
            message: "KYC verification completed successfully"
        )
    }

    /// Configure the mock to simulate a rejected KYC status
    func simulateRejectedStatus(accountId: String = "mock_account_123", reason: String = "Invalid documentation provided") {
        statusResponseToReturn = KYCSubmissionResponse(
            accountId: accountId,
            status: .rejected,
            message: reason
        )
    }

    /// Configure the mock to simulate action required status
    func simulateActionRequiredStatus(accountId: String = "mock_account_123", message: String = "Additional documentation required") {
        statusResponseToReturn = KYCSubmissionResponse(
            accountId: accountId,
            status: .actionRequired,
            message: message
        )
    }

    /// Configure the mock to throw an error on next call
    func simulateError(_ error: Error) {
        errorToThrow = error
    }
}
