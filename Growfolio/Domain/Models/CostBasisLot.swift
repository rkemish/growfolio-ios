//
//  CostBasisLot.swift
//  Growfolio
//
//  Individual purchase lot with cost basis tracking in both USD and GBP.
//

import Foundation

/// Represents a single purchase lot for cost basis tracking
struct CostBasisLot: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier (derived from date and shares for lot identification)
    var id: String {
        "\(date.iso8601String)-\(shares)"
    }

    /// Date of the purchase
    let date: Date

    /// Number of shares in this lot
    let shares: Decimal

    /// Price per share in USD at time of purchase
    let priceUsd: Decimal

    /// Total cost in USD for this lot
    let totalUsd: Decimal

    /// Total cost in GBP for this lot
    let totalGbp: Decimal

    /// FX rate (GBP/USD) at time of purchase
    let fxRate: Decimal

    // MARK: - Computed Properties

    /// Price per share in GBP (calculated from USD price and FX rate)
    var priceGbp: Decimal {
        guard fxRate > 0 else { return 0 }
        return priceUsd / fxRate
    }

    /// Days since purchase
    var daysSincePurchase: Int {
        date.daysSinceNow
    }

    /// Whether this lot qualifies as long-term (held > 365 days)
    /// For US tax purposes, long-term capital gains have preferential rates
    var isLongTerm: Bool {
        daysSincePurchase > 365
    }

    /// Holding period category for display
    var holdingPeriodCategory: HoldingPeriodCategory {
        if daysSincePurchase <= 365 {
            return .shortTerm
        } else {
            return .longTerm
        }
    }

    // MARK: - Initialization

    init(
        date: Date,
        shares: Decimal,
        priceUsd: Decimal,
        totalUsd: Decimal,
        totalGbp: Decimal,
        fxRate: Decimal
    ) {
        self.date = date
        self.shares = shares
        self.priceUsd = priceUsd
        self.totalUsd = totalUsd
        self.totalGbp = totalGbp
        self.fxRate = fxRate
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case date
        case shares
        case priceUsd
        case totalUsd
        case totalGbp
        case fxRate
    }
}

// MARK: - Holding Period Category

/// Tax-relevant holding period categories
enum HoldingPeriodCategory: String, Codable, Sendable {
    case shortTerm = "short_term"
    case longTerm = "long_term"

    var displayName: String {
        switch self {
        case .shortTerm:
            return "Short-Term"
        case .longTerm:
            return "Long-Term"
        }
    }

    var description: String {
        switch self {
        case .shortTerm:
            return "Held 1 year or less"
        case .longTerm:
            return "Held more than 1 year"
        }
    }

    var taxImplication: String {
        switch self {
        case .shortTerm:
            return "Taxed as ordinary income"
        case .longTerm:
            return "Preferential capital gains rates"
        }
    }
}

// MARK: - Array Extension

extension Array where Element == CostBasisLot {
    /// Group lots by holding period category
    func groupedByHoldingPeriod() -> [HoldingPeriodCategory: [CostBasisLot]] {
        Dictionary(grouping: self) { $0.holdingPeriodCategory }
    }

    /// Total shares across all lots
    var totalShares: Decimal {
        reduce(0) { $0 + $1.shares }
    }

    /// Total cost in USD across all lots
    var totalCostUsd: Decimal {
        reduce(0) { $0 + $1.totalUsd }
    }

    /// Total cost in GBP across all lots
    var totalCostGbp: Decimal {
        reduce(0) { $0 + $1.totalGbp }
    }

    /// Short-term lots (held <= 365 days)
    var shortTermLots: [CostBasisLot] {
        filter { !$0.isLongTerm }
    }

    /// Long-term lots (held > 365 days)
    var longTermLots: [CostBasisLot] {
        filter { $0.isLongTerm }
    }

    /// Sorted by date (most recent first)
    var sortedByDateDescending: [CostBasisLot] {
        sorted { $0.date > $1.date }
    }

    /// Sorted by date (oldest first)
    var sortedByDateAscending: [CostBasisLot] {
        sorted { $0.date < $1.date }
    }
}
