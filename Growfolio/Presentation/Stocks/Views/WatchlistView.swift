//
//  WatchlistView.swift
//  Growfolio
//
//  View displaying the user's stock watchlist with real-time quotes.
//

import SwiftUI

struct WatchlistView: View {

    // MARK: - Properties

    @State private var viewModel = WatchlistViewModel()
    @State private var showStockSearch = false
    @State private var selectedSymbolForDetail: String?
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(NavigationState.self) private var navState: NavigationState?

    // MARK: - Body

    /// Check if we're in iPad split view mode (navState available means iPad)
    private var isIPad: Bool {
        navState != nil
    }

    var body: some View {
        Group {
            if isIPad {
                watchlistMainContent
            } else {
                NavigationStack {
                    watchlistMainContent
                }
            }
        }
    }

    private var watchlistMainContent: some View {
        ZStack {
            if viewModel.isLoading && viewModel.watchlistItems.isEmpty {
                loadingView
            } else if let error = viewModel.error, viewModel.watchlistItems.isEmpty {
                errorView(error)
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                watchlistContent
            }
        }
        .navigationTitle("Watchlist")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showStockSearch = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await viewModel.refreshWatchlist()
        }
        .task {
            await viewModel.loadWatchlist()
        }
        .sheet(isPresented: $showStockSearch) {
            StockSearchView { symbol in
                showStockSearch = false
                // After adding from search, refresh the list
                Task {
                    await viewModel.refreshWatchlist()
                }
            }
        }
        .sheet(item: Binding(
            get: { navState == nil ? selectedSymbolForDetail : nil },
            set: { selectedSymbolForDetail = $0 }
        )) { symbol in
            StockDetailView(symbol: symbol)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading watchlist...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                Task {
                    await viewModel.loadWatchlist()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Stocks in Watchlist", systemImage: "star")
        } description: {
            Text("Add stocks to your watchlist to track their prices and performance.")
        } actions: {
            Button {
                showStockSearch = true
            } label: {
                Label("Add Stock", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Watchlist Content

    private var watchlistContent: some View {
        List {
            ForEach(viewModel.watchlistItems) { item in
                WatchlistRowView(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let navState = navState {
                            // iPad: Update navigation state
                            navState.selectedStock = item.symbol
                        } else {
                            // iPhone: Show sheet
                            selectedSymbolForDetail = item.symbol
                        }
                    }
            }
            .onDelete { offsets in
                Task {
                    await viewModel.removeFromWatchlist(at: offsets)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Watchlist Row View

struct WatchlistRowView: View {
    let item: WatchlistItemWithQuote

    var body: some View {
        HStack(spacing: 12) {
            // Stock Symbol Badge
            Circle()
                .fill(item.isPriceUp ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay {
                    Text(String(item.symbol.prefix(2)))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(item.isPriceUp ? Color.positive : Color.negative)
                }

            // Stock Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.symbol)
                    .font(.headline)

                Text(item.companyName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Price Info
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.formattedPrice)
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: item.isPriceUp ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)

                    Text(item.formattedChangePercent)
                        .font(.subheadline)
                }
                .foregroundStyle(item.isPriceUp ? Color.positive : Color.negative)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - String Extension for Sheet Item

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Stock Search View

struct StockSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [StockSearchResult] = []
    @State private var isSearching = false
    @State private var selectedSymbol: String?

    private let stocksRepository: StocksRepositoryProtocol = RepositoryContainer.stocksRepository
    let onStockSelected: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if searchResults.isEmpty && !isSearching {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(searchResults) { result in
                        Button {
                            addToWatchlist(symbol: result.symbol)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.symbol)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Text(result.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if let exchange = result.exchange {
                                    Text(exchange)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray5))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Add to Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search stocks...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: searchText) { _, newValue in
                searchStocks(query: newValue)
            }
            .overlay {
                if isSearching {
                    ProgressView()
                }
            }
        }
    }

    private func searchStocks(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        Task {
            do {
                let results = try await stocksRepository.searchStocks(query: query, limit: 20)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }

    private func addToWatchlist(symbol: String) {
        Task {
            do {
                try await stocksRepository.addToWatchlist(symbol: symbol)
                await MainActor.run {
                    ToastManager.shared.showSuccess("\(symbol) added to watchlist")
                    onStockSelected(symbol)
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("Failed to add \(symbol) to watchlist")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Watchlist with Items") {
    WatchlistView()
}

#Preview("Empty Watchlist") {
    let view = WatchlistView()
    return view
}
