//
//  DCAViewModel.swift
//  Growfolio
//
//  View model for DCA schedules management.
//

import Foundation
import SwiftUI

@Observable
final class DCAViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Loading State
    var isLoading = false
    var isRefreshing = false
    var error: Error?

    // Schedules Data
    var schedules: [DCASchedule] = []
    var selectedSchedule: DCASchedule?

    // Filter State
    var showInactive = false
    var filterFrequency: DCAFrequency?
    var sortOrder: DCASortOrder = .nextExecution

    // Sheet Presentation
    var showCreateSchedule = false
    var showScheduleDetail = false
    var scheduleToEdit: DCASchedule?

    // Repository
    private let repository: DCARepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol

    // WebSocket Tasks
    nonisolated(unsafe) private var dcaUpdatesTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var filteredSchedules: [DCASchedule] {
        var filtered = schedules

        if !showInactive {
            filtered = filtered.filter { $0.status == .active || $0.status == .pendingFunds }
        }

        if let frequency = filterFrequency {
            filtered = filtered.filter { $0.frequency == frequency }
        }

        return sortSchedules(filtered, by: sortOrder)
    }

    var activeSchedulesCount: Int {
        schedules.filter { $0.status == .active }.count
    }

    var totalMonthlyInvestment: Decimal {
        schedules
            .filter { $0.status == .active }
            .reduce(Decimal.zero) { total, schedule in
                let monthlyEquivalent = schedule.amount * Decimal(schedule.frequency.executionsPerYear) / 12
                return total + monthlyEquivalent
            }
    }

    var summary: DCASummary {
        DCASummary(schedules: schedules)
    }

    var hasSchedules: Bool {
        !schedules.isEmpty
    }

    var isEmpty: Bool {
        filteredSchedules.isEmpty && !isLoading
    }

    var upcomingExecutions: [DCASchedule] {
        schedules
            .filter { $0.nextExecutionDate != nil && $0.status == .active }
            .sorted { ($0.nextExecutionDate ?? .distantFuture) < ($1.nextExecutionDate ?? .distantFuture) }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Initialization

    nonisolated(unsafe) init(
        repository: DCARepositoryProtocol = RepositoryContainer.dcaRepository,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.repository = repository
        if let webSocketService {
            self.webSocketService = webSocketService
        } else {
            self.webSocketService = MainActor.assumeIsolated { WebSocketService.shared }
        }
    }

    deinit {
        dcaUpdatesTask?.cancel()

        // Note: Cannot await in deinit, but WebSocketService handles cleanup internally
        // The unsubscribe will happen when the service is deallocated or connection closes
    }

    // MARK: - Data Loading

    @MainActor
    func loadSchedules() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            schedules = try await repository.fetchSchedules()

            // Start real-time DCA updates after successful data load
            await startDCAUpdates()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func refreshSchedules() async {
        isRefreshing = true
        await repository.invalidateCache()
        await loadSchedules()
        isRefreshing = false
    }

    func refresh() {
        Task { @MainActor in
            await refreshSchedules()
        }
    }

    // MARK: - CRUD Operations

    @MainActor
    func createSchedule(
        stockSymbol: String,
        amount: Decimal,
        frequency: DCAFrequency,
        startDate: Date,
        endDate: Date?,
        portfolioId: String
    ) async throws {
        let _ = try await repository.createSchedule(
            stockSymbol: stockSymbol,
            amount: amount,
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            portfolioId: portfolioId
        )

        await refreshSchedules()

        // Show success toast
        ToastManager.shared.showSuccess("DCA schedule for \(stockSymbol) created successfully!")
    }

    @MainActor
    func updateSchedule(_ schedule: DCASchedule) async throws {
        let _ = try await repository.updateSchedule(schedule)
        await refreshSchedules()

        // Show success toast
        ToastManager.shared.showSuccess("DCA schedule for \(schedule.stockSymbol) updated successfully!")
    }

    @MainActor
    func deleteSchedule(_ schedule: DCASchedule) async throws {
        try await repository.deleteSchedule(id: schedule.id)
        schedules.removeAll { $0.id == schedule.id }
    }

    @MainActor
    func pauseSchedule(_ schedule: DCASchedule) async throws {
        let _ = try await repository.pauseSchedule(id: schedule.id)
        await refreshSchedules()
    }

    @MainActor
    func resumeSchedule(_ schedule: DCASchedule) async throws {
        let _ = try await repository.resumeSchedule(id: schedule.id)
        await refreshSchedules()
    }

    // MARK: - Selection

    func selectSchedule(_ schedule: DCASchedule) {
        selectedSchedule = schedule
        showScheduleDetail = true
    }

    func editSchedule(_ schedule: DCASchedule) {
        scheduleToEdit = schedule
        showCreateSchedule = true
    }

    // MARK: - Sorting

    private func sortSchedules(_ schedules: [DCASchedule], by order: DCASortOrder) -> [DCASchedule] {
        switch order {
        case .nextExecution:
            return schedules.sorted { schedule1, schedule2 in
                guard let date1 = schedule1.nextExecutionDate else { return false }
                guard let date2 = schedule2.nextExecutionDate else { return true }
                return date1 < date2
            }
        case .symbol:
            return schedules.sorted { $0.stockSymbol < $1.stockSymbol }
        case .amount:
            return schedules.sorted { $0.amount > $1.amount }
        case .totalInvested:
            return schedules.sorted { $0.totalInvested > $1.totalInvested }
        case .createdAt:
            return schedules.sorted { $0.createdAt > $1.createdAt }
        }
    }

    // MARK: - WebSocket DCA Updates

    @MainActor
    private func startDCAUpdates() async {
        // Subscribe to DCA channel
        await webSocketService.subscribe(channels: [WebSocketChannel.dca.rawValue])

        // Start event listener
        startDCAUpdatesListener()
    }

    @MainActor
    private func startDCAUpdatesListener() {
        guard dcaUpdatesTask == nil else { return }

        dcaUpdatesTask = Task { [weak self] in
            guard let self else { return }

            let stream = await webSocketService.eventUpdates()
            for await event in stream {
                await MainActor.run {
                    self.handleWebSocketEvent(event)
                }
            }
        }
    }

    @MainActor
    private func handleWebSocketEvent(_ event: WebSocketEvent) {
        switch event.name {
        case .dcaExecuted:
            if let payload = try? event.decodeData(WebSocketDCAExecutionPayload.self) {
                handleDCAExecuted(payload)
            }
        case .dcaFailed:
            if let payload = try? event.decodeData(WebSocketDCAExecutionPayload.self) {
                handleDCAFailed(payload)
            }
        case .dcaStatusChanged:
            // Refresh schedules when status changes
            Task {
                await refreshSchedules()
            }
        default:
            break
        }
    }

    @MainActor
    private func handleDCAExecuted(_ payload: WebSocketDCAExecutionPayload) {
        // Show success notification
        let formattedAmount = payload.totalAmountGbp.value.formatted(.currency(code: "GBP"))
        ToastManager.shared.showSuccess(
            "DCA executed: \(payload.scheduleName) - \(formattedAmount) invested"
        )

        // Refresh schedules to show updated execution count and total invested
        Task {
            await refreshSchedules()
        }
    }

    @MainActor
    private func handleDCAFailed(_ payload: WebSocketDCAExecutionPayload) {
        // Show error notification with details
        let errorMessage = payload.errorMessage ?? "Unknown error"
        ToastManager.shared.showError(
            "DCA failed: \(payload.scheduleName) - \(errorMessage)"
        )

        // Refresh schedules to show updated status
        Task {
            await refreshSchedules()
        }
    }
}

// MARK: - DCA Sort Order

enum DCASortOrder: String, CaseIterable, Sendable {
    case nextExecution
    case symbol
    case amount
    case totalInvested
    case createdAt

    var displayName: String {
        switch self {
        case .nextExecution:
            return "Next Execution"
        case .symbol:
            return "Symbol"
        case .amount:
            return "Amount"
        case .totalInvested:
            return "Total Invested"
        case .createdAt:
            return "Date Created"
        }
    }

    var iconName: String {
        switch self {
        case .nextExecution:
            return "clock.fill"
        case .symbol:
            return "textformat.abc"
        case .amount:
            return "dollarsign.circle.fill"
        case .totalInvested:
            return "chart.bar.fill"
        case .createdAt:
            return "calendar"
        }
    }
}
