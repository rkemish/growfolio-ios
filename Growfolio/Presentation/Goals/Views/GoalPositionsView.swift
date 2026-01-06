//
//  GoalPositionsView.swift
//  Growfolio
//
//  Shows all fractional positions acquired through DCA for a goal.
//

import SwiftUI

struct GoalPositionsView: View {

    // MARK: - Properties

    let goal: Goal
    let positionsSummary: GoalPositionsSummary

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPosition: GoalPosition?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Header
                    summaryHeader

                    // Positions List
                    positionsList
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Positions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedPosition) { position in
                PositionPurchasesView(position: position, goalColor: goal.colorHex)
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: 16) {
            // Goal info
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: goal.colorHex).opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: goal.category.iconName)
                        .font(.title2)
                        .foregroundStyle(Color(hex: goal.colorHex))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.headline)
                    Text("\(positionsSummary.uniqueStocks) stocks • \(positionsSummary.totalPurchases) purchases")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            // Value stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(positionsSummary.totalCurrentValue.currencyString)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Cost Basis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(positionsSummary.totalCostBasis.currencyString)
                        .font(.headline)
                }
            }

            // Return stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Return")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: positionsSummary.isProfitable ? "arrow.up.right" : "arrow.down.right")
                        Text(positionsSummary.totalGain.currencyString)
                    }
                    .font(.headline)
                    .foregroundStyle(positionsSummary.isProfitable ? Color.positive : Color.negative)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Return %")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(positionsSummary.totalGainPercent.formatted(.number.precision(.fractionLength(2))))%")
                        .font(.headline)
                        .foregroundStyle(positionsSummary.isProfitable ? Color.positive : Color.negative)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Positions List

    private var positionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Holdings")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(positionsSummary.positions) { position in
                Button {
                    selectedPosition = position
                } label: {
                    positionRow(position: position)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func positionRow(position: GoalPosition) -> some View {
        VStack(spacing: 12) {
            HStack {
                // Stock info
                VStack(alignment: .leading, spacing: 2) {
                    Text(position.stockSymbol)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(position.stockName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Value
                VStack(alignment: .trailing, spacing: 2) {
                    Text(position.currentValue.currencyString)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: 2) {
                        Image(systemName: position.isProfitable ? "arrow.up.right" : "arrow.down.right")
                        Text("\(position.totalGain.currencyString)")
                    }
                    .font(.caption)
                    .foregroundStyle(position.isProfitable ? Color.positive : Color.negative)
                }
            }

            // Details row
            HStack {
                Label {
                    Text("\(position.totalShares.formatted(.number.precision(.fractionLength(4)))) shares")
                } icon: {
                    Image(systemName: "chart.pie")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                Text("Avg: \(position.averageCostPerShare.currencyString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text("\(position.purchases.count) purchases")
                    Image(systemName: "chevron.right")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Position Purchases View

struct PositionPurchasesView: View {

    let position: GoalPosition
    let goalColor: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Position Summary
                    positionSummary

                    // Purchases List
                    purchasesList
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(position.stockSymbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var positionSummary: some View {
        VStack(spacing: 16) {
            // Stock header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(position.stockSymbol)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(position.stockName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Current Price")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(position.currentPrice.currencyString)
                        .font(.headline)
                }
            }

            Divider()

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statItem(title: "Total Shares", value: position.totalShares.formatted(.number.precision(.fractionLength(4))))
                statItem(title: "Market Value", value: position.currentValue.currencyString)
                statItem(title: "Cost Basis", value: position.totalCostBasis.currencyString)
                statItem(title: "Avg Cost", value: position.averageCostPerShare.currencyString)
            }

            // Return
            HStack {
                Text("Total Return")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: position.isProfitable ? "arrow.up.right" : "arrow.down.right")
                    Text("\(position.totalGain.currencyString) (\(position.totalGainPercent.formatted(.number.precision(.fractionLength(2))))%)")
                }
                .font(.headline)
                .foregroundStyle(position.isProfitable ? Color.positive : Color.negative)
            }
            .padding()
            .background(Color(hex: goalColor).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var purchasesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Purchase History")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(position.purchases.sorted { $0.date > $1.date }) { purchase in
                purchaseRow(purchase: purchase)
            }
        }
    }

    private func purchaseRow(purchase: GoalPurchase) -> some View {
        HStack {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(purchase.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("DCA Purchase")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Shares
            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(purchase.shares.formatted(.number.precision(.fractionLength(4)))) shares")
                    .font(.subheadline)
                    .foregroundStyle(Color.positive)
                Text("@ \(purchase.pricePerShare.currencyString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount
            Text(purchase.totalAmount.currencyString)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    let purchases: [GoalPurchase] = [
        GoalPurchase(date: Date().addingTimeInterval(-86400 * 30), shares: 0.2541, pricePerShare: 196.52, totalAmount: 50, dcaScheduleId: "1"),
        GoalPurchase(date: Date().addingTimeInterval(-86400 * 60), shares: 0.2678, pricePerShare: 186.71, totalAmount: 50, dcaScheduleId: "1"),
        GoalPurchase(date: Date().addingTimeInterval(-86400 * 90), shares: 0.2832, pricePerShare: 176.55, totalAmount: 50, dcaScheduleId: "1"),
    ]

    let position = GoalPosition(
        id: "1",
        stockSymbol: "QQQ",
        stockName: "Invesco QQQ Trust",
        totalShares: 0.8051,
        totalCostBasis: 150,
        currentPrice: 198.45,
        purchases: purchases
    )

    let summary = GoalPositionsSummary(
        goalId: "goal1",
        positions: [position]
    )

    let goal = Goal(
        id: "goal1",
        userId: "user1",
        name: "College Fund",
        targetAmount: 50000,
        currentAmount: 12500,
        linkedDCAScheduleIds: ["dca1"],
        category: .education,
        colorHex: "#5856D6"
    )

    return GoalPositionsView(goal: goal, positionsSummary: summary)
}
