//
//  MockDCARepository.swift
//  GrowfolioTests
//
//  Mock DCA repository for testing.
//

import Foundation
@testable import Growfolio

/// Mock DCA repository that returns predefined responses for testing
final class MockDCARepository: DCARepositoryProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    var schedulesToReturn: [DCASchedule] = []
    var scheduleToReturn: DCASchedule?
    var executionsToReturn: [DCAExecution] = []
    var executionToReturn: DCAExecution?
    var paginatedExecutionsToReturn: PaginatedResponse<DCAExecution>?
    var simulationToReturn: DCASimulation?
    var projectionToReturn: DCAProjection?
    var summaryToReturn: DCASummary?
    var upcomingExecutionsToReturn: [UpcomingExecution] = []
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var fetchSchedulesCalled = false
    var fetchActiveSchedulesCalled = false
    var fetchScheduleCalled = false
    var lastFetchedScheduleId: String?
    var fetchSchedulesForSymbolCalled = false
    var lastFetchedSymbol: String?
    var fetchSchedulesLinkedToPortfolioCalled = false
    var lastLinkedPortfolioId: String?
    var createScheduleCalled = false
    var lastCreatedSchedule: DCASchedule?
    var lastCreateScheduleParams: (stockSymbol: String, amount: Decimal, frequency: DCAFrequency, startDate: Date, endDate: Date?, portfolioId: String)?
    var updateScheduleCalled = false
    var lastUpdatedSchedule: DCASchedule?
    var updateScheduleAmountCalled = false
    var updateScheduleFrequencyCalled = false
    var pauseScheduleCalled = false
    var lastPausedScheduleId: String?
    var resumeScheduleCalled = false
    var lastResumedScheduleId: String?
    var cancelScheduleCalled = false
    var lastCancelledScheduleId: String?
    var deleteScheduleCalled = false
    var lastDeletedScheduleId: String?
    var fetchExecutionsCalled = false
    var fetchAllExecutionsCalled = false
    var fetchExecutionCalled = false
    var fetchRecentExecutionsCalled = false
    var executeNowCalled = false
    var retryExecutionCalled = false
    var simulateDCACalled = false
    var projectReturnsCalled = false
    var fetchDCASummaryCalled = false
    var fetchUpcomingExecutionsCalled = false
    var invalidateCacheCalled = false
    var prefetchSchedulesCalled = false

    // MARK: - Reset

    func reset() {
        schedulesToReturn = []
        scheduleToReturn = nil
        executionsToReturn = []
        executionToReturn = nil
        paginatedExecutionsToReturn = nil
        simulationToReturn = nil
        projectionToReturn = nil
        summaryToReturn = nil
        upcomingExecutionsToReturn = []
        errorToThrow = nil

        fetchSchedulesCalled = false
        fetchActiveSchedulesCalled = false
        fetchScheduleCalled = false
        lastFetchedScheduleId = nil
        fetchSchedulesForSymbolCalled = false
        lastFetchedSymbol = nil
        fetchSchedulesLinkedToPortfolioCalled = false
        lastLinkedPortfolioId = nil
        createScheduleCalled = false
        lastCreatedSchedule = nil
        lastCreateScheduleParams = nil
        updateScheduleCalled = false
        lastUpdatedSchedule = nil
        updateScheduleAmountCalled = false
        updateScheduleFrequencyCalled = false
        pauseScheduleCalled = false
        lastPausedScheduleId = nil
        resumeScheduleCalled = false
        lastResumedScheduleId = nil
        cancelScheduleCalled = false
        lastCancelledScheduleId = nil
        deleteScheduleCalled = false
        lastDeletedScheduleId = nil
        fetchExecutionsCalled = false
        fetchAllExecutionsCalled = false
        fetchExecutionCalled = false
        fetchRecentExecutionsCalled = false
        executeNowCalled = false
        retryExecutionCalled = false
        simulateDCACalled = false
        projectReturnsCalled = false
        fetchDCASummaryCalled = false
        fetchUpcomingExecutionsCalled = false
        invalidateCacheCalled = false
        prefetchSchedulesCalled = false
    }

    // MARK: - DCARepositoryProtocol Implementation

    func fetchSchedules() async throws -> [DCASchedule] {
        fetchSchedulesCalled = true
        if let error = errorToThrow { throw error }
        return schedulesToReturn
    }

    func fetchActiveSchedules() async throws -> [DCASchedule] {
        fetchActiveSchedulesCalled = true
        if let error = errorToThrow { throw error }
        return schedulesToReturn.filter { $0.isActive && !$0.isPaused }
    }

    func fetchSchedule(id: String) async throws -> DCASchedule {
        fetchScheduleCalled = true
        lastFetchedScheduleId = id
        if let error = errorToThrow { throw error }
        if let schedule = scheduleToReturn { return schedule }
        throw DCARepositoryError.scheduleNotFound(id: id)
    }

    func fetchSchedules(for symbol: String) async throws -> [DCASchedule] {
        fetchSchedulesForSymbolCalled = true
        lastFetchedSymbol = symbol
        if let error = errorToThrow { throw error }
        return schedulesToReturn.filter { $0.stockSymbol == symbol }
    }

    func fetchSchedules(linkedToPortfolio portfolioId: String) async throws -> [DCASchedule] {
        fetchSchedulesLinkedToPortfolioCalled = true
        lastLinkedPortfolioId = portfolioId
        if let error = errorToThrow { throw error }
        return schedulesToReturn.filter { $0.portfolioId == portfolioId }
    }

    func createSchedule(_ schedule: DCASchedule) async throws -> DCASchedule {
        createScheduleCalled = true
        lastCreatedSchedule = schedule
        if let error = errorToThrow { throw error }
        return schedule
    }

    func createSchedule(
        stockSymbol: String,
        amount: Decimal,
        frequency: DCAFrequency,
        startDate: Date,
        endDate: Date?,
        portfolioId: String
    ) async throws -> DCASchedule {
        createScheduleCalled = true
        lastCreateScheduleParams = (stockSymbol, amount, frequency, startDate, endDate, portfolioId)
        if let error = errorToThrow { throw error }
        let schedule = DCASchedule(
            userId: "user-123",
            stockSymbol: stockSymbol,
            amount: amount,
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            portfolioId: portfolioId
        )
        return schedule
    }

    func updateSchedule(_ schedule: DCASchedule) async throws -> DCASchedule {
        updateScheduleCalled = true
        lastUpdatedSchedule = schedule
        if let error = errorToThrow { throw error }
        return schedule
    }

    func updateScheduleAmount(id: String, amount: Decimal) async throws -> DCASchedule {
        updateScheduleAmountCalled = true
        if let error = errorToThrow { throw error }
        if var schedule = scheduleToReturn {
            schedule.amount = amount
            return schedule
        }
        throw DCARepositoryError.scheduleNotFound(id: id)
    }

    func updateScheduleFrequency(id: String, frequency: DCAFrequency) async throws -> DCASchedule {
        updateScheduleFrequencyCalled = true
        if let error = errorToThrow { throw error }
        if var schedule = scheduleToReturn {
            schedule.frequency = frequency
            return schedule
        }
        throw DCARepositoryError.scheduleNotFound(id: id)
    }

    func pauseSchedule(id: String) async throws -> DCASchedule {
        pauseScheduleCalled = true
        lastPausedScheduleId = id
        if let error = errorToThrow { throw error }
        if var schedule = scheduleToReturn {
            schedule.isPaused = true
            return schedule
        }
        throw DCARepositoryError.scheduleNotFound(id: id)
    }

    func resumeSchedule(id: String) async throws -> DCASchedule {
        resumeScheduleCalled = true
        lastResumedScheduleId = id
        if let error = errorToThrow { throw error }
        if var schedule = scheduleToReturn {
            schedule.isPaused = false
            return schedule
        }
        throw DCARepositoryError.scheduleNotFound(id: id)
    }

    func cancelSchedule(id: String) async throws -> DCASchedule {
        cancelScheduleCalled = true
        lastCancelledScheduleId = id
        if let error = errorToThrow { throw error }
        if var schedule = scheduleToReturn {
            schedule.isActive = false
            return schedule
        }
        throw DCARepositoryError.scheduleNotFound(id: id)
    }

    func deleteSchedule(id: String) async throws {
        deleteScheduleCalled = true
        lastDeletedScheduleId = id
        if let error = errorToThrow { throw error }
    }

    func fetchExecutions(for scheduleId: String, page: Int, limit: Int) async throws -> PaginatedResponse<DCAExecution> {
        fetchExecutionsCalled = true
        if let error = errorToThrow { throw error }
        if let paginated = paginatedExecutionsToReturn { return paginated }
        return PaginatedResponse(
            data: executionsToReturn,
            pagination: PaginatedResponse<DCAExecution>.Pagination(
                page: page,
                limit: limit,
                totalPages: 1,
                totalItems: executionsToReturn.count
            )
        )
    }

    func fetchAllExecutions(for scheduleId: String) async throws -> [DCAExecution] {
        fetchAllExecutionsCalled = true
        if let error = errorToThrow { throw error }
        return executionsToReturn
    }

    func fetchExecution(id executionId: String) async throws -> DCAExecution {
        fetchExecutionCalled = true
        if let error = errorToThrow { throw error }
        if let execution = executionToReturn { return execution }
        throw DCARepositoryError.executionNotFound(id: executionId)
    }

    func fetchRecentExecutions(limit: Int) async throws -> [DCAExecution] {
        fetchRecentExecutionsCalled = true
        if let error = errorToThrow { throw error }
        return Array(executionsToReturn.prefix(limit))
    }

    func executeNow(scheduleId: String) async throws -> DCAExecution {
        executeNowCalled = true
        if let error = errorToThrow { throw error }
        if let execution = executionToReturn { return execution }
        return DCAExecution(
            scheduleId: scheduleId,
            stockSymbol: "AAPL",
            amount: 100,
            sharesAcquired: 0.5,
            pricePerShare: 200
        )
    }

    func retryExecution(id executionId: String) async throws -> DCAExecution {
        retryExecutionCalled = true
        if let error = errorToThrow { throw error }
        if let execution = executionToReturn { return execution }
        throw DCARepositoryError.executionNotFound(id: executionId)
    }

    func simulateDCA(
        symbol: String,
        amount: Decimal,
        frequency: DCAFrequency,
        startDate: Date,
        endDate: Date
    ) async throws -> DCASimulation {
        simulateDCACalled = true
        if let error = errorToThrow { throw error }
        if let simulation = simulationToReturn { return simulation }
        return DCASimulation(
            symbol: symbol,
            amount: amount,
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            totalInvested: 1200,
            finalValue: 1500,
            totalShares: 10,
            averageCost: 120,
            totalReturn: 300,
            totalReturnPercent: 25,
            executionCount: 12,
            dataPoints: []
        )
    }

    func projectReturns(
        for scheduleId: String,
        projectionMonths: Int,
        expectedAnnualReturn: Decimal
    ) async throws -> DCAProjection {
        projectReturnsCalled = true
        if let error = errorToThrow { throw error }
        if let projection = projectionToReturn { return projection }
        return DCAProjection(
            scheduleId: scheduleId,
            projectionMonths: projectionMonths,
            expectedAnnualReturn: expectedAnnualReturn,
            projectedInvestment: 1200,
            projectedValue: 1500,
            projectedReturn: 300,
            projectedReturnPercent: 25,
            dataPoints: []
        )
    }

    func fetchDCASummary() async throws -> DCASummary {
        fetchDCASummaryCalled = true
        if let error = errorToThrow { throw error }
        if let summary = summaryToReturn { return summary }
        return DCASummary(schedules: schedulesToReturn)
    }

    func fetchUpcomingExecutions(days: Int) async throws -> [UpcomingExecution] {
        fetchUpcomingExecutionsCalled = true
        if let error = errorToThrow { throw error }
        return upcomingExecutionsToReturn
    }

    func invalidateCache() async {
        invalidateCacheCalled = true
    }

    func prefetchSchedules() async throws {
        prefetchSchedulesCalled = true
        if let error = errorToThrow { throw error }
    }
}
