//
//  CorporateActionRepositoryProtocol.swift
//  Growfolio
//
//  Repository protocol for corporate action operations.
//

import Foundation

/// Protocol for corporate action repository operations
protocol CorporateActionRepositoryProtocol: Sendable {
    /// Fetch corporate actions with optional filtering
    func fetchCorporateActions(
        symbol: String?,
        type: CorporateActionType?,
        status: CorporateActionStatus?
    ) async throws -> [CorporateAction]

    /// Fetch a specific corporate action by announcement ID
    func fetchCorporateAction(announcementId: String) async throws -> CorporateAction
}
