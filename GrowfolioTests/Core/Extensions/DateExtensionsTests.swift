//
//  DateExtensionsTests.swift
//  GrowfolioTests
//
//  Tests for Date extensions and DateRange.
//

import XCTest
@testable import Growfolio

final class DateExtensionsTests: XCTestCase {

    // MARK: - ISO8601 Formatter Tests

    func testDateISO8601String() {
        let date = Date(timeIntervalSince1970: 1704067200) // 2024-01-01 00:00:00 UTC
        let iso8601String = date.iso8601String

        XCTAssertTrue(iso8601String.contains("2024-01-01"))
        XCTAssertTrue(iso8601String.contains("T"))
    }

    func testDateFromISO8601Valid() {
        let dateString = "2024-06-15T14:30:00.000Z"
        let date = Date.fromISO8601(dateString)

        XCTAssertNotNil(date)
    }

    func testDateFromISO8601Invalid() {
        let dateString = "not-a-date"
        let date = Date.fromISO8601(dateString)

        XCTAssertNil(date)
    }

    // MARK: - Date Only Formatter Tests

    func testDateDateOnlyString() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let dateOnly = date.dateOnlyString

        XCTAssertTrue(dateOnly.contains("2024"))
    }

    func testDateFromDateOnlyValid() {
        let dateString = "2024-06-15"
        let date = Date.fromDateOnly(dateString)

        XCTAssertNotNil(date)
    }

    func testDateFromDateOnlyInvalid() {
        let dateString = "invalid"
        let date = Date.fromDateOnly(dateString)

        XCTAssertNil(date)
    }

    // MARK: - Display Formatter Tests

    func testDateDisplayString() {
        let date = Date()
        let displayString = date.displayString

        XCTAssertFalse(displayString.isEmpty)
    }

    func testDateDisplayDateTimeString() {
        let date = Date()
        let dateTimeString = date.displayDateTimeString

        XCTAssertFalse(dateTimeString.isEmpty)
    }

    func testDateShortDateString() {
        let date = Date()
        let shortString = date.shortDateString

        XCTAssertFalse(shortString.isEmpty)
    }

    func testDateMonthYearString() {
        let date = Date()
        let monthYear = date.monthYearString

        XCTAssertFalse(monthYear.isEmpty)
    }

    func testDateRelativeString() {
        let date = Date()
        let relative = date.relativeString

        XCTAssertFalse(relative.isEmpty)
    }

    // MARK: - Start/End of Period Tests

    func testDateStartOfDay() {
        let date = Date()
        let startOfDay = date.startOfDay

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testDateEndOfDay() {
        let date = Date()
        let endOfDay = date.endOfDay

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: endOfDay)
        XCTAssertEqual(components.hour, 23)
        XCTAssertEqual(components.minute, 59)
        XCTAssertEqual(components.second, 59)
    }

    func testDateStartOfWeek() {
        let date = Date()
        let startOfWeek = date.startOfWeek

        XCTAssertLessThanOrEqual(startOfWeek, date)
    }

    func testDateEndOfWeek() {
        let date = Date()
        let endOfWeek = date.endOfWeek

        XCTAssertGreaterThanOrEqual(endOfWeek, date)
    }

    func testDateStartOfMonth() {
        let date = Date()
        let startOfMonth = date.startOfMonth

        let components = Calendar.current.dateComponents([.day], from: startOfMonth)
        XCTAssertEqual(components.day, 1)
    }

    func testDateEndOfMonth() {
        let date = Date()
        let endOfMonth = date.endOfMonth

        XCTAssertGreaterThanOrEqual(endOfMonth, date.startOfMonth)
    }

    func testDateStartOfYear() {
        let date = Date()
        let startOfYear = date.startOfYear

        let components = Calendar.current.dateComponents([.month, .day], from: startOfYear)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 1)
    }

    func testDateEndOfYear() {
        let date = Date()
        let endOfYear = date.endOfYear

        let components = Calendar.current.dateComponents([.month], from: endOfYear)
        XCTAssertEqual(components.month, 12)
    }

    // MARK: - Date Checks Tests

    func testDateIsToday() {
        let today = Date()
        XCTAssertTrue(today.isToday)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        XCTAssertFalse(yesterday.isToday)
    }

    func testDateIsYesterday() {
        let today = Date()
        XCTAssertFalse(today.isYesterday)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        XCTAssertTrue(yesterday.isYesterday)
    }

    func testDateIsTomorrow() {
        let today = Date()
        XCTAssertFalse(today.isTomorrow)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        XCTAssertTrue(tomorrow.isTomorrow)
    }

    func testDateIsPast() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(pastDate.isPast)

        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertFalse(futureDate.isPast)
    }

    func testDateIsFuture() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertTrue(futureDate.isFuture)

        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(pastDate.isFuture)
    }

    func testDateIsThisWeek() {
        let today = Date()
        XCTAssertTrue(today.isThisWeek)
    }

    func testDateIsThisMonth() {
        let today = Date()
        XCTAssertTrue(today.isThisMonth)
    }

    func testDateIsThisYear() {
        let today = Date()
        XCTAssertTrue(today.isThisYear)
    }

    // MARK: - Days Calculation Tests

    func testDateDaysFromNow() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        XCTAssertEqual(futureDate.daysFromNow, 5)
    }

    func testDateDaysSinceNow() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        XCTAssertEqual(pastDate.daysSinceNow, 3)
    }

    func testDateMonthsFromNow() {
        let futureDate = Calendar.current.date(byAdding: .month, value: 2, to: Date())!
        // Allow for edge cases around month boundaries
        XCTAssertTrue(futureDate.monthsFromNow >= 1 && futureDate.monthsFromNow <= 2)
    }

    func testDateYearsFromNow() {
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        // Allow for edge cases around year boundaries
        XCTAssertTrue(futureDate.yearsFromNow >= 0 && futureDate.yearsFromNow <= 1)
    }

    // MARK: - Date Manipulation Tests

    func testDateAddingDays() {
        let date = Date()
        let newDate = date.adding(days: 7)

        let daysDiff = Calendar.current.dateComponents([.day], from: date, to: newDate).day
        XCTAssertEqual(daysDiff, 7)
    }

    func testDateAddingWeeks() {
        let date = Date()
        let newDate = date.adding(weeks: 2)

        let weeksDiff = Calendar.current.dateComponents([.weekOfYear], from: date, to: newDate).weekOfYear
        XCTAssertEqual(weeksDiff, 2)
    }

    func testDateAddingMonths() {
        let date = Date()
        let newDate = date.adding(months: 3)

        let monthsDiff = Calendar.current.dateComponents([.month], from: date, to: newDate).month
        XCTAssertEqual(monthsDiff, 3)
    }

    func testDateAddingYears() {
        let date = Date()
        let newDate = date.adding(years: 1)

        let yearsDiff = Calendar.current.dateComponents([.year], from: date, to: newDate).year
        XCTAssertEqual(yearsDiff, 1)
    }

    func testDateAddingNegativeDays() {
        let date = Date()
        let newDate = date.adding(days: -5)

        XCTAssertLessThan(newDate, date)
    }

    // MARK: - Business Days Tests

    func testDateIsWeekday() {
        // Create a known Monday
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 8 // Monday
        let monday = Calendar.current.date(from: components)!

        XCTAssertTrue(monday.isWeekday)
    }

    func testDateIsWeekend() {
        // Create a known Saturday
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 6 // Saturday
        let saturday = Calendar.current.date(from: components)!

        XCTAssertTrue(saturday.isWeekend)
    }

    func testDateNextWeekday() {
        // Create a known Friday
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 5 // Friday
        let friday = Calendar.current.date(from: components)!

        let nextWeekday = friday.nextWeekday

        // Should be Monday (skipping Sat/Sun)
        XCTAssertTrue(nextWeekday.isWeekday)
        XCTAssertGreaterThan(nextWeekday, friday)
    }

    func testDateAddingBusinessDays() {
        // Create a known Monday
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 8 // Monday
        let monday = Calendar.current.date(from: components)!

        let afterFiveBusinessDays = monday.adding(businessDays: 5)

        // 5 business days from Monday should be the following Monday
        XCTAssertTrue(afterFiveBusinessDays.isWeekday)
    }

    // MARK: - DateRange Tests

    func testDateRangeInitialization() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 5, to: start)!

        let range = DateRange(start: start, end: end)

        XCTAssertEqual(range.start, start)
        XCTAssertEqual(range.end, end)
    }

    func testDateRangeSwapsIfEndBeforeStart() {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: 5, to: end)!

        let range = DateRange(start: start, end: end)

        XCTAssertLessThanOrEqual(range.start, range.end)
    }

    func testDateRangeContains() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 10, to: start)!
        let range = DateRange(start: start, end: end)

        let middleDate = Calendar.current.date(byAdding: .day, value: 5, to: start)!
        XCTAssertTrue(range.contains(middleDate))

        let outsideDate = Calendar.current.date(byAdding: .day, value: 15, to: start)!
        XCTAssertFalse(range.contains(outsideDate))
    }

    func testDateRangeContainsBoundaries() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 10, to: start)!
        let range = DateRange(start: start, end: end)

        XCTAssertTrue(range.contains(start))
        XCTAssertTrue(range.contains(end))
    }

    func testDateRangeDayCount() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        let range = DateRange(start: start, end: end)

        XCTAssertEqual(range.dayCount, 7)
    }

    func testDateRangeDates() {
        let start = Date().startOfDay
        let end = Calendar.current.date(byAdding: .day, value: 3, to: start)!
        let range = DateRange(start: start, end: end)

        let dates = range.dates

        XCTAssertEqual(dates.count, 4) // start, +1, +2, +3 (end)
    }

    func testDateRangeToday() {
        let today = DateRange.today

        XCTAssertTrue(today.contains(Date()))
    }

    func testDateRangeThisWeek() {
        let thisWeek = DateRange.thisWeek

        XCTAssertTrue(thisWeek.contains(Date()))
    }

    func testDateRangeThisMonth() {
        let thisMonth = DateRange.thisMonth

        XCTAssertTrue(thisMonth.contains(Date()))
    }

    func testDateRangeThisYear() {
        let thisYear = DateRange.thisYear

        XCTAssertTrue(thisYear.contains(Date()))
    }

    func testDateRangeLastDays() {
        let lastWeek = DateRange.last(days: 7)

        // The end date should be now or very close to now
        XCTAssertLessThanOrEqual(lastWeek.end.timeIntervalSinceNow, 1)
        XCTAssertGreaterThanOrEqual(lastWeek.dayCount, 6)
    }

    func testDateRangeLastMonths() {
        let lastThreeMonths = DateRange.last(months: 3)

        // The end date should be now or very close to now
        XCTAssertLessThanOrEqual(lastThreeMonths.end.timeIntervalSinceNow, 1)
        XCTAssertLessThan(lastThreeMonths.start, lastThreeMonths.end)
    }

    func testDateRangeLastYears() {
        let lastYear = DateRange.last(years: 1)

        // The end date should be now or very close to now
        XCTAssertLessThanOrEqual(lastYear.end.timeIntervalSinceNow, 1)
        XCTAssertLessThan(lastYear.start, lastYear.end)
    }

    func testDateRangeEquatable() {
        let start = Date().startOfDay
        let end = Calendar.current.date(byAdding: .day, value: 5, to: start)!

        let range1 = DateRange(start: start, end: end)
        let range2 = DateRange(start: start, end: end)

        XCTAssertEqual(range1, range2)
    }

    func testDateRangeIsSendable() {
        let range = DateRange.today
        Task {
            let copy = range
            XCTAssertNotNil(copy.start)
        }
    }
}
