//
//  BasketRepositoryProtocol.swift
//  Growfolio
//
//  Repository protocol for basket operations.
//

import Foundation

/// Protocol for basket repository operations
protocol BasketRepositoryProtocol: Sendable {
    /// Fetch all baskets for the current user
    func fetchBaskets() async throws -> [Basket]

    /// Fetch a specific basket by ID
    func fetchBasket(id: String) async throws -> Basket

    /// Create a new basket
    func createBasket(_ basket: BasketCreate) async throws -> Basket

    /// Update an existing basket
    func updateBasket(id: String, _ basket: BasketCreate) async throws -> Basket

    /// Delete a basket
    func deleteBasket(id: String) async throws
}
