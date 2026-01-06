//
//  HoldingTests.swift
//  GrowfolioTests
//
//  Tests for Holding domain model.
//

import XCTest
@testable import Growfolio

final class HoldingTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithDefaults() {
        let holding = Holding(
            portfolioId: "portfolio-123",
            stockSymbol: "AAPL",
            quantity: 10,
            averageCostPerShare: 150,
            currentPricePerShare: 175
        )

        XCTAssertFalse(holding.id.isEmpty)
        XCTAssertEqual(holding.portfolioId, "portfolio-123")
        XCTAssertEqual(holding.stockSymbol, "AAPL")
        XCTAssertNil(holding.stockName)
        XCTAssertEqual(holding.quantity, 10)
        XCTAssertEqual(holding.averageCostPerShare, 150)
        XCTAssertEqual(holding.currentPricePerShare, 175)
        XCTAssertNil(holding.firstPurchaseDate)
        XCTAssertNil(holding.lastPurchaseDate)
        XCTAssertNil(holding.sector)
        XCTAssertNil(holding.industry)
        XCTAssertEqual(holding.assetType, .stock)
    }

    func testInit_WithAllParameters() {
        let holding = TestFixtures.holding(
            id: "holding-456",
            portfolioId: "portfolio-456",
            stockSymbol: "MSFT",
            stockName: "Microsoft Corporation",
            quantity: 25,
            averageCostPerShare: 300,
            currentPricePerShare: 350,
            firstPurchaseDate: TestFixtures.pastDate,
            lastPurchaseDate: TestFixtures.referenceDate,
            sector: "Technology",
            industry: "Software",
            assetType: .stock
        )

        XCTAssertEqual(holding.id, "holding-456")
        XCTAssertEqual(holding.portfolioId, "portfolio-456")
        XCTAssertEqual(holding.stockSymbol, "MSFT")
        XCTAssertEqual(holding.stockName, "Microsoft Corporation")
        XCTAssertEqual(holding.quantity, 25)
        XCTAssertEqual(holding.averageCostPerShare, 300)
        XCTAssertEqual(holding.currentPricePerShare, 350)
        XCTAssertNotNil(holding.firstPurchaseDate)
        XCTAssertNotNil(holding.lastPurchaseDate)
        XCTAssertEqual(holding.sector, "Technology")
        XCTAssertEqual(holding.industry, "Software")
        XCTAssertEqual(holding.assetType, .stock)
    }

    // MARK: - Computed Properties Tests

    func testDisplayName_WithStockName() {
        let holding = TestFixtures.holding(
            stockSymbol: "AAPL",
            stockName: "Apple Inc."
        )

        XCTAssertEqual(holding.displayName, "Apple Inc. (AAPL)")
    }

    func testDisplayName_WithoutStockName() {
        let holding = TestFixtures.holding(
            stockSymbol: "AAPL",
            stockName: nil
        )

        XCTAssertEqual(holding.displayName, "AAPL")
    }

    // MARK: - CostBasis Tests

    func testCostBasis() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 150
        )

        XCTAssertEqual(holding.costBasis, 1500) // 10 * 150
    }

    func testCostBasis_ZeroQuantity() {
        let holding = TestFixtures.holding(
            quantity: 0,
            averageCostPerShare: 150
        )

        XCTAssertEqual(holding.costBasis, 0)
    }

    func testCostBasis_ZeroCost() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 0
        )

        XCTAssertEqual(holding.costBasis, 0)
    }

    // MARK: - MarketValue Tests

    func testMarketValue() {
        let holding = TestFixtures.holding(
            quantity: 10,
            currentPricePerShare: 175
        )

        XCTAssertEqual(holding.marketValue, 1750) // 10 * 175
    }

    func testMarketValue_ZeroQuantity() {
        let holding = TestFixtures.holding(
            quantity: 0,
            currentPricePerShare: 175
        )

        XCTAssertEqual(holding.marketValue, 0)
    }

    func testMarketValue_ZeroPrice() {
        let holding = TestFixtures.holding(
            quantity: 10,
            currentPricePerShare: 0
        )

        XCTAssertEqual(holding.marketValue, 0)
    }

    // MARK: - UnrealizedGainLoss Tests

    func testUnrealizedGainLoss_Positive() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 150,
            currentPricePerShare: 175
        )

        // marketValue (1750) - costBasis (1500) = 250
        XCTAssertEqual(holding.unrealizedGainLoss, 250)
    }

    func testUnrealizedGainLoss_Negative() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 175,
            currentPricePerShare: 150
        )

        // marketValue (1500) - costBasis (1750) = -250
        XCTAssertEqual(holding.unrealizedGainLoss, -250)
    }

    func testUnrealizedGainLoss_Zero() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 150,
            currentPricePerShare: 150
        )

        XCTAssertEqual(holding.unrealizedGainLoss, 0)
    }

    // MARK: - UnrealizedGainLossPercentage Tests

    func testUnrealizedGainLossPercentage_Positive() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 100,
            currentPricePerShare: 125
        )

        // ((1250 - 1000) / 1000) * 100 = 25%
        XCTAssertEqual(holding.unrealizedGainLossPercentage, 25)
    }

    func testUnrealizedGainLossPercentage_Negative() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 100,
            currentPricePerShare: 75
        )

        // ((750 - 1000) / 1000) * 100 = -25%
        XCTAssertEqual(holding.unrealizedGainLossPercentage, -25)
    }

    func testUnrealizedGainLossPercentage_ZeroCostBasis_ReturnsZero() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 0,
            currentPricePerShare: 100
        )

        XCTAssertEqual(holding.unrealizedGainLossPercentage, 0)
    }

    func testUnrealizedGainLossPercentage_Doubled() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 100,
            currentPricePerShare: 200
        )

        XCTAssertEqual(holding.unrealizedGainLossPercentage, 100)
    }

    // MARK: - IsProfitable Tests

    func testIsProfitable_PositiveGain_ReturnsTrue() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 150,
            currentPricePerShare: 175
        )

        XCTAssertTrue(holding.isProfitable)
    }

    func testIsProfitable_NegativeGain_ReturnsFalse() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 175,
            currentPricePerShare: 150
        )

        XCTAssertFalse(holding.isProfitable)
    }

    func testIsProfitable_ZeroGain_ReturnsFalse() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 150,
            currentPricePerShare: 150
        )

        XCTAssertFalse(holding.isProfitable)
    }

    // MARK: - TodaysChange Tests

    func testTodaysChange_ReturnsNil() {
        let holding = TestFixtures.holding()

        // Currently returns nil (requires previous close price)
        XCTAssertNil(holding.todaysChange)
        XCTAssertNil(holding.todaysChangePercentage)
    }

    // MARK: - Holding Period Tests

    func testDaysSinceLastPurchase_NoDate_ReturnsNil() {
        let holding = TestFixtures.holding(lastPurchaseDate: nil)

        XCTAssertNil(holding.daysSinceLastPurchase)
    }

    func testDaysSinceLastPurchase_WithDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let holding = TestFixtures.holding(lastPurchaseDate: pastDate)

        XCTAssertNotNil(holding.daysSinceLastPurchase)
        XCTAssertGreaterThanOrEqual(holding.daysSinceLastPurchase ?? 0, 29)
    }

    func testHoldingPeriodDays_NoDate_ReturnsNil() {
        let holding = TestFixtures.holding(firstPurchaseDate: nil)

        XCTAssertNil(holding.holdingPeriodDays)
    }

    func testHoldingPeriodDays_WithDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let holding = TestFixtures.holding(firstPurchaseDate: pastDate)

        XCTAssertNotNil(holding.holdingPeriodDays)
        XCTAssertGreaterThanOrEqual(holding.holdingPeriodDays ?? 0, 99)
    }

    func testIsLongTermHolding_NoDate_ReturnsFalse() {
        let holding = TestFixtures.holding(firstPurchaseDate: nil)

        XCTAssertFalse(holding.isLongTermHolding)
    }

    func testIsLongTermHolding_Under365Days_ReturnsFalse() {
        let recentDate = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let holding = TestFixtures.holding(firstPurchaseDate: recentDate)

        XCTAssertFalse(holding.isLongTermHolding)
    }

    func testIsLongTermHolding_Over365Days_ReturnsTrue() {
        let longAgoDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!
        let holding = TestFixtures.holding(firstPurchaseDate: longAgoDate)

        XCTAssertTrue(holding.isLongTermHolding)
    }

    // MARK: - Methods Tests

    func testAverageCostAfterAdding() {
        let holding = TestFixtures.holding(
            quantity: 10,
            averageCostPerShare: 100 // costBasis = 1000
        )

        // Adding 10 shares at $150 = $1500
        // New total: $1000 + $1500 = $2500
        // New quantity: 20
        // New average: $125
        let newAverage = holding.averageCostAfterAdding(shares: 10, at: 150)

        XCTAssertEqual(newAverage, 125)
    }

    func testAverageCostAfterAdding_ZeroNewQuantity() {
        let holding = TestFixtures.holding(
            quantity: 0,
            averageCostPerShare: 100
        )

        let newAverage = holding.averageCostAfterAdding(shares: 0, at: 150)

        XCTAssertEqual(newAverage, 0)
    }

    func testPortfolioWeight() {
        let holding = TestFixtures.holding(
            quantity: 10,
            currentPricePerShare: 100 // marketValue = 1000
        )

        let weight = holding.portfolioWeight(totalValue: 10000)

        XCTAssertEqual(weight, 10) // 10%
    }

    func testPortfolioWeight_ZeroTotalValue() {
        let holding = TestFixtures.holding()

        let weight = holding.portfolioWeight(totalValue: 0)

        XCTAssertEqual(weight, 0)
    }

    // MARK: - AssetType Tests

    func testAssetType_DisplayName() {
        XCTAssertEqual(AssetType.stock.displayName, "Stock")
        XCTAssertEqual(AssetType.etf.displayName, "ETF")
        XCTAssertEqual(AssetType.mutualFund.displayName, "Mutual Fund")
        XCTAssertEqual(AssetType.bond.displayName, "Bond")
        XCTAssertEqual(AssetType.reit.displayName, "REIT")
        XCTAssertEqual(AssetType.crypto.displayName, "Cryptocurrency")
        XCTAssertEqual(AssetType.commodity.displayName, "Commodity")
        XCTAssertEqual(AssetType.option.displayName, "Option")
        XCTAssertEqual(AssetType.other.displayName, "Other")
    }

    func testAssetType_IconName_NotEmpty() {
        for assetType in AssetType.allCases {
            XCTAssertFalse(assetType.iconName.isEmpty, "Icon name for \(assetType) should not be empty")
        }
    }

    func testAssetType_AllCases() {
        XCTAssertEqual(AssetType.allCases.count, 9)
    }

    // MARK: - HoldingLot Tests

    func testHoldingLot_Initialization() {
        let lot = HoldingLot(
            holdingId: "holding-123",
            quantity: 10,
            costPerShare: 150,
            purchaseDate: TestFixtures.referenceDate
        )

        XCTAssertFalse(lot.id.isEmpty)
        XCTAssertEqual(lot.holdingId, "holding-123")
        XCTAssertEqual(lot.quantity, 10)
        XCTAssertEqual(lot.costPerShare, 150)
        XCTAssertEqual(lot.soldQuantity, 0)
        XCTAssertNil(lot.soldDate)
    }

    func testHoldingLot_RemainingQuantity() {
        let lot = HoldingLot(
            holdingId: "holding-123",
            quantity: 10,
            costPerShare: 150,
            purchaseDate: TestFixtures.referenceDate,
            soldQuantity: 3
        )

        XCTAssertEqual(lot.remainingQuantity, 7)
    }

    func testHoldingLot_IsFullySold_False() {
        let lot = HoldingLot(
            holdingId: "holding-123",
            quantity: 10,
            costPerShare: 150,
            purchaseDate: TestFixtures.referenceDate,
            soldQuantity: 5
        )

        XCTAssertFalse(lot.isFullySold)
    }

    func testHoldingLot_IsFullySold_True() {
        let lot = HoldingLot(
            holdingId: "holding-123",
            quantity: 10,
            costPerShare: 150,
            purchaseDate: TestFixtures.referenceDate,
            soldQuantity: 10
        )

        XCTAssertTrue(lot.isFullySold)
    }

    func testHoldingLot_TotalCost() {
        let lot = HoldingLot(
            holdingId: "holding-123",
            quantity: 10,
            costPerShare: 150,
            purchaseDate: TestFixtures.referenceDate
        )

        XCTAssertEqual(lot.totalCost, 1500)
    }

    func testHoldingLot_RemainingCostBasis() {
        let lot = HoldingLot(
            holdingId: "holding-123",
            quantity: 10,
            costPerShare: 150,
            purchaseDate: TestFixtures.referenceDate,
            soldQuantity: 4
        )

        XCTAssertEqual(lot.remainingCostBasis, 900) // 6 * 150
    }

    func testHoldingLot_IsLongTerm() {
        let longAgoDate = Calendar.current.date(byAdding: .day, value: -400, to: Date())!
        let lot = HoldingLot(
            holdingId: "holding-123",
            quantity: 10,
            costPerShare: 150,
            purchaseDate: longAgoDate
        )

        XCTAssertTrue(lot.isLongTerm)
    }

    func testHoldingLot_IsNotLongTerm() {
        let recentDate = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let lot = HoldingLot(
            holdingId: "holding-123",
            quantity: 10,
            costPerShare: 150,
            purchaseDate: recentDate
        )

        XCTAssertFalse(lot.isLongTerm)
    }

    // MARK: - HoldingsSummary Tests

    func testHoldingsSummary_Initialization() {
        let holdings = TestFixtures.sampleHoldings
        let summary = HoldingsSummary(holdings: holdings)

        XCTAssertEqual(summary.totalHoldings, 3)
        XCTAssertGreaterThan(summary.totalMarketValue, 0)
        XCTAssertGreaterThan(summary.totalCostBasis, 0)
    }

    func testHoldingsSummary_EmptyHoldings() {
        let summary = HoldingsSummary(holdings: [])

        XCTAssertEqual(summary.totalHoldings, 0)
        XCTAssertEqual(summary.totalMarketValue, 0)
        XCTAssertEqual(summary.totalCostBasis, 0)
        XCTAssertEqual(summary.totalUnrealizedGainLoss, 0)
        XCTAssertEqual(summary.profitableHoldings, 0)
        XCTAssertEqual(summary.unprofitableHoldings, 0)
        XCTAssertEqual(summary.overallGainLossPercentage, 0)
        XCTAssertEqual(summary.profitabilityRatio, 0)
    }

    func testHoldingsSummary_OverallGainLossPercentage() {
        let holdings = [
            TestFixtures.holding(quantity: 10, averageCostPerShare: 100, currentPricePerShare: 150),
            TestFixtures.holding(quantity: 10, averageCostPerShare: 100, currentPricePerShare: 150)
        ]
        let summary = HoldingsSummary(holdings: holdings)

        // totalMarketValue = 3000, totalCostBasis = 2000
        // (1000 / 2000) * 100 = 50%
        XCTAssertEqual(summary.overallGainLossPercentage, 50)
    }

    func testHoldingsSummary_ProfitabilityRatio() {
        let holdings = [
            TestFixtures.holding(averageCostPerShare: 100, currentPricePerShare: 150), // Profitable
            TestFixtures.holding(averageCostPerShare: 100, currentPricePerShare: 80),  // Unprofitable
            TestFixtures.holding(averageCostPerShare: 100, currentPricePerShare: 120)  // Profitable
        ]
        let summary = HoldingsSummary(holdings: holdings)

        XCTAssertEqual(summary.profitabilityRatio, 2.0 / 3.0, accuracy: 0.001)
    }

    // MARK: - SectorAllocation Tests

    func testSectorAllocation_Initialization() {
        let holdings = [
            TestFixtures.holding(quantity: 10, currentPricePerShare: 100, sector: "Technology"),
            TestFixtures.holding(quantity: 5, currentPricePerShare: 100, sector: "Technology")
        ]

        let allocation = SectorAllocation(sector: "Technology", holdings: holdings, totalValue: 3000)

        XCTAssertEqual(allocation.id, "Technology")
        XCTAssertEqual(allocation.sector, "Technology")
        XCTAssertEqual(allocation.value, 1500) // 10*100 + 5*100
        XCTAssertEqual(allocation.percentage, 50) // 1500/3000 * 100
        XCTAssertEqual(allocation.holdings.count, 2)
    }

    func testSectorAllocation_ZeroTotalValue() {
        let holdings = [TestFixtures.holding()]
        let allocation = SectorAllocation(sector: "Technology", holdings: holdings, totalValue: 0)

        XCTAssertEqual(allocation.percentage, 0)
    }

    // MARK: - Codable Tests

    func testHolding_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.holding(
            id: "holding-test",
            stockSymbol: "GOOGL",
            stockName: "Alphabet Inc.",
            quantity: 5,
            averageCostPerShare: 140,
            currentPricePerShare: 150,
            sector: "Technology",
            assetType: .stock
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(Holding.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.stockSymbol, original.stockSymbol)
        XCTAssertEqual(decoded.stockName, original.stockName)
        XCTAssertEqual(decoded.quantity, original.quantity)
        XCTAssertEqual(decoded.averageCostPerShare, original.averageCostPerShare)
        XCTAssertEqual(decoded.currentPricePerShare, original.currentPricePerShare)
        XCTAssertEqual(decoded.sector, original.sector)
        XCTAssertEqual(decoded.assetType, original.assetType)
    }

    func testAssetType_Codable() throws {
        for assetType in AssetType.allCases {
            let data = try JSONEncoder().encode(assetType)
            let decoded = try JSONDecoder().decode(AssetType.self, from: data)
            XCTAssertEqual(decoded, assetType)
        }
    }

    // MARK: - Equatable Tests

    func testHolding_Equatable() {
        let holding1 = TestFixtures.holding(id: "holding-1", stockSymbol: "AAPL")
        let holding2 = TestFixtures.holding(id: "holding-1", stockSymbol: "AAPL")
        let holding3 = TestFixtures.holding(id: "holding-2", stockSymbol: "MSFT")

        XCTAssertEqual(holding1, holding2)
        XCTAssertNotEqual(holding1, holding3)
    }

    // MARK: - Hashable Tests

    func testHolding_Hashable() {
        let holding1 = TestFixtures.holding(id: "holding-1")
        let holding2 = TestFixtures.holding(id: "holding-2")

        var set = Set<Holding>()
        set.insert(holding1)
        set.insert(holding2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Edge Cases

    func testHolding_ZeroValues() {
        let holding = TestFixtures.holding(
            quantity: 0,
            averageCostPerShare: 0,
            currentPricePerShare: 0
        )

        XCTAssertEqual(holding.costBasis, 0)
        XCTAssertEqual(holding.marketValue, 0)
        XCTAssertEqual(holding.unrealizedGainLoss, 0)
        XCTAssertEqual(holding.unrealizedGainLossPercentage, 0)
        XCTAssertFalse(holding.isProfitable)
    }

    func testHolding_VeryLargeValues() {
        let holding = TestFixtures.holding(
            quantity: 1_000_000,
            averageCostPerShare: 1000,
            currentPricePerShare: 1500
        )

        XCTAssertEqual(holding.costBasis, 1_000_000_000)
        XCTAssertEqual(holding.marketValue, 1_500_000_000)
        XCTAssertEqual(holding.unrealizedGainLoss, 500_000_000)
    }

    func testHolding_VerySmallValues() {
        let holding = TestFixtures.holding(
            quantity: Decimal(string: "0.000001")!,
            averageCostPerShare: Decimal(string: "0.01")!,
            currentPricePerShare: Decimal(string: "0.02")!
        )

        XCTAssertTrue(holding.isProfitable)
    }

    func testHolding_FractionalShares() {
        let holding = TestFixtures.holding(
            quantity: Decimal(string: "0.123456")!,
            averageCostPerShare: 175,
            currentPricePerShare: 200
        )

        XCTAssertEqual(holding.costBasis, Decimal(string: "0.123456")! * 175)
        XCTAssertEqual(holding.marketValue, Decimal(string: "0.123456")! * 200)
        XCTAssertTrue(holding.isProfitable)
    }
}
