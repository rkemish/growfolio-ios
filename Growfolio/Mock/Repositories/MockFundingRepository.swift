//
//  MockFundingRepository.swift
//  Growfolio
//
//  Mock implementation of FundingRepositoryProtocol for demo mode.
//

import Foundation

/// Mock implementation of FundingRepositoryProtocol
final class MockFundingRepository: FundingRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let store = MockDataStore.shared
    private let config = MockConfiguration.shared

    // MARK: - Balance Operations

    func fetchBalance() async throws -> FundingBalance {
        try await simulateNetwork()
        await ensureInitialized()

        guard let balance = await store.fundingBalance else {
            let userId = await store.currentUser?.id ?? "mock"
            let portfolioId = await store.portfolios.first?.id ?? "mock"
            let defaultBalance = FundingBalance(
                userId: userId,
                portfolioId: portfolioId,
                availableUSD: 0,
                availableGBP: 0
            )
            await store.setFundingBalance(defaultBalance)
            return defaultBalance
        }
        return balance
    }

    func fetchFXRate() async throws -> FXRate {
        try await simulateNetwork()
        await ensureInitialized()

        if let rate = await store.currentFXRate, rate.isValid {
            return rate
        }

        // Generate a new FX rate with small fluctuation
        let baseRate: Decimal = 1.27
        let fluctuation = Decimal(Double.random(in: -0.02...0.02))
        let newRate = FXRate(
            rate: baseRate + fluctuation,
            spread: 0.005
        )

        await store.setFXRate(newRate)
        return newRate
    }

    // MARK: - Deposit Operations

    func initiateDeposit(amount: Decimal, notes: String?) async throws -> Transfer {
        try await simulateNetwork()
        await ensureInitialized()

        guard amount > 0 else {
            throw FundingRepositoryError.invalidAmount
        }

        let minimumDeposit: Decimal = 10
        guard amount >= minimumDeposit else {
            throw FundingRepositoryError.minimumAmountNotMet(minimum: minimumDeposit)
        }

        let userId = await store.currentUser?.id ?? "mock"
        let portfolioId = await store.portfolios.first?.id ?? "mock"
        let fxRate = try await fetchFXRate()
        let amountUSD = amount * fxRate.effectiveRate

        let transfer = Transfer(
            id: MockDataGenerator.mockId(prefix: "transfer"),
            userId: userId,
            portfolioId: portfolioId,
            type: .deposit,
            status: .pending,
            amount: amount,
            currency: "GBP",
            amountUSD: amountUSD,
            fxRate: fxRate.effectiveRate,
            referenceNumber: MockDataGenerator.referenceNumber(),
            notes: notes,
            expectedCompletionDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        )

        await store.addTransfer(transfer)

        // Update pending deposits
        if var balance = await store.fundingBalance {
            balance.pendingDepositsGBP += amount
            balance.pendingDepositsUSD += amountUSD
            await store.updateFundingBalance(balance)
        }

        return transfer
    }

    func confirmDeposit(transferId: String, fxRate: Decimal) async throws -> Transfer {
        try await simulateNetwork()

        guard var transfer = await store.transfers.first(where: { $0.id == transferId }) else {
            throw FundingRepositoryError.transferNotFound(id: transferId)
        }

        guard transfer.status == .pending || transfer.status == .processing else {
            throw FundingRepositoryError.transferAlreadyProcessed
        }

        let amountUSD = transfer.amount * fxRate

        transfer.status = .completed
        transfer.completedAt = Date()
        transfer.updatedAt = Date()

        await store.updateTransfer(transfer)

        // Update balance
        if var balance = await store.fundingBalance {
            balance.availableGBP += transfer.amount
            balance.availableUSD += amountUSD
            balance.pendingDepositsGBP -= transfer.amount
            balance.pendingDepositsUSD -= transfer.amountUSD ?? amountUSD
            await store.updateFundingBalance(balance)
        }

        return transfer
    }

    // MARK: - Withdrawal Operations

    func initiateWithdrawal(amount: Decimal, notes: String?) async throws -> Transfer {
        try await simulateNetwork()
        await ensureInitialized()

        guard amount > 0 else {
            throw FundingRepositoryError.invalidAmount
        }

        let balance = await store.fundingBalance
        let availableGBP = balance?.availableGBP ?? 0

        guard availableGBP >= amount else {
            throw FundingRepositoryError.insufficientFunds(available: availableGBP, requested: amount)
        }

        let minimumWithdrawal: Decimal = 10
        guard amount >= minimumWithdrawal else {
            throw FundingRepositoryError.minimumAmountNotMet(minimum: minimumWithdrawal)
        }

        let userId = await store.currentUser?.id ?? "mock"
        let portfolioId = await store.portfolios.first?.id ?? "mock"
        let fxRate = try await fetchFXRate()
        let amountUSD = amount * fxRate.effectiveRate

        let transfer = Transfer(
            id: MockDataGenerator.mockId(prefix: "transfer"),
            userId: userId,
            portfolioId: portfolioId,
            type: .withdrawal,
            status: .pending,
            amount: amount,
            currency: "GBP",
            amountUSD: amountUSD,
            fxRate: fxRate.effectiveRate,
            referenceNumber: MockDataGenerator.referenceNumber(),
            notes: notes,
            expectedCompletionDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())
        )

        await store.addTransfer(transfer)

        // Update pending withdrawals and reduce available
        if var balance = await store.fundingBalance {
            balance.availableGBP -= amount
            balance.pendingWithdrawalsGBP += amount
            balance.pendingWithdrawalsUSD += amountUSD
            await store.updateFundingBalance(balance)
        }

        return transfer
    }

    func confirmWithdrawal(transferId: String, fxRate: Decimal) async throws -> Transfer {
        try await simulateNetwork()

        guard var transfer = await store.transfers.first(where: { $0.id == transferId }) else {
            throw FundingRepositoryError.transferNotFound(id: transferId)
        }

        guard transfer.status == .pending || transfer.status == .processing else {
            throw FundingRepositoryError.transferAlreadyProcessed
        }

        let amountUSD = transfer.amount * fxRate

        transfer.status = .completed
        transfer.completedAt = Date()
        transfer.updatedAt = Date()

        await store.updateTransfer(transfer)

        // Clear pending
        if var balance = await store.fundingBalance {
            balance.pendingWithdrawalsGBP -= transfer.amount
            balance.pendingWithdrawalsUSD -= transfer.amountUSD ?? amountUSD
            await store.updateFundingBalance(balance)
        }

        return transfer
    }

    // MARK: - Transfer Operations

    func fetchTransfer(id: String) async throws -> Transfer {
        try await simulateNetwork()

        guard let transfer = await store.transfers.first(where: { $0.id == id }) else {
            throw FundingRepositoryError.transferNotFound(id: id)
        }
        return transfer
    }

    func cancelTransfer(id: String) async throws -> Transfer {
        try await simulateNetwork()

        guard var transfer = await store.transfers.first(where: { $0.id == id }) else {
            throw FundingRepositoryError.transferNotFound(id: id)
        }

        guard transfer.canCancel else {
            throw FundingRepositoryError.transferCannotBeCancelled
        }

        transfer.status = .cancelled
        transfer.updatedAt = Date()

        await store.updateTransfer(transfer)

        // Restore balance if withdrawal was cancelled
        if transfer.type == .withdrawal {
            if var balance = await store.fundingBalance {
                balance.availableGBP += transfer.amount
                balance.pendingWithdrawalsGBP -= transfer.amount
                balance.pendingWithdrawalsUSD -= transfer.amountUSD ?? 0
                await store.updateFundingBalance(balance)
            }
        } else if transfer.type == .deposit {
            if var balance = await store.fundingBalance {
                balance.pendingDepositsGBP -= transfer.amount
                balance.pendingDepositsUSD -= transfer.amountUSD ?? 0
                await store.updateFundingBalance(balance)
            }
        }

        return transfer
    }

    // MARK: - History Operations

    func fetchTransferHistory(page: Int, limit: Int) async throws -> PaginatedResponse<Transfer> {
        try await simulateNetwork()
        await ensureInitialized()

        let allTransfers = await store.transfers.sorted { $0.initiatedAt > $1.initiatedAt }

        let startIndex = (page - 1) * limit
        let endIndex = min(startIndex + limit, allTransfers.count)

        guard startIndex < allTransfers.count else {
            let totalPages = allTransfers.isEmpty ? 1 : (allTransfers.count + limit - 1) / limit
            return PaginatedResponse(
                data: [],
                pagination: PaginatedResponse.Pagination(page: page, limit: limit, totalPages: totalPages, totalItems: allTransfers.count)
            )
        }

        let pageItems = Array(allTransfers[startIndex..<endIndex])
        let totalPages = (allTransfers.count + limit - 1) / limit
        return PaginatedResponse(
            data: pageItems,
            pagination: PaginatedResponse.Pagination(page: page, limit: limit, totalPages: totalPages, totalItems: allTransfers.count)
        )
    }

    func fetchTransferHistory(portfolioId: String, page: Int, limit: Int) async throws -> PaginatedResponse<Transfer> {
        try await simulateNetwork()

        let filteredTransfers = await store.transfers
            .filter { $0.portfolioId == portfolioId }
            .sorted { $0.initiatedAt > $1.initiatedAt }

        let startIndex = (page - 1) * limit
        let endIndex = min(startIndex + limit, filteredTransfers.count)

        guard startIndex < filteredTransfers.count else {
            let totalPages = filteredTransfers.isEmpty ? 1 : (filteredTransfers.count + limit - 1) / limit
            return PaginatedResponse(
                data: [],
                pagination: PaginatedResponse.Pagination(page: page, limit: limit, totalPages: totalPages, totalItems: filteredTransfers.count)
            )
        }

        let pageItems = Array(filteredTransfers[startIndex..<endIndex])
        let totalPages = (filteredTransfers.count + limit - 1) / limit
        return PaginatedResponse(
            data: pageItems,
            pagination: PaginatedResponse.Pagination(page: page, limit: limit, totalPages: totalPages, totalItems: filteredTransfers.count)
        )
    }

    func fetchAllTransfers() async throws -> [Transfer] {
        try await simulateNetwork()
        await ensureInitialized()
        return await store.transfers.sorted { $0.initiatedAt > $1.initiatedAt }
    }

    func fetchTransfers(type: TransferType) async throws -> [Transfer] {
        try await simulateNetwork()
        return await store.transfers
            .filter { $0.type == type }
            .sorted { $0.initiatedAt > $1.initiatedAt }
    }

    func fetchTransfers(status: TransferStatus) async throws -> [Transfer] {
        try await simulateNetwork()
        return await store.transfers
            .filter { $0.status == status }
            .sorted { $0.initiatedAt > $1.initiatedAt }
    }

    func fetchPendingTransfers() async throws -> [Transfer] {
        try await simulateNetwork()
        return await store.transfers
            .filter { $0.status.isInProgress }
            .sorted { $0.initiatedAt > $1.initiatedAt }
    }

    // MARK: - Summary Operations

    func fetchTransferSummary() async throws -> TransferHistory {
        try await simulateNetwork()
        await ensureInitialized()
        return TransferHistory(transfers: await store.transfers)
    }

    // MARK: - Cache Operations

    func invalidateCache() async {
        // No-op for mock
    }

    func prefetchFundingData() async throws {
        await ensureInitialized()
    }

    // MARK: - Private Methods

    private func simulateNetwork() async throws {
        try await config.simulateNetworkDelay()
        try config.maybeThrowSimulatedError()
    }

    private func ensureInitialized() async {
        if await store.fundingBalance == nil {
            await store.initialize(for: config.demoPersona)
        }
    }
}
