//
//  BankAccount.swift
//  Growfolio
//
//  Domain model for linked bank accounts.
//

import Foundation

// MARK: - Bank Account Type

enum BankAccountType: String, Codable, Sendable, CaseIterable {
    case checking
    case savings

    var displayName: String {
        switch self {
        case .checking: return "Checking"
        case .savings: return "Savings"
        }
    }

    var iconName: String {
        switch self {
        case .checking: return "creditcard"
        case .savings: return "banknote"
        }
    }
}

// MARK: - Bank Account Status

enum BankAccountStatus: String, Codable, Sendable, CaseIterable {
    case active
    case pending
    case closed
    case error

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .pending: return "Pending"
        case .closed: return "Closed"
        case .error: return "Error"
        }
    }

    var iconName: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .closed: return "xmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .active: return "#10B981"  // Green
        case .pending: return "#F59E0B"  // Amber
        case .closed: return "#6B7280"  // Gray
        case .error: return "#EF4444"  // Red
        }
    }
}

// MARK: - Bank Account Main Model

struct BankAccount: Identifiable, Codable, Sendable, Equatable, Hashable {
    // MARK: - Properties
    let id: String
    let relationshipId: String
    let userId: String
    let bankName: String
    let accountType: BankAccountType
    let accountNumberLast4: String
    let status: BankAccountStatus
    let capabilities: [String]
    let linkedAt: Date

    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        relationshipId: String,
        userId: String,
        bankName: String,
        accountType: BankAccountType,
        accountNumberLast4: String,
        status: BankAccountStatus,
        capabilities: [String] = [],
        linkedAt: Date = Date()
    ) {
        self.id = id
        self.relationshipId = relationshipId
        self.userId = userId
        self.bankName = bankName
        self.accountType = accountType
        self.accountNumberLast4 = accountNumberLast4
        self.status = status
        self.capabilities = capabilities
        self.linkedAt = linkedAt
    }

    // MARK: - Computed Properties

    var displayName: String {
        "\(bankName) ••••\(accountNumberLast4)"
    }

    var isActive: Bool {
        status == .active
    }

    var canDeposit: Bool {
        capabilities.contains("deposit")
    }

    var canWithdraw: Bool {
        capabilities.contains("withdraw")
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case relationshipId = "relationship_id"
        case userId = "user_id"
        case bankName = "bank_name"
        case accountType = "account_type"
        case accountNumberLast4 = "account_number_last4"
        case status
        case capabilities
        case linkedAt = "linked_at"
    }
}
