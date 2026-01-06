//
//  StockDetailView.swift
//  Growfolio
//
//  Full stock information page with price, company info, and actions.
//

import SwiftUI

struct StockDetailView: View {

    // MARK: - Properties

    @State private var viewModel: StockDetailViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(symbol: String) {
        _viewModel = State(initialValue: StockDetailViewModel(symbol: symbol))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.stock == nil {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    stockContentView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.toggleWatchlist()
                        } label: {
                            Label(
                                viewModel.isInWatchlist ? "Remove from Watchlist" : "Add to Watchlist",
                                systemImage: viewModel.isInWatchlist ? "star.slash" : "star"
                            )
                        }

                        ShareLink(item: viewModel.shareStock()) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button {
                            Task {
                                await viewModel.refreshPrice()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await viewModel.loadStock()
            }
            .sheet(isPresented: $viewModel.showBuySheet) {
                BuyStockSheet(
                    symbol: viewModel.symbol,
                    stockName: viewModel.companyName,
                    currentPriceUSD: viewModel.currentPriceDecimal,
                    onDismiss: {
                        viewModel.showBuySheet = false
                    }
                )
            }
            .sheet(isPresented: $viewModel.showAddToDCASheet) {
                AddToDCASheet(
                    symbol: viewModel.symbol,
                    stockName: viewModel.companyName,
                    onDismiss: {
                        viewModel.showAddToDCASheet = false
                    }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $viewModel.showFullDescription) {
                descriptionSheet
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading stock data...")
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
                    await viewModel.loadStock()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Stock Content

    private var stockContentView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Price Section
                StockPriceView(
                    price: viewModel.displayPrice,
                    change: viewModel.priceChange,
                    changePercent: viewModel.priceChangePercent,
                    isPriceUp: viewModel.isPriceUp,
                    companyName: viewModel.companyName,
                    exchange: viewModel.exchange,
                    isLoading: viewModel.isLoadingPrice,
                    marketHours: viewModel.marketHours
                )

                // Chart placeholder
                chartSection

                // Period Selector
                periodSelector

                // Actions
                StockActionsView(
                    onBuy: viewModel.buyStock,
                    onAddToDCA: viewModel.addToDCA
                )

                // Stock Info
                StockInfoCard(
                    marketCap: viewModel.marketCap,
                    peRatio: viewModel.peRatio,
                    dividendYield: viewModel.dividendYield,
                    volume: viewModel.volume,
                    dayRange: viewModel.dayRange,
                    weekRange52: viewModel.weekRange52,
                    sector: viewModel.sector,
                    industry: viewModel.industry
                )

                // Company Description
                if viewModel.hasDescription {
                    companyDescriptionCard
                }

                // AI Insights
                aiInsightsSection
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshPrice()
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack {
            if let history = viewModel.history, !history.dataPoints.isEmpty {
                // Simple chart visualization
                GeometryReader { geometry in
                    let prices = history.dataPoints.map { $0.close }
                    let minPrice = prices.min() ?? 0
                    let maxPrice = prices.max() ?? 1
                    let range = maxPrice - minPrice

                    Path { path in
                        for (index, dataPoint) in history.dataPoints.enumerated() {
                            let x = geometry.size.width * CGFloat(index) / CGFloat(history.dataPoints.count - 1)
                            let normalizedY = range > 0 ? CGFloat(truncating: (dataPoint.close - minPrice) / range as NSNumber) : 0.5
                            let y = geometry.size.height * (1 - normalizedY)

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        viewModel.isPriceUp ? Color.green : Color.red,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                    )
                }
                .frame(height: 150)
                .padding(.horizontal)
            } else {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 150)
                    .overlay {
                        Text("Chart data unavailable")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([
                    HistoryPeriod.oneWeek,
                    .oneMonth,
                    .threeMonths,
                    .sixMonths,
                    .oneYear,
                    .fiveYears
                ], id: \.rawValue) { period in
                    Button {
                        Task {
                            await viewModel.loadHistory(period: period)
                        }
                    } label: {
                        Text(periodLabel(period))
                            .font(.subheadline)
                            .fontWeight(viewModel.selectedPeriod == period ? .semibold : .regular)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedPeriod == period
                                    ? Color.blue
                                    : Color(.systemGray5)
                            )
                            .foregroundStyle(
                                viewModel.selectedPeriod == period
                                    ? .white
                                    : .primary
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func periodLabel(_ period: HistoryPeriod) -> String {
        switch period {
        case .oneWeek: return "1W"
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .oneYear: return "1Y"
        case .fiveYears: return "5Y"
        case .all: return "All"
        }
    }

    // MARK: - Company Description Card

    private var companyDescriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)

            Text(viewModel.shortDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if (viewModel.stock?.companyDescription?.count ?? 0) > 200 {
                Button {
                    viewModel.showFullDescription = true
                } label: {
                    Text("Read More")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private var descriptionSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let description = viewModel.stock?.companyDescription {
                        Text(description)
                            .font(.body)
                    }

                    if let website = viewModel.stock?.websiteURL {
                        Link(destination: website) {
                            Label("Visit Website", systemImage: "globe")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("About \(viewModel.companyName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.showFullDescription = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - AI Insights Section

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.trustBlue)
                Text("AI Insights")
                    .font(.headline)
            }

            if viewModel.isLoadingExplanation {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating insights...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let explanation = viewModel.aiExplanation {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    Task {
                        await viewModel.loadAIExplanation()
                    }
                } label: {
                    Label("Get AI Analysis", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    StockDetailView(symbol: "AAPL")
}
