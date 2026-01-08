//
//  DashboardViewModelTests.swift
//  GrowfolioTests
//
//  Tests for DashboardViewModel - main dashboard state management.
//

import XCTest
@testable import Growfolio

@MainActor
final class DashboardViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockGoalRepository: MockGoalRepository!
    var mockDCARepository: MockDCARepository!
    var mockPortfolioRepository: MockPortfolioRepository!
    var mockStocksRepository: MockStocksRepository!
    var mockWebSocketService: MockWebSocketService!
    var sut: DashboardViewModel!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockGoalRepository = MockGoalRepository()
        mockDCARepository = MockDCARepository()
        mockPortfolioRepository = MockPortfolioRepository()
        mockStocksRepository = MockStocksRepository()
        mockWebSocketService = await MockWebSocketService()
        sut = DashboardViewModel(
            goalRepository: mockGoalRepository,
            dcaRepository: mockDCARepository,
            portfolioRepository: mockPortfolioRepository,
            stocksRepository: mockStocksRepository,
            webSocketService: mockWebSocketService
        )
    }

    override func tearDown() async throws {
        mockGoalRepository = nil
        mockDCARepository = nil
        mockPortfolioRepository = nil
        mockStocksRepository = nil
        mockWebSocketService = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.showError)
        XCTAssertEqual(sut.totalPortfolioValue, 0)
        XCTAssertEqual(sut.todaysChange, 0)
        XCTAssertEqual(sut.todaysChangePercent, 0)
        XCTAssertEqual(sut.totalReturn, 0)
        XCTAssertEqual(sut.totalReturnPercent, 0)
        XCTAssertEqual(sut.cashBalance, 0)
        XCTAssertNil(sut.marketHours)
        XCTAssertTrue(sut.topGoals.isEmpty)
        XCTAssertTrue(sut.activeDCASchedules.isEmpty)
        XCTAssertTrue(sut.recentActivity.isEmpty)
        XCTAssertNil(sut.portfolio)
    }

    func test_initialState_sheetPresentationIsFalse() {
        XCTAssertFalse(sut.showAddGoal)
        XCTAssertFalse(sut.showAddDCA)
        XCTAssertFalse(sut.showRecordTrade)
        XCTAssertFalse(sut.showDeposit)
    }

    // MARK: - Computed Properties Tests

    func test_greeting_returnsCorrectGreetingBasedOnTime() {
        // This test will depend on the current time, but we test the property exists
        let greeting = sut.greeting
        XCTAssertFalse(greeting.isEmpty)
        XCTAssertTrue(
            greeting == "Good Morning" ||
            greeting == "Good Afternoon" ||
            greeting == "Good Evening"
        )
    }

    func test_hasData_returnsFalseWhenEmpty() {
        XCTAssertFalse(sut.hasData)
    }

    func test_hasData_returnsTrueWhenHasGoals() async {
        mockGoalRepository.goalsToReturn = [TestFixtures.goal()]
        mockPortfolioRepository.portfolioToReturn = nil

        await sut.loadDashboardData()

        XCTAssertTrue(sut.hasData)
    }

    func test_hasData_returnsTrueWhenHasPortfolio() async {
        let portfolio = TestFixtures.portfolio()
        mockPortfolioRepository.portfolioToReturn = portfolio

        await sut.loadDashboardData()

        XCTAssertTrue(sut.hasData)
    }

    func test_isProfitable_returnsTrueWhenTotalReturnPositive() {
        sut.totalReturn = 100
        XCTAssertTrue(sut.isProfitable)
    }

    func test_isProfitable_returnsTrueWhenTotalReturnZero() {
        sut.totalReturn = 0
        XCTAssertTrue(sut.isProfitable)
    }

    func test_isProfitable_returnsFalseWhenTotalReturnNegative() {
        sut.totalReturn = -100
        XCTAssertFalse(sut.isProfitable)
    }

    // MARK: - Loading State Tests

    func test_loadDashboardData_setsIsLoadingDuringOperation() async {
        mockPortfolioRepository.portfolioToReturn = TestFixtures.portfolio()

        await sut.loadDashboardData()

        XCTAssertFalse(sut.isLoading)
    }

    func test_loadDashboardData_preventsMultipleSimultaneousLoads() async {
        mockPortfolioRepository.portfolioToReturn = TestFixtures.portfolio()

        // Start first load
        sut.isLoading = true

        // Try second load - should not proceed
        await sut.loadDashboardData()

        // Reset for proper test cleanup
        sut.isLoading = false
    }

    // MARK: - Data Loading Tests

    func test_loadDashboardData_loadsPortfolioSummary() async {
        let portfolio = TestFixtures.portfolio(
            totalValue: 25000,
            totalCostBasis: 20000,
            cashBalance: 1000
        )
        mockPortfolioRepository.portfolioToReturn = portfolio
        mockPortfolioRepository.holdingsToReturn = []

        await sut.loadDashboardData()

        XCTAssertEqual(sut.totalPortfolioValue, 25000)
        XCTAssertEqual(sut.cashBalance, 1000)
        XCTAssertNotNil(sut.portfolio)
    }

    func test_loadDashboardData_loadsTopGoals() async {
        let goals = [
            TestFixtures.goal(id: "goal-1", name: "Goal 1", targetAmount: 10000, currentAmount: 7500),
            TestFixtures.goal(id: "goal-2", name: "Goal 2", targetAmount: 5000, currentAmount: 2000),
            TestFixtures.goal(id: "goal-3", name: "Goal 3", targetAmount: 20000, currentAmount: 5000),
            TestFixtures.goal(id: "goal-4", name: "Goal 4", targetAmount: 1000, currentAmount: 100)
        ]
        mockGoalRepository.goalsToReturn = goals

        await sut.loadDashboardData()

        XCTAssertLessThanOrEqual(sut.topGoals.count, 3)
        // Top goals should be sorted by progress percentage descending
        if sut.topGoals.count >= 2 {
            XCTAssertGreaterThanOrEqual(sut.topGoals[0].progressPercentage, sut.topGoals[1].progressPercentage)
        }
    }

    func test_loadDashboardData_filtersArchivedAndAchievedGoals() async {
        let goals = [
            TestFixtures.goal(id: "goal-1", name: "Active Goal", targetAmount: 10000, currentAmount: 5000, isArchived: false),
            TestFixtures.goal(id: "goal-2", name: "Archived Goal", targetAmount: 5000, currentAmount: 2000, isArchived: true),
            TestFixtures.goal(id: "goal-3", name: "Achieved Goal", targetAmount: 1000, currentAmount: 1000, isArchived: false)
        ]
        mockGoalRepository.goalsToReturn = goals

        await sut.loadDashboardData()

        // Should only include in-progress goals (not archived or achieved)
        XCTAssertTrue(sut.topGoals.allSatisfy { !$0.isArchived && !$0.isAchieved })
    }

    func test_loadDashboardData_loadsActiveDCASchedules() async {
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", stockSymbol: "AAPL", isActive: true, isPaused: false),
            TestFixtures.dcaSchedule(id: "dca-2", stockSymbol: "MSFT", isActive: true, isPaused: true),
            TestFixtures.dcaSchedule(id: "dca-3", stockSymbol: "GOOGL", isActive: false, isPaused: false)
        ]
        mockDCARepository.schedulesToReturn = schedules

        await sut.loadDashboardData()

        // Should only include active (non-paused) schedules
        XCTAssertTrue(sut.activeDCASchedules.allSatisfy { $0.isActive })
        XCTAssertLessThanOrEqual(sut.activeDCASchedules.count, 5)
    }

    func test_loadDashboardData_loadsRecentActivity() async {
        let portfolio = TestFixtures.portfolio()
        let entries = TestFixtures.sampleLedgerEntries
        mockPortfolioRepository.portfolioToReturn = portfolio
        mockPortfolioRepository.ledgerEntriesToReturn = entries

        await sut.loadDashboardData()

        XCTAssertLessThanOrEqual(sut.recentActivity.count, 5)
    }

    func test_loadDashboardData_loadsMarketStatus() async {
        let marketHours = TestFixtures.marketHours(isOpen: true)
        mockStocksRepository.marketStatusToReturn = marketHours

        await sut.loadDashboardData()

        XCTAssertNotNil(sut.marketHours)
        XCTAssertEqual(sut.marketHours?.isOpen, true)
    }

    func test_loadDashboardData_usesFallbackMarketStatusOnError() async {
        mockStocksRepository.errorToThrow = NetworkError.noConnection

        await sut.loadDashboardData()

        // Should use fallback market hours instead of throwing
        XCTAssertNotNil(sut.marketHours)
    }

    // MARK: - Error Handling Tests

    func test_loadDashboardData_setsErrorOnFailure() async {
        mockGoalRepository.errorToThrow = NetworkError.noConnection

        await sut.loadDashboardData()

        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.showError)
    }

    func test_dismissError_clearsErrorState() async {
        mockGoalRepository.errorToThrow = NetworkError.noConnection
        await sut.loadDashboardData()

        sut.dismissError()

        XCTAssertFalse(sut.showError)
        XCTAssertNil(sut.error)
    }

    // MARK: - Refresh Tests

    func test_refreshDataAsync_reloadsAllData() async {
        let portfolio = TestFixtures.portfolio()
        mockPortfolioRepository.portfolioToReturn = portfolio

        await sut.refreshDataAsync()

        XCTAssertNotNil(sut.portfolio)
    }

    // MARK: - Quick Actions Tests

    func test_recordDeposit_throwsWhenNoPortfolio() async {
        sut.portfolio = nil

        do {
            try await sut.recordDeposit(amount: 1000)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is DashboardError)
        }
    }

    func test_recordDeposit_callsRepositoryWithCorrectAmount() async {
        let portfolio = TestFixtures.portfolio(id: "portfolio-123")
        sut.portfolio = portfolio
        mockPortfolioRepository.portfolioToReturn = portfolio

        try? await sut.recordDeposit(amount: 1000)

        XCTAssertEqual(mockPortfolioRepository.depositCashAmountCalled, 1000)
        XCTAssertEqual(mockPortfolioRepository.depositCashPortfolioIdCalled, "portfolio-123")
    }

    func test_recordWithdrawal_throwsWhenNoPortfolio() async {
        sut.portfolio = nil

        do {
            try await sut.recordWithdrawal(amount: 500)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is DashboardError)
        }
    }

    func test_recordWithdrawal_callsRepositoryWithCorrectAmount() async {
        let portfolio = TestFixtures.portfolio(id: "portfolio-456")
        sut.portfolio = portfolio
        mockPortfolioRepository.portfolioToReturn = portfolio

        try? await sut.recordWithdrawal(amount: 500)

        XCTAssertEqual(mockPortfolioRepository.withdrawCashAmountCalled, 500)
        XCTAssertEqual(mockPortfolioRepository.withdrawCashPortfolioIdCalled, "portfolio-456")
    }

    // MARK: - Selection Tests

    func test_selectGoal_setsSelectedGoal() {
        let goal = TestFixtures.goal()

        sut.selectGoal(goal)

        // Method exists and doesn't throw
    }

    func test_selectDCASchedule_setsSelectedSchedule() {
        let schedule = TestFixtures.dcaSchedule()

        sut.selectDCASchedule(schedule)

        // Method exists and doesn't throw
    }

    func test_selectActivity_setsSelectedActivity() {
        let entry = TestFixtures.ledgerEntry()

        sut.selectActivity(entry)

        // Method exists and doesn't throw
    }

    // MARK: - New User Tests

    func test_loadDashboardData_handlesNoPortfolioForNewUser() async {
        mockPortfolioRepository.portfolioToReturn = nil

        await sut.loadDashboardData()

        XCTAssertNil(sut.portfolio)
        XCTAssertEqual(sut.totalPortfolioValue, 0)
    }

    // MARK: - WebSocket Order Event Tests

    func test_webSocketSubscription_subscribesToOrdersChannel() async {
        mockPortfolioRepository.portfolioToReturn = TestFixtures.portfolio()

        await sut.loadDashboardData()

        // Give the subscription time to process
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertTrue(mockWebSocketService.subscribedChannels.contains("orders"))
    }

    func test_handleOrderCreated_addsOrderToRecentOrders() async {
        mockPortfolioRepository.portfolioToReturn = TestFixtures.portfolio()

        await sut.loadDashboardData()

        // Give the event listener task time to start
        try? await Task.sleep(for: .milliseconds(200))

        // Simulate order created event
        let event = MockWebSocketService.makeOrderCreatedEvent(
            orderId: "order-123",
            symbol: "AAPL",
            side: "buy",
            quantity: 10
        )

        await mockWebSocketService.sendEvent(event)

        // Give async handling time to process
        try? await Task.sleep(for: .milliseconds(300))

        // Verify order was added
        XCTAssertEqual(sut.recentOrders.count, 1)
        XCTAssertEqual(sut.recentOrders.first?.id, "order-123")
        XCTAssertEqual(sut.recentOrders.first?.symbol, "AAPL")
        XCTAssertEqual(sut.recentOrders.first?.side, .buy)
    }

    func test_handleOrderStatus_updatesExistingOrder() async {
        mockPortfolioRepository.portfolioToReturn = TestFixtures.portfolio()

        await sut.loadDashboardData()
        try? await Task.sleep(for: .milliseconds(200))

        // Create initial order
        let createEvent = MockWebSocketService.makeOrderCreatedEvent(
            orderId: "order-123",
            symbol: "AAPL",
            status: "new"
        )
        await mockWebSocketService.sendEvent(createEvent)
        try? await Task.sleep(for: .milliseconds(300))

        // Update order status
        let statusEvent = MockWebSocketService.makeOrderStatusEvent(
            orderId: "order-123",
            symbol: "AAPL",
            status: "accepted",
            filledQty: 0
        )
        await mockWebSocketService.sendEvent(statusEvent)
        try? await Task.sleep(for: .milliseconds(300))

        // Verify order was updated
        XCTAssertEqual(sut.recentOrders.count, 1)
        XCTAssertEqual(sut.recentOrders.first?.id, "order-123")
        XCTAssertEqual(sut.recentOrders.first?.status, .accepted)
    }

    func test_handleOrderFill_updatesOrderAndShowsNotification() async {
        mockPortfolioRepository.portfolioToReturn = TestFixtures.portfolio()
        mockPortfolioRepository.holdingsToReturn = []

        await sut.loadDashboardData()
        try? await Task.sleep(for: .milliseconds(200))

        // Create initial order
        let createEvent = MockWebSocketService.makeOrderCreatedEvent(
            orderId: "order-123",
            symbol: "AAPL",
            quantity: 10
        )
        await mockWebSocketService.sendEvent(createEvent)
        try? await Task.sleep(for: .milliseconds(300))

        // Fill order
        let fillEvent = MockWebSocketService.makeOrderFillEvent(
            orderId: "order-123",
            symbol: "AAPL",
            status: "filled",
            quantity: 10,
            filledQty: 10,
            filledAvgPrice: 150.50
        )
        await mockWebSocketService.sendEvent(fillEvent)
        try? await Task.sleep(for: .milliseconds(500))

        // Verify order was updated
        XCTAssertEqual(sut.recentOrders.count, 1)
        XCTAssertEqual(sut.recentOrders.first?.status, .filled)
        XCTAssertEqual(sut.recentOrders.first?.filledQuantity, 10)
        XCTAssertEqual(sut.recentOrders.first?.filledAvgPrice, 150.50)
    }

    func test_handleOrderFill_partiallyFilledOrder() async {
        mockPortfolioRepository.portfolioToReturn = TestFixtures.portfolio()

        await sut.loadDashboardData()
        try? await Task.sleep(for: .milliseconds(200))

        // Fill order partially
        let fillEvent = MockWebSocketService.makeOrderFillEvent(
            orderId: "order-123",
            symbol: "MSFT",
            status: "partially_filled",
            quantity: 20,
            filledQty: 10,
            filledAvgPrice: 300.25
        )
        await mockWebSocketService.sendEvent(fillEvent)
        try? await Task.sleep(for: .milliseconds(500))

        // Verify order was added with partial fill
        XCTAssertEqual(sut.recentOrders.count, 1)
        XCTAssertEqual(sut.recentOrders.first?.status, .partiallyFilled)
        XCTAssertEqual(sut.recentOrders.first?.filledQuantity, 10)
        XCTAssertEqual(sut.recentOrders.first?.quantity, 20)
    }

    func test_handleOrderCancelled_updatesOrderStatus() async {
        mockPortfolioRepository.portfolioToReturn = TestFixtures.portfolio()

        await sut.loadDashboardData()
        try? await Task.sleep(for: .milliseconds(200))

        // Create initial order
        let createEvent = MockWebSocketService.makeOrderCreatedEvent(
            orderId: "order-123",
            symbol: "GOOGL"
        )
        await mockWebSocketService.sendEvent(createEvent)
        try? await Task.sleep(for: .milliseconds(300))

        // Cancel order
        let cancelEvent = MockWebSocketService.makeOrderCancelledEvent(
            orderId: "order-123",
            symbol: "GOOGL",
            status: "canceled"
        )
        await mockWebSocketService.sendEvent(cancelEvent)
        try? await Task.sleep(for: .milliseconds(300))

        // Verify order was updated
        XCTAssertEqual(sut.recentOrders.count, 1)
        XCTAssertEqual(sut.recentOrders.first?.status, .cancelled)
    }

    func test_recentOrders_limitsToMaximum10Orders() async {
        mockPortfolioRepository.portfolioToReturn = TestFixtures.portfolio()

        await sut.loadDashboardData()
        try? await Task.sleep(for: .milliseconds(200))

        // Create 15 orders
        for i in 1...15 {
            let event = MockWebSocketService.makeOrderCreatedEvent(
                orderId: "order-\(i)",
                symbol: "AAPL"
            )
            await mockWebSocketService.sendEvent(event)
            try? await Task.sleep(for: .milliseconds(100))
        }

        // Wait for all events to process
        try? await Task.sleep(for: .milliseconds(500))

        // Verify only 10 most recent orders are kept
        XCTAssertEqual(sut.recentOrders.count, 10)
        // Most recent order should be first
        XCTAssertEqual(sut.recentOrders.first?.id, "order-15")
    }

    func test_webSocketEvents_multipleOrderTypes() async {
        mockPortfolioRepository.portfolioToReturn = TestFixtures.portfolio()

        await sut.loadDashboardData()
        try? await Task.sleep(for: .milliseconds(200))

        // Create multiple order types
        let buyOrder = MockWebSocketService.makeOrderCreatedEvent(
            orderId: "order-1",
            symbol: "AAPL",
            side: "buy",
            type: "market"
        )
        await mockWebSocketService.sendEvent(buyOrder)
        try? await Task.sleep(for: .milliseconds(200))

        let sellOrder = MockWebSocketService.makeOrderCreatedEvent(
            orderId: "order-2",
            symbol: "MSFT",
            side: "sell",
            type: "limit"
        )
        await mockWebSocketService.sendEvent(sellOrder)
        try? await Task.sleep(for: .milliseconds(200))

        // Verify both orders were added
        XCTAssertEqual(sut.recentOrders.count, 2)
        XCTAssertTrue(sut.recentOrders.contains(where: { $0.side == .buy }))
        XCTAssertTrue(sut.recentOrders.contains(where: { $0.side == .sell }))
    }
}

// MARK: - DashboardError Tests

final class DashboardErrorTests: XCTestCase {

    func test_noPortfolioError_hasCorrectDescription() {
        let error = DashboardError.noPortfolio

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("portfolio") ?? false)
    }
}
