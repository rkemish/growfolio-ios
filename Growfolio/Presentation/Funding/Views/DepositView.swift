//
//  DepositView.swift
//  Growfolio
//
//  View for initiating deposits with FX rate display.
//

import SwiftUI

struct DepositView: View {

    // MARK: - Properties

    @Bindable var viewModel: FundingViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAmountFocused: Bool

    @State private var showConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Amount Section
                amountSection

                // FX Conversion Section
                fxConversionSection

                // Notes Section
                notesSection

                // Summary Section
                if viewModel.canDeposit {
                    summarySection
                }
            }
            .navigationTitle("Deposit Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.dismissDeposit()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        initiateDeposit()
                    }
                    .disabled(!viewModel.canDeposit || viewModel.isSubmitting)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isAmountFocused = false
                    }
                }
            }
            .alert("Confirm Deposit", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {
                    viewModel.resetDepositForm()
                }
                Button("Confirm") {
                    confirmDeposit()
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

    // MARK: - Amount Section

    private var amountSection: some View {
        Section {
            HStack {
                Text("GBP")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(width: 50)

                TextField("0.00", text: $viewModel.depositAmount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .semibold))
                    .multilineTextAlignment(.trailing)
                    .focused($isAmountFocused)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Amount to Deposit")
        } footer: {
            Text("Enter the amount in GBP you wish to deposit to your account.")
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

            // Converted Amount
            if viewModel.depositAmountValue != nil {
                HStack {
                    Text("You Will Receive")
                    Spacer()
                    Text(viewModel.depositConvertedUSD.currencyString(code: "USD"))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.positive)
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
            Text("The exchange rate is provided for informational purposes. The final rate will be locked when you confirm the deposit.")
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section("Notes (Optional)") {
            TextField("Add a note for this deposit", text: $viewModel.notes, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        Section {
            VStack(spacing: 12) {
                // Deposit Amount
                HStack {
                    Text("Deposit Amount")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text((viewModel.depositAmountValue ?? 0).currencyString(code: "GBP"))
                        .fontWeight(.medium)
                }

                Divider()

                // FX Rate
                HStack {
                    Text("Exchange Rate")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("1 GBP = \(viewModel.effectiveFXRate.rounded(places: 4)) USD")
                        .fontWeight(.medium)
                }

                Divider()

                // Final Amount
                HStack {
                    Text("Credit to Account")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(viewModel.depositConvertedUSD.currencyString(code: "USD"))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.positive)
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

    // MARK: - Confirmation Message

    private var confirmationMessage: String {
        guard let amount = viewModel.depositAmountValue else { return "" }
        return """
        You are about to deposit \(amount.currencyString(code: "GBP")).

        At the current exchange rate, this will credit approximately \(viewModel.depositConvertedUSD.currencyString(code: "USD")) to your account.

        Do you want to proceed?
        """
    }

    // MARK: - Actions

    private func initiateDeposit() {
        Task {
            do {
                let _ = try await viewModel.initiateDeposit()
                showConfirmation = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func confirmDeposit() {
        Task {
            do {
                try await viewModel.confirmDeposit()
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
    DepositView(viewModel: FundingViewModel())
}
