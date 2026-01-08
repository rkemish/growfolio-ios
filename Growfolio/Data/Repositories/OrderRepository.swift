//
//  OrderRepository.swift
//  Growfolio
//
//  Repository implementation for order operations using APIClient.
//

import Foundation

/// Repository for order operations
final class OrderRepository: OrderRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchOrders(
        status: OrderStatus? = nil,
        limit: Int? = nil,
        after: Date? = nil,
        until: Date? = nil
    ) async throws -> [Order] {
        try await apiClient.request(
            Endpoints.GetOrders(
                status: status,
                limit: limit,
                after: after,
                until: until
            )
        )
    }

    func fetchOrder(id: String) async throws -> Order {
        try await apiClient.request(Endpoints.GetOrder(orderId: id))
    }

    func cancelOrder(id: String) async throws {
        try await apiClient.request(Endpoints.CancelOrder(orderId: id))
    }
}
