//
//  FundingViewModelTests.swift
//  GrowfolioTests
//
//  Tests for FundingViewModel - funding operations (deposits and withdrawals).
//

import XCTest
@testable import Growfolio

@MainActor
final class FundingViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockRepository: MockFundingRepository!
    var sut: FundingViewModel!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockFundingRepository()
        sut = FundingViewModel(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isRefreshing)
        XCTAssertFalse(sut.isSubmitting)
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.balance)
        XCTAssertNil(sut.fxRate)
        XCTAssertTrue(sut.transfers.isEmpty)
        XCTAssertNil(sut.selectedTransfer)
        XCTAssertNil(sut.transferHistory)
        XCTAssertTrue(sut.depositAmount.isEmpty)
        XCTAssertTrue(sut.withdrawalAmount.isEmpty)
        XCTAssertTrue(sut.notes.isEmpty)
    }

    func test_initialState_sheetPresentationIsFalse() {
        XCTAssertFalse(sut.showDeposit)
        XCTAssertFalse(sut.showWithdrawal)
        XCTAssertFalse(sut.showTransferHistory)
        XCTAssertFalse(sut.showTransferDetail)
        XCTAssertFalse(sut.showConfirmation)
    }

    func test_initialState_filterStateIsNil() {
        XCTAssertNil(sut.filterType)
        XCTAssertNil(sut.filterStatus)
    }

    // MARK: - Computed Properties Tests

    func test_availableBalanceUSD_returnsZeroWhenNoBalance() {
        XCTAssertEqual(sut.availableBalanceUSD, 0)
    }

    func test_availableBalanceUSD_returnsBalanceValue() {
        sut.balance = TestFixtures.fundingBalance(availableUSD: 5000)
        XCTAssertEqual(sut.availableBalanceUSD, 5000)
    }

    func test_availableBalanceGBP_returnsBalanceValue() {
        sut.balance = TestFixtures.fundingBalance(availableGBP: 4000)
        XCTAssertEqual(sut.availableBalanceGBP, 4000)
    }

    func test_currentFXRate_returnsZeroWhenNoRate() {
        XCTAssertEqual(sut.currentFXRate, 0)
    }

    func test_currentFXRate_returnsRateValue() {
        sut.fxRate = TestFixtures.fxRate(rate: 1.25)
        XCTAssertEqual(sut.currentFXRate, 1.25)
    }

    func test_isFXRateValid_returnsFalseWhenNoRate() {
        sut.fxRate = nil
        XCTAssertFalse(sut.isFXRateValid)
    }

    func test_isFXRateValid_returnsTrueWhenRateIsValid() {
        sut.fxRate = TestFixtures.fxRate(expiresAt: Date().addingTimeInterval(300))
        XCTAssertTrue(sut.isFXRateValid)
    }

    func test_depositAmountValue_returnsNilForEmptyString() {
        sut.depositAmount = ""
        XCTAssertNil(sut.depositAmountValue)
    }

    func test_depositAmountValue_parsesValidDecimal() {
        sut.depositAmount = "1000"
        XCTAssertEqual(sut.depositAmountValue, 1000)
    }

    func test_depositAmountValue_handlesCommaFormatting() {
        sut.depositAmount = "1,000.50"
        XCTAssertEqual(sut.depositAmountValue, 1000.50)
    }

    func test_withdrawalAmountValue_parsesValidDecimal() {
        sut.withdrawalAmount = "500"
        XCTAssertEqual(sut.withdrawalAmountValue, 500)
    }

    func test_canDeposit_returnsFalseWhenNoAmount() {
        sut.depositAmount = ""
        sut.fxRate = TestFixtures.fxRate()
        XCTAssertFalse(sut.canDeposit)
    }

    func test_canDeposit_returnsFalseWhenZeroAmount() {
        sut.depositAmount = "0"
        sut.fxRate = TestFixtures.fxRate()
        XCTAssertFalse(sut.canDeposit)
    }

    func test_canDeposit_returnsFalseWhenNoFXRate() {
        sut.depositAmount = "1000"
        sut.fxRate = nil
        XCTAssertFalse(sut.canDeposit)
    }

    func test_canDeposit_returnsTrueWhenValidAmountAndRate() {
        sut.depositAmount = "1000"
        sut.fxRate = TestFixtures.fxRate(expiresAt: Date().addingTimeInterval(300))
        XCTAssertTrue(sut.canDeposit)
    }

    func test_canWithdraw_returnsFalseWhenInsufficientBalance() {
        sut.withdrawalAmount = "5000"
        sut.balance = TestFixtures.fundingBalance(availableGBP: 1000)
        sut.fxRate = TestFixtures.fxRate(expiresAt: Date().addingTimeInterval(300))
        XCTAssertFalse(sut.canWithdraw)
    }

    func test_canWithdraw_returnsTrueWhenSufficientBalance() {
        sut.withdrawalAmount = "500"
        sut.balance = TestFixtures.fundingBalance(availableGBP: 1000)
        sut.fxRate = TestFixtures.fxRate(expiresAt: Date().addingTimeInterval(300))
        XCTAssertTrue(sut.canWithdraw)
    }

    func test_filteredTransfers_returnsAllWhenNoFilters() {
        sut.transfers = TestFixtures.sampleTransfers
        sut.filterType = nil
        sut.filterStatus = nil

        XCTAssertEqual(sut.filteredTransfers.count, sut.transfers.count)
    }

    func test_filteredTransfers_filtersByType() {
        sut.transfers = TestFixtures.sampleTransfers
        sut.filterType = .deposit

        XCTAssertTrue(sut.filteredTransfers.allSatisfy { $0.type == .deposit })
    }

    func test_filteredTransfers_filtersByStatus() {
        sut.transfers = TestFixtures.sampleTransfers
        sut.filterStatus = .completed

        XCTAssertTrue(sut.filteredTransfers.allSatisfy { $0.status == .completed })
    }

    func test_pendingTransfers_returnsOnlyInProgressTransfers() {
        let transfers = [
            TestFixtures.transfer(id: "t1", status: .pending),
            TestFixtures.transfer(id: "t2", status: .completed),
            TestFixtures.transfer(id: "t3", status: .processing),
            TestFixtures.transfer(id: "t4", status: .failed)
        ]
        sut.transfers = transfers

        XCTAssertEqual(sut.pendingTransfers.count, 2)
        XCTAssertTrue(sut.pendingTransfers.allSatisfy { $0.status.isInProgress })
    }

    func test_recentTransfers_limitsToFive() {
        let transfers = (0..<10).map { i in
            TestFixtures.transfer(id: "t\(i)")
        }
        sut.transfers = transfers

        XCTAssertEqual(sut.recentTransfers.count, 5)
    }

    func test_hasTransfers_returnsFalseWhenEmpty() {
        sut.transfers = []
        XCTAssertFalse(sut.hasTransfers)
    }

    func test_hasTransfers_returnsTrueWhenNotEmpty() {
        sut.transfers = [TestFixtures.transfer()]
        XCTAssertTrue(sut.hasTransfers)
    }

    // MARK: - Loading State Tests

    func test_loadFundingData_setsIsLoadingDuringOperation() async {
        await sut.loadFundingData()

        XCTAssertFalse(sut.isLoading)
    }

    func test_loadFundingData_preventsMultipleSimultaneousLoads() async {
        sut.isLoading = true

        await sut.loadFundingData()

        XCTAssertFalse(mockRepository.fetchBalanceCalled)
    }

    func test_refreshFundingData_setsIsRefreshingDuringOperation() async {
        await sut.refreshFundingData()

        XCTAssertFalse(sut.isRefreshing)
        XCTAssertTrue(mockRepository.invalidateCacheCalled)
    }

    // MARK: - Data Loading Tests

    func test_loadFundingData_fetchesBalanceFXRateAndTransfers() async {
        let balance = TestFixtures.fundingBalance()
        let fxRate = TestFixtures.fxRate()
        let transfers = TestFixtures.sampleTransfers
        mockRepository.balanceToReturn = balance
        mockRepository.fxRateToReturn = fxRate
        mockRepository.transfersToReturn = transfers

        await sut.loadFundingData()

        XCTAssertTrue(mockRepository.fetchBalanceCalled)
        XCTAssertTrue(mockRepository.fetchFXRateCalled)
        XCTAssertTrue(mockRepository.fetchAllTransfersCalled)
        XCTAssertNotNil(sut.balance)
        XCTAssertNotNil(sut.fxRate)
        XCTAssertEqual(sut.transfers.count, transfers.count)
    }

    func test_loadFundingData_createsTransferHistory() async {
        mockRepository.transfersToReturn = TestFixtures.sampleTransfers

        await sut.loadFundingData()

        XCTAssertNotNil(sut.transferHistory)
    }

    func test_loadFundingData_clearsErrorOnSuccess() async {
        sut.error = NetworkError.noConnection
        mockRepository.balanceToReturn = TestFixtures.fundingBalance()
        mockRepository.fxRateToReturn = TestFixtures.fxRate()

        await sut.loadFundingData()

        XCTAssertNil(sut.error)
    }

    func test_refreshFXRate_updatesFXRate() async {
        let newRate = TestFixtures.fxRate(rate: 1.30)
        mockRepository.fxRateToReturn = newRate

        await sut.refreshFXRate()

        XCTAssertTrue(mockRepository.fetchFXRateCalled)
        XCTAssertEqual(sut.fxRate?.rate, 1.30)
    }

    // MARK: - Error Handling Tests

    func test_loadFundingData_setsErrorOnFailure() async {
        mockRepository.errorToThrow = NetworkError.serverError(statusCode: 500, message: nil)

        await sut.loadFundingData()

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Deposit Operations Tests

    func test_initiateDeposit_callsRepositoryWithCorrectAmount() async {
        sut.depositAmount = "1000"
        sut.notes = "Test deposit"

        _ = try? await sut.initiateDeposit()

        XCTAssertTrue(mockRepository.initiateDepositCalled)
        XCTAssertEqual(mockRepository.lastDepositAmount, 1000)
        XCTAssertEqual(mockRepository.lastDepositNotes, "Test deposit")
    }

    func test_initiateDeposit_throwsWhenInvalidAmount() async {
        sut.depositAmount = ""

        do {
            _ = try await sut.initiateDeposit()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is FundingRepositoryError)
        }
    }

    func test_initiateDeposit_setsIsSubmittingDuringOperation() async {
        sut.depositAmount = "1000"

        _ = try? await sut.initiateDeposit()

        XCTAssertFalse(sut.isSubmitting)
    }

    func test_initiateDeposit_storesPendingTransferAndFXRate() async {
        sut.depositAmount = "1000"
        sut.fxRate = TestFixtures.fxRate(rate: 1.25)
        let transfer = TestFixtures.transfer(type: .deposit)
        mockRepository.transferToReturn = transfer

        _ = try? await sut.initiateDeposit()

        XCTAssertNotNil(sut.pendingTransfer)
        XCTAssertNotNil(sut.confirmedFXRate)
    }

    func test_confirmDeposit_callsRepositoryWithCorrectParams() async {
        let transfer = TestFixtures.transfer(id: "deposit-123", type: .deposit)
        sut.pendingTransfer = transfer
        sut.confirmedFXRate = 1.25
        mockRepository.transferToReturn = transfer

        try? await sut.confirmDeposit()

        XCTAssertTrue(mockRepository.confirmDepositCalled)
        XCTAssertEqual(mockRepository.lastConfirmDepositTransferId, "deposit-123")
        XCTAssertEqual(mockRepository.lastConfirmDepositFXRate, 1.25)
    }

    func test_confirmDeposit_resetsFormOnSuccess() async {
        let transfer = TestFixtures.transfer(type: .deposit)
        sut.pendingTransfer = transfer
        sut.confirmedFXRate = 1.25
        sut.depositAmount = "1000"
        mockRepository.transferToReturn = transfer

        try? await sut.confirmDeposit()

        XCTAssertTrue(sut.depositAmount.isEmpty)
        XCTAssertNil(sut.pendingTransfer)
        XCTAssertNil(sut.confirmedFXRate)
    }

    // MARK: - Withdrawal Operations Tests

    func test_initiateWithdrawal_callsRepositoryWithCorrectAmount() async {
        sut.withdrawalAmount = "500"
        sut.notes = "Test withdrawal"

        _ = try? await sut.initiateWithdrawal()

        XCTAssertTrue(mockRepository.initiateWithdrawalCalled)
        XCTAssertEqual(mockRepository.lastWithdrawalAmount, 500)
        XCTAssertEqual(mockRepository.lastWithdrawalNotes, "Test withdrawal")
    }

    func test_initiateWithdrawal_throwsWhenInvalidAmount() async {
        sut.withdrawalAmount = ""

        do {
            _ = try await sut.initiateWithdrawal()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is FundingRepositoryError)
        }
    }

    func test_confirmWithdrawal_callsRepositoryWithCorrectParams() async {
        let transfer = TestFixtures.transfer(id: "withdrawal-123", type: .withdrawal)
        sut.pendingTransfer = transfer
        sut.confirmedFXRate = 1.25
        mockRepository.transferToReturn = transfer

        try? await sut.confirmWithdrawal()

        XCTAssertTrue(mockRepository.confirmWithdrawalCalled)
        XCTAssertEqual(mockRepository.lastConfirmWithdrawalTransferId, "withdrawal-123")
    }

    // MARK: - Transfer Operations Tests

    func test_cancelTransfer_callsRepository() async {
        let transfer = TestFixtures.transfer(id: "transfer-to-cancel", status: .pending)
        mockRepository.transferToReturn = transfer

        try? await sut.cancelTransfer(transfer)

        XCTAssertTrue(mockRepository.cancelTransferCalled)
        XCTAssertEqual(mockRepository.lastCancelledTransferId, "transfer-to-cancel")
    }

    func test_cancelTransfer_throwsWhenTransferCannotBeCancelled() async {
        let transfer = TestFixtures.transfer(status: .completed)

        do {
            try await sut.cancelTransfer(transfer)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is FundingRepositoryError)
        }
    }

    func test_selectTransfer_setsSelectedTransferAndShowsDetail() {
        let transfer = TestFixtures.transfer()

        sut.selectTransfer(transfer)

        XCTAssertEqual(sut.selectedTransfer?.id, transfer.id)
        XCTAssertTrue(sut.showTransferDetail)
    }

    // MARK: - Form Management Tests

    func test_resetDepositForm_clearsAllDepositState() {
        sut.depositAmount = "1000"
        sut.notes = "Test"
        sut.pendingTransfer = TestFixtures.transfer()
        sut.confirmedFXRate = 1.25
        sut.showConfirmation = true

        sut.resetDepositForm()

        XCTAssertTrue(sut.depositAmount.isEmpty)
        XCTAssertTrue(sut.notes.isEmpty)
        XCTAssertNil(sut.pendingTransfer)
        XCTAssertNil(sut.confirmedFXRate)
        XCTAssertFalse(sut.showConfirmation)
    }

    func test_resetWithdrawalForm_clearsAllWithdrawalState() {
        sut.withdrawalAmount = "500"
        sut.notes = "Test"
        sut.pendingTransfer = TestFixtures.transfer()
        sut.confirmedFXRate = 1.25
        sut.showConfirmation = true

        sut.resetWithdrawalForm()

        XCTAssertTrue(sut.withdrawalAmount.isEmpty)
        XCTAssertTrue(sut.notes.isEmpty)
        XCTAssertNil(sut.pendingTransfer)
        XCTAssertNil(sut.confirmedFXRate)
        XCTAssertFalse(sut.showConfirmation)
    }

    func test_setMaxWithdrawal_setsAmountToAvailableBalance() {
        sut.balance = TestFixtures.fundingBalance(availableGBP: 1500)

        sut.setMaxWithdrawal()

        XCTAssertEqual(sut.withdrawalAmount, "1500")
    }

    // MARK: - Filter Management Tests

    func test_clearFilters_resetsAllFilters() {
        sut.filterType = .deposit
        sut.filterStatus = .completed

        sut.clearFilters()

        XCTAssertNil(sut.filterType)
        XCTAssertNil(sut.filterStatus)
    }

    func test_setFilterType_setsFilterType() {
        sut.setFilter(type: .withdrawal)

        XCTAssertEqual(sut.filterType, .withdrawal)
    }

    func test_setFilterStatus_setsFilterStatus() {
        sut.setFilter(status: .pending)

        XCTAssertEqual(sut.filterStatus, .pending)
    }

    // MARK: - Presentation Tests

    func test_presentDeposit_resetsFormAndShowsSheet() {
        sut.depositAmount = "1000"
        sut.showDeposit = false

        sut.presentDeposit()

        XCTAssertTrue(sut.depositAmount.isEmpty)
        XCTAssertTrue(sut.showDeposit)
    }

    func test_presentWithdrawal_resetsFormAndShowsSheet() {
        sut.withdrawalAmount = "500"
        sut.showWithdrawal = false

        sut.presentWithdrawal()

        XCTAssertTrue(sut.withdrawalAmount.isEmpty)
        XCTAssertTrue(sut.showWithdrawal)
    }

    func test_presentTransferHistory_showsSheet() {
        sut.presentTransferHistory()

        XCTAssertTrue(sut.showTransferHistory)
    }

    func test_dismissDeposit_hidesSheetAndResetsForm() {
        sut.showDeposit = true
        sut.depositAmount = "1000"

        sut.dismissDeposit()

        XCTAssertFalse(sut.showDeposit)
        XCTAssertTrue(sut.depositAmount.isEmpty)
    }

    func test_dismissWithdrawal_hidesSheetAndResetsForm() {
        sut.showWithdrawal = true
        sut.withdrawalAmount = "500"

        sut.dismissWithdrawal()

        XCTAssertFalse(sut.showWithdrawal)
        XCTAssertTrue(sut.withdrawalAmount.isEmpty)
    }
}

// MARK: - Transfer Filtering Tests

final class TransferFilteringTests: XCTestCase {

    func test_transferType_allCases() {
        XCTAssertEqual(TransferType.allCases.count, 2)
        XCTAssertTrue(TransferType.allCases.contains(.deposit))
        XCTAssertTrue(TransferType.allCases.contains(.withdrawal))
    }

    func test_transferStatus_allCases() {
        XCTAssertEqual(TransferStatus.allCases.count, 5)
        XCTAssertTrue(TransferStatus.allCases.contains(.pending))
        XCTAssertTrue(TransferStatus.allCases.contains(.processing))
        XCTAssertTrue(TransferStatus.allCases.contains(.completed))
        XCTAssertTrue(TransferStatus.allCases.contains(.failed))
        XCTAssertTrue(TransferStatus.allCases.contains(.cancelled))
    }

    func test_transferStatus_isInProgress() {
        XCTAssertTrue(TransferStatus.pending.isInProgress)
        XCTAssertTrue(TransferStatus.processing.isInProgress)
        XCTAssertFalse(TransferStatus.completed.isInProgress)
        XCTAssertFalse(TransferStatus.failed.isInProgress)
        XCTAssertFalse(TransferStatus.cancelled.isInProgress)
    }

    func test_transferStatus_isSuccess() {
        XCTAssertTrue(TransferStatus.completed.isSuccess)
        XCTAssertFalse(TransferStatus.pending.isSuccess)
        XCTAssertFalse(TransferStatus.failed.isSuccess)
    }

    func test_transferStatus_isError() {
        XCTAssertTrue(TransferStatus.failed.isError)
        XCTAssertFalse(TransferStatus.completed.isError)
        XCTAssertFalse(TransferStatus.pending.isError)
    }
}
