//
//  Date+Extensions.swift
//  Growfolio
//
//  Date utility extensions.
//

import Foundation

extension Date {

    // MARK: - Formatters

    /// ISO 8601 formatter for API communication
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Date only formatter
    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.DateFormat.dateOnly
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Display date formatter
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.DateFormat.displayDate
        return formatter
    }()

    /// Display date and time formatter
    static let displayDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.DateFormat.displayDateTime
        return formatter
    }()

    /// Short date formatter
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.DateFormat.shortDate
        return formatter
    }()

    /// Month and year formatter
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.DateFormat.monthYear
        return formatter
    }()

    /// Relative date formatter
    static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    // MARK: - Formatted Strings

    /// ISO 8601 string representation
    var iso8601String: String {
        Date.iso8601Formatter.string(from: self)
    }

    /// Date only string (yyyy-MM-dd)
    var dateOnlyString: String {
        Date.dateOnlyFormatter.string(from: self)
    }

    /// Display formatted date string
    var displayString: String {
        Date.displayDateFormatter.string(from: self)
    }

    /// Display formatted date and time string
    var displayDateTimeString: String {
        Date.displayDateTimeFormatter.string(from: self)
    }

    /// Short date string
    var shortDateString: String {
        Date.shortDateFormatter.string(from: self)
    }

    /// Month and year string
    var monthYearString: String {
        Date.monthYearFormatter.string(from: self)
    }

    /// Relative date string (e.g., "2 days ago")
    var relativeString: String {
        Date.relativeDateFormatter.localizedString(for: self, relativeTo: Date())
    }

    // MARK: - Date Components

    /// Start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// End of day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    /// Start of week
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// End of week
    var endOfWeek: Date {
        var components = DateComponents()
        components.day = 7
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek) ?? self
    }

    /// Start of month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// End of month
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? self
    }

    /// Start of year
    var startOfYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        return calendar.date(from: components) ?? self
    }

    /// End of year
    var endOfYear: Date {
        var components = DateComponents()
        components.year = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfYear) ?? self
    }

    // MARK: - Date Calculations

    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Check if date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    /// Check if date is in the past
    var isPast: Bool {
        self < Date()
    }

    /// Check if date is in the future
    var isFuture: Bool {
        self > Date()
    }

    /// Check if date is this week
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    /// Check if date is this month
    var isThisMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }

    /// Check if date is this year
    var isThisYear: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    /// Days until this date
    var daysFromNow: Int {
        Calendar.current.dateComponents([.day], from: Date().startOfDay, to: startOfDay).day ?? 0
    }

    /// Days since this date
    var daysSinceNow: Int {
        -daysFromNow
    }

    /// Months until this date
    var monthsFromNow: Int {
        Calendar.current.dateComponents([.month], from: Date(), to: self).month ?? 0
    }

    /// Years until this date
    var yearsFromNow: Int {
        Calendar.current.dateComponents([.year], from: Date(), to: self).year ?? 0
    }

    // MARK: - Date Manipulation

    /// Add days to date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Add weeks to date
    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }

    /// Add months to date
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Add years to date
    func adding(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }

    // MARK: - Parsing

    /// Parse from ISO 8601 string
    static func fromISO8601(_ string: String) -> Date? {
        iso8601Formatter.date(from: string)
    }

    /// Parse from date only string
    static func fromDateOnly(_ string: String) -> Date? {
        dateOnlyFormatter.date(from: string)
    }

    // MARK: - Business Days

    /// Check if date is a weekday
    /// Weekday numbers: 1=Sunday, 2=Monday, ..., 6=Friday, 7=Saturday
    var isWeekday: Bool {
        let weekday = Calendar.current.component(.weekday, from: self)
        // Monday (2) through Friday (6) are weekdays
        return weekday >= 2 && weekday <= 6
    }

    /// Check if date is a weekend
    var isWeekend: Bool {
        !isWeekday
    }

    /// Next weekday from this date
    var nextWeekday: Date {
        var date = self.adding(days: 1)
        while !date.isWeekday {
            date = date.adding(days: 1)
        }
        return date
    }

    /// Add business days
    /// Skips weekends when counting - only increments on weekdays
    func adding(businessDays: Int) -> Date {
        var remaining = businessDays
        var date = self

        // Iterate forward, only counting weekdays
        while remaining > 0 {
            date = date.adding(days: 1)
            if date.isWeekday {
                remaining -= 1
            }
        }

        return date
    }
}

// MARK: - Date Range

/// Represents a range of dates
struct DateRange: Sendable, Equatable {
    let start: Date
    let end: Date

    init(start: Date, end: Date) {
        self.start = min(start, end)
        self.end = max(start, end)
    }

    /// Check if date is within range
    func contains(_ date: Date) -> Bool {
        date >= start && date <= end
    }

    /// Number of days in range
    var dayCount: Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// All dates in range
    var dates: [Date] {
        var dates: [Date] = []
        var current = start

        while current <= end {
            dates.append(current)
            current = current.adding(days: 1)
        }

        return dates
    }

    /// Common date ranges
    static var today: DateRange {
        let now = Date()
        return DateRange(start: now.startOfDay, end: now.endOfDay)
    }

    static var thisWeek: DateRange {
        let now = Date()
        return DateRange(start: now.startOfWeek, end: now.endOfWeek)
    }

    static var thisMonth: DateRange {
        let now = Date()
        return DateRange(start: now.startOfMonth, end: now.endOfMonth)
    }

    static var thisYear: DateRange {
        let now = Date()
        return DateRange(start: now.startOfYear, end: now.endOfYear)
    }

    static func last(days: Int) -> DateRange {
        let now = Date()
        return DateRange(start: now.adding(days: -days), end: now)
    }

    static func last(months: Int) -> DateRange {
        let now = Date()
        return DateRange(start: now.adding(months: -months), end: now)
    }

    static func last(years: Int) -> DateRange {
        let now = Date()
        return DateRange(start: now.adding(years: -years), end: now)
    }
}
