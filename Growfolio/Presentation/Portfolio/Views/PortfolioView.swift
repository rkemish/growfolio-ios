//
//  PortfolioView.swift
//  Growfolio
//
//  Main portfolio view showing holdings and performance.
//

import SwiftUI

struct PortfolioView: View {

    // MARK: - Properties

    @State private var viewModel = PortfolioViewModel()
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
                portfolioMainContent
            } else {
                NavigationStack {
                    portfolioMainContent
                }
            }
        }
    }

    private var portfolioMainContent: some View {
        ZStack {
            if viewModel.isLoading && viewModel.holdings.isEmpty {
                loadingView
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                portfolioContentView
            }
        }
        .navigationTitle("Portfolio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.showAddTransaction = true
                    } label: {
                        Label("Record Trade", systemImage: "plus.circle")
                    }

                    Button {
                        Task {
                            await viewModel.refreshPrices()
                        }
                    } label: {
                        Label("Refresh Prices", systemImage: "arrow.clockwise")
                    }

                    Divider()

                    Button {
                        viewModel.showTransactionHistory = true
                    } label: {
                        Label("Transaction History", systemImage: "list.bullet.rectangle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            await viewModel.refreshPortfolioData()
        }
        .task {
            await viewModel.loadPortfolioData()
        }
        .sheet(isPresented: Binding(
            get: { navState == nil && viewModel.showHoldingDetail },
            set: { viewModel.showHoldingDetail = $0 }
        )) {
            if let holding = viewModel.selectedHolding {
                HoldingDetailView(holding: holding)
            }
        }
        .sheet(isPresented: $viewModel.showTransactionHistory) {
            TransactionHistoryView(transactions: viewModel.transactions)
        }
        .sheet(isPresented: $viewModel.showAddTransaction) {
            AddTransactionView(
                onSave: { type, symbol, qty, price, amount, notes in
                    Task {
                        try? await viewModel.addTransaction(
                            type: type,
                            stockSymbol: symbol,
                            quantity: qty,
                            pricePerShare: price,
                            totalAmount: amount,
                            notes: notes
                        )
                        viewModel.showAddTransaction = false
                    }
                },
                onCancel: {
                    viewModel.showAddTransaction = false
                }
            )
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading portfolio...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Holdings", systemImage: "chart.pie")
        } description: {
            Text("Your portfolio is empty. Start investing to see your holdings here.")
        } actions: {
            Button {
                viewModel.showAddTransaction = true
            } label: {
                Text("Record Trade")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Portfolio Content

    private var portfolioContentView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Summary Card
                summaryCard

                // Period Selector
                periodSelector

                // Holdings Section
                holdingsSection

                // Allocation Section
                allocationSection

                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 16) {
            // Total Value
            VStack(spacing: 4) {
                Text("Total Value")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.totalValue.currencyString)
                    .font(.system(size: 36, weight: .bold))
            }

            // Return
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("Total Return")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isProfitable ? "arrow.up.right" : "arrow.down.right")
                        Text(viewModel.totalReturn.currencyString)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.isProfitable ? Color.positive : Color.negative)
                }

                VStack(spacing: 4) {
                    Text("Return %")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(viewModel.isProfitable ? "+" : "")\(viewModel.totalReturnPercentage.rounded(places: 2))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.isProfitable ? Color.positive : Color.negative)
                }

                VStack(spacing: 4) {
                    Text("Cash")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(viewModel.cashBalance.currencyString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PerformancePeriod.allCases, id: \.self) { period in
                    periodButton(for: period)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func periodButton(for period: PerformancePeriod) -> some View {
        let isSelected = viewModel.selectedPeriod == period
        return Button {
            viewModel.selectedPeriod = period
        } label: {
            Text(period.displayName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.trustBlue : Color(.systemGray5))
                .foregroundColor(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Holdings Section

    private var holdingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Holdings")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.holdings.count) positions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(viewModel.sortedHoldings) { holding in
                HoldingRow(holding: holding, totalValue: viewModel.totalValue)
                    .onTapGesture {
                        if let navState = navState {
                            // iPad: Update navigation state
                            navState.selectedHolding = holding
                        } else {
                            // iPhone: Show sheet
                            viewModel.selectHolding(holding)
                        }
                    }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Allocation Section

    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allocation")
                .font(.headline)

            if viewModel.allocationByHolding.isEmpty {
                Text("No allocation data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                // Simple bar chart representation
                ForEach(viewModel.allocationByHolding.prefix(5)) { item in
                    HStack {
                        Text(item.category)
                            .font(.subheadline)
                            .frame(width: 60, alignment: .leading)

                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: item.colorHex))
                                .frame(width: geometry.size.width * CGFloat(truncating: item.percentage as NSNumber) / 100)
                        }
                        .frame(height: 20)

                        Text("\(item.percentage.rounded(places: 1))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)

                Spacer()

                Button("View All") {
                    viewModel.showTransactionHistory = true
                }
                .font(.subheadline)
            }

            if viewModel.recentTransactions.isEmpty {
                Text("No recent transactions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentTransactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Holding Row

struct HoldingRow: View {
    let holding: Holding
    let totalValue: Decimal

    var weight: Decimal {
        holding.portfolioWeight(totalValue: totalValue)
    }

    var body: some View {
        HStack {
            // Symbol and Name
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.stockSymbol)
                    .font(.headline)

                if let name = holding.stockName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Shares
            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.quantity.sharesString)
                    .font(.subheadline)

                Text("shares")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Value and P&L
            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.marketValue.currencyString)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 2) {
                    Image(systemName: holding.isProfitable ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)

                    Text("\(holding.unrealizedGainLossPercentage.rounded(places: 1))%")
                        .font(.caption)
                }
                .foregroundStyle(holding.isProfitable ? Color.positive : Color.negative)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: LedgerEntry

    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.type.colorHex).opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: transaction.type.iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: transaction.type.colorHex))
            }

            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.displayDescription)
                    .font(.subheadline)

                Text(transaction.transactionDate.relativeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount
            Text("\(transaction.signPrefix)\(transaction.totalAmount.currencyString)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(
                    transaction.type == .sell || transaction.type == .deposit || transaction.type == .dividend
                        ? Color.positive
                        : .primary
                )
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    PortfolioView()
}
