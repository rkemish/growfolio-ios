//
//  PersonalInfoView.swift
//  Growfolio
//
//  KYC step for collecting personal information.
//

import SwiftUI

struct PersonalInfoView: View {
    @Bindable var viewModel: KYCViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case firstName, lastName, phone
    }

    private var maxDateOfBirth: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    private var minDateOfBirth: Date {
        Calendar.current.date(byAdding: .year, value: -120, to: Date()) ?? Date()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection

                VStack(spacing: 20) {
                    firstNameField
                    lastNameField
                    dateOfBirthField
                    phoneField
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
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(Color.trustBlue)
                .symbolRenderingMode(.hierarchical)

            Text("We need some basic information to set up your brokerage account.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - First Name Field

    private var firstNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Legal First Name")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("Enter your first name", text: $viewModel.kycData.firstName)
                .textContentType(.givenName)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .focused($focusedField, equals: .firstName)
                .submitLabel(.next)
                .onSubmit { focusedField = .lastName }

            if let error = viewModel.validationErrors["firstName"] {
                errorLabel(error)
            }
        }
    }

    // MARK: - Last Name Field

    private var lastNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Legal Last Name")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("Enter your last name", text: $viewModel.kycData.lastName)
                .textContentType(.familyName)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .focused($focusedField, equals: .lastName)
                .submitLabel(.next)
                .onSubmit { focusedField = .phone }

            if let error = viewModel.validationErrors["lastName"] {
                errorLabel(error)
            }
        }
    }

    // MARK: - Date of Birth Field

    private var dateOfBirthField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Date of Birth")
                .font(.subheadline)
                .fontWeight(.medium)

            DatePicker(
                "Date of Birth",
                selection: Binding(
                    get: { viewModel.kycData.dateOfBirth ?? maxDateOfBirth },
                    set: { viewModel.kycData.dateOfBirth = $0 }
                ),
                in: minDateOfBirth...maxDateOfBirth,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))

            if let error = viewModel.validationErrors["dateOfBirth"] {
                errorLabel(error)
            } else {
                Text("You must be at least 18 years old to open an account.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Phone Field

    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Phone Number")
                .font(.subheadline)
                .fontWeight(.medium)

            TextField("(555) 555-5555", text: $viewModel.kycData.phoneNumber)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                .focused($focusedField, equals: .phone)
                .onChange(of: viewModel.kycData.phoneNumber) { _, newValue in
                    let digits = newValue.filter { $0.isNumber }
                    if digits.count <= 10 {
                        viewModel.kycData.phoneNumber = formatPhoneInput(digits)
                    } else {
                        viewModel.kycData.phoneNumber = formatPhoneInput(String(digits.prefix(10)))
                    }
                }

            if let error = viewModel.validationErrors["phoneNumber"] {
                errorLabel(error)
            }
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

    // MARK: - Formatting

    private func formatPhoneInput(_ digits: String) -> String {
        var result = ""
        let chars = Array(digits)

        for (index, char) in chars.enumerated() {
            if index == 0 { result += "(" }
            if index == 3 { result += ") " }
            if index == 6 { result += "-" }
            result.append(char)
        }

        return result
    }
}

#Preview {
    PersonalInfoView(viewModel: KYCViewModel())
}
