//
//  HoldingDetailView.swift
//  Growfolio
//
//  Detailed view for a single holding.
//

import SwiftUI

struct HoldingDetailView: View {

    // MARK: - Properties

    let holding: Holding

    @Environment(\.dismiss) private var dismiss
    @State private var showCostBasisView = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Value Card
                    valueCard

                    // Position Details
                    positionDetailsSection

                    // Cost Basis Section (NEW)
                    costBasisSection

                    // Performance
                    performanceSection

                    // Info
                    infoSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(holding.stockSymbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCostBasisView) {
                CostBasisView(holding: holding)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(holding.stockSymbol)
                .font(.largeTitle)
                .fontWeight(.bold)

            if let name = holding.stockName {
                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Asset Type Badge
            Text(holding.assetType.displayName)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
    }

    // MARK: - Value Card

    private var valueCard: some View {
        VStack(spacing: 16) {
            // Current Value
            VStack(spacing: 4) {
                Text("Market Value")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(holding.marketValue.currencyString)
                    .font(.system(size: 32, weight: .bold))
            }

            Divider()

            // P&L
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("Unrealized P&L")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: holding.isProfitable ? "arrow.up.right" : "arrow.down.right")
                        Text(holding.unrealizedGainLoss.currencyString)
                    }
                    .font(.headline)
                    .foregroundStyle(holding.isProfitable ? Color.positive : Color.negative)
                }

                VStack(spacing: 4) {
                    Text("Return")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(holding.isProfitable ? "+" : "")\(holding.unrealizedGainLossPercentage.rounded(places: 2))%")
                        .font(.headline)
                        .foregroundStyle(holding.isProfitable ? Color.positive : Color.negative)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Position Details

    private var positionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Position")
                .font(.headline)

            VStack(spacing: 0) {
                detailRow(label: "Shares", value: holding.quantity.sharesString)
                Divider()
                detailRow(label: "Avg Cost/Share", value: holding.averageCostPerShare.currencyString)
                Divider()
                detailRow(label: "Current Price", value: holding.currentPricePerShare.currencyString)
                Divider()
                detailRow(label: "Cost Basis", value: holding.costBasis.currencyString)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Cost Basis Section

    private var costBasisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Cost Basis")
                    .font(.headline)

                Spacer()

                Button {
                    showCostBasisView = true
                } label: {
                    HStack(spacing: 4) {
                        Text("View Details")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.trustBlue)
                }
            }

            VStack(spacing: 0) {
                // Total Cost Basis
                HStack {
                    Text("Total Cost")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(holding.costBasis.currencyString)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Divider()

                // Average Cost Per Share
                HStack {
                    Text("Avg Cost/Share")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(holding.averageCostPerShare.currencyString)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Divider()

                // Unrealized P&L
                HStack {
                    Text("Unrealized P&L")
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: holding.isProfitable ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(holding.unrealizedGainLoss.currencyString)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(holding.isProfitable ? Color.positive : Color.negative)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                Divider()

                // Tax Status
                HStack {
                    Text("Tax Status")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(holding.isLongTermHolding ? "Long-Term" : "Short-Term")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(holding.isLongTermHolding ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundStyle(holding.isLongTermHolding ? Color.positive : Color.warning)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Hint text
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Tap \"View Details\" for purchase lots, FX rates, and tax breakdown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Performance

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if let days = holding.holdingPeriodDays {
                    statCard(title: "Holding Period", value: "\(days) days")
                }

                statCard(
                    title: "Long-term",
                    value: holding.isLongTermHolding ? "Yes" : "No",
                    color: holding.isLongTermHolding ? Color.positive : .secondary
                )

                if let priceUpdated = holding.priceUpdatedAt {
                    statCard(title: "Price Updated", value: priceUpdated.relativeString)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Information")
                .font(.headline)

            VStack(spacing: 0) {
                if let sector = holding.sector {
                    detailRow(label: "Sector", value: sector)
                    Divider()
                }

                if let industry = holding.industry {
                    detailRow(label: "Industry", value: industry)
                    Divider()
                }

                if let firstPurchase = holding.firstPurchaseDate {
                    detailRow(label: "First Purchase", value: firstPurchase.displayString)
                    Divider()
                }

                if let lastPurchase = holding.lastPurchaseDate {
                    detailRow(label: "Last Purchase", value: lastPurchase.displayString)
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private func statCard(title: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Preview

#Preview {
    HoldingDetailView(
        holding: Holding(
            portfolioId: "1",
            stockSymbol: "AAPL",
            stockName: "Apple Inc.",
            quantity: 10,
            averageCostPerShare: 150,
            currentPricePerShare: 195,
            sector: "Technology",
            industry: "Consumer Electronics"
        )
    )
}
