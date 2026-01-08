//
//  Holding.swift
//  Growfolio
//
//  Portfolio holding domain model.
//

import Foundation

/// Represents a stock holding within a portfolio
struct Holding: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Portfolio ID this holding belongs to
    let portfolioId: String

    /// Stock symbol
    let stockSymbol: String

    /// Stock name
    var stockName: String?

    /// Number of shares owned
    var quantity: Decimal

    /// Average cost per share
    var averageCostPerShare: Decimal

    /// Current price per share
    var currentPricePerShare: Decimal

    /// Date of the first purchase
    var firstPurchaseDate: Date?

    /// Date of the most recent purchase
    var lastPurchaseDate: Date?

    /// Date when the price was last updated
    var priceUpdatedAt: Date?

    /// Sector classification
    var sector: String?

    /// Industry classification
    var industry: String?

    /// Asset type
    var assetType: AssetType

    /// Date when the holding was created
    let createdAt: Date

    /// Date when the holding was last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        portfolioId: String,
        stockSymbol: String,
        stockName: String? = nil,
        quantity: Decimal,
        averageCostPerShare: Decimal,
        currentPricePerShare: Decimal,
        firstPurchaseDate: Date? = nil,
        lastPurchaseDate: Date? = nil,
        priceUpdatedAt: Date? = nil,
        sector: String? = nil,
        industry: String? = nil,
        assetType: AssetType = .stock,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.portfolioId = portfolioId
        self.stockSymbol = stockSymbol
        self.stockName = stockName
        self.quantity = quantity
        self.averageCostPerShare = averageCostPerShare
        self.currentPricePerShare = currentPricePerShare
        self.firstPurchaseDate = firstPurchaseDate
        self.lastPurchaseDate = lastPurchaseDate
        self.priceUpdatedAt = priceUpdatedAt
        self.sector = sector
        self.industry = industry
        self.assetType = assetType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Display name for the holding
    var displayName: String {
        if let stockName = stockName {
            return "\(stockName) (\(stockSymbol))"
        }
        return stockSymbol
    }

    /// Total cost basis (average cost * quantity)
    var costBasis: Decimal {
        averageCostPerShare * quantity
    }

    /// Current market value
    var marketValue: Decimal {
        currentPricePerShare * quantity
    }

    /// Unrealized gain/loss in currency
    var unrealizedGainLoss: Decimal {
        marketValue - costBasis
    }

    /// Unrealized gain/loss percentage
    var unrealizedGainLossPercentage: Decimal {
        guard costBasis > 0 else { return 0 }
        return ((marketValue - costBasis) / costBasis) * 100
    }

    /// Whether the holding is profitable
    var isProfitable: Bool {
        unrealizedGainLoss > 0
    }

    /// Today's change (requires previous close price - simplified here)
    var todaysChange: Decimal? {
        // This would typically require the previous close price
        // For now, return nil - actual implementation would compare with previous close
        nil
    }

    /// Today's change percentage
    var todaysChangePercentage: Decimal? {
        nil
    }

    /// Days since last purchase
    var daysSinceLastPurchase: Int? {
        lastPurchaseDate?.daysSinceNow
    }

    /// Holding period in days
    var holdingPeriodDays: Int? {
        firstPurchaseDate?.daysSinceNow
    }

    /// Whether this is a long-term holding (> 1 year)
    var isLongTermHolding: Bool {
        guard let days = holdingPeriodDays else { return false }
        return days > 365
    }

    // MARK: - Methods

    /// Calculate the new average cost after adding shares
    /// Uses weighted average: (current cost basis + new purchase) / total shares
    func averageCostAfterAdding(shares: Decimal, at price: Decimal) -> Decimal {
        let newTotalCost = costBasis + (shares * price)
        let newQuantity = quantity + shares
        guard newQuantity > 0 else { return 0 }
        return newTotalCost / newQuantity
    }

    /// Calculate portfolio weight given total portfolio value
    func portfolioWeight(totalValue: Decimal) -> Decimal {
        guard totalValue > 0 else { return 0 }
        return (marketValue / totalValue) * 100
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case portfolioId
        case stockSymbol
        case stockName
        case quantity
        case averageCostPerShare
        case currentPricePerShare
        case firstPurchaseDate
        case lastPurchaseDate
        case priceUpdatedAt
        case sector
        case industry
        case assetType
        case createdAt
        case updatedAt
    }
}

// MARK: - Asset Type

/// Types of assets that can be held
enum AssetType: String, Codable, Sendable, CaseIterable {
    case stock
    case etf
    case mutualFund
    case bond
    case reit
    case crypto
    case commodity
    case option
    case other

    var displayName: String {
        switch self {
        case .stock:
            return "Stock"
        case .etf:
            return "ETF"
        case .mutualFund:
            return "Mutual Fund"
        case .bond:
            return "Bond"
        case .reit:
            return "REIT"
        case .crypto:
            return "Cryptocurrency"
        case .commodity:
            return "Commodity"
        case .option:
            return "Option"
        case .other:
            return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .stock:
            return "chart.line.uptrend.xyaxis"
        case .etf:
            return "square.stack.3d.up"
        case .mutualFund:
            return "chart.pie.fill"
        case .bond:
            return "doc.text.fill"
        case .reit:
            return "building.2.fill"
        case .crypto:
            return "bitcoinsign.circle.fill"
        case .commodity:
            return "cube.fill"
        case .option:
            return "arrow.left.arrow.right"
        case .other:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Holding Lot

/// Represents a specific lot/purchase of a holding (for tax lot accounting)
struct HoldingLot: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let holdingId: String
    let quantity: Decimal
    let costPerShare: Decimal
    let purchaseDate: Date
    var soldQuantity: Decimal
    var soldDate: Date?

    /// Remaining quantity in this lot
    var remainingQuantity: Decimal {
        quantity - soldQuantity
    }

    /// Whether this lot is fully sold
    var isFullySold: Bool {
        remainingQuantity <= 0
    }

    /// Total cost of this lot
    var totalCost: Decimal {
        quantity * costPerShare
    }

    /// Remaining cost basis
    var remainingCostBasis: Decimal {
        remainingQuantity * costPerShare
    }

    /// Whether this is a long-term lot (purchased > 1 year ago)
    var isLongTerm: Bool {
        purchaseDate.daysSinceNow > 365
    }

    init(
        id: String = UUID().uuidString,
        holdingId: String,
        quantity: Decimal,
        costPerShare: Decimal,
        purchaseDate: Date,
        soldQuantity: Decimal = 0,
        soldDate: Date? = nil
    ) {
        self.id = id
        self.holdingId = holdingId
        self.quantity = quantity
        self.costPerShare = costPerShare
        self.purchaseDate = purchaseDate
        self.soldQuantity = soldQuantity
        self.soldDate = soldDate
    }
}

// MARK: - Holdings Summary

/// Summary of holdings in a portfolio
struct HoldingsSummary: Sendable {
    let totalHoldings: Int
    let totalMarketValue: Decimal
    let totalCostBasis: Decimal
    let totalUnrealizedGainLoss: Decimal
    let profitableHoldings: Int
    let unprofitableHoldings: Int

    var overallGainLossPercentage: Decimal {
        guard totalCostBasis > 0 else { return 0 }
        return (totalUnrealizedGainLoss / totalCostBasis) * 100
    }

    var profitabilityRatio: Double {
        guard totalHoldings > 0 else { return 0 }
        return Double(profitableHoldings) / Double(totalHoldings)
    }

    init(holdings: [Holding]) {
        self.totalHoldings = holdings.count
        self.totalMarketValue = holdings.reduce(0) { $0 + $1.marketValue }
        self.totalCostBasis = holdings.reduce(0) { $0 + $1.costBasis }
        self.totalUnrealizedGainLoss = holdings.reduce(0) { $0 + $1.unrealizedGainLoss }
        self.profitableHoldings = holdings.filter { $0.isProfitable }.count
        self.unprofitableHoldings = holdings.filter { !$0.isProfitable && $0.unrealizedGainLoss != 0 }.count
    }
}

// MARK: - Sector Allocation

/// Sector-based allocation
struct SectorAllocation: Identifiable, Sendable {
    var id: String { sector }
    let sector: String
    let value: Decimal
    let percentage: Decimal
    let holdings: [Holding]

    init(sector: String, holdings: [Holding], totalValue: Decimal) {
        self.sector = sector
        self.holdings = holdings
        self.value = holdings.reduce(0) { $0 + $1.marketValue }
        self.percentage = totalValue > 0 ? (self.value / totalValue) * 100 : 0
    }
}
