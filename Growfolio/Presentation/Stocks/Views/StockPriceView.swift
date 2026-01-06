//
//  StockPriceView.swift
//  Growfolio
//
//  Price display component with change indicator.
//

import SwiftUI

struct StockPriceView: View {

    // MARK: - Properties

    let price: String
    let change: String
    let changePercent: String
    let isPriceUp: Bool
    let companyName: String
    let exchange: String?
    var isLoading: Bool = false
    var marketHours: MarketHours?

    private var changeColor: Color {
        isPriceUp ? Color.positive : Color.negative
    }

    private var changeIcon: String {
        isPriceUp ? "arrow.up.right" : "arrow.down.right"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Company Info
            VStack(spacing: 4) {
                Text(companyName)
                    .font(.title3)
                    .fontWeight(.semibold)

                if let exchange = exchange {
                    Text(exchange)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Price Display
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }

                    Text(price)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }

                // Change Indicator
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: changeIcon)
                            .font(.caption)

                        Text(change)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(changeColor)

                    Text("(\(changePercent))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(changeColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(changeColor.opacity(0.1))
                .clipShape(Capsule())
            }

            // Market Status
            InlineMarketStatus(marketHours: marketHours)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Compact Price View

struct CompactStockPriceView: View {
    let symbol: String
    let price: String
    let change: String
    let changePercent: String
    let isPriceUp: Bool

    private var changeColor: Color {
        isPriceUp ? Color.positive : Color.negative
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(symbol)
                    .font(.headline)

                Text(price)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(change)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(changeColor)

                Text(changePercent)
                    .font(.caption)
                    .foregroundStyle(changeColor)
            }
        }
    }
}

// MARK: - Large Price Badge

struct LargePriceBadge: View {
    let price: Decimal
    let change: Decimal
    let changePercent: Decimal
    var size: CGFloat = 100

    private var isPriceUp: Bool {
        change >= 0
    }

    private var changeColor: Color {
        isPriceUp ? Color.positive : Color.negative
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(changeColor.opacity(0.1))
                    .frame(width: size, height: size)

                VStack(spacing: 2) {
                    Text(price.currencyString)
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    HStack(spacing: 2) {
                        Image(systemName: isPriceUp ? "arrow.up" : "arrow.down")
                            .font(.system(size: size * 0.1))

                        Text("\(changePercent.rounded(places: 2))%")
                            .font(.system(size: size * 0.12, weight: .medium))
                    }
                    .foregroundStyle(changeColor)
                }
                .padding(8)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StockPriceView(
            price: "$185.92",
            change: "+$2.34",
            changePercent: "+1.27%",
            isPriceUp: true,
            companyName: "Apple Inc.",
            exchange: "NASDAQ",
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: true,
                session: .regular,
                nextClose: Date().addingTimeInterval(3600 * 4)
            )
        )

        StockPriceView(
            price: "$142.56",
            change: "-$3.21",
            changePercent: "-2.20%",
            isPriceUp: false,
            companyName: "Microsoft Corporation",
            exchange: "NASDAQ",
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: false,
                session: .closed,
                nextOpen: Date().addingTimeInterval(3600 * 12)
            )
        )

        CompactStockPriceView(
            symbol: "AAPL",
            price: "$185.92",
            change: "+$2.34",
            changePercent: "+1.27%",
            isPriceUp: true
        )
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))

        LargePriceBadge(
            price: 185.92,
            change: 2.34,
            changePercent: 1.27
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
