//
//  MockFundingWalletRepository.swift
//  Growfolio
//
//  Mock funding wallet repository for previews and testing.
//

import Foundation

/// Mock implementation of funding wallet repository
final class MockFundingWalletRepository: FundingWalletRepositoryProtocol, @unchecked Sendable {
    private let store = MockDataStore.shared
    var shouldFail = false
    var errorToThrow: Error?

    init() {}

    func fetchFundingWallet() async throws -> FundingWallet {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay

        return await store.fundingWallet ?? FundingWallet(
            balance: 1000.00,
            currency: "USD",
            pendingTransfers: [],
            fundingDetails: FundingDetails(
                accountNumber: "123456789",
                routingNumber: "021000021",
                swiftCode: nil,
                iban: nil
            )
        )
    }

    func fetchFundingDetails() async throws -> FundingDetails {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay

        return FundingDetails(
            accountNumber: "123456789",
            routingNumber: "021000021",
            swiftCode: nil,
            iban: nil
        )
    }

    func fetchRecipientBank() async throws -> RecipientBankInfo {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay

        return await store.recipientBankInfo ?? RecipientBankInfo(
            bankName: "Alpaca Securities LLC",
            accountNumber: "987654321",
            routingNumber: "021000021",
            accountType: "checking",
            wireInstructions: "Reference: USER123456"
        )
    }

    func syncDeposits() async throws {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
        // Syncing deposits - no return value
    }

    func fetchWalletTransfers() async throws -> [PendingTransfer] {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay

        return await store.walletTransfers
    }

    func initiateWithdraw(request: WalletWithdrawRequest) async throws -> PendingTransfer {
        if shouldFail {
            throw errorToThrow ?? NetworkError.serverError(statusCode: 500, message: "Mock error")
        }
        try? await Task.sleep(nanoseconds: 700_000_000) // 0.7s delay

        let transfer = PendingTransfer(
            id: UUID().uuidString,
            amount: request.amount,
            direction: .outgoing,
            status: "pending",
            createdAt: Date()
        )

        await store.addWalletTransfer(transfer)
        return transfer
    }
}
