//
//  PositionRepository.swift
//  Growfolio
//
//  Repository implementation for position operations using APIClient.
//

import Foundation

/// Repository for position operations
final class PositionRepository: PositionRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchPositions() async throws -> [Position] {
        try await apiClient.request(Endpoints.GetPositions())
    }

    func fetchPosition(symbol: String) async throws -> Position {
        try await apiClient.request(Endpoints.GetPosition(symbol: symbol))
    }

    func fetchPositionHistory(
        page: Int = 1,
        limit: Int = Constants.API.defaultPageSize,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> PaginatedResponse<Position> {
        try await apiClient.request(
            Endpoints.GetPositionHistory(
                page: page,
                limit: limit,
                startDate: startDate,
                endDate: endDate
            )
        )
    }
}
