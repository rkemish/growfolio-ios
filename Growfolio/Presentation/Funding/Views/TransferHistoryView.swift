//
//  TransferHistoryView.swift
//  Growfolio
//
//  View displaying the history of deposits and withdrawals.
//

import SwiftUI

struct TransferHistoryView: View {

    // MARK: - Properties

    @Bindable var viewModel: FundingViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.transfers.isEmpty {
                    loadingView
                } else if viewModel.filteredTransfers.isEmpty {
                    emptyStateView
                } else {
                    transferListView
                }
            }
            .navigationTitle("Transfer History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    filterMenu
                }
            }
            .refreshable {
                await viewModel.refreshFundingData()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading transfers...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(emptyStateTitle, systemImage: emptyStateIcon)
        } description: {
            Text(emptyStateDescription)
        } actions: {
            if hasActiveFilters {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var emptyStateTitle: String {
        if hasActiveFilters {
            return "No Matching Transfers"
        }
        return "No Transfers Yet"
    }

    private var emptyStateIcon: String {
        if hasActiveFilters {
            return "line.3.horizontal.decrease.circle"
        }
        return "arrow.up.arrow.down.circle"
    }

    private var emptyStateDescription: String {
        if hasActiveFilters {
            return "No transfers match your current filters. Try adjusting your filter criteria."
        }
        return "Your transfer history will appear here once you make your first deposit or withdrawal."
    }

    private var hasActiveFilters: Bool {
        viewModel.filterType != nil || viewModel.filterStatus != nil
    }

    // MARK: - Transfer List

    private var transferListView: some View {
        List {
            // Summary Section
            if let history = viewModel.transferHistory {
                summarySection(history: history)
            }

            // Transfers grouped by date
            ForEach(viewModel.groupedTransfers) { group in
                Section(group.title) {
                    ForEach(group.transfers) { transfer in
                        TransferHistoryRow(transfer: transfer)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectTransfer(transfer)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $viewModel.showTransferDetail) {
            if let transfer = viewModel.selectedTransfer {
                TransferDetailView(transfer: transfer, viewModel: viewModel)
            }
        }
    }

    // MARK: - Summary Section

    private func summarySection(history: TransferHistory) -> some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Deposits")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(history.totalDeposits.currencyString(code: "GBP"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.positive)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Total Withdrawals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(history.totalWithdrawals.currencyString(code: "GBP"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.prosperityGold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Net")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(history.netTransfers.currencyString(code: "GBP"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(history.netTransfers >= 0 ? Color.positive : Color.negative)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Summary")
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            // Type Filter
            Menu {
                Button {
                    viewModel.setFilter(type: nil)
                } label: {
                    HStack {
                        Text("All Types")
                        if viewModel.filterType == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                ForEach(TransferType.allCases, id: \.self) { type in
                    Button {
                        viewModel.setFilter(type: type)
                    } label: {
                        HStack {
                            Label(type.displayName, systemImage: type.iconName)
                            if viewModel.filterType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label(
                    viewModel.filterType?.displayName ?? "Type",
                    systemImage: "arrow.up.arrow.down"
                )
            }

            // Status Filter
            Menu {
                Button {
                    viewModel.setFilter(status: nil)
                } label: {
                    HStack {
                        Text("All Statuses")
                        if viewModel.filterStatus == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                ForEach(TransferStatus.allCases, id: \.self) { status in
                    Button {
                        viewModel.setFilter(status: status)
                    } label: {
                        HStack {
                            Label(status.displayName, systemImage: status.iconName)
                            if viewModel.filterStatus == status {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label(
                    viewModel.filterStatus?.displayName ?? "Status",
                    systemImage: "line.3.horizontal.decrease.circle"
                )
            }

            // Clear Filters
            if hasActiveFilters {
                Divider()

                Button(role: .destructive) {
                    viewModel.clearFilters()
                } label: {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
            }
        } label: {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(hasActiveFilters ? Color.trustBlue : .primary)
        }
    }
}

// MARK: - Transfer History Row

struct TransferHistoryRow: View {
    let transfer: Transfer

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: transfer.type.colorHex).opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: transfer.type.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: transfer.type.colorHex))
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transfer.displayDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text(transfer.amountDisplayString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(transfer.type == .deposit ? Color.positive : .primary)
                }

                HStack {
                    Text(transfer.initiatedAt.displayString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    TransferStatusBadge(status: transfer.status)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    TransferHistoryView(viewModel: FundingViewModel())
}
