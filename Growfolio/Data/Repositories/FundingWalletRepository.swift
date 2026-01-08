//
//  FundingWalletRepository.swift
//  Growfolio
//
//  Repository implementation for funding wallet operations using APIClient.
//

import Foundation

/// Repository for funding wallet operations
final class FundingWalletRepository: FundingWalletRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchFundingWallet() async throws -> FundingWallet {
        try await apiClient.request(Endpoints.GetFundingWallet())
    }

    func fetchFundingDetails() async throws -> FundingDetails {
        try await apiClient.request(Endpoints.GetFundingDetails())
    }

    func fetchRecipientBank() async throws -> RecipientBankInfo {
        try await apiClient.request(Endpoints.GetRecipientBank())
    }

    func syncDeposits() async throws {
        try await apiClient.request(Endpoints.SyncDeposits())
    }

    func fetchWalletTransfers() async throws -> [PendingTransfer] {
        try await apiClient.request(Endpoints.GetWalletTransfers())
    }

    func initiateWithdraw(request: WalletWithdrawRequest) async throws -> PendingTransfer {
        try await apiClient.request(Endpoints.InitiateWalletWithdraw(request: request))
    }
}
