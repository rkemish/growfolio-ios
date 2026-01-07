//
//  BasketDetailViewModel.swift
//  Growfolio
//
//  ViewModel for basket detail view.
//

import Foundation

@Observable
final class BasketDetailViewModel: @unchecked Sendable {

    // MARK: - Properties

    var basket: Basket
    var isLoading = false
    var errorMessage: String?
    var showError = false

    private let basketRepository: BasketRepositoryProtocol

    // MARK: - Initialization

    init(
        basket: Basket,
        basketRepository: BasketRepositoryProtocol = RepositoryContainer.basketRepository
    ) {
        self.basket = basket
        self.basketRepository = basketRepository
    }

    // MARK: - Methods

    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            basket = try await basketRepository.fetchBasket(id: basket.id)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    @MainActor
    func toggleStatus() async {
        let newStatus: BasketStatus = basket.status == .active ? .paused : .active

        do {
            let updatedBasket = try await basketRepository.updateBasket(
                id: basket.id,
                BasketCreate(
                    name: basket.name,
                    description: basket.description,
                    category: basket.category,
                    icon: basket.icon,
                    color: basket.color,
                    allocations: basket.allocations,
                    isShared: basket.isShared
                )
            )
            basket = updatedBasket
        } catch {
            errorMessage = "Failed to update basket: \(error.localizedDescription)"
            showError = true
        }
    }

    // MARK: - Computed Properties

    var returnPercentage: Decimal {
        basket.summary.returnPercentage
    }

    var isGaining: Bool {
        basket.summary.totalGainLoss > 0
    }

    var performanceColor: String {
        isGaining ? "#34C759" : "#FF3B30"
    }
}
