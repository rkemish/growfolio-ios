//
//  KYCRepository.swift
//  Growfolio
//
//  Repository for KYC submission and status operations.
//

import Foundation

protocol KYCRepositoryProtocol: Sendable {
    func submitKYC(data: KYCData, email: String) async throws -> KYCSubmissionResponse
    func getKYCStatus() async throws -> KYCSubmissionResponse
}

final class KYCRepository: KYCRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let apiClient: APIClientProtocol

    // MARK: - Initialization

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - KYC Operations

    func submitKYC(data: KYCData, email: String) async throws -> KYCSubmissionResponse {
        let ipAddress = await getIPAddress()
        let request = KYCSubmissionRequest(from: data, email: email, ipAddress: ipAddress)

        return try await apiClient.request(
            try Endpoints.SubmitKYC(request: request)
        )
    }

    func getKYCStatus() async throws -> KYCSubmissionResponse {
        return try await apiClient.request(Endpoints.GetKYCStatus())
    }

    // MARK: - Private Methods

    private func getIPAddress() async -> String {
        // In production, this would be fetched from a service or the device
        // For now, return a placeholder that the server can replace
        return "0.0.0.0"
    }
}

// MARK: - KYC Repository Errors

enum KYCRepositoryError: LocalizedError {
    case invalidData(String)
    case submissionFailed(String)
    case statusCheckFailed

    var errorDescription: String? {
        switch self {
        case .invalidData(let reason):
            return "Invalid KYC data: \(reason)"
        case .submissionFailed(let reason):
            return "KYC submission failed: \(reason)"
        case .statusCheckFailed:
            return "Failed to check KYC status"
        }
    }
}
