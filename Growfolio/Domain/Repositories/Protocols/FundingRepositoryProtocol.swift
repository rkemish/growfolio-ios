//
//  FundingRepositoryProtocol.swift
//  Growfolio
//
//  Protocol defining the funding repository interface.
//

import Foundation

/// Protocol for funding data operations
protocol FundingRepositoryProtocol: Sendable {

    // MARK: - Balance Operations

    /// Fetch the current funding balance
    /// - Returns: The funding balance with USD and GBP amounts
    func fetchBalance() async throws -> FundingBalance

    /// Fetch the current FX rate (GBP/USD)
    /// - Returns: The current FX rate
    func fetchFXRate() async throws -> FXRate

    // MARK: - Deposit Operations

    /// Initiate a deposit
    /// - Parameters:
    ///   - amount: Amount to deposit in GBP
    ///   - notes: Optional notes for the deposit
    /// - Returns: The created transfer record
    func initiateDeposit(amount: Decimal, notes: String?) async throws -> Transfer

    /// Confirm a deposit with the provided details
    /// - Parameters:
    ///   - transferId: The transfer ID to confirm
    ///   - fxRate: The FX rate to lock in
    /// - Returns: The confirmed transfer record
    func confirmDeposit(transferId: String, fxRate: Decimal) async throws -> Transfer

    // MARK: - Withdrawal Operations

    /// Initiate a withdrawal
    /// - Parameters:
    ///   - amount: Amount to withdraw in GBP
    ///   - notes: Optional notes for the withdrawal
    /// - Returns: The created transfer record
    func initiateWithdrawal(amount: Decimal, notes: String?) async throws -> Transfer

    /// Confirm a withdrawal with the provided details
    /// - Parameters:
    ///   - transferId: The transfer ID to confirm
    ///   - fxRate: The FX rate to lock in
    /// - Returns: The confirmed transfer record
    func confirmWithdrawal(transferId: String, fxRate: Decimal) async throws -> Transfer

    // MARK: - Transfer Operations

    /// Fetch a specific transfer by ID
    /// - Parameter id: Transfer identifier
    /// - Returns: The transfer if found
    func fetchTransfer(id: String) async throws -> Transfer

    /// Cancel a pending transfer
    /// - Parameter id: Transfer identifier
    /// - Returns: The cancelled transfer
    func cancelTransfer(id: String) async throws -> Transfer

    // MARK: - History Operations

    /// Fetch transfer history
    /// - Parameters:
    ///   - page: Page number (1-indexed)
    ///   - limit: Number of items per page
    /// - Returns: Paginated response containing transfers
    func fetchTransferHistory(page: Int, limit: Int) async throws -> PaginatedResponse<Transfer>

    /// Fetch transfer history for a specific portfolio
    /// - Parameters:
    ///   - portfolioId: Portfolio identifier
    ///   - page: Page number (1-indexed)
    ///   - limit: Number of items per page
    /// - Returns: Paginated response containing transfers
    func fetchTransferHistory(portfolioId: String, page: Int, limit: Int) async throws -> PaginatedResponse<Transfer>

    /// Fetch all transfers (for local filtering)
    /// - Returns: Array of all transfers
    func fetchAllTransfers() async throws -> [Transfer]

    /// Fetch transfers by type
    /// - Parameter type: Transfer type to filter by
    /// - Returns: Array of transfers of the specified type
    func fetchTransfers(type: TransferType) async throws -> [Transfer]

    /// Fetch transfers by status
    /// - Parameter status: Transfer status to filter by
    /// - Returns: Array of transfers with the specified status
    func fetchTransfers(status: TransferStatus) async throws -> [Transfer]

    /// Fetch pending transfers
    /// - Returns: Array of pending transfers
    func fetchPendingTransfers() async throws -> [Transfer]

    // MARK: - Summary Operations

    /// Fetch transfer summary/history statistics
    /// - Returns: Transfer history with summary statistics
    func fetchTransferSummary() async throws -> TransferHistory

    // MARK: - Cache Operations

    /// Invalidate cached funding data
    func invalidateCache() async

    /// Prefetch funding data for offline access
    func prefetchFundingData() async throws
}

// MARK: - Default Implementations

extension FundingRepositoryProtocol {
    func fetchTransferHistory(page: Int = 1, limit: Int = Constants.API.defaultPageSize) async throws -> PaginatedResponse<Transfer> {
        try await fetchTransferHistory(page: page, limit: limit)
    }

    func fetchTransferHistory(portfolioId: String, page: Int = 1, limit: Int = Constants.API.defaultPageSize) async throws -> PaginatedResponse<Transfer> {
        try await fetchTransferHistory(portfolioId: portfolioId, page: page, limit: limit)
    }
}

// MARK: - Funding Repository Error

/// Errors specific to funding operations
enum FundingRepositoryError: LocalizedError {
    case insufficientFunds(available: Decimal, requested: Decimal)
    case invalidAmount
    case transferNotFound(id: String)
    case transferAlreadyProcessed
    case transferCannotBeCancelled
    case fxRateExpired
    case fxRateUnavailable
    case minimumAmountNotMet(minimum: Decimal)
    case maximumAmountExceeded(maximum: Decimal)
    case withdrawalLimitExceeded(dailyLimit: Decimal)
    case depositLimitExceeded(dailyLimit: Decimal)
    case bankAccountNotLinked
    case bankAccountVerificationRequired

    var errorDescription: String? {
        switch self {
        case .insufficientFunds(let available, let requested):
            return "Insufficient funds. Available: \(available.currencyString), Requested: \(requested.currencyString)"
        case .invalidAmount:
            return "The amount entered is invalid"
        case .transferNotFound(let id):
            return "Transfer with ID '\(id)' was not found"
        case .transferAlreadyProcessed:
            return "This transfer has already been processed"
        case .transferCannotBeCancelled:
            return "This transfer cannot be cancelled"
        case .fxRateExpired:
            return "The FX rate has expired. Please refresh and try again."
        case .fxRateUnavailable:
            return "Unable to fetch current FX rate. Please try again later."
        case .minimumAmountNotMet(let minimum):
            return "Minimum amount is \(minimum.currencyString)"
        case .maximumAmountExceeded(let maximum):
            return "Maximum amount is \(maximum.currencyString)"
        case .withdrawalLimitExceeded(let dailyLimit):
            return "Daily withdrawal limit of \(dailyLimit.currencyString) exceeded"
        case .depositLimitExceeded(let dailyLimit):
            return "Daily deposit limit of \(dailyLimit.currencyString) exceeded"
        case .bankAccountNotLinked:
            return "Please link a bank account before making transfers"
        case .bankAccountVerificationRequired:
            return "Bank account verification is required"
        }
    }
}
