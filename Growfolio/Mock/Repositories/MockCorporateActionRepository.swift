//
//  MockCorporateActionRepository.swift
//  Growfolio
//
//  Mock corporate action repository for previews and testing.
//

import Foundation

/// Mock implementation of corporate action repository
final class MockCorporateActionRepository: CorporateActionRepositoryProtocol, @unchecked Sendable {
    private let store = MockDataStore.shared
    var shouldFail = false
    var errorToThrow: Error?

    init(corporateActions: [CorporateAction] = []) {
        Task {
            for action in corporateActions {
                await store.addCorporateAction(action)
            }
        }
    }

    func fetchCorporateActions(
        symbol: String? = nil,
        type: CorporateActionType? = nil,
        status: CorporateActionStatus? = nil
    ) async throws -> [CorporateAction] {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay

        var filtered = await store.corporateActions

        if let symbol = symbol {
            filtered = filtered.filter { $0.symbol == symbol }
        }

        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }

        if let status = status {
            filtered = filtered.filter { $0.status == status }
        }

        return filtered
    }

    func fetchCorporateAction(announcementId: String) async throws -> CorporateAction {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay

        guard let action = await store.getCorporateAction(id: announcementId) else {
            throw NetworkError.notFound
        }
        return action
    }
}
