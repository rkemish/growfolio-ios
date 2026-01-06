//
//  StocksRepository.swift
//  Growfolio
//
//  Repository for stock search, quotes, and market data.
//

import Foundation

/// Protocol for stock data operations
protocol StocksRepositoryProtocol: Sendable {
    /// Search for stocks by query
    func searchStocks(query: String, limit: Int) async throws -> [StockSearchResult]

    /// Get stock details by symbol
    func getStock(symbol: String) async throws -> Stock

    /// Get real-time quote for a symbol
    func getQuote(symbol: String) async throws -> StockQuote

    /// Get quotes for multiple symbols
    func getQuotes(symbols: [String]) async throws -> [StockQuote]

    /// Get historical price data
    func getHistory(symbol: String, period: HistoryPeriod) async throws -> StockHistory

    /// Get market hours status
    func getMarketStatus() async throws -> MarketHours

    /// Submit a buy order for a stock
    /// - Parameters:
    ///   - symbol: Stock symbol to buy
    ///   - notionalUSD: Dollar amount to invest (USD)
    /// - Returns: The submitted order details
    func submitBuyOrder(symbol: String, notionalUSD: Decimal) async throws -> StockOrder

    /// Invalidate cache
    func invalidateCache() async

    // MARK: - Watchlist Operations

    /// Get all watchlist items
    func getWatchlist() async throws -> [WatchlistItem]

    /// Add a stock to the watchlist
    func addToWatchlist(symbol: String) async throws

    /// Remove a stock from the watchlist
    func removeFromWatchlist(symbol: String) async throws

    /// Check if a stock is in the watchlist
    func isInWatchlist(symbol: String) async throws -> Bool

    /// Get watchlist items with current quotes
    func getWatchlistWithQuotes() async throws -> [WatchlistItemWithQuote]
}

/// Implementation of the stocks repository using the API client
final class StocksRepository: StocksRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let apiClient: APIClientProtocol
    private var quoteCache: [String: (quote: StockQuote, timestamp: Date)] = [:]
    private var stockCache: [String: Stock] = [:]
    private var marketStatusCache: (status: MarketHours, timestamp: Date)?
    private let quoteCacheDuration: TimeInterval = 5 // 5 seconds for quotes
    private let stockCacheDuration: TimeInterval = 300 // 5 minutes for stock details
    private let marketStatusCacheDuration: TimeInterval = 60 // 1 minute for market status

    // MARK: - Watchlist Storage

    private static let watchlistKey = "com.growfolio.watchlist"
    private let userDefaults: UserDefaults

    // MARK: - Initialization

    init(apiClient: APIClientProtocol = APIClient.shared, userDefaults: UserDefaults = .standard) {
        self.apiClient = apiClient
        self.userDefaults = userDefaults
    }

    // MARK: - Search

    func searchStocks(query: String, limit: Int = 10) async throws -> [StockSearchResult] {
        guard !query.isEmpty else { return [] }

        return try await apiClient.request(
            Endpoints.SearchStocks(query: query, limit: limit)
        )
    }

    // MARK: - Stock Details

    func getStock(symbol: String) async throws -> Stock {
        let uppercasedSymbol = symbol.uppercased()

        // Check cache
        if let cached = stockCache[uppercasedSymbol],
           let lastUpdated = cached.lastUpdated,
           Date().timeIntervalSince(lastUpdated) < stockCacheDuration {
            return cached
        }

        let stock: Stock = try await apiClient.request(
            Endpoints.GetStock(symbol: uppercasedSymbol)
        )

        stockCache[uppercasedSymbol] = stock

        return stock
    }

    // MARK: - Quotes

    func getQuote(symbol: String) async throws -> StockQuote {
        let uppercasedSymbol = symbol.uppercased()

        // Check cache
        if let cached = quoteCache[uppercasedSymbol],
           Date().timeIntervalSince(cached.timestamp) < quoteCacheDuration {
            return cached.quote
        }

        let quote: StockQuote = try await apiClient.request(
            Endpoints.GetStockQuote(symbol: uppercasedSymbol)
        )

        quoteCache[uppercasedSymbol] = (quote: quote, timestamp: Date())

        return quote
    }

    func getQuotes(symbols: [String]) async throws -> [StockQuote] {
        // Fetch quotes in parallel
        return try await withThrowingTaskGroup(of: StockQuote?.self) { group in
            for symbol in symbols {
                group.addTask {
                    try? await self.getQuote(symbol: symbol)
                }
            }

            var quotes: [StockQuote] = []
            for try await quote in group {
                if let quote = quote {
                    quotes.append(quote)
                }
            }
            return quotes
        }
    }

    // MARK: - Historical Data

    func getHistory(symbol: String, period: HistoryPeriod) async throws -> StockHistory {
        return try await apiClient.request(
            Endpoints.GetStockHistory(symbol: symbol.uppercased(), period: period)
        )
    }

    // MARK: - Market Status

    func getMarketStatus() async throws -> MarketHours {
        // Check cache first
        if let cached = marketStatusCache,
           Date().timeIntervalSince(cached.timestamp) < marketStatusCacheDuration {
            return cached.status
        }

        do {
            // Try to fetch from API
            let status: MarketHours = try await apiClient.request(
                Endpoints.GetMarketStatus()
            )

            // Cache the result
            marketStatusCache = (status: status, timestamp: Date())

            return status
        } catch {
            // Fall back to local calculation if API fails
            let fallbackStatus = MarketHours.fallback()
            return fallbackStatus
        }
    }

    // MARK: - Cache Operations

    func invalidateCache() async {
        quoteCache = [:]
        stockCache = [:]
        marketStatusCache = nil
    }

    // MARK: - Order Operations

    func submitBuyOrder(symbol: String, notionalUSD: Decimal) async throws -> StockOrder {
        let uppercasedSymbol = symbol.uppercased()

        let order: StockOrder = try await apiClient.request(
            try Endpoints.SubmitBuyOrder(symbol: uppercasedSymbol, notionalUSD: notionalUSD)
        )

        return order
    }

    // MARK: - Watchlist Operations

    func getWatchlist() async throws -> [WatchlistItem] {
        loadWatchlistFromStorage()
    }

    func addToWatchlist(symbol: String) async throws {
        var watchlist = loadWatchlistFromStorage()
        let uppercasedSymbol = symbol.uppercased()

        // Check if already in watchlist
        guard !watchlist.contains(where: { $0.symbol == uppercasedSymbol }) else {
            return
        }

        let item = WatchlistItem(symbol: uppercasedSymbol)
        watchlist.append(item)
        saveWatchlistToStorage(watchlist)
    }

    func removeFromWatchlist(symbol: String) async throws {
        var watchlist = loadWatchlistFromStorage()
        let uppercasedSymbol = symbol.uppercased()

        watchlist.removeAll { $0.symbol == uppercasedSymbol }
        saveWatchlistToStorage(watchlist)
    }

    func isInWatchlist(symbol: String) async throws -> Bool {
        let watchlist = loadWatchlistFromStorage()
        let uppercasedSymbol = symbol.uppercased()
        return watchlist.contains { $0.symbol == uppercasedSymbol }
    }

    func getWatchlistWithQuotes() async throws -> [WatchlistItemWithQuote] {
        let watchlist = loadWatchlistFromStorage()

        // Fetch quotes and stock data in parallel
        return try await withThrowingTaskGroup(of: WatchlistItemWithQuote.self) { group in
            for item in watchlist {
                group.addTask {
                    // Try to get stock and quote data, but don't fail if unavailable
                    let stock = try? await self.getStock(symbol: item.symbol)
                    let quote = try? await self.getQuote(symbol: item.symbol)

                    return WatchlistItemWithQuote(
                        item: item,
                        stock: stock,
                        quote: quote
                    )
                }
            }

            var results: [WatchlistItemWithQuote] = []
            for try await result in group {
                results.append(result)
            }

            // Sort by date added (newest first)
            return results.sorted { $0.dateAdded > $1.dateAdded }
        }
    }

    // MARK: - Private Watchlist Helpers

    private func loadWatchlistFromStorage() -> [WatchlistItem] {
        guard let data = userDefaults.data(forKey: Self.watchlistKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([WatchlistItem].self, from: data)
        } catch {
            // If decoding fails, return empty array
            return []
        }
    }

    private func saveWatchlistToStorage(_ watchlist: [WatchlistItem]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(watchlist)
            userDefaults.set(data, forKey: Self.watchlistKey)
        } catch {
            // Log error in production
        }
    }
}

// MARK: - Stocks Repository Error

/// Errors specific to stock operations
enum StocksRepositoryError: LocalizedError {
    case stockNotFound(symbol: String)
    case invalidSymbol
    case quotesUnavailable
    case historyUnavailable
    case marketDataUnavailable
    case orderSubmissionFailed(reason: String)
    case insufficientFunds
    case marketClosed

    var errorDescription: String? {
        switch self {
        case .stockNotFound(let symbol):
            return "Stock '\(symbol)' was not found"
        case .invalidSymbol:
            return "Invalid stock symbol"
        case .quotesUnavailable:
            return "Quotes are temporarily unavailable"
        case .historyUnavailable:
            return "Historical data is unavailable"
        case .marketDataUnavailable:
            return "Market data is temporarily unavailable"
        case .orderSubmissionFailed(let reason):
            return "Failed to submit order: \(reason)"
        case .insufficientFunds:
            return "Insufficient funds to complete this order"
        case .marketClosed:
            return "The market is currently closed. Please try again during market hours."
        }
    }
}
