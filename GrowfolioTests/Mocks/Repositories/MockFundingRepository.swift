//
//  MockFundingRepository.swift
//  GrowfolioTests
//
//  Mock funding repository for testing.
//

import Foundation
@testable import Growfolio

/// Mock funding repository that returns predefined responses for testing
final class MockFundingRepository: FundingRepositoryProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    var balanceToReturn: FundingBalance?
    var fxRateToReturn: FXRate?
    var transferToReturn: Transfer?
    var transfersToReturn: [Transfer] = []
    var paginatedTransfersToReturn: PaginatedResponse<Transfer>?
    var transferHistoryToReturn: TransferHistory?
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var fetchBalanceCalled = false
    var fetchFXRateCalled = false
    var initiateDepositCalled = false
    var lastDepositAmount: Decimal?
    var lastDepositNotes: String?
    var confirmDepositCalled = false
    var lastConfirmDepositTransferId: String?
    var lastConfirmDepositFXRate: Decimal?
    var initiateWithdrawalCalled = false
    var lastWithdrawalAmount: Decimal?
    var lastWithdrawalNotes: String?
    var confirmWithdrawalCalled = false
    var lastConfirmWithdrawalTransferId: String?
    var lastConfirmWithdrawalFXRate: Decimal?
    var fetchTransferCalled = false
    var lastFetchedTransferId: String?
    var cancelTransferCalled = false
    var lastCancelledTransferId: String?
    var fetchTransferHistoryCalled = false
    var fetchTransferHistoryPortfolioIdCalled: String?
    var fetchAllTransfersCalled = false
    var fetchTransfersByTypeCalled = false
    var lastFetchedType: TransferType?
    var fetchTransfersByStatusCalled = false
    var lastFetchedStatus: TransferStatus?
    var fetchPendingTransfersCalled = false
    var fetchTransferSummaryCalled = false
    var invalidateCacheCalled = false
    var prefetchFundingDataCalled = false

    // MARK: - Reset

    func reset() {
        balanceToReturn = nil
        fxRateToReturn = nil
        transferToReturn = nil
        transfersToReturn = []
        paginatedTransfersToReturn = nil
        transferHistoryToReturn = nil
        errorToThrow = nil

        fetchBalanceCalled = false
        fetchFXRateCalled = false
        initiateDepositCalled = false
        lastDepositAmount = nil
        lastDepositNotes = nil
        confirmDepositCalled = false
        lastConfirmDepositTransferId = nil
        lastConfirmDepositFXRate = nil
        initiateWithdrawalCalled = false
        lastWithdrawalAmount = nil
        lastWithdrawalNotes = nil
        confirmWithdrawalCalled = false
        lastConfirmWithdrawalTransferId = nil
        lastConfirmWithdrawalFXRate = nil
        fetchTransferCalled = false
        lastFetchedTransferId = nil
        cancelTransferCalled = false
        lastCancelledTransferId = nil
        fetchTransferHistoryCalled = false
        fetchTransferHistoryPortfolioIdCalled = nil
        fetchAllTransfersCalled = false
        fetchTransfersByTypeCalled = false
        lastFetchedType = nil
        fetchTransfersByStatusCalled = false
        lastFetchedStatus = nil
        fetchPendingTransfersCalled = false
        fetchTransferSummaryCalled = false
        invalidateCacheCalled = false
        prefetchFundingDataCalled = false
    }

    // MARK: - FundingRepositoryProtocol Implementation

    func fetchBalance() async throws -> FundingBalance {
        fetchBalanceCalled = true
        if let error = errorToThrow { throw error }
        if let balance = balanceToReturn { return balance }
        return FundingBalance(
            id: "balance-123",
            userId: "user-123",
            portfolioId: "portfolio-123",
            availableUSD: 5000,
            availableGBP: 4000,
            pendingDepositsUSD: 0,
            pendingDepositsGBP: 500,
            pendingWithdrawalsUSD: 0,
            pendingWithdrawalsGBP: 0,
            updatedAt: Date()
        )
    }

    func fetchFXRate() async throws -> FXRate {
        fetchFXRateCalled = true
        if let error = errorToThrow { throw error }
        if let rate = fxRateToReturn { return rate }
        return FXRate(
            fromCurrency: "GBP",
            toCurrency: "USD",
            rate: 1.25,
            spread: 0.01,
            timestamp: Date(),
            expiresAt: Date().addingTimeInterval(300)
        )
    }

    func initiateDeposit(amount: Decimal, notes: String?) async throws -> Transfer {
        initiateDepositCalled = true
        lastDepositAmount = amount
        lastDepositNotes = notes
        if let error = errorToThrow { throw error }
        if let transfer = transferToReturn { return transfer }
        return Transfer(
            userId: "user-123",
            portfolioId: "portfolio-123",
            type: .deposit,
            status: .pending,
            amount: amount,
            currency: "GBP",
            amountUSD: amount * 1.25,
            fxRate: 1.25,
            notes: notes
        )
    }

    func confirmDeposit(transferId: String, fxRate: Decimal) async throws -> Transfer {
        confirmDepositCalled = true
        lastConfirmDepositTransferId = transferId
        lastConfirmDepositFXRate = fxRate
        if let error = errorToThrow { throw error }
        if var transfer = transferToReturn {
            transfer.status = .processing
            return transfer
        }
        return Transfer(
            id: transferId,
            userId: "user-123",
            portfolioId: "portfolio-123",
            type: .deposit,
            status: .processing,
            amount: 1000,
            currency: "GBP",
            amountUSD: 1000 * fxRate,
            fxRate: fxRate
        )
    }

    func initiateWithdrawal(amount: Decimal, notes: String?) async throws -> Transfer {
        initiateWithdrawalCalled = true
        lastWithdrawalAmount = amount
        lastWithdrawalNotes = notes
        if let error = errorToThrow { throw error }
        if let transfer = transferToReturn { return transfer }
        return Transfer(
            userId: "user-123",
            portfolioId: "portfolio-123",
            type: .withdrawal,
            status: .pending,
            amount: amount,
            currency: "GBP",
            amountUSD: amount * 1.25,
            fxRate: 1.25,
            notes: notes
        )
    }

    func confirmWithdrawal(transferId: String, fxRate: Decimal) async throws -> Transfer {
        confirmWithdrawalCalled = true
        lastConfirmWithdrawalTransferId = transferId
        lastConfirmWithdrawalFXRate = fxRate
        if let error = errorToThrow { throw error }
        if var transfer = transferToReturn {
            transfer.status = .processing
            return transfer
        }
        return Transfer(
            id: transferId,
            userId: "user-123",
            portfolioId: "portfolio-123",
            type: .withdrawal,
            status: .processing,
            amount: 500,
            currency: "GBP",
            amountUSD: 500 * fxRate,
            fxRate: fxRate
        )
    }

    func fetchTransfer(id: String) async throws -> Transfer {
        fetchTransferCalled = true
        lastFetchedTransferId = id
        if let error = errorToThrow { throw error }
        if let transfer = transferToReturn { return transfer }
        throw FundingRepositoryError.transferNotFound(id: id)
    }

    func cancelTransfer(id: String) async throws -> Transfer {
        cancelTransferCalled = true
        lastCancelledTransferId = id
        if let error = errorToThrow { throw error }
        if var transfer = transferToReturn {
            transfer.status = .cancelled
            return transfer
        }
        return Transfer(
            id: id,
            userId: "user-123",
            portfolioId: "portfolio-123",
            type: .deposit,
            status: .cancelled,
            amount: 1000,
            currency: "GBP"
        )
    }

    func fetchTransferHistory(page: Int, limit: Int) async throws -> PaginatedResponse<Transfer> {
        fetchTransferHistoryCalled = true
        if let error = errorToThrow { throw error }
        if let paginated = paginatedTransfersToReturn { return paginated }
        return PaginatedResponse(
            data: transfersToReturn,
            pagination: PaginatedResponse<Transfer>.Pagination(
                page: page,
                limit: limit,
                totalPages: 1,
                totalItems: transfersToReturn.count
            )
        )
    }

    func fetchTransferHistory(portfolioId: String, page: Int, limit: Int) async throws -> PaginatedResponse<Transfer> {
        fetchTransferHistoryCalled = true
        fetchTransferHistoryPortfolioIdCalled = portfolioId
        if let error = errorToThrow { throw error }
        if let paginated = paginatedTransfersToReturn { return paginated }
        let filtered = transfersToReturn.filter { $0.portfolioId == portfolioId }
        return PaginatedResponse(
            data: filtered,
            pagination: PaginatedResponse<Transfer>.Pagination(
                page: page,
                limit: limit,
                totalPages: 1,
                totalItems: filtered.count
            )
        )
    }

    func fetchAllTransfers() async throws -> [Transfer] {
        fetchAllTransfersCalled = true
        if let error = errorToThrow { throw error }
        return transfersToReturn
    }

    func fetchTransfers(type: TransferType) async throws -> [Transfer] {
        fetchTransfersByTypeCalled = true
        lastFetchedType = type
        if let error = errorToThrow { throw error }
        return transfersToReturn.filter { $0.type == type }
    }

    func fetchTransfers(status: TransferStatus) async throws -> [Transfer] {
        fetchTransfersByStatusCalled = true
        lastFetchedStatus = status
        if let error = errorToThrow { throw error }
        return transfersToReturn.filter { $0.status == status }
    }

    func fetchPendingTransfers() async throws -> [Transfer] {
        fetchPendingTransfersCalled = true
        if let error = errorToThrow { throw error }
        return transfersToReturn.filter { $0.status.isInProgress }
    }

    func fetchTransferSummary() async throws -> TransferHistory {
        fetchTransferSummaryCalled = true
        if let error = errorToThrow { throw error }
        if let history = transferHistoryToReturn { return history }
        return TransferHistory(transfers: transfersToReturn)
    }

    func invalidateCache() async {
        invalidateCacheCalled = true
    }

    func prefetchFundingData() async throws {
        prefetchFundingDataCalled = true
        if let error = errorToThrow { throw error }
    }
}
