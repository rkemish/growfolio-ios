//
//  Position.swift
//  Growfolio
//
//  Domain model for stock positions (current holdings).
//

import Foundation

// MARK: - Position Side

enum PositionSide: String, Codable, Sendable, CaseIterable {
    case long
    case short

    var displayName: String {
        switch self {
        case .long: return "Long"
        case .short: return "Short"
        }
    }
}

// MARK: - Position Main Model

struct Position: Identifiable, Codable, Sendable, Equatable, Hashable {
    // MARK: - Properties
    let symbol: String
    let quantity: Decimal
    let marketValueUsd: Decimal
    let marketValueGbp: Decimal
    let costBasis: Decimal
    let unrealizedPnlUsd: Decimal
    let unrealizedPnlGbp: Decimal
    let averageEntryPrice: Decimal
    let currentPrice: Decimal
    let changePct: Decimal
    let side: PositionSide
    let lastUpdated: Date

    var id: String { symbol }

    // MARK: - Initialization
    init(
        symbol: String,
        quantity: Decimal,
        marketValueUsd: Decimal,
        marketValueGbp: Decimal,
        costBasis: Decimal,
        unrealizedPnlUsd: Decimal,
        unrealizedPnlGbp: Decimal,
        averageEntryPrice: Decimal,
        currentPrice: Decimal,
        changePct: Decimal,
        side: PositionSide = .long,
        lastUpdated: Date = Date()
    ) {
        self.symbol = symbol
        self.quantity = quantity
        self.marketValueUsd = marketValueUsd
        self.marketValueGbp = marketValueGbp
        self.costBasis = costBasis
        self.unrealizedPnlUsd = unrealizedPnlUsd
        self.unrealizedPnlGbp = unrealizedPnlGbp
        self.averageEntryPrice = averageEntryPrice
        self.currentPrice = currentPrice
        self.changePct = changePct
        self.side = side
        self.lastUpdated = lastUpdated
    }

    // MARK: - Computed Properties

    var isProfitable: Bool {
        unrealizedPnlUsd > 0
    }

    var displayName: String {
        "\(quantity) shares of \(symbol)"
    }

    var returnPercentage: Decimal {
        guard costBasis > 0 else { return 0 }
        return (unrealizedPnlUsd / costBasis) * 100
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case symbol
        case quantity
        case marketValueUsd = "market_value_usd"
        case marketValueGbp = "market_value_gbp"
        case costBasis = "cost_basis"
        case unrealizedPnlUsd = "unrealized_pnl_usd"
        case unrealizedPnlGbp = "unrealized_pnl_gbp"
        case averageEntryPrice = "average_entry_price"
        case currentPrice = "current_price"
        case changePct = "change_pct"
        case side
        case lastUpdated = "last_updated"
    }
}

// MARK: - Positions Summary

struct PositionsSummary: Sendable, Equatable {
    let totalPositions: Int
    let totalMarketValueUsd: Decimal
    let totalMarketValueGbp: Decimal
    let totalCostBasis: Decimal
    let totalUnrealizedPnlUsd: Decimal
    let totalUnrealizedPnlGbp: Decimal

    var overallReturnPercentage: Decimal {
        guard totalCostBasis > 0 else { return 0 }
        return (totalUnrealizedPnlUsd / totalCostBasis) * 100
    }

    var isProfitable: Bool {
        totalUnrealizedPnlUsd > 0
    }

    init(positions: [Position]) {
        self.totalPositions = positions.count
        self.totalMarketValueUsd = positions.reduce(0) { $0 + $1.marketValueUsd }
        self.totalMarketValueGbp = positions.reduce(0) { $0 + $1.marketValueGbp }
        self.totalCostBasis = positions.reduce(0) { $0 + $1.costBasis }
        self.totalUnrealizedPnlUsd = positions.reduce(0) { $0 + $1.unrealizedPnlUsd }
        self.totalUnrealizedPnlGbp = positions.reduce(0) { $0 + $1.unrealizedPnlGbp }
    }
}
