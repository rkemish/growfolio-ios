//
//  DashboardViewModel.swift
//  Growfolio
//
//  View model for the main dashboard.
//

import Foundation
import SwiftUI

@Observable
final class DashboardViewModel: @unchecked Sendable {

    // MARK: - Dependencies

    private let goalRepository: GoalRepositoryProtocol
    private let dcaRepository: DCARepositoryProtocol
    private let portfolioRepository: PortfolioRepositoryProtocol
    private let stocksRepository: StocksRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol

    // MARK: - Properties

    // Loading State
    var isLoading = false
    var error: Error?

    // Error display flag for alert
    var showError = false

    // Portfolio Data
    var totalPortfolioValue: Decimal = 0
    var todaysChange: Decimal = 0
    var todaysChangePercent: Decimal = 0
    var totalReturn: Decimal = 0
    var totalReturnPercent: Decimal = 0
    var cashBalance: Decimal = 0

    // Market Status
    var marketHours: MarketHours?

    // Goals
    var topGoals: [Goal] = []

    // DCA Schedules
    var activeDCASchedules: [DCASchedule] = []

    // Recent Activity
    var recentActivity: [LedgerEntry] = []

    // Recent Orders
    var recentOrders: [StockOrder] = []

    // Portfolio Summary
    var portfolio: Portfolio?

    // Sheet Presentation
    var showAddGoal = false
    var showAddDCA = false
    var showRecordTrade = false
    var showDeposit = false

    // MARK: - Computed Properties

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())

        // Time-based greeting for personalized UX
        // 0-11: Morning, 12-16: Afternoon, 17-23: Evening
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }

    var hasData: Bool {
        !topGoals.isEmpty || !activeDCASchedules.isEmpty || !recentActivity.isEmpty || portfolio != nil
    }

    var isProfitable: Bool {
        totalReturn >= 0
    }

    // WebSocket Tasks
    nonisolated(unsafe) private var orderUpdatesTask: Task<Void, Never>?

    // MARK: - Initialization

    nonisolated(unsafe) init(
        goalRepository: GoalRepositoryProtocol = RepositoryContainer.goalRepository,
        dcaRepository: DCARepositoryProtocol = RepositoryContainer.dcaRepository,
        portfolioRepository: PortfolioRepositoryProtocol = RepositoryContainer.portfolioRepository,
        stocksRepository: StocksRepositoryProtocol = RepositoryContainer.stocksRepository,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.goalRepository = goalRepository
        self.dcaRepository = dcaRepository
        self.portfolioRepository = portfolioRepository
        self.stocksRepository = stocksRepository
        if let webSocketService {
            self.webSocketService = webSocketService
        } else {
            self.webSocketService = MainActor.assumeIsolated { WebSocketService.shared }
        }
    }

    deinit {
        orderUpdatesTask?.cancel()

        // Note: Cannot await in deinit, but WebSocketService handles cleanup internally
        // The unsubscribe will happen when the service is deallocated or connection closes
    }

    // MARK: - Data Loading

    @MainActor
    func loadDashboardData() async {
        // Prevent concurrent loads (e.g., from pull-to-refresh + view appear)
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Use structured concurrency to load all data in parallel
            // This pattern is faster than sequential awaits and handles errors gracefully
            // Each async let starts a child task that runs concurrently
            async let portfolio = loadPortfolioSummary()
            async let goals = loadTopGoals()
            async let dca = loadActiveDCASchedules()
            async let activity = loadRecentActivity()
            async let marketStatus = loadMarketStatus()

            // Wait for all child tasks to complete before proceeding
            // If any task throws, all others are automatically cancelled
            _ = try await (portfolio, goals, dca, activity, marketStatus)

            // Start real-time order updates after successful data load
            await startOrderUpdates()

        } catch {
            self.error = error
            self.showError = true

            // Show error toast with retry option
            Task { @MainActor in
                ToastManager.shared.showError(error) { [weak self] in
                    guard let self else { return }
                    Task { await self.loadDashboardData() }
                }
            }
        }

        isLoading = false
    }

    func refreshData() {
        Task { @MainActor in
            await loadDashboardData()
        }
    }

    @MainActor
    func refreshDataAsync() async {
        await loadDashboardData()
    }

    // MARK: - Private Loading Methods

    @MainActor
    private func loadPortfolioSummary() async throws {
        do {
            // Fetch default portfolio from API
            guard let fetchedPortfolio = try await portfolioRepository.fetchDefaultPortfolio() else {
                // No portfolio yet, that's okay for new users
                return
            }
            portfolio = fetchedPortfolio

            // Update summary values from portfolio
            totalPortfolioValue = fetchedPortfolio.totalValue
            cashBalance = fetchedPortfolio.cashBalance
            totalReturn = fetchedPortfolio.totalReturn
            totalReturnPercent = fetchedPortfolio.totalReturnPercentage

            // Fetch holdings to calculate today's change
            let holdings = try await portfolioRepository.fetchHoldings(for: fetchedPortfolio.id)

            // Calculate today's change (sum of unrealized gain/loss for the day)
            // This is a simple approximation - in production this would use historical data
            todaysChange = holdings.reduce(Decimal(0)) { result, holding in
                result + holding.unrealizedGainLoss * Decimal(0.01)
            }
            todaysChangePercent = totalPortfolioValue > 0 ? (todaysChange / totalPortfolioValue) * 100 : 0

        } catch {
            // If API fails, keep existing values
            print("Failed to load portfolio summary: \(error)")
            throw error
        }
    }

    @MainActor
    private func loadTopGoals() async throws {
        do {
            // Fetch all goals and take top 3 by progress
            let allGoals = try await goalRepository.fetchGoals(includeArchived: false)

            // Sort by progress percentage descending, then by target date
            // Filter to only in-progress goals (exclude archived and achieved)
            topGoals = Array(
                allGoals
                    .filter { $0.status != GoalStatus.archived && $0.status != GoalStatus.achieved }
                    .sorted { $0.progressPercentage > $1.progressPercentage }
                    .prefix(3)
            )
        } catch {
            print("Failed to load goals: \(error)")
            throw error
        }
    }

    @MainActor
    private func loadActiveDCASchedules() async throws {
        do {
            // Fetch active DCA schedules
            let allSchedules = try await dcaRepository.fetchSchedules()

            // Filter active and sort by next execution date
            activeDCASchedules = Array(
                allSchedules
                    .filter { $0.isActive }
                    .sorted { ($0.nextExecutionDate ?? Date.distantFuture) < ($1.nextExecutionDate ?? Date.distantFuture) }
                    .prefix(5)
            )
        } catch {
            print("Failed to load DCA schedules: \(error)")
            throw error
        }
    }

    @MainActor
    private func loadRecentActivity() async throws {
        do {
            // Get portfolio, fetching if not loaded
            let currentPortfolio: Portfolio
            if let existing = portfolio {
                currentPortfolio = existing
            } else if let fetched = try await portfolioRepository.fetchDefaultPortfolio() {
                self.portfolio = fetched
                currentPortfolio = fetched
            } else {
                return
            }

            let portfolioId = currentPortfolio.id

            // Fetch recent ledger entries (page 1, limit 10)
            let response = try await portfolioRepository.fetchLedgerEntries(
                for: portfolioId,
                page: 1,
                limit: 10
            )

            // Sort by date descending and take top 5
            recentActivity = Array(
                response.data
                    .sorted { $0.transactionDate > $1.transactionDate }
                    .prefix(5)
            )
        } catch {
            print("Failed to load recent activity: \(error)")
            throw error
        }
    }

    @MainActor
    private func loadMarketStatus() async throws {
        do {
            marketHours = try await stocksRepository.getMarketStatus()
        } catch {
            // Market status is non-critical, so we don't throw
            // Just use fallback
            marketHours = MarketHours.fallback()
            print("Failed to load market status: \(error)")
        }
    }

    // MARK: - Actions

    func selectGoal(_ goal: Goal) {
        // Navigate to goal details
    }

    func selectDCASchedule(_ schedule: DCASchedule) {
        // Navigate to DCA schedule details
    }

    func selectActivity(_ entry: LedgerEntry) {
        // Navigate to activity details
    }

    // MARK: - Quick Actions

    @MainActor
    func recordDeposit(amount: Decimal) async throws {
        guard let portfolioId = portfolio?.id else {
            throw DashboardError.noPortfolio
        }

        _ = try await portfolioRepository.depositCash(
            amount: amount,
            to: portfolioId,
            notes: "Deposit from dashboard"
        )

        // Refresh data after recording
        await loadDashboardData()
    }

    @MainActor
    func recordWithdrawal(amount: Decimal) async throws {
        guard let portfolioId = portfolio?.id else {
            throw DashboardError.noPortfolio
        }

        _ = try await portfolioRepository.withdrawCash(
            amount: amount,
            from: portfolioId,
            notes: "Withdrawal from dashboard"
        )

        // Refresh data after recording
        await loadDashboardData()
    }

    // MARK: - Error Handling

    func dismissError() {
        showError = false
        error = nil
    }

    // MARK: - WebSocket Order Updates

    @MainActor
    private func startOrderUpdates() async {
        // Subscribe to orders channel
        await webSocketService.subscribe(channels: [WebSocketChannel.orders.rawValue])

        // Start event listener
        startOrderUpdatesListener()
    }

    @MainActor
    private func startOrderUpdatesListener() {
        guard orderUpdatesTask == nil else { return }

        orderUpdatesTask = Task { [weak self] in
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
        case .orderCreated:
            if let payload = try? event.decodeData(WebSocketOrderPayload.self) {
                handleOrderCreated(payload)
            }
        case .orderStatus:
            if let payload = try? event.decodeData(WebSocketOrderPayload.self) {
                handleOrderStatus(payload)
            }
        case .orderFill:
            if let payload = try? event.decodeData(WebSocketOrderPayload.self) {
                handleOrderFill(payload)
            }
        case .orderCancelled:
            if let payload = try? event.decodeData(WebSocketOrderPayload.self) {
                handleOrderCancelled(payload)
            }
        default:
            break
        }
    }

    @MainActor
    private func handleOrderCreated(_ payload: WebSocketOrderPayload) {
        let order = payload.toStockOrder()

        // Add to recent orders (keep max 10)
        recentOrders.insert(order, at: 0)
        if recentOrders.count > 10 {
            recentOrders = Array(recentOrders.prefix(10))
        }

        // Show toast notification
        let displayType = "\(order.side.rawValue.capitalized) \(order.type.rawValue.capitalized)"
        ToastManager.shared.showInfo(
            "Order created: \(displayType) \(order.symbol)"
        )
    }

    @MainActor
    private func handleOrderStatus(_ payload: WebSocketOrderPayload) {
        let order = payload.toStockOrder()

        // Update existing order or add new one
        if let index = recentOrders.firstIndex(where: { $0.id == order.id }) {
            recentOrders[index] = order
        } else {
            recentOrders.insert(order, at: 0)
            if recentOrders.count > 10 {
                recentOrders = Array(recentOrders.prefix(10))
            }
        }
    }

    @MainActor
    private func handleOrderFill(_ payload: WebSocketOrderPayload) {
        let order = payload.toStockOrder()

        // Update existing order
        if let index = recentOrders.firstIndex(where: { $0.id == order.id }) {
            recentOrders[index] = order
        } else {
            recentOrders.insert(order, at: 0)
            if recentOrders.count > 10 {
                recentOrders = Array(recentOrders.prefix(10))
            }
        }

        // Show toast notification for filled orders
        if order.status == .filled {
            let displayType = "\(order.side.rawValue.capitalized) \(order.type.rawValue.capitalized)"
            ToastManager.shared.showSuccess(
                "Order filled: \(displayType) \(order.filledQuantity ?? 0) shares of \(order.symbol)"
            )

            // Refresh portfolio data to show updated positions
            Task {
                try? await loadPortfolioSummary()
            }
        } else if order.status == .partiallyFilled {
            ToastManager.shared.showInfo(
                "Order partially filled: \(order.filledQuantity) of \(order.quantity ?? 0) shares"
            )
        }
    }

    @MainActor
    private func handleOrderCancelled(_ payload: WebSocketOrderPayload) {
        let order = payload.toStockOrder()

        // Update existing order
        if let index = recentOrders.firstIndex(where: { $0.id == order.id }) {
            recentOrders[index] = order
        }

        // Show toast notification
        let displayType = "\(order.side.rawValue.capitalized) \(order.type.rawValue.capitalized)"
        ToastManager.shared.showInfo(
            "Order cancelled: \(displayType) \(order.symbol)"
        )
    }
}

// MARK: - Dashboard Error

enum DashboardError: LocalizedError {
    case noPortfolio

    var errorDescription: String? {
        switch self {
        case .noPortfolio:
            return "No portfolio found. Please create a portfolio first."
        }
    }
}

// MARK: - Dashboard Statistics

struct DashboardStatistics: Sendable {
    let totalValue: Decimal
    let todayChange: Decimal
    let todayChangePercent: Decimal
    let weekChange: Decimal
    let weekChangePercent: Decimal
    let monthChange: Decimal
    let monthChangePercent: Decimal
    let yearChange: Decimal
    let yearChangePercent: Decimal
    let allTimeReturn: Decimal
    let allTimeReturnPercent: Decimal

    static var empty: DashboardStatistics {
        DashboardStatistics(
            totalValue: 0,
            todayChange: 0,
            todayChangePercent: 0,
            weekChange: 0,
            weekChangePercent: 0,
            monthChange: 0,
            monthChangePercent: 0,
            yearChange: 0,
            yearChangePercent: 0,
            allTimeReturn: 0,
            allTimeReturnPercent: 0
        )
    }
}

// MARK: - Dashboard Widget

struct DashboardWidget: Identifiable, Sendable {
    let id: String
    let type: WidgetType
    var isEnabled: Bool
    var order: Int

    enum WidgetType: String, Sendable, CaseIterable {
        case portfolioSummary
        case quickActions
        case goalsProgress
        case dcaSchedules
        case recentActivity
        case marketSummary
        case aiInsights

        var title: String {
            switch self {
            case .portfolioSummary:
                return "Portfolio Summary"
            case .quickActions:
                return "Quick Actions"
            case .goalsProgress:
                return "Goals Progress"
            case .dcaSchedules:
                return "DCA Schedules"
            case .recentActivity:
                return "Recent Activity"
            case .marketSummary:
                return "Market Summary"
            case .aiInsights:
                return "AI Insights"
            }
        }

        var iconName: String {
            switch self {
            case .portfolioSummary:
                return "chart.pie.fill"
            case .quickActions:
                return "bolt.fill"
            case .goalsProgress:
                return "target"
            case .dcaSchedules:
                return "arrow.triangle.2.circlepath"
            case .recentActivity:
                return "clock.fill"
            case .marketSummary:
                return "chart.line.uptrend.xyaxis"
            case .aiInsights:
                return "sparkles"
            }
        }
    }

    static var defaultWidgets: [DashboardWidget] {
        WidgetType.allCases.enumerated().map { index, type in
            DashboardWidget(
                id: type.rawValue,
                type: type,
                isEnabled: true,
                order: index
            )
        }
    }
}
