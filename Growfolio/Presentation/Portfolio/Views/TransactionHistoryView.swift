//
//  TransactionHistoryView.swift
//  Growfolio
//
//  View showing transaction history.
//

import SwiftUI

struct TransactionHistoryView: View {

    // MARK: - Properties

    let transactions: [LedgerEntry]

    @Environment(\.dismiss) private var dismiss

    @State private var filterType: LedgerEntryType?
    @State private var searchText: String = ""

    // MARK: - Computed Properties

    private var filteredTransactions: [LedgerEntry] {
        var result = transactions

        if let filter = filterType {
            result = result.filter { $0.type == filter }
        }

        if !searchText.isEmpty {
            result = result.filter { transaction in
                transaction.stockSymbol?.lowercased().contains(searchText.lowercased()) == true ||
                transaction.displayDescription.lowercased().contains(searchText.lowercased())
            }
        }

        return result
    }

    private var groupedTransactions: [TransactionGroup] {
        filteredTransactions.groupedByDate()
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    emptyState
                } else {
                    transactionsList
                }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All Types") {
                            filterType = nil
                        }
                        Divider()
                        ForEach(LedgerEntryType.allCases, id: \.self) { type in
                            Button {
                                filterType = type
                            } label: {
                                HStack {
                                    Image(systemName: type.iconName)
                                    Text(type.displayName)
                                    if filterType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search transactions")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Transactions", systemImage: "list.bullet.rectangle")
        } description: {
            Text("Your transaction history will appear here.")
        }
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        List {
            ForEach(groupedTransactions) { group in
                Section(group.title) {
                    ForEach(group.entries) { transaction in
                        TransactionDetailRow(transaction: transaction)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Transaction Detail Row

struct TransactionDetailRow: View {
    let transaction: LedgerEntry

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.type.colorHex).opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.type.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: transaction.type.colorHex))
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(transaction.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())

                    Text(transaction.transactionDate.displayString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.signPrefix)\(transaction.totalAmount.currencyString)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(amountColor)

                if transaction.fees > 0 {
                    Text("Fee: \(transaction.fees.currencyString)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var amountColor: Color {
        switch transaction.type {
        case .sell, .deposit, .dividend, .interest:
            return Color.positive
        case .buy, .withdrawal, .fee:
            return .primary
        case .transfer, .adjustment:
            return transaction.totalAmount >= 0 ? Color.positive : Color.negative
        }
    }
}

// MARK: - Preview

#Preview {
    TransactionHistoryView(
        transactions: [
            LedgerEntry(
                portfolioId: "1",
                userId: "user1",
                type: .buy,
                stockSymbol: "AAPL",
                quantity: 10,
                pricePerShare: 150,
                totalAmount: 1500,
                transactionDate: Date().adding(days: -1)
            ),
            LedgerEntry(
                portfolioId: "1",
                userId: "user1",
                type: .dividend,
                stockSymbol: "AAPL",
                totalAmount: 25,
                transactionDate: Date().adding(days: -5)
            ),
            LedgerEntry(
                portfolioId: "1",
                userId: "user1",
                type: .deposit,
                totalAmount: 5000,
                transactionDate: Date().adding(days: -10)
            )
        ]
    )
}
