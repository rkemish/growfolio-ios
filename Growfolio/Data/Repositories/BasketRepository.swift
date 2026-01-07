//
//  BasketRepository.swift
//  Growfolio
//
//  Repository implementation for basket operations using APIClient.
//

import Foundation

/// Repository for basket operations
final class BasketRepository: BasketRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchBaskets() async throws -> [Basket] {
        try await apiClient.request(Endpoints.GetBaskets())
    }

    func fetchBasket(id: String) async throws -> Basket {
        try await apiClient.request(Endpoints.GetBasket(id: id))
    }

    func createBasket(_ basket: BasketCreate) async throws -> Basket {
        try await apiClient.request(Endpoints.CreateBasket(basket: basket))
    }

    func updateBasket(id: String, _ basket: BasketCreate) async throws -> Basket {
        try await apiClient.request(Endpoints.UpdateBasket(id: id, basket: basket))
    }

    func deleteBasket(id: String) async throws {
        try await apiClient.request(Endpoints.DeleteBasket(id: id))
    }
}
