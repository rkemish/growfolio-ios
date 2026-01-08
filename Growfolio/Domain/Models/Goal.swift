//
//  Goal.swift
//  Growfolio
//
//  Investment goal domain model.
//

import Foundation

/// Represents an investment goal
struct Goal: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// User ID who owns this goal
    let userId: String

    /// Goal name/title
    var name: String

    /// Target amount to reach
    var targetAmount: Decimal

    /// Current amount accumulated
    var currentAmount: Decimal

    /// Target date to reach the goal (optional)
    var targetDate: Date?

    /// Linked portfolio ID (optional)
    var linkedPortfolioId: String?

    /// Linked DCA schedule IDs (positions from these schedules contribute to this goal)
    var linkedDCAScheduleIds: [String]

    /// Goal category
    var category: GoalCategory

    /// Goal icon name (SF Symbol)
    var iconName: String

    /// Goal color (hex string)
    var colorHex: String

    /// Additional notes
    var notes: String?

    /// Whether the goal is archived
    var isArchived: Bool

    /// Date when the goal was created
    let createdAt: Date

    /// Date when the goal was last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        targetDate: Date? = nil,
        linkedPortfolioId: String? = nil,
        linkedDCAScheduleIds: [String] = [],
        category: GoalCategory = .other,
        iconName: String = "target",
        colorHex: String = "#007AFF",
        notes: String? = nil,
        isArchived: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
        self.linkedPortfolioId = linkedPortfolioId
        self.linkedDCAScheduleIds = linkedDCAScheduleIds
        self.category = category
        self.iconName = iconName
        self.colorHex = colorHex
        self.notes = notes
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Progress towards the goal (0.0 to 1.0+)
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return (currentAmount / targetAmount).doubleValue
    }

    /// Progress percentage (0 to 100+)
    var progressPercentage: Decimal {
        currentAmount.percentage(of: targetAmount)
    }

    /// Clamped progress for UI (0.0 to 1.0)
    var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    /// Amount remaining to reach the goal
    var remainingAmount: Decimal {
        max(targetAmount - currentAmount, 0)
    }

    /// Whether the goal has been achieved
    var isAchieved: Bool {
        currentAmount >= targetAmount
    }

    /// Whether the goal is overdue
    var isOverdue: Bool {
        guard let targetDate = targetDate else { return false }
        return !isAchieved && targetDate < Date()
    }

    /// Days remaining until target date
    var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        return targetDate.daysFromNow
    }

    /// Estimated monthly contribution needed to reach goal on time
    /// Calculates simple linear monthly amount needed (doesn't account for investment growth)
    var estimatedMonthlyContribution: Decimal? {
        guard let targetDate = targetDate,
              targetDate > Date(),
              !isAchieved else {
            return nil
        }

        let monthsRemaining = Decimal(targetDate.monthsFromNow)
        guard monthsRemaining > 0 else { return nil }

        return remainingAmount / monthsRemaining
    }

    /// Whether this goal has linked DCA schedules
    var hasLinkedDCASchedules: Bool {
        !linkedDCAScheduleIds.isEmpty
    }

    /// Status of the goal
    /// Categorizes goals into meaningful states based on progress and dates
    var status: GoalStatus {
        if isArchived {
            return .archived
        } else if isAchieved {
            return .achieved
        } else if isOverdue {
            return .overdue
        } else if progress >= 0.75 {
            // At 75%+ progress, show encouraging "almost there" state
            return .almostThere
        } else if progress >= 0.5 {
            return .halfway
        } else if progress > 0 {
            return .inProgress
        } else {
            return .notStarted
        }
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case targetAmount
        case currentAmount
        case targetDate
        case linkedPortfolioId
        case linkedDCAScheduleIds = "linkedDcaScheduleIds"
        case category
        case iconName
        case colorHex
        case notes
        case isArchived
        case createdAt
        case updatedAt
    }
}

// MARK: - Goal Category

/// Categories for investment goals
enum GoalCategory: String, Codable, Sendable, CaseIterable {
    case retirement
    case education
    case house
    case car
    case vacation
    case emergency
    case wedding
    case investment
    case other

    var displayName: String {
        switch self {
        case .retirement:
            return "Retirement"
        case .education:
            return "Education"
        case .house:
            return "Home Purchase"
        case .car:
            return "Vehicle"
        case .vacation:
            return "Vacation"
        case .emergency:
            return "Emergency Fund"
        case .wedding:
            return "Wedding"
        case .investment:
            return "Investment"
        case .other:
            return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .retirement:
            return "sun.horizon.fill"
        case .education:
            return "graduationcap.fill"
        case .house:
            return "house.fill"
        case .car:
            return "car.fill"
        case .vacation:
            return "airplane"
        case .emergency:
            return "cross.case.fill"
        case .wedding:
            return "heart.fill"
        case .investment:
            return "chart.line.uptrend.xyaxis"
        case .other:
            return "target"
        }
    }

    var defaultColorHex: String {
        switch self {
        case .retirement:
            return "#FF9500"
        case .education:
            return "#5856D6"
        case .house:
            return "#34C759"
        case .car:
            return "#007AFF"
        case .vacation:
            return "#FF2D55"
        case .emergency:
            return "#FF3B30"
        case .wedding:
            return "#FF2D55"
        case .investment:
            return "#30D158"
        case .other:
            return "#8E8E93"
        }
    }
}

// MARK: - Goal Status

/// Status of a goal
enum GoalStatus: String, Codable, Sendable {
    case notStarted
    case inProgress
    case halfway
    case almostThere
    case achieved
    case overdue
    case archived

    var displayName: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .halfway:
            return "Halfway There"
        case .almostThere:
            return "Almost There"
        case .achieved:
            return "Achieved"
        case .overdue:
            return "Overdue"
        case .archived:
            return "Archived"
        }
    }

    var iconName: String {
        switch self {
        case .notStarted:
            return "circle"
        case .inProgress:
            return "circle.lefthalf.filled"
        case .halfway:
            return "circle.lefthalf.filled"
        case .almostThere:
            return "circle.inset.filled"
        case .achieved:
            return "checkmark.circle.fill"
        case .overdue:
            return "exclamationmark.circle.fill"
        case .archived:
            return "archivebox.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .notStarted:
            return "#8E8E93"
        case .inProgress:
            return "#007AFF"
        case .halfway:
            return "#FF9500"
        case .almostThere:
            return "#34C759"
        case .achieved:
            return "#30D158"
        case .overdue:
            return "#FF3B30"
        case .archived:
            return "#8E8E93"
        }
    }
}

// MARK: - Goal Milestone

/// Represents a milestone within a goal
struct GoalMilestone: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let goalId: String
    var name: String
    var targetAmount: Decimal
    var reachedAt: Date?

    var isReached: Bool {
        reachedAt != nil
    }

    init(
        id: String = UUID().uuidString,
        goalId: String,
        name: String,
        targetAmount: Decimal,
        reachedAt: Date? = nil
    ) {
        self.id = id
        self.goalId = goalId
        self.name = name
        self.targetAmount = targetAmount
        self.reachedAt = reachedAt
    }
}

// MARK: - Goal Summary

/// Summary statistics for all goals
struct GoalsSummary: Sendable {
    let totalGoals: Int
    let achievedGoals: Int
    let inProgressGoals: Int
    let totalTargetAmount: Decimal
    let totalCurrentAmount: Decimal

    var overallProgress: Double {
        guard totalTargetAmount > 0 else { return 0 }
        return (totalCurrentAmount / totalTargetAmount).doubleValue
    }

    var achievementRate: Double {
        guard totalGoals > 0 else { return 0 }
        return Double(achievedGoals) / Double(totalGoals)
    }

    init(goals: [Goal]) {
        self.totalGoals = goals.count
        self.achievedGoals = goals.filter { $0.isAchieved }.count
        self.inProgressGoals = goals.filter { !$0.isAchieved && !$0.isArchived }.count
        self.totalTargetAmount = goals.reduce(0) { $0 + $1.targetAmount }
        self.totalCurrentAmount = goals.reduce(0) { $0 + $1.currentAmount }
    }
}

// MARK: - Goal Position

/// Represents a stock position acquired through DCA for a goal
struct GoalPosition: Identifiable, Sendable, Equatable {
    let id: String
    let stockSymbol: String
    let stockName: String
    let totalShares: Decimal
    let totalCostBasis: Decimal
    let currentPrice: Decimal
    let purchases: [GoalPurchase]

    var currentValue: Decimal {
        totalShares * currentPrice
    }

    var totalGain: Decimal {
        currentValue - totalCostBasis
    }

    var totalGainPercent: Decimal {
        guard totalCostBasis > 0 else { return 0 }
        return (totalGain / totalCostBasis) * 100
    }

    var averageCostPerShare: Decimal {
        guard totalShares > 0 else { return 0 }
        return totalCostBasis / totalShares
    }

    var isProfitable: Bool {
        totalGain > 0
    }
}

/// Represents a single DCA purchase contributing to a goal
struct GoalPurchase: Identifiable, Sendable, Equatable {
    let id: String
    let date: Date
    let shares: Decimal
    let pricePerShare: Decimal
    let totalAmount: Decimal
    let dcaScheduleId: String

    var currentValue: Decimal? // Set when displaying with current price

    init(
        id: String = UUID().uuidString,
        date: Date,
        shares: Decimal,
        pricePerShare: Decimal,
        totalAmount: Decimal,
        dcaScheduleId: String,
        currentValue: Decimal? = nil
    ) {
        self.id = id
        self.date = date
        self.shares = shares
        self.pricePerShare = pricePerShare
        self.totalAmount = totalAmount
        self.dcaScheduleId = dcaScheduleId
        self.currentValue = currentValue
    }
}

/// Summary of all positions for a goal
struct GoalPositionsSummary: Sendable {
    let goalId: String
    let positions: [GoalPosition]

    var totalCostBasis: Decimal {
        positions.reduce(0) { $0 + $1.totalCostBasis }
    }

    var totalCurrentValue: Decimal {
        positions.reduce(0) { $0 + $1.currentValue }
    }

    var totalGain: Decimal {
        totalCurrentValue - totalCostBasis
    }

    var totalGainPercent: Decimal {
        guard totalCostBasis > 0 else { return 0 }
        return (totalGain / totalCostBasis) * 100
    }

    var isProfitable: Bool {
        totalGain > 0
    }

    var totalPurchases: Int {
        positions.reduce(0) { $0 + $1.purchases.count }
    }

    var uniqueStocks: Int {
        positions.count
    }
}
