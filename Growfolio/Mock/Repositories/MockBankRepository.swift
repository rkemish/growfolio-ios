//
//  MockBankRepository.swift
//  Growfolio
//
//  Mock bank repository for previews and testing.
//

import Foundation

/// Mock implementation of bank repository
final class MockBankRepository: BankRepositoryProtocol, @unchecked Sendable {
    private let store = MockDataStore.shared
    var shouldFail = false
    var errorToThrow: Error?

    init(bankAccounts: [BankAccount] = []) {
        Task {
            for account in bankAccounts {
                await store.addBankAccount(account)
            }
        }
    }

    func fetchBankAccounts() async throws -> [BankAccount] {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        return await store.bankAccounts
    }

    func fetchBankAccount(relationshipId: String) async throws -> BankAccount {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay

        guard let account = await store.getBankAccount(relationshipId: relationshipId) else {
            throw NetworkError.notFound
        }
        return account
    }

    func linkBankManual(request: BankLinkManualRequest) async throws -> BankAccount {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 700_000_000) // 0.7s delay

        let newAccount = BankAccount(
            id: UUID().uuidString,
            relationshipId: UUID().uuidString,
            userId: "mock-user",
            bankName: request.bankName,
            accountType: BankAccountType(rawValue: request.accountType) ?? .checking,
            accountNumberLast4: String(request.accountNumber.suffix(4)),
            status: .pending,
            capabilities: ["ach_debit", "ach_credit"],
            linkedAt: Date()
        )

        await store.addBankAccount(newAccount)
        return newAccount
    }

    func linkBankPlaid(request: BankLinkPlaidRequest) async throws -> BankAccount {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 700_000_000) // 0.7s delay

        let newAccount = BankAccount(
            id: UUID().uuidString,
            relationshipId: UUID().uuidString,
            userId: "mock-user",
            bankName: "Plaid Bank",
            accountType: .checking,
            accountNumberLast4: "1234",
            status: .active,
            capabilities: ["ach_debit", "ach_credit", "instant"],
            linkedAt: Date()
        )

        await store.addBankAccount(newAccount)
        return newAccount
    }

    func removeBankAccount(relationshipId: String) async throws {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        await store.deleteBankAccount(relationshipId: relationshipId)
    }
}
