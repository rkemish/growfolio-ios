//
//  BankRepositoryProtocol.swift
//  Growfolio
//
//  Repository protocol for bank account operations.
//

import Foundation

/// Protocol for bank account repository operations
protocol BankRepositoryProtocol: Sendable {
    /// Fetch all linked bank accounts
    func fetchBankAccounts() async throws -> [BankAccount]

    /// Fetch a specific bank account by relationship ID
    func fetchBankAccount(relationshipId: String) async throws -> BankAccount

    /// Link a bank account manually (ACH)
    func linkBankManual(request: BankLinkManualRequest) async throws -> BankAccount

    /// Link a bank account via Plaid
    func linkBankPlaid(request: BankLinkPlaidRequest) async throws -> BankAccount

    /// Remove a linked bank account
    func removeBankAccount(relationshipId: String) async throws
}
