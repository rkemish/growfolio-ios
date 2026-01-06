//
//  TransferTests.swift
//  GrowfolioTests
//
//  Tests for Transfer domain model.
//

import XCTest
@testable import Growfolio

final class TransferTests: XCTestCase {

    // MARK: - Net Amount Tests

    func testNetAmount_NoFees() {
        let transfer = TestFixtures.transfer(amount: 1000, fees: 0)
        XCTAssertEqual(transfer.netAmount, 1000)
    }

    func testNetAmount_WithFees() {
        let transfer = TestFixtures.transfer(amount: 1000, fees: 25)
        XCTAssertEqual(transfer.netAmount, 975)
    }

    func testNetAmount_LargeFees() {
        let transfer = TestFixtures.transfer(amount: 1000, fees: 100)
        XCTAssertEqual(transfer.netAmount, 900)
    }

    // MARK: - Net Amount USD Tests

    func testNetAmountUSD_WithFxConversion() {
        let transfer = TestFixtures.transfer(
            amount: 1000,
            amountUSD: 1250,
            fxRate: 1.25,
            fees: 10
        )
        XCTAssertEqual(transfer.netAmountUSD, 1240) // 1250 - 10
    }

    func testNetAmountUSD_NilAmountUSD() {
        let transfer = TestFixtures.transfer(amountUSD: nil)
        XCTAssertNil(transfer.netAmountUSD)
    }

    // MARK: - Display Description Tests

    func testDisplayDescription_Deposit() {
        let transfer = TestFixtures.transfer(type: .deposit)
        XCTAssertEqual(transfer.displayDescription, "Deposit")
    }

    func testDisplayDescription_Withdrawal() {
        let transfer = TestFixtures.transfer(type: .withdrawal)
        XCTAssertEqual(transfer.displayDescription, "Withdrawal")
    }

    // MARK: - Amount Display String Tests

    func testAmountDisplayString_Deposit_HasPlusSign() {
        let transfer = TestFixtures.transfer(type: .deposit, amount: 1000, currency: "GBP")
        XCTAssertTrue(transfer.amountDisplayString.hasPrefix("+"))
    }

    func testAmountDisplayString_Withdrawal_HasMinusSign() {
        let transfer = TestFixtures.transfer(type: .withdrawal, amount: 500, currency: "GBP")
        XCTAssertTrue(transfer.amountDisplayString.hasPrefix("-"))
    }

    // MARK: - Has FX Conversion Tests

    func testHasFXConversion_WithRate_NonUSD() {
        let transfer = TestFixtures.transfer(currency: "GBP", fxRate: 1.25)
        XCTAssertTrue(transfer.hasFXConversion)
    }

    func testHasFXConversion_NoRate() {
        let transfer = TestFixtures.transfer(currency: "GBP", fxRate: nil)
        XCTAssertFalse(transfer.hasFXConversion)
    }

    func testHasFXConversion_USDCurrency() {
        let transfer = TestFixtures.transfer(currency: "USD", fxRate: 1.0)
        XCTAssertFalse(transfer.hasFXConversion)
    }

    // MARK: - Is Terminal Tests

    func testIsTerminal_Completed_ReturnsTrue() {
        let transfer = TestFixtures.transfer(status: .completed)
        XCTAssertTrue(transfer.isTerminal)
    }

    func testIsTerminal_Failed_ReturnsTrue() {
        let transfer = TestFixtures.transfer(status: .failed)
        XCTAssertTrue(transfer.isTerminal)
    }

    func testIsTerminal_Cancelled_ReturnsTrue() {
        let transfer = TestFixtures.transfer(status: .cancelled)
        XCTAssertTrue(transfer.isTerminal)
    }

    func testIsTerminal_Pending_ReturnsFalse() {
        let transfer = TestFixtures.transfer(status: .pending)
        XCTAssertFalse(transfer.isTerminal)
    }

    func testIsTerminal_Processing_ReturnsFalse() {
        let transfer = TestFixtures.transfer(status: .processing)
        XCTAssertFalse(transfer.isTerminal)
    }

    // MARK: - Can Cancel Tests

    func testCanCancel_Pending_ReturnsTrue() {
        let transfer = TestFixtures.transfer(status: .pending)
        XCTAssertTrue(transfer.canCancel)
    }

    func testCanCancel_Processing_ReturnsTrue() {
        let transfer = TestFixtures.transfer(status: .processing)
        XCTAssertTrue(transfer.canCancel)
    }

    func testCanCancel_Completed_ReturnsFalse() {
        let transfer = TestFixtures.transfer(status: .completed)
        XCTAssertFalse(transfer.canCancel)
    }

    func testCanCancel_Failed_ReturnsFalse() {
        let transfer = TestFixtures.transfer(status: .failed)
        XCTAssertFalse(transfer.canCancel)
    }

    func testCanCancel_Cancelled_ReturnsFalse() {
        let transfer = TestFixtures.transfer(status: .cancelled)
        XCTAssertFalse(transfer.canCancel)
    }

    // MARK: - Time Until Completion Tests

    func testTimeUntilCompletion_HasExpectedDate() {
        let futureDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
        let transfer = TestFixtures.transfer(expectedCompletionDate: futureDate)
        XCTAssertNotNil(transfer.timeUntilCompletion)
        XCTAssertGreaterThan(transfer.timeUntilCompletion!, 0)
    }

    func testTimeUntilCompletion_NoExpectedDate() {
        let transfer = TestFixtures.transfer(expectedCompletionDate: nil)
        XCTAssertNil(transfer.timeUntilCompletion)
    }

    func testTimeUntilCompletion_PastDate_ReturnsNegative() {
        let pastDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
        let transfer = TestFixtures.transfer(expectedCompletionDate: pastDate)
        XCTAssertNotNil(transfer.timeUntilCompletion)
        XCTAssertLessThan(transfer.timeUntilCompletion!, 0)
    }

    // MARK: - TransferType Tests

    func testTransferType_DisplayName() {
        XCTAssertEqual(TransferType.deposit.displayName, "Deposit")
        XCTAssertEqual(TransferType.withdrawal.displayName, "Withdrawal")
    }

    func testTransferType_IconName() {
        XCTAssertFalse(TransferType.deposit.iconName.isEmpty)
        XCTAssertFalse(TransferType.withdrawal.iconName.isEmpty)
    }

    func testTransferType_ColorHex() {
        XCTAssertTrue(TransferType.deposit.colorHex.hasPrefix("#"))
        XCTAssertTrue(TransferType.withdrawal.colorHex.hasPrefix("#"))
    }

    func testTransferType_Verb() {
        XCTAssertEqual(TransferType.deposit.verb, "deposited")
        XCTAssertEqual(TransferType.withdrawal.verb, "withdrawn")
    }

    func testTransferType_AllCases() {
        XCTAssertEqual(TransferType.allCases.count, 2)
    }

    // MARK: - TransferStatus Tests

    func testTransferStatus_DisplayName() {
        XCTAssertEqual(TransferStatus.pending.displayName, "Pending")
        XCTAssertEqual(TransferStatus.processing.displayName, "Processing")
        XCTAssertEqual(TransferStatus.completed.displayName, "Completed")
        XCTAssertEqual(TransferStatus.failed.displayName, "Failed")
        XCTAssertEqual(TransferStatus.cancelled.displayName, "Cancelled")
    }

    func testTransferStatus_IconName() {
        for status in TransferStatus.allCases {
            XCTAssertFalse(status.iconName.isEmpty)
        }
    }

    func testTransferStatus_ColorHex() {
        for status in TransferStatus.allCases {
            XCTAssertTrue(status.colorHex.hasPrefix("#"))
        }
    }

    func testTransferStatus_IsSuccess() {
        XCTAssertTrue(TransferStatus.completed.isSuccess)
        XCTAssertFalse(TransferStatus.pending.isSuccess)
        XCTAssertFalse(TransferStatus.failed.isSuccess)
    }

    func testTransferStatus_IsError() {
        XCTAssertTrue(TransferStatus.failed.isError)
        XCTAssertFalse(TransferStatus.completed.isError)
        XCTAssertFalse(TransferStatus.pending.isError)
    }

    func testTransferStatus_IsInProgress() {
        XCTAssertTrue(TransferStatus.pending.isInProgress)
        XCTAssertTrue(TransferStatus.processing.isInProgress)
        XCTAssertFalse(TransferStatus.completed.isInProgress)
        XCTAssertFalse(TransferStatus.failed.isInProgress)
        XCTAssertFalse(TransferStatus.cancelled.isInProgress)
    }

    func testTransferStatus_AllCases() {
        XCTAssertEqual(TransferStatus.allCases.count, 5)
    }

    // MARK: - TransferHistory Tests

    func testTransferHistory_TotalDeposits() {
        let transfers = [
            TestFixtures.transfer(id: "t1", type: .deposit, status: .completed, amount: 1000),
            TestFixtures.transfer(id: "t2", type: .deposit, status: .completed, amount: 500),
            TestFixtures.transfer(id: "t3", type: .deposit, status: .pending, amount: 200),
            TestFixtures.transfer(id: "t4", type: .withdrawal, status: .completed, amount: 300)
        ]
        let history = TransferHistory(transfers: transfers)

        XCTAssertEqual(history.totalDeposits, 1500) // Only completed deposits
    }

    func testTransferHistory_TotalWithdrawals() {
        let transfers = [
            TestFixtures.transfer(id: "t1", type: .withdrawal, status: .completed, amount: 500),
            TestFixtures.transfer(id: "t2", type: .withdrawal, status: .completed, amount: 300),
            TestFixtures.transfer(id: "t3", type: .deposit, status: .completed, amount: 1000)
        ]
        let history = TransferHistory(transfers: transfers)

        XCTAssertEqual(history.totalWithdrawals, 800)
    }

    func testTransferHistory_PendingDeposits() {
        let transfers = [
            TestFixtures.transfer(id: "t1", type: .deposit, status: .pending, amount: 1000),
            TestFixtures.transfer(id: "t2", type: .deposit, status: .processing, amount: 500),
            TestFixtures.transfer(id: "t3", type: .deposit, status: .completed, amount: 2000)
        ]
        let history = TransferHistory(transfers: transfers)

        XCTAssertEqual(history.pendingDeposits, 1500) // pending + processing
    }

    func testTransferHistory_PendingWithdrawals() {
        let transfers = [
            TestFixtures.transfer(id: "t1", type: .withdrawal, status: .pending, amount: 200),
            TestFixtures.transfer(id: "t2", type: .withdrawal, status: .processing, amount: 100),
            TestFixtures.transfer(id: "t3", type: .withdrawal, status: .completed, amount: 500)
        ]
        let history = TransferHistory(transfers: transfers)

        XCTAssertEqual(history.pendingWithdrawals, 300)
    }

    func testTransferHistory_NetTransfers() {
        let transfers = [
            TestFixtures.transfer(id: "t1", type: .deposit, status: .completed, amount: 1000),
            TestFixtures.transfer(id: "t2", type: .withdrawal, status: .completed, amount: 300)
        ]
        let history = TransferHistory(transfers: transfers)

        XCTAssertEqual(history.netTransfers, 700)
    }

    func testTransferHistory_TotalPending() {
        let transfers = [
            TestFixtures.transfer(id: "t1", type: .deposit, status: .pending, amount: 500),
            TestFixtures.transfer(id: "t2", type: .withdrawal, status: .processing, amount: 200)
        ]
        let history = TransferHistory(transfers: transfers)

        XCTAssertEqual(history.totalPending, 700)
    }

    func testTransferHistory_PendingTransfers() {
        let transfers = [
            TestFixtures.transfer(id: "t1", status: .pending),
            TestFixtures.transfer(id: "t2", status: .processing),
            TestFixtures.transfer(id: "t3", status: .completed)
        ]
        let history = TransferHistory(transfers: transfers)

        XCTAssertEqual(history.pendingTransfers.count, 2)
    }

    func testTransferHistory_CompletedTransfers() {
        let transfers = [
            TestFixtures.transfer(id: "t1", status: .completed),
            TestFixtures.transfer(id: "t2", status: .completed),
            TestFixtures.transfer(id: "t3", status: .pending)
        ]
        let history = TransferHistory(transfers: transfers)

        XCTAssertEqual(history.completedTransfers.count, 2)
    }

    func testTransferHistory_EmptyTransfers() {
        let history = TransferHistory(transfers: [])

        XCTAssertEqual(history.totalDeposits, 0)
        XCTAssertEqual(history.totalWithdrawals, 0)
        XCTAssertEqual(history.netTransfers, 0)
        XCTAssertEqual(history.pendingTransfers.count, 0)
    }

    // MARK: - Codable Tests

    func testTransfer_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.transfer(
            type: .deposit,
            status: .completed,
            amount: 1500,
            currency: "GBP",
            amountUSD: 1875,
            fxRate: 1.25,
            fees: 10
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(Transfer.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.amount, original.amount)
        XCTAssertEqual(decoded.currency, original.currency)
        XCTAssertEqual(decoded.amountUSD, original.amountUSD)
        XCTAssertEqual(decoded.fxRate, original.fxRate)
        XCTAssertEqual(decoded.fees, original.fees)
    }

    func testTransferType_Codable() throws {
        for type in TransferType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(TransferType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    func testTransferStatus_Codable() throws {
        for status in TransferStatus.allCases {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(TransferStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - Equatable Tests

    func testTransfer_Equatable() {
        let transfer1 = TestFixtures.transfer(id: "t1")
        let transfer2 = TestFixtures.transfer(id: "t1")
        let transfer3 = TestFixtures.transfer(id: "t2")

        XCTAssertEqual(transfer1, transfer2)
        XCTAssertNotEqual(transfer1, transfer3)
    }

    // MARK: - Hashable Tests

    func testTransfer_Hashable() {
        let transfer1 = TestFixtures.transfer(id: "t1")
        let transfer2 = TestFixtures.transfer(id: "t2")

        var set = Set<Transfer>()
        set.insert(transfer1)
        set.insert(transfer2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Edge Cases

    func testTransfer_ZeroAmount() {
        let transfer = TestFixtures.transfer(amount: 0, fees: 0)
        XCTAssertEqual(transfer.netAmount, 0)
    }

    func testTransfer_VeryLargeAmount() {
        let transfer = TestFixtures.transfer(amount: 1_000_000, fees: 100)
        XCTAssertEqual(transfer.netAmount, 999_900)
    }

    func testTransfer_FeesEqualAmount() {
        let transfer = TestFixtures.transfer(amount: 100, fees: 100)
        XCTAssertEqual(transfer.netAmount, 0)
    }
}
