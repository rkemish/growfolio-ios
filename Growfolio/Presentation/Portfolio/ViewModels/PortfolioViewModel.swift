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
    private let webSocketService: WebSocketServiceProtocol

    // WebSocket Tasks
    nonisolated(unsafe) private var eventUpdatesTask: Task<Void, Never>?

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
        // Avoid division by zero if portfolio is empty or all positions at $0
        guard total > 0 else { return [] }

        return holdings.map { holding in
            // Assign consistent color to each holding based on its index in array
            // This ensures the same stock always gets the same color in charts
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

    nonisolated(unsafe) init(
        repository: PortfolioRepositoryProtocol = RepositoryContainer.portfolioRepository,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.repository = repository
        if let webSocketService {
            self.webSocketService = webSocketService
        } else {
            self.webSocketService = MainActor.assumeIsolated { WebSocketService.shared }
        }
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

            // After successful data load, start real-time updates
            await startRealtimeUpdates()
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

    // MARK: - WebSocket Real-Time Updates

    @MainActor
    private func startRealtimeUpdates() async {
        // Subscribe to channels
        await webSocketService.subscribe(channels: [
            WebSocketChannel.positions.rawValue,
            WebSocketChannel.account.rawValue
        ])

        // Start event listener
        startEventUpdatesListener()
    }

    @MainActor
    private func startEventUpdatesListener() {
        guard eventUpdatesTask == nil else { return }

        eventUpdatesTask = Task { [weak self] in
            guard let self else { return }

            let stream = await webSocketService.eventUpdates()
            for await event in stream {
                await MainActor.run {
                    self.handleWebSocketEvent(event)
                }
            }
        }
    }

    @MainActor
    private func handleWebSocketEvent(_ event: WebSocketEvent) {
        switch event.name {
        case .positionUpdated:
            if let payload = try? event.decodeData(WebSocketPositionUpdatePayload.self) {
                handlePositionUpdate(payload)
            }
        case .positionCreated:
            if let payload = try? event.decodeData(WebSocketPositionUpdatePayload.self) {
                handlePositionCreated(payload)
            }
        case .positionClosed:
            if let payload = try? event.decodeData(WebSocketPositionUpdatePayload.self) {
                handlePositionClosed(payload)
            }
        case .cashChanged, .buyingPowerChanged, .accountStatusChanged:
            if let payload = try? event.decodeData(WebSocketAccountUpdatePayload.self) {
                handleAccountUpdate(payload)
            }
        default:
            break
        }
    }

    @MainActor
    private func handlePositionUpdate(_ payload: WebSocketPositionUpdatePayload) {
        // Find matching holding by symbol
        guard let index = holdings.firstIndex(where: { $0.stockSymbol == payload.symbol }) else {
            // If holding doesn't exist locally, refresh full portfolio
            Task {
                await refreshPrices()
            }
            return
        }

        // Update holding with new values
        var holding = holdings[index]
        holding.quantity = payload.quantity.value
        holding.currentPricePerShare = payload.marketValueUsd.value / max(holding.quantity, 1)
        holding.priceUpdatedAt = Date()

        holdings[index] = holding

        // Note: Portfolio totals will auto-recalculate via computed properties
    }

    @MainActor
    private func handleAccountUpdate(_ payload: WebSocketAccountUpdatePayload) {
        // Update portfolio totals
        guard var portfolio = selectedPortfolio else { return }

        portfolio.totalValue = payload.portfolioValueGbp.value
        portfolio.cashBalance = payload.cashGbp.value

        selectedPortfolio = portfolio

        // Also update in portfolios array if present
        if let index = portfolios.firstIndex(where: { $0.id == portfolio.id }) {
            portfolios[index] = portfolio
        }
    }

    @MainActor
    private func handlePositionCreated(_ payload: WebSocketPositionUpdatePayload) {
        // Show celebration notification for new position
        ToastManager.shared.showSuccess(
            "New position created: \(payload.symbol) 🎉"
        )

        // Refresh portfolio to show new holding
        Task {
            await refreshPrices()
        }
    }

    @MainActor
    private func handlePositionClosed(_ payload: WebSocketPositionUpdatePayload) {
        // Show notification for closed position
        let pnl = payload.unrealizedPnlGbp.value
        let pnlFormatted = pnl.formatted(.currency(code: "GBP"))
        let emoji = pnl >= 0 ? "✅" : "📉"

        ToastManager.shared.showInfo(
            "Position closed: \(payload.symbol) \(emoji) P&L: \(pnlFormatted)"
        )

        // Refresh portfolio to remove closed holding
        Task {
            await refreshPrices()
        }
    }

    deinit {
        eventUpdatesTask?.cancel()

        // Note: Cannot await in deinit, but WebSocketService handles cleanup internally
        // The unsubscribe will happen when the service is deallocated or connection closes
    }
}
