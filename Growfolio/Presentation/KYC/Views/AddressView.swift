//
//  AddressView.swift
//  Growfolio
//
//  KYC step for collecting address information.
//

import SwiftUI

struct AddressView: View {
    @Bindable var viewModel: KYCViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case street, apartment, city, postalCode
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                VStack(spacing: 20) {
                    streetAddressField
                    apartmentField
                    cityField
                    stateField
                    postalCodeField
                    countryField
                }
                .padding(.horizontal, Constants.UI.standardPadding)
            }
            .padding(.vertical, Constants.UI.standardPadding)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "house.circle")
                .font(.system(size: 60))
                .foregroundStyle(Color.positive)
                .symbolRenderingMode(.hierarchical)

            Text("Your legal residence address is required for regulatory compliance.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - Street Address Field

    private var streetAddressField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Street Address")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("123 Main Street", text: $viewModel.kycData.streetAddress)
                .textContentType(.streetAddressLine1)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .focused($focusedField, equals: .street)
                .submitLabel(.next)
                .onSubmit { focusedField = .apartment }

            if let error = viewModel.validationErrors["streetAddress"] {
                errorLabel(error)
            }
        }
    }

    // MARK: - Apartment Field

    private var apartmentField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Apartment/Unit (Optional)")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("Apt 4B", text: $viewModel.kycData.apartmentUnit)
                .textContentType(.streetAddressLine2)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .focused($focusedField, equals: .apartment)
                .submitLabel(.next)
                .onSubmit { focusedField = .city }
        }
    }

    // MARK: - City Field

    private var cityField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("City")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("New York", text: $viewModel.kycData.city)
                .textContentType(.addressCity)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .focused($focusedField, equals: .city)
                .submitLabel(.next)
                .onSubmit { focusedField = .postalCode }

            if let error = viewModel.validationErrors["city"] {
                errorLabel(error)
            }
        }
    }

    // MARK: - State Field

    private var stateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("State")
                .font(.subheadline)
                .fontWeight(.medium)

            Menu {
                ForEach(USState.allCases, id: \.self) { state in
                    Button {
                        viewModel.kycData.state = state.rawValue
                    } label: {
                        Text(state.fullName)
                    }
                }
            } label: {
                HStack {
                    if viewModel.kycData.state.isEmpty {
                        Text("Select a state")
                            .foregroundStyle(.secondary)
                    } else if let state = USState(rawValue: viewModel.kycData.state) {
                        Text(state.fullName)
                            .foregroundStyle(.primary)
                    } else {
                        Text(viewModel.kycData.state)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }

            if let error = viewModel.validationErrors["state"] {
                errorLabel(error)
            }
        }
    }

    // MARK: - Postal Code Field

    private var postalCodeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Postal Code")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("10001", text: $viewModel.kycData.postalCode)
                .textContentType(.postalCode)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .focused($focusedField, equals: .postalCode)
                .onChange(of: viewModel.kycData.postalCode) { _, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    viewModel.kycData.postalCode = String(digits.prefix(5))
                }

            if let error = viewModel.validationErrors["postalCode"] {
                errorLabel(error)
            }
        }
    }

    // MARK: - Country Field

    private var countryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Country")
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

            Text("Only US residents can open accounts at this time.")
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
    AddressView(viewModel: KYCViewModel())
}
