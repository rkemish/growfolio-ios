//
//  KYCData.swift
//  Growfolio
//
//  KYC data models for Alpaca brokerage account creation.
//

import Foundation

struct KYCData: Codable, Sendable, Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: Date?
    var phoneNumber: String = ""

    var streetAddress: String = ""
    var apartmentUnit: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
    var country: String = "USA"

    var taxIdType: TaxIdType = .ssn
    var taxId: String = ""
    var citizenship: String = "USA"
    var taxCountry: String = "USA"

    var employmentStatus: EmploymentStatus = .employed
    var employer: String = ""
    var occupation: String = ""

    var fundingSource: FundingSource = .employmentIncome
    var annualIncome: AnnualIncomeRange = .range50kTo100k
    var liquidNetWorth: LiquidNetWorthRange = .range50kTo100k
    var totalNetWorth: TotalNetWorthRange = .range100kTo200k

    var disclosuresAccepted: Bool = false
    var customerAgreementAccepted: Bool = false
    var accountAgreementAccepted: Bool = false
    var marketDataAgreementAccepted: Bool = false
}

// MARK: - Supporting Types

enum TaxIdType: String, Codable, Sendable, CaseIterable {
    case ssn = "USA_SSN"
    case itin = "USA_ITIN"

    var displayName: String {
        switch self {
        case .ssn: return "Social Security Number (SSN)"
        case .itin: return "Individual Taxpayer Identification Number (ITIN)"
        }
    }
}

enum EmploymentStatus: String, Codable, Sendable, CaseIterable {
    case employed = "employed"
    case selfEmployed = "self_employed"
    case unemployed = "unemployed"
    case retired = "retired"
    case student = "student"

    var displayName: String {
        switch self {
        case .employed: return "Employed"
        case .selfEmployed: return "Self-Employed"
        case .unemployed: return "Unemployed"
        case .retired: return "Retired"
        case .student: return "Student"
        }
    }
}

enum FundingSource: String, Codable, Sendable, CaseIterable {
    case employmentIncome = "employment_income"
    case investments = "investments"
    case inheritance = "inheritance"
    case businessIncome = "business_income"
    case savings = "savings"
    case family = "family"

    var displayName: String {
        switch self {
        case .employmentIncome: return "Employment Income"
        case .investments: return "Investments"
        case .inheritance: return "Inheritance"
        case .businessIncome: return "Business Income"
        case .savings: return "Savings"
        case .family: return "Family"
        }
    }
}

enum AnnualIncomeRange: String, Codable, Sendable, CaseIterable {
    case rangeLessThan25k = "0-25000"
    case range25kTo50k = "25001-50000"
    case range50kTo100k = "50001-100000"
    case range100kTo200k = "100001-200000"
    case range200kTo500k = "200001-500000"
    case range500kTo1m = "500001-1000000"
    case rangeOver1m = "1000001+"

    var displayName: String {
        switch self {
        case .rangeLessThan25k: return "Less than $25,000"
        case .range25kTo50k: return "$25,001 - $50,000"
        case .range50kTo100k: return "$50,001 - $100,000"
        case .range100kTo200k: return "$100,001 - $200,000"
        case .range200kTo500k: return "$200,001 - $500,000"
        case .range500kTo1m: return "$500,001 - $1,000,000"
        case .rangeOver1m: return "Over $1,000,000"
        }
    }
}

enum LiquidNetWorthRange: String, Codable, Sendable, CaseIterable {
    case rangeLessThan25k = "0-25000"
    case range25kTo50k = "25001-50000"
    case range50kTo100k = "50001-100000"
    case range100kTo200k = "100001-200000"
    case range200kTo500k = "200001-500000"
    case range500kTo1m = "500001-1000000"
    case rangeOver1m = "1000001+"

    var displayName: String {
        switch self {
        case .rangeLessThan25k: return "Less than $25,000"
        case .range25kTo50k: return "$25,001 - $50,000"
        case .range50kTo100k: return "$50,001 - $100,000"
        case .range100kTo200k: return "$100,001 - $200,000"
        case .range200kTo500k: return "$200,001 - $500,000"
        case .range500kTo1m: return "$500,001 - $1,000,000"
        case .rangeOver1m: return "Over $1,000,000"
        }
    }
}

enum TotalNetWorthRange: String, Codable, Sendable, CaseIterable {
    case rangeLessThan50k = "0-50000"
    case range50kTo100k = "50001-100000"
    case range100kTo200k = "100001-200000"
    case range200kTo500k = "200001-500000"
    case range500kTo1m = "500001-1000000"
    case range1mTo5m = "1000001-5000000"
    case rangeOver5m = "5000001+"

    var displayName: String {
        switch self {
        case .rangeLessThan50k: return "Less than $50,000"
        case .range50kTo100k: return "$50,001 - $100,000"
        case .range100kTo200k: return "$100,001 - $200,000"
        case .range200kTo500k: return "$200,001 - $500,000"
        case .range500kTo1m: return "$500,001 - $1,000,000"
        case .range1mTo5m: return "$1,000,001 - $5,000,000"
        case .rangeOver5m: return "Over $5,000,000"
        }
    }
}

// MARK: - US States

enum USState: String, Codable, Sendable, CaseIterable {
    case AL, AK, AZ, AR, CA, CO, CT, DE, FL, GA
    case HI, ID, IL, IN, IA, KS, KY, LA, ME, MD
    case MA, MI, MN, MS, MO, MT, NE, NV, NH, NJ
    case NM, NY, NC, ND, OH, OK, OR, PA, RI, SC
    case SD, TN, TX, UT, VT, VA, WA, WV, WI, WY
    case DC

    var fullName: String {
        switch self {
        case .AL: return "Alabama"
        case .AK: return "Alaska"
        case .AZ: return "Arizona"
        case .AR: return "Arkansas"
        case .CA: return "California"
        case .CO: return "Colorado"
        case .CT: return "Connecticut"
        case .DE: return "Delaware"
        case .FL: return "Florida"
        case .GA: return "Georgia"
        case .HI: return "Hawaii"
        case .ID: return "Idaho"
        case .IL: return "Illinois"
        case .IN: return "Indiana"
        case .IA: return "Iowa"
        case .KS: return "Kansas"
        case .KY: return "Kentucky"
        case .LA: return "Louisiana"
        case .ME: return "Maine"
        case .MD: return "Maryland"
        case .MA: return "Massachusetts"
        case .MI: return "Michigan"
        case .MN: return "Minnesota"
        case .MS: return "Mississippi"
        case .MO: return "Missouri"
        case .MT: return "Montana"
        case .NE: return "Nebraska"
        case .NV: return "Nevada"
        case .NH: return "New Hampshire"
        case .NJ: return "New Jersey"
        case .NM: return "New Mexico"
        case .NY: return "New York"
        case .NC: return "North Carolina"
        case .ND: return "North Dakota"
        case .OH: return "Ohio"
        case .OK: return "Oklahoma"
        case .OR: return "Oregon"
        case .PA: return "Pennsylvania"
        case .RI: return "Rhode Island"
        case .SC: return "South Carolina"
        case .SD: return "South Dakota"
        case .TN: return "Tennessee"
        case .TX: return "Texas"
        case .UT: return "Utah"
        case .VT: return "Vermont"
        case .VA: return "Virginia"
        case .WA: return "Washington"
        case .WV: return "West Virginia"
        case .WI: return "Wisconsin"
        case .WY: return "Wyoming"
        case .DC: return "District of Columbia"
        }
    }
}

// MARK: - KYC Submission Response

struct KYCSubmissionResponse: Codable, Sendable, Equatable {
    let accountId: String
    let status: KYCStatus
    let message: String?
}

enum KYCStatus: String, Codable, Sendable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case actionRequired = "ACTION_REQUIRED"

    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .actionRequired: return "Action Required"
        }
    }
}

// MARK: - KYC Request DTO

struct KYCSubmissionRequest: Codable, Sendable {
    let contact: Contact
    let identity: Identity
    let disclosures: Disclosures
    let agreements: [Agreement]

    struct Contact: Codable, Sendable {
        let emailAddress: String
        let phoneNumber: String
        let streetAddress: [String]
        let city: String
        let state: String
        let postalCode: String
        let country: String
    }

    struct Identity: Codable, Sendable {
        let givenName: String
        let familyName: String
        let dateOfBirth: String
        let taxId: String
        let taxIdType: String
        let countryOfCitizenship: String
        let countryOfTax: String
        let fundingSource: [String]
    }

    struct Disclosures: Codable, Sendable {
        let isControlPerson: Bool
        let isAffiliatedExchangeOrFinra: Bool
        let isPoliticallyExposed: Bool
        let immediateFamilyExposed: Bool
        let employmentStatus: String
        let employerName: String?
        let employerAddress: String?
        let employmentPosition: String?
    }

    struct Agreement: Codable, Sendable {
        let agreementType: String
        let signedAt: String
        let ipAddress: String
    }

    init(from kycData: KYCData, email: String, ipAddress: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let isoFormatter = ISO8601DateFormatter()
        let signedAt = isoFormatter.string(from: Date())

        var streetAddress = [kycData.streetAddress]
        if !kycData.apartmentUnit.isEmpty {
            streetAddress.append(kycData.apartmentUnit)
        }

        self.contact = Contact(
            emailAddress: email,
            phoneNumber: kycData.phoneNumber,
            streetAddress: streetAddress,
            city: kycData.city,
            state: kycData.state,
            postalCode: kycData.postalCode,
            country: kycData.country
        )

        self.identity = Identity(
            givenName: kycData.firstName,
            familyName: kycData.lastName,
            dateOfBirth: kycData.dateOfBirth.map { dateFormatter.string(from: $0) } ?? "",
            taxId: kycData.taxId,
            taxIdType: kycData.taxIdType.rawValue,
            countryOfCitizenship: kycData.citizenship,
            countryOfTax: kycData.taxCountry,
            fundingSource: [kycData.fundingSource.rawValue]
        )

        self.disclosures = Disclosures(
            isControlPerson: false,
            isAffiliatedExchangeOrFinra: false,
            isPoliticallyExposed: false,
            immediateFamilyExposed: false,
            employmentStatus: kycData.employmentStatus.rawValue,
            employerName: kycData.employmentStatus == .employed || kycData.employmentStatus == .selfEmployed ? kycData.employer : nil,
            employerAddress: nil,
            employmentPosition: kycData.employmentStatus == .employed || kycData.employmentStatus == .selfEmployed ? kycData.occupation : nil
        )

        self.agreements = [
            Agreement(agreementType: "customer_agreement", signedAt: signedAt, ipAddress: ipAddress),
            Agreement(agreementType: "account_agreement", signedAt: signedAt, ipAddress: ipAddress),
            Agreement(agreementType: "margin_agreement", signedAt: signedAt, ipAddress: ipAddress)
        ]
    }
}
