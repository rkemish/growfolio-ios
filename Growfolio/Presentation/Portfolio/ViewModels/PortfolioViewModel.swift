//
//  PortfolioViewModel.swift
//  Growfolio
//
//  View model for portfolio management and holdings display.
//

import Foundation
import SwiftUI

@Observable
final class PortfolioViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Loading State
    var isLoading = false
    var isRefreshing = false
    var error: Error?

    // Error display flag
    var showError = false

    // Portfolio Data
    var portfolios: [Portfolio] = []
    var selectedPortfolio: Portfolio?
    var holdings: [Holding] = []
    var transactions: [LedgerEntry] = []

    // Selected Period
    var selectedPeriod: PerformancePeriod = .oneMonth

    // View State
    var showHoldingDetail = false
    var selectedHolding: Holding?
    var showTransactionHistory = false
    var showAddTransaction = false

    // Repository
    private let repository: PortfolioRepositoryProtocol

    // MARK: - Computed Properties

    var currentPortfolio: Portfolio? {
        selectedPortfolio ?? portfolios.first
    }

    var totalValue: Decimal {
        currentPortfolio?.totalValue ?? 0
    }

    var totalReturn: Decimal {
        currentPortfolio?.totalReturn ?? 0
    }

    var totalReturnPercentage: Decimal {
        currentPortfolio?.totalReturnPercentage ?? 0
    }

    var cashBalance: Decimal {
        currentPortfolio?.cashBalance ?? 0
    }

    var isProfitable: Bool {
        totalReturn > 0
    }

    var sortedHoldings: [Holding] {
        holdings.sorted { $0.marketValue > $1.marketValue }
    }

    var topHoldings: [Holding] {
        Array(sortedHoldings.prefix(5))
    }

    var holdingsSummary: HoldingsSummary {
        HoldingsSummary(holdings: holdings)
    }

    var recentTransactions: [LedgerEntry] {
        Array(transactions.prefix(10))
    }

    var allocationByHolding: [AllocationItem] {
        let total = holdings.reduce(Decimal.zero) { $0 + $1.marketValue }
        guard total > 0 else { return [] }

        return holdings.map { holding in
            AllocationItem(
                category: holding.stockSymbol,
                value: holding.marketValue,
                percentage: (holding.marketValue / total) * 100,
                colorHex: Color.chartColor(at: holdings.firstIndex(where: { $0.id == holding.id }) ?? 0).hexString ?? "#007AFF"
            )
        }.sorted { $0.percentage > $1.percentage }
    }

    var hasHoldings: Bool {
        !holdings.isEmpty
    }

    var isEmpty: Bool {
        holdings.isEmpty && !isLoading
    }

    // MARK: - Initialization

    init(repository: PortfolioRepositoryProtocol = RepositoryContainer.portfolioRepository) {
        self.repository = repository
    }

    // MARK: - Data Loading

    @MainActor
    func loadPortfolioData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Load portfolios
            portfolios = try await repository.fetchPortfolios()

            // Set default portfolio if none selected
            if selectedPortfolio == nil {
                selectedPortfolio = portfolios.first
            }

            // Load holdings for current portfolio
            if let portfolio = currentPortfolio {
                holdings = try await repository.fetchHoldings(for: portfolio.id)

                // Load recent transactions
                let transactionsResponse = try await repository.fetchLedgerEntries(
                    for: portfolio.id,
                    page: 1,
                    limit: 20
                )
                transactions = transactionsResponse.data
            }
        } catch {
            self.error = error
            self.showError = true

            // Show error toast with retry option
            Task { @MainActor in
                ToastManager.shared.showError(error) { [weak self] in
                    guard let self else { return }
                    Task { await self.loadPortfolioData() }
                }
            }
        }

        isLoading = false
    }

    @MainActor
    func refreshPortfolioData() async {
        isRefreshing = true
        await repository.invalidateCache()
        await loadPortfolioData()
        isRefreshing = false
    }

    func refresh() {
        Task { @MainActor in
            await refreshPortfolioData()
        }
    }

    @MainActor
    func refreshPrices() async {
        guard let portfolio = currentPortfolio else { return }

        do {
            holdings = try await repository.refreshHoldingPrices(for: portfolio.id)
        } catch {
            self.error = error

            // Show error toast for price refresh failures
            Task { @MainActor in
                ToastManager.shared.showError(
                    "Unable to refresh prices",
                    actionTitle: "Retry"
                ) { [weak self] in
                    guard let self else { return }
                    Task { await self.refreshPrices() }
                }
            }
        }
    }

    // MARK: - Portfolio Selection

    @MainActor
    func selectPortfolio(_ portfolio: Portfolio) async {
        selectedPortfolio = portfolio
        await loadHoldingsForCurrentPortfolio()
    }

    @MainActor
    private func loadHoldingsForCurrentPortfolio() async {
        guard let portfolio = currentPortfolio else { return }

        do {
            holdings = try await repository.fetchHoldings(for: portfolio.id)
        } catch {
            self.error = error

            // Show error toast for holdings load failures
            Task { @MainActor in
                ToastManager.shared.showError(error) { [weak self] in
                    guard let self else { return }
                    Task { await self.loadHoldingsForCurrentPortfolio() }
                }
            }
        }
    }

    // MARK: - Error Handling

    func dismissError() {
        showError = false
        error = nil
    }

    // MARK: - Holding Selection

    func selectHolding(_ holding: Holding) {
        selectedHolding = holding
        showHoldingDetail = true
    }

    // MARK: - Transactions

    @MainActor
    func addTransaction(
        type: LedgerEntryType,
        stockSymbol: String?,
        quantity: Decimal?,
        pricePerShare: Decimal?,
        totalAmount: Decimal,
        notes: String?
    ) async throws {
        guard let portfolio = currentPortfolio else { return }

        let entry = LedgerEntry(
            portfolioId: portfolio.id,
            userId: "",
            type: type,
            stockSymbol: stockSymbol,
            quantity: quantity,
            pricePerShare: pricePerShare,
            totalAmount: totalAmount,
            notes: notes
        )

        let _ = try await repository.addLedgerEntry(entry, to: portfolio.id)
        await refreshPortfolioData()
    }

    @MainActor
    func deposit(amount: Decimal, notes: String?) async throws {
        guard let portfolio = currentPortfolio else { return }
        let _ = try await repository.depositCash(amount: amount, to: portfolio.id, notes: notes)
        await refreshPortfolioData()
    }

    @MainActor
    func withdraw(amount: Decimal, notes: String?) async throws {
        guard let portfolio = currentPortfolio else { return }
        let _ = try await repository.withdrawCash(amount: amount, from: portfolio.id, notes: notes)
        await refreshPortfolioData()
    }
}
