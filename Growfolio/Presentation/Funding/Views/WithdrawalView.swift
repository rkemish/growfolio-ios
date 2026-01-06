//
//  WithdrawalView.swift
//  Growfolio
//
//  View for initiating withdrawals with balance check and FX conversion.
//

import SwiftUI

struct WithdrawalView: View {

    // MARK: - Properties

    @Bindable var viewModel: FundingViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAmountFocused: Bool

    @State private var showConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var availableBalance: Decimal {
        viewModel.availableBalanceGBP
    }

    private var isOverBalance: Bool {
        guard let amount = viewModel.withdrawalAmountValue else { return false }
        return amount > availableBalance
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Available Balance Section
                availableBalanceSection

                // Amount Section
                amountSection

                // FX Conversion Section
                fxConversionSection

                // Notes Section
                notesSection

                // Summary Section
                if viewModel.canWithdraw {
                    summarySection
                }
            }
            .navigationTitle("Withdraw Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.dismissWithdrawal()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        initiateWithdrawal()
                    }
                    .disabled(!viewModel.canWithdraw || viewModel.isSubmitting)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isAmountFocused = false
                    }
                }
            }
            .alert("Confirm Withdrawal", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {
                    viewModel.resetWithdrawalForm()
                }
                Button("Confirm", role: .destructive) {
                    confirmWithdrawal()
                }
            } message: {
                Text(confirmationMessage)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if viewModel.isSubmitting {
                    submittingOverlay
                }
            }
        }
    }

    // MARK: - Available Balance Section

    private var availableBalanceSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Balance")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(availableBalance.currencyString(code: "GBP"))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                Button("Max") {
                    viewModel.setMaxWithdrawal()
                }
                .buttonStyle(.bordered)
                .tint(Color.trustBlue)
            }
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        Section {
            HStack {
                Text("GBP")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)

                TextField("0.00", text: $viewModel.withdrawalAmount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .semibold))
                    .multilineTextAlignment(.trailing)
                    .focused($isAmountFocused)
                    .foregroundStyle(isOverBalance ? Color.negative : .primary)
            }
            .padding(.vertical, 8)

            if isOverBalance {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.negative)
                    Text("Amount exceeds available balance")
                        .font(.caption)
                        .foregroundStyle(Color.negative)
                }
            }
        } header: {
            Text("Amount to Withdraw")
        } footer: {
            Text("Enter the amount in GBP you wish to withdraw from your account.")
        }
    }

    // MARK: - FX Conversion Section

    private var fxConversionSection: some View {
        Section {
            // Current Rate
            HStack {
                Text("Exchange Rate")
                Spacer()
                Text(viewModel.fxRateDisplayString)
                    .foregroundStyle(.secondary)
            }

            // Rate Status
            HStack {
                Text("Rate Status")
                Spacer()
                if viewModel.isFXRateValid {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.positive)
                        Text("Live")
                            .foregroundStyle(Color.positive)
                    }
                    .font(.subheadline)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.prosperityGold)
                        Text("Expired")
                            .foregroundStyle(Color.prosperityGold)
                    }
                    .font(.subheadline)
                }
            }

            // USD Equivalent
            if viewModel.withdrawalAmountValue != nil && !isOverBalance {
                HStack {
                    Text("USD Equivalent")
                    Spacer()
                    Text(viewModel.withdrawalConvertedUSD.currencyString(code: "USD"))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.prosperityGold)
                }
            }

            // Refresh Rate Button
            Button {
                Task {
                    await viewModel.refreshFXRate()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Refresh Rate")
                }
            }
        } header: {
            Text("Currency Conversion")
        } footer: {
            Text("The exchange rate is provided for informational purposes. The final rate will be locked when you confirm the withdrawal.")
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section("Notes (Optional)") {
            TextField("Add a note for this withdrawal", text: $viewModel.notes, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        Section {
            VStack(spacing: 12) {
                // Current Balance
                HStack {
                    Text("Current Balance")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(availableBalance.currencyString(code: "GBP"))
                        .fontWeight(.medium)
                }

                Divider()

                // Withdrawal Amount
                HStack {
                    Text("Withdrawal Amount")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("-" + (viewModel.withdrawalAmountValue ?? 0).currencyString(code: "GBP"))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.prosperityGold)
                }

                Divider()

                // Remaining Balance
                HStack {
                    Text("Remaining Balance")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(remainingBalance.currencyString(code: "GBP"))
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Divider()

                // USD Value Being Withdrawn
                HStack {
                    Text("USD Value")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.withdrawalConvertedUSD.currencyString(code: "USD"))
                        .fontWeight(.medium)
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Summary")
        }
    }

    // MARK: - Submitting Overlay

    private var submittingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Processing...")
                    .font(.headline)
            }
            .padding(32)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Computed Properties

    private var remainingBalance: Decimal {
        availableBalance - (viewModel.withdrawalAmountValue ?? 0)
    }

    private var confirmationMessage: String {
        guard let amount = viewModel.withdrawalAmountValue else { return "" }
        return """
        You are about to withdraw \(amount.currencyString(code: "GBP")).

        This is equivalent to approximately \(viewModel.withdrawalConvertedUSD.currencyString(code: "USD")) at the current rate.

        Your remaining balance will be \(remainingBalance.currencyString(code: "GBP")).

        Do you want to proceed?
        """
    }

    // MARK: - Actions

    private func initiateWithdrawal() {
        Task {
            do {
                let _ = try await viewModel.initiateWithdrawal()
                showConfirmation = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func confirmWithdrawal() {
        Task {
            do {
                try await viewModel.confirmWithdrawal()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WithdrawalView(viewModel: FundingViewModel())
}
