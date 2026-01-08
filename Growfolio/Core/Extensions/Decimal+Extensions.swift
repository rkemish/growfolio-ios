//
//  Decimal+Extensions.swift
//  Growfolio
//
//  Decimal utility extensions for financial calculations.
//

import Foundation

extension Decimal {

    // MARK: - Currency Formatting

    /// Currency formatter with default settings
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()

    /// Compact currency formatter (e.g., $1.2M)
    private static let compactCurrencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    /// Percent formatter
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    /// Decimal formatter
    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    // MARK: - Formatted Strings

    /// Format as currency string
    var currencyString: String {
        Decimal.currencyFormatter.string(from: self as NSDecimalNumber) ?? "$0.00"
    }

    /// Format as currency with specific currency code
    func currencyString(code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: self as NSDecimalNumber) ?? "\(code)0.00"
    }

    /// Format as compact currency (e.g., $1.2K, $3.4M)
    /// Useful for displaying large numbers in a space-constrained UI
    var compactCurrencyString: String {
        let number = NSDecimalNumber(decimal: self).doubleValue
        let absNumber = abs(number)
        // Preserve sign for negative numbers
        let sign = number < 0 ? "-" : ""

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 1

        // Scale down large numbers and append appropriate suffix
        if absNumber >= 1_000_000_000 {
            // Billions: use 2 decimal places for precision
            formatter.maximumFractionDigits = 2
            let value = absNumber / 1_000_000_000
            let formatted = formatter.string(from: NSNumber(value: value)) ?? "$0"
            return "\(sign)\(formatted)B"
        } else if absNumber >= 1_000_000 {
            // Millions
            let value = absNumber / 1_000_000
            let formatted = formatter.string(from: NSNumber(value: value)) ?? "$0"
            return "\(sign)\(formatted)M"
        } else if absNumber >= 1_000 {
            // Thousands
            let value = absNumber / 1_000
            let formatted = formatter.string(from: NSNumber(value: value)) ?? "$0"
            return "\(sign)\(formatted)K"
        } else {
            // Small numbers: display full amount
            return Decimal.currencyFormatter.string(from: self as NSDecimalNumber) ?? "$0.00"
        }
    }

    /// Format as percentage string
    var percentString: String {
        // Convert decimal to percentage (0.15 -> 15%)
        Decimal.percentFormatter.string(from: self as NSDecimalNumber) ?? "0.00%"
    }

    /// Format as percentage from raw value (15 -> 15%)
    var rawPercentString: String {
        let value = self / 100
        return Decimal.percentFormatter.string(from: value as NSDecimalNumber) ?? "0.00%"
    }

    /// Format as decimal string with 2 decimal places
    var decimalString: String {
        Decimal.decimalFormatter.string(from: self as NSDecimalNumber) ?? "0.00"
    }

    /// Format as shares/quantity string
    var sharesString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        return formatter.string(from: self as NSDecimalNumber) ?? "0"
    }

    // MARK: - Math Operations

    /// Round to specified decimal places
    func rounded(places: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, places, .plain)
        return result
    }

    /// Round up to specified decimal places
    func roundedUp(places: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, places, .up)
        return result
    }

    /// Round down to specified decimal places
    func roundedDown(places: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, places, .down)
        return result
    }

    /// Absolute value
    var absoluteValue: Decimal {
        self < 0 ? -self : self
    }

    /// Check if value is positive
    var isPositive: Bool {
        self > 0
    }

    /// Check if value is negative
    var isNegative: Bool {
        self < 0
    }

    /// Check if value is zero
    var isZero: Bool {
        self == 0
    }

    // MARK: - Financial Calculations

    /// Calculate percentage of another value
    func percentage(of total: Decimal) -> Decimal {
        guard total != 0 else { return 0 }
        return (self / total) * 100
    }

    /// Calculate percentage change from another value
    func percentageChange(from original: Decimal) -> Decimal {
        guard original != 0 else { return 0 }
        return ((self - original) / original) * 100
    }

    /// Apply percentage (e.g., apply 10% = multiply by 0.10)
    func applying(percentage: Decimal) -> Decimal {
        self * (percentage / 100)
    }

    /// Add percentage (e.g., add 10% = multiply by 1.10)
    func adding(percentage: Decimal) -> Decimal {
        self * (1 + percentage / 100)
    }

    /// Subtract percentage
    func subtracting(percentage: Decimal) -> Decimal {
        self * (1 - percentage / 100)
    }

    // MARK: - Conversion

    /// Convert to Double
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// Convert to Int (truncated)
    var intValue: Int {
        NSDecimalNumber(decimal: self).intValue
    }

    /// Create from Double
    static func from(_ double: Double) -> Decimal {
        Decimal(double)
    }

    /// Create from Int
    static func from(_ int: Int) -> Decimal {
        Decimal(int)
    }

    /// Create from String
    static func from(_ string: String) -> Decimal? {
        Decimal(string: string)
    }
}

// MARK: - Safe Division

extension Decimal {
    /// Safe division that returns 0 if dividing by 0
    /// Note: This is a method, not an operator overload, to avoid recursion issues
    func dividedBy(_ divisor: Decimal) -> Decimal {
        guard divisor != 0 else { return 0 }
        return self / divisor
    }
}

// MARK: - Money Type

/// Type-safe money representation
struct Money: Codable, Sendable, Equatable, Comparable, Hashable {
    let amount: Decimal
    let currencyCode: String

    init(_ amount: Decimal, currency: String = "USD") {
        self.amount = amount
        self.currencyCode = currency
    }

    init(_ amount: Double, currency: String = "USD") {
        self.amount = Decimal(amount)
        self.currencyCode = currency
    }

    init(_ amount: Int, currency: String = "USD") {
        self.amount = Decimal(amount)
        self.currencyCode = currency
    }

    // MARK: - Formatting

    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currencyCode)\(amount)"
    }

    var compactFormatted: String {
        amount.compactCurrencyString
    }

    // MARK: - Comparable

    static func < (lhs: Money, rhs: Money) -> Bool {
        // Only compare if same currency - comparing different currencies is meaningless
        // Returns false if currencies don't match (undefined comparison)
        guard lhs.currencyCode == rhs.currencyCode else {
            return false
        }
        return lhs.amount < rhs.amount
    }

    // MARK: - Arithmetic

    static func + (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currencyCode == rhs.currencyCode, "Cannot add different currencies")
        return Money(lhs.amount + rhs.amount, currency: lhs.currencyCode)
    }

    static func - (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currencyCode == rhs.currencyCode, "Cannot subtract different currencies")
        return Money(lhs.amount - rhs.amount, currency: lhs.currencyCode)
    }

    static func * (lhs: Money, rhs: Decimal) -> Money {
        Money(lhs.amount * rhs, currency: lhs.currencyCode)
    }

    static func / (lhs: Money, rhs: Decimal) -> Money {
        guard rhs != 0 else { return Money(0, currency: lhs.currencyCode) }
        return Money(lhs.amount / rhs, currency: lhs.currencyCode)
    }

    // MARK: - Zero

    static func zero(currency: String = "USD") -> Money {
        Money(0, currency: currency)
    }

    var isZero: Bool {
        amount.isZero
    }

    var isPositive: Bool {
        amount.isPositive
    }

    var isNegative: Bool {
        amount.isNegative
    }
}

// MARK: - Percentage Type

/// Type-safe percentage representation
struct Percentage: Codable, Sendable, Equatable, Comparable, Hashable {
    /// The raw value (e.g., 15 for 15%)
    let value: Decimal

    init(_ value: Decimal) {
        self.value = value
    }

    init(_ value: Double) {
        self.value = Decimal(value)
    }

    init(_ value: Int) {
        self.value = Decimal(value)
    }

    /// Create from decimal representation (0.15 for 15%)
    static func fromDecimal(_ decimal: Decimal) -> Percentage {
        Percentage(decimal * 100)
    }

    /// Decimal representation (15% -> 0.15)
    var decimalValue: Decimal {
        value / 100
    }

    /// Formatted string
    var formatted: String {
        value.rawPercentString
    }

    /// Formatted string with sign
    var formattedWithSign: String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(formatted)"
    }

    // MARK: - Comparable

    static func < (lhs: Percentage, rhs: Percentage) -> Bool {
        lhs.value < rhs.value
    }

    // MARK: - Common Percentages

    static let zero = Percentage(0)
    static let oneHundred = Percentage(100)
}
