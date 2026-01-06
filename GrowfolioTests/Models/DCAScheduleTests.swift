//
//  DCAScheduleTests.swift
//  GrowfolioTests
//
//  Tests for DCASchedule domain model.
//

import XCTest
@testable import Growfolio

final class DCAScheduleTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithDefaults() {
        let schedule = DCASchedule(
            userId: "user-123",
            stockSymbol: "AAPL",
            amount: 100,
            portfolioId: "portfolio-123"
        )

        XCTAssertFalse(schedule.id.isEmpty)
        XCTAssertEqual(schedule.userId, "user-123")
        XCTAssertEqual(schedule.stockSymbol, "AAPL")
        XCTAssertEqual(schedule.amount, 100)
        XCTAssertEqual(schedule.frequency, .monthly)
        XCTAssertNil(schedule.preferredDayOfWeek)
        XCTAssertNil(schedule.preferredDayOfMonth)
        XCTAssertNil(schedule.endDate)
        XCTAssertTrue(schedule.isActive)
        XCTAssertFalse(schedule.isPaused)
        XCTAssertEqual(schedule.totalInvested, 0)
        XCTAssertEqual(schedule.executionCount, 0)
    }

    func testInit_WithAllParameters() {
        let schedule = TestFixtures.dcaSchedule(
            id: "dca-456",
            userId: "user-456",
            stockSymbol: "MSFT",
            stockName: "Microsoft Corporation",
            amount: 250,
            frequency: .weekly,
            preferredDayOfWeek: 2,
            preferredDayOfMonth: nil,
            isActive: true,
            isPaused: false,
            totalInvested: 3000,
            executionCount: 12
        )

        XCTAssertEqual(schedule.id, "dca-456")
        XCTAssertEqual(schedule.userId, "user-456")
        XCTAssertEqual(schedule.stockSymbol, "MSFT")
        XCTAssertEqual(schedule.stockName, "Microsoft Corporation")
        XCTAssertEqual(schedule.amount, 250)
        XCTAssertEqual(schedule.frequency, .weekly)
        XCTAssertEqual(schedule.preferredDayOfWeek, 2)
        XCTAssertEqual(schedule.totalInvested, 3000)
        XCTAssertEqual(schedule.executionCount, 12)
    }

    // MARK: - Computed Properties Tests

    func testDisplayName_WithStockName() {
        let schedule = TestFixtures.dcaSchedule(
            stockSymbol: "AAPL",
            stockName: "Apple Inc."
        )

        XCTAssertEqual(schedule.displayName, "Apple Inc. (AAPL)")
    }

    func testDisplayName_WithoutStockName() {
        let schedule = TestFixtures.dcaSchedule(
            stockSymbol: "AAPL",
            stockName: nil
        )

        XCTAssertEqual(schedule.displayName, "AAPL")
    }

    func testAveragePerExecution_WithExecutions() {
        let schedule = TestFixtures.dcaSchedule(
            amount: 100,
            totalInvested: 1200,
            executionCount: 12
        )

        XCTAssertEqual(schedule.averagePerExecution, 100)
    }

    func testAveragePerExecution_NoExecutions() {
        let schedule = TestFixtures.dcaSchedule(
            amount: 150,
            totalInvested: 0,
            executionCount: 0
        )

        XCTAssertEqual(schedule.averagePerExecution, 150)
    }

    func testEstimatedAnnualInvestment_Daily() {
        let schedule = TestFixtures.dcaSchedule(amount: 10, frequency: .daily)

        XCTAssertEqual(schedule.estimatedAnnualInvestment, 3650) // 10 * 365
    }

    func testEstimatedAnnualInvestment_Weekly() {
        let schedule = TestFixtures.dcaSchedule(amount: 100, frequency: .weekly)

        XCTAssertEqual(schedule.estimatedAnnualInvestment, 5200) // 100 * 52
    }

    func testEstimatedAnnualInvestment_Biweekly() {
        let schedule = TestFixtures.dcaSchedule(amount: 200, frequency: .biweekly)

        XCTAssertEqual(schedule.estimatedAnnualInvestment, 5200) // 200 * 26
    }

    func testEstimatedAnnualInvestment_Monthly() {
        let schedule = TestFixtures.dcaSchedule(amount: 500, frequency: .monthly)

        XCTAssertEqual(schedule.estimatedAnnualInvestment, 6000) // 500 * 12
    }

    func testEstimatedAnnualInvestment_Quarterly() {
        let schedule = TestFixtures.dcaSchedule(amount: 1000, frequency: .quarterly)

        XCTAssertEqual(schedule.estimatedAnnualInvestment, 4000) // 1000 * 4
    }

    // MARK: - Status Tests

    func testStatus_Active() {
        let schedule = TestFixtures.dcaSchedule(
            isActive: true,
            isPaused: false
        )

        XCTAssertEqual(schedule.status, .active)
    }

    func testStatus_Paused() {
        let schedule = TestFixtures.dcaSchedule(
            isActive: true,
            isPaused: true
        )

        XCTAssertEqual(schedule.status, .paused)
    }

    func testStatus_Completed_NotActive() {
        let schedule = TestFixtures.dcaSchedule(
            isActive: false,
            isPaused: false
        )

        XCTAssertEqual(schedule.status, .completed)
    }

    func testStatus_Completed_PastEndDate() {
        let pastEndDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let schedule = TestFixtures.dcaSchedule(
            endDate: pastEndDate,
            isActive: true,
            isPaused: false
        )

        XCTAssertEqual(schedule.status, .completed)
    }

    func testStatus_PendingExecution() {
        let pastDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let schedule = TestFixtures.dcaSchedule(
            nextExecutionDate: pastDate,
            isActive: true,
            isPaused: false
        )

        XCTAssertEqual(schedule.status, .pendingExecution)
    }

    // MARK: - HasEnded Tests

    func testHasEnded_NoEndDate_ReturnsFalse() {
        let schedule = TestFixtures.dcaSchedule(endDate: nil)

        XCTAssertFalse(schedule.hasEnded)
    }

    func testHasEnded_FutureEndDate_ReturnsFalse() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let schedule = TestFixtures.dcaSchedule(endDate: futureDate)

        XCTAssertFalse(schedule.hasEnded)
    }

    func testHasEnded_PastEndDate_ReturnsTrue() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let schedule = TestFixtures.dcaSchedule(endDate: pastDate)

        XCTAssertTrue(schedule.hasEnded)
    }

    // MARK: - DaysUntilNextExecution Tests

    func testDaysUntilNextExecution_NoNextDate_ReturnsNil() {
        let schedule = TestFixtures.dcaSchedule(nextExecutionDate: nil)

        XCTAssertNil(schedule.daysUntilNextExecution)
    }

    func testDaysUntilNextExecution_FutureDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let schedule = TestFixtures.dcaSchedule(nextExecutionDate: futureDate)

        XCTAssertNotNil(schedule.daysUntilNextExecution)
        XCTAssertGreaterThanOrEqual(schedule.daysUntilNextExecution ?? 0, 4)
    }

    func testDaysUntilNextExecution_PastDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let schedule = TestFixtures.dcaSchedule(nextExecutionDate: pastDate)

        XCTAssertNotNil(schedule.daysUntilNextExecution)
        XCTAssertLessThan(schedule.daysUntilNextExecution ?? 0, 0)
    }

    // MARK: - EstimatedRemainingExecutions Tests

    func testEstimatedRemainingExecutions_NoEndDate_ReturnsNil() {
        let schedule = TestFixtures.dcaSchedule(endDate: nil)

        XCTAssertNil(schedule.estimatedRemainingExecutions)
    }

    func testEstimatedRemainingExecutions_PastEndDate_ReturnsZero() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let schedule = TestFixtures.dcaSchedule(endDate: pastDate)

        XCTAssertEqual(schedule.estimatedRemainingExecutions, 0)
    }

    // MARK: - DCAFrequency Tests

    func testDCAFrequency_DisplayName() {
        XCTAssertEqual(DCAFrequency.daily.displayName, "Daily")
        XCTAssertEqual(DCAFrequency.weekly.displayName, "Weekly")
        XCTAssertEqual(DCAFrequency.biweekly.displayName, "Every 2 Weeks")
        XCTAssertEqual(DCAFrequency.monthly.displayName, "Monthly")
        XCTAssertEqual(DCAFrequency.quarterly.displayName, "Quarterly")
    }

    func testDCAFrequency_ShortName() {
        XCTAssertEqual(DCAFrequency.daily.shortName, "Daily")
        XCTAssertEqual(DCAFrequency.weekly.shortName, "Weekly")
        XCTAssertEqual(DCAFrequency.biweekly.shortName, "Bi-weekly")
        XCTAssertEqual(DCAFrequency.monthly.shortName, "Monthly")
        XCTAssertEqual(DCAFrequency.quarterly.shortName, "Quarterly")
    }

    func testDCAFrequency_ExecutionsPerYear() {
        XCTAssertEqual(DCAFrequency.daily.executionsPerYear, 365)
        XCTAssertEqual(DCAFrequency.weekly.executionsPerYear, 52)
        XCTAssertEqual(DCAFrequency.biweekly.executionsPerYear, 26)
        XCTAssertEqual(DCAFrequency.monthly.executionsPerYear, 12)
        XCTAssertEqual(DCAFrequency.quarterly.executionsPerYear, 4)
    }

    func testDCAFrequency_AverageDaysBetweenExecutions() {
        XCTAssertEqual(DCAFrequency.daily.averageDaysBetweenExecutions, 1)
        XCTAssertEqual(DCAFrequency.weekly.averageDaysBetweenExecutions, 7)
        XCTAssertEqual(DCAFrequency.biweekly.averageDaysBetweenExecutions, 14)
        XCTAssertEqual(DCAFrequency.monthly.averageDaysBetweenExecutions, 30)
        XCTAssertEqual(DCAFrequency.quarterly.averageDaysBetweenExecutions, 91)
    }

    func testDCAFrequency_AllCases() {
        XCTAssertEqual(DCAFrequency.allCases.count, 5)
    }

    // MARK: - DCAScheduleStatus Tests

    func testDCAScheduleStatus_DisplayName() {
        XCTAssertEqual(DCAScheduleStatus.active.displayName, "Active")
        XCTAssertEqual(DCAScheduleStatus.paused.displayName, "Paused")
        XCTAssertEqual(DCAScheduleStatus.pendingExecution.displayName, "Pending")
        XCTAssertEqual(DCAScheduleStatus.completed.displayName, "Completed")
    }

    func testDCAScheduleStatus_IconName_NotEmpty() {
        let statuses: [DCAScheduleStatus] = [.active, .paused, .pendingExecution, .completed]
        for status in statuses {
            XCTAssertFalse(status.iconName.isEmpty, "Icon name for \(status) should not be empty")
        }
    }

    func testDCAScheduleStatus_ColorHex_ValidFormat() {
        let statuses: [DCAScheduleStatus] = [.active, .paused, .pendingExecution, .completed]
        for status in statuses {
            XCTAssertTrue(status.colorHex.hasPrefix("#"), "Color hex for \(status) should start with #")
            XCTAssertEqual(status.colorHex.count, 7, "Color hex for \(status) should be 7 characters")
        }
    }

    // MARK: - CalculateNextExecutionDate Tests

    func testCalculateNextExecutionDate_Daily() {
        let schedule = TestFixtures.dcaSchedule(frequency: .daily)
        let fromDate = Date()
        let nextDate = schedule.calculateNextExecutionDate(from: fromDate)

        let dayDiff = Calendar.current.dateComponents([.day], from: fromDate, to: nextDate).day ?? 0
        XCTAssertEqual(dayDiff, 1)
    }

    func testCalculateNextExecutionDate_Weekly() {
        let schedule = TestFixtures.dcaSchedule(frequency: .weekly)
        let fromDate = Date()
        let nextDate = schedule.calculateNextExecutionDate(from: fromDate)

        let dayDiff = Calendar.current.dateComponents([.day], from: fromDate, to: nextDate).day ?? 0
        XCTAssertGreaterThanOrEqual(dayDiff, 7)
    }

    func testCalculateNextExecutionDate_Biweekly() {
        let schedule = TestFixtures.dcaSchedule(frequency: .biweekly)
        let fromDate = Date()
        let nextDate = schedule.calculateNextExecutionDate(from: fromDate)

        let dayDiff = Calendar.current.dateComponents([.day], from: fromDate, to: nextDate).day ?? 0
        XCTAssertEqual(dayDiff, 14)
    }

    func testCalculateNextExecutionDate_Monthly() {
        let schedule = TestFixtures.dcaSchedule(frequency: .monthly)
        let fromDate = Date()
        let nextDate = schedule.calculateNextExecutionDate(from: fromDate)

        let monthDiff = Calendar.current.dateComponents([.month], from: fromDate, to: nextDate).month ?? 0
        XCTAssertEqual(monthDiff, 1)
    }

    func testCalculateNextExecutionDate_Quarterly() {
        let schedule = TestFixtures.dcaSchedule(frequency: .quarterly)
        let fromDate = Date()
        let nextDate = schedule.calculateNextExecutionDate(from: fromDate)

        let monthDiff = Calendar.current.dateComponents([.month], from: fromDate, to: nextDate).month ?? 0
        XCTAssertEqual(monthDiff, 3)
    }

    // MARK: - DCAExecution Tests

    func testDCAExecution_Initialization() {
        let execution = DCAExecution(
            scheduleId: "dca-123",
            stockSymbol: "AAPL",
            amount: 100,
            sharesAcquired: Decimal(string: "0.571428")!,
            pricePerShare: 175
        )

        XCTAssertFalse(execution.id.isEmpty)
        XCTAssertEqual(execution.scheduleId, "dca-123")
        XCTAssertEqual(execution.stockSymbol, "AAPL")
        XCTAssertEqual(execution.amount, 100)
        XCTAssertEqual(execution.sharesAcquired, Decimal(string: "0.571428")!)
        XCTAssertEqual(execution.pricePerShare, 175)
        XCTAssertEqual(execution.status, .completed)
        XCTAssertNil(execution.errorMessage)
    }

    func testDCAExecution_TotalCost() {
        let execution = DCAExecution(
            scheduleId: "dca-123",
            stockSymbol: "AAPL",
            amount: 100,
            sharesAcquired: 2,
            pricePerShare: 50
        )

        XCTAssertEqual(execution.totalCost, 100)
    }

    func testDCAExecution_WithError() {
        let execution = DCAExecution(
            scheduleId: "dca-123",
            stockSymbol: "AAPL",
            amount: 100,
            sharesAcquired: 0,
            pricePerShare: 0,
            status: .failed,
            errorMessage: "Insufficient funds"
        )

        XCTAssertEqual(execution.status, .failed)
        XCTAssertEqual(execution.errorMessage, "Insufficient funds")
    }

    // MARK: - DCASummary Tests

    func testDCASummary_Initialization() {
        let schedules = TestFixtures.sampleDCASchedules
        let summary = DCASummary(schedules: schedules)

        XCTAssertGreaterThan(summary.totalInvested, 0)
        XCTAssertGreaterThan(summary.totalExecutions, 0)
    }

    func testDCASummary_EmptySchedules() {
        let summary = DCASummary(schedules: [])

        XCTAssertEqual(summary.activeSchedules, 0)
        XCTAssertEqual(summary.totalMonthlyInvestment, 0)
        XCTAssertEqual(summary.totalInvested, 0)
        XCTAssertEqual(summary.totalExecutions, 0)
    }

    // MARK: - Codable Tests

    func testDCASchedule_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.dcaSchedule(
            id: "dca-test",
            stockSymbol: "VOO",
            stockName: "Vanguard S&P 500 ETF",
            amount: 500,
            frequency: .monthly,
            preferredDayOfMonth: 15
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(DCASchedule.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.stockSymbol, original.stockSymbol)
        XCTAssertEqual(decoded.stockName, original.stockName)
        XCTAssertEqual(decoded.amount, original.amount)
        XCTAssertEqual(decoded.frequency, original.frequency)
        XCTAssertEqual(decoded.preferredDayOfMonth, original.preferredDayOfMonth)
    }

    func testDCAFrequency_Codable() throws {
        for frequency in DCAFrequency.allCases {
            let data = try JSONEncoder().encode(frequency)
            let decoded = try JSONDecoder().decode(DCAFrequency.self, from: data)
            XCTAssertEqual(decoded, frequency)
        }
    }

    func testDCAScheduleStatus_Codable() throws {
        let statuses: [DCAScheduleStatus] = [.active, .paused, .pendingExecution, .completed]
        for status in statuses {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(DCAScheduleStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - Equatable Tests

    func testDCASchedule_Equatable() {
        let schedule1 = TestFixtures.dcaSchedule(id: "dca-1", stockSymbol: "AAPL")
        let schedule2 = TestFixtures.dcaSchedule(id: "dca-1", stockSymbol: "AAPL")
        let schedule3 = TestFixtures.dcaSchedule(id: "dca-2", stockSymbol: "MSFT")

        XCTAssertEqual(schedule1, schedule2)
        XCTAssertNotEqual(schedule1, schedule3)
    }

    // MARK: - Hashable Tests

    func testDCASchedule_Hashable() {
        let schedule1 = TestFixtures.dcaSchedule(id: "dca-1")
        let schedule2 = TestFixtures.dcaSchedule(id: "dca-2")

        var set = Set<DCASchedule>()
        set.insert(schedule1)
        set.insert(schedule2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Edge Cases

    func testDCASchedule_ZeroAmount() {
        let schedule = TestFixtures.dcaSchedule(amount: 0)

        XCTAssertEqual(schedule.amount, 0)
        XCTAssertEqual(schedule.estimatedAnnualInvestment, 0)
    }

    func testDCASchedule_VeryLargeAmount() {
        let schedule = TestFixtures.dcaSchedule(
            amount: 1_000_000,
            frequency: .monthly
        )

        XCTAssertEqual(schedule.estimatedAnnualInvestment, 12_000_000)
    }

    func testDCASchedule_SmallAmount() {
        let schedule = TestFixtures.dcaSchedule(
            amount: Decimal(string: "0.01")!,
            frequency: .daily
        )

        XCTAssertEqual(schedule.estimatedAnnualInvestment, Decimal(string: "3.65")!)
    }
}
