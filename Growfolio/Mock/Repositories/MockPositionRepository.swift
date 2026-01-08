//
//  MockPositionRepository.swift
//  Growfolio
//
//  Mock position repository for previews and testing.
//

import Foundation

/// Mock implementation of position repository
final class MockPositionRepository: PositionRepositoryProtocol, @unchecked Sendable {
    private let store = MockDataStore.shared
    var shouldFail = false
    var errorToThrow: Error?

    init(positions: [Position] = []) {
        Task {
            for position in positions {
                await store.addPosition(position)
            }
        }
    }

    func fetchPositions() async throws -> [Position] {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        return await store.positions
    }

    func fetchPosition(symbol: String) async throws -> Position {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay

        guard let position = await store.getPosition(symbol: symbol) else {
            throw NetworkError.notFound
        }
        return position
    }

    func fetchPositionHistory(
        page: Int = 1,
        limit: Int = Constants.API.defaultPageSize,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> PaginatedResponse<Position> {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay

        var filtered = await store.positionHistory

        if let startDate = startDate {
            filtered = filtered.filter { $0.lastUpdated >= startDate }
        }

        if let endDate = endDate {
            filtered = filtered.filter { $0.lastUpdated <= endDate }
        }

        let totalItems = filtered.count
        let offset = (page - 1) * limit
        let paginatedData = Array(filtered.dropFirst(offset).prefix(limit))
        let totalPages = (totalItems + limit - 1) / limit

        return PaginatedResponse(
            data: paginatedData,
            pagination: PaginatedResponse.Pagination(
                page: page,
                limit: limit,
                totalPages: totalPages,
                totalItems: totalItems
            )
        )
    }
}
