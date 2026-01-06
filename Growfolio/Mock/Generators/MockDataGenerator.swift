//
//  MockDataGenerator.swift
//  Growfolio
//
//  Core utilities for generating realistic mock data.
//

import Foundation

/// Core utilities for generating realistic mock data values
enum MockDataGenerator {

    // MARK: - Decimal Generation

    /// Generate a random decimal value within a range
    /// - Parameters:
    ///   - min: Minimum value
    ///   - max: Maximum value
    ///   - precision: Number of decimal places
    /// - Returns: Random decimal value
    static func decimal(min: Decimal, max: Decimal, precision: Int = 2) -> Decimal {
        let minDouble = NSDecimalNumber(decimal: min).doubleValue
        let maxDouble = NSDecimalNumber(decimal: max).doubleValue
        let randomDouble = Double.random(in: minDouble...maxDouble)
        let multiplier = pow(10.0, Double(precision))
        let rounded = (randomDouble * multiplier).rounded() / multiplier
        return Decimal(rounded)
    }

    /// Generate a realistic percentage change (typically -10% to +30%)
    static func percentageChange(min: Decimal = -10, max: Decimal = 30) -> Decimal {
        decimal(min: min, max: max, precision: 2)
    }

    /// Generate a realistic number of shares
    static func shares(min: Decimal = 0.1, max: Decimal = 100) -> Decimal {
        decimal(min: min, max: max, precision: 4)
    }

    /// Generate a realistic investment amount
    static func investmentAmount(min: Decimal = 100, max: Decimal = 10000) -> Decimal {
        decimal(min: min, max: max, precision: 2)
    }

    // MARK: - Random Selection

    /// Select a random element from a collection
    static func randomElement<T>(from collection: [T]) -> T {
        collection.randomElement()!
    }

    /// Select a random element with weighted probabilities
    static func weightedRandom<T>(options: [(T, Double)]) -> T {
        let totalWeight = options.reduce(0) { $0 + $1.1 }
        let random = Double.random(in: 0..<totalWeight)

        var cumulative = 0.0
        for (item, weight) in options {
            cumulative += weight
            if random < cumulative {
                return item
            }
        }
        return options.last!.0
    }

    // MARK: - ID Generation

    /// Generate a unique mock ID with a prefix
    static func mockId(prefix: String = "mock") -> String {
        "\(prefix)_\(UUID().uuidString.lowercased().prefix(8))"
    }

    // MARK: - Date Generation

    /// Generate a random date within a range
    static func date(from startDate: Date, to endDate: Date = Date()) -> Date {
        let startTime = startDate.timeIntervalSince1970
        let endTime = endDate.timeIntervalSince1970
        let randomTime = Double.random(in: startTime...endTime)
        return Date(timeIntervalSince1970: randomTime)
    }

    /// Generate a date in the past
    static func pastDate(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }

    /// Generate a date in the future
    static func futureDate(daysFromNow: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
    }

    /// Generate the next execution date based on frequency
    static func nextExecutionDate(frequency: DCAFrequency, from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        }
    }

    // MARK: - Color Generation

    /// Generate a random color hex string
    static func colorHex() -> String {
        let colors = [
            "#007AFF", "#34C759", "#FF9500", "#FF2D55",
            "#5856D6", "#AF52DE", "#00C7BE", "#FF3B30"
        ]
        return colors.randomElement()!
    }

    // MARK: - Reference Number Generation

    /// Generate a bank-style reference number
    static func referenceNumber() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"

        var ref = ""
        for _ in 0..<3 {
            ref += String(letters.randomElement()!)
        }
        for _ in 0..<8 {
            ref += String(numbers.randomElement()!)
        }
        return ref
    }

    // MARK: - Bank Account Masking

    /// Generate a masked bank account number
    static func maskedBankAccount() -> String {
        "****\(Int.random(in: 1000...9999))"
    }
}
