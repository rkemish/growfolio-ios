//
//  KYCReviewView.swift
//  Growfolio
//
//  KYC step for reviewing all information before submission.
//

import SwiftUI

struct KYCReviewView: View {
    @Bindable var viewModel: KYCViewModel

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                VStack(spacing: 16) {
                    personalInfoSection
                    addressSection
                    taxInfoSection
                    employmentSection
                    financialInfoSection
                    disclosuresSection
                }
                .padding(.horizontal, Constants.UI.standardPadding)
            }
            .padding(.vertical, Constants.UI.standardPadding)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 60))
                .foregroundStyle(Color.positive)
                .symbolRenderingMode(.hierarchical)

            Text("Review Your Information")
                .font(.title2)
                .fontWeight(.bold)

            Text("Please verify all information is correct before submitting your application.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Personal Info Section

    private var personalInfoSection: some View {
        reviewSection(
            title: "Personal Information",
            icon: "person.fill",
            step: .personalInfo
        ) {
            reviewRow("First Name", value: viewModel.kycData.firstName)
            reviewRow("Last Name", value: viewModel.kycData.lastName)
            if let dob = viewModel.kycData.dateOfBirth {
                reviewRow("Date of Birth", value: dateFormatter.string(from: dob))
            }
            reviewRow("Phone", value: viewModel.formatPhoneNumber(viewModel.kycData.phoneNumber))
        }
    }

    // MARK: - Address Section

    private var addressSection: some View {
        reviewSection(
            title: "Address",
            icon: "house.fill",
            step: .address
        ) {
            reviewRow("Street", value: viewModel.kycData.streetAddress)
            if !viewModel.kycData.apartmentUnit.isEmpty {
                reviewRow("Unit", value: viewModel.kycData.apartmentUnit)
            }
            reviewRow("City", value: viewModel.kycData.city)
            if let state = USState(rawValue: viewModel.kycData.state) {
                reviewRow("State", value: state.fullName)
            }
            reviewRow("Postal Code", value: viewModel.kycData.postalCode)
            reviewRow("Country", value: "United States")
        }
    }

    // MARK: - Tax Info Section

    private var taxInfoSection: some View {
        reviewSection(
            title: "Tax Information",
            icon: "doc.text.fill",
            step: .taxInfo
        ) {
            reviewRow("Tax ID Type", value: viewModel.kycData.taxIdType.displayName)
            reviewRow("Tax ID", value: viewModel.maskedTaxId())
            reviewRow("Citizenship", value: "United States")
            reviewRow("Tax Country", value: "United States")
        }
    }

    // MARK: - Employment Section

    private var employmentSection: some View {
        reviewSection(
            title: "Employment",
            icon: "briefcase.fill",
            step: .employment
        ) {
            reviewRow("Status", value: viewModel.kycData.employmentStatus.displayName)
            if viewModel.kycData.employmentStatus == .employed ||
               viewModel.kycData.employmentStatus == .selfEmployed {
                reviewRow("Employer", value: viewModel.kycData.employer)
                reviewRow("Occupation", value: viewModel.kycData.occupation)
            }
        }
    }

    // MARK: - Financial Info Section

    private var financialInfoSection: some View {
        reviewSection(
            title: "Financial Information",
            icon: "dollarsign.circle.fill",
            step: .employment
        ) {
            reviewRow("Funding Source", value: viewModel.kycData.fundingSource.displayName)
            reviewRow("Annual Income", value: viewModel.kycData.annualIncome.displayName)
            reviewRow("Liquid Net Worth", value: viewModel.kycData.liquidNetWorth.displayName)
            reviewRow("Total Net Worth", value: viewModel.kycData.totalNetWorth.displayName)
        }
    }

    // MARK: - Disclosures Section

    private var disclosuresSection: some View {
        reviewSection(
            title: "Agreements",
            icon: "doc.badge.gearshape.fill",
            step: .disclosures
        ) {
            agreementRow("Regulatory Disclosures", accepted: viewModel.kycData.disclosuresAccepted)
            agreementRow("Customer Agreement", accepted: viewModel.kycData.customerAgreementAccepted)
            agreementRow("Account Agreement", accepted: viewModel.kycData.accountAgreementAccepted)
            agreementRow("Market Data Agreement", accepted: viewModel.kycData.marketDataAgreementAccepted)
        }
    }

    // MARK: - Review Section Builder

    private func reviewSection<Content: View>(
        title: String,
        icon: String,
        step: KYCViewModel.Step,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.goToStep(step)
                } label: {
                    Text("Edit")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }

            VStack(spacing: 8) {
                content()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }

    // MARK: - Review Row

    private func reviewRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Agreement Row

    private func agreementRow(_ label: String, accepted: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Image(systemName: accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(accepted ? Color.positive : Color.negative)
        }
    }
}

#Preview {
    let viewModel = KYCViewModel()
    viewModel.kycData = KYCData(
        firstName: "John",
        lastName: "Doe",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
        phoneNumber: "(555) 123-4567",
        streetAddress: "123 Main Street",
        apartmentUnit: "Apt 4B",
        city: "New York",
        state: "NY",
        postalCode: "10001",
        country: "USA",
        taxIdType: .ssn,
        taxId: "123-45-6789",
        citizenship: "USA",
        taxCountry: "USA",
        employmentStatus: .employed,
        employer: "Acme Corp",
        occupation: "Software Engineer",
        fundingSource: .employmentIncome,
        annualIncome: .range100kTo200k,
        liquidNetWorth: .range50kTo100k,
        totalNetWorth: .range200kTo500k,
        disclosuresAccepted: true,
        customerAgreementAccepted: true,
        accountAgreementAccepted: true,
        marketDataAgreementAccepted: true
    )
    return KYCReviewView(viewModel: viewModel)
}
