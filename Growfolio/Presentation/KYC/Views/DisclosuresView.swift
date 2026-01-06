//
//  DisclosuresView.swift
//  Growfolio
//
//  KYC step for required Alpaca disclosures and agreements.
//

import SwiftUI

struct DisclosuresView: View {
    @Bindable var viewModel: KYCViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                VStack(spacing: 16) {
                    disclosureToggle(
                        title: "Regulatory Disclosures",
                        description: disclosureDescription,
                        isAccepted: $viewModel.kycData.disclosuresAccepted,
                        errorKey: "disclosures"
                    )

                    disclosureToggle(
                        title: "Customer Agreement",
                        description: customerAgreementDescription,
                        isAccepted: $viewModel.kycData.customerAgreementAccepted,
                        errorKey: "customerAgreement",
                        linkText: "Read Customer Agreement",
                        linkURL: URL(string: "https://alpaca.markets/disclosures/customer-agreement")
                    )

                    disclosureToggle(
                        title: "Account Agreement",
                        description: accountAgreementDescription,
                        isAccepted: $viewModel.kycData.accountAgreementAccepted,
                        errorKey: "accountAgreement",
                        linkText: "Read Account Agreement",
                        linkURL: URL(string: "https://alpaca.markets/disclosures/account-agreement")
                    )

                    disclosureToggle(
                        title: "Market Data Agreement",
                        description: marketDataDescription,
                        isAccepted: $viewModel.kycData.marketDataAgreementAccepted,
                        errorKey: "marketDataAgreement",
                        linkText: "Read Market Data Agreement",
                        linkURL: URL(string: "https://alpaca.markets/disclosures/market-data-agreement")
                    )
                }
                .padding(.horizontal, Constants.UI.standardPadding)

                additionalDisclosures
            }
            .padding(.vertical, Constants.UI.standardPadding)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.gearshape")
                .font(.system(size: 60))
                .foregroundStyle(.indigo)
                .symbolRenderingMode(.hierarchical)

            Text("Please review and accept the required agreements to open your brokerage account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Disclosure Toggle

    private func disclosureToggle(
        title: String,
        description: String,
        isAccepted: Binding<Bool>,
        errorKey: String,
        linkText: String? = nil,
        linkURL: URL? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Toggle("", isOn: isAccepted)
                    .labelsHidden()
                    .tint(.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let linkText = linkText, let linkURL = linkURL {
                        Link(linkText, destination: linkURL)
                            .font(.caption)
                    }
                }
            }

            if let error = viewModel.validationErrors[errorKey] {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(error)
                }
                .font(.caption)
                .foregroundStyle(Color.negative)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }

    // MARK: - Additional Disclosures

    private var additionalDisclosures: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Disclosures")
                .font(.headline)
                .padding(.horizontal, Constants.UI.standardPadding)

            VStack(alignment: .leading, spacing: 16) {
                disclosureItem(
                    icon: "building.columns",
                    title: "FINRA & SIPC Protection",
                    description: "Your account is protected by SIPC up to $500,000, including $250,000 for cash claims."
                )

                disclosureItem(
                    icon: "exclamationmark.triangle",
                    title: "Investment Risk",
                    description: "Investing involves risk. You could lose some or all of your investment."
                )

                disclosureItem(
                    icon: "person.badge.shield.checkmark",
                    title: "Identity Verification",
                    description: "Your identity will be verified using the information you provide. False information may result in account closure."
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            .padding(.horizontal, Constants.UI.standardPadding)
        }
    }

    private func disclosureItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Disclosure Text

    private var disclosureDescription: String {
        "I confirm that I am not a control person of a publicly traded company, I am not affiliated with FINRA or any stock exchange, and I am not a politically exposed person."
    }

    private var customerAgreementDescription: String {
        "I have read and agree to the Alpaca Securities Customer Agreement, which governs my brokerage account."
    }

    private var accountAgreementDescription: String {
        "I have read and agree to the Account Agreement, including the terms for fractional share trading."
    }

    private var marketDataDescription: String {
        "I agree to receive market data under the terms of the Market Data Agreement and understand associated usage limitations."
    }
}

#Preview {
    DisclosuresView(viewModel: KYCViewModel())
}
