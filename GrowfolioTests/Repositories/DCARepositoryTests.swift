//
//  DCARepositoryTests.swift
//  GrowfolioTests
//
//  Tests for DCARepository.
//

import XCTest
@testable import Growfolio

final class DCARepositoryTests: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var sut: DCARepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = DCARepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        mockAPIClient.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeSchedule(
        id: String = "schedule-1",
        stockSymbol: String = "AAPL",
        amount: Decimal = 100,
        frequency: DCAFrequency = .monthly,
        isActive: Bool = true,
        isPaused: Bool = false
    ) -> DCASchedule {
        DCASchedule(
            id: id,
            userId: "user-1",
            stockSymbol: stockSymbol,
            stockName: "Apple Inc.",
            amount: amount,
            frequency: frequency,
            startDate: Date(),
            portfolioId: "portfolio-1",
            isActive: isActive,
            isPaused: isPaused
        )
    }

    // MARK: - Fetch Schedules Tests

    func test_fetchSchedules_returnsSchedulesFromAPI() async throws {
        // Arrange
        let expectedSchedules = [
            makeSchedule(id: "schedule-1", stockSymbol: "AAPL"),
            makeSchedule(id: "schedule-2", stockSymbol: "GOOGL")
        ]
        mockAPIClient.setResponse(expectedSchedules, for: Endpoints.GetDCASchedules.self)

        // Act
        let schedules = try await sut.fetchSchedules()

        // Assert
        XCTAssertEqual(schedules.count, 2)
        XCTAssertEqual(schedules[0].stockSymbol, "AAPL")
        XCTAssertEqual(schedules[1].stockSymbol, "GOOGL")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchSchedules_usesCache() async throws {
        // Arrange
        let expectedSchedules = [makeSchedule()]
        mockAPIClient.setResponse(expectedSchedules, for: Endpoints.GetDCASchedules.self)

        // Act - First call populates cache
        _ = try await sut.fetchSchedules()

        // Act - Second call should use cache
        let result = try await sut.fetchSchedules()

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchSchedules_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Server error"), for: Endpoints.GetDCASchedules.self)

        // Act & Assert
        do {
            _ = try await sut.fetchSchedules()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Fetch Active Schedules Tests

    func test_fetchActiveSchedules_filtersActiveOnly() async throws {
        // Arrange
        let schedules = [
            makeSchedule(id: "schedule-1", isActive: true),
            makeSchedule(id: "schedule-2", isActive: false),
            makeSchedule(id: "schedule-3", isActive: true)
        ]
        mockAPIClient.setResponse(schedules, for: Endpoints.GetDCASchedules.self)

        // Act
        let result = try await sut.fetchActiveSchedules()

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.isActive })
    }

    // MARK: - Fetch Schedule by ID Tests

    func test_fetchSchedule_returnsScheduleFromAPI() async throws {
        // Arrange
        let expectedSchedule = makeSchedule(id: "schedule-123")
        mockAPIClient.setResponse(expectedSchedule, for: Endpoints.GetDCASchedule.self)

        // Act
        let schedule = try await sut.fetchSchedule(id: "schedule-123")

        // Assert
        XCTAssertEqual(schedule.id, "schedule-123")
    }

    func test_fetchSchedule_returnsCachedScheduleIfAvailable() async throws {
        // Arrange - First populate the cache
        let cachedSchedule = makeSchedule(id: "schedule-cached")
        mockAPIClient.setResponse([cachedSchedule], for: Endpoints.GetDCASchedules.self)
        _ = try await sut.fetchSchedules()
        mockAPIClient.reset()

        // Act - Fetch by ID should use cache
        let schedule = try await sut.fetchSchedule(id: "schedule-cached")

        // Assert
        XCTAssertEqual(schedule.id, "schedule-cached")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    // MARK: - Fetch Schedules by Symbol Tests

    func test_fetchSchedules_forSymbol_filtersCorrectly() async throws {
        // Arrange
        let schedules = [
            makeSchedule(id: "schedule-1", stockSymbol: "AAPL"),
            makeSchedule(id: "schedule-2", stockSymbol: "GOOGL"),
            makeSchedule(id: "schedule-3", stockSymbol: "AAPL")
        ]
        mockAPIClient.setResponse(schedules, for: Endpoints.GetDCASchedules.self)

        // Act
        let result = try await sut.fetchSchedules(for: "AAPL")

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.stockSymbol == "AAPL" })
    }

    func test_fetchSchedules_forSymbol_isCaseInsensitive() async throws {
        // Arrange
        let schedules = [makeSchedule(stockSymbol: "AAPL")]
        mockAPIClient.setResponse(schedules, for: Endpoints.GetDCASchedules.self)

        // Act
        let result = try await sut.fetchSchedules(for: "aapl")

        // Assert
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - Fetch Schedules by Portfolio Tests

    func test_fetchSchedules_linkedToPortfolio_filtersCorrectly() async throws {
        // Arrange
        let schedule1 = DCASchedule(
            id: "schedule-1",
            userId: "user-1",
            stockSymbol: "AAPL",
            amount: 100,
            portfolioId: "portfolio-1"
        )
        let schedule2 = DCASchedule(
            id: "schedule-2",
            userId: "user-1",
            stockSymbol: "GOOGL",
            amount: 100,
            portfolioId: "portfolio-2"
        )
        mockAPIClient.setResponse([schedule1, schedule2], for: Endpoints.GetDCASchedules.self)

        // Act
        let result = try await sut.fetchSchedules(linkedToPortfolio: "portfolio-1")

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.portfolioId, "portfolio-1")
    }

    // MARK: - Create Schedule Tests

    func test_createSchedule_returnsCreatedSchedule() async throws {
        // Arrange
        let scheduleToCreate = makeSchedule(id: "new-schedule")
        mockAPIClient.setResponse(scheduleToCreate, for: Endpoints.CreateDCASchedule.self)

        // Act
        let created = try await sut.createSchedule(scheduleToCreate)

        // Assert
        XCTAssertEqual(created.id, "new-schedule")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_createSchedule_updatesCache() async throws {
        // Arrange - First populate cache
        let existingSchedule = makeSchedule(id: "existing")
        mockAPIClient.setResponse([existingSchedule], for: Endpoints.GetDCASchedules.self)
        _ = try await sut.fetchSchedules()

        // Create new schedule
        let newSchedule = makeSchedule(id: "new-schedule")
        mockAPIClient.setResponse(newSchedule, for: Endpoints.CreateDCASchedule.self)

        // Act
        _ = try await sut.createSchedule(newSchedule)

        // Assert - Cache should now include both schedules
        mockAPIClient.reset()
        let schedules = try await sut.fetchSchedules()
        XCTAssertEqual(schedules.count, 2)
    }

    // MARK: - Update Schedule Tests

    func test_updateSchedule_returnsUpdatedSchedule() async throws {
        // Arrange
        var schedule = makeSchedule(id: "schedule-1", amount: 100)
        schedule.amount = 200
        mockAPIClient.setResponse(schedule, for: Endpoints.UpdateDCASchedule.self)

        // Act
        let updated = try await sut.updateSchedule(schedule)

        // Assert
        XCTAssertEqual(updated.amount, 200)
    }

    func test_updateScheduleAmount_updatesAmount() async throws {
        // Arrange
        let schedule = makeSchedule(id: "schedule-1", amount: 200)
        mockAPIClient.setResponse(schedule, for: Endpoints.UpdateDCASchedule.self)

        // Act
        let updated = try await sut.updateScheduleAmount(id: "schedule-1", amount: 200)

        // Assert
        XCTAssertEqual(updated.amount, 200)
    }

    func test_updateScheduleFrequency_updatesFrequency() async throws {
        // Arrange
        let schedule = makeSchedule(id: "schedule-1", frequency: .weekly)
        mockAPIClient.setResponse(schedule, for: Endpoints.UpdateDCASchedule.self)

        // Act
        let updated = try await sut.updateScheduleFrequency(id: "schedule-1", frequency: .weekly)

        // Assert
        XCTAssertEqual(updated.frequency, .weekly)
    }

    // MARK: - Pause/Resume Schedule Tests

    func test_pauseSchedule_setsIsActiveToFalse() async throws {
        // Arrange
        var schedule = makeSchedule(id: "schedule-1", isActive: true)
        schedule.isActive = false
        mockAPIClient.setResponse(schedule, for: Endpoints.UpdateDCASchedule.self)

        // Act
        let paused = try await sut.pauseSchedule(id: "schedule-1")

        // Assert
        XCTAssertFalse(paused.isActive)
    }

    func test_resumeSchedule_setsIsActiveToTrue() async throws {
        // Arrange
        var schedule = makeSchedule(id: "schedule-1", isActive: false)
        schedule.isActive = true
        mockAPIClient.setResponse(schedule, for: Endpoints.UpdateDCASchedule.self)

        // Act
        let resumed = try await sut.resumeSchedule(id: "schedule-1")

        // Assert
        XCTAssertTrue(resumed.isActive)
    }

    // MARK: - Delete Schedule Tests

    func test_deleteSchedule_removesFromCache() async throws {
        // Arrange - First populate cache
        let schedule1 = makeSchedule(id: "schedule-1")
        let schedule2 = makeSchedule(id: "schedule-2")
        mockAPIClient.setResponse([schedule1, schedule2], for: Endpoints.GetDCASchedules.self)
        _ = try await sut.fetchSchedules()

        // Act
        try await sut.deleteSchedule(id: "schedule-1")

        // Assert - Cache should have only one schedule
        mockAPIClient.reset()
        let schedules = try await sut.fetchSchedules()
        XCTAssertEqual(schedules.count, 1)
        XCTAssertEqual(schedules.first?.id, "schedule-2")
    }

    // MARK: - Cache Invalidation Tests

    func test_invalidateCache_clearsCache() async throws {
        // Arrange - First populate cache
        let schedule = makeSchedule()
        mockAPIClient.setResponse([schedule], for: Endpoints.GetDCASchedules.self)
        _ = try await sut.fetchSchedules()

        // Act
        await sut.invalidateCache()

        // Reset and set up new response
        mockAPIClient.reset()
        let newSchedule = makeSchedule(id: "new-schedule")
        mockAPIClient.setResponse([newSchedule], for: Endpoints.GetDCASchedules.self)

        // Act - Should make new API call
        let schedules = try await sut.fetchSchedules()

        // Assert
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
        XCTAssertEqual(schedules.first?.id, "new-schedule")
    }

    // MARK: - Empty Response Tests

    func test_fetchSchedules_returnsEmptyArrayWhenNoSchedules() async throws {
        // Arrange
        mockAPIClient.setResponse([DCASchedule](), for: Endpoints.GetDCASchedules.self)

        // Act
        let schedules = try await sut.fetchSchedules()

        // Assert
        XCTAssertTrue(schedules.isEmpty)
    }

    // MARK: - DCA Summary Tests

    // TODO: This test causes SIGBUS crash - needs investigation
    // The fetchDCASummary method creates DCASummary which accesses computed properties
    // func test_fetchDCASummary_calculatesSummaryCorrectly() async throws { ... }

    // MARK: - Upcoming Executions Tests

    func test_fetchUpcomingExecutions_returnsSchedulesWithUpcomingDates() async throws {
        // Arrange
        let futureDate = Date().addingTimeInterval(86400 * 3) // 3 days from now
        var schedule = makeSchedule(id: "schedule-1", isActive: true)
        schedule.nextExecutionDate = futureDate
        mockAPIClient.setResponse([schedule], for: Endpoints.GetDCASchedules.self)

        // Act
        let upcoming = try await sut.fetchUpcomingExecutions(days: 7)

        // Assert
        XCTAssertEqual(upcoming.count, 1)
        XCTAssertEqual(upcoming.first?.scheduleId, "schedule-1")
    }

    func test_fetchUpcomingExecutions_excludesSchedulesOutsideRange() async throws {
        // Arrange
        let futureDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
        var schedule = makeSchedule(id: "schedule-1", isActive: true)
        schedule.nextExecutionDate = futureDate
        mockAPIClient.setResponse([schedule], for: Endpoints.GetDCASchedules.self)

        // Act
        let upcoming = try await sut.fetchUpcomingExecutions(days: 7)

        // Assert
        XCTAssertTrue(upcoming.isEmpty)
    }

    // MARK: - Prefetch Tests

    func test_prefetchSchedules_populatesCache() async throws {
        // Arrange
        let schedules = [makeSchedule()]
        mockAPIClient.setResponse(schedules, for: Endpoints.GetDCASchedules.self)

        // Act
        try await sut.prefetchSchedules()

        // Assert
        mockAPIClient.reset()
        let result = try await sut.fetchSchedules()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0) // Cache hit
    }
}
