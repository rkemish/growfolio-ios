//
//  PositionRepositoryProtocol.swift
//  Growfolio
//
//  Repository protocol for position operations.
//

import Foundation

/// Protocol for position repository operations
protocol PositionRepositoryProtocol: Sendable {
    /// Fetch all current positions
    func fetchPositions() async throws -> [Position]

    /// Fetch a specific position by symbol
    func fetchPosition(symbol: String) async throws -> Position

    /// Fetch position history with pagination
    func fetchPositionHistory(
        page: Int,
        limit: Int,
        startDate: Date?,
        endDate: Date?
    ) async throws -> PaginatedResponse<Position>
}
