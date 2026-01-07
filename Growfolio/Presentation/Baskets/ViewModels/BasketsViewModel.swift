//
//  BasketsViewModel.swift
//  Growfolio
//
//  ViewModel for managing user baskets list.
//

import Foundation

@Observable
final class BasketsViewModel: @unchecked Sendable {

    // MARK: - Properties

    var baskets: [Basket] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let basketRepository: BasketRepositoryProtocol

    // MARK: - Initialization

    init(basketRepository: BasketRepositoryProtocol = RepositoryContainer.basketRepository) {
        self.basketRepository = basketRepository
    }

    // MARK: - Methods

    @MainActor
    func loadBaskets() async {
        isLoading = true
        errorMessage = nil

        do {
            baskets = try await basketRepository.fetchBaskets()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    @MainActor
    func deleteBasket(_ basket: Basket) async {
        do {
            try await basketRepository.deleteBasket(id: basket.id)
            baskets.removeAll { $0.id == basket.id }
        } catch {
            errorMessage = "Failed to delete basket: \(error.localizedDescription)"
            showError = true
        }
    }

    @MainActor
    func refreshBaskets() async {
        await loadBaskets()
    }

    // MARK: - Computed Properties

    var activeBaskets: [Basket] {
        baskets.filter { $0.status == .active }
    }

    var pausedBaskets: [Basket] {
        baskets.filter { $0.status == .paused }
    }

    var hasBaskets: Bool {
        !baskets.isEmpty
    }

    var totalValue: Decimal {
        baskets.reduce(0) { $0 + $1.summary.currentValue }
    }

    var totalInvested: Decimal {
        baskets.reduce(0) { $0 + $1.summary.totalInvested }
    }

    var totalGainLoss: Decimal {
        baskets.reduce(0) { $0 + $1.summary.totalGainLoss }
    }
}
