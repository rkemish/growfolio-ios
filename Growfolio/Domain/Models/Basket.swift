//
//  Basket.swift
//  Growfolio
//
//  Basket domain models for grouping fractional stock holdings.
//

import Foundation

// MARK: - Basket Status

/// Status of a basket
enum BasketStatus: String, Codable, Sendable, CaseIterable {
    case active
    case paused
    case cancelled

    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .paused:
            return "Paused"
        case .cancelled:
            return "Cancelled"
        }
    }

    var iconName: String {
        switch self {
        case .active:
            return "play.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .active:
            return "#34C759"
        case .paused:
            return "#FF9500"
        case .cancelled:
            return "#FF3B30"
        }
    }
}

// MARK: - Basket Allocation

/// Represents a stock allocation within a basket
struct BasketAllocation: Codable, Sendable, Equatable, Hashable, Identifiable {
    var id: String { symbol }

    /// Stock symbol
    let symbol: String

    /// Company name
    let name: String

    /// Target allocation percentage (0-100)
    let percentage: Decimal

    /// Target number of shares (optional)
    let targetShares: Decimal?

    enum CodingKeys: String, CodingKey {
        case symbol
        case name
        case percentage
        case targetShares = "target_shares"
    }
}

// MARK: - Basket Summary

/// Summary of basket performance
struct BasketSummary: Codable, Sendable, Equatable, Hashable {
    /// Current market value
    let currentValue: Decimal

    /// Total amount invested
    let totalInvested: Decimal

    /// Total gain/loss
    let totalGainLoss: Decimal

    /// Return percentage
    var returnPercentage: Decimal {
        guard totalInvested > 0 else { return 0 }
        return (totalGainLoss / totalInvested) * 100
    }

    enum CodingKeys: String, CodingKey {
        case currentValue = "current_value"
        case totalInvested = "total_invested"
        case totalGainLoss = "total_gain_loss"
    }
}

// MARK: - Basket

/// Represents a basket of stocks with target allocations
struct Basket: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Owner user ID
    let userId: String

    /// Family ID if shared basket
    let familyId: String?

    /// Basket name
    var name: String

    /// Basket description
    var description: String?

    /// Category label
    var category: String?

    /// Icon name
    var icon: String?

    /// Color hex code
    var color: String?

    /// Stock allocations
    var allocations: [BasketAllocation]

    /// Whether DCA is enabled for this basket
    var dcaEnabled: Bool

    /// Linked DCA schedule ID
    var dcaScheduleId: String?

    /// Basket status
    var status: BasketStatus

    /// Performance summary
    var summary: BasketSummary

    /// Whether basket is shared with family
    var isShared: Bool

    /// Date created
    let createdAt: Date

    /// Date last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        userId: String,
        familyId: String? = nil,
        name: String,
        description: String? = nil,
        category: String? = nil,
        icon: String? = nil,
        color: String? = nil,
        allocations: [BasketAllocation],
        dcaEnabled: Bool = false,
        dcaScheduleId: String? = nil,
        status: BasketStatus = .active,
        summary: BasketSummary = BasketSummary(currentValue: 0, totalInvested: 0, totalGainLoss: 0),
        isShared: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.familyId = familyId
        self.name = name
        self.description = description
        self.category = category
        self.icon = icon
        self.color = color
        self.allocations = allocations
        self.dcaEnabled = dcaEnabled
        self.dcaScheduleId = dcaScheduleId
        self.status = status
        self.summary = summary
        self.isShared = isShared
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Total allocation percentage
    var totalAllocationPercentage: Decimal {
        allocations.reduce(0) { $0 + $1.percentage }
    }

    /// Whether allocations sum to 100%
    var hasValidAllocations: Bool {
        abs(totalAllocationPercentage - 100) < 0.01
    }

    /// Number of stocks in basket
    var stockCount: Int {
        allocations.count
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case familyId = "family_id"
        case name
        case description
        case category
        case icon
        case color
        case allocations
        case dcaEnabled = "dca_enabled"
        case dcaScheduleId = "dca_schedule_id"
        case status
        case summary
        case isShared = "is_shared"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Basket Create

/// Request model for creating a basket
struct BasketCreate: Encodable, Sendable {
    /// Basket name
    let name: String

    /// Basket description
    let description: String?

    /// Category label
    let category: String?

    /// Icon name
    let icon: String?

    /// Color hex code
    let color: String?

    /// Stock allocations (must sum to 100%)
    let allocations: [BasketAllocation]

    /// Whether to share with family
    let isShared: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case category
        case icon
        case color
        case allocations
        case isShared = "is_shared"
    }
}
