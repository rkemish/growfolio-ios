//
//  DCARepository.swift
//  Growfolio
//
//  Implementation of DCARepositoryProtocol using the API client.
//

import Foundation

/// Implementation of the DCA repository using the API client
final class DCARepository: DCARepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let apiClient: APIClientProtocol
    private var cachedSchedules: [DCASchedule] = []
    private var lastFetchTime: Date?
    private let cacheDuration: TimeInterval = 60 // 1 minute cache

    // MARK: - Initialization

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - Schedule Operations

    func fetchSchedules() async throws -> [DCASchedule] {
        // Check cache first
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheDuration,
           !cachedSchedules.isEmpty {
            return cachedSchedules
        }

        let schedules: [DCASchedule] = try await apiClient.request(Endpoints.GetDCASchedules())

        cachedSchedules = schedules
        lastFetchTime = Date()

        return schedules
    }

    func fetchActiveSchedules() async throws -> [DCASchedule] {
        let schedules = try await fetchSchedules()
        return schedules.filter { $0.status == .active }
    }

    func fetchSchedule(id: String) async throws -> DCASchedule {
        // Check cache first
        if let cached = cachedSchedules.first(where: { $0.id == id }) {
            return cached
        }

        return try await apiClient.request(Endpoints.GetDCASchedule(id: id))
    }

    func fetchSchedules(for symbol: String) async throws -> [DCASchedule] {
        let schedules = try await fetchSchedules()
        return schedules.filter { $0.stockSymbol.uppercased() == symbol.uppercased() }
    }

    func fetchSchedules(linkedToPortfolio portfolioId: String) async throws -> [DCASchedule] {
        let schedules = try await fetchSchedules()
        return schedules.filter { $0.portfolioId == portfolioId }
    }

    func createSchedule(_ schedule: DCASchedule) async throws -> DCASchedule {
        let request = DCAScheduleCreateRequest(
            stockSymbol: schedule.stockSymbol,
            amount: schedule.amount,
            frequency: schedule.frequency.rawValue,
            startDate: schedule.startDate,
            endDate: schedule.endDate,
            portfolioId: schedule.portfolioId
        )

        let createdSchedule: DCASchedule = try await apiClient.request(
            try Endpoints.CreateDCASchedule(schedule: request)
        )

        // Update cache
        cachedSchedules.append(createdSchedule)

        return createdSchedule
    }

    func createSchedule(
        stockSymbol: String,
        amount: Decimal,
        frequency: DCAFrequency,
        startDate: Date,
        endDate: Date?,
        portfolioId: String
    ) async throws -> DCASchedule {
        let request = DCAScheduleCreateRequest(
            stockSymbol: stockSymbol,
            amount: amount,
            frequency: frequency.rawValue,
            startDate: startDate,
            endDate: endDate,
            portfolioId: portfolioId
        )

        let createdSchedule: DCASchedule = try await apiClient.request(
            try Endpoints.CreateDCASchedule(schedule: request)
        )

        // Update cache
        cachedSchedules.append(createdSchedule)

        return createdSchedule
    }

    func updateSchedule(_ schedule: DCASchedule) async throws -> DCASchedule {
        let request = DCAScheduleUpdateRequest(
            amount: schedule.amount,
            frequency: schedule.frequency.rawValue,
            endDate: schedule.endDate,
            isActive: schedule.isActive
        )

        let updatedSchedule: DCASchedule = try await apiClient.request(
            try Endpoints.UpdateDCASchedule(id: schedule.id, update: request)
        )

        // Update cache
        if let index = cachedSchedules.firstIndex(where: { $0.id == schedule.id }) {
            cachedSchedules[index] = updatedSchedule
        }

        return updatedSchedule
    }

    func updateScheduleAmount(id: String, amount: Decimal) async throws -> DCASchedule {
        let request = DCAScheduleUpdateRequest(amount: amount)

        let updatedSchedule: DCASchedule = try await apiClient.request(
            try Endpoints.UpdateDCASchedule(id: id, update: request)
        )

        // Update cache
        if let index = cachedSchedules.firstIndex(where: { $0.id == id }) {
            cachedSchedules[index] = updatedSchedule
        }

        return updatedSchedule
    }

    func updateScheduleFrequency(id: String, frequency: DCAFrequency) async throws -> DCASchedule {
        let request = DCAScheduleUpdateRequest(frequency: frequency.rawValue)

        let updatedSchedule: DCASchedule = try await apiClient.request(
            try Endpoints.UpdateDCASchedule(id: id, update: request)
        )

        // Update cache
        if let index = cachedSchedules.firstIndex(where: { $0.id == id }) {
            cachedSchedules[index] = updatedSchedule
        }

        return updatedSchedule
    }

    func pauseSchedule(id: String) async throws -> DCASchedule {
        let request = DCAScheduleUpdateRequest(isActive: false)

        let updatedSchedule: DCASchedule = try await apiClient.request(
            try Endpoints.UpdateDCASchedule(id: id, update: request)
        )

        // Update cache
        if let index = cachedSchedules.firstIndex(where: { $0.id == id }) {
            cachedSchedules[index] = updatedSchedule
        }

        return updatedSchedule
    }

    func resumeSchedule(id: String) async throws -> DCASchedule {
        let request = DCAScheduleUpdateRequest(isActive: true)

        let updatedSchedule: DCASchedule = try await apiClient.request(
            try Endpoints.UpdateDCASchedule(id: id, update: request)
        )

        // Update cache
        if let index = cachedSchedules.firstIndex(where: { $0.id == id }) {
            cachedSchedules[index] = updatedSchedule
        }

        return updatedSchedule
    }

    func cancelSchedule(id: String) async throws -> DCASchedule {
        let request = DCAScheduleUpdateRequest(isActive: false)

        let updatedSchedule: DCASchedule = try await apiClient.request(
            try Endpoints.UpdateDCASchedule(id: id, update: request)
        )

        // Update cache
        if let index = cachedSchedules.firstIndex(where: { $0.id == id }) {
            cachedSchedules[index] = updatedSchedule
        }

        return updatedSchedule
    }

    func deleteSchedule(id: String) async throws {
        try await apiClient.request(Endpoints.DeleteDCASchedule(id: id))

        // Update cache
        cachedSchedules.removeAll { $0.id == id }
    }

    // MARK: - Execution Operations

    func fetchExecutions(for scheduleId: String, page: Int, limit: Int) async throws -> PaginatedResponse<DCAExecution> {
        // The backend returns execution history as part of schedule
        // For now, create a paginated response from the schedule's execution data
        let schedule = try await fetchSchedule(id: scheduleId)

        // This would need a dedicated endpoint in the backend
        // For now, return empty
        return PaginatedResponse(
            data: [],
            pagination: PaginatedResponse<DCAExecution>.Pagination(
                page: page,
                limit: limit,
                totalPages: 1,
                totalItems: 0
            )
        )
    }

    func fetchAllExecutions(for scheduleId: String) async throws -> [DCAExecution] {
        // This would need a dedicated endpoint
        return []
    }

    func fetchExecution(id executionId: String) async throws -> DCAExecution {
        throw DCARepositoryError.executionNotFound(id: executionId)
    }

    func fetchRecentExecutions(limit: Int) async throws -> [DCAExecution] {
        // This would need a dedicated endpoint
        return []
    }

    func executeNow(scheduleId: String) async throws -> DCAExecution {
        // This would trigger immediate execution on the backend
        throw DCARepositoryError.scheduleNotFound(id: scheduleId)
    }

    func retryExecution(id executionId: String) async throws -> DCAExecution {
        throw DCARepositoryError.executionCannotBeRetried
    }

    // MARK: - Simulation Operations

    func simulateDCA(
        symbol: String,
        amount: Decimal,
        frequency: DCAFrequency,
        startDate: Date,
        endDate: Date
    ) async throws -> DCASimulation {
        // This would need a dedicated backend endpoint
        throw DCARepositoryError.insufficientData
    }

    func projectReturns(
        for scheduleId: String,
        projectionMonths: Int,
        expectedAnnualReturn: Decimal
    ) async throws -> DCAProjection {
        // This would need a dedicated backend endpoint
        throw DCARepositoryError.insufficientData
    }

    // MARK: - Summary Operations

    func fetchDCASummary() async throws -> DCASummary {
        let schedules = try await fetchSchedules()
        return DCASummary(schedules: schedules)
    }

    func fetchUpcomingExecutions(days: Int) async throws -> [UpcomingExecution] {
        let schedules = try await fetchActiveSchedules()
        let now = Date()
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .day, value: days, to: now) ?? now

        return schedules.compactMap { schedule -> UpcomingExecution? in
            guard let nextDate = schedule.nextExecutionDate,
                  nextDate >= now && nextDate <= futureDate else {
                return nil
            }

            return UpcomingExecution(
                scheduleId: schedule.id,
                stockSymbol: schedule.stockSymbol,
                stockName: schedule.stockName,
                amount: schedule.amount,
                executionDate: nextDate,
                portfolioId: schedule.portfolioId,
                portfolioName: nil
            )
        }.sorted { $0.executionDate < $1.executionDate }
    }

    // MARK: - Cache Operations

    func invalidateCache() async {
        cachedSchedules = []
        lastFetchTime = nil
    }

    func prefetchSchedules() async throws {
        _ = try await fetchSchedules()
    }
}
