//
//  StockInfoCard.swift
//  Growfolio
//
//  Company information section displaying key stock metrics.
//

import SwiftUI

struct StockInfoCard: View {

    // MARK: - Properties

    let marketCap: String?
    let peRatio: String?
    let dividendYield: String?
    let volume: String?
    let dayRange: String?
    let weekRange52: String?
    let sector: String?
    let industry: String?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Statistics")
                .font(.headline)

            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let marketCap = marketCap {
                    StatItem(label: "Market Cap", value: marketCap, icon: "building.2")
                }

                if let peRatio = peRatio {
                    StatItem(label: "P/E Ratio", value: peRatio, icon: "percent")
                }

                if let dividendYield = dividendYield {
                    StatItem(label: "Dividend Yield", value: dividendYield, icon: "dollarsign.arrow.circlepath")
                }

                if let volume = volume {
                    StatItem(label: "Volume", value: volume, icon: "chart.bar")
                }
            }

            // Ranges
            if dayRange != nil || weekRange52 != nil {
                Divider()

                VStack(spacing: 12) {
                    if let dayRange = dayRange {
                        RangeItem(label: "Day Range", range: dayRange)
                    }

                    if let weekRange52 = weekRange52 {
                        RangeItem(label: "52 Week Range", range: weekRange52)
                    }
                }
            }

            // Sector & Industry
            if sector != nil || industry != nil {
                Divider()

                VStack(spacing: 8) {
                    if let sector = sector {
                        HStack {
                            Text("Sector")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(sector)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }

                    if let industry = industry {
                        HStack {
                            Text("Industry")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(industry)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .glassCard(material: .regular, cornerRadius: Constants.UI.glassCornerRadius)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.trustBlue)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Range Item

struct RangeItem: View {
    let label: String
    let range: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(range)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Detailed Stock Info Card

struct DetailedStockInfoCard: View {
    let stock: Stock

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Price Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Price Information")
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        Text("Open")
                            .foregroundStyle(.secondary)
                        Text(stock.openPrice?.currencyString ?? "--")
                            .fontWeight(.medium)
                    }
                    GridRow {
                        Text("Previous Close")
                            .foregroundStyle(.secondary)
                        Text(stock.previousClose?.currencyString ?? "--")
                            .fontWeight(.medium)
                    }
                    GridRow {
                        Text("Day High")
                            .foregroundStyle(.secondary)
                        Text(stock.dayHigh?.currencyString ?? "--")
                            .fontWeight(.medium)
                    }
                    GridRow {
                        Text("Day Low")
                            .foregroundStyle(.secondary)
                        Text(stock.dayLow?.currencyString ?? "--")
                            .fontWeight(.medium)
                    }
                }
                .font(.subheadline)
            }

            Divider()

            // Fundamentals Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Fundamentals")
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    if let marketCap = stock.formattedMarketCap {
                        GridRow {
                            Text("Market Cap")
                                .foregroundStyle(.secondary)
                            Text(marketCap)
                                .fontWeight(.medium)
                        }
                    }
                    if let pe = stock.peRatio {
                        GridRow {
                            Text("P/E Ratio")
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", NSDecimalNumber(decimal: pe).doubleValue))
                                .fontWeight(.medium)
                        }
                    }
                    if let eps = stock.eps {
                        GridRow {
                            Text("EPS")
                                .foregroundStyle(.secondary)
                            Text(eps.currencyString)
                                .fontWeight(.medium)
                        }
                    }
                    if let beta = stock.beta {
                        GridRow {
                            Text("Beta")
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.2f", NSDecimalNumber(decimal: beta).doubleValue))
                                .fontWeight(.medium)
                        }
                    }
                    if stock.paysDividends, let yield = stock.dividendYield {
                        GridRow {
                            Text("Dividend Yield")
                                .foregroundStyle(.secondary)
                            Text("\(yield.rounded(places: 2))%")
                                .fontWeight(.medium)
                        }
                    }
                }
                .font(.subheadline)
            }

            Divider()

            // Trading Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Trading Information")
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    if let volume = stock.formattedVolume {
                        GridRow {
                            Text("Volume")
                                .foregroundStyle(.secondary)
                            Text(volume)
                                .fontWeight(.medium)
                        }
                    }
                    if let avgVolume = stock.averageVolume {
                        GridRow {
                            Text("Avg Volume")
                                .foregroundStyle(.secondary)
                            Text(formatLargeNumber(avgVolume))
                                .fontWeight(.medium)
                        }
                    }
                    if let dayRange = stock.dayRange {
                        GridRow {
                            Text("Day Range")
                                .foregroundStyle(.secondary)
                            Text(dayRange)
                                .fontWeight(.medium)
                        }
                    }
                    if let weekRange = stock.weekRange52 {
                        GridRow {
                            Text("52 Week Range")
                                .foregroundStyle(.secondary)
                            Text(weekRange)
                                .fontWeight(.medium)
                        }
                    }
                }
                .font(.subheadline)
            }
        }
        .padding()
        .glassCard(material: .regular, cornerRadius: Constants.UI.glassCornerRadius)
    }

    private func formatLargeNumber(_ number: Int) -> String {
        let absNumber = abs(number)
        if absNumber >= 1_000_000_000 {
            return String(format: "%.2fB", Double(absNumber) / 1_000_000_000)
        } else if absNumber >= 1_000_000 {
            return String(format: "%.2fM", Double(absNumber) / 1_000_000)
        } else if absNumber >= 1_000 {
            return String(format: "%.2fK", Double(absNumber) / 1_000)
        }
        return "\(absNumber)"
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            StockInfoCard(
                marketCap: "$2.89T",
                peRatio: "28.5",
                dividendYield: "0.51%",
                volume: "52.4M",
                dayRange: "$183.80 - $186.50",
                weekRange52: "$124.17 - $199.62",
                sector: "Technology",
                industry: "Consumer Electronics"
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
