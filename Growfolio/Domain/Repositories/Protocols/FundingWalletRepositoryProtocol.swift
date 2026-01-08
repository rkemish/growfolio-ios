//
//  FundingWalletRepositoryProtocol.swift
//  Growfolio
//
//  Repository protocol for funding wallet operations.
//

import Foundation

/// Protocol for funding wallet repository operations
protocol FundingWalletRepositoryProtocol: Sendable {
    /// Fetch funding wallet balance and details
    func fetchFundingWallet() async throws -> FundingWallet

    /// Fetch funding details (account/routing numbers)
    func fetchFundingDetails() async throws -> FundingDetails

    /// Fetch recipient bank information for incoming transfers
    func fetchRecipientBank() async throws -> RecipientBankInfo

    /// Sync pending deposits
    func syncDeposits() async throws

    /// Fetch wallet transfer history
    func fetchWalletTransfers() async throws -> [PendingTransfer]

    /// Initiate a withdrawal from funding wallet
    func initiateWithdraw(request: WalletWithdrawRequest) async throws -> PendingTransfer
}
