//
//  KYCRepositoryTests.swift
//  GrowfolioTests
//
//  Tests for KYCRepository.
//

import XCTest
@testable import Growfolio

final class KYCRepositoryTests: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var sut: KYCRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = KYCRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        mockAPIClient.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeKYCData(
        firstName: String = "John",
        lastName: String = "Doe",
        dateOfBirth: Date? = Calendar.current.date(byAdding: .year, value: -30, to: Date()),
        phoneNumber: String = "+1234567890",
        streetAddress: String = "123 Main St",
        city: String = "New York",
        state: String = "NY",
        postalCode: String = "10001",
        country: String = "USA",
        taxId: String = "123-45-6789",
        employmentStatus: EmploymentStatus = .employed,
        employer: String = "Acme Corp",
        disclosuresAccepted: Bool = true
    ) -> KYCData {
        var data = KYCData()
        data.firstName = firstName
        data.lastName = lastName
        data.dateOfBirth = dateOfBirth
        data.phoneNumber = phoneNumber
        data.streetAddress = streetAddress
        data.city = city
        data.state = state
        data.postalCode = postalCode
        data.country = country
        data.taxId = taxId
        data.employmentStatus = employmentStatus
        data.employer = employer
        data.disclosuresAccepted = disclosuresAccepted
        data.customerAgreementAccepted = true
        data.accountAgreementAccepted = true
        data.marketDataAgreementAccepted = true
        return data
    }

    private func makeKYCSubmissionResponse(
        accountId: String = "account-123",
        status: KYCStatus = .pending,
        message: String? = "Your application is being reviewed."
    ) -> KYCSubmissionResponse {
        KYCSubmissionResponse(
            accountId: accountId,
            status: status,
            message: message
        )
    }

    // MARK: - Submit KYC Tests

    func test_submitKYC_returnsSubmissionResponse() async throws {
        // Arrange
        let kycData = makeKYCData()
        let expectedResponse = makeKYCSubmissionResponse(
            accountId: "new-account-123",
            status: .pending
        )
        mockAPIClient.setResponse(expectedResponse, for: Endpoints.SubmitKYC.self)

        // Act
        let response = try await sut.submitKYC(data: kycData, email: "john@example.com")

        // Assert
        XCTAssertEqual(response.accountId, "new-account-123")
        XCTAssertEqual(response.status, .pending)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_submitKYC_returnsApprovedStatus() async throws {
        // Arrange
        let kycData = makeKYCData()
        let expectedResponse = makeKYCSubmissionResponse(
            accountId: "approved-account",
            status: .approved,
            message: "Your account has been approved."
        )
        mockAPIClient.setResponse(expectedResponse, for: Endpoints.SubmitKYC.self)

        // Act
        let response = try await sut.submitKYC(data: kycData, email: "john@example.com")

        // Assert
        XCTAssertEqual(response.status, .approved)
        XCTAssertEqual(response.message, "Your account has been approved.")
    }

    func test_submitKYC_returnsRejectedStatus() async throws {
        // Arrange
        let kycData = makeKYCData()
        let expectedResponse = makeKYCSubmissionResponse(
            accountId: "rejected-account",
            status: .rejected,
            message: "Your application was rejected due to verification failure."
        )
        mockAPIClient.setResponse(expectedResponse, for: Endpoints.SubmitKYC.self)

        // Act
        let response = try await sut.submitKYC(data: kycData, email: "john@example.com")

        // Assert
        XCTAssertEqual(response.status, .rejected)
    }

    func test_submitKYC_returnsActionRequiredStatus() async throws {
        // Arrange
        let kycData = makeKYCData()
        let expectedResponse = makeKYCSubmissionResponse(
            accountId: "action-required-account",
            status: .actionRequired,
            message: "Additional documentation is required."
        )
        mockAPIClient.setResponse(expectedResponse, for: Endpoints.SubmitKYC.self)

        // Act
        let response = try await sut.submitKYC(data: kycData, email: "john@example.com")

        // Assert
        XCTAssertEqual(response.status, .actionRequired)
    }

    func test_submitKYC_throwsOnServerError() async {
        // Arrange
        let kycData = makeKYCData()
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Internal error"), for: Endpoints.SubmitKYC.self)

        // Act & Assert
        do {
            _ = try await sut.submitKYC(data: kycData, email: "john@example.com")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    func test_submitKYC_throwsOnClientError() async {
        // Arrange
        let kycData = makeKYCData()
        mockAPIClient.setError(NetworkError.clientError(statusCode: 400, message: "Invalid data"), for: Endpoints.SubmitKYC.self)

        // Act & Assert
        do {
            _ = try await sut.submitKYC(data: kycData, email: "john@example.com")
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .clientError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 400)
            } else {
                XCTFail("Expected clientError")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_submitKYC_throwsOnUnauthorized() async {
        // Arrange
        let kycData = makeKYCData()
        mockAPIClient.setError(NetworkError.unauthorized, for: Endpoints.SubmitKYC.self)

        // Act & Assert
        do {
            _ = try await sut.submitKYC(data: kycData, email: "john@example.com")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .unauthorized)
        }
    }

    // MARK: - Get KYC Status Tests

    func test_getKYCStatus_returnsStatusFromAPI() async throws {
        // Arrange
        let expectedResponse = makeKYCSubmissionResponse(
            accountId: "existing-account",
            status: .pending
        )
        mockAPIClient.setResponse(expectedResponse, for: Endpoints.GetKYCStatus.self)

        // Act
        let response = try await sut.getKYCStatus()

        // Assert
        XCTAssertEqual(response.accountId, "existing-account")
        XCTAssertEqual(response.status, .pending)
    }

    func test_getKYCStatus_returnsApprovedStatus() async throws {
        // Arrange
        let expectedResponse = makeKYCSubmissionResponse(
            accountId: "approved-account",
            status: .approved
        )
        mockAPIClient.setResponse(expectedResponse, for: Endpoints.GetKYCStatus.self)

        // Act
        let response = try await sut.getKYCStatus()

        // Assert
        XCTAssertEqual(response.status, .approved)
    }

    func test_getKYCStatus_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Error"), for: Endpoints.GetKYCStatus.self)

        // Act & Assert
        do {
            _ = try await sut.getKYCStatus()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    func test_getKYCStatus_throwsOnNotFound() async {
        // Arrange
        mockAPIClient.setError(NetworkError.notFound, for: Endpoints.GetKYCStatus.self)

        // Act & Assert
        do {
            _ = try await sut.getKYCStatus()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .notFound)
        }
    }

    // MARK: - KYCData Validation Tests

    func test_kycData_containsAllRequiredFields() {
        // Arrange
        let kycData = makeKYCData()

        // Assert
        XCTAssertFalse(kycData.firstName.isEmpty)
        XCTAssertFalse(kycData.lastName.isEmpty)
        XCTAssertNotNil(kycData.dateOfBirth)
        XCTAssertFalse(kycData.phoneNumber.isEmpty)
        XCTAssertFalse(kycData.streetAddress.isEmpty)
        XCTAssertFalse(kycData.city.isEmpty)
        XCTAssertFalse(kycData.state.isEmpty)
        XCTAssertFalse(kycData.postalCode.isEmpty)
        XCTAssertFalse(kycData.taxId.isEmpty)
    }

    func test_kycData_defaultValues() {
        // Arrange
        let kycData = KYCData()

        // Assert - Check default values
        XCTAssertEqual(kycData.country, "USA")
        XCTAssertEqual(kycData.taxIdType, .ssn)
        XCTAssertEqual(kycData.citizenship, "USA")
        XCTAssertEqual(kycData.taxCountry, "USA")
        XCTAssertEqual(kycData.employmentStatus, .employed)
        XCTAssertEqual(kycData.fundingSource, .employmentIncome)
    }

    // MARK: - KYCSubmissionRequest Tests

    func test_kycSubmissionRequest_initFromKYCData() {
        // Arrange
        let kycData = makeKYCData(
            firstName: "Jane",
            lastName: "Smith",
            streetAddress: "456 Oak Ave",
            city: "Los Angeles",
            state: "CA",
            postalCode: "90001"
        )

        // Act
        let request = KYCSubmissionRequest(
            from: kycData,
            email: "jane@example.com",
            ipAddress: "192.168.1.1"
        )

        // Assert
        XCTAssertEqual(request.contact.emailAddress, "jane@example.com")
        XCTAssertEqual(request.contact.city, "Los Angeles")
        XCTAssertEqual(request.contact.state, "CA")
        XCTAssertEqual(request.identity.givenName, "Jane")
        XCTAssertEqual(request.identity.familyName, "Smith")
    }

    func test_kycSubmissionRequest_includesApartmentUnit() {
        // Arrange
        var kycData = makeKYCData()
        kycData.apartmentUnit = "Apt 5B"

        // Act
        let request = KYCSubmissionRequest(
            from: kycData,
            email: "test@example.com",
            ipAddress: "0.0.0.0"
        )

        // Assert
        XCTAssertEqual(request.contact.streetAddress.count, 2)
        XCTAssertEqual(request.contact.streetAddress[1], "Apt 5B")
    }

    func test_kycSubmissionRequest_excludesEmployerForUnemployed() {
        // Arrange
        var kycData = makeKYCData()
        kycData.employmentStatus = .unemployed
        kycData.employer = "Previous Employer"
        kycData.occupation = "Previous Job"

        // Act
        let request = KYCSubmissionRequest(
            from: kycData,
            email: "test@example.com",
            ipAddress: "0.0.0.0"
        )

        // Assert
        XCTAssertNil(request.disclosures.employerName)
        XCTAssertNil(request.disclosures.employmentPosition)
    }

    func test_kycSubmissionRequest_includesEmployerForEmployed() {
        // Arrange
        var kycData = makeKYCData()
        kycData.employmentStatus = .employed
        kycData.employer = "Tech Company"
        kycData.occupation = "Engineer"

        // Act
        let request = KYCSubmissionRequest(
            from: kycData,
            email: "test@example.com",
            ipAddress: "0.0.0.0"
        )

        // Assert
        XCTAssertEqual(request.disclosures.employerName, "Tech Company")
        XCTAssertEqual(request.disclosures.employmentPosition, "Engineer")
    }

    func test_kycSubmissionRequest_includesAgreements() {
        // Arrange
        let kycData = makeKYCData()

        // Act
        let request = KYCSubmissionRequest(
            from: kycData,
            email: "test@example.com",
            ipAddress: "192.168.1.1"
        )

        // Assert
        XCTAssertEqual(request.agreements.count, 3)
        let agreementTypes = request.agreements.map { $0.agreementType }
        XCTAssertTrue(agreementTypes.contains("customer_agreement"))
        XCTAssertTrue(agreementTypes.contains("account_agreement"))
        XCTAssertTrue(agreementTypes.contains("margin_agreement"))
    }

    // MARK: - KYCStatus Tests

    func test_kycStatus_displayNames() {
        // Assert
        XCTAssertEqual(KYCStatus.pending.displayName, "Pending Review")
        XCTAssertEqual(KYCStatus.approved.displayName, "Approved")
        XCTAssertEqual(KYCStatus.rejected.displayName, "Rejected")
        XCTAssertEqual(KYCStatus.actionRequired.displayName, "Action Required")
    }

    // MARK: - KYCRepositoryError Tests

    func test_kycRepositoryError_descriptions() {
        // Assert
        XCTAssertNotNil(KYCRepositoryError.invalidData("test").errorDescription)
        XCTAssertNotNil(KYCRepositoryError.submissionFailed("test").errorDescription)
        XCTAssertNotNil(KYCRepositoryError.statusCheckFailed.errorDescription)
    }

    // MARK: - Edge Cases

    func test_submitKYC_withMinimalData() async throws {
        // Arrange
        var kycData = KYCData()
        kycData.firstName = "A"
        kycData.lastName = "B"
        kycData.phoneNumber = "1"
        kycData.streetAddress = "1"
        kycData.city = "C"
        kycData.state = "NY"
        kycData.postalCode = "10001"
        kycData.taxId = "123456789"

        let expectedResponse = makeKYCSubmissionResponse()
        mockAPIClient.setResponse(expectedResponse, for: Endpoints.SubmitKYC.self)

        // Act
        let response = try await sut.submitKYC(data: kycData, email: "test@example.com")

        // Assert
        XCTAssertEqual(response.status, .pending)
    }

    func test_submitKYC_withAllEmploymentStatuses() async throws {
        // Arrange
        let expectedResponse = makeKYCSubmissionResponse()
        mockAPIClient.setResponse(expectedResponse, for: Endpoints.SubmitKYC.self)

        let statuses: [EmploymentStatus] = [.employed, .selfEmployed, .unemployed, .retired, .student]

        for status in statuses {
            var kycData = makeKYCData()
            kycData.employmentStatus = status

            // Act
            let response = try await sut.submitKYC(data: kycData, email: "test@example.com")

            // Assert
            XCTAssertEqual(response.status, .pending)
        }
    }

    func test_submitKYC_withDifferentTaxIdTypes() async throws {
        // Arrange
        let expectedResponse = makeKYCSubmissionResponse()
        mockAPIClient.setResponse(expectedResponse, for: Endpoints.SubmitKYC.self)

        var kycDataSSN = makeKYCData()
        kycDataSSN.taxIdType = .ssn

        var kycDataITIN = makeKYCData()
        kycDataITIN.taxIdType = .itin

        // Act & Assert - Both should succeed
        let responseSSN = try await sut.submitKYC(data: kycDataSSN, email: "test@example.com")
        XCTAssertEqual(responseSSN.status, .pending)

        let responseITIN = try await sut.submitKYC(data: kycDataITIN, email: "test@example.com")
        XCTAssertEqual(responseITIN.status, .pending)
    }
}
