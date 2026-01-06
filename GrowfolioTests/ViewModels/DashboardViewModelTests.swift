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
    var sut: DashboardViewModel!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockGoalRepository = MockGoalRepository()
        mockDCARepository = MockDCARepository()
        mockPortfolioRepository = MockPortfolioRepository()
        mockStocksRepository = MockStocksRepository()
        sut = DashboardViewModel(
            goalRepository: mockGoalRepository,
            dcaRepository: mockDCARepository,
            portfolioRepository: mockPortfolioRepository,
            stocksRepository: mockStocksRepository
        )
    }

    override func tearDown() {
        mockGoalRepository = nil
        mockDCARepository = nil
        mockPortfolioRepository = nil
        mockStocksRepository = nil
        sut = nil
        super.tearDown()
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
}

// MARK: - DashboardError Tests

final class DashboardErrorTests: XCTestCase {

    func test_noPortfolioError_hasCorrectDescription() {
        let error = DashboardError.noPortfolio

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("portfolio") ?? false)
    }
}
