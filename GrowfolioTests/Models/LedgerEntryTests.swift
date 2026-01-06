//
//  LedgerEntryTests.swift
//  GrowfolioTests
//
//  Tests for LedgerEntry domain model.
//

import XCTest
@testable import Growfolio

final class LedgerEntryTests: XCTestCase {

    // MARK: - Net Amount Tests

    func testNetAmount_BuyTransaction() {
        let entry = TestFixtures.ledgerEntry(type: .buy, totalAmount: 1500, fees: 10)
        XCTAssertEqual(entry.netAmount, -1510) // -(1500 + 10)
    }

    func testNetAmount_SellTransaction() {
        let entry = TestFixtures.ledgerEntry(type: .sell, totalAmount: 1500, fees: 10)
        XCTAssertEqual(entry.netAmount, 1490) // 1500 - 10
    }

    func testNetAmount_DepositTransaction() {
        let entry = TestFixtures.ledgerEntry(type: .deposit, totalAmount: 5000, fees: 0)
        XCTAssertEqual(entry.netAmount, 5000)
    }

    func testNetAmount_WithdrawalTransaction() {
        let entry = TestFixtures.ledgerEntry(type: .withdrawal, totalAmount: 2000, fees: 25)
        XCTAssertEqual(entry.netAmount, -2025) // -(2000 + 25)
    }

    func testNetAmount_DividendTransaction() {
        let entry = TestFixtures.ledgerEntry(type: .dividend, totalAmount: 50, fees: 0)
        XCTAssertEqual(entry.netAmount, 50)
    }

    func testNetAmount_InterestTransaction() {
        let entry = TestFixtures.ledgerEntry(type: .interest, totalAmount: 10, fees: 0)
        XCTAssertEqual(entry.netAmount, 10)
    }

    func testNetAmount_FeeTransaction() {
        let entry = TestFixtures.ledgerEntry(type: .fee, totalAmount: 15, fees: 0)
        XCTAssertEqual(entry.netAmount, -15)
    }

    func testNetAmount_TransferTransaction_Positive() {
        let entry = TestFixtures.ledgerEntry(type: .transfer, totalAmount: 1000, fees: 0)
        XCTAssertEqual(entry.netAmount, 1000)
    }

    func testNetAmount_TransferTransaction_Negative() {
        var entry = TestFixtures.ledgerEntry(type: .transfer, totalAmount: -1000, fees: 0)
        entry.totalAmount = -1000
        XCTAssertEqual(entry.netAmount, -1000)
    }

    func testNetAmount_AdjustmentTransaction() {
        let entry = TestFixtures.ledgerEntry(type: .adjustment, totalAmount: 500, fees: 0)
        XCTAssertEqual(entry.netAmount, 500)
    }

    // MARK: - Calculated Total Tests

    func testCalculatedTotal_WithQuantityAndPrice() {
        let entry = TestFixtures.ledgerEntry(
            type: .buy,
            quantity: 10,
            pricePerShare: 150,
            totalAmount: 1500
        )
        XCTAssertEqual(entry.calculatedTotal, 1500)
    }

    func testCalculatedTotal_FractionalShares() {
        let entry = TestFixtures.ledgerEntry(
            type: .buy,
            quantity: Decimal(string: "2.5")!,
            pricePerShare: 200,
            totalAmount: 500
        )
        XCTAssertEqual(entry.calculatedTotal, 500)
    }

    func testCalculatedTotal_NilQuantity() {
        let entry = TestFixtures.ledgerEntry(
            type: .deposit,
            quantity: nil,
            pricePerShare: nil,
            totalAmount: 5000
        )
        XCTAssertNil(entry.calculatedTotal)
    }

    func testCalculatedTotal_NilPrice() {
        let entry = TestFixtures.ledgerEntry(
            type: .buy,
            quantity: 10,
            pricePerShare: nil,
            totalAmount: 1500
        )
        XCTAssertNil(entry.calculatedTotal)
    }

    // MARK: - Display Description Tests

    func testDisplayDescription_Buy_WithSymbol() {
        let entry = TestFixtures.ledgerEntry(
            type: .buy,
            stockSymbol: "AAPL",
            quantity: 10
        )
        XCTAssertTrue(entry.displayDescription.contains("Buy"))
        XCTAssertTrue(entry.displayDescription.contains("AAPL"))
    }

    func testDisplayDescription_Sell_WithSymbol() {
        let entry = TestFixtures.ledgerEntry(
            type: .sell,
            stockSymbol: "MSFT",
            quantity: 5
        )
        XCTAssertTrue(entry.displayDescription.contains("Sell"))
        XCTAssertTrue(entry.displayDescription.contains("MSFT"))
    }

    func testDisplayDescription_Deposit() {
        let entry = TestFixtures.ledgerEntry(type: .deposit)
        XCTAssertEqual(entry.displayDescription, "Deposit")
    }

    func testDisplayDescription_Withdrawal() {
        let entry = TestFixtures.ledgerEntry(type: .withdrawal)
        XCTAssertEqual(entry.displayDescription, "Withdrawal")
    }

    func testDisplayDescription_Dividend_WithSymbol() {
        let entry = TestFixtures.ledgerEntry(
            type: .dividend,
            stockSymbol: "AAPL"
        )
        XCTAssertTrue(entry.displayDescription.contains("Dividend"))
        XCTAssertTrue(entry.displayDescription.contains("AAPL"))
    }

    func testDisplayDescription_Dividend_NoSymbol() {
        let entry = TestFixtures.ledgerEntry(
            type: .dividend,
            stockSymbol: nil
        )
        XCTAssertEqual(entry.displayDescription, "Dividend")
    }

    // MARK: - Is Stock Transaction Tests

    func testIsStockTransaction_Buy_ReturnsTrue() {
        let entry = TestFixtures.ledgerEntry(type: .buy)
        XCTAssertTrue(entry.isStockTransaction)
    }

    func testIsStockTransaction_Sell_ReturnsTrue() {
        let entry = TestFixtures.ledgerEntry(type: .sell)
        XCTAssertTrue(entry.isStockTransaction)
    }

    func testIsStockTransaction_Deposit_ReturnsFalse() {
        let entry = TestFixtures.ledgerEntry(type: .deposit)
        XCTAssertFalse(entry.isStockTransaction)
    }

    func testIsStockTransaction_Dividend_ReturnsFalse() {
        let entry = TestFixtures.ledgerEntry(type: .dividend)
        XCTAssertFalse(entry.isStockTransaction)
    }

    // MARK: - Affects Cash Tests

    func testAffectsCash_Adjustment_ReturnsFalse() {
        let entry = TestFixtures.ledgerEntry(type: .adjustment)
        XCTAssertFalse(entry.affectsCash)
    }

    func testAffectsCash_Buy_ReturnsTrue() {
        let entry = TestFixtures.ledgerEntry(type: .buy)
        XCTAssertTrue(entry.affectsCash)
    }

    func testAffectsCash_Deposit_ReturnsTrue() {
        let entry = TestFixtures.ledgerEntry(type: .deposit)
        XCTAssertTrue(entry.affectsCash)
    }

    // MARK: - Sign Prefix Tests

    func testSignPrefix_Sell() {
        let entry = TestFixtures.ledgerEntry(type: .sell)
        XCTAssertEqual(entry.signPrefix, "+")
    }

    func testSignPrefix_Deposit() {
        let entry = TestFixtures.ledgerEntry(type: .deposit)
        XCTAssertEqual(entry.signPrefix, "+")
    }

    func testSignPrefix_Dividend() {
        let entry = TestFixtures.ledgerEntry(type: .dividend)
        XCTAssertEqual(entry.signPrefix, "+")
    }

    func testSignPrefix_Interest() {
        let entry = TestFixtures.ledgerEntry(type: .interest)
        XCTAssertEqual(entry.signPrefix, "+")
    }

    func testSignPrefix_Buy() {
        let entry = TestFixtures.ledgerEntry(type: .buy)
        XCTAssertEqual(entry.signPrefix, "-")
    }

    func testSignPrefix_Withdrawal() {
        let entry = TestFixtures.ledgerEntry(type: .withdrawal)
        XCTAssertEqual(entry.signPrefix, "-")
    }

    func testSignPrefix_Fee() {
        let entry = TestFixtures.ledgerEntry(type: .fee)
        XCTAssertEqual(entry.signPrefix, "-")
    }

    func testSignPrefix_Transfer_Positive() {
        let entry = TestFixtures.ledgerEntry(type: .transfer, totalAmount: 1000)
        XCTAssertEqual(entry.signPrefix, "+")
    }

    func testSignPrefix_Transfer_Negative() {
        var entry = TestFixtures.ledgerEntry(type: .transfer, totalAmount: -1000)
        entry.totalAmount = -1000
        XCTAssertEqual(entry.signPrefix, "")
    }

    // MARK: - LedgerEntryType Tests

    func testLedgerEntryType_DisplayName() {
        XCTAssertEqual(LedgerEntryType.buy.displayName, "Buy")
        XCTAssertEqual(LedgerEntryType.sell.displayName, "Sell")
        XCTAssertEqual(LedgerEntryType.deposit.displayName, "Deposit")
        XCTAssertEqual(LedgerEntryType.withdrawal.displayName, "Withdrawal")
        XCTAssertEqual(LedgerEntryType.dividend.displayName, "Dividend")
        XCTAssertEqual(LedgerEntryType.interest.displayName, "Interest")
        XCTAssertEqual(LedgerEntryType.fee.displayName, "Fee")
        XCTAssertEqual(LedgerEntryType.transfer.displayName, "Transfer")
        XCTAssertEqual(LedgerEntryType.adjustment.displayName, "Adjustment")
    }

    func testLedgerEntryType_IconName() {
        for type in LedgerEntryType.allCases {
            XCTAssertFalse(type.iconName.isEmpty)
        }
    }

    func testLedgerEntryType_ColorHex() {
        for type in LedgerEntryType.allCases {
            XCTAssertTrue(type.colorHex.hasPrefix("#"))
        }
    }

    func testLedgerEntryType_RequiresStock() {
        XCTAssertTrue(LedgerEntryType.buy.requiresStock)
        XCTAssertTrue(LedgerEntryType.sell.requiresStock)
        XCTAssertFalse(LedgerEntryType.dividend.requiresStock)
        XCTAssertFalse(LedgerEntryType.deposit.requiresStock)
    }

    func testLedgerEntryType_RequiresQuantity() {
        XCTAssertTrue(LedgerEntryType.buy.requiresQuantity)
        XCTAssertTrue(LedgerEntryType.sell.requiresQuantity)
        XCTAssertFalse(LedgerEntryType.deposit.requiresQuantity)
        XCTAssertFalse(LedgerEntryType.dividend.requiresQuantity)
    }

    func testLedgerEntryType_AllCases() {
        XCTAssertEqual(LedgerEntryType.allCases.count, 9)
    }

    // MARK: - LedgerEntrySource Tests

    func testLedgerEntrySource_DisplayName() {
        XCTAssertEqual(LedgerEntrySource.manual.displayName, "Manual Entry")
        XCTAssertEqual(LedgerEntrySource.dca.displayName, "DCA Schedule")
        XCTAssertEqual(LedgerEntrySource.import.displayName, "Imported")
        XCTAssertEqual(LedgerEntrySource.sync.displayName, "Synced")
        XCTAssertEqual(LedgerEntrySource.system.displayName, "System")
    }

    // MARK: - LedgerSummary Tests

    func testLedgerSummary_TotalTransactions() {
        let entries = TestFixtures.sampleLedgerEntries
        let summary = LedgerSummary(entries: entries)
        XCTAssertEqual(summary.totalTransactions, 4)
    }

    func testLedgerSummary_TotalBuys() {
        let entries = [
            TestFixtures.ledgerEntry(id: "e1", type: .buy),
            TestFixtures.ledgerEntry(id: "e2", type: .buy),
            TestFixtures.ledgerEntry(id: "e3", type: .sell)
        ]
        let summary = LedgerSummary(entries: entries)
        XCTAssertEqual(summary.totalBuys, 2)
    }

    func testLedgerSummary_TotalSells() {
        let entries = [
            TestFixtures.ledgerEntry(id: "e1", type: .sell),
            TestFixtures.ledgerEntry(id: "e2", type: .buy),
            TestFixtures.ledgerEntry(id: "e3", type: .sell)
        ]
        let summary = LedgerSummary(entries: entries)
        XCTAssertEqual(summary.totalSells, 2)
    }

    func testLedgerSummary_TotalDeposits() {
        let entries = [
            TestFixtures.ledgerEntry(id: "e1", type: .deposit, totalAmount: 1000),
            TestFixtures.ledgerEntry(id: "e2", type: .deposit, totalAmount: 2000),
            TestFixtures.ledgerEntry(id: "e3", type: .withdrawal, totalAmount: 500)
        ]
        let summary = LedgerSummary(entries: entries)
        XCTAssertEqual(summary.totalDeposits, 3000)
    }

    func testLedgerSummary_TotalWithdrawals() {
        let entries = [
            TestFixtures.ledgerEntry(id: "e1", type: .withdrawal, totalAmount: 500),
            TestFixtures.ledgerEntry(id: "e2", type: .withdrawal, totalAmount: 300),
            TestFixtures.ledgerEntry(id: "e3", type: .deposit, totalAmount: 1000)
        ]
        let summary = LedgerSummary(entries: entries)
        XCTAssertEqual(summary.totalWithdrawals, 800)
    }

    func testLedgerSummary_TotalDividends() {
        let entries = [
            TestFixtures.ledgerEntry(id: "e1", type: .dividend, totalAmount: 50),
            TestFixtures.ledgerEntry(id: "e2", type: .dividend, totalAmount: 75)
        ]
        let summary = LedgerSummary(entries: entries)
        XCTAssertEqual(summary.totalDividends, 125)
    }

    func testLedgerSummary_TotalFees() {
        let entries = [
            TestFixtures.ledgerEntry(id: "e1", type: .fee, totalAmount: 10),
            TestFixtures.ledgerEntry(id: "e2", type: .fee, totalAmount: 15)
        ]
        let summary = LedgerSummary(entries: entries)
        XCTAssertEqual(summary.totalFees, 25)
    }

    func testLedgerSummary_EmptyEntries() {
        let summary = LedgerSummary(entries: [])
        XCTAssertEqual(summary.totalTransactions, 0)
        XCTAssertEqual(summary.totalBuys, 0)
        XCTAssertEqual(summary.totalSells, 0)
        XCTAssertEqual(summary.netCashFlow, 0)
    }

    // MARK: - Codable Tests

    func testLedgerEntry_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.ledgerEntry(
            type: .buy,
            stockSymbol: "MSFT",
            stockName: "Microsoft",
            quantity: 15,
            pricePerShare: 350,
            totalAmount: 5250,
            fees: 5,
            source: .dca
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(LedgerEntry.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.stockSymbol, original.stockSymbol)
        XCTAssertEqual(decoded.quantity, original.quantity)
        XCTAssertEqual(decoded.totalAmount, original.totalAmount)
        XCTAssertEqual(decoded.fees, original.fees)
        XCTAssertEqual(decoded.source, original.source)
    }

    func testLedgerEntryType_Codable() throws {
        for type in LedgerEntryType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(LedgerEntryType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    // MARK: - Equatable Tests

    func testLedgerEntry_Equatable() {
        let entry1 = TestFixtures.ledgerEntry(id: "e1")
        let entry2 = TestFixtures.ledgerEntry(id: "e1")
        let entry3 = TestFixtures.ledgerEntry(id: "e2")

        XCTAssertEqual(entry1, entry2)
        XCTAssertNotEqual(entry1, entry3)
    }

    // MARK: - Hashable Tests

    func testLedgerEntry_Hashable() {
        let entry1 = TestFixtures.ledgerEntry(id: "e1")
        let entry2 = TestFixtures.ledgerEntry(id: "e2")

        var set = Set<LedgerEntry>()
        set.insert(entry1)
        set.insert(entry2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Edge Cases

    func testLedgerEntry_ZeroAmount() {
        let entry = TestFixtures.ledgerEntry(type: .adjustment, totalAmount: 0, fees: 0)
        XCTAssertEqual(entry.netAmount, 0)
    }

    func testLedgerEntry_VeryLargeValues() {
        let entry = TestFixtures.ledgerEntry(
            type: .buy,
            quantity: 100_000,
            pricePerShare: 1000,
            totalAmount: 100_000_000,
            fees: 1000
        )
        XCTAssertEqual(entry.calculatedTotal, 100_000_000)
        XCTAssertEqual(entry.netAmount, -100_001_000)
    }

    func testLedgerEntry_FractionalShares() {
        let entry = TestFixtures.ledgerEntry(
            type: .buy,
            quantity: Decimal(string: "0.12345")!,
            pricePerShare: 175,
            totalAmount: Decimal(string: "21.60375")!
        )
        XCTAssertNotNil(entry.calculatedTotal)
    }
}
