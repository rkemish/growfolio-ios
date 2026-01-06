//
//  KYCViewModelTests.swift
//  GrowfolioTests
//
//  Tests for the KYCViewModel - multi-step KYC form validation logic.
//

import XCTest
@testable import Growfolio

@MainActor
final class KYCViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: KYCViewModel!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sut = KYCViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_startsAtPersonalInfoStep() {
        XCTAssertEqual(sut.currentStep, .personalInfo)
    }

    func test_initialState_hasEmptyKYCData() {
        XCTAssertEqual(sut.kycData.firstName, "")
        XCTAssertEqual(sut.kycData.lastName, "")
        XCTAssertNil(sut.kycData.dateOfBirth)
        XCTAssertEqual(sut.kycData.phoneNumber, "")
    }

    func test_initialState_hasNoValidationErrors() {
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }

    func test_initialState_isNotSubmitting() {
        XCTAssertFalse(sut.isSubmitting)
    }

    func test_initialState_isFirstStep() {
        XCTAssertTrue(sut.isFirstStep)
        XCTAssertFalse(sut.isLastStep)
    }

    func test_initialState_progressIsZero() {
        XCTAssertEqual(sut.progress, 0.0)
    }

    // MARK: - Personal Info Validation Tests

    func test_validatePersonalInfo_failsWithEmptyFirstName() {
        sut.kycData.firstName = ""
        sut.kycData.lastName = "Doe"
        sut.kycData.dateOfBirth = createDate(yearsAgo: 25)
        sut.kycData.phoneNumber = "1234567890"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["firstName"])
        XCTAssertEqual(sut.validationErrors["firstName"], "First name is required")
    }

    func test_validatePersonalInfo_failsWithWhitespaceOnlyFirstName() {
        sut.kycData.firstName = "   "
        sut.kycData.lastName = "Doe"
        sut.kycData.dateOfBirth = createDate(yearsAgo: 25)
        sut.kycData.phoneNumber = "1234567890"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["firstName"])
    }

    func test_validatePersonalInfo_failsWithEmptyLastName() {
        sut.kycData.firstName = "John"
        sut.kycData.lastName = ""
        sut.kycData.dateOfBirth = createDate(yearsAgo: 25)
        sut.kycData.phoneNumber = "1234567890"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["lastName"])
        XCTAssertEqual(sut.validationErrors["lastName"], "Last name is required")
    }

    func test_validatePersonalInfo_failsWithMissingDateOfBirth() {
        sut.kycData.firstName = "John"
        sut.kycData.lastName = "Doe"
        sut.kycData.dateOfBirth = nil
        sut.kycData.phoneNumber = "1234567890"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["dateOfBirth"])
        XCTAssertEqual(sut.validationErrors["dateOfBirth"], "Date of birth is required")
    }

    func test_validatePersonalInfo_failsWhenUnder18() {
        sut.kycData.firstName = "John"
        sut.kycData.lastName = "Doe"
        sut.kycData.dateOfBirth = createDate(yearsAgo: 17)
        sut.kycData.phoneNumber = "1234567890"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["dateOfBirth"])
        XCTAssertEqual(sut.validationErrors["dateOfBirth"], "You must be at least 18 years old")
    }

    func test_validatePersonalInfo_passesAt18YearsOld() {
        sut.kycData.firstName = "John"
        sut.kycData.lastName = "Doe"
        sut.kycData.dateOfBirth = createDate(yearsAgo: 18)
        sut.kycData.phoneNumber = "1234567890"

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
        XCTAssertNil(sut.validationErrors["dateOfBirth"])
    }

    func test_validatePersonalInfo_failsWithShortPhoneNumber() {
        sut.kycData.firstName = "John"
        sut.kycData.lastName = "Doe"
        sut.kycData.dateOfBirth = createDate(yearsAgo: 25)
        sut.kycData.phoneNumber = "123456789" // 9 digits

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["phoneNumber"])
        XCTAssertEqual(sut.validationErrors["phoneNumber"], "Valid phone number is required")
    }

    func test_validatePersonalInfo_passesWithFormattedPhoneNumber() {
        sut.kycData.firstName = "John"
        sut.kycData.lastName = "Doe"
        sut.kycData.dateOfBirth = createDate(yearsAgo: 25)
        sut.kycData.phoneNumber = "(123) 456-7890" // Contains 10 digits

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }

    func test_validatePersonalInfo_passesWithValidData() {
        setupValidPersonalInfo()

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }

    func test_validatePersonalInfo_collectsMultipleErrors() {
        sut.kycData.firstName = ""
        sut.kycData.lastName = ""
        sut.kycData.dateOfBirth = nil
        sut.kycData.phoneNumber = ""

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertEqual(sut.validationErrors.count, 4)
        XCTAssertNotNil(sut.validationErrors["firstName"])
        XCTAssertNotNil(sut.validationErrors["lastName"])
        XCTAssertNotNil(sut.validationErrors["dateOfBirth"])
        XCTAssertNotNil(sut.validationErrors["phoneNumber"])
    }

    // MARK: - Address Validation Tests

    func test_validateAddress_failsWithEmptyStreetAddress() {
        sut.currentStep = .address
        sut.kycData.streetAddress = ""
        sut.kycData.city = "New York"
        sut.kycData.state = "NY"
        sut.kycData.postalCode = "10001"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["streetAddress"])
        XCTAssertEqual(sut.validationErrors["streetAddress"], "Street address is required")
    }

    func test_validateAddress_failsWithEmptyCity() {
        sut.currentStep = .address
        sut.kycData.streetAddress = "123 Main St"
        sut.kycData.city = ""
        sut.kycData.state = "NY"
        sut.kycData.postalCode = "10001"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["city"])
        XCTAssertEqual(sut.validationErrors["city"], "City is required")
    }

    func test_validateAddress_failsWithEmptyState() {
        sut.currentStep = .address
        sut.kycData.streetAddress = "123 Main St"
        sut.kycData.city = "New York"
        sut.kycData.state = ""
        sut.kycData.postalCode = "10001"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["state"])
        XCTAssertEqual(sut.validationErrors["state"], "State is required")
    }

    func test_validateAddress_failsWithShortPostalCode() {
        sut.currentStep = .address
        sut.kycData.streetAddress = "123 Main St"
        sut.kycData.city = "New York"
        sut.kycData.state = "NY"
        sut.kycData.postalCode = "1234" // Only 4 digits

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["postalCode"])
        XCTAssertEqual(sut.validationErrors["postalCode"], "Valid postal code is required")
    }

    func test_validateAddress_passesWithValidData() {
        sut.currentStep = .address
        setupValidAddress()

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }

    func test_validateAddress_passesWithFormattedPostalCode() {
        sut.currentStep = .address
        sut.kycData.streetAddress = "123 Main St"
        sut.kycData.city = "New York"
        sut.kycData.state = "NY"
        sut.kycData.postalCode = "10001-1234" // ZIP+4 format

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
    }

    // MARK: - Tax Info Validation Tests

    func test_validateTaxInfo_failsWithInvalidTaxId() {
        sut.currentStep = .taxInfo
        sut.kycData.taxId = "12345678" // Only 8 digits
        sut.kycData.citizenship = "USA"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["taxId"])
        XCTAssertEqual(sut.validationErrors["taxId"], "Valid 9-digit tax ID is required")
    }

    func test_validateTaxInfo_failsWithEmptyCitizenship() {
        sut.currentStep = .taxInfo
        sut.kycData.taxId = "123456789"
        sut.kycData.citizenship = ""

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["citizenship"])
        XCTAssertEqual(sut.validationErrors["citizenship"], "Citizenship is required")
    }

    func test_validateTaxInfo_passesWithValidData() {
        sut.currentStep = .taxInfo
        setupValidTaxInfo()

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }

    func test_validateTaxInfo_passesWithFormattedTaxId() {
        sut.currentStep = .taxInfo
        sut.kycData.taxId = "123-45-6789" // Formatted SSN
        sut.kycData.citizenship = "USA"

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
    }

    // MARK: - Employment Validation Tests

    func test_validateEmployment_requiresEmployerWhenEmployed() {
        sut.currentStep = .employment
        sut.kycData.employmentStatus = .employed
        sut.kycData.employer = ""
        sut.kycData.occupation = "Engineer"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["employer"])
        XCTAssertEqual(sut.validationErrors["employer"], "Employer name is required")
    }

    func test_validateEmployment_requiresOccupationWhenEmployed() {
        sut.currentStep = .employment
        sut.kycData.employmentStatus = .employed
        sut.kycData.employer = "Acme Corp"
        sut.kycData.occupation = ""

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["occupation"])
        XCTAssertEqual(sut.validationErrors["occupation"], "Occupation is required")
    }

    func test_validateEmployment_requiresEmployerWhenSelfEmployed() {
        sut.currentStep = .employment
        sut.kycData.employmentStatus = .selfEmployed
        sut.kycData.employer = ""
        sut.kycData.occupation = "Consultant"

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["employer"])
    }

    func test_validateEmployment_passesWithValidEmployedData() {
        sut.currentStep = .employment
        sut.kycData.employmentStatus = .employed
        sut.kycData.employer = "Acme Corp"
        sut.kycData.occupation = "Software Engineer"

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }

    func test_validateEmployment_passesWhenRetired() {
        sut.currentStep = .employment
        sut.kycData.employmentStatus = .retired
        sut.kycData.employer = ""
        sut.kycData.occupation = ""

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
    }

    func test_validateEmployment_passesWhenStudent() {
        sut.currentStep = .employment
        sut.kycData.employmentStatus = .student
        sut.kycData.employer = ""
        sut.kycData.occupation = ""

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
    }

    func test_validateEmployment_passesWhenUnemployed() {
        sut.currentStep = .employment
        sut.kycData.employmentStatus = .unemployed
        sut.kycData.employer = ""
        sut.kycData.occupation = ""

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
    }

    // MARK: - Disclosures Validation Tests

    func test_validateDisclosures_failsWithoutDisclosuresAccepted() {
        sut.currentStep = .disclosures
        sut.kycData.disclosuresAccepted = false
        sut.kycData.customerAgreementAccepted = true
        sut.kycData.accountAgreementAccepted = true
        sut.kycData.marketDataAgreementAccepted = true

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["disclosures"])
        XCTAssertEqual(sut.validationErrors["disclosures"], "You must accept the disclosures")
    }

    func test_validateDisclosures_failsWithoutCustomerAgreement() {
        sut.currentStep = .disclosures
        sut.kycData.disclosuresAccepted = true
        sut.kycData.customerAgreementAccepted = false
        sut.kycData.accountAgreementAccepted = true
        sut.kycData.marketDataAgreementAccepted = true

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["customerAgreement"])
    }

    func test_validateDisclosures_failsWithoutAccountAgreement() {
        sut.currentStep = .disclosures
        sut.kycData.disclosuresAccepted = true
        sut.kycData.customerAgreementAccepted = true
        sut.kycData.accountAgreementAccepted = false
        sut.kycData.marketDataAgreementAccepted = true

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["accountAgreement"])
    }

    func test_validateDisclosures_failsWithoutMarketDataAgreement() {
        sut.currentStep = .disclosures
        sut.kycData.disclosuresAccepted = true
        sut.kycData.customerAgreementAccepted = true
        sut.kycData.accountAgreementAccepted = true
        sut.kycData.marketDataAgreementAccepted = false

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationErrors["marketDataAgreement"])
    }

    func test_validateDisclosures_passesWithAllAccepted() {
        sut.currentStep = .disclosures
        setupValidDisclosures()

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
        XCTAssertTrue(sut.validationErrors.isEmpty)
    }

    // MARK: - Review Step Validation Tests

    func test_validateReview_validatesAllSteps() {
        sut.currentStep = .review

        // Fill in all required data
        setupValidPersonalInfo()
        setupValidAddress()
        setupValidTaxInfo()
        sut.kycData.employmentStatus = .employed
        sut.kycData.employer = "Acme Corp"
        sut.kycData.occupation = "Engineer"
        setupValidDisclosures()

        let isValid = sut.validateCurrentStep()

        XCTAssertTrue(isValid)
    }

    func test_validateReview_failsWithIncompletePersonalInfo() {
        sut.currentStep = .review

        // Missing personal info
        sut.kycData.firstName = ""
        setupValidAddress()
        setupValidTaxInfo()
        sut.kycData.employmentStatus = .retired
        setupValidDisclosures()

        let isValid = sut.validateCurrentStep()

        XCTAssertFalse(isValid)
    }

    // MARK: - Navigation Tests

    func test_nextStep_advancesWhenValid() {
        setupValidPersonalInfo()

        sut.nextStep()

        XCTAssertEqual(sut.currentStep, .address)
    }

    func test_nextStep_doesNotAdvanceWhenInvalid() {
        // Leave data invalid
        sut.nextStep()

        XCTAssertEqual(sut.currentStep, .personalInfo)
    }

    func test_previousStep_goesBack() {
        sut.currentStep = .address

        sut.previousStep()

        XCTAssertEqual(sut.currentStep, .personalInfo)
    }

    func test_previousStep_doesNothingOnFirstStep() {
        XCTAssertEqual(sut.currentStep, .personalInfo)

        sut.previousStep()

        XCTAssertEqual(sut.currentStep, .personalInfo)
    }

    func test_goToStep_navigatesToSpecificStep() {
        sut.goToStep(.taxInfo)

        XCTAssertEqual(sut.currentStep, .taxInfo)
    }

    func test_nextStep_doesNotAdvancePastReview() {
        sut.currentStep = .review
        setupCompleteKYCData()

        sut.nextStep()

        XCTAssertEqual(sut.currentStep, .review)
    }

    // MARK: - Progress Tests

    func test_progress_calculatesCorrectly() {
        XCTAssertEqual(sut.progress, 0.0) // Step 0

        sut.currentStep = .address
        XCTAssertEqual(sut.progress, 0.2, accuracy: 0.01) // Step 1

        sut.currentStep = .taxInfo
        XCTAssertEqual(sut.progress, 0.4, accuracy: 0.01) // Step 2

        sut.currentStep = .employment
        XCTAssertEqual(sut.progress, 0.6, accuracy: 0.01) // Step 3

        sut.currentStep = .disclosures
        XCTAssertEqual(sut.progress, 0.8, accuracy: 0.01) // Step 4

        sut.currentStep = .review
        XCTAssertEqual(sut.progress, 1.0) // Step 5
    }

    // MARK: - Computed Properties Tests

    func test_isFirstStep_isTrueOnlyOnPersonalInfo() {
        XCTAssertTrue(sut.isFirstStep)

        sut.currentStep = .address
        XCTAssertFalse(sut.isFirstStep)

        sut.currentStep = .review
        XCTAssertFalse(sut.isFirstStep)
    }

    func test_isLastStep_isTrueOnlyOnReview() {
        XCTAssertFalse(sut.isLastStep)

        sut.currentStep = .disclosures
        XCTAssertFalse(sut.isLastStep)

        sut.currentStep = .review
        XCTAssertTrue(sut.isLastStep)
    }

    func test_canProceed_matchesValidation() {
        XCTAssertFalse(sut.canProceed)

        setupValidPersonalInfo()
        XCTAssertTrue(sut.canProceed)
    }

    // MARK: - Formatting Helpers Tests

    func test_formatPhoneNumber_formatsCorrectly() {
        let formatted = sut.formatPhoneNumber("1234567890")

        XCTAssertEqual(formatted, "(123) 456-7890")
    }

    func test_formatPhoneNumber_returnOriginalIfTooShort() {
        let formatted = sut.formatPhoneNumber("12345")

        XCTAssertEqual(formatted, "12345")
    }

    func test_formatTaxId_formatsCorrectly() {
        let formatted = sut.formatTaxId("123456789")

        XCTAssertEqual(formatted, "123-45-6789")
    }

    func test_formatTaxId_returnsOriginalIfInvalid() {
        let formatted = sut.formatTaxId("12345")

        XCTAssertEqual(formatted, "12345")
    }

    func test_maskedTaxId_masksCorrectly() {
        sut.kycData.taxId = "123456789"

        let masked = sut.maskedTaxId()

        XCTAssertEqual(masked, "***-**-6789")
    }

    func test_maskedTaxId_returnsPlaceholderIfInvalid() {
        sut.kycData.taxId = "12345"

        let masked = sut.maskedTaxId()

        XCTAssertEqual(masked, "***-**-****")
    }

    // MARK: - Validation Clears Previous Errors Tests

    func test_validateCurrentStep_clearsPreviousErrors() {
        // First validation - get some errors
        sut.kycData.firstName = ""
        _ = sut.validateCurrentStep()
        XCTAssertFalse(sut.validationErrors.isEmpty)

        // Second validation - fix all issues
        setupValidPersonalInfo()
        _ = sut.validateCurrentStep()

        XCTAssertTrue(sut.validationErrors.isEmpty)
    }

    // MARK: - Step Title and Subtitle Tests

    func test_stepTitles_areCorrect() {
        XCTAssertEqual(KYCViewModel.Step.personalInfo.title, "Personal Information")
        XCTAssertEqual(KYCViewModel.Step.address.title, "Address")
        XCTAssertEqual(KYCViewModel.Step.taxInfo.title, "Tax Information")
        XCTAssertEqual(KYCViewModel.Step.employment.title, "Employment")
        XCTAssertEqual(KYCViewModel.Step.disclosures.title, "Disclosures")
        XCTAssertEqual(KYCViewModel.Step.review.title, "Review")
    }

    func test_stepSubtitles_areCorrect() {
        XCTAssertEqual(KYCViewModel.Step.personalInfo.subtitle, "Let's start with your basic information")
        XCTAssertEqual(KYCViewModel.Step.address.subtitle, "Where do you live?")
        XCTAssertEqual(KYCViewModel.Step.taxInfo.subtitle, "Tax identification details")
        XCTAssertEqual(KYCViewModel.Step.employment.subtitle, "Tell us about your employment")
        XCTAssertEqual(KYCViewModel.Step.disclosures.subtitle, "Required agreements")
        XCTAssertEqual(KYCViewModel.Step.review.subtitle, "Review your information")
    }

    // MARK: - Helpers

    private func createDate(yearsAgo years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: -years, to: Date())!
    }

    private func setupValidPersonalInfo() {
        sut.kycData.firstName = "John"
        sut.kycData.lastName = "Doe"
        sut.kycData.dateOfBirth = createDate(yearsAgo: 25)
        sut.kycData.phoneNumber = "1234567890"
    }

    private func setupValidAddress() {
        sut.kycData.streetAddress = "123 Main Street"
        sut.kycData.city = "New York"
        sut.kycData.state = "NY"
        sut.kycData.postalCode = "10001"
    }

    private func setupValidTaxInfo() {
        sut.kycData.taxId = "123456789"
        sut.kycData.citizenship = "USA"
    }

    private func setupValidDisclosures() {
        sut.kycData.disclosuresAccepted = true
        sut.kycData.customerAgreementAccepted = true
        sut.kycData.accountAgreementAccepted = true
        sut.kycData.marketDataAgreementAccepted = true
    }

    private func setupCompleteKYCData() {
        setupValidPersonalInfo()
        setupValidAddress()
        setupValidTaxInfo()
        sut.kycData.employmentStatus = .employed
        sut.kycData.employer = "Acme Corp"
        sut.kycData.occupation = "Software Engineer"
        setupValidDisclosures()
    }
}
