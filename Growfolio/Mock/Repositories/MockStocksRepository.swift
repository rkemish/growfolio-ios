//
//  MockStocksRepository.swift
//  Growfolio
//
//  Mock implementation of StocksRepositoryProtocol for demo mode.
//

import Foundation

/// Mock implementation of StocksRepositoryProtocol
final class MockStocksRepository: StocksRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let store = MockDataStore.shared
    private let config = MockConfiguration.shared

    // MARK: - Search

    func searchStocks(query: String, limit: Int = 10) async throws -> [StockSearchResult] {
        try await simulateNetwork()

        guard !query.isEmpty else { return [] }
        return MockStockDataProvider.searchResults(for: query, limit: limit)
    }

    // MARK: - Stock Details

    func getStock(symbol: String) async throws -> Stock {
        try await simulateNetwork()
        return MockStockDataProvider.stock(for: symbol.uppercased())
    }

    // MARK: - Quotes

    func getQuote(symbol: String) async throws -> StockQuote {
        try await simulateNetwork()
        return MockStockDataProvider.quote(for: symbol.uppercased())
    }

    func getQuotes(symbols: [String]) async throws -> [StockQuote] {
        try await simulateNetwork()
        return symbols.map { MockStockDataProvider.quote(for: $0.uppercased()) }
    }

    // MARK: - History

    func getHistory(symbol: String, period: HistoryPeriod) async throws -> StockHistory {
        try await simulateNetwork()

        let dataPoints = MockStockDataProvider.historicalPrices(for: symbol.uppercased(), period: period)
        return StockHistory(
            symbol: symbol.uppercased(),
            period: period,
            dataPoints: dataPoints
        )
    }

    // MARK: - Market Status

    func getMarketStatus() async throws -> MarketHours {
        try await simulateNetwork()
        return MockStockDataProvider.marketHours()
    }

    // MARK: - Orders

    func submitBuyOrder(symbol: String, notionalUSD: Decimal) async throws -> StockOrder {
        try await simulateNetwork()

        let price = MockStockDataProvider.currentPrice(for: symbol.uppercased())
        let quantity = (notionalUSD / price).rounded(places: 4)

        return StockOrder(
            id: MockDataGenerator.mockId(prefix: "order"),
            symbol: symbol.uppercased(),
            side: .buy,
            type: .market,
            status: .filled,
            notional: notionalUSD,
            quantity: nil,
            filledQuantity: quantity,
            filledAvgPrice: price,
            submittedAt: Date(),
            filledAt: Date(),
            cancelledAt: nil,
            expiredAt: nil,
            clientOrderId: MockDataGenerator.mockId(prefix: "client")
        )
    }

    // MARK: - Watchlist

    func getWatchlist() async throws -> [WatchlistItem] {
        try await simulateNetwork()
        await ensureInitialized()

        return await store.watchlist.map { symbol in
            WatchlistItem(
                symbol: symbol,
                dateAdded: MockDataGenerator.pastDate(daysAgo: Int.random(in: 1...30))
            )
        }
    }

    func addToWatchlist(symbol: String) async throws {
        try await simulateNetwork()
        await store.addToWatchlist(symbol.uppercased())
    }

    func removeFromWatchlist(symbol: String) async throws {
        try await simulateNetwork()
        await store.removeFromWatchlist(symbol.uppercased())
    }

    func isInWatchlist(symbol: String) async throws -> Bool {
        try await simulateNetwork()
        return await store.watchlist.contains(symbol.uppercased())
    }

    func getWatchlistWithQuotes() async throws -> [WatchlistItemWithQuote] {
        try await simulateNetwork()
        await ensureInitialized()

        return await store.watchlist.map { symbol in
            let profile = MockStockDataProvider.stockProfiles[symbol]
            let quote = MockStockDataProvider.quote(for: symbol)

            let item = WatchlistItem(
                symbol: symbol,
                dateAdded: MockDataGenerator.pastDate(daysAgo: Int.random(in: 1...30))
            )

            let stock = Stock(
                symbol: symbol,
                name: profile?.name ?? symbol,
                exchange: "NYSE",
                assetType: .stock,
                currentPrice: quote.price,
                priceChange: quote.change,
                priceChangePercent: quote.changePercent,
                sector: profile?.sector
            )

            return WatchlistItemWithQuote(
                item: item,
                stock: stock,
                quote: quote
            )
        }
    }

    func invalidateCache() async {
        // No-op for mock
    }

    // MARK: - Private Methods

    private func simulateNetwork() async throws {
        try await config.simulateNetworkDelay()
        try config.maybeThrowSimulatedError()
    }

    private func ensureInitialized() async {
        if await store.portfolios.isEmpty {
            await store.initialize(for: config.demoPersona)
        }
    }
}


