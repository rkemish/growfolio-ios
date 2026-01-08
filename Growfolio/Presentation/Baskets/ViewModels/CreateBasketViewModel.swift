//
//  CreateBasketViewModel.swift
//  Growfolio
//
//  ViewModel for creating a new basket.
//

import Foundation

@Observable
final class CreateBasketViewModel: @unchecked Sendable {

    // MARK: - Properties

    var name: String = ""
    var description: String = ""
    var category: String = ""
    var selectedIcon: String = "basket.fill"
    var selectedColor: String = "#007AFF"
    var allocations: [AllocationInput] = []
    var isShared: Bool = false

    var isCreating = false
    var errorMessage: String?
    var showError = false

    private let basketRepository: BasketRepositoryProtocol

    // MARK: - Nested Types

    struct AllocationInput: Identifiable, Equatable {
        let id = UUID()
        var symbol: String = ""
        var name: String = ""
        var percentage: String = ""

        var isValid: Bool {
            !symbol.isEmpty && !name.isEmpty && !percentage.isEmpty
        }

        var decimalPercentage: Decimal? {
            Decimal(string: percentage)
        }
    }

    // MARK: - Initialization

    init(basketRepository: BasketRepositoryProtocol = RepositoryContainer.basketRepository) {
        self.basketRepository = basketRepository
        // Start with one empty allocation
        allocations.append(AllocationInput())
    }

    // MARK: - Methods

    func addAllocation() {
        allocations.append(AllocationInput())
    }

    func removeAllocation(at index: Int) {
        guard allocations.count > 1 else { return }
        allocations.remove(at: index)
    }

    @MainActor
    func createBasket() async -> Basket? {
        guard validateInputs() else { return nil }

        isCreating = true
        errorMessage = nil

        do {
            let basketAllocations = allocations.compactMap { input -> BasketAllocation? in
                guard let percentage = input.decimalPercentage else { return nil }
                return BasketAllocation(
                    symbol: input.symbol.uppercased(),
                    name: input.name,
                    percentage: percentage,
                    targetShares: nil
                )
            }

            let basketCreate = BasketCreate(
                name: name,
                description: description.isEmpty ? nil : description,
                category: category.isEmpty ? nil : category,
                icon: selectedIcon,
                color: selectedColor,
                allocations: basketAllocations,
                isShared: isShared
            )

            let basket = try await basketRepository.createBasket(basketCreate)
            isCreating = false

            // Show success toast
            ToastManager.shared.showSuccess("Basket '\(name)' created successfully!")

            return basket
        } catch {
            errorMessage = "Failed to create basket: \(error.localizedDescription)"
            showError = true
            isCreating = false
            return nil
        }
    }

    private func validateInputs() -> Bool {
        // Validate name
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Basket name is required"
            showError = true
            return false
        }

        // Validate allocations
        let validAllocations = allocations.filter { $0.isValid }
        guard !validAllocations.isEmpty else {
            errorMessage = "At least one stock allocation is required"
            showError = true
            return false
        }

        // Validate total percentage
        let totalPercentage = validAllocations.compactMap { $0.decimalPercentage }.reduce(0, +)
        guard abs(totalPercentage - 100) < 0.01 else {
            errorMessage = "Stock allocations must total 100% (currently \(totalPercentage)%)"
            showError = true
            return false
        }

        return true
    }

    // MARK: - Computed Properties

    var isValid: Bool {
        !name.isEmpty && totalAllocationPercentage >= 99.99 && totalAllocationPercentage <= 100.01
    }

    var totalAllocationPercentage: Decimal {
        allocations.compactMap { $0.decimalPercentage }.reduce(0, +)
    }

    var validAllocationsCount: Int {
        allocations.filter { $0.isValid }.count
    }

    // MARK: - Icon and Color Options

    static let iconOptions = [
        "basket.fill",
        "chart.pie.fill",
        "chart.line.uptrend.xyaxis",
        "dollarsign.circle.fill",
        "briefcase.fill",
        "building.columns.fill",
        "lightbulb.fill",
        "star.fill",
        "heart.fill",
        "leaf.fill"
    ]

    static let colorOptions = [
        "#007AFF", // Blue
        "#34C759", // Green
        "#FF9500", // Orange
        "#FF3B30", // Red
        "#AF52DE", // Purple
        "#FF2D55", // Pink
        "#5AC8FA", // Light Blue
        "#FFCC00", // Yellow
        "#8E8E93"  // Gray
    ]
}
