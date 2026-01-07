//
//  FundingViewModel.swift
//  Growfolio
//
//  View model for funding operations (deposits and withdrawals).
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class FundingViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Loading State
    var isLoading = false
    var isRefreshing = false
    var isSubmitting = false
    var error: Error?

    // Balance Data
    var balance: FundingBalance?
    var fxRate: FXRate?

    // Transfer Data
    var transfers: [Transfer] = []
    var selectedTransfer: Transfer?
    var transferHistory: TransferHistory?

    // Form State
    var depositAmount: String = ""
    var withdrawalAmount: String = ""
    var notes: String = ""

    // Sheet Presentation
    var showDeposit = false
    var showWithdrawal = false
    var showTransferHistory = false
    var showTransferDetail = false
    var showConfirmation = false

    // Confirmation State
    var pendingTransfer: Transfer?
    var confirmedFXRate: Decimal?

    // Filter State
    var filterType: TransferType?
    var filterStatus: TransferStatus?

    // Repository
    private let repository: FundingRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol
    nonisolated(unsafe) private var transferUpdatesTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var availableBalanceUSD: Decimal {
        balance?.availableUSD ?? 0
    }

    var availableBalanceGBP: Decimal {
        balance?.availableGBP ?? 0
    }

    var currentFXRate: Decimal {
        fxRate?.rate ?? 0
    }

    var effectiveFXRate: Decimal {
        fxRate?.effectiveRate ?? 0
    }

    var fxRateDisplayString: String {
        fxRate?.displayString ?? "Rate unavailable"
    }

    var isFXRateValid: Bool {
        fxRate?.isValid ?? false
    }

    /// Parsed deposit amount
    var depositAmountValue: Decimal? {
        Decimal(string: depositAmount.replacingOccurrences(of: ",", with: ""))
    }

    /// Parsed withdrawal amount
    var withdrawalAmountValue: Decimal? {
        Decimal(string: withdrawalAmount.replacingOccurrences(of: ",", with: ""))
    }

    /// Converted USD amount for deposit
    var depositConvertedUSD: Decimal {
        guard let amount = depositAmountValue, let rate = fxRate else { return 0 }
        return rate.convert(amount)
    }

    /// Converted USD amount for withdrawal
    var withdrawalConvertedUSD: Decimal {
        guard let amount = withdrawalAmountValue, let rate = fxRate else { return 0 }
        return rate.convert(amount)
    }

    /// Whether deposit form is valid
    var canDeposit: Bool {
        guard let amount = depositAmountValue else { return false }
        return amount > 0 && isFXRateValid
    }

    /// Whether withdrawal form is valid
    var canWithdraw: Bool {
        guard let amount = withdrawalAmountValue else { return false }
        return amount > 0 && amount <= availableBalanceGBP && isFXRateValid
    }

    /// Filtered transfers
    var filteredTransfers: [Transfer] {
        var result = transfers

        if let type = filterType {
            result = result.filter { $0.type == type }
        }

        if let status = filterStatus {
            result = result.filter { $0.status == status }
        }

        return result
    }

    /// Grouped transfers by date
    var groupedTransfers: [TransferGroup] {
        filteredTransfers.groupedByDate()
    }

    /// Pending transfers
    var pendingTransfers: [Transfer] {
        transfers.filter { $0.status.isInProgress }
    }

    /// Recent transfers (last 5)
    var recentTransfers: [Transfer] {
        Array(transfers.prefix(5))
    }

    /// Whether there are any transfers
    var hasTransfers: Bool {
        !transfers.isEmpty
    }

    /// Whether balance has pending transactions
    var hasPendingBalance: Bool {
        balance?.hasPendingTransactions ?? false
    }

    // MARK: - Initialization

    init(
        repository: FundingRepositoryProtocol = RepositoryContainer.fundingRepository,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.repository = repository
        if let webSocketService {
            self.webSocketService = webSocketService
        } else {
            self.webSocketService = WebSocketService.shared
        }
    }

    deinit {
        transferUpdatesTask?.cancel()
    }

    // MARK: - Data Loading

    @MainActor
    func loadFundingData() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Load balance, FX rate, and transfers in parallel
            async let balanceTask = repository.fetchBalance()
            async let fxRateTask = repository.fetchFXRate()
            async let transfersTask = repository.fetchAllTransfers()

            let (fetchedBalance, fetchedRate, fetchedTransfers) = try await (
                balanceTask,
                fxRateTask,
                transfersTask
            )

            balance = fetchedBalance
            fxRate = fetchedRate
            transfers = fetchedTransfers
            transferHistory = TransferHistory(transfers: fetchedTransfers)
        } catch {
            self.error = error
        }

        isLoading = false

        startTransferUpdatesIfNeeded()
    }

    @MainActor
    func refreshFundingData() async {
        isRefreshing = true
        await repository.invalidateCache()
        await loadFundingData()
        isRefreshing = false
    }

    func refresh() {
        Task { @MainActor in
            await refreshFundingData()
        }
    }

    @MainActor
    func refreshFXRate() async {
        do {
            fxRate = try await repository.fetchFXRate()
        } catch {
            self.error = error
        }
    }

    @MainActor
    private func startTransferUpdatesIfNeeded() {
        guard transferUpdatesTask == nil else { return }

        transferUpdatesTask = Task { [weak self] in
            guard let self else { return }

            await webSocketService.subscribe(channels: [.transfers])

            let stream = await webSocketService.eventUpdates()
            for await event in stream {
                guard event.name == .transferComplete || event.name == .transferFailed else { continue }
                await refreshFundingData()
            }
        }
    }

    // MARK: - Deposit Operations

    @MainActor
    func initiateDeposit() async throws -> Transfer {
        guard let amount = depositAmountValue else {
            throw FundingRepositoryError.invalidAmount
        }

        isSubmitting = true
        error = nil

        do {
            let transfer = try await repository.initiateDeposit(
                amount: amount,
                notes: notes.isEmpty ? nil : notes
            )

            // Store for confirmation
            pendingTransfer = transfer
            confirmedFXRate = effectiveFXRate

            isSubmitting = false
            return transfer
        } catch {
            isSubmitting = false
            self.error = error
            throw error
        }
    }

    @MainActor
    func confirmDeposit() async throws {
        guard let transfer = pendingTransfer,
              let rate = confirmedFXRate else {
            throw FundingRepositoryError.invalidAmount
        }

        isSubmitting = true
        error = nil

        do {
            let _ = try await repository.confirmDeposit(
                transferId: transfer.id,
                fxRate: rate
            )

            // Reset form
            resetDepositForm()

            // Refresh data
            await refreshFundingData()

            isSubmitting = false
        } catch {
            isSubmitting = false
            self.error = error
            throw error
        }
    }

    // MARK: - Withdrawal Operations

    @MainActor
    func initiateWithdrawal() async throws -> Transfer {
        guard let amount = withdrawalAmountValue else {
            throw FundingRepositoryError.invalidAmount
        }

        isSubmitting = true
        error = nil

        do {
            let transfer = try await repository.initiateWithdrawal(
                amount: amount,
                notes: notes.isEmpty ? nil : notes
            )

            // Store for confirmation
            pendingTransfer = transfer
            confirmedFXRate = effectiveFXRate

            isSubmitting = false
            return transfer
        } catch {
            isSubmitting = false
            self.error = error
            throw error
        }
    }

    @MainActor
    func confirmWithdrawal() async throws {
        guard let transfer = pendingTransfer,
              let rate = confirmedFXRate else {
            throw FundingRepositoryError.invalidAmount
        }

        isSubmitting = true
        error = nil

        do {
            let _ = try await repository.confirmWithdrawal(
                transferId: transfer.id,
                fxRate: rate
            )

            // Reset form
            resetWithdrawalForm()

            // Refresh data
            await refreshFundingData()

            isSubmitting = false
        } catch {
            isSubmitting = false
            self.error = error
            throw error
        }
    }

    // MARK: - Transfer Operations

    @MainActor
    func cancelTransfer(_ transfer: Transfer) async throws {
        guard transfer.canCancel else {
            throw FundingRepositoryError.transferCannotBeCancelled
        }

        do {
            let _ = try await repository.cancelTransfer(id: transfer.id)
            await refreshFundingData()
        } catch {
            self.error = error
            throw error
        }
    }

    func selectTransfer(_ transfer: Transfer) {
        selectedTransfer = transfer
        showTransferDetail = true
    }

    // MARK: - Form Management

    func resetDepositForm() {
        depositAmount = ""
        notes = ""
        pendingTransfer = nil
        confirmedFXRate = nil
        showConfirmation = false
    }

    func resetWithdrawalForm() {
        withdrawalAmount = ""
        notes = ""
        pendingTransfer = nil
        confirmedFXRate = nil
        showConfirmation = false
    }

    func setMaxWithdrawal() {
        withdrawalAmount = "\(availableBalanceGBP)"
    }

    // MARK: - Filter Management

    func clearFilters() {
        filterType = nil
        filterStatus = nil
    }

    func setFilter(type: TransferType?) {
        filterType = type
    }

    func setFilter(status: TransferStatus?) {
        filterStatus = status
    }

    // MARK: - Presentation

    func presentDeposit() {
        resetDepositForm()
        showDeposit = true
    }

    func presentWithdrawal() {
        resetWithdrawalForm()
        showWithdrawal = true
    }

    func presentTransferHistory() {
        showTransferHistory = true
    }

    func dismissDeposit() {
        showDeposit = false
        resetDepositForm()
    }

    func dismissWithdrawal() {
        showWithdrawal = false
        resetWithdrawalForm()
    }
}
