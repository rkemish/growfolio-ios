//
//  TaxInfoView.swift
//  Growfolio
//
//  KYC step for collecting tax identification information.
//

import SwiftUI

struct TaxInfoView: View {
    @Bindable var viewModel: KYCViewModel
    @FocusState private var isTaxIdFocused: Bool
    @State private var showTaxId = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                VStack(spacing: 20) {
                    taxIdTypeField
                    taxIdField
                    citizenshipField
                    taxCountryField
                }
                .padding(.horizontal, Constants.UI.standardPadding)

                securityNotice
            }
            .padding(.vertical, Constants.UI.standardPadding)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(Color.prosperityGold)
                .symbolRenderingMode(.hierarchical)

            Text("We're required to collect your tax information for regulatory compliance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Tax ID Type Field

    private var taxIdTypeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tax ID Type")
                .font(.subheadline)
                .fontWeight(.medium)

            Picker("Tax ID Type", selection: $viewModel.kycData.taxIdType) {
                ForEach(TaxIdType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Tax ID Field

    private var taxIdField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.kycData.taxIdType == .ssn ? "Social Security Number" : "ITIN")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Group {
                    if showTaxId {
                        TextField("XXX-XX-XXXX", text: $viewModel.kycData.taxId)
                            .keyboardType(.numberPad)
                    } else {
                        SecureField("XXX-XX-XXXX", text: $viewModel.kycData.taxId)
                    }
                }
                .textContentType(.none)
                .focused($isTaxIdFocused)
                .onChange(of: viewModel.kycData.taxId) { _, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    if digits.count <= 9 {
                        viewModel.kycData.taxId = formatTaxIdInput(digits)
                    } else {
                        viewModel.kycData.taxId = formatTaxIdInput(String(digits.prefix(9)))
                    }
                }

                Button {
                    showTaxId.toggle()
                } label: {
                    Image(systemName: showTaxId ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))

            if let error = viewModel.validationErrors["taxId"] {
                errorLabel(error)
            } else {
                Text("Your tax ID is encrypted and stored securely.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Citizenship Field

    private var citizenshipField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Country of Citizenship")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Text("United States")
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))

            Text("Non-US citizens are not supported at this time.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tax Country Field

    private var taxCountryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Country of Tax Residence")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack {
                Text("United States")
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        }
    }

    // MARK: - Security Notice

    private var securityNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundStyle(Color.positive)

            VStack(alignment: .leading, spacing: 4) {
                Text("Your Information is Secure")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("All sensitive data is encrypted using bank-level security. Your tax information is only shared with our brokerage partner Alpaca for account verification.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        .padding(.horizontal, Constants.UI.standardPadding)
    }

    // MARK: - Helper Views

    private func errorLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(text)
        }
        .font(.caption)
        .foregroundStyle(Color.negative)
    }

    // MARK: - Formatting

    private func formatTaxIdInput(_ digits: String) -> String {
        var result = ""
        let chars = Array(digits)

        for (index, char) in chars.enumerated() {
            if index == 3 || index == 5 { result += "-" }
            result.append(char)
        }

        return result
    }
}

#Preview {
    TaxInfoView(viewModel: KYCViewModel())
}
