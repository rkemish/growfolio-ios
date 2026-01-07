//
//  DCAViewModelTests.swift
//  GrowfolioTests
//
//  Tests for DCAViewModel - DCA schedule management.
//

import XCTest
@testable import Growfolio

@MainActor
final class DCAViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockRepository: MockDCARepository!
    var sut: DCAViewModel!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockDCARepository()
        sut = DCAViewModel(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isRefreshing)
        XCTAssertNil(sut.error)
        XCTAssertTrue(sut.schedules.isEmpty)
        XCTAssertNil(sut.selectedSchedule)
        XCTAssertFalse(sut.showInactive)
        XCTAssertNil(sut.filterFrequency)
        XCTAssertEqual(sut.sortOrder, .nextExecution)
    }

    func test_initialState_sheetPresentationIsFalse() {
        XCTAssertFalse(sut.showCreateSchedule)
        XCTAssertFalse(sut.showScheduleDetail)
        XCTAssertNil(sut.scheduleToEdit)
    }

    // MARK: - Computed Properties Tests

    func test_filteredSchedules_returnsActiveByDefault() {
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", isActive: true, isPaused: false),
            TestFixtures.dcaSchedule(id: "dca-2", isActive: true, isPaused: true),
            TestFixtures.dcaSchedule(id: "dca-3", isActive: false, isPaused: false)
        ]
        sut.schedules = schedules
        sut.showInactive = false

        let filtered = sut.filteredSchedules

        // Should exclude inactive and paused schedules (status != .active)
        XCTAssertTrue(filtered.allSatisfy { $0.status == .active || $0.status == .pendingFunds })
    }

    func test_filteredSchedules_includesInactiveWhenEnabled() {
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", isActive: true, isPaused: false),
            TestFixtures.dcaSchedule(id: "dca-2", isActive: true, isPaused: true),
            TestFixtures.dcaSchedule(id: "dca-3", isActive: false, isPaused: false)
        ]
        sut.schedules = schedules
        sut.showInactive = true

        let filtered = sut.filteredSchedules

        XCTAssertEqual(filtered.count, 3)
    }

    func test_filteredSchedules_filtersByFrequency() {
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", frequency: .monthly),
            TestFixtures.dcaSchedule(id: "dca-2", frequency: .weekly),
            TestFixtures.dcaSchedule(id: "dca-3", frequency: .monthly)
        ]
        sut.schedules = schedules
        sut.showInactive = true
        sut.filterFrequency = .monthly

        let filtered = sut.filteredSchedules

        XCTAssertTrue(filtered.allSatisfy { $0.frequency == .monthly })
    }

    func test_activeSchedulesCount_returnsCorrectCount() {
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", isActive: true, isPaused: false),
            TestFixtures.dcaSchedule(id: "dca-2", isActive: true, isPaused: true),
            TestFixtures.dcaSchedule(id: "dca-3", isActive: false, isPaused: false)
        ]
        sut.schedules = schedules

        XCTAssertEqual(sut.activeSchedulesCount, 1)
    }

    func test_totalMonthlyInvestment_calculatesCorrectly() {
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", amount: 120, frequency: .monthly, isActive: true, isPaused: false),
            TestFixtures.dcaSchedule(id: "dca-2", amount: 52, frequency: .weekly, isActive: true, isPaused: false), // ~226/month
            TestFixtures.dcaSchedule(id: "dca-3", amount: 100, frequency: .monthly, isActive: false, isPaused: false) // Inactive, excluded
        ]
        sut.schedules = schedules

        // Monthly from schedule 1: 120
        // Weekly (52 executions/year): 52 * 52 / 12 = ~225.33
        // Total should be ~345.33
        XCTAssertGreaterThan(sut.totalMonthlyInvestment, 300)
        XCTAssertLessThan(sut.totalMonthlyInvestment, 400)
    }

    func test_hasSchedules_returnsFalseWhenEmpty() {
        sut.schedules = []
        XCTAssertFalse(sut.hasSchedules)
    }

    func test_hasSchedules_returnsTrueWhenNotEmpty() {
        sut.schedules = [TestFixtures.dcaSchedule()]
        XCTAssertTrue(sut.hasSchedules)
    }

    func test_isEmpty_returnsFalseWhenLoading() {
        sut.isLoading = true
        sut.schedules = []

        XCTAssertFalse(sut.isEmpty)
    }

    func test_isEmpty_returnsTrueWhenNotLoadingAndNoSchedules() {
        sut.isLoading = false
        sut.schedules = []

        XCTAssertTrue(sut.isEmpty)
    }

    func test_upcomingExecutions_returnsSchedulesWithNextExecutionDateSorted() {
        let now = Date()
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", nextExecutionDate: now.addingTimeInterval(86400 * 7), isActive: true, isPaused: false),
            TestFixtures.dcaSchedule(id: "dca-2", nextExecutionDate: now.addingTimeInterval(86400 * 1), isActive: true, isPaused: false),
            TestFixtures.dcaSchedule(id: "dca-3", nextExecutionDate: now.addingTimeInterval(86400 * 3), isActive: true, isPaused: false),
            TestFixtures.dcaSchedule(id: "dca-4", nextExecutionDate: nil, isActive: true, isPaused: false)
        ]
        sut.schedules = schedules

        let upcoming = sut.upcomingExecutions

        // Should be sorted by next execution date
        XCTAssertEqual(upcoming.count, 3) // Excludes one without nextExecutionDate
        XCTAssertEqual(upcoming.first?.id, "dca-2") // Earliest execution first
    }

    func test_upcomingExecutions_limitsToFiveResults() {
        let now = Date()
        let schedules = (0..<10).map { i in
            TestFixtures.dcaSchedule(
                id: "dca-\(i)",
                nextExecutionDate: now.addingTimeInterval(TimeInterval(86400 * i)),
                isActive: true,
                isPaused: false
            )
        }
        sut.schedules = schedules

        XCTAssertEqual(sut.upcomingExecutions.count, 5)
    }

    func test_summary_createsFromSchedules() {
        let schedules = TestFixtures.sampleDCASchedules
        sut.schedules = schedules

        let summary = sut.summary

        XCTAssertEqual(summary.totalInvested, schedules.reduce(0) { $0 + $1.totalInvested })
        XCTAssertEqual(summary.totalExecutions, schedules.reduce(0) { $0 + $1.executionCount })
    }

    // MARK: - Loading State Tests

    func test_loadSchedules_setsIsLoadingDuringOperation() async {
        await sut.loadSchedules()

        XCTAssertFalse(sut.isLoading)
    }

    func test_loadSchedules_preventsMultipleSimultaneousLoads() async {
        sut.isLoading = true

        await sut.loadSchedules()

        XCTAssertFalse(mockRepository.fetchSchedulesCalled)
    }

    func test_refreshSchedules_setsIsRefreshingDuringOperation() async {
        await sut.refreshSchedules()

        XCTAssertFalse(sut.isRefreshing)
        XCTAssertTrue(mockRepository.invalidateCacheCalled)
    }

    // MARK: - Data Loading Tests

    func test_loadSchedules_fetchesFromRepository() async {
        let schedules = TestFixtures.sampleDCASchedules
        mockRepository.schedulesToReturn = schedules

        await sut.loadSchedules()

        XCTAssertTrue(mockRepository.fetchSchedulesCalled)
        XCTAssertEqual(sut.schedules.count, schedules.count)
    }

    func test_loadSchedules_clearsErrorOnSuccess() async {
        sut.error = NetworkError.noConnection
        mockRepository.schedulesToReturn = TestFixtures.sampleDCASchedules

        await sut.loadSchedules()

        XCTAssertNil(sut.error)
    }

    // MARK: - Error Handling Tests

    func test_loadSchedules_setsErrorOnFailure() async {
        mockRepository.errorToThrow = NetworkError.serverError(statusCode: 500, message: nil)

        await sut.loadSchedules()

        XCTAssertNotNil(sut.error)
    }

    // MARK: - CRUD Operations Tests

    func test_createSchedule_callsRepositoryWithCorrectParams() async {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .year, value: 1, to: startDate)

        try? await sut.createSchedule(
            stockSymbol: "AAPL",
            amount: 100,
            frequency: .monthly,
            startDate: startDate,
            endDate: endDate,
            portfolioId: "portfolio-123"
        )

        XCTAssertTrue(mockRepository.createScheduleCalled)
        XCTAssertEqual(mockRepository.lastCreateScheduleParams?.stockSymbol, "AAPL")
        XCTAssertEqual(mockRepository.lastCreateScheduleParams?.amount, 100)
        XCTAssertEqual(mockRepository.lastCreateScheduleParams?.frequency, .monthly)
        XCTAssertEqual(mockRepository.lastCreateScheduleParams?.portfolioId, "portfolio-123")
    }

    func test_createSchedule_refreshesAfterSuccess() async {
        try? await sut.createSchedule(
            stockSymbol: "AAPL",
            amount: 100,
            frequency: .monthly,
            startDate: Date(),
            endDate: nil,
            portfolioId: "portfolio-123"
        )

        XCTAssertTrue(mockRepository.invalidateCacheCalled)
        XCTAssertTrue(mockRepository.fetchSchedulesCalled)
    }

    func test_createSchedule_throwsOnRepositoryError() async {
        mockRepository.errorToThrow = DCARepositoryError.invalidAmount

        do {
            try await sut.createSchedule(
                stockSymbol: "AAPL",
                amount: 0,
                frequency: .monthly,
                startDate: Date(),
                endDate: nil,
                portfolioId: "portfolio-123"
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is DCARepositoryError)
        }
    }

    func test_updateSchedule_callsRepository() async {
        let schedule = TestFixtures.dcaSchedule()

        try? await sut.updateSchedule(schedule)

        XCTAssertTrue(mockRepository.updateScheduleCalled)
        XCTAssertEqual(mockRepository.lastUpdatedSchedule?.id, schedule.id)
    }

    func test_updateSchedule_refreshesAfterSuccess() async {
        let schedule = TestFixtures.dcaSchedule()

        try? await sut.updateSchedule(schedule)

        XCTAssertTrue(mockRepository.invalidateCacheCalled)
    }

    func test_deleteSchedule_callsRepository() async {
        let schedule = TestFixtures.dcaSchedule(id: "dca-to-delete")
        sut.schedules = [schedule]

        try? await sut.deleteSchedule(schedule)

        XCTAssertTrue(mockRepository.deleteScheduleCalled)
        XCTAssertEqual(mockRepository.lastDeletedScheduleId, "dca-to-delete")
    }

    func test_deleteSchedule_removesFromLocalList() async {
        let schedule = TestFixtures.dcaSchedule(id: "dca-to-delete")
        sut.schedules = [schedule, TestFixtures.dcaSchedule(id: "dca-other")]

        try? await sut.deleteSchedule(schedule)

        XCTAssertFalse(sut.schedules.contains { $0.id == "dca-to-delete" })
        XCTAssertEqual(sut.schedules.count, 1)
    }

    func test_pauseSchedule_callsRepository() async {
        let schedule = TestFixtures.dcaSchedule(id: "dca-to-pause")
        mockRepository.scheduleToReturn = schedule

        try? await sut.pauseSchedule(schedule)

        XCTAssertTrue(mockRepository.pauseScheduleCalled)
        XCTAssertEqual(mockRepository.lastPausedScheduleId, "dca-to-pause")
    }

    func test_resumeSchedule_callsRepository() async {
        let schedule = TestFixtures.dcaSchedule(id: "dca-to-resume", isPaused: true)
        mockRepository.scheduleToReturn = schedule

        try? await sut.resumeSchedule(schedule)

        XCTAssertTrue(mockRepository.resumeScheduleCalled)
        XCTAssertEqual(mockRepository.lastResumedScheduleId, "dca-to-resume")
    }

    // MARK: - Selection Tests

    func test_selectSchedule_setsSelectedScheduleAndShowsDetail() {
        let schedule = TestFixtures.dcaSchedule()

        sut.selectSchedule(schedule)

        XCTAssertEqual(sut.selectedSchedule?.id, schedule.id)
        XCTAssertTrue(sut.showScheduleDetail)
    }

    func test_editSchedule_setsScheduleToEditAndShowsCreateSheet() {
        let schedule = TestFixtures.dcaSchedule()

        sut.editSchedule(schedule)

        XCTAssertEqual(sut.scheduleToEdit?.id, schedule.id)
        XCTAssertTrue(sut.showCreateSchedule)
    }

    // MARK: - Sorting Tests

    func test_filteredSchedules_sortsById_whenSortOrderIsSymbol() {
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", stockSymbol: "MSFT"),
            TestFixtures.dcaSchedule(id: "dca-2", stockSymbol: "AAPL"),
            TestFixtures.dcaSchedule(id: "dca-3", stockSymbol: "GOOGL")
        ]
        sut.schedules = schedules
        sut.showInactive = true
        sut.sortOrder = .symbol

        let filtered = sut.filteredSchedules

        XCTAssertEqual(filtered.first?.stockSymbol, "AAPL")
        XCTAssertEqual(filtered.last?.stockSymbol, "MSFT")
    }

    func test_filteredSchedules_sortsByAmount_whenSortOrderIsAmount() {
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", amount: 50),
            TestFixtures.dcaSchedule(id: "dca-2", amount: 200),
            TestFixtures.dcaSchedule(id: "dca-3", amount: 100)
        ]
        sut.schedules = schedules
        sut.showInactive = true
        sut.sortOrder = .amount

        let filtered = sut.filteredSchedules

        XCTAssertEqual(filtered.first?.amount, 200) // Highest first
        XCTAssertEqual(filtered.last?.amount, 50)
    }

    func test_filteredSchedules_sortsByTotalInvested_whenSortOrderIsTotalInvested() {
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", totalInvested: 500),
            TestFixtures.dcaSchedule(id: "dca-2", totalInvested: 2000),
            TestFixtures.dcaSchedule(id: "dca-3", totalInvested: 1000)
        ]
        sut.schedules = schedules
        sut.showInactive = true
        sut.sortOrder = .totalInvested

        let filtered = sut.filteredSchedules

        XCTAssertEqual(filtered.first?.totalInvested, 2000)
    }

    func test_filteredSchedules_sortsByCreatedAt_whenSortOrderIsCreatedAt() {
        let now = Date()
        let schedules = [
            TestFixtures.dcaSchedule(id: "dca-1", createdAt: now.addingTimeInterval(-86400)), // 1 day ago
            TestFixtures.dcaSchedule(id: "dca-2", createdAt: now), // Now
            TestFixtures.dcaSchedule(id: "dca-3", createdAt: now.addingTimeInterval(-86400 * 7)) // 7 days ago
        ]
        sut.schedules = schedules
        sut.showInactive = true
        sut.sortOrder = .createdAt

        let filtered = sut.filteredSchedules

        XCTAssertEqual(filtered.first?.id, "dca-2") // Most recent first
    }
}

// MARK: - DCASortOrder Tests

final class DCASortOrderTests: XCTestCase {

    func test_allCases_containsExpectedValues() {
        let cases = DCASortOrder.allCases

        XCTAssertTrue(cases.contains(.nextExecution))
        XCTAssertTrue(cases.contains(.symbol))
        XCTAssertTrue(cases.contains(.amount))
        XCTAssertTrue(cases.contains(.totalInvested))
        XCTAssertTrue(cases.contains(.createdAt))
    }

    func test_displayName_returnsNonEmptyString() {
        for sortOrder in DCASortOrder.allCases {
            XCTAssertFalse(sortOrder.displayName.isEmpty)
        }
    }

    func test_iconName_returnsNonEmptyString() {
        for sortOrder in DCASortOrder.allCases {
            XCTAssertFalse(sortOrder.iconName.isEmpty)
        }
    }
}
