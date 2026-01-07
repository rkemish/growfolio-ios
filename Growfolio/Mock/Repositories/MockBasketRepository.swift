//
//  MockBasketRepository.swift
//  Growfolio
//
//  Mock basket repository for previews and testing.
//

import Foundation

/// Mock implementation of basket repository
final class MockBasketRepository: BasketRepositoryProtocol, @unchecked Sendable {
    private var baskets: [Basket] = []
    var shouldFail = false
    var errorToThrow: Error?

    init(baskets: [Basket] = []) {
        self.baskets = baskets
    }

    func fetchBaskets() async throws -> [Basket] {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        return baskets
    }

    func fetchBasket(id: String) async throws -> Basket {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
        guard let basket = baskets.first(where: { $0.id == id }) else {
            throw NetworkError.notFound
        }
        return basket
    }

    func createBasket(_ basket: BasketCreate) async throws -> Basket {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 700_000_000) // 0.7s delay
        let newBasket = Basket(
            userId: "mock-user",
            name: basket.name,
            description: basket.description,
            category: basket.category,
            icon: basket.icon,
            color: basket.color,
            allocations: basket.allocations,
            isShared: basket.isShared
        )
        baskets.append(newBasket)
        return newBasket
    }

    func updateBasket(id: String, _ basket: BasketCreate) async throws -> Basket {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        guard let index = baskets.firstIndex(where: { $0.id == id }) else {
            throw NetworkError.notFound
        }
        let updatedBasket = Basket(
            id: baskets[index].id,
            userId: baskets[index].userId,
            familyId: baskets[index].familyId,
            name: basket.name,
            description: basket.description,
            category: basket.category,
            icon: basket.icon,
            color: basket.color,
            allocations: basket.allocations,
            dcaEnabled: baskets[index].dcaEnabled,
            dcaScheduleId: baskets[index].dcaScheduleId,
            status: baskets[index].status,
            summary: baskets[index].summary,
            isShared: basket.isShared,
            createdAt: baskets[index].createdAt,
            updatedAt: Date()
        )
        baskets[index] = updatedBasket
        return updatedBasket
    }

    func deleteBasket(id: String) async throws {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        baskets.removeAll { $0.id == id }
    }
}
