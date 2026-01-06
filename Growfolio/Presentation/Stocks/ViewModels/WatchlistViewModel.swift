//
//  WatchlistViewModel.swift
//  Growfolio
//
//  View model for the watchlist screen - manages watchlist items and their quotes.
//

import Foundation
import SwiftUI

@Observable
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

    // MARK: - Computed Properties

    var isEmpty: Bool {
        watchlistItems.isEmpty
    }

    var itemCount: Int {
        watchlistItems.count
    }

    // MARK: - Initialization

    init(stocksRepository: StocksRepositoryProtocol = RepositoryContainer.stocksRepository) {
        self.stocksRepository = stocksRepository
    }

    // MARK: - Data Loading

    @MainActor
    func loadWatchlist() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            watchlistItems = try await stocksRepository.getWatchlistWithQuotes()
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
