//
//  FundingRepository.swift
//  Growfolio
//
//  Implementation of FundingRepositoryProtocol using the API client.
//

import Foundation

/// Implementation of the funding repository using the API client
final class FundingRepository: FundingRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let apiClient: APIClientProtocol
    private var cachedBalance: FundingBalance?
    private var cachedFXRate: FXRate?
    private var cachedTransfers: [Transfer] = []
    private var lastBalanceFetch: Date?
    private var lastTransfersFetch: Date?
    private let balanceCacheDuration: TimeInterval = 30 // 30 seconds for balance
    private let transfersCacheDuration: TimeInterval = 60 // 1 minute for transfers

    // MARK: - Initialization

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - Balance Operations

    func fetchBalance() async throws -> FundingBalance {
        // Check cache first
        if let cached = cachedBalance,
           let lastFetch = lastBalanceFetch,
           Date().timeIntervalSince(lastFetch) < balanceCacheDuration {
            return cached
        }

        let balance: FundingBalance = try await apiClient.request(Endpoints.GetFundingBalance())

        cachedBalance = balance
        lastBalanceFetch = Date()

        return balance
    }

    func fetchFXRate() async throws -> FXRate {
        // Check if cached rate is still valid
        if let cached = cachedFXRate, cached.isValid {
            return cached
        }

        let rate: FXRate = try await apiClient.request(Endpoints.GetFXRate())

        cachedFXRate = rate

        return rate
    }

    // MARK: - Deposit Operations

    func initiateDeposit(amount: Decimal, notes: String?) async throws -> Transfer {
        // Validate amount
        guard amount > 0 else {
            throw FundingRepositoryError.invalidAmount
        }

        let request = FundingTransferRequest(
            amount: amount,
            currency: "GBP",
            notes: notes
        )

        let transfer: Transfer = try await apiClient.request(
            try Endpoints.InitiateDeposit(request: request)
        )

        // Add to cache
        cachedTransfers.insert(transfer, at: 0)

        // Invalidate balance cache
        cachedBalance = nil

        return transfer
    }

    func confirmDeposit(transferId: String, fxRate: Decimal) async throws -> Transfer {
        let request = FundingConfirmRequest(
            transferId: transferId,
            fxRate: fxRate
        )

        let transfer: Transfer = try await apiClient.request(
            try Endpoints.ConfirmDeposit(request: request)
        )

        // Update cache
        if let index = cachedTransfers.firstIndex(where: { $0.id == transferId }) {
            cachedTransfers[index] = transfer
        }

        // Invalidate balance cache
        cachedBalance = nil

        return transfer
    }

    // MARK: - Withdrawal Operations

    func initiateWithdrawal(amount: Decimal, notes: String?) async throws -> Transfer {
        // Validate amount
        guard amount > 0 else {
            throw FundingRepositoryError.invalidAmount
        }

        // Check balance first
        let balance = try await fetchBalance()
        let availableGBP = balance.availableGBP

        guard amount <= availableGBP else {
            throw FundingRepositoryError.insufficientFunds(available: availableGBP, requested: amount)
        }

        let request = FundingTransferRequest(
            amount: amount,
            currency: "GBP",
            notes: notes
        )

        let transfer: Transfer = try await apiClient.request(
            try Endpoints.InitiateWithdrawal(request: request)
        )

        // Add to cache
        cachedTransfers.insert(transfer, at: 0)

        // Invalidate balance cache
        cachedBalance = nil

        return transfer
    }

    func confirmWithdrawal(transferId: String, fxRate: Decimal) async throws -> Transfer {
        let request = FundingConfirmRequest(
            transferId: transferId,
            fxRate: fxRate
        )

        let transfer: Transfer = try await apiClient.request(
            try Endpoints.ConfirmWithdrawal(request: request)
        )

        // Update cache
        if let index = cachedTransfers.firstIndex(where: { $0.id == transferId }) {
            cachedTransfers[index] = transfer
        }

        // Invalidate balance cache
        cachedBalance = nil

        return transfer
    }

    // MARK: - Transfer Operations

    func fetchTransfer(id: String) async throws -> Transfer {
        // Check cache first
        if let cached = cachedTransfers.first(where: { $0.id == id }) {
            return cached
        }

        return try await apiClient.request(Endpoints.GetTransfer(id: id))
    }

    func cancelTransfer(id: String) async throws -> Transfer {
        // Check if transfer can be cancelled
        if let cached = cachedTransfers.first(where: { $0.id == id }) {
            guard cached.canCancel else {
                throw FundingRepositoryError.transferCannotBeCancelled
            }
        }

        let transfer: Transfer = try await apiClient.request(Endpoints.CancelTransfer(id: id))

        // Update cache
        if let index = cachedTransfers.firstIndex(where: { $0.id == id }) {
            cachedTransfers[index] = transfer
        }

        // Invalidate balance cache
        cachedBalance = nil

        return transfer
    }

    // MARK: - History Operations

    func fetchTransferHistory(page: Int, limit: Int) async throws -> PaginatedResponse<Transfer> {
        let response: PaginatedResponse<Transfer> = try await apiClient.request(
            Endpoints.GetTransferHistory(page: page, limit: limit)
        )

        // Update cache if fetching first page
        if page == 1 {
            cachedTransfers = response.data
            lastTransfersFetch = Date()
        }

        return response
    }

    func fetchTransferHistory(portfolioId: String, page: Int, limit: Int) async throws -> PaginatedResponse<Transfer> {
        let response: PaginatedResponse<Transfer> = try await apiClient.request(
            Endpoints.GetTransferHistory(portfolioId: portfolioId, page: page, limit: limit)
        )

        // Update cache if fetching first page
        if page == 1 {
            cachedTransfers = response.data
            lastTransfersFetch = Date()
        }

        return response
    }

    func fetchAllTransfers() async throws -> [Transfer] {
        // Check cache first
        if let lastFetch = lastTransfersFetch,
           Date().timeIntervalSince(lastFetch) < transfersCacheDuration,
           !cachedTransfers.isEmpty {
            return cachedTransfers
        }

        let response = try await fetchTransferHistory(page: 1, limit: Constants.API.maxPageSize)
        return response.data
    }

    func fetchTransfers(type: TransferType) async throws -> [Transfer] {
        let transfers = try await fetchAllTransfers()
        return transfers.filter { $0.type == type }
    }

    func fetchTransfers(status: TransferStatus) async throws -> [Transfer] {
        let transfers = try await fetchAllTransfers()
        return transfers.filter { $0.status == status }
    }

    func fetchPendingTransfers() async throws -> [Transfer] {
        let transfers = try await fetchAllTransfers()
        return transfers.filter { $0.status.isInProgress }
    }

    // MARK: - Summary Operations

    func fetchTransferSummary() async throws -> TransferHistory {
        let transfers = try await fetchAllTransfers()
        return TransferHistory(transfers: transfers)
    }

    // MARK: - Cache Operations

    func invalidateCache() async {
        cachedBalance = nil
        cachedFXRate = nil
        cachedTransfers = []
        lastBalanceFetch = nil
        lastTransfersFetch = nil
    }

    func prefetchFundingData() async throws {
        // Prefetch balance and transfers in parallel
        async let balanceTask: () = { let _ = try await self.fetchBalance() }()
        async let transfersTask: () = { let _ = try await self.fetchAllTransfers() }()
        async let fxRateTask: () = { let _ = try await self.fetchFXRate() }()

        _ = try await (balanceTask, transfersTask, fxRateTask)
    }
}

// MARK: - Request DTOs

struct FundingTransferRequest: Codable, Sendable {
    let amount: Decimal
    let currency: String
    let notes: String?
}

struct FundingConfirmRequest: Codable, Sendable {
    let transferId: String
    let fxRate: Decimal
}
