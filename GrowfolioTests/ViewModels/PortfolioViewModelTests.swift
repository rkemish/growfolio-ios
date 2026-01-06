//
//  PortfolioViewModelTests.swift
//  GrowfolioTests
//
//  Tests for PortfolioViewModel - portfolio data loading, holdings, and performance.
//

import XCTest
@testable import Growfolio

@MainActor
final class PortfolioViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockRepository: MockPortfolioRepository!
    var sut: PortfolioViewModel!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockPortfolioRepository()
        sut = PortfolioViewModel(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isRefreshing)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.showError)
        XCTAssertTrue(sut.portfolios.isEmpty)
        XCTAssertNil(sut.selectedPortfolio)
        XCTAssertTrue(sut.holdings.isEmpty)
        XCTAssertTrue(sut.transactions.isEmpty)
        XCTAssertEqual(sut.selectedPeriod, .oneMonth)
    }

    func test_initialState_viewStateProperties() {
        XCTAssertFalse(sut.showHoldingDetail)
        XCTAssertNil(sut.selectedHolding)
        XCTAssertFalse(sut.showTransactionHistory)
        XCTAssertFalse(sut.showAddTransaction)
    }

    // MARK: - Computed Properties Tests - Empty State

    func test_currentPortfolio_returnsNilWhenNoPortfolios() {
        XCTAssertNil(sut.currentPortfolio)
    }

    func test_totalValue_returnsZeroWhenNoPortfolio() {
        XCTAssertEqual(sut.totalValue, 0)
    }

    func test_totalReturn_returnsZeroWhenNoPortfolio() {
        XCTAssertEqual(sut.totalReturn, 0)
    }

    func test_totalReturnPercentage_returnsZeroWhenNoPortfolio() {
        XCTAssertEqual(sut.totalReturnPercentage, 0)
    }

    func test_cashBalance_returnsZeroWhenNoPortfolio() {
        XCTAssertEqual(sut.cashBalance, 0)
    }

    func test_isProfitable_returnsFalseWhenNoPortfolio() {
        XCTAssertFalse(sut.isProfitable)
    }

    func test_hasHoldings_returnsFalseWhenEmpty() {
        XCTAssertFalse(sut.hasHoldings)
    }

    func test_isEmpty_returnsTrueWhenNoHoldingsAndNotLoading() {
        XCTAssertTrue(sut.isEmpty)
    }

    // MARK: - Computed Properties Tests - With Data

    func test_currentPortfolio_returnsSelectedPortfolio() async {
        let portfolio = MockPortfolioRepository.samplePortfolio()
        mockRepository.portfoliosToReturn = [portfolio]

        await sut.loadPortfolioData()

        XCTAssertEqual(sut.currentPortfolio?.id, portfolio.id)
    }

    func test_currentPortfolio_returnsFirstPortfolioWhenNoneSelected() async {
        let portfolio1 = MockPortfolioRepository.samplePortfolio(id: "p1", name: "First")
        let portfolio2 = MockPortfolioRepository.samplePortfolio(id: "p2", name: "Second")
        mockRepository.portfoliosToReturn = [portfolio1, portfolio2]

        await sut.loadPortfolioData()

        XCTAssertEqual(sut.currentPortfolio?.id, "p1")
    }

    func test_totalValue_returnsPortfolioTotalValue() async {
        let portfolio = MockPortfolioRepository.samplePortfolio(totalValue: 15000)
        mockRepository.portfoliosToReturn = [portfolio]

        await sut.loadPortfolioData()

        XCTAssertEqual(sut.totalValue, 15000)
    }

    func test_totalReturn_calculatesCorrectly() async {
        let portfolio = MockPortfolioRepository.samplePortfolio(
            totalValue: 12000,
            totalCostBasis: 10000
        )
        mockRepository.portfoliosToReturn = [portfolio]

        await sut.loadPortfolioData()

        XCTAssertEqual(sut.totalReturn, 2000)
    }

    func test_isProfitable_returnsTrueWhenPositiveReturn() async {
        let portfolio = MockPortfolioRepository.samplePortfolio(
            totalValue: 12000,
            totalCostBasis: 10000
        )
        mockRepository.portfoliosToReturn = [portfolio]

        await sut.loadPortfolioData()

        XCTAssertTrue(sut.isProfitable)
    }

    func test_isProfitable_returnsFalseWhenNegativeReturn() async {
        let portfolio = MockPortfolioRepository.samplePortfolio(
            totalValue: 8000,
            totalCostBasis: 10000
        )
        mockRepository.portfoliosToReturn = [portfolio]

        await sut.loadPortfolioData()

        XCTAssertFalse(sut.isProfitable)
    }

    func test_sortedHoldings_sortsByMarketValueDescending() async {
        let holding1 = MockPortfolioRepository.sampleHolding(id: "h1", symbol: "AAPL", quantity: 10, currentPrice: 100) // value: 1000
        let holding2 = MockPortfolioRepository.sampleHolding(id: "h2", symbol: "MSFT", quantity: 5, currentPrice: 300) // value: 1500
        let holding3 = MockPortfolioRepository.sampleHolding(id: "h3", symbol: "GOOGL", quantity: 2, currentPrice: 200) // value: 400

        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]
        mockRepository.holdingsToReturn = [holding1, holding2, holding3]

        await sut.loadPortfolioData()

        XCTAssertEqual(sut.sortedHoldings.count, 3)
        XCTAssertEqual(sut.sortedHoldings[0].stockSymbol, "MSFT")
        XCTAssertEqual(sut.sortedHoldings[1].stockSymbol, "AAPL")
        XCTAssertEqual(sut.sortedHoldings[2].stockSymbol, "GOOGL")
    }

    func test_topHoldings_returnsMaxFiveHoldings() async {
        let holdings = (1...7).map { i in
            MockPortfolioRepository.sampleHolding(id: "h\(i)", symbol: "SYM\(i)", quantity: Decimal(i) * 10, currentPrice: 100)
        }
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]
        mockRepository.holdingsToReturn = holdings

        await sut.loadPortfolioData()

        XCTAssertEqual(sut.topHoldings.count, 5)
    }

    func test_recentTransactions_returnsMaxTenTransactions() async {
        let transactions = (1...15).map { i in
            MockPortfolioRepository.sampleLedgerEntry(portfolioId: "p1", type: .buy, amount: Decimal(i) * 100)
        }
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]
        mockRepository.ledgerEntriesToReturn = transactions

        await sut.loadPortfolioData()

        XCTAssertEqual(sut.recentTransactions.count, 10)
    }

    func test_hasHoldings_returnsTrueWhenHoldingsExist() async {
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]
        mockRepository.holdingsToReturn = [MockPortfolioRepository.sampleHolding()]

        await sut.loadPortfolioData()

        XCTAssertTrue(sut.hasHoldings)
    }

    func test_isEmpty_returnsFalseWhenHoldingsExist() async {
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]
        mockRepository.holdingsToReturn = [MockPortfolioRepository.sampleHolding()]

        await sut.loadPortfolioData()

        XCTAssertFalse(sut.isEmpty)
    }

    // MARK: - Load Portfolio Data Tests

    func test_loadPortfolioData_setsIsLoading() async {
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]

        await sut.loadPortfolioData()

        // isLoading should be false after completion
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadPortfolioData_fetchesPortfolios() async {
        let portfolio = MockPortfolioRepository.samplePortfolio()
        mockRepository.portfoliosToReturn = [portfolio]

        await sut.loadPortfolioData()

        XCTAssertTrue(mockRepository.fetchPortfoliosCalled)
        XCTAssertEqual(sut.portfolios.count, 1)
        XCTAssertEqual(sut.portfolios.first?.id, portfolio.id)
    }

    func test_loadPortfolioData_setsDefaultSelectedPortfolio() async {
        let portfolio = MockPortfolioRepository.samplePortfolio()
        mockRepository.portfoliosToReturn = [portfolio]

        await sut.loadPortfolioData()

        XCTAssertEqual(sut.selectedPortfolio?.id, portfolio.id)
    }

    func test_loadPortfolioData_fetchesHoldingsForCurrentPortfolio() async {
        let portfolio = MockPortfolioRepository.samplePortfolio(id: "test-portfolio")
        let holding = MockPortfolioRepository.sampleHolding(portfolioId: "test-portfolio")
        mockRepository.portfoliosToReturn = [portfolio]
        mockRepository.holdingsToReturn = [holding]

        await sut.loadPortfolioData()

        XCTAssertEqual(mockRepository.fetchHoldingsPortfolioIdCalled, "test-portfolio")
        XCTAssertEqual(sut.holdings.count, 1)
    }

    func test_loadPortfolioData_fetchesLedgerEntries() async {
        let portfolio = MockPortfolioRepository.samplePortfolio(id: "test-portfolio")
        let entry = MockPortfolioRepository.sampleLedgerEntry(portfolioId: "test-portfolio")
        mockRepository.portfoliosToReturn = [portfolio]
        mockRepository.ledgerEntriesToReturn = [entry]

        await sut.loadPortfolioData()

        XCTAssertEqual(mockRepository.fetchLedgerEntriesPortfolioIdCalled, "test-portfolio")
        XCTAssertEqual(sut.transactions.count, 1)
    }

    func test_loadPortfolioData_doesNotFetchIfAlreadyLoading() async {
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]
        sut.isLoading = true

        await sut.loadPortfolioData()

        XCTAssertFalse(mockRepository.fetchPortfoliosCalled)
    }

    func test_loadPortfolioData_setsErrorOnFailure() async {
        mockRepository.errorToThrow = NetworkError.noConnection

        await sut.loadPortfolioData()

        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.showError)
    }

    func test_loadPortfolioData_clearsErrorBeforeLoading() async {
        sut.error = NetworkError.noConnection
        sut.showError = true
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]

        await sut.loadPortfolioData()

        XCTAssertNil(sut.error)
    }

    // MARK: - Refresh Portfolio Data Tests

    func test_refreshPortfolioData_setsIsRefreshing() async {
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]

        await sut.refreshPortfolioData()

        // isRefreshing should be false after completion
        XCTAssertFalse(sut.isRefreshing)
    }

    func test_refreshPortfolioData_invalidatesCache() async {
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]

        await sut.refreshPortfolioData()

        XCTAssertTrue(mockRepository.invalidateCacheCalled)
    }

    func test_refreshPortfolioData_reloadsData() async {
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]

        await sut.refreshPortfolioData()

        XCTAssertTrue(mockRepository.fetchPortfoliosCalled)
    }

    // MARK: - Refresh Prices Tests

    func test_refreshPrices_fetchesUpdatedPrices() async {
        let portfolio = MockPortfolioRepository.samplePortfolio()
        mockRepository.portfoliosToReturn = [portfolio]
        await sut.loadPortfolioData()

        let updatedHolding = MockPortfolioRepository.sampleHolding(currentPrice: 200)
        mockRepository.holdingsToReturn = [updatedHolding]

        await sut.refreshPrices()

        XCTAssertEqual(mockRepository.refreshHoldingPricesPortfolioIdCalled, portfolio.id)
    }

    func test_refreshPrices_doesNothingWhenNoPortfolio() async {
        await sut.refreshPrices()

        XCTAssertNil(mockRepository.refreshHoldingPricesPortfolioIdCalled)
    }

    func test_refreshPrices_setsErrorOnFailure() async {
        let portfolio = MockPortfolioRepository.samplePortfolio()
        mockRepository.portfoliosToReturn = [portfolio]
        await sut.loadPortfolioData()

        mockRepository.errorToThrow = NetworkError.noConnection

        await sut.refreshPrices()

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Portfolio Selection Tests

    func test_selectPortfolio_updatesSelectedPortfolio() async {
        let portfolio1 = MockPortfolioRepository.samplePortfolio(id: "p1")
        let portfolio2 = MockPortfolioRepository.samplePortfolio(id: "p2")
        mockRepository.portfoliosToReturn = [portfolio1, portfolio2]
        await sut.loadPortfolioData()

        await sut.selectPortfolio(portfolio2)

        XCTAssertEqual(sut.selectedPortfolio?.id, "p2")
    }

    func test_selectPortfolio_loadsHoldingsForSelectedPortfolio() async {
        let portfolio1 = MockPortfolioRepository.samplePortfolio(id: "p1")
        let portfolio2 = MockPortfolioRepository.samplePortfolio(id: "p2")
        mockRepository.portfoliosToReturn = [portfolio1, portfolio2]
        await sut.loadPortfolioData()

        let holding = MockPortfolioRepository.sampleHolding(portfolioId: "p2")
        mockRepository.holdingsToReturn = [holding]

        await sut.selectPortfolio(portfolio2)

        XCTAssertEqual(mockRepository.fetchHoldingsPortfolioIdCalled, "p2")
    }

    // MARK: - Error Handling Tests

    func test_dismissError_clearsErrorState() {
        sut.error = NetworkError.noConnection
        sut.showError = true

        sut.dismissError()

        XCTAssertFalse(sut.showError)
        XCTAssertNil(sut.error)
    }

    // MARK: - Holding Selection Tests

    func test_selectHolding_setsSelectedHolding() async {
        let holding = MockPortfolioRepository.sampleHolding()
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]
        mockRepository.holdingsToReturn = [holding]
        await sut.loadPortfolioData()

        sut.selectHolding(holding)

        XCTAssertEqual(sut.selectedHolding?.id, holding.id)
        XCTAssertTrue(sut.showHoldingDetail)
    }

    // MARK: - Transaction Tests

    func test_addTransaction_callsRepository() async throws {
        let portfolio = MockPortfolioRepository.samplePortfolio(id: "test-portfolio")
        mockRepository.portfoliosToReturn = [portfolio]
        await sut.loadPortfolioData()

        try await sut.addTransaction(
            type: .buy,
            stockSymbol: "AAPL",
            quantity: 10,
            pricePerShare: 150,
            totalAmount: 1500,
            notes: "Test purchase"
        )

        XCTAssertTrue(mockRepository.addLedgerEntryCalled)
        XCTAssertEqual(mockRepository.lastAddedLedgerEntry?.stockSymbol, "AAPL")
        XCTAssertEqual(mockRepository.lastAddedLedgerEntry?.quantity, 10)
    }

    func test_addTransaction_refreshesPortfolioData() async throws {
        let portfolio = MockPortfolioRepository.samplePortfolio()
        mockRepository.portfoliosToReturn = [portfolio]
        await sut.loadPortfolioData()
        mockRepository.fetchPortfoliosCalled = false

        try await sut.addTransaction(
            type: .deposit,
            stockSymbol: nil,
            quantity: nil,
            pricePerShare: nil,
            totalAmount: 1000,
            notes: nil
        )

        // Refresh should have been called
        XCTAssertTrue(mockRepository.invalidateCacheCalled)
    }

    func test_deposit_callsRepositoryWithCorrectAmount() async throws {
        let portfolio = MockPortfolioRepository.samplePortfolio(id: "test-portfolio")
        mockRepository.portfoliosToReturn = [portfolio]
        await sut.loadPortfolioData()

        try await sut.deposit(amount: 5000, notes: "Initial deposit")

        XCTAssertEqual(mockRepository.depositCashAmountCalled, 5000)
        XCTAssertEqual(mockRepository.depositCashPortfolioIdCalled, "test-portfolio")
    }

    func test_withdraw_callsRepositoryWithCorrectAmount() async throws {
        let portfolio = MockPortfolioRepository.samplePortfolio(id: "test-portfolio")
        mockRepository.portfoliosToReturn = [portfolio]
        await sut.loadPortfolioData()

        try await sut.withdraw(amount: 1000, notes: "Withdrawal")

        XCTAssertEqual(mockRepository.withdrawCashAmountCalled, 1000)
        XCTAssertEqual(mockRepository.withdrawCashPortfolioIdCalled, "test-portfolio")
    }

    // MARK: - Allocation Tests

    func test_allocationByHolding_calculatesPercentagesCorrectly() async {
        let holding1 = MockPortfolioRepository.sampleHolding(id: "h1", symbol: "AAPL", quantity: 10, currentPrice: 100) // value: 1000
        let holding2 = MockPortfolioRepository.sampleHolding(id: "h2", symbol: "MSFT", quantity: 10, currentPrice: 100) // value: 1000

        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]
        mockRepository.holdingsToReturn = [holding1, holding2]

        await sut.loadPortfolioData()

        let allocation = sut.allocationByHolding
        XCTAssertEqual(allocation.count, 2)

        // Each holding should be 50%
        for item in allocation {
            XCTAssertEqual(item.percentage, 50, accuracy: 0.01)
        }
    }

    func test_allocationByHolding_returnsEmptyWhenNoHoldings() async {
        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]
        mockRepository.holdingsToReturn = []

        await sut.loadPortfolioData()

        XCTAssertTrue(sut.allocationByHolding.isEmpty)
    }

    // MARK: - Holdings Summary Tests

    func test_holdingsSummary_calculatesCorrectly() async {
        let holding1 = MockPortfolioRepository.sampleHolding(
            id: "h1",
            symbol: "AAPL",
            quantity: 10,
            averageCost: 100,
            currentPrice: 150 // profitable
        )
        let holding2 = MockPortfolioRepository.sampleHolding(
            id: "h2",
            symbol: "MSFT",
            quantity: 5,
            averageCost: 300,
            currentPrice: 250 // loss
        )

        mockRepository.portfoliosToReturn = [MockPortfolioRepository.samplePortfolio()]
        mockRepository.holdingsToReturn = [holding1, holding2]

        await sut.loadPortfolioData()

        let summary = sut.holdingsSummary
        XCTAssertEqual(summary.totalHoldings, 2)
        XCTAssertEqual(summary.profitableHoldings, 1)
        XCTAssertEqual(summary.unprofitableHoldings, 1)
    }
}
