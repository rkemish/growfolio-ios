//
//  MockOrderRepository.swift
//  Growfolio
//
//  Mock order repository for previews and testing.
//

import Foundation

/// Mock implementation of order repository
final class MockOrderRepository: OrderRepositoryProtocol, @unchecked Sendable {
    private let store = MockDataStore.shared
    var shouldFail = false
    var errorToThrow: Error?

    init(orders: [Order] = []) {
        Task {
            for order in orders {
                await store.addOrder(order)
            }
        }
    }

    func fetchOrders(
        status: OrderStatus? = nil,
        limit: Int? = nil,
        after: Date? = nil,
        until: Date? = nil
    ) async throws -> [Order] {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay

        var filtered = await store.orders

        if let status = status {
            filtered = filtered.filter { $0.status == status }
        }

        if let after = after {
            filtered = filtered.filter { $0.submittedAt >= after }
        }

        if let until = until {
            filtered = filtered.filter { $0.submittedAt <= until }
        }

        if let limit = limit {
            filtered = Array(filtered.prefix(limit))
        }

        return filtered
    }

    func fetchOrder(id: String) async throws -> Order {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay

        guard let order = await store.getOrder(id: id) else {
            throw NetworkError.notFound
        }
        return order
    }

    func cancelOrder(id: String) async throws {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay

        guard let order = await store.getOrder(id: id) else {
            throw NetworkError.notFound
        }

        // Update order status to cancelled
        let cancelledOrder = Order(
            id: order.id,
            clientOrderId: order.clientOrderId,
            symbol: order.symbol,
            side: order.side,
            type: order.type,
            status: .cancelled,
            timeInForce: order.timeInForce,
            quantity: order.quantity,
            notional: order.notional,
            filledQuantity: order.filledQuantity,
            filledAvgPrice: order.filledAvgPrice,
            limitPrice: order.limitPrice,
            stopPrice: order.stopPrice,
            submittedAt: order.submittedAt,
            filledAt: order.filledAt,
            canceledAt: Date(),
            expiredAt: order.expiredAt
        )

        await store.updateOrder(cancelledOrder)
    }
}
