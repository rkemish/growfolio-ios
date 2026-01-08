//
//  WatchlistViewModel.swift
//  Growfolio
//
//  View model for the watchlist screen - manages watchlist items and their quotes.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class WatchlistViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Loading States
    var isLoading = false
    var isRefreshing = false
    var error: Error?

    // Data
    var watchlistItems: [WatchlistItemWithQuote] = []

    // Selection for navigation
    var selectedSymbol: String?

    // Repository
    private let stocksRepository: StocksRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol
    nonisolated(unsafe) private var quoteUpdatesTask: Task<Void, Never>?
    nonisolated(unsafe) private var connectionObserverTask: Task<Void, Never>?
    private var subscribedSymbols: Set<String> = []
    private var previousConnectionState: WebSocketService.ConnectionState = .disconnected

    // MARK: - Computed Properties

    var isEmpty: Bool {
        watchlistItems.isEmpty
    }

    var itemCount: Int {
        watchlistItems.count
    }

    // MARK: - Initialization

    init(
        stocksRepository: StocksRepositoryProtocol = RepositoryContainer.stocksRepository,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.stocksRepository = stocksRepository
        self.webSocketService = webSocketService ?? MainActor.assumeIsolated { WebSocketService.shared }
        startConnectionObserver()
    }

    deinit {
        quoteUpdatesTask?.cancel()
        connectionObserverTask?.cancel()
    }

    // MARK: - Data Loading

    @MainActor
    func loadWatchlist() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            watchlistItems = try await stocksRepository.getWatchlistWithQuotes()
            await updateQuoteSubscriptions()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func refreshWatchlist() async {
        isRefreshing = true
        error = nil

        do {
            watchlistItems = try await stocksRepository.getWatchlistWithQuotes()
            await updateQuoteSubscriptions()
        } catch {
            self.error = error
            ToastManager.shared.showError(
                "Unable to refresh watchlist",
                actionTitle: "Retry"
            ) { [weak self] in
                guard let self else { return }
                Task { await self.refreshWatchlist() }
            }
        }

        isRefreshing = false
    }

    // MARK: - Actions

    @MainActor
    func removeFromWatchlist(symbol: String) async {
        do {
            try await stocksRepository.removeFromWatchlist(symbol: symbol)

            // Remove from local list
            watchlistItems.removeAll { $0.symbol == symbol }
            await updateQuoteSubscriptions()

            ToastManager.shared.showSuccess("Removed from watchlist")
        } catch {
            ToastManager.shared.showError(
                "Failed to remove from watchlist",
                actionTitle: "Retry"
            ) { [weak self] in
                guard let self else { return }
                Task { await self.removeFromWatchlist(symbol: symbol) }
            }
        }
    }

    @MainActor
    func removeFromWatchlist(at offsets: IndexSet) async {
        // Get symbols to remove before modifying the array
        let symbolsToRemove = offsets.map { watchlistItems[$0].symbol }

        for symbol in symbolsToRemove {
            await removeFromWatchlist(symbol: symbol)
        }
    }

    func selectStock(_ symbol: String) {
        selectedSymbol = symbol
    }

    @MainActor
    func stopQuoteUpdates() async {
        quoteUpdatesTask?.cancel()
        quoteUpdatesTask = nil
        connectionObserverTask?.cancel()
        connectionObserverTask = nil

        let symbols = Array(subscribedSymbols)
        subscribedSymbols.removeAll()
        if !symbols.isEmpty {
            await webSocketService.unsubscribeFromQuotes(symbols: symbols)
        }
    }

    // MARK: - Connection Observation

    private func startConnectionObserver() {
        connectionObserverTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // Use withObservationTracking to observe WebSocketService.shared.connectionState
            while !Task.isCancelled {
                let currentState = WebSocketService.shared.connectionState

                // Check for reconnection: transitioning to connected from disconnected/connecting
                if currentState == .connected && previousConnectionState != .connected {
                    await resubscribeSymbols()
                }

                previousConnectionState = currentState

                // Wait for the next state change using observation tracking
                await withCheckedContinuation { continuation in
                    withObservationTracking {
                        _ = WebSocketService.shared.connectionState
                    } onChange: {
                        continuation.resume()
                    }
                }
            }
        }
    }

    @MainActor
    private func resubscribeSymbols() async {
        guard !subscribedSymbols.isEmpty else { return }
        let symbols = Array(subscribedSymbols)
        await webSocketService.subscribeToQuotes(symbols: symbols)
    }
}

// MARK: - Quote Updates

private extension WatchlistViewModel {
    @MainActor
    func updateQuoteSubscriptions() async {
        let symbols = Set(watchlistItems.map { $0.symbol.uppercased() })
        let newSymbols = symbols.subtracting(subscribedSymbols)
        let removedSymbols = subscribedSymbols.subtracting(symbols)

        if !newSymbols.isEmpty {
            await webSocketService.subscribeToQuotes(symbols: Array(newSymbols))
        }
        if !removedSymbols.isEmpty {
            await webSocketService.unsubscribeFromQuotes(symbols: Array(removedSymbols))
        }

        subscribedSymbols = symbols
        if !symbols.isEmpty {
            startQuoteUpdatesIfNeeded()
        }
    }

    @MainActor
    func startQuoteUpdatesIfNeeded() {
        guard quoteUpdatesTask == nil else { return }

        quoteUpdatesTask = Task { [weak self] in
            guard let self else { return }
            let stream = await webSocketService.quoteUpdates()
            for await quote in stream {
                await MainActor.run {
                    self.applyQuoteUpdate(quote)
                }
            }
        }
    }

    @MainActor
    func applyQuoteUpdate(_ quote: StockQuote) {
        guard let index = watchlistItems.firstIndex(where: { $0.symbol == quote.symbol }) else { return }
        let currentItem = watchlistItems[index]
        watchlistItems[index] = WatchlistItemWithQuote(
            item: currentItem.item,
            stock: currentItem.stock,
            quote: quote
        )
    }
}

// MARK: - Preview Helper

extension WatchlistViewModel {
    static var preview: WatchlistViewModel {
        let viewModel = WatchlistViewModel()

        let items: [WatchlistItemWithQuote] = [
            WatchlistItemWithQuote(
                item: WatchlistItem(symbol: "AAPL", dateAdded: Date().addingTimeInterval(-86400 * 7)),
                stock: Stock(
                    symbol: "AAPL",
                    name: "Apple Inc.",
                    exchange: "NASDAQ",
                    currentPrice: 185.92,
                    priceChange: 2.34,
                    priceChangePercent: 1.27
                ),
                quote: StockQuote(
                    symbol: "AAPL",
                    price: 185.92,
                    change: 2.34,
                    changePercent: 1.27,
                    volume: 52_431_678,
                    timestamp: Date()
                )
            ),
            WatchlistItemWithQuote(
                item: WatchlistItem(symbol: "MSFT", dateAdded: Date().addingTimeInterval(-86400 * 3)),
                stock: Stock(
                    symbol: "MSFT",
                    name: "Microsoft Corporation",
                    exchange: "NASDAQ",
                    currentPrice: 378.91,
                    priceChange: -1.23,
                    priceChangePercent: -0.32
                ),
                quote: StockQuote(
                    symbol: "MSFT",
                    price: 378.91,
                    change: -1.23,
                    changePercent: -0.32,
                    volume: 18_234_567,
                    timestamp: Date()
                )
            ),
            WatchlistItemWithQuote(
                item: WatchlistItem(symbol: "GOOGL", dateAdded: Date().addingTimeInterval(-86400)),
                stock: Stock(
                    symbol: "GOOGL",
                    name: "Alphabet Inc.",
                    exchange: "NASDAQ",
                    currentPrice: 141.80,
                    priceChange: 0.56,
                    priceChangePercent: 0.40
                ),
                quote: StockQuote(
                    symbol: "GOOGL",
                    price: 141.80,
                    change: 0.56,
                    changePercent: 0.40,
                    volume: 24_567_890,
                    timestamp: Date()
                )
            )
        ]

        viewModel.watchlistItems = items
        return viewModel
    }

    static var emptyPreview: WatchlistViewModel {
        WatchlistViewModel()
    }
}
