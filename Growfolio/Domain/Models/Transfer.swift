//
//  Transfer.swift
//  Growfolio
//
//  Domain model for deposit and withdrawal transfers.
//

import Foundation

/// Represents a funding transfer (deposit or withdrawal)
struct Transfer: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// User ID who initiated the transfer
    let userId: String

    /// Portfolio ID this transfer belongs to
    let portfolioId: String

    /// Type of transfer
    let type: TransferType

    /// Transfer status
    var status: TransferStatus

    /// Amount in source currency
    let amount: Decimal

    /// Source currency code
    let currency: String

    /// Converted amount in USD (for GBP transfers)
    let amountUSD: Decimal?

    /// FX rate used for conversion (if applicable)
    let fxRate: Decimal?

    /// Fees charged for the transfer
    let fees: Decimal

    /// Net amount after fees
    var netAmount: Decimal {
        amount - fees
    }

    /// Net amount in USD after fees
    var netAmountUSD: Decimal? {
        guard let amountUSD = amountUSD else { return nil }
        return amountUSD - fees
    }

    /// Bank account ID (masked)
    let bankAccountId: String?

    /// Reference number for the transfer
    let referenceNumber: String?

    /// Optional notes
    var notes: String?

    /// Date when the transfer was initiated
    let initiatedAt: Date

    /// Date when the transfer was completed (if applicable)
    var completedAt: Date?

    /// Expected completion date
    let expectedCompletionDate: Date?

    /// Failure reason (if status is failed)
    var failureReason: String?

    /// Date when the transfer was created
    let createdAt: Date

    /// Date when the transfer was last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        userId: String,
        portfolioId: String,
        type: TransferType,
        status: TransferStatus = .pending,
        amount: Decimal,
        currency: String = "GBP",
        amountUSD: Decimal? = nil,
        fxRate: Decimal? = nil,
        fees: Decimal = 0,
        bankAccountId: String? = nil,
        referenceNumber: String? = nil,
        notes: String? = nil,
        initiatedAt: Date = Date(),
        completedAt: Date? = nil,
        expectedCompletionDate: Date? = nil,
        failureReason: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.portfolioId = portfolioId
        self.type = type
        self.status = status
        self.amount = amount
        self.currency = currency
        self.amountUSD = amountUSD
        self.fxRate = fxRate
        self.fees = fees
        self.bankAccountId = bankAccountId
        self.referenceNumber = referenceNumber
        self.notes = notes
        self.initiatedAt = initiatedAt
        self.completedAt = completedAt
        self.expectedCompletionDate = expectedCompletionDate
        self.failureReason = failureReason
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Display description for the transfer
    var displayDescription: String {
        switch type {
        case .deposit:
            return "Deposit"
        case .withdrawal:
            return "Withdrawal"
        }
    }

    /// Display string for the amount
    var amountDisplayString: String {
        let sign = type == .deposit ? "+" : "-"
        return "\(sign)\(amount.currencyString(code: currency))"
    }

    /// Display string for USD amount
    var amountUSDDisplayString: String? {
        guard let usd = amountUSD else { return nil }
        let sign = type == .deposit ? "+" : "-"
        return "\(sign)\(usd.currencyString(code: "USD"))"
    }

    /// Whether FX conversion was applied
    var hasFXConversion: Bool {
        fxRate != nil && currency != "USD"
    }

    /// Whether the transfer is in a terminal state
    var isTerminal: Bool {
        status == .completed || status == .failed || status == .cancelled
    }

    /// Whether the transfer can be cancelled
    var canCancel: Bool {
        status == .pending || status == .processing
    }

    /// Time until expected completion
    var timeUntilCompletion: TimeInterval? {
        guard let expectedDate = expectedCompletionDate else { return nil }
        return expectedDate.timeIntervalSince(Date())
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case portfolioId
        case type
        case status
        case amount
        case currency
        case amountUSD = "amountUsd"
        case fxRate
        case fees
        case bankAccountId
        case referenceNumber
        case notes
        case initiatedAt
        case completedAt
        case expectedCompletionDate
        case failureReason
        case createdAt
        case updatedAt
    }
}

// MARK: - Transfer Type

/// Types of funding transfers
enum TransferType: String, Codable, Sendable, CaseIterable {
    case deposit
    case withdrawal

    var displayName: String {
        switch self {
        case .deposit:
            return "Deposit"
        case .withdrawal:
            return "Withdrawal"
        }
    }

    var iconName: String {
        switch self {
        case .deposit:
            return "arrow.down.circle.fill"
        case .withdrawal:
            return "arrow.up.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .deposit:
            return "#34C759" // Green
        case .withdrawal:
            return "#FF9500" // Orange
        }
    }

    var verb: String {
        switch self {
        case .deposit:
            return "deposited"
        case .withdrawal:
            return "withdrawn"
        }
    }
}

// MARK: - Transfer Status

/// Status of a funding transfer
enum TransferStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case processing
    case completed
    case failed
    case cancelled

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }

    var iconName: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .processing:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .pending:
            return "#FF9500" // Orange
        case .processing:
            return "#007AFF" // Blue
        case .completed:
            return "#34C759" // Green
        case .failed:
            return "#FF3B30" // Red
        case .cancelled:
            return "#8E8E93" // Gray
        }
    }

    /// Whether this status indicates success
    var isSuccess: Bool {
        self == .completed
    }

    /// Whether this status indicates an error
    var isError: Bool {
        self == .failed
    }

    /// Whether this status is still in progress
    var isInProgress: Bool {
        self == .pending || self == .processing
    }
}

// MARK: - Transfer History

/// Container for transfer history with summary statistics
struct TransferHistory: Sendable {
    let transfers: [Transfer]
    let totalDeposits: Decimal
    let totalWithdrawals: Decimal
    let pendingDeposits: Decimal
    let pendingWithdrawals: Decimal

    init(transfers: [Transfer]) {
        self.transfers = transfers

        self.totalDeposits = transfers
            .filter { $0.type == .deposit && $0.status == .completed }
            .reduce(0) { $0 + $1.amount }

        self.totalWithdrawals = transfers
            .filter { $0.type == .withdrawal && $0.status == .completed }
            .reduce(0) { $0 + $1.amount }

        self.pendingDeposits = transfers
            .filter { $0.type == .deposit && $0.status.isInProgress }
            .reduce(0) { $0 + $1.amount }

        self.pendingWithdrawals = transfers
            .filter { $0.type == .withdrawal && $0.status.isInProgress }
            .reduce(0) { $0 + $1.amount }
    }

    /// Net transfers (deposits - withdrawals)
    var netTransfers: Decimal {
        totalDeposits - totalWithdrawals
    }

    /// Total pending amount
    var totalPending: Decimal {
        pendingDeposits + pendingWithdrawals
    }

    /// Recent transfers (last 10)
    var recentTransfers: [Transfer] {
        Array(transfers.sorted { $0.initiatedAt > $1.initiatedAt }.prefix(10))
    }

    /// Pending transfers
    var pendingTransfers: [Transfer] {
        transfers.filter { $0.status.isInProgress }
    }

    /// Completed transfers
    var completedTransfers: [Transfer] {
        transfers.filter { $0.status == .completed }
    }
}

// MARK: - Transfer Group

/// Group of transfers by date
struct TransferGroup: Identifiable, Sendable {
    let id: String
    let title: String
    let transfers: [Transfer]

    init(title: String, transfers: [Transfer]) {
        self.id = title
        self.title = title
        self.transfers = transfers
    }
}

// MARK: - Extensions

extension Array where Element == Transfer {
    /// Group transfers by date
    func groupedByDate() -> [TransferGroup] {
        let grouped = Dictionary(grouping: self) { transfer in
            transfer.initiatedAt.startOfDay
        }

        return grouped.map { date, transfers in
            TransferGroup(
                title: date.displayString,
                transfers: transfers.sorted { $0.initiatedAt > $1.initiatedAt }
            )
        }.sorted { group1, group2 in
            guard let date1 = group1.transfers.first?.initiatedAt,
                  let date2 = group2.transfers.first?.initiatedAt else {
                return false
            }
            return date1 > date2
        }
    }

    /// Group transfers by month
    func groupedByMonth() -> [TransferGroup] {
        let grouped = Dictionary(grouping: self) { transfer in
            transfer.initiatedAt.startOfMonth
        }

        return grouped.map { date, transfers in
            TransferGroup(
                title: date.monthYearString,
                transfers: transfers.sorted { $0.initiatedAt > $1.initiatedAt }
            )
        }.sorted { group1, group2 in
            guard let date1 = group1.transfers.first?.initiatedAt,
                  let date2 = group2.transfers.first?.initiatedAt else {
                return false
            }
            return date1 > date2
        }
    }

    /// Filter by transfer type
    func filtered(by type: TransferType?) -> [Transfer] {
        guard let type = type else { return self }
        return filter { $0.type == type }
    }

    /// Filter by status
    func filtered(by status: TransferStatus?) -> [Transfer] {
        guard let status = status else { return self }
        return filter { $0.status == status }
    }
}
