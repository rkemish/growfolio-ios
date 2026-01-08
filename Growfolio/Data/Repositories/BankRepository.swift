//
//  BankRepository.swift
//  Growfolio
//
//  Repository implementation for bank account operations using APIClient.
//

import Foundation

/// Repository for bank account operations
final class BankRepository: BankRepositoryProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func fetchBankAccounts() async throws -> [BankAccount] {
        try await apiClient.request(Endpoints.GetBankAccounts())
    }

    func fetchBankAccount(relationshipId: String) async throws -> BankAccount {
        try await apiClient.request(Endpoints.GetBankAccount(relationshipId: relationshipId))
    }

    func linkBankManual(request: BankLinkManualRequest) async throws -> BankAccount {
        try await apiClient.request(Endpoints.LinkBankManual(request: request))
    }

    func linkBankPlaid(request: BankLinkPlaidRequest) async throws -> BankAccount {
        try await apiClient.request(Endpoints.LinkBankPlaid(request: request))
    }

    func removeBankAccount(relationshipId: String) async throws {
        try await apiClient.request(Endpoints.RemoveBankAccount(relationshipId: relationshipId))
    }
}
