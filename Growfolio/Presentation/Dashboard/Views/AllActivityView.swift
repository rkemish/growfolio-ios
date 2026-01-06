//
//  AllActivityView.swift
//  Growfolio
//
//  View showing all transaction activity.
//

import SwiftUI

struct AllActivityView: View {

    // MARK: - Properties

    @State private var viewModel = AllActivityViewModel()
    @State private var filterType: LedgerEntryType?
    @State private var searchText: String = ""

    // MARK: - Computed Properties

    private var filteredTransactions: [LedgerEntry] {
        var result = viewModel.transactions

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

    private var groupedTransactions: [ActivityGroup] {
        filteredTransactions.groupedByActivityDate()
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.transactions.isEmpty {
                ProgressView("Loading transactions...")
            } else if viewModel.transactions.isEmpty {
                emptyState
            } else {
                transactionsList
            }
        }
        .navigationTitle("All Activity")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search transactions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                filterMenu
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadTransactions()
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView(
            "No Transactions",
            systemImage: "clock",
            description: Text("Your investment activity will appear here")
        )
    }

    private var transactionsList: some View {
        List {
            ForEach(groupedTransactions) { group in
                Section {
                    ForEach(group.transactions) { transaction in
                        AllActivityRow(entry: transaction)
                    }
                } header: {
                    Text(group.dateString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var filterMenu: some View {
        Menu {
            Button {
                filterType = nil
            } label: {
                Label("All Types", systemImage: filterType == nil ? "checkmark" : "")
            }

            Divider()

            ForEach(LedgerEntryType.allCases, id: \.self) { type in
                Button {
                    filterType = type
                } label: {
                    Label(type.displayName, systemImage: filterType == type ? "checkmark" : "")
                }
            }
        } label: {
            Image(systemName: filterType == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }
}

// MARK: - Activity Row

struct AllActivityRow: View {
    let entry: LedgerEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.type.iconName)
                .foregroundStyle(Color(hex: entry.type.colorHex) ?? .accentColor)
                .font(.title3)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayDescription)
                    .font(.body)

                HStack(spacing: 8) {
                    Text(entry.transactionDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let symbol = entry.stockSymbol {
                        Text(symbol)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.signPrefix)\(entry.totalAmount.currencyString)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(entry.isCredit ? Color.positive : .primary)

                if let quantity = entry.quantity, quantity > 0 {
                    Text("\(quantity.formatted()) shares")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View Model

@Observable
final class AllActivityViewModel: @unchecked Sendable {

    var transactions: [LedgerEntry] = []
    var isLoading = false
    var error: Error?

    private let repository: PortfolioRepositoryProtocol

    init(repository: PortfolioRepositoryProtocol = RepositoryContainer.portfolioRepository) {
        self.repository = repository
    }

    @MainActor
    func loadTransactions() async {
        guard transactions.isEmpty else { return }
        isLoading = true

        do {
            // Get default portfolio
            if let portfolio = try await repository.fetchDefaultPortfolio() {
                let response = try await repository.fetchLedgerEntries(for: portfolio.id, page: 1, limit: 100)
                transactions = response.data
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func refresh() async {
        isLoading = true

        do {
            if let portfolio = try await repository.fetchDefaultPortfolio() {
                let response = try await repository.fetchLedgerEntries(for: portfolio.id, page: 1, limit: 100)
                transactions = response.data
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

// MARK: - Activity Grouping (local to this view)

private struct ActivityGroup: Identifiable {
    let id = UUID()
    let date: Date
    let transactions: [LedgerEntry]

    var dateString: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

private extension Array where Element == LedgerEntry {
    func groupedByActivityDate() -> [ActivityGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: self) { entry in
            calendar.startOfDay(for: entry.transactionDate)
        }

        return grouped.map { ActivityGroup(date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }
}

// MARK: - LedgerEntry Extensions (local to this view)

private extension LedgerEntry {
    var isCredit: Bool {
        type == .deposit || type == .sell || type == .dividend
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AllActivityView()
    }
}
