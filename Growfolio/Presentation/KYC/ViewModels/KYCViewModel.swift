//
//  KYCViewModel.swift
//  Growfolio
//
//  View model for the KYC onboarding flow.
//

import Foundation
import SwiftUI

@Observable
final class KYCViewModel {

    // MARK: - Types

    enum Step: Int, CaseIterable {
        case personalInfo = 0
        case address = 1
        case taxInfo = 2
        case employment = 3
        case disclosures = 4
        case review = 5

        var title: String {
            switch self {
            case .personalInfo: return "Personal Information"
            case .address: return "Address"
            case .taxInfo: return "Tax Information"
            case .employment: return "Employment"
            case .disclosures: return "Disclosures"
            case .review: return "Review"
            }
        }

        var subtitle: String {
            switch self {
            case .personalInfo: return "Let's start with your basic information"
            case .address: return "Where do you live?"
            case .taxInfo: return "Tax identification details"
            case .employment: return "Tell us about your employment"
            case .disclosures: return "Required agreements"
            case .review: return "Review your information"
            }
        }
    }

    enum SubmissionState: Equatable {
        case idle
        case submitting
        case success(KYCSubmissionResponse)
        case error(String)
    }

    // MARK: - Properties

    var currentStep: Step = .personalInfo
    var kycData = KYCData()
    var submissionState: SubmissionState = .idle
    var validationErrors: [String: String] = [:]
    var userEmail: String = ""

    private let repository: KYCRepositoryProtocol

    // MARK: - Computed Properties

    var progress: Double {
        Double(currentStep.rawValue) / Double(Step.allCases.count - 1)
    }

    var isFirstStep: Bool {
        currentStep == .personalInfo
    }

    var isLastStep: Bool {
        currentStep == .review
    }

    var canProceed: Bool {
        validateCurrentStep()
    }

    var isSubmitting: Bool {
        if case .submitting = submissionState {
            return true
        }
        return false
    }

    // MARK: - Initialization

    init(repository: KYCRepositoryProtocol = RepositoryContainer.kycRepository) {
        self.repository = repository
    }

    // MARK: - Navigation

    func nextStep() {
        guard canProceed else { return }
        guard let nextIndex = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextIndex
    }

    func previousStep() {
        guard let prevIndex = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prevIndex
    }

    func goToStep(_ step: Step) {
        currentStep = step
    }

    // MARK: - Validation

    func validateCurrentStep() -> Bool {
        validationErrors = [:]

        switch currentStep {
        case .personalInfo:
            return validatePersonalInfo()
        case .address:
            return validateAddress()
        case .taxInfo:
            return validateTaxInfo()
        case .employment:
            return validateEmployment()
        case .disclosures:
            return validateDisclosures()
        case .review:
            return validateAll()
        }
    }

    private func validatePersonalInfo() -> Bool {
        var isValid = true

        if kycData.firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["firstName"] = "First name is required"
            isValid = false
        }

        if kycData.lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["lastName"] = "Last name is required"
            isValid = false
        }

        if kycData.dateOfBirth == nil {
            validationErrors["dateOfBirth"] = "Date of birth is required"
            isValid = false
        } else if let dob = kycData.dateOfBirth {
            let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
            if age < 18 {
                validationErrors["dateOfBirth"] = "You must be at least 18 years old"
                isValid = false
            }
        }

        let phoneDigits = kycData.phoneNumber.filter { $0.isNumber }
        if phoneDigits.count < 10 {
            validationErrors["phoneNumber"] = "Valid phone number is required"
            isValid = false
        }

        return isValid
    }

    private func validateAddress() -> Bool {
        var isValid = true

        if kycData.streetAddress.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["streetAddress"] = "Street address is required"
            isValid = false
        }

        if kycData.city.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["city"] = "City is required"
            isValid = false
        }

        if kycData.state.isEmpty {
            validationErrors["state"] = "State is required"
            isValid = false
        }

        let postalDigits = kycData.postalCode.filter { $0.isNumber }
        if postalDigits.count < 5 {
            validationErrors["postalCode"] = "Valid postal code is required"
            isValid = false
        }

        return isValid
    }

    private func validateTaxInfo() -> Bool {
        var isValid = true

        let taxIdDigits = kycData.taxId.filter { $0.isNumber }
        if taxIdDigits.count != 9 {
            validationErrors["taxId"] = "Valid 9-digit tax ID is required"
            isValid = false
        }

        if kycData.citizenship.isEmpty {
            validationErrors["citizenship"] = "Citizenship is required"
            isValid = false
        }

        return isValid
    }

    private func validateEmployment() -> Bool {
        var isValid = true

        if kycData.employmentStatus == .employed || kycData.employmentStatus == .selfEmployed {
            if kycData.employer.trimmingCharacters(in: .whitespaces).isEmpty {
                validationErrors["employer"] = "Employer name is required"
                isValid = false
            }
            if kycData.occupation.trimmingCharacters(in: .whitespaces).isEmpty {
                validationErrors["occupation"] = "Occupation is required"
                isValid = false
            }
        }

        return isValid
    }

    private func validateDisclosures() -> Bool {
        var isValid = true

        if !kycData.disclosuresAccepted {
            validationErrors["disclosures"] = "You must accept the disclosures"
            isValid = false
        }

        if !kycData.customerAgreementAccepted {
            validationErrors["customerAgreement"] = "You must accept the customer agreement"
            isValid = false
        }

        if !kycData.accountAgreementAccepted {
            validationErrors["accountAgreement"] = "You must accept the account agreement"
            isValid = false
        }

        if !kycData.marketDataAgreementAccepted {
            validationErrors["marketDataAgreement"] = "You must accept the market data agreement"
            isValid = false
        }

        return isValid
    }

    private func validateAll() -> Bool {
        let personalValid = validatePersonalInfoSilent()
        let addressValid = validateAddressSilent()
        let taxValid = validateTaxInfoSilent()
        let employmentValid = validateEmploymentSilent()
        let disclosuresValid = validateDisclosuresSilent()

        return personalValid && addressValid && taxValid && employmentValid && disclosuresValid
    }

    private func validatePersonalInfoSilent() -> Bool {
        let phoneDigits = kycData.phoneNumber.filter { $0.isNumber }
        guard !kycData.firstName.trimmingCharacters(in: .whitespaces).isEmpty,
              !kycData.lastName.trimmingCharacters(in: .whitespaces).isEmpty,
              kycData.dateOfBirth != nil,
              phoneDigits.count >= 10 else {
            return false
        }

        if let dob = kycData.dateOfBirth {
            let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
            if age < 18 { return false }
        }

        return true
    }

    private func validateAddressSilent() -> Bool {
        let postalDigits = kycData.postalCode.filter { $0.isNumber }
        return !kycData.streetAddress.trimmingCharacters(in: .whitespaces).isEmpty &&
               !kycData.city.trimmingCharacters(in: .whitespaces).isEmpty &&
               !kycData.state.isEmpty &&
               postalDigits.count >= 5
    }

    private func validateTaxInfoSilent() -> Bool {
        let taxIdDigits = kycData.taxId.filter { $0.isNumber }
        return taxIdDigits.count == 9 && !kycData.citizenship.isEmpty
    }

    private func validateEmploymentSilent() -> Bool {
        if kycData.employmentStatus == .employed || kycData.employmentStatus == .selfEmployed {
            return !kycData.employer.trimmingCharacters(in: .whitespaces).isEmpty &&
                   !kycData.occupation.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return true
    }

    private func validateDisclosuresSilent() -> Bool {
        return kycData.disclosuresAccepted &&
               kycData.customerAgreementAccepted &&
               kycData.accountAgreementAccepted &&
               kycData.marketDataAgreementAccepted
    }

    // MARK: - Submission

    nonisolated(nonsending)
    func submit() async {
        guard validateAll() else {
            submissionState = .error("Please complete all required fields")
            return
        }

        submissionState = .submitting

        do {
            let response = try await repository.submitKYC(data: kycData, email: userEmail)
            submissionState = .success(response)
        } catch let error as NetworkError {
            submissionState = .error(error.errorDescription ?? "Submission failed")
        } catch {
            submissionState = .error(error.localizedDescription)
        }
    }

    // MARK: - Formatting Helpers

    func formatPhoneNumber(_ phone: String) -> String {
        let digits = phone.filter { $0.isNumber }
        guard digits.count >= 10 else { return phone }

        let areaCode = String(digits.prefix(3))
        let middle = String(digits.dropFirst(3).prefix(3))
        let last = String(digits.dropFirst(6).prefix(4))

        return "(\(areaCode)) \(middle)-\(last)"
    }

    func formatTaxId(_ taxId: String) -> String {
        let digits = taxId.filter { $0.isNumber }
        guard digits.count == 9 else { return taxId }

        let first = String(digits.prefix(3))
        let middle = String(digits.dropFirst(3).prefix(2))
        let last = String(digits.dropFirst(5))

        return "\(first)-\(middle)-\(last)"
    }

    func maskedTaxId() -> String {
        let digits = kycData.taxId.filter { $0.isNumber }
        guard digits.count == 9 else { return "***-**-****" }
        let last = String(digits.suffix(4))
        return "***-**-\(last)"
    }
}
