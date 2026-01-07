//
//  MockBasketRepository.swift
//  Growfolio
//
//  Mock basket repository for previews and testing.
//

import Foundation

/// Mock implementation of basket repository
final class MockBasketRepository: BasketRepositoryProtocol, @unchecked Sendable {
    private let store = MockDataStore.shared
    var shouldFail = false
    var errorToThrow: Error?

    init(baskets: [Basket] = []) {
        Task {
            for basket in baskets {
                await store.addBasket(basket)
            }
        }
    }

    func fetchBaskets() async throws -> [Basket] {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        return await store.baskets
    }

    func fetchBasket(id: String) async throws -> Basket {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
        guard let basket = await store.getBasket(id: id) else {
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
        await store.addBasket(newBasket)
        return newBasket
    }

    func updateBasket(id: String, _ basket: BasketCreate) async throws -> Basket {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        guard let existing = await store.getBasket(id: id) else {
            throw NetworkError.notFound
        }
        let updatedBasket = Basket(
            id: existing.id,
            userId: existing.userId,
            familyId: existing.familyId,
            name: basket.name,
            description: basket.description,
            category: basket.category,
            icon: basket.icon,
            color: basket.color,
            allocations: basket.allocations,
            dcaEnabled: existing.dcaEnabled,
            dcaScheduleId: existing.dcaScheduleId,
            status: existing.status,
            summary: existing.summary,
            isShared: basket.isShared,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )
        await store.updateBasket(updatedBasket)
        return updatedBasket
    }

    func deleteBasket(id: String) async throws {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        await store.deleteBasket(id: id)
    }
}
