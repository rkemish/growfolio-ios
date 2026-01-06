//
//  FundingRepositoryTests.swift
//  GrowfolioTests
//
//  Tests for FundingRepository.
//

import XCTest
@testable import Growfolio

final class FundingRepositoryTests: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var sut: FundingRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = FundingRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        mockAPIClient.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeBalance(
        id: String = "balance-1",
        availableUSD: Decimal = 1000,
        availableGBP: Decimal = 800,
        pendingDepositsUSD: Decimal = 0,
        pendingDepositsGBP: Decimal = 0
    ) -> FundingBalance {
        FundingBalance(
            id: id,
            userId: "user-1",
            portfolioId: "portfolio-1",
            availableUSD: availableUSD,
            availableGBP: availableGBP,
            pendingDepositsUSD: pendingDepositsUSD,
            pendingDepositsGBP: pendingDepositsGBP
        )
    }

    private func makeFXRate(
        rate: Decimal = 1.27,
        spread: Decimal = 0.005
    ) -> FXRate {
        FXRate(
            fromCurrency: "GBP",
            toCurrency: "USD",
            rate: rate,
            spread: spread
        )
    }

    private func makeTransfer(
        id: String = "transfer-1",
        type: TransferType = .deposit,
        status: TransferStatus = .pending,
        amount: Decimal = 100
    ) -> Transfer {
        Transfer(
            id: id,
            userId: "user-1",
            portfolioId: "portfolio-1",
            type: type,
            status: status,
            amount: amount,
            currency: "GBP"
        )
    }

    private func makePaginatedResponse(transfers: [Transfer]) -> PaginatedResponse<Transfer> {
        PaginatedResponse(
            data: transfers,
            pagination: PaginatedResponse<Transfer>.Pagination(
                page: 1,
                limit: 50,
                totalPages: 1,
                totalItems: transfers.count
            )
        )
    }

    // MARK: - Fetch Balance Tests

    func test_fetchBalance_returnsBalanceFromAPI() async throws {
        // Arrange
        let expectedBalance = makeBalance(availableUSD: 5000, availableGBP: 4000)
        mockAPIClient.setResponse(expectedBalance, for: Endpoints.GetFundingBalance.self)

        // Act
        let balance = try await sut.fetchBalance()

        // Assert
        XCTAssertEqual(balance.availableUSD, 5000)
        XCTAssertEqual(balance.availableGBP, 4000)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchBalance_usesCache() async throws {
        // Arrange
        let expectedBalance = makeBalance()
        mockAPIClient.setResponse(expectedBalance, for: Endpoints.GetFundingBalance.self)

        // Act - First call populates cache
        _ = try await sut.fetchBalance()

        // Act - Second call should use cache (within 30 seconds)
        let result = try await sut.fetchBalance()

        // Assert
        XCTAssertEqual(result.id, "balance-1")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchBalance_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Server error"), for: Endpoints.GetFundingBalance.self)

        // Act & Assert
        do {
            _ = try await sut.fetchBalance()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Fetch FX Rate Tests

    func test_fetchFXRate_returnsRateFromAPI() async throws {
        // Arrange
        let expectedRate = makeFXRate(rate: 1.30)
        mockAPIClient.setResponse(expectedRate, for: Endpoints.GetFXRate.self)

        // Act
        let rate = try await sut.fetchFXRate()

        // Assert
        XCTAssertEqual(rate.rate, 1.30)
        XCTAssertEqual(rate.fromCurrency, "GBP")
        XCTAssertEqual(rate.toCurrency, "USD")
    }

    func test_fetchFXRate_usesValidCachedRate() async throws {
        // Arrange
        let validRate = makeFXRate(rate: 1.28)
        mockAPIClient.setResponse(validRate, for: Endpoints.GetFXRate.self)

        // Act - First call populates cache
        _ = try await sut.fetchFXRate()

        // Act - Second call should use cache if rate is still valid
        let result = try await sut.fetchFXRate()

        // Assert
        XCTAssertEqual(result.rate, 1.28)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Initiate Deposit Tests

    func test_initiateDeposit_returnsTransfer() async throws {
        // Arrange
        let expectedTransfer = makeTransfer(id: "deposit-1", type: .deposit)
        mockAPIClient.setResponse(expectedTransfer, for: Endpoints.InitiateDeposit.self)

        // Act
        let transfer = try await sut.initiateDeposit(amount: 100, notes: "Test deposit")

        // Assert
        XCTAssertEqual(transfer.id, "deposit-1")
        XCTAssertEqual(transfer.type, .deposit)
    }

    func test_initiateDeposit_invalidatesBalanceCache() async throws {
        // Arrange - First populate balance cache
        let balance = makeBalance()
        mockAPIClient.setResponse(balance, for: Endpoints.GetFundingBalance.self)
        _ = try await sut.fetchBalance()

        // Set up deposit response
        let transfer = makeTransfer(type: .deposit)
        mockAPIClient.setResponse(transfer, for: Endpoints.InitiateDeposit.self)

        // Act
        _ = try await sut.initiateDeposit(amount: 100, notes: nil)

        // Assert - Balance cache should be invalidated
        mockAPIClient.reset()
        let newBalance = makeBalance(availableGBP: 900)
        mockAPIClient.setResponse(newBalance, for: Endpoints.GetFundingBalance.self)

        let fetchedBalance = try await sut.fetchBalance()
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1) // New API call made
        XCTAssertEqual(fetchedBalance.availableGBP, 900)
    }

    func test_initiateDeposit_throwsForInvalidAmount() async {
        // Act & Assert
        do {
            _ = try await sut.initiateDeposit(amount: 0, notes: nil)
            XCTFail("Expected error to be thrown")
        } catch let error as FundingRepositoryError {
            XCTAssertEqual(error, .invalidAmount)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_initiateDeposit_throwsForNegativeAmount() async {
        // Act & Assert
        do {
            _ = try await sut.initiateDeposit(amount: -50, notes: nil)
            XCTFail("Expected error to be thrown")
        } catch let error as FundingRepositoryError {
            XCTAssertEqual(error, .invalidAmount)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Confirm Deposit Tests

    func test_confirmDeposit_returnsUpdatedTransfer() async throws {
        // Arrange
        var transfer = makeTransfer(id: "deposit-1", type: .deposit, status: .pending)
        transfer.status = .completed
        mockAPIClient.setResponse(transfer, for: Endpoints.ConfirmDeposit.self)

        // Act
        let confirmed = try await sut.confirmDeposit(transferId: "deposit-1", fxRate: 1.27)

        // Assert
        XCTAssertEqual(confirmed.status, .completed)
    }

    // MARK: - Initiate Withdrawal Tests

    func test_initiateWithdrawal_returnsTransfer() async throws {
        // Arrange - First set up balance
        let balance = makeBalance(availableGBP: 1000)
        mockAPIClient.setResponse(balance, for: Endpoints.GetFundingBalance.self)

        let expectedTransfer = makeTransfer(id: "withdrawal-1", type: .withdrawal)
        mockAPIClient.setResponse(expectedTransfer, for: Endpoints.InitiateWithdrawal.self)

        // Act
        let transfer = try await sut.initiateWithdrawal(amount: 100, notes: nil)

        // Assert
        XCTAssertEqual(transfer.id, "withdrawal-1")
        XCTAssertEqual(transfer.type, .withdrawal)
    }

    func test_initiateWithdrawal_throwsForInsufficientFunds() async {
        // Arrange
        let balance = makeBalance(availableGBP: 50)
        mockAPIClient.setResponse(balance, for: Endpoints.GetFundingBalance.self)

        // Act & Assert
        do {
            _ = try await sut.initiateWithdrawal(amount: 100, notes: nil)
            XCTFail("Expected error to be thrown")
        } catch let error as FundingRepositoryError {
            if case .insufficientFunds(let available, let requested) = error {
                XCTAssertEqual(available, 50)
                XCTAssertEqual(requested, 100)
            } else {
                XCTFail("Expected insufficientFunds error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Fetch Transfer Tests

    func test_fetchTransfer_returnsCachedTransferIfAvailable() async throws {
        // Arrange - First populate transfers cache
        let transfers = [makeTransfer(id: "transfer-123")]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)
        _ = try await sut.fetchTransferHistory(page: 1, limit: 50)
        mockAPIClient.reset()

        // Act - Fetch by ID should use cache
        let transfer = try await sut.fetchTransfer(id: "transfer-123")

        // Assert
        XCTAssertEqual(transfer.id, "transfer-123")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    func test_fetchTransfer_fetchesFromAPIIfNotCached() async throws {
        // Arrange
        let transfer = makeTransfer(id: "transfer-456")
        mockAPIClient.setResponse(transfer, for: Endpoints.GetTransfer.self)

        // Act
        let result = try await sut.fetchTransfer(id: "transfer-456")

        // Assert
        XCTAssertEqual(result.id, "transfer-456")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Cancel Transfer Tests

    func test_cancelTransfer_returnsCancelledTransfer() async throws {
        // Arrange
        let cancelledTransfer = makeTransfer(id: "transfer-1", status: .cancelled)
        mockAPIClient.setResponse(cancelledTransfer, for: Endpoints.CancelTransfer.self)

        // Act
        let result = try await sut.cancelTransfer(id: "transfer-1")

        // Assert
        XCTAssertEqual(result.status, .cancelled)
    }

    func test_cancelTransfer_throwsIfCannotBeCancelled() async throws {
        // Arrange - Populate cache with completed transfer
        let completedTransfer = makeTransfer(id: "transfer-1", status: .completed)
        let response = makePaginatedResponse(transfers: [completedTransfer])
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)
        _ = try await sut.fetchTransferHistory(page: 1, limit: 50)

        // Act & Assert
        do {
            _ = try await sut.cancelTransfer(id: "transfer-1")
            XCTFail("Expected error to be thrown")
        } catch let error as FundingRepositoryError {
            XCTAssertEqual(error, .transferCannotBeCancelled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Fetch Transfer History Tests

    func test_fetchTransferHistory_returnsTransfersFromAPI() async throws {
        // Arrange
        let transfers = [
            makeTransfer(id: "transfer-1", type: .deposit),
            makeTransfer(id: "transfer-2", type: .withdrawal)
        ]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)

        // Act
        let result = try await sut.fetchTransferHistory(page: 1, limit: 50)

        // Assert
        XCTAssertEqual(result.data.count, 2)
        XCTAssertEqual(result.data[0].type, .deposit)
        XCTAssertEqual(result.data[1].type, .withdrawal)
    }

    func test_fetchTransferHistory_updatesCacheOnFirstPage() async throws {
        // Arrange
        let transfers = [makeTransfer(id: "transfer-1")]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)

        // Act
        _ = try await sut.fetchTransferHistory(page: 1, limit: 50)

        // Assert - Subsequent fetch of all transfers should use cache
        mockAPIClient.reset()
        let allTransfers = try await sut.fetchAllTransfers()
        XCTAssertEqual(allTransfers.count, 1)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    // MARK: - Fetch All Transfers Tests

    func test_fetchAllTransfers_returnsAllTransfers() async throws {
        // Arrange
        let transfers = [
            makeTransfer(id: "t1"),
            makeTransfer(id: "t2"),
            makeTransfer(id: "t3")
        ]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)

        // Act
        let result = try await sut.fetchAllTransfers()

        // Assert
        XCTAssertEqual(result.count, 3)
    }

    func test_fetchAllTransfers_usesCache() async throws {
        // Arrange
        let transfers = [makeTransfer()]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)

        // Act - First call populates cache
        _ = try await sut.fetchAllTransfers()

        // Act - Second call should use cache (within 60 seconds)
        let result = try await sut.fetchAllTransfers()

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Filter Transfers Tests

    func test_fetchTransfers_byType_filtersDeposits() async throws {
        // Arrange
        let transfers = [
            makeTransfer(id: "t1", type: .deposit),
            makeTransfer(id: "t2", type: .withdrawal),
            makeTransfer(id: "t3", type: .deposit)
        ]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)

        // Act
        let deposits = try await sut.fetchTransfers(type: .deposit)

        // Assert
        XCTAssertEqual(deposits.count, 2)
        XCTAssertTrue(deposits.allSatisfy { $0.type == .deposit })
    }

    func test_fetchTransfers_byStatus_filtersPending() async throws {
        // Arrange
        let transfers = [
            makeTransfer(id: "t1", status: .pending),
            makeTransfer(id: "t2", status: .completed),
            makeTransfer(id: "t3", status: .pending)
        ]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)

        // Act
        let pending = try await sut.fetchTransfers(status: .pending)

        // Assert
        XCTAssertEqual(pending.count, 2)
        XCTAssertTrue(pending.allSatisfy { $0.status == .pending })
    }

    func test_fetchPendingTransfers_returnsOnlyInProgressTransfers() async throws {
        // Arrange
        let transfers = [
            makeTransfer(id: "t1", status: .pending),
            makeTransfer(id: "t2", status: .completed),
            makeTransfer(id: "t3", status: .processing),
            makeTransfer(id: "t4", status: .failed)
        ]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)

        // Act
        let pending = try await sut.fetchPendingTransfers()

        // Assert
        XCTAssertEqual(pending.count, 2)
        XCTAssertTrue(pending.allSatisfy { $0.status.isInProgress })
    }

    // MARK: - Transfer Summary Tests

    func test_fetchTransferSummary_returnsTransferHistory() async throws {
        // Arrange
        let transfers = [
            makeTransfer(id: "t1", type: .deposit, status: .completed, amount: 100),
            makeTransfer(id: "t2", type: .withdrawal, status: .completed, amount: 50),
            makeTransfer(id: "t3", type: .deposit, status: .pending, amount: 200)
        ]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)

        // Act
        let summary = try await sut.fetchTransferSummary()

        // Assert
        XCTAssertEqual(summary.transfers.count, 3)
        XCTAssertEqual(summary.totalDeposits, 100)
        XCTAssertEqual(summary.totalWithdrawals, 50)
        XCTAssertEqual(summary.pendingDeposits, 200)
    }

    // MARK: - Cache Invalidation Tests

    func test_invalidateCache_clearsAllCaches() async throws {
        // Arrange - Populate caches
        let balance = makeBalance()
        mockAPIClient.setResponse(balance, for: Endpoints.GetFundingBalance.self)
        _ = try await sut.fetchBalance()

        let transfers = [makeTransfer()]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)
        _ = try await sut.fetchAllTransfers()

        // Act
        await sut.invalidateCache()

        // Reset and set up new responses
        mockAPIClient.reset()
        let newBalance = makeBalance(id: "new-balance")
        mockAPIClient.setResponse(newBalance, for: Endpoints.GetFundingBalance.self)

        // Assert - New API call should be made
        let fetchedBalance = try await sut.fetchBalance()
        XCTAssertEqual(fetchedBalance.id, "new-balance")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Empty Response Tests

    func test_fetchAllTransfers_returnsEmptyArrayWhenNoTransfers() async throws {
        // Arrange
        let response = makePaginatedResponse(transfers: [])
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)

        // Act
        let transfers = try await sut.fetchAllTransfers()

        // Assert
        XCTAssertTrue(transfers.isEmpty)
    }

    // MARK: - Prefetch Tests

    func test_prefetchFundingData_populatesAllCaches() async throws {
        // Arrange
        let balance = makeBalance()
        mockAPIClient.setResponse(balance, for: Endpoints.GetFundingBalance.self)

        let transfers = [makeTransfer()]
        let response = makePaginatedResponse(transfers: transfers)
        mockAPIClient.setResponse(response, for: Endpoints.GetTransferHistory.self)

        let fxRate = makeFXRate()
        mockAPIClient.setResponse(fxRate, for: Endpoints.GetFXRate.self)

        // Act
        try await sut.prefetchFundingData()

        // Assert - All data should be cached
        mockAPIClient.reset()

        let cachedBalance = try await sut.fetchBalance()
        let cachedTransfers = try await sut.fetchAllTransfers()
        let cachedRate = try await sut.fetchFXRate()

        XCTAssertEqual(cachedBalance.id, "balance-1")
        XCTAssertEqual(cachedTransfers.count, 1)
        XCTAssertEqual(cachedRate.rate, 1.27)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }
}

// MARK: - FundingRepositoryError Equatable

extension FundingRepositoryError: Equatable {
    public static func == (lhs: FundingRepositoryError, rhs: FundingRepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidAmount, .invalidAmount):
            return true
        case (.transferCannotBeCancelled, .transferCannotBeCancelled):
            return true
        case (.insufficientFunds(let lhsAvailable, let lhsRequested), .insufficientFunds(let rhsAvailable, let rhsRequested)):
            return lhsAvailable == rhsAvailable && lhsRequested == rhsRequested
        default:
            return false
        }
    }
}
