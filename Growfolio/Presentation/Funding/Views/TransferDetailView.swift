//
//  TransferDetailView.swift
//  Growfolio
//
//  View displaying detailed information about a single transfer.
//

import SwiftUI

struct TransferDetailView: View {

    // MARK: - Properties

    let transfer: Transfer
    @Bindable var viewModel: FundingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showCancelConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Header Section
                headerSection

                // Amount Details
                amountSection

                // FX Information
                if transfer.hasFXConversion {
                    fxSection
                }

                // Timeline Section
                timelineSection

                // Additional Details
                detailsSection

                // Actions
                if transfer.canCancel {
                    actionsSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Transfer Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Cancel Transfer",
                isPresented: $showCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Cancel Transfer", role: .destructive) {
                    cancelTransfer()
                }
                Button("Keep Transfer", role: .cancel) {}
            } message: {
                Text("Are you sure you want to cancel this transfer? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Section {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: transfer.type.colorHex).opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: transfer.type.iconName)
                        .font(.system(size: 36))
                        .foregroundStyle(Color(hex: transfer.type.colorHex))
                }

                // Type
                Text(transfer.displayDescription)
                    .font(.title2)
                    .fontWeight(.bold)

                // Amount
                Text(transfer.amountDisplayString)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(transfer.type == .deposit ? Color.positive : .primary)

                // Status Badge
                TransferStatusBadge(status: transfer.status)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        Section("Amount") {
            DetailRow(
                label: "Amount (\(transfer.currency))",
                value: transfer.amount.currencyString(code: transfer.currency)
            )

            if let amountUSD = transfer.amountUSD {
                DetailRow(
                    label: "Amount (USD)",
                    value: amountUSD.currencyString(code: "USD")
                )
            }

            if transfer.fees > 0 {
                DetailRow(
                    label: "Fees",
                    value: transfer.fees.currencyString(code: transfer.currency)
                )

                DetailRow(
                    label: "Net Amount",
                    value: transfer.netAmount.currencyString(code: transfer.currency),
                    isHighlighted: true
                )
            }
        }
    }

    // MARK: - FX Section

    private var fxSection: some View {
        Section("Currency Conversion") {
            if let rate = transfer.fxRate {
                DetailRow(
                    label: "Exchange Rate",
                    value: "1 \(transfer.currency) = \(rate.rounded(places: 4)) USD"
                )
            }

            DetailRow(
                label: "Source Currency",
                value: transfer.currency
            )

            DetailRow(
                label: "Target Currency",
                value: "USD"
            )
        }
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        Section("Timeline") {
            // Initiated
            TimelineRow(
                icon: "clock.fill",
                iconColor: Color.trustBlue,
                label: "Initiated",
                date: transfer.initiatedAt,
                isCompleted: true
            )

            // Processing
            if transfer.status == .processing || transfer.status == .completed {
                TimelineRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: Color.prosperityGold,
                    label: "Processing",
                    date: nil,
                    isCompleted: transfer.status == .completed
                )
            }

            // Completed/Failed
            if transfer.status == .completed, let completedAt = transfer.completedAt {
                TimelineRow(
                    icon: "checkmark.circle.fill",
                    iconColor: Color.growthGreen,
                    label: "Completed",
                    date: completedAt,
                    isCompleted: true
                )
            } else if transfer.status == .failed {
                TimelineRow(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: Color.negative,
                    label: "Failed",
                    date: transfer.updatedAt,
                    isCompleted: true
                )
            } else if transfer.status == .cancelled {
                TimelineRow(
                    icon: "xmark.circle.fill",
                    iconColor: .gray,
                    label: "Cancelled",
                    date: transfer.updatedAt,
                    isCompleted: true
                )
            }

            // Expected Completion
            if transfer.status.isInProgress, let expectedDate = transfer.expectedCompletionDate {
                TimelineRow(
                    icon: "calendar",
                    iconColor: .secondary,
                    label: "Expected Completion",
                    date: expectedDate,
                    isCompleted: false
                )
            }
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        Section("Details") {
            // Reference Number
            if let reference = transfer.referenceNumber {
                DetailRow(label: "Reference", value: reference, canCopy: true)
            }

            // Transfer ID
            DetailRow(label: "Transfer ID", value: String(transfer.id.prefix(8)) + "...", canCopy: true, fullValue: transfer.id)

            // Notes
            if let notes = transfer.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.subheadline)
                }
            }

            // Failure Reason
            if let failureReason = transfer.failureReason {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Failure Reason")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(failureReason)
                        .font(.subheadline)
                        .foregroundStyle(Color.negative)
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section {
            Button(role: .destructive) {
                showCancelConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Label("Cancel Transfer", systemImage: "xmark.circle")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Actions

    private func cancelTransfer() {
        Task {
            do {
                try await viewModel.cancelTransfer(transfer)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    var isHighlighted: Bool = false
    var canCopy: Bool = false
    var fullValue: String? = nil

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            if canCopy {
                Button {
                    UIPasteboard.general.string = fullValue ?? value
                } label: {
                    HStack(spacing: 4) {
                        Text(value)
                            .font(isHighlighted ? .subheadline.weight(.semibold) : .subheadline)
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(isHighlighted ? .primary : .secondary)
            } else {
                Text(value)
                    .font(isHighlighted ? .subheadline.weight(.semibold) : .subheadline)
                    .foregroundStyle(isHighlighted ? .primary : .secondary)
            }
        }
    }
}

// MARK: - Timeline Row

struct TimelineRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let date: Date?
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(isCompleted ? 0.2 : 0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isCompleted ? iconColor : iconColor.opacity(0.5))
            }

            // Label
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isCompleted ? .medium : .regular)
                    .foregroundStyle(isCompleted ? .primary : .secondary)

                if let date = date {
                    Text(date.displayDateTimeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Status
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(Color.positive)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TransferDetailView(
        transfer: Transfer(
            userId: "user1",
            portfolioId: "portfolio1",
            type: .deposit,
            status: .completed,
            amount: 1000,
            currency: "GBP",
            amountUSD: 1250,
            fxRate: 1.25,
            completedAt: Date()
        ),
        viewModel: FundingViewModel()
    )
}
