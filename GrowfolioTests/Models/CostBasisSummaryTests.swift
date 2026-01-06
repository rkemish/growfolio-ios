//
//  CostBasisSummaryTests.swift
//  GrowfolioTests
//
//  Tests for CostBasisSummary domain model.
//

import XCTest
@testable import Growfolio

final class CostBasisSummaryTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithAllParameters() {
        let summary = TestFixtures.costBasisSummary(
            symbol: "AAPL",
            totalShares: 18,
            totalCostUsd: 2525,
            totalCostGbp: 2020,
            averageCostUsd: 140.28,
            averageCostGbp: 112.22,
            currentPriceUsd: 175,
            currentFxRate: 1.25
        )

        XCTAssertEqual(summary.symbol, "AAPL")
        XCTAssertEqual(summary.totalShares, 18)
        XCTAssertEqual(summary.totalCostUsd, 2525)
        XCTAssertEqual(summary.totalCostGbp, 2020)
        XCTAssertEqual(summary.averageCostUsd, 140.28)
        XCTAssertEqual(summary.averageCostGbp, 112.22)
        XCTAssertEqual(summary.currentPriceUsd, 175)
        XCTAssertEqual(summary.currentFxRate, 1.25)
    }

    func testInit_WithNilMarketData() {
        let summary = TestFixtures.costBasisSummary(
            currentPriceUsd: nil,
            currentFxRate: nil
        )

        XCTAssertNil(summary.currentPriceUsd)
        XCTAssertNil(summary.currentFxRate)
    }

    // MARK: - Current Value Tests

    func testCurrentValueUsd_WithPrice() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            currentPriceUsd: 175
        )

        XCTAssertEqual(summary.currentValueUsd, 1750) // 10 * 175
    }

    func testCurrentValueUsd_WithNilPrice_ReturnsZero() {
        let summary = TestFixtures.costBasisSummary(currentPriceUsd: nil)

        XCTAssertEqual(summary.currentValueUsd, 0)
    }

    func testCurrentValueGbp_WithPriceAndRate() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            currentPriceUsd: 175,
            currentFxRate: 1.25
        )

        // (10 * 175) / 1.25 = 1400
        XCTAssertEqual(summary.currentValueGbp, 1400)
    }

    func testCurrentValueGbp_WithNilFxRate_ReturnsZero() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            currentPriceUsd: 175,
            currentFxRate: nil
        )

        XCTAssertEqual(summary.currentValueGbp, 0)
    }

    func testCurrentValueGbp_WithZeroFxRate_ReturnsZero() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            currentPriceUsd: 175,
            currentFxRate: 0
        )

        XCTAssertEqual(summary.currentValueGbp, 0)
    }

    // MARK: - Unrealized P&L Tests

    func testUnrealizedPnlUsd_Positive() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            totalCostUsd: 1500,
            currentPriceUsd: 175
        )

        // (10 * 175) - 1500 = 1750 - 1500 = 250
        XCTAssertEqual(summary.unrealizedPnlUsd, 250)
    }

    func testUnrealizedPnlUsd_Negative() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            totalCostUsd: 2000,
            currentPriceUsd: 175
        )

        // (10 * 175) - 2000 = 1750 - 2000 = -250
        XCTAssertEqual(summary.unrealizedPnlUsd, -250)
    }

    func testUnrealizedPnlUsd_Zero() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            totalCostUsd: 1750,
            currentPriceUsd: 175
        )

        XCTAssertEqual(summary.unrealizedPnlUsd, 0)
    }

    func testUnrealizedPnlGbp() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            totalCostGbp: 1200,
            currentPriceUsd: 175,
            currentFxRate: 1.25
        )

        // currentValueGbp = 1750 / 1.25 = 1400
        // unrealizedPnlGbp = 1400 - 1200 = 200
        XCTAssertEqual(summary.unrealizedPnlGbp, 200)
    }

    func testUnrealizedPnlPercentage_Positive() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            totalCostUsd: 1000,
            currentPriceUsd: 150
        )

        // ((1500 - 1000) / 1000) * 100 = 50%
        XCTAssertEqual(summary.unrealizedPnlPercentage, 50)
    }

    func testUnrealizedPnlPercentage_Negative() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            totalCostUsd: 2000,
            currentPriceUsd: 150
        )

        // ((1500 - 2000) / 2000) * 100 = -25%
        XCTAssertEqual(summary.unrealizedPnlPercentage, -25)
    }

    func testUnrealizedPnlPercentage_ZeroCostBasis_ReturnsZero() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            totalCostUsd: 0,
            currentPriceUsd: 150
        )

        XCTAssertEqual(summary.unrealizedPnlPercentage, 0)
    }

    // MARK: - IsProfitable Tests

    func testIsProfitable_PositivePnl_ReturnsTrue() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            totalCostUsd: 1000,
            currentPriceUsd: 150
        )

        XCTAssertTrue(summary.isProfitable)
    }

    func testIsProfitable_NegativePnl_ReturnsFalse() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            totalCostUsd: 2000,
            currentPriceUsd: 150
        )

        XCTAssertFalse(summary.isProfitable)
    }

    func testIsProfitable_ZeroPnl_ReturnsFalse() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 10,
            totalCostUsd: 1500,
            currentPriceUsd: 150
        )

        XCTAssertFalse(summary.isProfitable)
    }

    // MARK: - Tax Analysis Tests

    func testLotCount() {
        let lots = TestFixtures.sampleCostBasisLots
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertEqual(summary.lotCount, 3)
    }

    func testShortTermLots_ReturnsCorrectLots() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, shares: 5),
            TestFixtures.costBasisLot(date: longTermDate, shares: 10),
            TestFixtures.costBasisLot(date: shortTermDate, shares: 3)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertEqual(summary.shortTermLots.count, 2)
    }

    func testLongTermLots_ReturnsCorrectLots() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, shares: 5),
            TestFixtures.costBasisLot(date: longTermDate, shares: 10),
            TestFixtures.costBasisLot(date: longTermDate, shares: 7)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertEqual(summary.longTermLots.count, 2)
    }

    func testShortTermShares() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, shares: 5),
            TestFixtures.costBasisLot(date: longTermDate, shares: 10),
            TestFixtures.costBasisLot(date: shortTermDate, shares: 3)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertEqual(summary.shortTermShares, 8)
    }

    func testLongTermShares() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, shares: 5),
            TestFixtures.costBasisLot(date: longTermDate, shares: 10),
            TestFixtures.costBasisLot(date: longTermDate, shares: 7)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertEqual(summary.longTermShares, 17)
    }

    func testShortTermCostUsd() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, totalUsd: 500),
            TestFixtures.costBasisLot(date: longTermDate, totalUsd: 1000),
            TestFixtures.costBasisLot(date: shortTermDate, totalUsd: 300)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertEqual(summary.shortTermCostUsd, 800)
    }

    func testLongTermCostUsd() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, totalUsd: 500),
            TestFixtures.costBasisLot(date: longTermDate, totalUsd: 1000),
            TestFixtures.costBasisLot(date: longTermDate, totalUsd: 700)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertEqual(summary.longTermCostUsd, 1700)
    }

    func testShortTermUnrealizedPnlUsd() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, shares: 10, totalUsd: 1000),
            TestFixtures.costBasisLot(date: longTermDate, shares: 5, totalUsd: 500)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots, currentPriceUsd: 150)

        // shortTermShares (10) * 150 - shortTermCostUsd (1000) = 1500 - 1000 = 500
        XCTAssertEqual(summary.shortTermUnrealizedPnlUsd, 500)
    }

    func testLongTermUnrealizedPnlUsd() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, shares: 10, totalUsd: 1000),
            TestFixtures.costBasisLot(date: longTermDate, shares: 5, totalUsd: 500)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots, currentPriceUsd: 150)

        // longTermShares (5) * 150 - longTermCostUsd (500) = 750 - 500 = 250
        XCTAssertEqual(summary.longTermUnrealizedPnlUsd, 250)
    }

    func testLongTermPercentage() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, shares: 25),
            TestFixtures.costBasisLot(date: longTermDate, shares: 75)
        ]
        let summary = TestFixtures.costBasisSummary(totalShares: 100, lots: lots)

        XCTAssertEqual(summary.longTermPercentage, 75)
    }

    func testLongTermPercentage_ZeroShares_ReturnsZero() {
        let summary = TestFixtures.costBasisSummary(totalShares: 0, lots: [])

        XCTAssertEqual(summary.longTermPercentage, 0)
    }

    // MARK: - Date Tests

    func testFirstPurchaseDate() {
        let date1 = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let date2 = Calendar.current.date(byAdding: .day, value: -50, to: Date())!
        let date3 = Calendar.current.date(byAdding: .day, value: -150, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: date1),
            TestFixtures.costBasisLot(date: date2),
            TestFixtures.costBasisLot(date: date3)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertEqual(summary.firstPurchaseDate, date3)
    }

    func testFirstPurchaseDate_EmptyLots_ReturnsNil() {
        let summary = TestFixtures.costBasisSummary(lots: [])

        XCTAssertNil(summary.firstPurchaseDate)
    }

    func testLastPurchaseDate() {
        let date1 = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let date2 = Calendar.current.date(byAdding: .day, value: -50, to: Date())!
        let date3 = Calendar.current.date(byAdding: .day, value: -150, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: date1),
            TestFixtures.costBasisLot(date: date2),
            TestFixtures.costBasisLot(date: date3)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertEqual(summary.lastPurchaseDate, date2)
    }

    func testLastPurchaseDate_EmptyLots_ReturnsNil() {
        let summary = TestFixtures.costBasisSummary(lots: [])

        XCTAssertNil(summary.lastPurchaseDate)
    }

    func testHoldingPeriodDays() {
        let date = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let lots = [TestFixtures.costBasisLot(date: date)]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertNotNil(summary.holdingPeriodDays)
        XCTAssertGreaterThanOrEqual(summary.holdingPeriodDays ?? 0, 99)
    }

    func testHoldingPeriodDays_EmptyLots_ReturnsNil() {
        let summary = TestFixtures.costBasisSummary(lots: [])

        XCTAssertNil(summary.holdingPeriodDays)
    }

    // MARK: - FX Rate Tests

    func testAverageFxRate() {
        let lots = [
            TestFixtures.costBasisLot(fxRate: 1.20),
            TestFixtures.costBasisLot(fxRate: 1.25),
            TestFixtures.costBasisLot(fxRate: 1.30)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        XCTAssertEqual(summary.averageFxRate, 1.25)
    }

    func testAverageFxRate_EmptyLots_ReturnsZero() {
        let summary = TestFixtures.costBasisSummary(lots: [])

        XCTAssertEqual(summary.averageFxRate, 0)
    }

    func testWeightedAverageFxRate() {
        let lots = [
            TestFixtures.costBasisLot(totalUsd: 1000, fxRate: 1.20),
            TestFixtures.costBasisLot(totalUsd: 2000, fxRate: 1.30)
        ]
        let summary = TestFixtures.costBasisSummary(totalCostUsd: 3000, lots: lots)

        // Weighted: (1.20 * 1000 + 1.30 * 2000) / 3000 = (1200 + 2600) / 3000 = 3800 / 3000 = 1.2667
        let expected = (Decimal(1.20) * 1000 + Decimal(1.30) * 2000) / 3000
        XCTAssertEqual(summary.weightedAverageFxRate, expected)
    }

    func testWeightedAverageFxRate_ZeroCost_ReturnsZero() {
        let summary = TestFixtures.costBasisSummary(totalCostUsd: 0, lots: [])

        XCTAssertEqual(summary.weightedAverageFxRate, 0)
    }

    // MARK: - WithMarketData Tests

    func testWithMarketData_ReturnsUpdatedCopy() {
        let original = TestFixtures.costBasisSummary(
            currentPriceUsd: nil,
            currentFxRate: nil
        )

        let updated = original.withMarketData(currentPrice: 200, fxRate: 1.30)

        XCTAssertNil(original.currentPriceUsd)
        XCTAssertNil(original.currentFxRate)
        XCTAssertEqual(updated.currentPriceUsd, 200)
        XCTAssertEqual(updated.currentFxRate, 1.30)
    }

    // MARK: - TaxSummary Tests

    func testTaxSummary_Initialization() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, shares: 10, totalUsd: 1000),
            TestFixtures.costBasisLot(date: longTermDate, shares: 5, totalUsd: 500)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots, currentPriceUsd: 150)

        let taxSummary = TaxSummary(from: summary)

        XCTAssertEqual(taxSummary.shortTermShares, 10)
        XCTAssertEqual(taxSummary.longTermShares, 5)
        XCTAssertEqual(taxSummary.shortTermCostBasisUsd, 1000)
        XCTAssertEqual(taxSummary.longTermCostBasisUsd, 500)
    }

    func testTaxSummary_TotalUnrealizedGain() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!

        let lots = [
            TestFixtures.costBasisLot(date: shortTermDate, shares: 10, totalUsd: 1000),
            TestFixtures.costBasisLot(date: longTermDate, shares: 5, totalUsd: 500)
        ]
        let summary = TestFixtures.costBasisSummary(lots: lots, currentPriceUsd: 150)

        let taxSummary = TaxSummary(from: summary)

        // shortTerm: 10 * 150 - 1000 = 500
        // longTerm: 5 * 150 - 500 = 250
        // total: 750
        XCTAssertEqual(taxSummary.totalUnrealizedGainUsd, 750)
    }

    func testTaxSummary_HasLongTermHoldings() {
        let longTermDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!
        let lots = [TestFixtures.costBasisLot(date: longTermDate, shares: 5)]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        let taxSummary = TaxSummary(from: summary)

        XCTAssertTrue(taxSummary.hasLongTermHoldings)
    }

    func testTaxSummary_HasShortTermHoldings() {
        let shortTermDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let lots = [TestFixtures.costBasisLot(date: shortTermDate, shares: 5)]
        let summary = TestFixtures.costBasisSummary(lots: lots)

        let taxSummary = TaxSummary(from: summary)

        XCTAssertTrue(taxSummary.hasShortTermHoldings)
    }

    // MARK: - Codable Tests

    func testCostBasisSummary_EncodeDecode_RoundTrip() throws {
        let lots = [TestFixtures.costBasisLot()]
        let original = TestFixtures.costBasisSummary(
            symbol: "MSFT",
            totalShares: 25,
            totalCostUsd: 5000,
            totalCostGbp: 4000,
            averageCostUsd: 200,
            averageCostGbp: 160,
            lots: lots,
            currentPriceUsd: 250,
            currentFxRate: 1.25
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(CostBasisSummary.self, from: data)

        XCTAssertEqual(decoded.symbol, original.symbol)
        XCTAssertEqual(decoded.totalShares, original.totalShares)
        XCTAssertEqual(decoded.totalCostUsd, original.totalCostUsd)
        XCTAssertEqual(decoded.currentPriceUsd, original.currentPriceUsd)
    }

    // MARK: - Equatable Tests

    func testCostBasisSummary_Equatable() {
        let summary1 = TestFixtures.costBasisSummary(symbol: "AAPL", totalShares: 10)
        let summary2 = TestFixtures.costBasisSummary(symbol: "AAPL", totalShares: 10)
        let summary3 = TestFixtures.costBasisSummary(symbol: "MSFT", totalShares: 10)

        XCTAssertEqual(summary1, summary2)
        XCTAssertNotEqual(summary1, summary3)
    }

    // MARK: - Edge Cases

    func testCostBasisSummary_ZeroValues() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 0,
            totalCostUsd: 0,
            totalCostGbp: 0,
            averageCostUsd: 0,
            averageCostGbp: 0,
            lots: [],
            currentPriceUsd: 0,
            currentFxRate: 0
        )

        XCTAssertEqual(summary.currentValueUsd, 0)
        XCTAssertEqual(summary.currentValueGbp, 0)
        XCTAssertEqual(summary.unrealizedPnlUsd, 0)
        XCTAssertEqual(summary.unrealizedPnlPercentage, 0)
        XCTAssertFalse(summary.isProfitable)
    }

    func testCostBasisSummary_VeryLargeValues() {
        let summary = TestFixtures.costBasisSummary(
            totalShares: 1_000_000,
            totalCostUsd: 150_000_000,
            currentPriceUsd: 175
        )

        XCTAssertEqual(summary.currentValueUsd, 175_000_000)
        XCTAssertEqual(summary.unrealizedPnlUsd, 25_000_000)
    }
}
