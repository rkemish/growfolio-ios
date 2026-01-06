//
//  LedgerEntry.swift
//  Growfolio
//
//  Ledger entry domain model for tracking all financial transactions.
//

import Foundation

/// Represents a financial transaction in the portfolio ledger
struct LedgerEntry: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Portfolio ID this entry belongs to
    let portfolioId: String

    /// User ID who created this entry
    let userId: String

    /// Type of transaction
    var type: LedgerEntryType

    /// Stock symbol (if applicable)
    var stockSymbol: String?

    /// Stock name (if applicable)
    var stockName: String?

    /// Number of shares (for buy/sell transactions)
    var quantity: Decimal?

    /// Price per share at time of transaction
    var pricePerShare: Decimal?

    /// Total amount of the transaction
    var totalAmount: Decimal

    /// Fees associated with the transaction
    var fees: Decimal

    /// Currency code
    var currencyCode: String

    /// Date of the transaction
    var transactionDate: Date

    /// Optional notes
    var notes: String?

    /// Source of the transaction (manual, DCA, import, etc.)
    var source: LedgerEntrySource

    /// Reference ID for linked transactions (e.g., DCA schedule ID)
    var referenceId: String?

    /// Whether the entry is reconciled
    var isReconciled: Bool

    /// Date when the entry was created
    let createdAt: Date

    /// Date when the entry was last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        portfolioId: String,
        userId: String,
        type: LedgerEntryType,
        stockSymbol: String? = nil,
        stockName: String? = nil,
        quantity: Decimal? = nil,
        pricePerShare: Decimal? = nil,
        totalAmount: Decimal,
        fees: Decimal = 0,
        currencyCode: String = "USD",
        transactionDate: Date = Date(),
        notes: String? = nil,
        source: LedgerEntrySource = .manual,
        referenceId: String? = nil,
        isReconciled: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.portfolioId = portfolioId
        self.userId = userId
        self.type = type
        self.stockSymbol = stockSymbol
        self.stockName = stockName
        self.quantity = quantity
        self.pricePerShare = pricePerShare
        self.totalAmount = totalAmount
        self.fees = fees
        self.currencyCode = currencyCode
        self.transactionDate = transactionDate
        self.notes = notes
        self.source = source
        self.referenceId = referenceId
        self.isReconciled = isReconciled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Net amount (total minus fees)
    var netAmount: Decimal {
        switch type {
        case .buy, .withdrawal, .fee:
            return -(totalAmount + fees)
        case .sell, .deposit, .dividend, .interest:
            return totalAmount - fees
        case .transfer, .adjustment:
            return totalAmount
        }
    }

    /// Calculated total from quantity and price
    var calculatedTotal: Decimal? {
        guard let quantity = quantity, let price = pricePerShare else { return nil }
        return quantity * price
    }

    /// Display string for the transaction
    var displayDescription: String {
        switch type {
        case .buy:
            if let symbol = stockSymbol, let qty = quantity {
                return "Buy \(qty.sharesString) shares of \(symbol)"
            }
            return "Buy"
        case .sell:
            if let symbol = stockSymbol, let qty = quantity {
                return "Sell \(qty.sharesString) shares of \(symbol)"
            }
            return "Sell"
        case .deposit:
            return "Deposit"
        case .withdrawal:
            return "Withdrawal"
        case .dividend:
            if let symbol = stockSymbol {
                return "Dividend from \(symbol)"
            }
            return "Dividend"
        case .interest:
            return "Interest"
        case .fee:
            return "Fee"
        case .transfer:
            return "Transfer"
        case .adjustment:
            return "Adjustment"
        }
    }

    /// Whether this is a stock transaction
    var isStockTransaction: Bool {
        type == .buy || type == .sell
    }

    /// Whether this affects cash balance
    var affectsCash: Bool {
        type != .adjustment
    }

    /// Sign for display (+/-)
    var signPrefix: String {
        switch type {
        case .sell, .deposit, .dividend, .interest:
            return "+"
        case .buy, .withdrawal, .fee:
            return "-"
        case .transfer, .adjustment:
            return totalAmount >= 0 ? "+" : ""
        }
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case portfolioId
        case userId
        case type
        case stockSymbol
        case stockName
        case quantity
        case pricePerShare
        case totalAmount
        case fees
        case currencyCode
        case transactionDate
        case notes
        case source
        case referenceId
        case isReconciled
        case createdAt
        case updatedAt
    }
}

// MARK: - Ledger Entry Type

/// Types of ledger entries
enum LedgerEntryType: String, Codable, Sendable, CaseIterable {
    case buy
    case sell
    case deposit
    case withdrawal
    case dividend
    case interest
    case fee
    case transfer
    case adjustment

    var displayName: String {
        switch self {
        case .buy:
            return "Buy"
        case .sell:
            return "Sell"
        case .deposit:
            return "Deposit"
        case .withdrawal:
            return "Withdrawal"
        case .dividend:
            return "Dividend"
        case .interest:
            return "Interest"
        case .fee:
            return "Fee"
        case .transfer:
            return "Transfer"
        case .adjustment:
            return "Adjustment"
        }
    }

    var iconName: String {
        switch self {
        case .buy:
            return "arrow.down.circle.fill"
        case .sell:
            return "arrow.up.circle.fill"
        case .deposit:
            return "plus.circle.fill"
        case .withdrawal:
            return "minus.circle.fill"
        case .dividend:
            return "dollarsign.circle.fill"
        case .interest:
            return "percent"
        case .fee:
            return "creditcard.fill"
        case .transfer:
            return "arrow.left.arrow.right.circle.fill"
        case .adjustment:
            return "pencil.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .buy:
            return "#FF3B30"
        case .sell, .deposit, .dividend, .interest:
            return "#34C759"
        case .withdrawal, .fee:
            return "#FF9500"
        case .transfer:
            return "#007AFF"
        case .adjustment:
            return "#8E8E93"
        }
    }

    /// Whether this type requires a stock symbol
    var requiresStock: Bool {
        switch self {
        case .buy, .sell:
            return true
        case .dividend:
            return false // Optional for dividends
        default:
            return false
        }
    }

    /// Whether this type requires quantity
    var requiresQuantity: Bool {
        self == .buy || self == .sell
    }
}

// MARK: - Ledger Entry Source

/// Source of the ledger entry
enum LedgerEntrySource: String, Codable, Sendable {
    case manual
    case dca
    case `import`
    case sync
    case system

    var displayName: String {
        switch self {
        case .manual:
            return "Manual Entry"
        case .dca:
            return "DCA Schedule"
        case .import:
            return "Imported"
        case .sync:
            return "Synced"
        case .system:
            return "System"
        }
    }
}

// MARK: - Ledger Summary

/// Summary of ledger entries for a portfolio
struct LedgerSummary: Sendable {
    let totalTransactions: Int
    let totalBuys: Int
    let totalSells: Int
    let totalDeposits: Decimal
    let totalWithdrawals: Decimal
    let totalDividends: Decimal
    let totalFees: Decimal
    let netCashFlow: Decimal

    init(entries: [LedgerEntry]) {
        self.totalTransactions = entries.count
        self.totalBuys = entries.filter { $0.type == .buy }.count
        self.totalSells = entries.filter { $0.type == .sell }.count
        self.totalDeposits = entries.filter { $0.type == .deposit }.reduce(0) { $0 + $1.totalAmount }
        self.totalWithdrawals = entries.filter { $0.type == .withdrawal }.reduce(0) { $0 + $1.totalAmount }
        self.totalDividends = entries.filter { $0.type == .dividend }.reduce(0) { $0 + $1.totalAmount }
        self.totalFees = entries.filter { $0.type == .fee }.reduce(0) { $0 + $1.totalAmount }
        self.netCashFlow = entries.reduce(0) { $0 + $1.netAmount }
    }
}

// MARK: - Transaction Group

/// Group of transactions by date or category
struct TransactionGroup: Identifiable, Sendable {
    let id: String
    let title: String
    let entries: [LedgerEntry]
    let totalAmount: Decimal

    init(title: String, entries: [LedgerEntry]) {
        self.id = title
        self.title = title
        self.entries = entries
        self.totalAmount = entries.reduce(0) { $0 + $1.netAmount }
    }
}

// MARK: - Extensions

extension Array where Element == LedgerEntry {
    /// Group entries by date
    func groupedByDate() -> [TransactionGroup] {
        let grouped = Dictionary(grouping: self) { entry in
            entry.transactionDate.startOfDay
        }

        return grouped.map { date, entries in
            TransactionGroup(title: date.displayString, entries: entries.sorted { $0.transactionDate > $1.transactionDate })
        }.sorted { $0.entries.first?.transactionDate ?? Date() > $1.entries.first?.transactionDate ?? Date() }
    }

    /// Group entries by month
    func groupedByMonth() -> [TransactionGroup] {
        let grouped = Dictionary(grouping: self) { entry in
            entry.transactionDate.startOfMonth
        }

        return grouped.map { date, entries in
            TransactionGroup(title: date.monthYearString, entries: entries.sorted { $0.transactionDate > $1.transactionDate })
        }.sorted { $0.entries.first?.transactionDate ?? Date() > $1.entries.first?.transactionDate ?? Date() }
    }

    /// Group entries by type
    func groupedByType() -> [TransactionGroup] {
        let grouped = Dictionary(grouping: self) { entry in
            entry.type.displayName
        }

        return grouped.map { type, entries in
            TransactionGroup(title: type, entries: entries.sorted { $0.transactionDate > $1.transactionDate })
        }.sorted { $0.title < $1.title }
    }
}
