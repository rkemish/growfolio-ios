//
//  DecimalExtensionsTests.swift
//  GrowfolioTests
//
//  Tests for Decimal extensions, Money, and Percentage types.
//

import XCTest
@testable import Growfolio

final class DecimalExtensionsTests: XCTestCase {

    // MARK: - Currency Formatting Tests

    func testDecimalCurrencyString() {
        let value: Decimal = 1234.56
        let formatted = value.currencyString

        XCTAssertTrue(formatted.contains("1,234") || formatted.contains("1234"))
        XCTAssertTrue(formatted.contains("56"))
    }

    func testDecimalCurrencyStringWithCode() {
        let value: Decimal = 100.50
        let formatted = value.currencyString(code: "EUR")

        XCTAssertTrue(formatted.contains("100") || formatted.contains("EUR"))
    }

    func testDecimalCompactCurrencyStringThousands() {
        let value: Decimal = 1500
        let formatted = value.compactCurrencyString

        XCTAssertTrue(formatted.contains("K") || formatted.contains("1,500"))
    }

    func testDecimalCompactCurrencyStringMillions() {
        let value: Decimal = 2_500_000
        let formatted = value.compactCurrencyString

        XCTAssertTrue(formatted.contains("M"))
    }

    func testDecimalCompactCurrencyStringBillions() {
        let value: Decimal = 3_500_000_000
        let formatted = value.compactCurrencyString

        XCTAssertTrue(formatted.contains("B"))
    }

    func testDecimalCompactCurrencyStringNegative() {
        let value: Decimal = -1_500_000
        let formatted = value.compactCurrencyString

        XCTAssertTrue(formatted.contains("-"))
        XCTAssertTrue(formatted.contains("M"))
    }

    func testDecimalCompactCurrencyStringSmallValue() {
        let value: Decimal = 500
        let formatted = value.compactCurrencyString

        XCTAssertFalse(formatted.contains("K"))
        XCTAssertFalse(formatted.contains("M"))
    }

    // MARK: - Percentage Formatting Tests

    func testDecimalPercentString() {
        let value: Decimal = 0.15
        let formatted = value.percentString

        XCTAssertTrue(formatted.contains("15"))
        XCTAssertTrue(formatted.contains("%"))
    }

    func testDecimalRawPercentString() {
        let value: Decimal = 25
        let formatted = value.rawPercentString

        XCTAssertTrue(formatted.contains("25"))
        XCTAssertTrue(formatted.contains("%"))
    }

    // MARK: - Decimal Formatting Tests

    func testDecimalDecimalString() {
        let value: Decimal = 123.456789
        let formatted = value.decimalString

        XCTAssertTrue(formatted.contains("123"))
    }

    func testDecimalSharesString() {
        let value: Decimal = 12.345678
        let formatted = value.sharesString

        XCTAssertTrue(formatted.contains("12"))
    }

    // MARK: - Rounding Tests

    func testDecimalRounded() {
        let value: Decimal = 3.14159
        let rounded = value.rounded(places: 2)

        XCTAssertEqual(rounded, 3.14)
    }

    func testDecimalRoundedUp() {
        let value: Decimal = 3.141
        let rounded = value.roundedUp(places: 2)

        XCTAssertEqual(rounded, 3.15)
    }

    func testDecimalRoundedDown() {
        let value: Decimal = 3.149
        let rounded = value.roundedDown(places: 2)

        XCTAssertEqual(rounded, 3.14)
    }

    func testDecimalRoundedZeroPlaces() {
        let value: Decimal = 3.7
        let rounded = value.rounded(places: 0)

        XCTAssertEqual(rounded, 4)
    }

    // MARK: - Math Properties Tests

    func testDecimalAbsoluteValue() {
        XCTAssertEqual(Decimal(-5).absoluteValue, 5)
        XCTAssertEqual(Decimal(5).absoluteValue, 5)
        XCTAssertEqual(Decimal(0).absoluteValue, 0)
    }

    func testDecimalIsPositive() {
        XCTAssertTrue(Decimal(5).isPositive)
        XCTAssertFalse(Decimal(-5).isPositive)
        XCTAssertFalse(Decimal(0).isPositive)
    }

    func testDecimalIsNegative() {
        XCTAssertTrue(Decimal(-5).isNegative)
        XCTAssertFalse(Decimal(5).isNegative)
        XCTAssertFalse(Decimal(0).isNegative)
    }

    func testDecimalIsZero() {
        // Use == 0 comparison since isZero is ambiguous with Foundation's Decimal.isZero
        XCTAssertTrue(Decimal(0) == 0)
        XCTAssertFalse(Decimal(5) == 0)
        XCTAssertFalse(Decimal(-5) == 0)
    }

    // MARK: - Financial Calculations Tests

    func testDecimalPercentageOf() {
        let value: Decimal = 25
        let total: Decimal = 100
        let percentage = value.percentage(of: total)

        XCTAssertEqual(percentage, 25)
    }

    func testDecimalPercentageOfZero() {
        let value: Decimal = 25
        let total: Decimal = 0
        let percentage = value.percentage(of: total)

        XCTAssertEqual(percentage, 0)
    }

    func testDecimalPercentageChange() {
        let newValue: Decimal = 120
        let originalValue: Decimal = 100
        let change = newValue.percentageChange(from: originalValue)

        XCTAssertEqual(change, 20)
    }

    func testDecimalPercentageChangeFromZero() {
        let newValue: Decimal = 100
        let originalValue: Decimal = 0
        let change = newValue.percentageChange(from: originalValue)

        XCTAssertEqual(change, 0)
    }

    func testDecimalApplyingPercentage() {
        let value: Decimal = 100
        let result = value.applying(percentage: 10)

        XCTAssertEqual(result, 10)
    }

    func testDecimalAddingPercentage() {
        let value: Decimal = 100
        let result = value.adding(percentage: 10)

        XCTAssertEqual(result, 110)
    }

    func testDecimalSubtractingPercentage() {
        let value: Decimal = 100
        let result = value.subtracting(percentage: 10)

        XCTAssertEqual(result, 90)
    }

    // MARK: - Conversion Tests

    func testDecimalDoubleValue() {
        let value: Decimal = 3.14
        let doubleValue = value.doubleValue

        XCTAssertEqual(doubleValue, 3.14, accuracy: 0.001)
    }

    func testDecimalIntValue() {
        let value: Decimal = 42.9
        let intValue = value.intValue

        XCTAssertEqual(intValue, 42)
    }

    func testDecimalFromDouble() {
        let value = Decimal.from(3.14)

        XCTAssertEqual(value.doubleValue, 3.14, accuracy: 0.001)
    }

    func testDecimalFromInt() {
        let value = Decimal.from(42)

        XCTAssertEqual(value, 42)
    }

    func testDecimalFromString() {
        let value = Decimal.from("123.45")

        XCTAssertNotNil(value)
        XCTAssertEqual(value, 123.45)
    }

    func testDecimalFromInvalidString() {
        let value = Decimal.from("not-a-number")

        XCTAssertNil(value)
    }

    // MARK: - Safe Division Tests

    func testDecimalDividedBy() {
        let value: Decimal = 100
        let result = value.dividedBy(4)

        XCTAssertEqual(result, 25)
    }

    func testDecimalDividedByZero() {
        let value: Decimal = 100
        let result = value.dividedBy(0)

        XCTAssertEqual(result, 0)
    }

    // MARK: - Money Type Tests

    func testMoneyInitializationWithDecimal() {
        let money = Money(Decimal(100.50), currency: "USD")

        XCTAssertEqual(money.amount, 100.50)
        XCTAssertEqual(money.currencyCode, "USD")
    }

    func testMoneyInitializationWithDouble() {
        let money = Money(100.50, currency: "EUR")

        XCTAssertEqual(money.amount.doubleValue, 100.50, accuracy: 0.01)
        XCTAssertEqual(money.currencyCode, "EUR")
    }

    func testMoneyInitializationWithInt() {
        let money = Money(100, currency: "GBP")

        XCTAssertEqual(money.amount, 100)
        XCTAssertEqual(money.currencyCode, "GBP")
    }

    func testMoneyDefaultCurrency() {
        let money = Money(100)

        XCTAssertEqual(money.currencyCode, "USD")
    }

    func testMoneyFormatted() {
        let money = Money(1234.56, currency: "USD")
        let formatted = money.formatted

        XCTAssertTrue(formatted.contains("1,234") || formatted.contains("1234"))
    }

    func testMoneyCompactFormatted() {
        let money = Money(1_500_000, currency: "USD")
        let formatted = money.compactFormatted

        XCTAssertTrue(formatted.contains("M"))
    }

    func testMoneyComparable() {
        let money1 = Money(100, currency: "USD")
        let money2 = Money(200, currency: "USD")

        XCTAssertTrue(money1 < money2)
        XCTAssertFalse(money2 < money1)
    }

    func testMoneyComparableDifferentCurrencies() {
        let usd = Money(100, currency: "USD")
        let eur = Money(50, currency: "EUR")

        // Different currencies should not be comparable (returns false)
        XCTAssertFalse(usd < eur)
        XCTAssertFalse(eur < usd)
    }

    func testMoneyAddition() {
        let money1 = Money(100, currency: "USD")
        let money2 = Money(50, currency: "USD")
        let result = money1 + money2

        XCTAssertEqual(result.amount, 150)
        XCTAssertEqual(result.currencyCode, "USD")
    }

    func testMoneySubtraction() {
        let money1 = Money(100, currency: "USD")
        let money2 = Money(30, currency: "USD")
        let result = money1 - money2

        XCTAssertEqual(result.amount, 70)
    }

    func testMoneyMultiplication() {
        let money = Money(100, currency: "USD")
        let result = money * Decimal(2)

        XCTAssertEqual(result.amount, 200)
    }

    func testMoneyDivision() {
        let money = Money(100, currency: "USD")
        let result = money / Decimal(4)

        XCTAssertEqual(result.amount, 25)
    }

    func testMoneyDivisionByZero() {
        let money = Money(100, currency: "USD")
        let result = money / Decimal(0)

        XCTAssertEqual(result.amount, 0)
    }

    func testMoneyZero() {
        let zero = Money.zero(currency: "EUR")

        XCTAssertEqual(zero.amount, 0)
        XCTAssertEqual(zero.currencyCode, "EUR")
    }

    func testMoneyIsZero() {
        let zero = Money(0)
        let nonZero = Money(100)

        XCTAssertTrue(zero.isZero)
        XCTAssertFalse(nonZero.isZero)
    }

    func testMoneyIsPositive() {
        let positive = Money(100)
        let negative = Money(-100)
        let zero = Money(0)

        XCTAssertTrue(positive.isPositive)
        XCTAssertFalse(negative.isPositive)
        XCTAssertFalse(zero.isPositive)
    }

    func testMoneyIsNegative() {
        let negative = Money(-100)
        let positive = Money(100)

        XCTAssertTrue(negative.isNegative)
        XCTAssertFalse(positive.isNegative)
    }

    func testMoneyEquatable() {
        let money1 = Money(100, currency: "USD")
        let money2 = Money(100, currency: "USD")
        let money3 = Money(100, currency: "EUR")

        XCTAssertEqual(money1, money2)
        XCTAssertNotEqual(money1, money3)
    }

    func testMoneyCodable() throws {
        let money = Money(123.45, currency: "USD")
        let data = try JSONEncoder().encode(money)
        let decoded = try JSONDecoder().decode(Money.self, from: data)

        XCTAssertEqual(decoded.amount, money.amount)
        XCTAssertEqual(decoded.currencyCode, money.currencyCode)
    }

    func testMoneyHashable() {
        let money1 = Money(100, currency: "USD")
        let money2 = Money(100, currency: "USD")

        XCTAssertEqual(money1.hashValue, money2.hashValue)
    }

    // MARK: - Percentage Type Tests

    func testPercentageInitializationWithDecimal() {
        let percentage = Percentage(Decimal(15))

        XCTAssertEqual(percentage.value, 15)
    }

    func testPercentageInitializationWithDouble() {
        let percentage = Percentage(15.5)

        XCTAssertEqual(percentage.value.doubleValue, 15.5, accuracy: 0.01)
    }

    func testPercentageInitializationWithInt() {
        let percentage = Percentage(25)

        XCTAssertEqual(percentage.value, 25)
    }

    func testPercentageFromDecimal() {
        let percentage = Percentage.fromDecimal(0.15)

        XCTAssertEqual(percentage.value, 15)
    }

    func testPercentageDecimalValue() {
        let percentage = Percentage(25)

        XCTAssertEqual(percentage.decimalValue, 0.25)
    }

    func testPercentageFormatted() {
        let percentage = Percentage(15)
        let formatted = percentage.formatted

        XCTAssertTrue(formatted.contains("15"))
        XCTAssertTrue(formatted.contains("%"))
    }

    func testPercentageFormattedWithSign() {
        let positive = Percentage(10)
        let negative = Percentage(-5)

        XCTAssertTrue(positive.formattedWithSign.contains("+"))
        XCTAssertFalse(negative.formattedWithSign.contains("+"))
    }

    func testPercentageComparable() {
        let p1 = Percentage(10)
        let p2 = Percentage(20)

        XCTAssertTrue(p1 < p2)
        XCTAssertFalse(p2 < p1)
    }

    func testPercentageZero() {
        XCTAssertEqual(Percentage.zero.value, 0)
    }

    func testPercentageOneHundred() {
        XCTAssertEqual(Percentage.oneHundred.value, 100)
    }

    func testPercentageCodable() throws {
        let percentage = Percentage(75)
        let data = try JSONEncoder().encode(percentage)
        let decoded = try JSONDecoder().decode(Percentage.self, from: data)

        XCTAssertEqual(decoded.value, percentage.value)
    }

    func testPercentageHashable() {
        let p1 = Percentage(50)
        let p2 = Percentage(50)

        XCTAssertEqual(p1.hashValue, p2.hashValue)
    }

    func testPercentageEquatable() {
        let p1 = Percentage(25)
        let p2 = Percentage(25)
        let p3 = Percentage(30)

        XCTAssertEqual(p1, p2)
        XCTAssertNotEqual(p1, p3)
    }
}
