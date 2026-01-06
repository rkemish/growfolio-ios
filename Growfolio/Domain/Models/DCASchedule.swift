//
//  DCASchedule.swift
//  Growfolio
//
//  Dollar-Cost Averaging schedule domain model.
//

import Foundation

/// Represents a Dollar-Cost Averaging investment schedule
struct DCASchedule: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// User ID who owns this schedule
    let userId: String

    /// Stock symbol to invest in
    var stockSymbol: String

    /// Stock name for display
    var stockName: String?

    /// Amount to invest per execution
    var amount: Decimal

    /// Investment frequency
    var frequency: DCAFrequency

    /// Preferred day of week for weekly schedules (1 = Sunday, 7 = Saturday)
    var preferredDayOfWeek: Int?

    /// Preferred day of month for monthly schedules (1-28)
    var preferredDayOfMonth: Int?

    /// Date when the schedule starts
    var startDate: Date

    /// Date when the schedule ends (nil for indefinite)
    var endDate: Date?

    /// Date of the next scheduled execution
    var nextExecutionDate: Date?

    /// Date of the last execution
    var lastExecutionDate: Date?

    /// Portfolio ID where shares are deposited
    var portfolioId: String

    /// Whether the schedule is active
    var isActive: Bool

    /// Whether the schedule is paused
    var isPaused: Bool

    /// Total amount invested through this schedule
    var totalInvested: Decimal

    /// Total number of executions
    var executionCount: Int

    /// Date when the schedule was created
    let createdAt: Date

    /// Date when the schedule was last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        userId: String,
        stockSymbol: String,
        stockName: String? = nil,
        amount: Decimal,
        frequency: DCAFrequency = .monthly,
        preferredDayOfWeek: Int? = nil,
        preferredDayOfMonth: Int? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        nextExecutionDate: Date? = nil,
        lastExecutionDate: Date? = nil,
        portfolioId: String,
        isActive: Bool = true,
        isPaused: Bool = false,
        totalInvested: Decimal = 0,
        executionCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.stockSymbol = stockSymbol
        self.stockName = stockName
        self.amount = amount
        self.frequency = frequency
        self.preferredDayOfWeek = preferredDayOfWeek
        self.preferredDayOfMonth = preferredDayOfMonth
        self.startDate = startDate
        self.endDate = endDate
        self.nextExecutionDate = nextExecutionDate
        self.lastExecutionDate = lastExecutionDate
        self.portfolioId = portfolioId
        self.isActive = isActive
        self.isPaused = isPaused
        self.totalInvested = totalInvested
        self.executionCount = executionCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Display name for the schedule
    var displayName: String {
        if let stockName = stockName {
            return "\(stockName) (\(stockSymbol))"
        }
        return stockSymbol
    }

    /// Average amount per execution
    var averagePerExecution: Decimal {
        guard executionCount > 0 else { return amount }
        return totalInvested / Decimal(executionCount)
    }

    /// Status of the schedule
    var status: DCAScheduleStatus {
        if !isActive {
            return .completed
        } else if isPaused {
            return .paused
        } else if let endDate = endDate, endDate < Date() {
            return .completed
        } else if let nextDate = nextExecutionDate, nextDate <= Date() {
            return .pendingExecution
        } else {
            return .active
        }
    }

    /// Whether the schedule has ended
    var hasEnded: Bool {
        guard let endDate = endDate else { return false }
        return endDate < Date()
    }

    /// Days until next execution
    var daysUntilNextExecution: Int? {
        guard let nextDate = nextExecutionDate else { return nil }
        return nextDate.daysFromNow
    }

    /// Estimated annual investment
    var estimatedAnnualInvestment: Decimal {
        amount * Decimal(frequency.executionsPerYear)
    }

    /// Estimated remaining executions
    var estimatedRemainingExecutions: Int? {
        guard let endDate = endDate else { return nil }
        let remainingDays = endDate.daysFromNow
        guard remainingDays > 0 else { return 0 }

        switch frequency {
        case .daily:
            return remainingDays
        case .weekly:
            return remainingDays / 7
        case .biweekly:
            return remainingDays / 14
        case .monthly:
            return endDate.monthsFromNow
        case .quarterly:
            return endDate.monthsFromNow / 3
        }
    }

    // MARK: - Methods

    /// Calculate the next execution date from a given date
    func calculateNextExecutionDate(from date: Date = Date()) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date

        case .weekly:
            var nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
            if let preferredDay = preferredDayOfWeek {
                // Adjust to preferred day of week
                let currentDay = calendar.component(.weekday, from: nextDate)
                let adjustment = (preferredDay - currentDay + 7) % 7
                nextDate = calendar.date(byAdding: .day, value: adjustment, to: nextDate) ?? nextDate
            }
            return nextDate

        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date

        case .monthly:
            var components = DateComponents()
            components.month = 1
            var nextDate = calendar.date(byAdding: components, to: date) ?? date
            if let preferredDay = preferredDayOfMonth {
                // Adjust to preferred day of month
                var dateComponents = calendar.dateComponents([.year, .month], from: nextDate)
                dateComponents.day = min(preferredDay, 28) // Cap at 28 for safety
                nextDate = calendar.date(from: dateComponents) ?? nextDate
            }
            return nextDate

        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        }
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case stockSymbol
        case stockName
        case amount
        case frequency
        case preferredDayOfWeek
        case preferredDayOfMonth
        case startDate
        case endDate
        case nextExecutionDate
        case lastExecutionDate
        case portfolioId
        case isActive
        case isPaused
        case totalInvested
        case executionCount
        case createdAt
        case updatedAt
    }
}

// MARK: - DCA Frequency

/// Investment frequency options for DCA
enum DCAFrequency: String, Codable, Sendable, CaseIterable {
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly

    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .biweekly:
            return "Every 2 Weeks"
        case .monthly:
            return "Monthly"
        case .quarterly:
            return "Quarterly"
        }
    }

    var shortName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .biweekly:
            return "Bi-weekly"
        case .monthly:
            return "Monthly"
        case .quarterly:
            return "Quarterly"
        }
    }

    var executionsPerYear: Int {
        switch self {
        case .daily:
            return 365
        case .weekly:
            return 52
        case .biweekly:
            return 26
        case .monthly:
            return 12
        case .quarterly:
            return 4
        }
    }

    var averageDaysBetweenExecutions: Int {
        switch self {
        case .daily:
            return 1
        case .weekly:
            return 7
        case .biweekly:
            return 14
        case .monthly:
            return 30
        case .quarterly:
            return 91
        }
    }
}

// MARK: - DCA Schedule Status

/// Status of a DCA schedule
enum DCAScheduleStatus: String, Codable, Sendable {
    case active
    case paused
    case pendingExecution
    case completed

    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .paused:
            return "Paused"
        case .pendingExecution:
            return "Pending"
        case .completed:
            return "Completed"
        }
    }

    var iconName: String {
        switch self {
        case .active:
            return "play.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .pendingExecution:
            return "clock.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .active:
            return "#34C759"
        case .paused:
            return "#FF9500"
        case .pendingExecution:
            return "#007AFF"
        case .completed:
            return "#8E8E93"
        }
    }
}

// MARK: - DCA Execution

/// Represents a single DCA execution/purchase
struct DCAExecution: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let scheduleId: String
    let stockSymbol: String
    let amount: Decimal
    let sharesAcquired: Decimal
    let pricePerShare: Decimal
    let executedAt: Date
    let status: DCAExecutionStatus
    let errorMessage: String?

    var totalCost: Decimal {
        sharesAcquired * pricePerShare
    }

    init(
        id: String = UUID().uuidString,
        scheduleId: String,
        stockSymbol: String,
        amount: Decimal,
        sharesAcquired: Decimal,
        pricePerShare: Decimal,
        executedAt: Date = Date(),
        status: DCAExecutionStatus = .completed,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.scheduleId = scheduleId
        self.stockSymbol = stockSymbol
        self.amount = amount
        self.sharesAcquired = sharesAcquired
        self.pricePerShare = pricePerShare
        self.executedAt = executedAt
        self.status = status
        self.errorMessage = errorMessage
    }
}

/// Status of a DCA execution
enum DCAExecutionStatus: String, Codable, Sendable {
    case pending
    case completed
    case failed
    case cancelled
}

// MARK: - DCA Summary

/// Summary statistics for all DCA schedules
struct DCASummary: Sendable {
    let activeSchedules: Int
    let totalMonthlyInvestment: Decimal
    let totalInvested: Decimal
    let totalExecutions: Int

    init(schedules: [DCASchedule]) {
        self.activeSchedules = schedules.filter { $0.status == .active }.count
        self.totalMonthlyInvestment = schedules
            .filter { $0.status == .active }
            .reduce(0) { total, schedule in
                let monthlyEquivalent = schedule.amount * Decimal(schedule.frequency.executionsPerYear) / 12
                return total + monthlyEquivalent
            }
        self.totalInvested = schedules.reduce(0) { $0 + $1.totalInvested }
        self.totalExecutions = schedules.reduce(0) { $0 + $1.executionCount }
    }
}
