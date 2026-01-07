//
//  BasketCard.swift
//  Growfolio
//
//  Card component for displaying a basket in the list.
//

import SwiftUI

struct BasketCard: View {
    let basket: Basket

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Icon
                if let icon = basket.icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(Color(hex: basket.color ?? "#007AFF"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(basket.name)
                        .font(.headline)

                    if let category = basket.category {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Status badge
                statusBadge
            }

            Divider()

            // Performance Summary
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(basket.summary.currentValue.currencyString)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Gain/Loss")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(basket.summary.totalGainLoss.currencyString)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(gainLossColor)
                }

                Spacer()

                // Return percentage
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Return")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(basket.summary.returnPercentage.rawPercentString)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(gainLossColor)
                }
            }

            // Allocations count
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(basket.allocations.count) stocks")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if basket.dcaEnabled {
                    Spacer()
                    Image(systemName: "repeat.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("DCA Enabled")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: basket.status.iconName)
                .font(.caption2)
            Text(basket.status.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: basket.status.colorHex).opacity(0.1))
        .foregroundStyle(Color(hex: basket.status.colorHex))
        .clipShape(Capsule())
    }

    private var gainLossColor: Color {
        basket.summary.totalGainLoss >= 0 ? .green : .red
    }
}

// MARK: - Preview

#Preview {
    BasketCard(basket: Basket(
        userId: "user1",
        name: "Tech Giants",
        description: "Major technology companies",
        category: "Technology",
        icon: "laptopcomputer",
        color: "#007AFF",
        allocations: [
            BasketAllocation(symbol: "AAPL", name: "Apple Inc.", percentage: 40, targetShares: nil),
            BasketAllocation(symbol: "MSFT", name: "Microsoft", percentage: 30, targetShares: nil),
            BasketAllocation(symbol: "GOOGL", name: "Alphabet", percentage: 30, targetShares: nil)
        ],
        dcaEnabled: true,
        status: .active,
        summary: BasketSummary(
            currentValue: 15678.50,
            totalInvested: 12000,
            totalGainLoss: 3678.50
        )
    ))
    .padding()
}
