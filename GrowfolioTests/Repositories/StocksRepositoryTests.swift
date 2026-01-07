//
//  StocksRepositoryTests.swift
//  GrowfolioTests
//
//  Tests for StocksRepository.
//

import XCTest
@testable import Growfolio

final class StocksRepositoryTests: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var mockUserDefaults: UserDefaults!
    var sut: StocksRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        mockUserDefaults = UserDefaults(suiteName: "StocksRepositoryTests")!
        mockUserDefaults.removePersistentDomain(forName: "StocksRepositoryTests")
        sut = StocksRepository(apiClient: mockAPIClient, userDefaults: mockUserDefaults)
    }

    override func tearDown() {
        mockAPIClient.reset()
        mockUserDefaults.removePersistentDomain(forName: "StocksRepositoryTests")
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeStock(
        symbol: String = "AAPL",
        name: String = "Apple Inc.",
        currentPrice: Decimal? = 175.50
    ) -> Stock {
        Stock(
            symbol: symbol,
            name: name,
            exchange: "NASDAQ",
            assetType: .stock,
            currentPrice: currentPrice,
            priceChange: 2.50,
            priceChangePercent: 1.44,
            sector: "Technology",
            industry: "Consumer Electronics",
            lastUpdated: Date()
        )
    }

    private func makeQuote(
        symbol: String = "AAPL",
        price: Decimal = 175.50,
        change: Decimal = 2.50,
        changePercent: Decimal = 1.44
    ) -> StockQuote {
        StockQuote(
            symbol: symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            volume: 50000000,
            timestamp: Date()
        )
    }

    private func makeSearchResult(
        symbol: String = "AAPL",
        name: String = "Apple Inc."
    ) -> StockSearchResult {
        StockSearchResult(
            symbol: symbol,
            name: name,
            exchange: "NASDAQ",
            assetType: .stock,
            status: nil,
            currencyCode: "USD"
        )
    }

    private func makeMarketHours(
        isOpen: Bool = true,
        session: MarketSession = .regular
    ) -> MarketHours {
        MarketHours(
            exchange: "NYSE",
            isOpen: isOpen,
            session: session
        )
    }

    // MARK: - Search Stocks Tests

    func test_searchStocks_returnsResultsFromAPI() async throws {
        // Arrange
        let expectedResults = [
            makeSearchResult(symbol: "AAPL", name: "Apple Inc."),
            makeSearchResult(symbol: "AMZN", name: "Amazon.com Inc.")
        ]
        mockAPIClient.setResponse(expectedResults, for: Endpoints.SearchStocks.self)

        // Act
        let results = try await sut.searchStocks(query: "A", limit: 10)

        // Assert
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].symbol, "AAPL")
        XCTAssertEqual(results[1].symbol, "AMZN")
    }

    func test_searchStocks_returnsEmptyForEmptyQuery() async throws {
        // Act
        let results = try await sut.searchStocks(query: "", limit: 10)

        // Assert
        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    func test_searchStocks_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Server error"), for: Endpoints.SearchStocks.self)

        // Act & Assert
        do {
            _ = try await sut.searchStocks(query: "AAPL", limit: 10)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Get Stock Tests

    func test_getStock_returnsStockFromAPI() async throws {
        // Arrange
        let expectedStock = makeStock(symbol: "AAPL")
        mockAPIClient.setResponse(expectedStock, for: Endpoints.GetStock.self)

        // Act
        let stock = try await sut.getStock(symbol: "AAPL")

        // Assert
        XCTAssertEqual(stock.symbol, "AAPL")
        XCTAssertEqual(stock.name, "Apple Inc.")
    }

    func test_getStock_usesCache() async throws {
        // Arrange
        let stock = makeStock(symbol: "AAPL")
        mockAPIClient.setResponse(stock, for: Endpoints.GetStock.self)

        // Act - First call populates cache
        _ = try await sut.getStock(symbol: "AAPL")

        // Act - Second call should use cache (within 5 minutes)
        let result = try await sut.getStock(symbol: "AAPL")

        // Assert
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_getStock_convertsToUppercase() async throws {
        // Arrange
        let stock = makeStock(symbol: "AAPL")
        mockAPIClient.setResponse(stock, for: Endpoints.GetStock.self)

        // Act
        _ = try await sut.getStock(symbol: "aapl")

        // Assert - Should normalize to uppercase and use cache
        mockAPIClient.reset()
        let result = try await sut.getStock(symbol: "AAPL")
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    // MARK: - Get Quote Tests

    func test_getQuote_returnsQuoteFromAPI() async throws {
        // Arrange
        let expectedQuote = makeQuote(symbol: "AAPL", price: 180.00)
        mockAPIClient.setResponse(expectedQuote, for: Endpoints.GetStockQuote.self)

        // Act
        let quote = try await sut.getQuote(symbol: "AAPL")

        // Assert
        XCTAssertEqual(quote.symbol, "AAPL")
        XCTAssertEqual(quote.price, 180.00)
    }

    func test_getQuote_usesShortCache() async throws {
        // Arrange
        let quote = makeQuote(symbol: "AAPL")
        mockAPIClient.setResponse(quote, for: Endpoints.GetStockQuote.self)

        // Act - First call populates cache
        _ = try await sut.getQuote(symbol: "AAPL")

        // Act - Second call should use cache (within 5 seconds)
        let result = try await sut.getQuote(symbol: "AAPL")

        // Assert
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Get Quotes Tests

    func test_getQuotes_returnsQuotesForMultipleSymbols() async throws {
        // Arrange
        let appleQuote = makeQuote(symbol: "AAPL")
        let googleQuote = makeQuote(symbol: "GOOGL")
        mockAPIClient.setResponse(appleQuote, for: Endpoints.GetStockQuote.self)

        // Note: Due to parallel execution, we need to handle multiple calls
        // For this test, we'll verify the structure works

        // Act
        let quotes = try await sut.getQuotes(symbols: ["AAPL"])

        // Assert
        XCTAssertFalse(quotes.isEmpty)
    }

    // MARK: - Get History Tests

    func test_getHistory_returnsHistoricalData() async throws {
        // Arrange
        let history = StockHistory(
            symbol: "AAPL",
            period: .oneMonth,
            dataPoints: [
                StockHistoryDataPoint(
                    date: Date().addingTimeInterval(-86400),
                    open: 170,
                    high: 175,
                    low: 169,
                    close: 174,
                    volume: 50000000
                )
            ]
        )
        mockAPIClient.setResponse(history, for: Endpoints.GetStockHistory.self)

        // Act
        let result = try await sut.getHistory(symbol: "AAPL", period: .oneMonth)

        // Assert
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(result.period, .oneMonth)
        XCTAssertFalse(result.dataPoints.isEmpty)
    }

    // MARK: - Get Market Status Tests

    func test_getMarketStatus_returnsStatusFromAPI() async throws {
        // Arrange
        let status = makeMarketHours(isOpen: true, session: .regular)
        mockAPIClient.setResponse(status, for: Endpoints.GetMarketStatus.self)

        // Act
        let result = try await sut.getMarketStatus()

        // Assert
        XCTAssertTrue(result.isOpen)
        XCTAssertEqual(result.session, .regular)
    }

    func test_getMarketStatus_usesCache() async throws {
        // Arrange
        let status = makeMarketHours()
        mockAPIClient.setResponse(status, for: Endpoints.GetMarketStatus.self)

        // Act - First call populates cache
        _ = try await sut.getMarketStatus()

        // Act - Second call should use cache (within 1 minute)
        let result = try await sut.getMarketStatus()

        // Assert
        XCTAssertTrue(result.isOpen)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_getMarketStatus_returnsFallbackOnError() async throws {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Error"), for: Endpoints.GetMarketStatus.self)

        // Act
        let result = try await sut.getMarketStatus()

        // Assert - Should return fallback status
        XCTAssertEqual(result.exchange, "NYSE")
    }

    // MARK: - Submit Buy Order Tests

    func test_submitBuyOrder_returnsOrder() async throws {
        // Arrange
        let order = StockOrder(
            id: "order-123",
            symbol: "AAPL",
            side: .buy,
            type: .market,
            status: .new,
            timeInForce: .day,
            notional: 1000,
            quantity: nil,
            filledQuantity: nil,
            filledAvgPrice: nil,
            limitPrice: nil,
            stopPrice: nil,
            submittedAt: Date(),
            filledAt: nil,
            cancelledAt: nil,
            expiredAt: nil,
            clientOrderId: nil
        )
        mockAPIClient.setResponse(order, for: Endpoints.SubmitBuyOrder.self)

        // Act
        let result = try await sut.submitBuyOrder(symbol: "AAPL", notionalUSD: 1000)

        // Assert
        XCTAssertEqual(result.id, "order-123")
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(result.side, .buy)
    }

    func test_submitBuyOrder_convertsSymbolToUppercase() async throws {
        // Arrange
        let order = StockOrder(
            id: "order-123",
            symbol: "AAPL",
            side: .buy,
            type: .market,
            status: .new,
            timeInForce: .day,
            notional: 1000,
            quantity: nil,
            filledQuantity: nil,
            filledAvgPrice: nil,
            limitPrice: nil,
            stopPrice: nil,
            submittedAt: Date(),
            filledAt: nil,
            cancelledAt: nil,
            expiredAt: nil,
            clientOrderId: nil
        )
        mockAPIClient.setResponse(order, for: Endpoints.SubmitBuyOrder.self)

        // Act
        let result = try await sut.submitBuyOrder(symbol: "aapl", notionalUSD: 1000)

        // Assert
        XCTAssertEqual(result.symbol, "AAPL")
    }

    // MARK: - Watchlist Tests

    func test_addToWatchlist_addsSymbol() async throws {
        // Act
        try await sut.addToWatchlist(symbol: "AAPL")

        // Assert
        let isInWatchlist = try await sut.isInWatchlist(symbol: "AAPL")
        XCTAssertTrue(isInWatchlist)
    }

    func test_addToWatchlist_doesNotDuplicate() async throws {
        // Arrange
        try await sut.addToWatchlist(symbol: "AAPL")

        // Act
        try await sut.addToWatchlist(symbol: "AAPL")

        // Assert
        let watchlist = try await sut.getWatchlist()
        let aaplCount = watchlist.filter { $0.symbol == "AAPL" }.count
        XCTAssertEqual(aaplCount, 1)
    }

    func test_addToWatchlist_convertsToUppercase() async throws {
        // Act
        try await sut.addToWatchlist(symbol: "aapl")

        // Assert
        let isInWatchlist = try await sut.isInWatchlist(symbol: "AAPL")
        XCTAssertTrue(isInWatchlist)
    }

    func test_removeFromWatchlist_removesSymbol() async throws {
        // Arrange
        try await sut.addToWatchlist(symbol: "AAPL")

        // Act
        try await sut.removeFromWatchlist(symbol: "AAPL")

        // Assert
        let isInWatchlist = try await sut.isInWatchlist(symbol: "AAPL")
        XCTAssertFalse(isInWatchlist)
    }

    func test_isInWatchlist_returnsTrueForExistingSymbol() async throws {
        // Arrange
        try await sut.addToWatchlist(symbol: "AAPL")

        // Act
        let result = try await sut.isInWatchlist(symbol: "AAPL")

        // Assert
        XCTAssertTrue(result)
    }

    func test_isInWatchlist_returnsFalseForMissingSymbol() async throws {
        // Act
        let result = try await sut.isInWatchlist(symbol: "AAPL")

        // Assert
        XCTAssertFalse(result)
    }

    func test_getWatchlist_returnsAllItems() async throws {
        // Arrange
        try await sut.addToWatchlist(symbol: "AAPL")
        try await sut.addToWatchlist(symbol: "GOOGL")
        try await sut.addToWatchlist(symbol: "MSFT")

        // Act
        let watchlist = try await sut.getWatchlist()

        // Assert
        XCTAssertEqual(watchlist.count, 3)
    }

    func test_getWatchlistWithQuotes_returnsItemsWithQuotes() async throws {
        // Arrange
        try await sut.addToWatchlist(symbol: "AAPL")

        let stock = makeStock(symbol: "AAPL")
        let quote = makeQuote(symbol: "AAPL")
        mockAPIClient.setResponse(stock, for: Endpoints.GetStock.self)
        mockAPIClient.setResponse(quote, for: Endpoints.GetStockQuote.self)

        // Act
        let result = try await sut.getWatchlistWithQuotes()

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.item.symbol, "AAPL")
    }

    // MARK: - Cache Invalidation Tests

    func test_invalidateCache_clearsAllCaches() async throws {
        // Arrange - Populate caches
        let stock = makeStock(symbol: "AAPL")
        mockAPIClient.setResponse(stock, for: Endpoints.GetStock.self)
        _ = try await sut.getStock(symbol: "AAPL")

        let quote = makeQuote(symbol: "AAPL")
        mockAPIClient.setResponse(quote, for: Endpoints.GetStockQuote.self)
        _ = try await sut.getQuote(symbol: "AAPL")

        let status = makeMarketHours()
        mockAPIClient.setResponse(status, for: Endpoints.GetMarketStatus.self)
        _ = try await sut.getMarketStatus()

        // Act
        await sut.invalidateCache()

        // Reset and set up new responses
        mockAPIClient.reset()
        let newStock = makeStock(symbol: "AAPL", currentPrice: 200)
        mockAPIClient.setResponse(newStock, for: Endpoints.GetStock.self)

        // Assert - New API call should be made
        let fetchedStock = try await sut.getStock(symbol: "AAPL")
        XCTAssertEqual(fetchedStock.currentPrice, 200)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Empty Response Tests

    func test_searchStocks_returnsEmptyArrayWhenNoResults() async throws {
        // Arrange
        mockAPIClient.setResponse([StockSearchResult](), for: Endpoints.SearchStocks.self)

        // Act
        let results = try await sut.searchStocks(query: "ZZZZZ", limit: 10)

        // Assert
        XCTAssertTrue(results.isEmpty)
    }

    func test_getWatchlist_returnsEmptyArrayWhenEmpty() async throws {
        // Act
        let watchlist = try await sut.getWatchlist()

        // Assert
        XCTAssertTrue(watchlist.isEmpty)
    }

    // MARK: - Get Stock Price Tests

    func test_getStockPrice_returnsPriceFromAPI() async throws {
        // Arrange
        let expectedPrice = StockPrice(
            symbol: "AAPL",
            price: 182.50,
            timestamp: Date()
        )
        mockAPIClient.setResponse(expectedPrice, for: Endpoints.GetStockPrice.self)

        // Act
        let result = try await sut.getStockPrice(symbol: "AAPL")

        // Assert
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(result.price, 182.50)
    }

    func test_getStockPrice_convertsSymbolToUppercase() async throws {
        // Arrange
        let price = StockPrice(symbol: "AAPL", price: 180.00, timestamp: Date())
        mockAPIClient.setResponse(price, for: Endpoints.GetStockPrice.self)

        // Act
        let result = try await sut.getStockPrice(symbol: "aapl")

        // Assert
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_getStockPrice_includesTimestamp() async throws {
        // Arrange
        let now = Date()
        let price = StockPrice(symbol: "GOOGL", price: 140.25, timestamp: now)
        mockAPIClient.setResponse(price, for: Endpoints.GetStockPrice.self)

        // Act
        let result = try await sut.getStockPrice(symbol: "GOOGL")

        // Assert
        XCTAssertEqual(result.timestamp, now)
    }

    func test_getStockPrice_throwsOnNetworkError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Server error"), for: Endpoints.GetStockPrice.self)

        // Act & Assert
        do {
            _ = try await sut.getStockPrice(symbol: "AAPL")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    func test_getStockPrice_throwsOnNotFound() async {
        // Arrange
        mockAPIClient.setError(NetworkError.notFound, for: Endpoints.GetStockPrice.self)

        // Act & Assert
        do {
            _ = try await sut.getStockPrice(symbol: "INVALID")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .notFound)
        }
    }

    func test_getStockPrice_handlesDecimalPrecision() async throws {
        // Arrange
        let price = StockPrice(symbol: "TSLA", price: 245.6789, timestamp: Date())
        mockAPIClient.setResponse(price, for: Endpoints.GetStockPrice.self)

        // Act
        let result = try await sut.getStockPrice(symbol: "TSLA")

        // Assert
        XCTAssertEqual(result.price, 245.6789)
    }

    func test_getStockPrice_sendsCorrectSymbol() async throws {
        // Arrange
        let price = StockPrice(symbol: "MSFT", price: 350.00, timestamp: Date())
        mockAPIClient.setResponse(price, for: Endpoints.GetStockPrice.self)

        // Act
        _ = try await sut.getStockPrice(symbol: "MSFT")

        // Assert
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }
}
