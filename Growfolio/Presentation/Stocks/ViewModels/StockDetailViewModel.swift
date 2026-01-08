//
//  StockDetailViewModel.swift
//  Growfolio
//
//  View model for stock detail page - fetches stock data, price, and AI explanation.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class StockDetailViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Loading States
    var isLoading = false
    var isLoadingPrice = false
    var isLoadingExplanation = false
    var isLoadingWatchlist = false
    var error: Error?

    // Error display
    var priceRefreshError: Error?
    var historyError: Error?
    var aiError: Error?
    var watchlistError: Error?

    // Watchlist State
    private(set) var isInWatchlistState = false

    // Stock Data
    var stock: Stock?
    var quote: StockQuote?
    var history: StockHistory?
    var aiExplanation: String?
    var marketHours: MarketHours?

    // Selection
    var selectedPeriod: HistoryPeriod = .oneMonth

    // Sheet Presentation
    var showBuySheet = false
    var showAddToDCASheet = false
    var showFullDescription = false

    // Repositories
    private let stocksRepository: StocksRepositoryProtocol
    private let aiRepository: AIRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol
    nonisolated(unsafe) private var quoteUpdatesTask: Task<Void, Never>?
    private var isQuoteSubscriptionActive = false

    // Symbol
    private(set) var symbol: String

    // MARK: - Computed Properties

    var displayPrice: String {
        if let price = quote?.price {
            return price.currencyString
        } else if let price = stock?.currentPrice {
            return price.currencyString
        }
        return "--"
    }

    /// Current price as Decimal (for use in buy sheet)
    var currentPriceDecimal: Decimal? {
        quote?.price ?? stock?.currentPrice
    }

    var priceChange: String {
        if let change = quote?.formattedChange {
            return change
        } else if let change = stock?.priceChange {
            let sign = change >= 0 ? "+" : ""
            return "\(sign)\(change.currencyString)"
        }
        return "--"
    }

    var priceChangePercent: String {
        if let percent = quote?.formattedChangePercent {
            return percent
        } else if let percent = stock?.priceChangePercent {
            let sign = percent >= 0 ? "+" : ""
            return "\(sign)\(percent.rounded(places: 2))%"
        }
        return "--"
    }

    var isPriceUp: Bool {
        quote?.isPriceUp ?? stock?.isPriceUp ?? true
    }

    var companyName: String {
        stock?.name ?? symbol
    }

    var exchange: String? {
        stock?.exchange
    }

    var sector: String? {
        stock?.sector
    }

    var industry: String? {
        stock?.industry
    }

    var hasDescription: Bool {
        stock?.companyDescription != nil && !(stock?.companyDescription?.isEmpty ?? true)
    }

    var shortDescription: String {
        guard let desc = stock?.companyDescription else { return "" }
        if desc.count > 200 {
            return String(desc.prefix(200)) + "..."
        }
        return desc
    }

    var marketCap: String? {
        stock?.formattedMarketCap
    }

    var peRatio: String? {
        guard let pe = stock?.peRatio else { return nil }
        return String(format: "%.2f", NSDecimalNumber(decimal: pe).doubleValue)
    }

    var dividendYield: String? {
        guard let yield = stock?.dividendYield, yield > 0 else { return nil }
        return "\(yield.rounded(places: 2))%"
    }

    var volume: String? {
        stock?.formattedVolume
    }

    var dayRange: String? {
        stock?.dayRange
    }

    var weekRange52: String? {
        stock?.weekRange52
    }

    var isInWatchlist: Bool {
        isInWatchlistState
    }

    // MARK: - Initialization

    init(
        symbol: String,
        stocksRepository: StocksRepositoryProtocol = RepositoryContainer.stocksRepository,
        aiRepository: AIRepositoryProtocol = RepositoryContainer.aiRepository,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.symbol = symbol.uppercased()
        self.stocksRepository = stocksRepository
        self.aiRepository = aiRepository
        self.webSocketService = webSocketService ?? MainActor.assumeIsolated { WebSocketService.shared }
    }

    // MARK: - Data Loading

    @MainActor
    func loadStock() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Load stock details and quote in parallel
            async let stockTask = stocksRepository.getStock(symbol: symbol)
            async let quoteTask = stocksRepository.getQuote(symbol: symbol)
            async let historyTask = stocksRepository.getHistory(symbol: symbol, period: selectedPeriod)
            async let marketStatusTask = stocksRepository.getMarketStatus()

            stock = try await stockTask
            quote = try await quoteTask
            history = try? await historyTask
            marketHours = try? await marketStatusTask

            // Also check watchlist status
            await checkWatchlistStatus()
            await startQuoteUpdates()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func checkWatchlistStatus() async {
        do {
            isInWatchlistState = try await stocksRepository.isInWatchlist(symbol: symbol)
        } catch {
            // Silently fail - watchlist status is not critical
        }
    }

    @MainActor
    func refreshPrice() async {
        isLoadingPrice = true
        priceRefreshError = nil

        do {
            quote = try await stocksRepository.getQuote(symbol: symbol)
        } catch {
            // Show error via toast for price refresh failures
            priceRefreshError = error
            Task { @MainActor in
                ToastManager.shared.showError(
                    "Unable to refresh price",
                    actionTitle: "Retry"
                ) { [weak self] in
                    guard let self else { return }
                    Task { await self.refreshPrice() }
                }
            }
        }

        isLoadingPrice = false
    }

    @MainActor
    func stopQuoteUpdates() async {
        guard isQuoteSubscriptionActive else { return }

        quoteUpdatesTask?.cancel()
        quoteUpdatesTask = nil
        isQuoteSubscriptionActive = false

        await webSocketService.unsubscribeFromQuotes(symbols: [symbol])
    }

    @MainActor
    func loadHistory(period: HistoryPeriod) async {
        selectedPeriod = period
        historyError = nil

        do {
            history = try await stocksRepository.getHistory(symbol: symbol, period: period)
        } catch {
            // Show error via toast for history load failures
            historyError = error
            Task { @MainActor in
                ToastManager.shared.showError(
                    "Unable to load price history",
                    actionTitle: "Retry"
                ) { [weak self] in
                    guard let self else { return }
                    Task { await self.loadHistory(period: period) }
                }
            }
        }
    }

    @MainActor
    func loadAIExplanation() async {
        guard aiExplanation == nil else { return }

        isLoadingExplanation = true
        aiError = nil

        do {
            let response = try await aiRepository.fetchStockExplanation(symbol: symbol)
            aiExplanation = response.explanation
        } catch {
            // AI explanation failures are shown as info toast (non-critical feature)
            aiError = error
            Task { @MainActor in
                ToastManager.shared.showInfo("AI insights temporarily unavailable")
            }
        }

        isLoadingExplanation = false
    }

    // MARK: - Actions

    func buyStock() {
        showBuySheet = true
    }

    func addToDCA() {
        showAddToDCASheet = true
    }

    @MainActor
    private func startQuoteUpdates() async {
        guard !isQuoteSubscriptionActive else { return }
        isQuoteSubscriptionActive = true

        await webSocketService.subscribeToQuotes(symbols: [symbol])

        quoteUpdatesTask = Task { [weak self] in
            guard let self else { return }
            let stream = await webSocketService.quoteUpdates()
            for await quote in stream where quote.symbol == self.symbol {
                await MainActor.run {
                    self.quote = quote
                }
            }
        }
    }

    @MainActor
    func toggleWatchlist() {
        guard !isLoadingWatchlist else { return }

        isLoadingWatchlist = true
        watchlistError = nil

        Task {
            do {
                if isInWatchlistState {
                    try await stocksRepository.removeFromWatchlist(symbol: symbol)
                    isInWatchlistState = false
                    ToastManager.shared.showSuccess("Removed from watchlist")
                } else {
                    try await stocksRepository.addToWatchlist(symbol: symbol)
                    isInWatchlistState = true
                    ToastManager.shared.showSuccess("Added to watchlist")
                }
            } catch {
                watchlistError = error
                ToastManager.shared.showError(
                    isInWatchlistState ? "Failed to remove from watchlist" : "Failed to add to watchlist",
                    actionTitle: "Retry"
                ) { [weak self] in
                    guard let self else { return }
                    Task { @MainActor [weak self] in
                        self?.toggleWatchlist()
                    }
                }
            }

            isLoadingWatchlist = false
        }
    }

    func shareStock() -> String {
        let url = "https://growfolio.app/stock/\(symbol)"
        return "Check out \(companyName) (\(symbol)) on Growfolio: \(url)"
    }
}

// MARK: - Preview Helper

extension StockDetailViewModel {
    static var preview: StockDetailViewModel {
        let viewModel = StockDetailViewModel(symbol: "AAPL")
        viewModel.stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            exchange: "NASDAQ",
            assetType: .stock,
            currentPrice: 185.92,
            priceChange: 2.34,
            priceChangePercent: 1.27,
            previousClose: 183.58,
            openPrice: 184.25,
            dayHigh: 186.50,
            dayLow: 183.80,
            weekHigh52: 199.62,
            weekLow52: 124.17,
            volume: 52_431_678,
            averageVolume: 58_000_000,
            marketCap: 2_890_000_000_000,
            peRatio: 28.5,
            dividendYield: 0.51,
            eps: 6.52,
            beta: 1.25,
            sector: "Technology",
            industry: "Consumer Electronics",
            companyDescription: "Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide. The company offers iPhone, Mac, iPad, and wearables, home, and accessories.",
            currencyCode: "USD",
            lastUpdated: Date()
        )
        viewModel.quote = StockQuote(
            symbol: "AAPL",
            price: 185.92,
            change: 2.34,
            changePercent: 1.27,
            volume: 52_431_678,
            timestamp: Date()
        )
        return viewModel
    }
}
