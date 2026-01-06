//
//  FundingView.swift
//  Growfolio
//
//  Main funding view showing balance and action buttons.
//

import SwiftUI

struct FundingView: View {

    // MARK: - Properties

    @State private var viewModel = FundingViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.balance == nil {
                    loadingView
                } else {
                    fundingContentView
                }
            }
            .navigationTitle("Funding")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.presentTransferHistory()
                        } label: {
                            Label("Transfer History", systemImage: "list.bullet.rectangle")
                        }

                        Button {
                            Task {
                                await viewModel.refreshFXRate()
                            }
                        } label: {
                            Label("Refresh FX Rate", systemImage: "arrow.triangle.2.circlepath")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshFundingData()
            }
            .task {
                await viewModel.loadFundingData()
            }
            .sheet(isPresented: $viewModel.showDeposit) {
                DepositView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showWithdrawal) {
                WithdrawalView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showTransferHistory) {
                TransferHistoryView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showTransferDetail) {
                if let transfer = viewModel.selectedTransfer {
                    TransferDetailView(transfer: transfer, viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading funding data...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Content View

    private var fundingContentView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Balance Card
                balanceCard

                // FX Rate Card
                fxRateCard

                // Action Buttons
                actionButtons

                // Pending Transfers
                if !viewModel.pendingTransfers.isEmpty {
                    pendingTransfersSection
                }

                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 16) {
            // GBP Balance
            VStack(spacing: 4) {
                Text("Available Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.availableBalanceGBP.currencyString(code: "GBP"))
                    .font(.system(size: 36, weight: .bold))
            }

            Divider()

            // USD Equivalent and Pending
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("USD Equivalent")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(viewModel.availableBalanceUSD.currencyString(code: "USD"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                if viewModel.hasPendingBalance {
                    VStack(spacing: 4) {
                        Text("Pending")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("Processing")
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.prosperityGold)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - FX Rate Card

    private var fxRateCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("GBP/USD Exchange Rate")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.fxRateDisplayString)
                    .font(.headline)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if viewModel.isFXRateValid {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.positive)
                        Text("Live")
                            .font(.caption)
                            .foregroundStyle(Color.positive)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.prosperityGold)
                        Text("Expired")
                            .font(.caption)
                            .foregroundStyle(Color.prosperityGold)
                    }
                }

                Button {
                    Task {
                        await viewModel.refreshFXRate()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Deposit Button
            Button {
                viewModel.presentDeposit()
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 56, height: 56)

                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.positive)
                    }

                    Text("Deposit")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            // Withdraw Button
            Button {
                viewModel.presentWithdrawal()
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 56, height: 56)

                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.prosperityGold)
                    }

                    Text("Withdraw")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Pending Transfers Section

    private var pendingTransfersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pending Transfers")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.pendingTransfers.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }

            ForEach(viewModel.pendingTransfers) { transfer in
                TransferRow(transfer: transfer)
                    .onTapGesture {
                        viewModel.selectTransfer(transfer)
                    }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)

                Spacer()

                Button("View All") {
                    viewModel.presentTransferHistory()
                }
                .font(.subheadline)
            }

            if viewModel.recentTransfers.isEmpty {
                Text("No recent transfers")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentTransfers) { transfer in
                    TransferRow(transfer: transfer)
                        .onTapGesture {
                            viewModel.selectTransfer(transfer)
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Transfer Row

struct TransferRow: View {
    let transfer: Transfer

    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: transfer.type.colorHex).opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: transfer.type.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: transfer.type.colorHex))
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(transfer.displayDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(transfer.initiatedAt.relativeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("*")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TransferStatusBadge(status: transfer.status)
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(transfer.amountDisplayString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(transfer.type == .deposit ? Color.positive : .primary)

                if let usdAmount = transfer.amountUSDDisplayString {
                    Text(usdAmount)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Transfer Status Badge

struct TransferStatusBadge: View {
    let status: TransferStatus

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: status.iconName)
                .font(.system(size: 8))

            Text(status.displayName)
                .font(.caption2)
        }
        .foregroundStyle(Color(hex: status.colorHex))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(hex: status.colorHex).opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    FundingView()
}
