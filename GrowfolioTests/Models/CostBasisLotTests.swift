//
//  CostBasisLotTests.swift
//  GrowfolioTests
//
//  Tests for CostBasisLot domain model.
//

import XCTest
@testable import Growfolio

final class CostBasisLotTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithAllParameters() {
        let lot = TestFixtures.costBasisLot(
            date: TestFixtures.referenceDate,
            shares: 10,
            priceUsd: 150,
            totalUsd: 1500,
            totalGbp: 1200,
            fxRate: 1.25
        )

        XCTAssertEqual(lot.shares, 10)
        XCTAssertEqual(lot.priceUsd, 150)
        XCTAssertEqual(lot.totalUsd, 1500)
        XCTAssertEqual(lot.totalGbp, 1200)
        XCTAssertEqual(lot.fxRate, 1.25)
    }

    // MARK: - Computed Properties Tests

    func testId_DerivedFromDateAndShares() {
        let lot = TestFixtures.costBasisLot(
            date: TestFixtures.referenceDate,
            shares: 10
        )

        XCTAssertFalse(lot.id.isEmpty)
        XCTAssertTrue(lot.id.contains("10"))
    }

    func testPriceGbp_CalculatedCorrectly() {
        let lot = TestFixtures.costBasisLot(
            priceUsd: 150,
            fxRate: 1.25
        )

        // 150 / 1.25 = 120
        XCTAssertEqual(lot.priceGbp, 120)
    }

    func testPriceGbp_ZeroFxRate_ReturnsZero() {
        let lot = TestFixtures.costBasisLot(
            priceUsd: 150,
            fxRate: 0
        )

        XCTAssertEqual(lot.priceGbp, 0)
    }

    func testPriceGbp_DifferentFxRates() {
        let lot1 = TestFixtures.costBasisLot(priceUsd: 100, fxRate: 1.0)
        XCTAssertEqual(lot1.priceGbp, 100)

        let lot2 = TestFixtures.costBasisLot(priceUsd: 100, fxRate: 2.0)
        XCTAssertEqual(lot2.priceGbp, 50)

        let lot3 = TestFixtures.costBasisLot(priceUsd: 100, fxRate: 0.5)
        XCTAssertEqual(lot3.priceGbp, 200)
    }

    func testDaysSincePurchase_RecentDate() {
        // Using pastDate which is 30 days ago from referenceDate
        let lot = TestFixtures.costBasisLot(date: TestFixtures.pastDate)

        // The actual value depends on the current date
        XCTAssertGreaterThanOrEqual(lot.daysSincePurchase, 0)
    }

    func testDaysSincePurchase_FutureDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let lot = TestFixtures.costBasisLot(date: futureDate)

        // For future dates, daysSincePurchase will be negative
        XCTAssertLessThan(lot.daysSincePurchase, 0)
    }

    // MARK: - IsLongTerm Tests

    func testIsLongTerm_Over365Days_ReturnsTrue() {
        // longTermDate is 400 days ago from referenceDate
        let lot = TestFixtures.costBasisLot(date: TestFixtures.longTermDate)

        XCTAssertTrue(lot.isLongTerm)
    }

    func testIsLongTerm_Under365Days_ReturnsFalse() {
        // 30 days ago from today
        let recentDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let lot = TestFixtures.costBasisLot(date: recentDate)

        XCTAssertFalse(lot.isLongTerm)
    }

    func testIsLongTerm_Exactly365Days_ReturnsFalse() {
        let exactlyOneYearAgo = Calendar.current.date(byAdding: .day, value: -365, to: Date())!
        let lot = TestFixtures.costBasisLot(date: exactlyOneYearAgo)

        // > 365 is required, so exactly 365 days is short-term
        XCTAssertFalse(lot.isLongTerm)
    }

    func testIsLongTerm_OverOneYear_ReturnsTrue() {
        let over366Days = Calendar.current.date(byAdding: .day, value: -366, to: Date())!
        let lot = TestFixtures.costBasisLot(date: over366Days)

        XCTAssertTrue(lot.isLongTerm)
    }

    // MARK: - Holding Period Category Tests

    func testHoldingPeriodCategory_ShortTerm() {
        // 30 days ago from today
        let recentDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let lot = TestFixtures.costBasisLot(date: recentDate)

        XCTAssertEqual(lot.holdingPeriodCategory, .shortTerm)
    }

    func testHoldingPeriodCategory_LongTerm() {
        let lot = TestFixtures.costBasisLot(date: TestFixtures.longTermDate)

        XCTAssertEqual(lot.holdingPeriodCategory, .longTerm)
    }

    // MARK: - HoldingPeriodCategory Enum Tests

    func testHoldingPeriodCategory_DisplayName() {
        XCTAssertEqual(HoldingPeriodCategory.shortTerm.displayName, "Short-Term")
        XCTAssertEqual(HoldingPeriodCategory.longTerm.displayName, "Long-Term")
    }

    func testHoldingPeriodCategory_Description() {
        XCTAssertEqual(HoldingPeriodCategory.shortTerm.description, "Held 1 year or less")
        XCTAssertEqual(HoldingPeriodCategory.longTerm.description, "Held more than 1 year")
    }

    func testHoldingPeriodCategory_TaxImplication() {
        XCTAssertEqual(HoldingPeriodCategory.shortTerm.taxImplication, "Taxed as ordinary income")
        XCTAssertEqual(HoldingPeriodCategory.longTerm.taxImplication, "Preferential capital gains rates")
    }

    func testHoldingPeriodCategory_RawValue() {
        XCTAssertEqual(HoldingPeriodCategory.shortTerm.rawValue, "short_term")
        XCTAssertEqual(HoldingPeriodCategory.longTerm.rawValue, "long_term")
    }

    // MARK: - Codable Tests

    func testCostBasisLot_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.costBasisLot(
            date: TestFixtures.referenceDate,
            shares: 15,
            priceUsd: 175,
            totalUsd: 2625,
            totalGbp: 2100,
            fxRate: 1.25
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(CostBasisLot.self, from: data)

        XCTAssertEqual(decoded.shares, original.shares)
        XCTAssertEqual(decoded.priceUsd, original.priceUsd)
        XCTAssertEqual(decoded.totalUsd, original.totalUsd)
        XCTAssertEqual(decoded.totalGbp, original.totalGbp)
        XCTAssertEqual(decoded.fxRate, original.fxRate)
    }

    func testHoldingPeriodCategory_Codable() throws {
        let categories: [HoldingPeriodCategory] = [.shortTerm, .longTerm]
        for category in categories {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(HoldingPeriodCategory.self, from: data)
            XCTAssertEqual(decoded, category)
        }
    }

    // MARK: - Equatable Tests

    func testCostBasisLot_Equatable() {
        let lot1 = TestFixtures.costBasisLot(shares: 10, priceUsd: 150)
        let lot2 = TestFixtures.costBasisLot(shares: 10, priceUsd: 150)
        let lot3 = TestFixtures.costBasisLot(shares: 20, priceUsd: 150)

        XCTAssertEqual(lot1, lot2)
        XCTAssertNotEqual(lot1, lot3)
    }

    // MARK: - Hashable Tests

    func testCostBasisLot_Hashable() {
        let lot1 = TestFixtures.costBasisLot(date: TestFixtures.referenceDate, shares: 10)
        let lot2 = TestFixtures.costBasisLot(date: TestFixtures.pastDate, shares: 20)

        var set = Set<CostBasisLot>()
        set.insert(lot1)
        set.insert(lot2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Array Extension Tests

    func testArrayExtension_GroupedByHoldingPeriod() {
        // Create lots with current-relative dates to ensure both short and long term
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!
        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, shares: 10),
            TestFixtures.costBasisLot(date: longTermDate, shares: 5)
        ]

        let grouped = lots.groupedByHoldingPeriod()

        XCTAssertNotNil(grouped[.shortTerm])
        XCTAssertNotNil(grouped[.longTerm])
    }

    func testArrayExtension_TotalShares() {
        let lots = [
            TestFixtures.costBasisLot(shares: 5),
            TestFixtures.costBasisLot(shares: 10),
            TestFixtures.costBasisLot(shares: 3)
        ]

        XCTAssertEqual(lots.totalShares, 18)
    }

    func testArrayExtension_TotalCostUsd() {
        let lots = [
            TestFixtures.costBasisLot(totalUsd: 500),
            TestFixtures.costBasisLot(totalUsd: 1500),
            TestFixtures.costBasisLot(totalUsd: 525)
        ]

        XCTAssertEqual(lots.totalCostUsd, 2525)
    }

    func testArrayExtension_TotalCostGbp() {
        let lots = [
            TestFixtures.costBasisLot(totalGbp: 400),
            TestFixtures.costBasisLot(totalGbp: 1200),
            TestFixtures.costBasisLot(totalGbp: 420)
        ]

        XCTAssertEqual(lots.totalCostGbp, 2020)
    }

    func testArrayExtension_ShortTermLots() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate),
            TestFixtures.costBasisLot(date: longTermDate),
            TestFixtures.costBasisLot(date: shortTermDate)
        ]

        let shortTermLots = lots.shortTermLots

        XCTAssertEqual(shortTermLots.count, 2)
    }

    func testArrayExtension_LongTermLots() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate),
            TestFixtures.costBasisLot(date: longTermDate),
            TestFixtures.costBasisLot(date: longTermDate)
        ]

        let longTermLots = lots.longTermLots

        XCTAssertEqual(longTermLots.count, 2)
    }

    func testArrayExtension_SortedByDateDescending() {
        let date1 = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let date2 = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let date3 = Calendar.current.date(byAdding: .day, value: -15, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: date1),
            TestFixtures.costBasisLot(date: date2),
            TestFixtures.costBasisLot(date: date3)
        ]

        let sorted = lots.sortedByDateDescending

        XCTAssertEqual(sorted[0].date, date2)
        XCTAssertEqual(sorted[1].date, date1)
        XCTAssertEqual(sorted[2].date, date3)
    }

    func testArrayExtension_SortedByDateAscending() {
        let date1 = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let date2 = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let date3 = Calendar.current.date(byAdding: .day, value: -15, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: date1),
            TestFixtures.costBasisLot(date: date2),
            TestFixtures.costBasisLot(date: date3)
        ]

        let sorted = lots.sortedByDateAscending

        XCTAssertEqual(sorted[0].date, date3)
        XCTAssertEqual(sorted[1].date, date1)
        XCTAssertEqual(sorted[2].date, date2)
    }

    func testArrayExtension_EmptyArray() {
        let lots: [CostBasisLot] = []

        XCTAssertEqual(lots.totalShares, 0)
        XCTAssertEqual(lots.totalCostUsd, 0)
        XCTAssertEqual(lots.totalCostGbp, 0)
        XCTAssertTrue(lots.shortTermLots.isEmpty)
        XCTAssertTrue(lots.longTermLots.isEmpty)
    }

    // MARK: - Edge Cases

    func testCostBasisLot_ZeroValues() {
        let lot = TestFixtures.costBasisLot(
            shares: 0,
            priceUsd: 0,
            totalUsd: 0,
            totalGbp: 0,
            fxRate: 1.25
        )

        XCTAssertEqual(lot.shares, 0)
        XCTAssertEqual(lot.priceUsd, 0)
        XCTAssertEqual(lot.priceGbp, 0)
    }

    func testCostBasisLot_VeryLargeValues() {
        let lot = TestFixtures.costBasisLot(
            shares: 1_000_000,
            priceUsd: 999_999,
            totalUsd: 999_999_000_000,
            totalGbp: 799_999_200_000,
            fxRate: 1.25
        )

        XCTAssertEqual(lot.shares, 1_000_000)
        XCTAssertEqual(lot.priceGbp, Decimal(999_999) / Decimal(1.25))
    }

    func testCostBasisLot_VerySmallValues() {
        let lot = TestFixtures.costBasisLot(
            shares: Decimal(string: "0.000001")!,
            priceUsd: Decimal(string: "0.01")!,
            totalUsd: Decimal(string: "0.00000001")!,
            totalGbp: Decimal(string: "0.000000008")!,
            fxRate: 1.25
        )

        XCTAssertEqual(lot.shares, Decimal(string: "0.000001")!)
    }

    func testCostBasisLot_FractionalShares() {
        let lot = TestFixtures.costBasisLot(
            shares: Decimal(string: "0.123456")!,
            priceUsd: 175,
            totalUsd: Decimal(string: "21.6048")!,
            totalGbp: Decimal(string: "17.28384")!,
            fxRate: 1.25
        )

        XCTAssertEqual(lot.shares, Decimal(string: "0.123456")!)
    }
}
