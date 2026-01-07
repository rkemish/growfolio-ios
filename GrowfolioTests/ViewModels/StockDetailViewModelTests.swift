//
//  StockDetailViewModelTests.swift
//  GrowfolioTests
//
//  Tests for StockDetailViewModel - stock info loading, buy actions, watchlist, and DCA.
//

import XCTest
@testable import Growfolio

@MainActor
final class StockDetailViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockStocksRepository: MockStocksRepository!
    var mockAIRepository: StubAIRepository!
    var sut: StockDetailViewModel!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockStocksRepository = MockStocksRepository()
        mockAIRepository = StubAIRepository()
        sut = StockDetailViewModel(
            symbol: "AAPL",
            stocksRepository: mockStocksRepository,
            aiRepository: mockAIRepository
        )
    }

    override func tearDown() {
        mockStocksRepository = nil
        mockAIRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isLoadingPrice)
        XCTAssertFalse(sut.isLoadingExplanation)
        XCTAssertFalse(sut.isLoadingWatchlist)
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.stock)
        XCTAssertNil(sut.quote)
        XCTAssertNil(sut.history)
        XCTAssertNil(sut.aiExplanation)
        XCTAssertNil(sut.marketHours)
        XCTAssertEqual(sut.selectedPeriod, .oneMonth)
    }

    func test_initialState_symbolIsUppercased() {
        let lowercaseSut = StockDetailViewModel(
            symbol: "aapl",
            stocksRepository: mockStocksRepository,
            aiRepository: mockAIRepository
        )

        XCTAssertEqual(lowercaseSut.symbol, "AAPL")
    }

    func test_initialState_sheetPresentationStates() {
        XCTAssertFalse(sut.showBuySheet)
        XCTAssertFalse(sut.showAddToDCASheet)
        XCTAssertFalse(sut.showFullDescription)
    }

    func test_initialState_watchlistState() {
        XCTAssertFalse(sut.isInWatchlist)
    }

    // MARK: - Computed Properties Tests - Without Data

    func test_displayPrice_returnsDashesWhenNoData() {
        XCTAssertEqual(sut.displayPrice, "--")
    }

    func test_currentPriceDecimal_returnsNilWhenNoData() {
        XCTAssertNil(sut.currentPriceDecimal)
    }

    func test_priceChange_returnsDashesWhenNoData() {
        XCTAssertEqual(sut.priceChange, "--")
    }

    func test_priceChangePercent_returnsDashesWhenNoData() {
        XCTAssertEqual(sut.priceChangePercent, "--")
    }

    func test_isPriceUp_returnsTrueByDefault() {
        XCTAssertTrue(sut.isPriceUp)
    }

    func test_companyName_returnsSymbolWhenNoStock() {
        XCTAssertEqual(sut.companyName, "AAPL")
    }

    func test_hasDescription_returnsFalseWhenNoStock() {
        XCTAssertFalse(sut.hasDescription)
    }

    // MARK: - Computed Properties Tests - With Quote Data

    func test_displayPrice_returnsQuotePriceWhenAvailable() async {
        let quote = MockStocksRepository.sampleQuote(price: 185.92)
        mockStocksRepository.quoteToReturn = quote
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        XCTAssertTrue(sut.displayPrice.contains("185"))
    }

    func test_currentPriceDecimal_returnsQuotePrice() async {
        let quote = MockStocksRepository.sampleQuote(price: 185.92)
        mockStocksRepository.quoteToReturn = quote
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        XCTAssertEqual(sut.currentPriceDecimal, 185.92)
    }

    func test_isPriceUp_returnsTrueForPositiveChange() async {
        let quote = MockStocksRepository.sampleQuote(change: 2.34)
        mockStocksRepository.quoteToReturn = quote
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        XCTAssertTrue(sut.isPriceUp)
    }

    func test_isPriceUp_returnsFalseForNegativeChange() async {
        let quote = MockStocksRepository.sampleQuote(change: -2.34, changePercent: -1.27)
        mockStocksRepository.quoteToReturn = quote
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock(priceChange: -2.34)

        await sut.loadStock()

        XCTAssertFalse(sut.isPriceUp)
    }

    // MARK: - Computed Properties Tests - With Stock Data

    func test_companyName_returnsStockName() async {
        let stock = MockStocksRepository.sampleStock(name: "Apple Inc.")
        mockStocksRepository.stockToReturn = stock

        await sut.loadStock()

        XCTAssertEqual(sut.companyName, "Apple Inc.")
    }

    func test_exchange_returnsStockExchange() async {
        let stock = MockStocksRepository.sampleStock()
        mockStocksRepository.stockToReturn = stock

        await sut.loadStock()

        XCTAssertEqual(sut.exchange, "NASDAQ")
    }

    func test_sector_returnsStockSector() async {
        let stock = MockStocksRepository.sampleStock()
        mockStocksRepository.stockToReturn = stock

        await sut.loadStock()

        XCTAssertEqual(sut.sector, "Technology")
    }

    func test_industry_returnsStockIndustry() async {
        let stock = MockStocksRepository.sampleStock()
        mockStocksRepository.stockToReturn = stock

        await sut.loadStock()

        XCTAssertEqual(sut.industry, "Consumer Electronics")
    }

    func test_hasDescription_returnsTrueWhenDescriptionExists() async {
        let stock = MockStocksRepository.sampleStock()
        mockStocksRepository.stockToReturn = stock

        await sut.loadStock()

        XCTAssertTrue(sut.hasDescription)
    }

    func test_shortDescription_truncatesLongDescription() async {
        let longDescription = String(repeating: "A", count: 300)
        var stock = MockStocksRepository.sampleStock()
        stock.companyDescription = longDescription
        mockStocksRepository.stockToReturn = stock

        await sut.loadStock()

        XCTAssertTrue(sut.shortDescription.count <= 203) // 200 + "..."
        XCTAssertTrue(sut.shortDescription.hasSuffix("..."))
    }

    // MARK: - Load Stock Tests

    func test_loadStock_setsIsLoading() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        // isLoading should be false after completion
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadStock_fetchesStockDetails() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        XCTAssertTrue(mockStocksRepository.getStockCalled)
        XCTAssertEqual(mockStocksRepository.lastGetStockSymbol, "AAPL")
    }

    func test_loadStock_fetchesQuote() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()
        mockStocksRepository.quoteToReturn = MockStocksRepository.sampleQuote()

        await sut.loadStock()

        XCTAssertTrue(mockStocksRepository.getQuoteCalled)
        XCTAssertEqual(mockStocksRepository.lastGetQuoteSymbol, "AAPL")
    }

    func test_loadStock_fetchesHistory() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        XCTAssertTrue(mockStocksRepository.getHistoryCalled)
        XCTAssertEqual(mockStocksRepository.lastGetHistorySymbol, "AAPL")
    }

    func test_loadStock_fetchesMarketStatus() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        XCTAssertTrue(mockStocksRepository.getMarketStatusCalled)
    }

    func test_loadStock_checksWatchlistStatus() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()
        mockStocksRepository.isInWatchlistResult = true

        await sut.loadStock()

        XCTAssertTrue(mockStocksRepository.isInWatchlistCalled)
        XCTAssertTrue(sut.isInWatchlist)
    }

    func test_loadStock_doesNotFetchIfAlreadyLoading() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()
        sut.isLoading = true

        await sut.loadStock()

        XCTAssertFalse(mockStocksRepository.getStockCalled)
    }

    func test_loadStock_setsErrorOnFailure() async {
        mockStocksRepository.errorToThrow = NetworkError.noConnection

        await sut.loadStock()

        XCTAssertNotNil(sut.error)
    }

    func test_loadStock_clearsErrorBeforeLoading() async {
        sut.error = NetworkError.noConnection
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        XCTAssertNil(sut.error)
    }

    // MARK: - Refresh Price Tests

    func test_refreshPrice_setsIsLoadingPrice() async {
        mockStocksRepository.quoteToReturn = MockStocksRepository.sampleQuote()

        await sut.refreshPrice()

        // isLoadingPrice should be false after completion
        XCTAssertFalse(sut.isLoadingPrice)
    }

    func test_refreshPrice_fetchesNewQuote() async {
        mockStocksRepository.quoteToReturn = MockStocksRepository.sampleQuote(price: 190.00)

        await sut.refreshPrice()

        XCTAssertTrue(mockStocksRepository.getQuoteCalled)
        XCTAssertEqual(sut.quote?.price, 190.00)
    }

    func test_refreshPrice_setsErrorOnFailure() async {
        mockStocksRepository.errorToThrow = NetworkError.noConnection

        await sut.refreshPrice()

        XCTAssertNotNil(sut.priceRefreshError)
    }

    // MARK: - Load History Tests

    func test_loadHistory_updatesSelectedPeriod() async {
        mockStocksRepository.historyToReturn = MockStocksRepository.sampleHistory(symbol: "AAPL", period: .threeMonths)

        await sut.loadHistory(period: .threeMonths)

        XCTAssertEqual(sut.selectedPeriod, .threeMonths)
    }

    func test_loadHistory_fetchesHistoryForPeriod() async {
        mockStocksRepository.historyToReturn = MockStocksRepository.sampleHistory(symbol: "AAPL", period: .sixMonths)

        await sut.loadHistory(period: .sixMonths)

        XCTAssertEqual(mockStocksRepository.lastGetHistoryPeriod, .sixMonths)
    }

    func test_loadHistory_setsErrorOnFailure() async {
        mockStocksRepository.errorToThrow = NetworkError.noConnection

        await sut.loadHistory(period: .oneYear)

        XCTAssertNotNil(sut.historyError)
    }

    // MARK: - Load AI Explanation Tests

    func test_loadAIExplanation_setsIsLoadingExplanation() async {
        let response = StockExplanation(
            symbol: "AAPL",
            explanation: "Apple is a leading tech company."
        )
        mockAIRepository.explanationToReturn = response

        await sut.loadAIExplanation()

        // isLoadingExplanation should be false after completion
        XCTAssertFalse(sut.isLoadingExplanation)
    }

    func test_loadAIExplanation_setsExplanation() async {
        let response = StockExplanation(
            symbol: "AAPL",
            explanation: "Apple is a leading tech company."
        )
        mockAIRepository.explanationToReturn = response

        await sut.loadAIExplanation()

        XCTAssertEqual(sut.aiExplanation, "Apple is a leading tech company.")
    }

    func test_loadAIExplanation_doesNotReloadIfAlreadyLoaded() async {
        sut.aiExplanation = "Already loaded"

        await sut.loadAIExplanation()

        XCTAssertEqual(mockAIRepository.fetchExplanationCallCount, 0)
    }

    func test_loadAIExplanation_setsErrorOnFailure() async {
        mockAIRepository.errorToThrow = NetworkError.serverError(statusCode: 500, message: nil)

        await sut.loadAIExplanation()

        XCTAssertNotNil(sut.aiError)
    }

    // MARK: - Buy Stock Tests

    func test_buyStock_showsBuySheet() {
        sut.buyStock()

        XCTAssertTrue(sut.showBuySheet)
    }

    // MARK: - Add to DCA Tests

    func test_addToDCA_showsAddToDCASheet() {
        sut.addToDCA()

        XCTAssertTrue(sut.showAddToDCASheet)
    }

    // MARK: - Watchlist Tests

    func test_toggleWatchlist_addsToWatchlistWhenNotIn() async {
        mockStocksRepository.isInWatchlistResult = false
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()
        await sut.loadStock()

        sut.toggleWatchlist()

        // Wait for the task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        XCTAssertTrue(mockStocksRepository.addToWatchlistCalled)
        XCTAssertEqual(mockStocksRepository.lastAddToWatchlistSymbol, "AAPL")
    }

    func test_toggleWatchlist_removesFromWatchlistWhenIn() async {
        mockStocksRepository.isInWatchlistResult = true
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()
        await sut.loadStock()

        sut.toggleWatchlist()

        // Wait for the task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        XCTAssertTrue(mockStocksRepository.removeFromWatchlistCalled)
        XCTAssertEqual(mockStocksRepository.lastRemoveFromWatchlistSymbol, "AAPL")
    }

    func test_toggleWatchlist_doesNothingWhileLoading() async {
        sut.isLoadingWatchlist = true

        sut.toggleWatchlist()

        // Wait a bit to ensure nothing happens
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertFalse(mockStocksRepository.addToWatchlistCalled)
        XCTAssertFalse(mockStocksRepository.removeFromWatchlistCalled)
    }

    func test_toggleWatchlist_setsErrorOnFailure() async {
        mockStocksRepository.isInWatchlistResult = false
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()
        await sut.loadStock()

        // Set error for the add operation
        mockStocksRepository.errorToThrow = NetworkError.noConnection

        sut.toggleWatchlist()

        // Wait for the task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(sut.watchlistError)
    }

    // MARK: - Share Stock Tests

    func test_shareStock_returnsFormattedShareText() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock(name: "Apple Inc.")
        await sut.loadStock()

        let shareText = sut.shareStock()

        XCTAssertTrue(shareText.contains("Apple Inc."))
        XCTAssertTrue(shareText.contains("AAPL"))
        XCTAssertTrue(shareText.contains("growfolio.app"))
    }

    func test_shareStock_includesSymbolInURL() {
        let shareText = sut.shareStock()

        XCTAssertTrue(shareText.contains("/stock/AAPL"))
    }

    // MARK: - Market Hours Tests

    func test_marketHours_isLoadedWithStock() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()
        mockStocksRepository.marketStatusToReturn = MockStocksRepository.sampleMarketHours(isOpen: true)

        await sut.loadStock()

        XCTAssertNotNil(sut.marketHours)
        XCTAssertTrue(sut.marketHours?.isOpen ?? false)
    }

    // MARK: - Watchlist Status Tests

    func test_checkWatchlistStatus_updatesIsInWatchlist() async {
        mockStocksRepository.isInWatchlistResult = true

        await sut.checkWatchlistStatus()

        XCTAssertTrue(sut.isInWatchlist)
    }

    func test_checkWatchlistStatus_handlesErrorSilently() async {
        mockStocksRepository.errorToThrow = NetworkError.noConnection

        await sut.checkWatchlistStatus()

        // Should not crash and isInWatchlist should remain false
        XCTAssertFalse(sut.isInWatchlist)
    }

    // MARK: - Stock Metrics Tests

    func test_marketCap_returnsFormattedValue() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        XCTAssertNotNil(sut.marketCap)
        // Market cap should contain some value indicator (B for billion, etc.)
    }

    func test_peRatio_returnsFormattedValue() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        XCTAssertNotNil(sut.peRatio)
        XCTAssertEqual(sut.peRatio, "28.50")
    }

    func test_dividendYield_returnsFormattedPercentage() async {
        mockStocksRepository.stockToReturn = MockStocksRepository.sampleStock()

        await sut.loadStock()

        XCTAssertNotNil(sut.dividendYield)
        XCTAssertTrue(sut.dividendYield?.contains("%") ?? false)
    }

    func test_dividendYield_returnsNilWhenZero() async {
        var stock = MockStocksRepository.sampleStock()
        stock.dividendYield = 0
        mockStocksRepository.stockToReturn = stock

        await sut.loadStock()

        XCTAssertNil(sut.dividendYield)
    }
}

// MARK: - Test Doubles

final class StubAIRepository: AIRepositoryProtocol {
    var explanationToReturn = StockExplanation(symbol: "AAPL", explanation: "Mock explanation")
    var errorToThrow: Error?
    private(set) var fetchExplanationCallCount = 0

    func sendMessage(
        _ message: String,
        conversationHistory: [ChatMessage],
        includePortfolioContext: Bool
    ) async throws -> ChatMessage {
        ChatMessage.assistant("Mock response")
    }

    func fetchInsights(includeGoals: Bool) async throws -> PortfolioInsightsResponse {
        PortfolioInsightsResponse(insights: [])
    }

    func fetchStockExplanation(symbol: String) async throws -> StockExplanation {
        fetchExplanationCallCount += 1
        if let errorToThrow {
            throw errorToThrow
        }
        return explanationToReturn
    }

    func fetchAllocationSuggestion(
        investmentAmount: Decimal,
        riskTolerance: RiskTolerance,
        timeHorizon: TimeHorizon
    ) async throws -> AllocationSuggestion {
        AllocationSuggestion(
            suggestion: "Mock suggestion",
            investmentAmount: investmentAmount,
            riskTolerance: riskTolerance,
            timeHorizon: timeHorizon
        )
    }

    func fetchInvestingTips() async throws -> [InvestingTip] {
        []
    }
}
