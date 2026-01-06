//
//  MockStocksRepository.swift
//  GrowfolioTests
//
//  Mock stocks repository for testing.
//

import Foundation
@testable import Growfolio

/// Mock stocks repository that returns predefined responses for testing
final class MockStocksRepository: StocksRepositoryProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    var searchResultsToReturn: [StockSearchResult] = []
    var stockToReturn: Stock?
    var quoteToReturn: StockQuote?
    var quotesToReturn: [StockQuote] = []
    var historyToReturn: StockHistory?
    var marketStatusToReturn: MarketHours?
    var orderToReturn: StockOrder?
    var watchlistToReturn: [WatchlistItem] = []
    var watchlistWithQuotesToReturn: [WatchlistItemWithQuote] = []
    var isInWatchlistResult: Bool = false
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var searchStocksCalled = false
    var lastSearchQuery: String?
    var lastSearchLimit: Int?
    var getStockCalled = false
    var lastGetStockSymbol: String?
    var getQuoteCalled = false
    var lastGetQuoteSymbol: String?
    var getQuotesCalled = false
    var lastGetQuotesSymbols: [String]?
    var getHistoryCalled = false
    var lastGetHistorySymbol: String?
    var lastGetHistoryPeriod: HistoryPeriod?
    var getMarketStatusCalled = false
    var submitBuyOrderCalled = false
    var lastBuyOrderSymbol: String?
    var lastBuyOrderNotional: Decimal?
    var invalidateCacheCalled = false
    var getWatchlistCalled = false
    var addToWatchlistCalled = false
    var lastAddToWatchlistSymbol: String?
    var removeFromWatchlistCalled = false
    var lastRemoveFromWatchlistSymbol: String?
    var isInWatchlistCalled = false
    var lastIsInWatchlistSymbol: String?
    var getWatchlistWithQuotesCalled = false

    // MARK: - Reset

    func reset() {
        searchResultsToReturn = []
        stockToReturn = nil
        quoteToReturn = nil
        quotesToReturn = []
        historyToReturn = nil
        marketStatusToReturn = nil
        orderToReturn = nil
        watchlistToReturn = []
        watchlistWithQuotesToReturn = []
        isInWatchlistResult = false
        errorToThrow = nil

        searchStocksCalled = false
        lastSearchQuery = nil
        lastSearchLimit = nil
        getStockCalled = false
        lastGetStockSymbol = nil
        getQuoteCalled = false
        lastGetQuoteSymbol = nil
        getQuotesCalled = false
        lastGetQuotesSymbols = nil
        getHistoryCalled = false
        lastGetHistorySymbol = nil
        lastGetHistoryPeriod = nil
        getMarketStatusCalled = false
        submitBuyOrderCalled = false
        lastBuyOrderSymbol = nil
        lastBuyOrderNotional = nil
        invalidateCacheCalled = false
        getWatchlistCalled = false
        addToWatchlistCalled = false
        lastAddToWatchlistSymbol = nil
        removeFromWatchlistCalled = false
        lastRemoveFromWatchlistSymbol = nil
        isInWatchlistCalled = false
        lastIsInWatchlistSymbol = nil
        getWatchlistWithQuotesCalled = false
    }

    // MARK: - StocksRepositoryProtocol Implementation

    func searchStocks(query: String, limit: Int) async throws -> [StockSearchResult] {
        searchStocksCalled = true
        lastSearchQuery = query
        lastSearchLimit = limit
        if let error = errorToThrow { throw error }
        return searchResultsToReturn
    }

    func getStock(symbol: String) async throws -> Stock {
        getStockCalled = true
        lastGetStockSymbol = symbol
        if let error = errorToThrow { throw error }
        if let stock = stockToReturn { return stock }
        return MockStocksRepository.sampleStock(symbol: symbol)
    }

    func getQuote(symbol: String) async throws -> StockQuote {
        getQuoteCalled = true
        lastGetQuoteSymbol = symbol
        if let error = errorToThrow { throw error }
        if let quote = quoteToReturn { return quote }
        return MockStocksRepository.sampleQuote(symbol: symbol)
    }

    func getQuotes(symbols: [String]) async throws -> [StockQuote] {
        getQuotesCalled = true
        lastGetQuotesSymbols = symbols
        if let error = errorToThrow { throw error }
        if !quotesToReturn.isEmpty { return quotesToReturn }
        return symbols.map { MockStocksRepository.sampleQuote(symbol: $0) }
    }

    func getHistory(symbol: String, period: HistoryPeriod) async throws -> StockHistory {
        getHistoryCalled = true
        lastGetHistorySymbol = symbol
        lastGetHistoryPeriod = period
        if let error = errorToThrow { throw error }
        if let history = historyToReturn { return history }
        return MockStocksRepository.sampleHistory(symbol: symbol, period: period)
    }

    func getMarketStatus() async throws -> MarketHours {
        getMarketStatusCalled = true
        if let error = errorToThrow { throw error }
        if let status = marketStatusToReturn { return status }
        return MockStocksRepository.sampleMarketHours()
    }

    func submitBuyOrder(symbol: String, notionalUSD: Decimal) async throws -> StockOrder {
        submitBuyOrderCalled = true
        lastBuyOrderSymbol = symbol
        lastBuyOrderNotional = notionalUSD
        if let error = errorToThrow { throw error }
        if let order = orderToReturn { return order }
        return MockStocksRepository.sampleOrder(symbol: symbol, notional: notionalUSD)
    }

    func invalidateCache() async {
        invalidateCacheCalled = true
    }

    func getWatchlist() async throws -> [WatchlistItem] {
        getWatchlistCalled = true
        if let error = errorToThrow { throw error }
        return watchlistToReturn
    }

    func addToWatchlist(symbol: String) async throws {
        addToWatchlistCalled = true
        lastAddToWatchlistSymbol = symbol
        if let error = errorToThrow { throw error }
    }

    func removeFromWatchlist(symbol: String) async throws {
        removeFromWatchlistCalled = true
        lastRemoveFromWatchlistSymbol = symbol
        if let error = errorToThrow { throw error }
    }

    func isInWatchlist(symbol: String) async throws -> Bool {
        isInWatchlistCalled = true
        lastIsInWatchlistSymbol = symbol
        if let error = errorToThrow { throw error }
        return isInWatchlistResult
    }

    func getWatchlistWithQuotes() async throws -> [WatchlistItemWithQuote] {
        getWatchlistWithQuotesCalled = true
        if let error = errorToThrow { throw error }
        return watchlistWithQuotesToReturn
    }

    // MARK: - Sample Data Generators

    static func sampleStock(
        symbol: String = "AAPL",
        name: String = "Apple Inc.",
        currentPrice: Decimal = 185.92,
        priceChange: Decimal = 2.34,
        priceChangePercent: Decimal = 1.27
    ) -> Stock {
        Stock(
            symbol: symbol,
            name: name,
            exchange: "NASDAQ",
            assetType: .stock,
            currentPrice: currentPrice,
            priceChange: priceChange,
            priceChangePercent: priceChangePercent,
            previousClose: currentPrice - priceChange,
            openPrice: currentPrice - 1,
            dayHigh: currentPrice + 2,
            dayLow: currentPrice - 3,
            weekHigh52: currentPrice + 20,
            weekLow52: currentPrice - 50,
            volume: 52_431_678,
            averageVolume: 58_000_000,
            marketCap: 2_890_000_000_000,
            peRatio: 28.5,
            dividendYield: 0.51,
            eps: 6.52,
            sector: "Technology",
            industry: "Consumer Electronics",
            companyDescription: "Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide.",
            currencyCode: "USD",
            lastUpdated: Date()
        )
    }

    static func sampleQuote(
        symbol: String = "AAPL",
        price: Decimal = 185.92,
        change: Decimal = 2.34,
        changePercent: Decimal = 1.27
    ) -> StockQuote {
        StockQuote(
            symbol: symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            volume: 52_431_678,
            timestamp: Date()
        )
    }

    static func sampleHistory(symbol: String, period: HistoryPeriod) -> StockHistory {
        let dataPoints = (0..<30).map { i in
            StockHistoryDataPoint(
                date: Date().addingTimeInterval(TimeInterval(-i * 86400)),
                open: 180 + Decimal(i % 5),
                high: 185 + Decimal(i % 5),
                low: 178 + Decimal(i % 5),
                close: 182 + Decimal(i % 5),
                volume: 50_000_000 + (i * 100_000)
            )
        }
        return StockHistory(symbol: symbol, period: period, dataPoints: dataPoints)
    }

    static func sampleMarketHours(isOpen: Bool = true) -> MarketHours {
        MarketHours(
            exchange: "NYSE",
            isOpen: isOpen,
            session: isOpen ? .regular : .closed,
            nextOpen: isOpen ? nil : Date().addingTimeInterval(3600),
            nextClose: isOpen ? Date().addingTimeInterval(3600) : nil,
            timestamp: Date()
        )
    }

    static func sampleOrder(
        symbol: String = "AAPL",
        notional: Decimal = 100
    ) -> StockOrder {
        StockOrder(
            id: UUID().uuidString,
            symbol: symbol,
            side: .buy,
            type: .market,
            status: .filled,
            notional: notional,
            quantity: nil,
            filledQuantity: notional / 185,
            filledAvgPrice: 185,
            submittedAt: Date(),
            filledAt: Date(),
            cancelledAt: nil,
            expiredAt: nil,
            clientOrderId: nil
        )
    }

    static func sampleWatchlistItem(symbol: String = "AAPL") -> WatchlistItem {
        WatchlistItem(symbol: symbol, dateAdded: Date())
    }

    static func sampleWatchlistItemWithQuote(
        symbol: String = "AAPL",
        name: String = "Apple Inc."
    ) -> WatchlistItemWithQuote {
        WatchlistItemWithQuote(
            item: sampleWatchlistItem(symbol: symbol),
            stock: sampleStock(symbol: symbol, name: name),
            quote: sampleQuote(symbol: symbol)
        )
    }
}
