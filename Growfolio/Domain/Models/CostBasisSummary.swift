//
//  CostBasisSummary.swift
//  Growfolio
//
//  Summary of cost basis for a holding, including P&L calculations.
//

import Foundation

/// Complete cost basis summary for a stock holding
struct CostBasisSummary: Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Stock symbol
    let symbol: String

    /// Total shares held
    let totalShares: Decimal

    /// Total cost basis in USD
    let totalCostUsd: Decimal

    /// Total cost basis in GBP
    let totalCostGbp: Decimal

    /// Average cost per share in USD
    let averageCostUsd: Decimal

    /// Average cost per share in GBP
    let averageCostGbp: Decimal

    /// Individual purchase lots
    let lots: [CostBasisLot]

    /// Current market price per share in USD (optional, for P&L calculation)
    var currentPriceUsd: Decimal?

    /// Current FX rate for GBP conversion (optional)
    var currentFxRate: Decimal?

    // MARK: - Computed Properties - Current Values

    /// Current market value in USD
    var currentValueUsd: Decimal {
        guard let price = currentPriceUsd else { return 0 }
        return totalShares * price
    }

    /// Current market value in GBP
    var currentValueGbp: Decimal {
        guard let rate = currentFxRate, rate > 0 else { return 0 }
        return currentValueUsd / rate
    }

    // MARK: - Computed Properties - Unrealized P&L

    /// Unrealized profit/loss in USD
    var unrealizedPnlUsd: Decimal {
        currentValueUsd - totalCostUsd
    }

    /// Unrealized profit/loss in GBP
    var unrealizedPnlGbp: Decimal {
        currentValueGbp - totalCostGbp
    }

    /// Unrealized P&L percentage (based on USD cost)
    var unrealizedPnlPercentage: Decimal {
        // Avoid division by zero for positions with no cost basis
        guard totalCostUsd > 0 else { return 0 }
        return ((currentValueUsd - totalCostUsd) / totalCostUsd) * 100
    }

    /// Whether the position is currently profitable
    var isProfitable: Bool {
        unrealizedPnlUsd > 0
    }

    // MARK: - Computed Properties - Tax Analysis

    /// Number of lots
    var lotCount: Int {
        lots.count
    }

    /// Short-term lots (held <= 365 days)
    var shortTermLots: [CostBasisLot] {
        lots.shortTermLots
    }

    /// Long-term lots (held > 365 days)
    var longTermLots: [CostBasisLot] {
        lots.longTermLots
    }

    /// Total shares in short-term lots
    var shortTermShares: Decimal {
        shortTermLots.totalShares
    }

    /// Total shares in long-term lots
    var longTermShares: Decimal {
        longTermLots.totalShares
    }

    /// Short-term cost basis in USD
    var shortTermCostUsd: Decimal {
        shortTermLots.totalCostUsd
    }

    /// Long-term cost basis in USD
    var longTermCostUsd: Decimal {
        longTermLots.totalCostUsd
    }

    /// Short-term cost basis in GBP
    var shortTermCostGbp: Decimal {
        shortTermLots.totalCostGbp
    }

    /// Long-term cost basis in GBP
    var longTermCostGbp: Decimal {
        longTermLots.totalCostGbp
    }

    /// Unrealized short-term gain/loss in USD
    var shortTermUnrealizedPnlUsd: Decimal {
        guard let price = currentPriceUsd else { return 0 }
        let currentValue = shortTermShares * price
        return currentValue - shortTermCostUsd
    }

    /// Unrealized long-term gain/loss in USD
    var longTermUnrealizedPnlUsd: Decimal {
        guard let price = currentPriceUsd else { return 0 }
        let currentValue = longTermShares * price
        return currentValue - longTermCostUsd
    }

    /// Percentage of shares that are long-term
    var longTermPercentage: Decimal {
        guard totalShares > 0 else { return 0 }
        return (longTermShares / totalShares) * 100
    }

    /// Earliest purchase date
    var firstPurchaseDate: Date? {
        lots.min { $0.date < $1.date }?.date
    }

    /// Most recent purchase date
    var lastPurchaseDate: Date? {
        lots.max { $0.date < $1.date }?.date
    }

    /// Days since first purchase
    var holdingPeriodDays: Int? {
        firstPurchaseDate?.daysSinceNow
    }

    /// Average FX rate across all lots
    var averageFxRate: Decimal {
        guard !lots.isEmpty else { return 0 }
        let totalFx = lots.reduce(Decimal(0)) { $0 + $1.fxRate }
        return totalFx / Decimal(lots.count)
    }

    /// Weighted average FX rate (by cost)
    /// Calculates the average FX rate weighted by the USD cost of each lot
    /// This is more accurate than simple average when lot sizes vary significantly
    var weightedAverageFxRate: Decimal {
        guard totalCostUsd > 0 else { return 0 }
        // Sum of (FX rate * lot cost) for each lot
        let weightedSum = lots.reduce(Decimal(0)) { $0 + ($1.fxRate * $1.totalUsd) }
        return weightedSum / totalCostUsd
    }

    // MARK: - Initialization

    init(
        symbol: String,
        totalShares: Decimal,
        totalCostUsd: Decimal,
        totalCostGbp: Decimal,
        averageCostUsd: Decimal,
        averageCostGbp: Decimal,
        lots: [CostBasisLot],
        currentPriceUsd: Decimal? = nil,
        currentFxRate: Decimal? = nil
    ) {
        self.symbol = symbol
        self.totalShares = totalShares
        self.totalCostUsd = totalCostUsd
        self.totalCostGbp = totalCostGbp
        self.averageCostUsd = averageCostUsd
        self.averageCostGbp = averageCostGbp
        self.lots = lots
        self.currentPriceUsd = currentPriceUsd
        self.currentFxRate = currentFxRate
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case symbol
        case totalShares
        case totalCostUsd
        case totalCostGbp
        case averageCostUsd
        case averageCostGbp
        case lots
        case currentPriceUsd
        case currentFxRate
    }
}

// MARK: - Tax Summary

/// Summary of tax-relevant information for a holding
struct TaxSummary: Sendable {
    let shortTermShares: Decimal
    let longTermShares: Decimal
    let shortTermCostBasisUsd: Decimal
    let longTermCostBasisUsd: Decimal
    let shortTermUnrealizedGainUsd: Decimal
    let longTermUnrealizedGainUsd: Decimal

    var totalUnrealizedGainUsd: Decimal {
        shortTermUnrealizedGainUsd + longTermUnrealizedGainUsd
    }

    var hasLongTermHoldings: Bool {
        longTermShares > 0
    }

    var hasShortTermHoldings: Bool {
        shortTermShares > 0
    }

    init(from summary: CostBasisSummary) {
        self.shortTermShares = summary.shortTermShares
        self.longTermShares = summary.longTermShares
        self.shortTermCostBasisUsd = summary.shortTermCostUsd
        self.longTermCostBasisUsd = summary.longTermCostUsd
        self.shortTermUnrealizedGainUsd = summary.shortTermUnrealizedPnlUsd
        self.longTermUnrealizedGainUsd = summary.longTermUnrealizedPnlUsd
    }
}

// MARK: - CostBasisSummary + Mutating

extension CostBasisSummary {
    /// Returns a copy with updated market data
    func withMarketData(currentPrice: Decimal, fxRate: Decimal) -> CostBasisSummary {
        var copy = self
        copy.currentPriceUsd = currentPrice
        copy.currentFxRate = fxRate
        return copy
    }
}
