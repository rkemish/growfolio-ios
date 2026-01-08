//
//  FundingWallet.swift
//  Growfolio
//
//  Domain model for funding wallet (separate from trading account).
//

import Foundation

// MARK: - Funding Wallet Main Model

struct FundingWallet: Codable, Sendable, Equatable {
    let balance: Decimal
    let currency: String
    let pendingTransfers: [PendingTransfer]
    let fundingDetails: FundingDetails

    // MARK: - Computed Properties

    var hasBalance: Bool {
        balance > 0
    }

    var hasPendingTransfers: Bool {
        !pendingTransfers.isEmpty
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case balance
        case currency
        case pendingTransfers = "pending_transfers"
        case fundingDetails = "funding_details"
    }
}

// MARK: - Funding Details

struct FundingDetails: Codable, Sendable, Equatable {
    let accountNumber: String
    let routingNumber: String
    let swiftCode: String?
    let iban: String?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case accountNumber = "account_number"
        case routingNumber = "routing_number"
        case swiftCode = "swift_code"
        case iban
    }
}

// MARK: - Pending Transfer

struct PendingTransfer: Codable, Sendable, Equatable, Identifiable {
    let id: String
    let amount: Decimal
    let direction: TransferDirection
    let status: String
    let createdAt: Date

    // MARK: - Computed Properties

    var isPending: Bool {
        status == "pending"
    }

    var isIncoming: Bool {
        direction == .incoming
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case direction
        case status
        case createdAt = "created_at"
    }
}

// MARK: - Transfer Direction

enum TransferDirection: String, Codable, Sendable, CaseIterable {
    case incoming = "INCOMING"
    case outgoing = "OUTGOING"

    var displayName: String {
        switch self {
        case .incoming: return "Incoming"
        case .outgoing: return "Outgoing"
        }
    }

    var iconName: String {
        switch self {
        case .incoming: return "arrow.down.circle.fill"
        case .outgoing: return "arrow.up.circle.fill"
        }
    }
}

// MARK: - Recipient Bank Info

struct RecipientBankInfo: Codable, Sendable, Equatable {
    let bankName: String
    let accountNumber: String
    let routingNumber: String
    let accountType: String
    let wireInstructions: String?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case bankName = "bank_name"
        case accountNumber = "account_number"
        case routingNumber = "routing_number"
        case accountType = "account_type"
        case wireInstructions = "wire_instructions"
    }
}
