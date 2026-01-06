//
//  DCARepositoryProtocol.swift
//  Growfolio
//
//  Protocol defining the DCA repository interface.
//

import Foundation

/// Protocol for DCA schedule data operations
protocol DCARepositoryProtocol: Sendable {

    // MARK: - Schedule Operations

    /// Fetch all DCA schedules for the current user
    /// - Returns: Array of DCA schedules
    func fetchSchedules() async throws -> [DCASchedule]

    /// Fetch active DCA schedules only
    /// - Returns: Array of active DCA schedules
    func fetchActiveSchedules() async throws -> [DCASchedule]

    /// Fetch a specific DCA schedule by ID
    /// - Parameter id: Schedule identifier
    /// - Returns: The schedule if found
    func fetchSchedule(id: String) async throws -> DCASchedule

    /// Fetch schedules for a specific stock
    /// - Parameter symbol: Stock symbol
    /// - Returns: Array of schedules for the stock
    func fetchSchedules(for symbol: String) async throws -> [DCASchedule]

    /// Fetch schedules linked to a portfolio
    /// - Parameter portfolioId: Portfolio identifier
    /// - Returns: Array of schedules for the portfolio
    func fetchSchedules(linkedToPortfolio portfolioId: String) async throws -> [DCASchedule]

    /// Create a new DCA schedule
    /// - Parameter schedule: Schedule to create
    /// - Returns: The created schedule with server-assigned ID
    func createSchedule(_ schedule: DCASchedule) async throws -> DCASchedule

    /// Create a schedule with the specified parameters
    /// - Parameters:
    ///   - stockSymbol: Stock symbol to invest in
    ///   - amount: Amount per execution
    ///   - frequency: Investment frequency
    ///   - startDate: Start date
    ///   - endDate: Optional end date
    ///   - portfolioId: Portfolio to deposit shares
    /// - Returns: The created schedule
    func createSchedule(
        stockSymbol: String,
        amount: Decimal,
        frequency: DCAFrequency,
        startDate: Date,
        endDate: Date?,
        portfolioId: String
    ) async throws -> DCASchedule

    /// Update an existing schedule
    /// - Parameter schedule: Schedule with updated values
    /// - Returns: The updated schedule
    func updateSchedule(_ schedule: DCASchedule) async throws -> DCASchedule

    /// Update schedule amount
    /// - Parameters:
    ///   - id: Schedule identifier
    ///   - amount: New amount
    /// - Returns: The updated schedule
    func updateScheduleAmount(id: String, amount: Decimal) async throws -> DCASchedule

    /// Update schedule frequency
    /// - Parameters:
    ///   - id: Schedule identifier
    ///   - frequency: New frequency
    /// - Returns: The updated schedule
    func updateScheduleFrequency(id: String, frequency: DCAFrequency) async throws -> DCASchedule

    /// Pause a schedule
    /// - Parameter id: Schedule identifier
    /// - Returns: The paused schedule
    func pauseSchedule(id: String) async throws -> DCASchedule

    /// Resume a paused schedule
    /// - Parameter id: Schedule identifier
    /// - Returns: The resumed schedule
    func resumeSchedule(id: String) async throws -> DCASchedule

    /// Cancel a schedule
    /// - Parameter id: Schedule identifier
    /// - Returns: The cancelled schedule
    func cancelSchedule(id: String) async throws -> DCASchedule

    /// Delete a schedule
    /// - Parameter id: Schedule identifier
    func deleteSchedule(id: String) async throws

    // MARK: - Execution Operations

    /// Fetch executions for a schedule
    /// - Parameters:
    ///   - scheduleId: Schedule identifier
    ///   - page: Page number (1-indexed)
    ///   - limit: Number of items per page
    /// - Returns: Paginated executions
    func fetchExecutions(for scheduleId: String, page: Int, limit: Int) async throws -> PaginatedResponse<DCAExecution>

    /// Fetch all executions for a schedule
    /// - Parameter scheduleId: Schedule identifier
    /// - Returns: Array of executions
    func fetchAllExecutions(for scheduleId: String) async throws -> [DCAExecution]

    /// Fetch a specific execution
    /// - Parameter executionId: Execution identifier
    /// - Returns: The execution if found
    func fetchExecution(id executionId: String) async throws -> DCAExecution

    /// Fetch recent executions across all schedules
    /// - Parameter limit: Maximum number of executions to fetch
    /// - Returns: Array of recent executions
    func fetchRecentExecutions(limit: Int) async throws -> [DCAExecution]

    /// Manually trigger an execution for a schedule
    /// - Parameter scheduleId: Schedule identifier
    /// - Returns: The created execution
    func executeNow(scheduleId: String) async throws -> DCAExecution

    /// Retry a failed execution
    /// - Parameter executionId: Execution identifier
    /// - Returns: The retried execution
    func retryExecution(id executionId: String) async throws -> DCAExecution

    // MARK: - Simulation Operations

    /// Simulate DCA returns for a stock
    /// - Parameters:
    ///   - symbol: Stock symbol
    ///   - amount: Amount per execution
    ///   - frequency: Investment frequency
    ///   - startDate: Simulation start date
    ///   - endDate: Simulation end date
    /// - Returns: Simulation results
    func simulateDCA(
        symbol: String,
        amount: Decimal,
        frequency: DCAFrequency,
        startDate: Date,
        endDate: Date
    ) async throws -> DCASimulation

    /// Project future returns for a schedule
    /// - Parameters:
    ///   - scheduleId: Schedule identifier
    ///   - projectionMonths: Number of months to project
    ///   - expectedAnnualReturn: Expected annual return percentage
    /// - Returns: Projection results
    func projectReturns(
        for scheduleId: String,
        projectionMonths: Int,
        expectedAnnualReturn: Decimal
    ) async throws -> DCAProjection

    // MARK: - Summary Operations

    /// Get summary statistics for all DCA schedules
    /// - Returns: DCA summary
    func fetchDCASummary() async throws -> DCASummary

    /// Get upcoming executions across all schedules
    /// - Parameter days: Number of days to look ahead
    /// - Returns: Array of upcoming execution dates with schedule info
    func fetchUpcomingExecutions(days: Int) async throws -> [UpcomingExecution]

    // MARK: - Cache Operations

    /// Invalidate cached DCA data
    func invalidateCache() async

    /// Prefetch DCA data for offline access
    func prefetchSchedules() async throws
}

// MARK: - DCA Simulation

/// Results of a DCA simulation
struct DCASimulation: Codable, Sendable {
    let symbol: String
    let amount: Decimal
    let frequency: DCAFrequency
    let startDate: Date
    let endDate: Date
    let totalInvested: Decimal
    let finalValue: Decimal
    let totalShares: Decimal
    let averageCost: Decimal
    let totalReturn: Decimal
    let totalReturnPercent: Decimal
    let executionCount: Int
    let dataPoints: [DCASimulationDataPoint]

    var annualizedReturn: Decimal {
        let years = Decimal(Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) / 365
        guard years > 0 else { return 0 }
        // Simplified calculation
        return (totalReturnPercent / years)
    }
}

/// Data point in a DCA simulation
struct DCASimulationDataPoint: Codable, Sendable, Identifiable {
    var id: Date { date }
    let date: Date
    let cumulativeInvested: Decimal
    let cumulativeValue: Decimal
    let sharesOwned: Decimal
    let priceAtDate: Decimal
}

// MARK: - DCA Projection

/// Future return projection for a DCA schedule
struct DCAProjection: Codable, Sendable {
    let scheduleId: String
    let projectionMonths: Int
    let expectedAnnualReturn: Decimal
    let projectedInvestment: Decimal
    let projectedValue: Decimal
    let projectedReturn: Decimal
    let projectedReturnPercent: Decimal
    let dataPoints: [DCAProjectionDataPoint]
}

/// Data point in a DCA projection
struct DCAProjectionDataPoint: Codable, Sendable, Identifiable {
    var id: Date { date }
    let date: Date
    let projectedInvestment: Decimal
    let projectedValue: Decimal
    let projectedValueLow: Decimal
    let projectedValueHigh: Decimal
}

// MARK: - Upcoming Execution

/// An upcoming scheduled execution
struct UpcomingExecution: Identifiable, Sendable {
    var id: String { scheduleId + executionDate.iso8601String }
    let scheduleId: String
    let stockSymbol: String
    let stockName: String?
    let amount: Decimal
    let executionDate: Date
    let portfolioId: String
    let portfolioName: String?

    var daysUntilExecution: Int {
        executionDate.daysFromNow
    }
}

// MARK: - Default Implementations

extension DCARepositoryProtocol {
    func fetchExecutions(for scheduleId: String, page: Int = 1, limit: Int = Constants.API.defaultPageSize) async throws -> PaginatedResponse<DCAExecution> {
        try await fetchExecutions(for: scheduleId, page: page, limit: limit)
    }

    func fetchRecentExecutions(limit: Int = 10) async throws -> [DCAExecution] {
        try await fetchRecentExecutions(limit: limit)
    }

    func fetchUpcomingExecutions(days: Int = 30) async throws -> [UpcomingExecution] {
        try await fetchUpcomingExecutions(days: days)
    }
}

// MARK: - DCA Repository Error

/// Errors specific to DCA operations
enum DCARepositoryError: LocalizedError {
    case scheduleNotFound(id: String)
    case executionNotFound(id: String)
    case portfolioNotFound(id: String)
    case stockNotFound(symbol: String)
    case scheduleAlreadyPaused
    case scheduleNotPaused
    case scheduleAlreadyCancelled
    case invalidAmount
    case invalidFrequency
    case invalidDateRange
    case executionAlreadyCompleted
    case executionCannotBeRetried
    case insufficientData

    var errorDescription: String? {
        switch self {
        case .scheduleNotFound(let id):
            return "DCA schedule with ID '\(id)' was not found"
        case .executionNotFound(let id):
            return "Execution with ID '\(id)' was not found"
        case .portfolioNotFound(let id):
            return "Portfolio with ID '\(id)' was not found"
        case .stockNotFound(let symbol):
            return "Stock '\(symbol)' was not found"
        case .scheduleAlreadyPaused:
            return "Schedule is already paused"
        case .scheduleNotPaused:
            return "Schedule is not paused"
        case .scheduleAlreadyCancelled:
            return "Schedule has already been cancelled"
        case .invalidAmount:
            return "Investment amount must be greater than zero"
        case .invalidFrequency:
            return "Invalid investment frequency"
        case .invalidDateRange:
            return "End date must be after start date"
        case .executionAlreadyCompleted:
            return "Execution has already been completed"
        case .executionCannotBeRetried:
            return "This execution cannot be retried"
        case .insufficientData:
            return "Insufficient historical data for simulation"
        }
    }
}
