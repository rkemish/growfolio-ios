//
//  EmploymentInfoView.swift
//  Growfolio
//
//  KYC step for collecting employment and financial information.
//

import SwiftUI

struct EmploymentInfoView: View {
    @Bindable var viewModel: KYCViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case employer, occupation
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                VStack(spacing: 20) {
                    employmentStatusField

                    if showEmployerFields {
                        employerField
                        occupationField
                    }

                    fundingSourceField
                    annualIncomeField
                    liquidNetWorthField
                    totalNetWorthField
                }
                .padding(.horizontal, Constants.UI.standardPadding)
            }
            .padding(.vertical, Constants.UI.standardPadding)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var showEmployerFields: Bool {
        viewModel.kycData.employmentStatus == .employed ||
        viewModel.kycData.employmentStatus == .selfEmployed
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "briefcase.circle")
                .font(.system(size: 60))
                .foregroundStyle(Color.trustBlue)
                .symbolRenderingMode(.hierarchical)

            Text("We need employment and financial information for regulatory compliance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Employment Status Field

    private var employmentStatusField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Employment Status")
                .font(.subheadline)
                .fontWeight(.medium)

            Menu {
                ForEach(EmploymentStatus.allCases, id: \.self) { status in
                    Button {
                        viewModel.kycData.employmentStatus = status
                    } label: {
                        Text(status.displayName)
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.kycData.employmentStatus.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }
        }
    }

    // MARK: - Employer Field

    private var employerField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.kycData.employmentStatus == .selfEmployed ? "Business Name" : "Employer Name")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("Company name", text: $viewModel.kycData.employer)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .focused($focusedField, equals: .employer)
                .submitLabel(.next)
                .onSubmit { focusedField = .occupation }

            if let error = viewModel.validationErrors["employer"] {
                errorLabel(error)
            }
        }
    }

    // MARK: - Occupation Field

    private var occupationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Occupation/Job Title")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("Software Engineer", text: $viewModel.kycData.occupation)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .focused($focusedField, equals: .occupation)

            if let error = viewModel.validationErrors["occupation"] {
                errorLabel(error)
            }
        }
    }

    // MARK: - Funding Source Field

    private var fundingSourceField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Primary Funding Source")
                .font(.subheadline)
                .fontWeight(.medium)

            Menu {
                ForEach(FundingSource.allCases, id: \.self) { source in
                    Button {
                        viewModel.kycData.fundingSource = source
                    } label: {
                        Text(source.displayName)
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.kycData.fundingSource.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }

            Text("Where does the money you plan to invest come from?")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Annual Income Field

    private var annualIncomeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Annual Income")
                .font(.subheadline)
                .fontWeight(.medium)

            Menu {
                ForEach(AnnualIncomeRange.allCases, id: \.self) { range in
                    Button {
                        viewModel.kycData.annualIncome = range
                    } label: {
                        Text(range.displayName)
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.kycData.annualIncome.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }
        }
    }

    // MARK: - Liquid Net Worth Field

    private var liquidNetWorthField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Liquid Net Worth")
                .font(.subheadline)
                .fontWeight(.medium)

            Menu {
                ForEach(LiquidNetWorthRange.allCases, id: \.self) { range in
                    Button {
                        viewModel.kycData.liquidNetWorth = range
                    } label: {
                        Text(range.displayName)
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.kycData.liquidNetWorth.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }

            Text("Assets that can be easily converted to cash (savings, stocks, etc.)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Total Net Worth Field

    private var totalNetWorthField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Total Net Worth")
                .font(.subheadline)
                .fontWeight(.medium)

            Menu {
                ForEach(TotalNetWorthRange.allCases, id: \.self) { range in
                    Button {
                        viewModel.kycData.totalNetWorth = range
                    } label: {
                        Text(range.displayName)
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.kycData.totalNetWorth.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }

            Text("Total value of all assets minus liabilities")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
}

#Preview {
    EmploymentInfoView(viewModel: KYCViewModel())
}
