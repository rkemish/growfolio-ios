//
//  PortfolioTests.swift
//  GrowfolioTests
//
//  Tests for Portfolio domain model.
//

import XCTest
@testable import Growfolio

final class PortfolioTests: XCTestCase {

    // MARK: - Total Return Tests

    func testTotalReturn_Positive() {
        let portfolio = TestFixtures.portfolio(totalValue: 25000, totalCostBasis: 20000)
        XCTAssertEqual(portfolio.totalReturn, 5000)
    }

    func testTotalReturn_Negative() {
        let portfolio = TestFixtures.portfolio(totalValue: 18000, totalCostBasis: 20000)
        XCTAssertEqual(portfolio.totalReturn, -2000)
    }

    func testTotalReturn_Zero() {
        let portfolio = TestFixtures.portfolio(totalValue: 20000, totalCostBasis: 20000)
        XCTAssertEqual(portfolio.totalReturn, 0)
    }

    func testTotalReturn_ZeroCostBasis() {
        let portfolio = TestFixtures.portfolio(totalValue: 5000, totalCostBasis: 0)
        XCTAssertEqual(portfolio.totalReturn, 5000)
    }

    // MARK: - Total Return Percentage Tests

    func testTotalReturnPercentage_Positive() {
        let portfolio = TestFixtures.portfolio(totalValue: 25000, totalCostBasis: 20000)
        XCTAssertEqual(portfolio.totalReturnPercentage, 25)
    }

    func testTotalReturnPercentage_Negative() {
        let portfolio = TestFixtures.portfolio(totalValue: 16000, totalCostBasis: 20000)
        XCTAssertEqual(portfolio.totalReturnPercentage, -20)
    }

    func testTotalReturnPercentage_Zero() {
        let portfolio = TestFixtures.portfolio(totalValue: 20000, totalCostBasis: 20000)
        XCTAssertEqual(portfolio.totalReturnPercentage, 0)
    }

    func testTotalReturnPercentage_ZeroCostBasis_ReturnsZero() {
        let portfolio = TestFixtures.portfolio(totalValue: 5000, totalCostBasis: 0)
        XCTAssertEqual(portfolio.totalReturnPercentage, 0)
    }

    func testTotalReturnPercentage_Doubled() {
        let portfolio = TestFixtures.portfolio(totalValue: 40000, totalCostBasis: 20000)
        XCTAssertEqual(portfolio.totalReturnPercentage, 100)
    }

    // MARK: - IsProfitable Tests

    func testIsProfitable_PositiveReturn_ReturnsTrue() {
        let portfolio = TestFixtures.portfolio(totalValue: 25000, totalCostBasis: 20000)
        XCTAssertTrue(portfolio.isProfitable)
    }

    func testIsProfitable_NegativeReturn_ReturnsFalse() {
        let portfolio = TestFixtures.portfolio(totalValue: 18000, totalCostBasis: 20000)
        XCTAssertFalse(portfolio.isProfitable)
    }

    func testIsProfitable_ZeroReturn_ReturnsFalse() {
        let portfolio = TestFixtures.portfolio(totalValue: 20000, totalCostBasis: 20000)
        XCTAssertFalse(portfolio.isProfitable)
    }

    // MARK: - Total Assets Tests

    func testTotalAssets_IncludesCash() {
        let portfolio = TestFixtures.portfolio(totalValue: 20000, cashBalance: 5000)
        XCTAssertEqual(portfolio.totalAssets, 25000)
    }

    func testTotalAssets_ZeroCash() {
        let portfolio = TestFixtures.portfolio(totalValue: 20000, cashBalance: 0)
        XCTAssertEqual(portfolio.totalAssets, 20000)
    }

    func testTotalAssets_OnlyCash() {
        let portfolio = TestFixtures.portfolio(totalValue: 0, cashBalance: 10000)
        XCTAssertEqual(portfolio.totalAssets, 10000)
    }

    // MARK: - Cash Percentage Tests

    func testCashPercentage_PositiveBalance() {
        let portfolio = TestFixtures.portfolio(totalValue: 20000, cashBalance: 5000)
        XCTAssertEqual(portfolio.cashPercentage, 20)
    }

    func testCashPercentage_ZeroCash() {
        let portfolio = TestFixtures.portfolio(totalValue: 20000, cashBalance: 0)
        XCTAssertEqual(portfolio.cashPercentage, 0)
    }

    func testCashPercentage_AllCash() {
        let portfolio = TestFixtures.portfolio(totalValue: 0, cashBalance: 10000)
        XCTAssertEqual(portfolio.cashPercentage, 100)
    }

    func testCashPercentage_ZeroTotalAssets_ReturnsZero() {
        let portfolio = TestFixtures.portfolio(totalValue: 0, cashBalance: 0)
        XCTAssertEqual(portfolio.cashPercentage, 0)
    }

    // MARK: - Invested Percentage Tests

    func testInvestedPercentage_FullyInvested() {
        let portfolio = TestFixtures.portfolio(totalValue: 20000, cashBalance: 0)
        XCTAssertEqual(portfolio.investedPercentage, 100)
    }

    func testInvestedPercentage_HalfInvested() {
        let portfolio = TestFixtures.portfolio(totalValue: 10000, cashBalance: 10000)
        XCTAssertEqual(portfolio.investedPercentage, 50)
    }

    func testInvestedPercentage_NoInvestments() {
        let portfolio = TestFixtures.portfolio(totalValue: 0, cashBalance: 10000)
        XCTAssertEqual(portfolio.investedPercentage, 0)
    }

    func testInvestedPercentage_ZeroTotalAssets_ReturnsZero() {
        let portfolio = TestFixtures.portfolio(totalValue: 0, cashBalance: 0)
        XCTAssertEqual(portfolio.investedPercentage, 0)
    }

    // MARK: - PortfolioType Tests

    func testPortfolioType_DisplayName() {
        XCTAssertEqual(PortfolioType.personal.displayName, "Personal")
        XCTAssertEqual(PortfolioType.retirement.displayName, "Retirement")
        XCTAssertEqual(PortfolioType.education.displayName, "Education")
        XCTAssertEqual(PortfolioType.ira.displayName, "Traditional IRA")
        XCTAssertEqual(PortfolioType.roth.displayName, "Roth IRA")
        XCTAssertEqual(PortfolioType.hsa.displayName, "HSA")
    }

    func testPortfolioType_IconName() {
        XCTAssertFalse(PortfolioType.personal.iconName.isEmpty)
        XCTAssertFalse(PortfolioType.retirement.iconName.isEmpty)
    }

    func testPortfolioType_IsTaxAdvantaged() {
        XCTAssertTrue(PortfolioType.retirement.isTaxAdvantaged)
        XCTAssertTrue(PortfolioType.ira.isTaxAdvantaged)
        XCTAssertTrue(PortfolioType.roth.isTaxAdvantaged)
        XCTAssertTrue(PortfolioType.hsa.isTaxAdvantaged)
        XCTAssertTrue(PortfolioType.education.isTaxAdvantaged)

        XCTAssertFalse(PortfolioType.personal.isTaxAdvantaged)
        XCTAssertFalse(PortfolioType.brokerage.isTaxAdvantaged)
        XCTAssertFalse(PortfolioType.joint.isTaxAdvantaged)
    }

    func testPortfolioType_AllCases() {
        XCTAssertEqual(PortfolioType.allCases.count, 11)
    }

    // MARK: - PortfolioPerformance Tests

    func testPortfolioPerformance_OutperformsBenchmark_True() {
        let performance = PortfolioPerformance(
            portfolioId: "portfolio-123",
            period: .oneYear,
            startValue: 10000,
            endValue: 12000,
            absoluteReturn: 2000,
            percentageReturn: 20,
            benchmarkReturn: 15
        )
        XCTAssertTrue(performance.outperformsBenchmark)
    }

    func testPortfolioPerformance_OutperformsBenchmark_False() {
        let performance = PortfolioPerformance(
            portfolioId: "portfolio-123",
            period: .oneYear,
            startValue: 10000,
            endValue: 11000,
            absoluteReturn: 1000,
            percentageReturn: 10,
            benchmarkReturn: 15
        )
        XCTAssertFalse(performance.outperformsBenchmark)
    }

    func testPortfolioPerformance_NoBenchmark_ReturnsFalse() {
        let performance = PortfolioPerformance(
            portfolioId: "portfolio-123",
            period: .oneYear,
            startValue: 10000,
            endValue: 12000,
            absoluteReturn: 2000,
            percentageReturn: 20,
            benchmarkReturn: nil
        )
        XCTAssertFalse(performance.outperformsBenchmark)
    }

    // MARK: - PerformanceDataPoint Tests

    func testPerformanceDataPoint_Id() {
        let date = Date()
        let dataPoint = PerformanceDataPoint(date: date, value: 1000)
        XCTAssertEqual(dataPoint.id, date)
    }

    // MARK: - AllocationItem Tests

    func testAllocationItem_Id() {
        let item = AllocationItem(category: "Technology", value: 5000, percentage: 25, colorHex: "#007AFF")
        XCTAssertEqual(item.id, "Technology")
    }

    // MARK: - PortfoliosSummary Tests

    func testPortfoliosSummary_TotalValue() {
        let portfolios = [
            TestFixtures.portfolio(id: "p1", totalValue: 10000),
            TestFixtures.portfolio(id: "p2", totalValue: 20000),
            TestFixtures.portfolio(id: "p3", totalValue: 15000)
        ]
        let summary = PortfoliosSummary(portfolios: portfolios)

        XCTAssertEqual(summary.totalValue, 45000)
    }

    func testPortfoliosSummary_TotalCostBasis() {
        let portfolios = [
            TestFixtures.portfolio(id: "p1", totalCostBasis: 8000),
            TestFixtures.portfolio(id: "p2", totalCostBasis: 18000),
            TestFixtures.portfolio(id: "p3", totalCostBasis: 12000)
        ]
        let summary = PortfoliosSummary(portfolios: portfolios)

        XCTAssertEqual(summary.totalCostBasis, 38000)
    }

    func testPortfoliosSummary_TotalCashBalance() {
        let portfolios = [
            TestFixtures.portfolio(id: "p1", cashBalance: 1000),
            TestFixtures.portfolio(id: "p2", cashBalance: 2000),
            TestFixtures.portfolio(id: "p3", cashBalance: 500)
        ]
        let summary = PortfoliosSummary(portfolios: portfolios)

        XCTAssertEqual(summary.totalCashBalance, 3500)
    }

    func testPortfoliosSummary_TotalReturn() {
        let portfolios = [
            TestFixtures.portfolio(id: "p1", totalValue: 12000, totalCostBasis: 10000),
            TestFixtures.portfolio(id: "p2", totalValue: 9000, totalCostBasis: 10000)
        ]
        let summary = PortfoliosSummary(portfolios: portfolios)

        XCTAssertEqual(summary.totalReturn, 1000) // 21000 - 20000
    }

    func testPortfoliosSummary_TotalReturnPercentage() {
        let portfolios = [
            TestFixtures.portfolio(id: "p1", totalValue: 12000, totalCostBasis: 10000)
        ]
        let summary = PortfoliosSummary(portfolios: portfolios)

        XCTAssertEqual(summary.totalReturnPercentage, 20)
    }

    func testPortfoliosSummary_EmptyPortfolios() {
        let summary = PortfoliosSummary(portfolios: [])

        XCTAssertEqual(summary.totalPortfolios, 0)
        XCTAssertEqual(summary.totalValue, 0)
        XCTAssertEqual(summary.totalCostBasis, 0)
        XCTAssertEqual(summary.totalCashBalance, 0)
        XCTAssertEqual(summary.totalReturn, 0)
        XCTAssertEqual(summary.totalReturnPercentage, 0)
    }

    // MARK: - Codable Tests

    func testPortfolio_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.portfolio(
            name: "Test Portfolio",
            type: .retirement,
            totalValue: 150000,
            totalCostBasis: 100000,
            cashBalance: 5000
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(Portfolio.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.totalValue, original.totalValue)
        XCTAssertEqual(decoded.totalCostBasis, original.totalCostBasis)
        XCTAssertEqual(decoded.cashBalance, original.cashBalance)
    }

    func testPortfolioType_Codable() throws {
        for type in PortfolioType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(PortfolioType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    // MARK: - Equatable Tests

    func testPortfolio_Equatable() {
        let portfolio1 = TestFixtures.portfolio(id: "p1", name: "Test")
        let portfolio2 = TestFixtures.portfolio(id: "p1", name: "Test")
        let portfolio3 = TestFixtures.portfolio(id: "p2", name: "Different")

        XCTAssertEqual(portfolio1, portfolio2)
        XCTAssertNotEqual(portfolio1, portfolio3)
    }

    // MARK: - Hashable Tests

    func testPortfolio_Hashable() {
        let portfolio1 = TestFixtures.portfolio(id: "p1")
        let portfolio2 = TestFixtures.portfolio(id: "p2")

        var set = Set<Portfolio>()
        set.insert(portfolio1)
        set.insert(portfolio2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Edge Cases

    func testPortfolio_VeryLargeValues() {
        let portfolio = TestFixtures.portfolio(
            totalValue: 999_999_999_999,
            totalCostBasis: 500_000_000_000,
            cashBalance: 100_000_000_000
        )

        XCTAssertEqual(portfolio.totalReturn, 499_999_999_999)
        XCTAssertGreaterThan(portfolio.totalAssets, 0)
    }

    func testPortfolio_VerySmallValues() {
        let portfolio = TestFixtures.portfolio(
            totalValue: Decimal(string: "0.01")!,
            totalCostBasis: Decimal(string: "0.005")!,
            cashBalance: Decimal(string: "0.001")!
        )

        XCTAssertEqual(portfolio.totalReturn, Decimal(string: "0.005")!)
        XCTAssertEqual(portfolio.totalReturnPercentage, 100)
    }
}
