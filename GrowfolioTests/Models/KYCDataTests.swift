//
//  KYCDataTests.swift
//  GrowfolioTests
//
//  Tests for KYCData domain model.
//

import XCTest
@testable import Growfolio

final class KYCDataTests: XCTestCase {

    // MARK: - Default Values Tests

    func testKYCData_DefaultValues() {
        let kycData = KYCData()

        XCTAssertEqual(kycData.firstName, "")
        XCTAssertEqual(kycData.lastName, "")
        XCTAssertNil(kycData.dateOfBirth)
        XCTAssertEqual(kycData.phoneNumber, "")
        XCTAssertEqual(kycData.streetAddress, "")
        XCTAssertEqual(kycData.apartmentUnit, "")
        XCTAssertEqual(kycData.city, "")
        XCTAssertEqual(kycData.state, "")
        XCTAssertEqual(kycData.postalCode, "")
        XCTAssertEqual(kycData.country, "USA")
        XCTAssertEqual(kycData.taxIdType, .ssn)
        XCTAssertEqual(kycData.taxId, "")
        XCTAssertEqual(kycData.citizenship, "USA")
        XCTAssertEqual(kycData.taxCountry, "USA")
        XCTAssertEqual(kycData.employmentStatus, .employed)
        XCTAssertEqual(kycData.employer, "")
        XCTAssertEqual(kycData.occupation, "")
        XCTAssertEqual(kycData.fundingSource, .employmentIncome)
        XCTAssertFalse(kycData.disclosuresAccepted)
        XCTAssertFalse(kycData.customerAgreementAccepted)
        XCTAssertFalse(kycData.accountAgreementAccepted)
        XCTAssertFalse(kycData.marketDataAgreementAccepted)
    }

    // MARK: - TaxIdType Tests

    func testTaxIdType_DisplayName() {
        XCTAssertEqual(TaxIdType.ssn.displayName, "Social Security Number (SSN)")
        XCTAssertEqual(TaxIdType.itin.displayName, "Individual Taxpayer Identification Number (ITIN)")
    }

    func testTaxIdType_RawValue() {
        XCTAssertEqual(TaxIdType.ssn.rawValue, "USA_SSN")
        XCTAssertEqual(TaxIdType.itin.rawValue, "USA_ITIN")
    }

    func testTaxIdType_AllCases() {
        XCTAssertEqual(TaxIdType.allCases.count, 2)
    }

    // MARK: - EmploymentStatus Tests

    func testEmploymentStatus_DisplayName() {
        XCTAssertEqual(EmploymentStatus.employed.displayName, "Employed")
        XCTAssertEqual(EmploymentStatus.selfEmployed.displayName, "Self-Employed")
        XCTAssertEqual(EmploymentStatus.unemployed.displayName, "Unemployed")
        XCTAssertEqual(EmploymentStatus.retired.displayName, "Retired")
        XCTAssertEqual(EmploymentStatus.student.displayName, "Student")
    }

    func testEmploymentStatus_RawValue() {
        XCTAssertEqual(EmploymentStatus.employed.rawValue, "employed")
        XCTAssertEqual(EmploymentStatus.selfEmployed.rawValue, "self_employed")
        XCTAssertEqual(EmploymentStatus.unemployed.rawValue, "unemployed")
        XCTAssertEqual(EmploymentStatus.retired.rawValue, "retired")
        XCTAssertEqual(EmploymentStatus.student.rawValue, "student")
    }

    func testEmploymentStatus_AllCases() {
        XCTAssertEqual(EmploymentStatus.allCases.count, 5)
    }

    // MARK: - FundingSource Tests

    func testFundingSource_DisplayName() {
        XCTAssertEqual(FundingSource.employmentIncome.displayName, "Employment Income")
        XCTAssertEqual(FundingSource.investments.displayName, "Investments")
        XCTAssertEqual(FundingSource.inheritance.displayName, "Inheritance")
        XCTAssertEqual(FundingSource.businessIncome.displayName, "Business Income")
        XCTAssertEqual(FundingSource.savings.displayName, "Savings")
        XCTAssertEqual(FundingSource.family.displayName, "Family")
    }

    func testFundingSource_AllCases() {
        XCTAssertEqual(FundingSource.allCases.count, 6)
    }

    // MARK: - AnnualIncomeRange Tests

    func testAnnualIncomeRange_DisplayName() {
        XCTAssertEqual(AnnualIncomeRange.rangeLessThan25k.displayName, "Less than $25,000")
        XCTAssertEqual(AnnualIncomeRange.range25kTo50k.displayName, "$25,001 - $50,000")
        XCTAssertEqual(AnnualIncomeRange.range50kTo100k.displayName, "$50,001 - $100,000")
        XCTAssertEqual(AnnualIncomeRange.range100kTo200k.displayName, "$100,001 - $200,000")
        XCTAssertEqual(AnnualIncomeRange.range200kTo500k.displayName, "$200,001 - $500,000")
        XCTAssertEqual(AnnualIncomeRange.range500kTo1m.displayName, "$500,001 - $1,000,000")
        XCTAssertEqual(AnnualIncomeRange.rangeOver1m.displayName, "Over $1,000,000")
    }

    func testAnnualIncomeRange_AllCases() {
        XCTAssertEqual(AnnualIncomeRange.allCases.count, 7)
    }

    // MARK: - LiquidNetWorthRange Tests

    func testLiquidNetWorthRange_DisplayName() {
        XCTAssertEqual(LiquidNetWorthRange.rangeLessThan25k.displayName, "Less than $25,000")
        XCTAssertEqual(LiquidNetWorthRange.range25kTo50k.displayName, "$25,001 - $50,000")
        XCTAssertEqual(LiquidNetWorthRange.range50kTo100k.displayName, "$50,001 - $100,000")
        XCTAssertEqual(LiquidNetWorthRange.range100kTo200k.displayName, "$100,001 - $200,000")
        XCTAssertEqual(LiquidNetWorthRange.range200kTo500k.displayName, "$200,001 - $500,000")
        XCTAssertEqual(LiquidNetWorthRange.range500kTo1m.displayName, "$500,001 - $1,000,000")
        XCTAssertEqual(LiquidNetWorthRange.rangeOver1m.displayName, "Over $1,000,000")
    }

    func testLiquidNetWorthRange_AllCases() {
        XCTAssertEqual(LiquidNetWorthRange.allCases.count, 7)
    }

    // MARK: - TotalNetWorthRange Tests

    func testTotalNetWorthRange_DisplayName() {
        XCTAssertEqual(TotalNetWorthRange.rangeLessThan50k.displayName, "Less than $50,000")
        XCTAssertEqual(TotalNetWorthRange.range50kTo100k.displayName, "$50,001 - $100,000")
        XCTAssertEqual(TotalNetWorthRange.range100kTo200k.displayName, "$100,001 - $200,000")
        XCTAssertEqual(TotalNetWorthRange.range200kTo500k.displayName, "$200,001 - $500,000")
        XCTAssertEqual(TotalNetWorthRange.range500kTo1m.displayName, "$500,001 - $1,000,000")
        XCTAssertEqual(TotalNetWorthRange.range1mTo5m.displayName, "$1,000,001 - $5,000,000")
        XCTAssertEqual(TotalNetWorthRange.rangeOver5m.displayName, "Over $5,000,000")
    }

    func testTotalNetWorthRange_AllCases() {
        XCTAssertEqual(TotalNetWorthRange.allCases.count, 7)
    }

    // MARK: - USState Tests

    func testUSState_FullName() {
        XCTAssertEqual(USState.NY.fullName, "New York")
        XCTAssertEqual(USState.CA.fullName, "California")
        XCTAssertEqual(USState.TX.fullName, "Texas")
        XCTAssertEqual(USState.FL.fullName, "Florida")
        XCTAssertEqual(USState.DC.fullName, "District of Columbia")
    }

    func testUSState_AllCases() {
        XCTAssertEqual(USState.allCases.count, 51) // 50 states + DC
    }

    // MARK: - KYCStatus Tests

    func testKYCStatus_DisplayName() {
        XCTAssertEqual(KYCStatus.pending.displayName, "Pending Review")
        XCTAssertEqual(KYCStatus.approved.displayName, "Approved")
        XCTAssertEqual(KYCStatus.rejected.displayName, "Rejected")
        XCTAssertEqual(KYCStatus.actionRequired.displayName, "Action Required")
    }

    func testKYCStatus_RawValue() {
        XCTAssertEqual(KYCStatus.pending.rawValue, "PENDING")
        XCTAssertEqual(KYCStatus.approved.rawValue, "APPROVED")
        XCTAssertEqual(KYCStatus.rejected.rawValue, "REJECTED")
        XCTAssertEqual(KYCStatus.actionRequired.rawValue, "ACTION_REQUIRED")
    }

    // MARK: - KYCSubmissionResponse Tests

    func testKYCSubmissionResponse_Init() {
        let response = KYCSubmissionResponse(
            accountId: "account-123",
            status: .approved,
            message: "Account approved"
        )

        XCTAssertEqual(response.accountId, "account-123")
        XCTAssertEqual(response.status, .approved)
        XCTAssertEqual(response.message, "Account approved")
    }

    func testKYCSubmissionResponse_NilMessage() {
        let response = KYCSubmissionResponse(
            accountId: "account-123",
            status: .pending,
            message: nil
        )

        XCTAssertNil(response.message)
    }

    // MARK: - Completeness Validation Tests

    func testKYCData_PersonalInfoComplete() {
        var kycData = KYCData()
        kycData.firstName = "John"
        kycData.lastName = "Doe"
        kycData.dateOfBirth = Date()
        kycData.phoneNumber = "+1234567890"

        XCTAssertFalse(kycData.firstName.isEmpty)
        XCTAssertFalse(kycData.lastName.isEmpty)
        XCTAssertNotNil(kycData.dateOfBirth)
        XCTAssertFalse(kycData.phoneNumber.isEmpty)
    }

    func testKYCData_AddressComplete() {
        var kycData = KYCData()
        kycData.streetAddress = "123 Main St"
        kycData.city = "New York"
        kycData.state = "NY"
        kycData.postalCode = "10001"
        kycData.country = "USA"

        XCTAssertFalse(kycData.streetAddress.isEmpty)
        XCTAssertFalse(kycData.city.isEmpty)
        XCTAssertFalse(kycData.state.isEmpty)
        XCTAssertFalse(kycData.postalCode.isEmpty)
        XCTAssertFalse(kycData.country.isEmpty)
    }

    func testKYCData_TaxInfoComplete() {
        var kycData = KYCData()
        kycData.taxIdType = .ssn
        kycData.taxId = "123-45-6789"
        kycData.citizenship = "USA"
        kycData.taxCountry = "USA"

        XCTAssertEqual(kycData.taxIdType, .ssn)
        XCTAssertFalse(kycData.taxId.isEmpty)
        XCTAssertFalse(kycData.citizenship.isEmpty)
        XCTAssertFalse(kycData.taxCountry.isEmpty)
    }

    func testKYCData_AgreementsComplete() {
        var kycData = KYCData()
        kycData.disclosuresAccepted = true
        kycData.customerAgreementAccepted = true
        kycData.accountAgreementAccepted = true
        kycData.marketDataAgreementAccepted = true

        XCTAssertTrue(kycData.disclosuresAccepted)
        XCTAssertTrue(kycData.customerAgreementAccepted)
        XCTAssertTrue(kycData.accountAgreementAccepted)
        XCTAssertTrue(kycData.marketDataAgreementAccepted)
    }

    // MARK: - Codable Tests

    func testKYCData_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.kycData()

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(KYCData.self, from: data)

        XCTAssertEqual(decoded.firstName, original.firstName)
        XCTAssertEqual(decoded.lastName, original.lastName)
        XCTAssertEqual(decoded.phoneNumber, original.phoneNumber)
        XCTAssertEqual(decoded.streetAddress, original.streetAddress)
        XCTAssertEqual(decoded.city, original.city)
        XCTAssertEqual(decoded.state, original.state)
        XCTAssertEqual(decoded.postalCode, original.postalCode)
        XCTAssertEqual(decoded.country, original.country)
        XCTAssertEqual(decoded.taxIdType, original.taxIdType)
        XCTAssertEqual(decoded.taxId, original.taxId)
        XCTAssertEqual(decoded.employmentStatus, original.employmentStatus)
        XCTAssertEqual(decoded.fundingSource, original.fundingSource)
        XCTAssertEqual(decoded.annualIncome, original.annualIncome)
        XCTAssertEqual(decoded.liquidNetWorth, original.liquidNetWorth)
        XCTAssertEqual(decoded.totalNetWorth, original.totalNetWorth)
    }

    func testTaxIdType_Codable() throws {
        for type in TaxIdType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(TaxIdType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    func testEmploymentStatus_Codable() throws {
        for status in EmploymentStatus.allCases {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(EmploymentStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    func testFundingSource_Codable() throws {
        for source in FundingSource.allCases {
            let data = try JSONEncoder().encode(source)
            let decoded = try JSONDecoder().decode(FundingSource.self, from: data)
            XCTAssertEqual(decoded, source)
        }
    }

    func testAnnualIncomeRange_Codable() throws {
        for range in AnnualIncomeRange.allCases {
            let data = try JSONEncoder().encode(range)
            let decoded = try JSONDecoder().decode(AnnualIncomeRange.self, from: data)
            XCTAssertEqual(decoded, range)
        }
    }

    func testLiquidNetWorthRange_Codable() throws {
        for range in LiquidNetWorthRange.allCases {
            let data = try JSONEncoder().encode(range)
            let decoded = try JSONDecoder().decode(LiquidNetWorthRange.self, from: data)
            XCTAssertEqual(decoded, range)
        }
    }

    func testTotalNetWorthRange_Codable() throws {
        for range in TotalNetWorthRange.allCases {
            let data = try JSONEncoder().encode(range)
            let decoded = try JSONDecoder().decode(TotalNetWorthRange.self, from: data)
            XCTAssertEqual(decoded, range)
        }
    }

    func testUSState_Codable() throws {
        for state in USState.allCases {
            let data = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(USState.self, from: data)
            XCTAssertEqual(decoded, state)
        }
    }

    func testKYCStatus_Codable() throws {
        let statuses: [KYCStatus] = [.pending, .approved, .rejected, .actionRequired]
        for status in statuses {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(KYCStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    func testKYCSubmissionResponse_Codable() throws {
        let original = KYCSubmissionResponse(
            accountId: "account-123",
            status: .approved,
            message: "Your account has been approved"
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(KYCSubmissionResponse.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Equatable Tests

    func testKYCData_Equatable() {
        let kycData1 = TestFixtures.kycData(firstName: "John", lastName: "Doe")
        let kycData2 = TestFixtures.kycData(firstName: "John", lastName: "Doe")
        XCTAssertEqual(kycData1, kycData2)
    }

    func testKYCData_NotEqual_DifferentFirstName() {
        let kycData1 = TestFixtures.kycData(firstName: "John")
        let kycData2 = TestFixtures.kycData(firstName: "Jane")
        XCTAssertNotEqual(kycData1, kycData2)
    }

    func testKYCSubmissionResponse_Equatable() {
        let response1 = KYCSubmissionResponse(accountId: "a1", status: .approved, message: nil)
        let response2 = KYCSubmissionResponse(accountId: "a1", status: .approved, message: nil)
        XCTAssertEqual(response1, response2)
    }

    // MARK: - Edge Cases

    func testKYCData_EmptyStrings() {
        let kycData = KYCData()
        XCTAssertEqual(kycData.firstName, "")
        XCTAssertEqual(kycData.lastName, "")
        XCTAssertEqual(kycData.phoneNumber, "")
    }

    func testKYCData_SpecialCharactersInName() {
        var kycData = KYCData()
        kycData.firstName = "O'Brien"
        kycData.lastName = "Smith-Jones"
        XCTAssertEqual(kycData.firstName, "O'Brien")
        XCTAssertEqual(kycData.lastName, "Smith-Jones")
    }

    func testKYCData_InternationalPhoneNumber() {
        var kycData = KYCData()
        kycData.phoneNumber = "+44 20 7946 0958"
        XCTAssertEqual(kycData.phoneNumber, "+44 20 7946 0958")
    }

    func testKYCData_ApartmentUnitOptional() {
        var kycData = KYCData()
        kycData.streetAddress = "123 Main St"
        kycData.apartmentUnit = "" // Empty is valid

        XCTAssertEqual(kycData.apartmentUnit, "")
    }

    func testKYCData_WithApartmentUnit() {
        var kycData = KYCData()
        kycData.streetAddress = "123 Main St"
        kycData.apartmentUnit = "Apt 4B"

        XCTAssertEqual(kycData.apartmentUnit, "Apt 4B")
    }

    func testKYCData_AllEmploymentStatuses() {
        var kycData = KYCData()

        // Employed needs employer and occupation
        kycData.employmentStatus = .employed
        kycData.employer = "Acme Corp"
        kycData.occupation = "Engineer"
        XCTAssertEqual(kycData.employmentStatus, .employed)
        XCTAssertFalse(kycData.employer.isEmpty)
        XCTAssertFalse(kycData.occupation.isEmpty)

        // Self-employed also needs employer and occupation
        kycData.employmentStatus = .selfEmployed
        XCTAssertEqual(kycData.employmentStatus, .selfEmployed)

        // Unemployed doesn't need employer/occupation
        kycData.employmentStatus = .unemployed
        XCTAssertEqual(kycData.employmentStatus, .unemployed)

        // Retired doesn't need employer/occupation
        kycData.employmentStatus = .retired
        XCTAssertEqual(kycData.employmentStatus, .retired)

        // Student doesn't need employer/occupation
        kycData.employmentStatus = .student
        XCTAssertEqual(kycData.employmentStatus, .student)
    }
}
