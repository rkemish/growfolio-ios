//
//  OrderRepositoryProtocol.swift
//  Growfolio
//
//  Repository protocol for order operations.
//

import Foundation

/// Protocol for order repository operations
protocol OrderRepositoryProtocol: Sendable {
    /// Fetch all orders with optional filtering
    func fetchOrders(
        status: OrderStatus?,
        limit: Int?,
        after: Date?,
        until: Date?
    ) async throws -> [Order]

    /// Fetch a specific order by ID
    func fetchOrder(id: String) async throws -> Order

    /// Cancel an order
    func cancelOrder(id: String) async throws
}
