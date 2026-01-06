//
//  FundingBalanceTests.swift
//  GrowfolioTests
//
//  Tests for FundingBalance domain model.
//

import XCTest
@testable import Growfolio

final class FundingBalanceTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithDefaults() {
        let balance = FundingBalance(
            userId: "user-123",
            portfolioId: "portfolio-123"
        )

        XCTAssertFalse(balance.id.isEmpty)
        XCTAssertEqual(balance.userId, "user-123")
        XCTAssertEqual(balance.portfolioId, "portfolio-123")
        XCTAssertEqual(balance.availableUSD, 0)
        XCTAssertEqual(balance.availableGBP, 0)
        XCTAssertEqual(balance.pendingDepositsUSD, 0)
        XCTAssertEqual(balance.pendingDepositsGBP, 0)
        XCTAssertEqual(balance.pendingWithdrawalsUSD, 0)
        XCTAssertEqual(balance.pendingWithdrawalsGBP, 0)
    }

    func testInit_WithAllParameters() {
        let balance = TestFixtures.fundingBalance(
            id: "balance-456",
            userId: "user-456",
            portfolioId: "portfolio-456",
            availableUSD: 5000,
            availableGBP: 4000,
            pendingDepositsUSD: 1000,
            pendingDepositsGBP: 500,
            pendingWithdrawalsUSD: 200,
            pendingWithdrawalsGBP: 100
        )

        XCTAssertEqual(balance.id, "balance-456")
        XCTAssertEqual(balance.userId, "user-456")
        XCTAssertEqual(balance.portfolioId, "portfolio-456")
        XCTAssertEqual(balance.availableUSD, 5000)
        XCTAssertEqual(balance.availableGBP, 4000)
        XCTAssertEqual(balance.pendingDepositsUSD, 1000)
        XCTAssertEqual(balance.pendingDepositsGBP, 500)
        XCTAssertEqual(balance.pendingWithdrawalsUSD, 200)
        XCTAssertEqual(balance.pendingWithdrawalsGBP, 100)
    }

    // MARK: - TotalAvailableUSD Tests

    func testTotalAvailableUSD_WithFxRate() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: 5000,
            availableGBP: 4000
        )

        // 5000 + (4000 * 1.25) = 5000 + 5000 = 10000
        XCTAssertEqual(balance.totalAvailableUSD(fxRate: 1.25), 10000)
    }

    func testTotalAvailableUSD_ZeroGBP() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: 5000,
            availableGBP: 0
        )

        XCTAssertEqual(balance.totalAvailableUSD(fxRate: 1.25), 5000)
    }

    func testTotalAvailableUSD_ZeroUSD() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: 0,
            availableGBP: 4000
        )

        XCTAssertEqual(balance.totalAvailableUSD(fxRate: 1.25), 5000)
    }

    func testTotalAvailableUSD_ZeroFxRate() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: 5000,
            availableGBP: 4000
        )

        XCTAssertEqual(balance.totalAvailableUSD(fxRate: 0), 5000)
    }

    // MARK: - TotalPendingUSD Tests

    func testTotalPendingUSD_DepositsMinusWithdrawals() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsUSD: 1000,
            pendingWithdrawalsUSD: 300
        )

        XCTAssertEqual(balance.totalPendingUSD, 700)
    }

    func testTotalPendingUSD_OnlyDeposits() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsUSD: 1000,
            pendingWithdrawalsUSD: 0
        )

        XCTAssertEqual(balance.totalPendingUSD, 1000)
    }

    func testTotalPendingUSD_OnlyWithdrawals() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsUSD: 0,
            pendingWithdrawalsUSD: 500
        )

        XCTAssertEqual(balance.totalPendingUSD, -500)
    }

    func testTotalPendingUSD_Zero() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsUSD: 0,
            pendingWithdrawalsUSD: 0
        )

        XCTAssertEqual(balance.totalPendingUSD, 0)
    }

    // MARK: - TotalPendingGBP Tests

    func testTotalPendingGBP_DepositsMinusWithdrawals() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsGBP: 500,
            pendingWithdrawalsGBP: 100
        )

        XCTAssertEqual(balance.totalPendingGBP, 400)
    }

    func testTotalPendingGBP_OnlyDeposits() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsGBP: 500,
            pendingWithdrawalsGBP: 0
        )

        XCTAssertEqual(balance.totalPendingGBP, 500)
    }

    func testTotalPendingGBP_OnlyWithdrawals() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsGBP: 0,
            pendingWithdrawalsGBP: 200
        )

        XCTAssertEqual(balance.totalPendingGBP, -200)
    }

    // MARK: - HasPendingTransactions Tests

    func testHasPendingTransactions_WithPendingDepositsUSD_ReturnsTrue() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsUSD: 100,
            pendingDepositsGBP: 0,
            pendingWithdrawalsUSD: 0,
            pendingWithdrawalsGBP: 0
        )

        XCTAssertTrue(balance.hasPendingTransactions)
    }

    func testHasPendingTransactions_WithPendingDepositsGBP_ReturnsTrue() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsUSD: 0,
            pendingDepositsGBP: 100,
            pendingWithdrawalsUSD: 0,
            pendingWithdrawalsGBP: 0
        )

        XCTAssertTrue(balance.hasPendingTransactions)
    }

    func testHasPendingTransactions_WithPendingWithdrawalsUSD_ReturnsTrue() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsUSD: 0,
            pendingDepositsGBP: 0,
            pendingWithdrawalsUSD: 100,
            pendingWithdrawalsGBP: 0
        )

        XCTAssertTrue(balance.hasPendingTransactions)
    }

    func testHasPendingTransactions_WithPendingWithdrawalsGBP_ReturnsTrue() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsUSD: 0,
            pendingDepositsGBP: 0,
            pendingWithdrawalsUSD: 0,
            pendingWithdrawalsGBP: 100
        )

        XCTAssertTrue(balance.hasPendingTransactions)
    }

    func testHasPendingTransactions_NoPending_ReturnsFalse() {
        let balance = TestFixtures.fundingBalance(
            pendingDepositsUSD: 0,
            pendingDepositsGBP: 0,
            pendingWithdrawalsUSD: 0,
            pendingWithdrawalsGBP: 0
        )

        XCTAssertFalse(balance.hasPendingTransactions)
    }

    // MARK: - HasAvailableBalance Tests

    func testHasAvailableBalance_WithUSD_ReturnsTrue() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: 100,
            availableGBP: 0
        )

        XCTAssertTrue(balance.hasAvailableBalance)
    }

    func testHasAvailableBalance_WithGBP_ReturnsTrue() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: 0,
            availableGBP: 100
        )

        XCTAssertTrue(balance.hasAvailableBalance)
    }

    func testHasAvailableBalance_WithBoth_ReturnsTrue() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: 100,
            availableGBP: 100
        )

        XCTAssertTrue(balance.hasAvailableBalance)
    }

    func testHasAvailableBalance_NoBalance_ReturnsFalse() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: 0,
            availableGBP: 0
        )

        XCTAssertFalse(balance.hasAvailableBalance)
    }

    // MARK: - FXRate Tests

    func testFXRate_Initialization() {
        let rate = TestFixtures.fxRate(
            fromCurrency: "GBP",
            toCurrency: "USD",
            rate: 1.25,
            spread: 0.01
        )

        XCTAssertEqual(rate.fromCurrency, "GBP")
        XCTAssertEqual(rate.toCurrency, "USD")
        XCTAssertEqual(rate.rate, 1.25)
        XCTAssertEqual(rate.spread, 0.01)
    }

    func testFXRate_EffectiveRate() {
        let rate = TestFixtures.fxRate(
            rate: 1.25,
            spread: 0.01
        )

        // 1.25 * (1 - 0.01) = 1.25 * 0.99 = 1.2375
        XCTAssertEqual(rate.effectiveRate, 1.2375)
    }

    func testFXRate_EffectiveRate_ZeroSpread() {
        let rate = TestFixtures.fxRate(
            rate: 1.25,
            spread: 0
        )

        XCTAssertEqual(rate.effectiveRate, 1.25)
    }

    func testFXRate_InverseRate() {
        let rate = TestFixtures.fxRate(rate: 1.25)

        // 1 / 1.25 = 0.8
        XCTAssertEqual(rate.inverseRate, 0.8)
    }

    func testFXRate_InverseRate_ZeroRate() {
        let rate = TestFixtures.fxRate(rate: 0)

        XCTAssertEqual(rate.inverseRate, 0)
    }

    func testFXRate_IsValid_NotExpired() {
        let futureExpiry = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let rate = FXRate(
            rate: 1.25,
            expiresAt: futureExpiry
        )

        XCTAssertTrue(rate.isValid)
    }

    func testFXRate_IsValid_Expired() {
        let pastExpiry = Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
        let rate = FXRate(
            rate: 1.25,
            expiresAt: pastExpiry
        )

        XCTAssertFalse(rate.isValid)
    }

    func testFXRate_Convert() {
        let rate = TestFixtures.fxRate(
            rate: 1.25,
            spread: 0
        )

        XCTAssertEqual(rate.convert(100), 125)
    }

    func testFXRate_Convert_WithSpread() {
        let rate = TestFixtures.fxRate(
            rate: 1.25,
            spread: 0.01
        )

        // 100 * 1.2375 = 123.75
        XCTAssertEqual(rate.convert(100), 123.75)
    }

    func testFXRate_ConvertBack() {
        let rate = TestFixtures.fxRate(
            rate: 1.25,
            spread: 0
        )

        XCTAssertEqual(rate.convertBack(125), 100)
    }

    func testFXRate_ConvertBack_ZeroEffectiveRate() {
        let rate = TestFixtures.fxRate(rate: 0)

        XCTAssertEqual(rate.convertBack(125), 0)
    }

    func testFXRate_DisplayString() {
        let rate = TestFixtures.fxRate(
            fromCurrency: "GBP",
            toCurrency: "USD",
            rate: 1.2567
        )

        XCTAssertTrue(rate.displayString.contains("GBP"))
        XCTAssertTrue(rate.displayString.contains("USD"))
        XCTAssertTrue(rate.displayString.contains("1.2567"))
    }

    func testFXRate_EffectiveDisplayString() {
        let rate = TestFixtures.fxRate(
            fromCurrency: "GBP",
            toCurrency: "USD",
            rate: 1.25,
            spread: 0
        )

        XCTAssertTrue(rate.effectiveDisplayString.contains("GBP"))
        XCTAssertTrue(rate.effectiveDisplayString.contains("USD"))
    }

    // MARK: - Codable Tests

    func testFundingBalance_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.fundingBalance(
            id: "balance-test",
            userId: "user-test",
            portfolioId: "portfolio-test",
            availableUSD: 5000,
            availableGBP: 4000,
            pendingDepositsUSD: 1000,
            pendingDepositsGBP: 500,
            pendingWithdrawalsUSD: 200,
            pendingWithdrawalsGBP: 100
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(FundingBalance.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.userId, original.userId)
        XCTAssertEqual(decoded.portfolioId, original.portfolioId)
        XCTAssertEqual(decoded.availableUSD, original.availableUSD)
        XCTAssertEqual(decoded.availableGBP, original.availableGBP)
        XCTAssertEqual(decoded.pendingDepositsUSD, original.pendingDepositsUSD)
        XCTAssertEqual(decoded.pendingDepositsGBP, original.pendingDepositsGBP)
        XCTAssertEqual(decoded.pendingWithdrawalsUSD, original.pendingWithdrawalsUSD)
        XCTAssertEqual(decoded.pendingWithdrawalsGBP, original.pendingWithdrawalsGBP)
    }

    func testFXRate_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.fxRate(
            fromCurrency: "GBP",
            toCurrency: "USD",
            rate: 1.25,
            spread: 0.01
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(FXRate.self, from: data)

        XCTAssertEqual(decoded.fromCurrency, original.fromCurrency)
        XCTAssertEqual(decoded.toCurrency, original.toCurrency)
        XCTAssertEqual(decoded.rate, original.rate)
        XCTAssertEqual(decoded.spread, original.spread)
    }

    // MARK: - Equatable Tests

    func testFundingBalance_Equatable() {
        let balance1 = TestFixtures.fundingBalance(id: "balance-1", availableUSD: 1000)
        let balance2 = TestFixtures.fundingBalance(id: "balance-1", availableUSD: 1000)
        let balance3 = TestFixtures.fundingBalance(id: "balance-2", availableUSD: 2000)

        XCTAssertEqual(balance1, balance2)
        XCTAssertNotEqual(balance1, balance3)
    }

    func testFXRate_Equatable() {
        let rate1 = TestFixtures.fxRate(rate: 1.25)
        let rate2 = TestFixtures.fxRate(rate: 1.25)
        let rate3 = TestFixtures.fxRate(rate: 1.30)

        XCTAssertEqual(rate1, rate2)
        XCTAssertNotEqual(rate1, rate3)
    }

    // MARK: - Edge Cases

    func testFundingBalance_ZeroValues() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: 0,
            availableGBP: 0,
            pendingDepositsUSD: 0,
            pendingDepositsGBP: 0,
            pendingWithdrawalsUSD: 0,
            pendingWithdrawalsGBP: 0
        )

        XCTAssertEqual(balance.totalAvailableUSD(fxRate: 1.25), 0)
        XCTAssertEqual(balance.totalPendingUSD, 0)
        XCTAssertEqual(balance.totalPendingGBP, 0)
        XCTAssertFalse(balance.hasPendingTransactions)
        XCTAssertFalse(balance.hasAvailableBalance)
    }

    func testFundingBalance_VeryLargeValues() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: 999_999_999,
            availableGBP: 800_000_000
        )

        let total = balance.totalAvailableUSD(fxRate: 1.25)
        XCTAssertEqual(total, 999_999_999 + 800_000_000 * Decimal(1.25))
    }

    func testFundingBalance_VerySmallValues() {
        let balance = TestFixtures.fundingBalance(
            availableUSD: Decimal(string: "0.01")!,
            availableGBP: Decimal(string: "0.01")!
        )

        XCTAssertTrue(balance.hasAvailableBalance)
        XCTAssertEqual(balance.totalAvailableUSD(fxRate: 1.25), Decimal(string: "0.0225")!)
    }

    func testFXRate_VerySmallRate() {
        // Use spread: 0 to test raw rate conversion without spread deduction
        let rate = TestFixtures.fxRate(rate: Decimal(string: "0.0001")!, spread: 0)

        XCTAssertEqual(rate.convert(1000), Decimal(string: "0.1")!)
    }

    func testFXRate_VeryLargeRate() {
        // Use spread: 0 to test raw rate conversion without spread deduction
        let rate = TestFixtures.fxRate(rate: 1000, spread: 0)

        XCTAssertEqual(rate.convert(1), 1000)
    }

    func testFXRate_HighPrecisionRate() {
        let rate = TestFixtures.fxRate(rate: Decimal(string: "1.2567890123")!)

        XCTAssertNotNil(rate.rate)
    }

    // MARK: - Mutable Properties Tests

    func testFundingBalance_MutableProperties() {
        var balance = TestFixtures.fundingBalance(
            availableUSD: 1000,
            pendingDepositsUSD: 0
        )

        balance.availableUSD = 2000
        balance.pendingDepositsUSD = 500

        XCTAssertEqual(balance.availableUSD, 2000)
        XCTAssertEqual(balance.pendingDepositsUSD, 500)
    }
}
