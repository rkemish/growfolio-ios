//
//  CostBasisView.swift
//  Growfolio
//
//  Detailed cost basis view for a specific holding.
//

import SwiftUI

struct CostBasisView: View {

    // MARK: - Properties

    let holding: Holding

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CostBasisViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if let summary = viewModel.costBasisSummary {
                    costBasisContent(summary)
                } else {
                    emptyView
                }
            }
            .navigationTitle("Cost Basis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadCostBasis(
                    for: holding.stockSymbol,
                    currentPrice: holding.currentPricePerShare
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading cost basis...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task {
                    await viewModel.loadCostBasis(
                        for: holding.stockSymbol,
                        currentPrice: holding.currentPricePerShare
                    )
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Cost Basis Data", systemImage: "doc.text")
        } description: {
            Text("No purchase history found for \(holding.stockSymbol)")
        }
    }

    // MARK: - Cost Basis Content

    private func costBasisContent(_ summary: CostBasisSummary) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection(summary)

                // Summary Card
                summaryCard(summary)

                // Unrealized P&L Card
                pnlCard(summary)

                // Tax Summary Section
                taxSummarySection(summary)

                // Purchase Lots Section
                lotsSection(summary)

                // Export Hint
                exportHintSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Header Section

    private func headerSection(_ summary: CostBasisSummary) -> some View {
        VStack(spacing: 8) {
            Text(summary.symbol)
                .font(.largeTitle)
                .fontWeight(.bold)

            if let name = holding.stockName {
                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("\(summary.totalShares.sharesString) shares")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
    }

    // MARK: - Summary Card

    private func summaryCard(_ summary: CostBasisSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Basis Summary")
                .font(.headline)

            VStack(spacing: 0) {
                // Total Cost Basis
                HStack {
                    Text("Total Cost Basis")
                        .foregroundStyle(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(summary.totalCostUsd.currencyString(code: "USD"))
                            .fontWeight(.medium)
                        Text(summary.totalCostGbp.currencyString(code: "GBP"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Divider()

                // Average Cost Per Share
                HStack {
                    Text("Avg Cost/Share")
                        .foregroundStyle(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(summary.averageCostUsd.currencyString(code: "USD"))
                            .fontWeight(.medium)
                        Text(summary.averageCostGbp.currencyString(code: "GBP"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Divider()

                // Current Price
                HStack {
                    Text("Current Price")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(holding.currentPricePerShare.currencyString(code: "USD"))
                        .fontWeight(.medium)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Divider()

                // Current Value
                HStack {
                    Text("Current Value")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(holding.marketValue.currencyString(code: "USD"))
                        .fontWeight(.medium)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Divider()

                // Average FX Rate
                HStack {
                    Text("Weighted Avg FX Rate")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.4f", NSDecimalNumber(decimal: summary.weightedAverageFxRate).doubleValue))
                        .fontWeight(.medium)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - P&L Card

    private func pnlCard(_ summary: CostBasisSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unrealized P&L")
                .font(.headline)

            HStack(spacing: 24) {
                // USD P&L
                VStack(spacing: 4) {
                    Text("USD")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: summary.isProfitable ? "arrow.up.right" : "arrow.down.right")
                        Text(summary.unrealizedPnlUsd.currencyString(code: "USD"))
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(summary.isProfitable ? Color.positive : Color.negative)
                }

                Spacer()

                // GBP P&L
                VStack(spacing: 4) {
                    Text("GBP")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: summary.isProfitable ? "arrow.up.right" : "arrow.down.right")
                        Text(summary.unrealizedPnlGbp.currencyString(code: "GBP"))
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(summary.isProfitable ? Color.positive : Color.negative)
                }

                Spacer()

                // Percentage
                VStack(spacing: 4) {
                    Text("Return")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(summary.isProfitable ? "+" : "")\(summary.unrealizedPnlPercentage.rounded(places: 2))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(summary.isProfitable ? Color.positive : Color.negative)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Tax Summary Section

    private func taxSummarySection(_ summary: CostBasisSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tax Summary")
                    .font(.headline)

                Spacer()

                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                // Short-term holdings
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Short-Term Holdings")
                            .fontWeight(.medium)
                        Text("Held 1 year or less")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(summary.shortTermShares.sharesString) shares")
                            .fontWeight(.medium)
                        if summary.shortTermUnrealizedPnlUsd != 0 {
                            Text(summary.shortTermUnrealizedPnlUsd.currencyString(code: "USD"))
                                .font(.caption)
                                .foregroundStyle(summary.shortTermUnrealizedPnlUsd > 0 ? Color.positive : Color.negative)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Divider()

                // Long-term holdings
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Long-Term Holdings")
                            .fontWeight(.medium)
                        Text("Held more than 1 year")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(summary.longTermShares.sharesString) shares")
                            .fontWeight(.medium)
                        if summary.longTermUnrealizedPnlUsd != 0 {
                            Text(summary.longTermUnrealizedPnlUsd.currencyString(code: "USD"))
                                .font(.caption)
                                .foregroundStyle(summary.longTermUnrealizedPnlUsd > 0 ? Color.positive : Color.negative)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                if summary.longTermPercentage > 0 {
                    Divider()

                    // Long-term percentage
                    HStack {
                        Text("Long-Term %")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(summary.longTermPercentage.rounded(places: 1))%")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.positive)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Tax note
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)

                Text("Long-term holdings may qualify for preferential capital gains tax rates. Consult a tax professional for advice specific to your situation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Lots Section

    private func lotsSection(_ summary: CostBasisSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Purchase Lots")
                    .font(.headline)

                Spacer()

                Text("\(summary.lotCount) lots")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Table Header
            HStack {
                Text("Date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .leading)

                Text("Shares")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .trailing)

                Text("Price")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .trailing)

                Text("Cost USD")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 70, alignment: .trailing)

                Text("FX")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
            .padding(.horizontal, 12)

            // Lot Rows
            ForEach(summary.lots.sortedByDateDescending) { lot in
                lotRow(lot)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func lotRow(_ lot: CostBasisLot) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(lot.date.shortDateString)
                    .font(.subheadline)
                    .frame(width: 80, alignment: .leading)

                Text(lot.shares.sharesString)
                    .font(.subheadline)
                    .frame(width: 50, alignment: .trailing)

                Text(lot.priceUsd.currencyString(code: "USD"))
                    .font(.caption)
                    .frame(width: 60, alignment: .trailing)

                Text(lot.totalUsd.currencyString(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(minWidth: 70, alignment: .trailing)

                Text(String(format: "%.2f", NSDecimalNumber(decimal: lot.fxRate).doubleValue))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // GBP cost and holding period indicator
            HStack {
                // Holding period badge
                Text(lot.holdingPeriodCategory.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(lot.isLongTerm ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundStyle(lot.isLongTerm ? Color.positive : Color.warning)
                    .clipShape(Capsule())

                Spacer()

                Text(lot.totalGbp.currencyString(code: "GBP"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Export Hint Section

    private var exportHintSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(Color.trustBlue)

                Text("Tax Reporting")
                    .font(.headline)
            }

            Text("For tax reporting purposes, you may need to provide cost basis information to HMRC or IRS. The data shown above includes all purchase lots with their respective FX rates at the time of purchase.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Consider consulting a tax professional familiar with cross-border investments for guidance on reporting requirements.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Cost Basis View Model

@Observable
final class CostBasisViewModel {
    var costBasisSummary: CostBasisSummary?
    var isLoading = false
    var errorMessage: String?

    private let repository: PortfolioRepositoryProtocol

    init(repository: PortfolioRepositoryProtocol = RepositoryContainer.portfolioRepository) {
        self.repository = repository
    }

    func loadCostBasis(for symbol: String, currentPrice: Decimal) async {
        isLoading = true
        errorMessage = nil

        do {
            var summary = try await repository.getCostBasis(symbol: symbol)
            // Add current market price for P&L calculations
            summary.currentPriceUsd = currentPrice
            // Estimate current FX rate from weighted average (in real app, would fetch current rate)
            summary.currentFxRate = summary.weightedAverageFxRate
            costBasisSummary = summary
        } catch {
            errorMessage = "Failed to load cost basis: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    CostBasisView(
        holding: Holding(
            portfolioId: "1",
            stockSymbol: "AAPL",
            stockName: "Apple Inc.",
            quantity: 10,
            averageCostPerShare: 150,
            currentPricePerShare: 195
        )
    )
}
