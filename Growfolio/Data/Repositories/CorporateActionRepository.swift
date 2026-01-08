//
//  CorporateActionRepository.swift
//  Growfolio
//
//  Repository implementation for corporate action operations using APIClient.
//

import Foundation

/// Repository for corporate action operations
final class CorporateActionRepository: CorporateActionRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchCorporateActions(
        symbol: String? = nil,
        type: CorporateActionType? = nil,
        status: CorporateActionStatus? = nil
    ) async throws -> [CorporateAction] {
        try await apiClient.request(
            Endpoints.GetCorporateActions(
                symbol: symbol,
                type: type,
                status: status
            )
        )
    }

    func fetchCorporateAction(announcementId: String) async throws -> CorporateAction {
        try await apiClient.request(Endpoints.GetCorporateAction(announcementId: announcementId))
    }
}
