//
//  PositionsViewModel.swift
//  Growfolio
//
//  View model for position management and P&L tracking.
//

import Foundation
import SwiftUI

@Observable
final class PositionsViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Loading State
    var isLoading = false
    var isRefreshing = false
    var error: Error?
    var showError = false

    // Position Data
    var positions: [Position] = []
    var selectedPosition: Position?

    // Sort & Filter
    var sortOption: SortOption = .marketValue
    var filterSide: PositionSide?
    var showOnlyProfitable = false

    // View State
    var showPositionDetail = false
    var showHistorySheet = false

    // Repository
    private let positionRepository: PositionRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol

    // WebSocket Tasks
    nonisolated(unsafe) private var eventUpdatesTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var filteredPositions: [Position] {
        var filtered = positions

        if let side = filterSide {
            filtered = filtered.filter { $0.side == side }
        }

        if showOnlyProfitable {
            filtered = filtered.filter { $0.unrealizedPnlUsd > 0 }
        }

        return filtered.sorted { lhs, rhs in
            switch sortOption {
            case .marketValue:
                return lhs.marketValueUsd > rhs.marketValueUsd
            case .gainLoss:
                return lhs.unrealizedPnlUsd > rhs.unrealizedPnlUsd
            case .percentage:
                return lhs.changePct > rhs.changePct
            case .symbol:
                return lhs.symbol < rhs.symbol
            }
        }
    }

    var summary: PositionsSummary {
        PositionsSummary(positions: positions)
    }

    var totalMarketValueUsd: Decimal {
        summary.totalMarketValueUsd
    }

    var totalMarketValueGbp: Decimal {
        summary.totalMarketValueGbp
    }

    var totalUnrealizedPnlUsd: Decimal {
        summary.totalUnrealizedPnlUsd
    }

    var totalUnrealizedPnlGbp: Decimal {
        summary.totalUnrealizedPnlGbp
    }

    var overallReturnPercentage: Decimal {
        summary.overallReturnPercentage
    }

    var isProfitable: Bool {
        totalUnrealizedPnlUsd > 0
    }

    var profitablePositions: [Position] {
        positions.filter { $0.unrealizedPnlUsd > 0 }
    }

    var losingPositions: [Position] {
        positions.filter { $0.unrealizedPnlUsd < 0 }
    }

    var topGainers: [Position] {
        Array(positions.sorted { $0.unrealizedPnlUsd > $1.unrealizedPnlUsd }.prefix(5))
    }

    var topLosers: [Position] {
        Array(positions.sorted { $0.unrealizedPnlUsd < $1.unrealizedPnlUsd }.prefix(5))
    }

    var hasPositions: Bool {
        !positions.isEmpty
    }

    var isEmpty: Bool {
        positions.isEmpty && !isLoading
    }

    var allocationByPosition: [AllocationItem] {
        let total = positions.reduce(Decimal.zero) { $0 + $1.marketValueUsd }
        guard total > 0 else { return [] }

        return positions.map { position in
            AllocationItem(
                category: position.symbol,
                value: position.marketValueUsd,
                percentage: (position.marketValueUsd / total) * 100,
                colorHex: Color.chartColor(at: positions.firstIndex(where: { $0.symbol == position.symbol }) ?? 0).hexString ?? "#007AFF"
            )
        }.sorted { $0.percentage > $1.percentage }
    }

    // MARK: - Initialization

    nonisolated(unsafe) init(
        positionRepository: PositionRepositoryProtocol = RepositoryContainer.positionRepository,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.positionRepository = positionRepository
        if let webSocketService {
            self.webSocketService = webSocketService
        } else {
            self.webSocketService = MainActor.assumeIsolated { WebSocketService.shared }
        }
    }

    // MARK: - Data Loading

    @MainActor
    func loadPositions() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            positions = try await positionRepository.fetchPositions()

            // Start WebSocket updates after successful load
            await startRealtimeUpdates()
        } catch {
            self.error = error
            showError = true
            ToastManager.shared.showError(
                "Failed to load positions",
                actionTitle: "Retry"
            ) { [weak self] in
                guard let self else { return }
                Task { await self.loadPositions() }
            }
        }

        isLoading = false
    }

    @MainActor
    func refresh() async {
        guard !isRefreshing else { return }

        isRefreshing = true
        error = nil

        do {
            positions = try await positionRepository.fetchPositions()
        } catch {
            self.error = error
            ToastManager.shared.showError("Failed to refresh positions")
        }

        isRefreshing = false
    }

    @MainActor
    func loadPositionDetails(symbol: String) async {
        do {
            let position = try await positionRepository.fetchPosition(symbol: symbol)
            selectedPosition = position
            showPositionDetail = true
        } catch {
            ToastManager.shared.showError("Failed to load position details")
        }
    }

    // MARK: - Sorting & Filtering

    @MainActor
    func applySortOption(_ option: SortOption) {
        sortOption = option
    }

    @MainActor
    func applyFilterSide(_ side: PositionSide?) {
        filterSide = side
    }

    @MainActor
    func toggleProfitableFilter() {
        showOnlyProfitable.toggle()
    }

    // MARK: - WebSocket Real-Time Updates

    @MainActor
    func startRealtimeUpdates() async {
        // Subscribe to positions channel
        await webSocketService.subscribe(channels: [WebSocketChannel.positions.rawValue])

        // Start event listener
        startPositionUpdatesListener()
    }

    @MainActor
    func stopRealtimeUpdates() async {
        eventUpdatesTask?.cancel()
        eventUpdatesTask = nil

        await webSocketService.unsubscribe(channels: [WebSocketChannel.positions.rawValue])
    }

    @MainActor
    private func startPositionUpdatesListener() {
        guard eventUpdatesTask == nil else { return }

        eventUpdatesTask = Task { [weak self] in
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
        case .positionCreated:
            if let payload = try? event.decodeData(WebSocketPositionUpdatePayload.self) {
                handlePositionCreated(payload)
            }
        case .positionUpdated:
            if let payload = try? event.decodeData(WebSocketPositionUpdatePayload.self) {
                handlePositionUpdate(payload)
            }
        case .positionClosed:
            if let payload = try? event.decodeData(WebSocketPositionUpdatePayload.self) {
                handlePositionClosed(payload)
            }
        default:
            break
        }
    }

    @MainActor
    private func handlePositionCreated(_ payload: WebSocketPositionUpdatePayload) {
        let newPosition = Position(
            symbol: payload.symbol,
            quantity: payload.quantity.value,
            marketValueUsd: payload.marketValueUsd.value,
            marketValueGbp: payload.marketValueGbp.value,
            costBasis: payload.costBasis.value,
            unrealizedPnlUsd: payload.unrealizedPnlUsd.value,
            unrealizedPnlGbp: payload.unrealizedPnlGbp.value,
            averageEntryPrice: payload.averageEntryPrice.value,
            currentPrice: payload.currentPrice.value,
            changePct: payload.changePct.value,
            side: payload.side == "long" ? .long : .short,
            lastUpdated: Date()
        )

        if !positions.contains(where: { $0.symbol == newPosition.symbol }) {
            positions.append(newPosition)
            ToastManager.shared.showSuccess("🎉 New position: \(payload.symbol)")
        }
    }

    @MainActor
    private func handlePositionUpdate(_ payload: WebSocketPositionUpdatePayload) {
        if let index = positions.firstIndex(where: { $0.symbol == payload.symbol }) {
            let existingPosition = positions[index]
            let updatedPosition = Position(
                symbol: payload.symbol,
                quantity: payload.quantity.value,
                marketValueUsd: payload.marketValueUsd.value,
                marketValueGbp: payload.marketValueGbp.value,
                costBasis: payload.costBasis.value,
                unrealizedPnlUsd: payload.unrealizedPnlUsd.value,
                unrealizedPnlGbp: payload.unrealizedPnlGbp.value,
                averageEntryPrice: payload.averageEntryPrice.value,
                currentPrice: payload.currentPrice.value,
                changePct: payload.changePct.value,
                side: payload.side == "long" ? .long : .short,
                lastUpdated: Date()
            )
            positions[index] = updatedPosition

            // Show notification for significant P&L changes (>5%)
            let pnlChange = abs(updatedPosition.unrealizedPnlUsd - existingPosition.unrealizedPnlUsd)
            if pnlChange > existingPosition.marketValueUsd * 0.05 {
                let emoji = updatedPosition.unrealizedPnlUsd > existingPosition.unrealizedPnlUsd ? "📈" : "📉"
                ToastManager.shared.showInfo("\(emoji) \(payload.symbol) P&L updated")
            }
        }
    }

    @MainActor
    private func handlePositionClosed(_ payload: WebSocketPositionUpdatePayload) {
        if let index = positions.firstIndex(where: { $0.symbol == payload.symbol }) {
            let closedPosition = positions[index]
            positions.remove(at: index)

            let pnl = closedPosition.unrealizedPnlUsd
            let emoji = pnl > 0 ? "💰" : "📊"
            let message = pnl > 0
                ? "\(emoji) Position closed: \(payload.symbol) (+\(pnl.currencyString))"
                : "\(emoji) Position closed: \(payload.symbol) (\(pnl.currencyString))"

            ToastManager.shared.showInfo(message)
        }
    }

    deinit {
        eventUpdatesTask?.cancel()
    }
}

// MARK: - Supporting Types

extension PositionsViewModel {
    enum SortOption: String, CaseIterable, Identifiable {
        case marketValue = "Market Value"
        case gainLoss = "Gain/Loss"
        case percentage = "% Change"
        case symbol = "Symbol"

        var id: String { rawValue }
    }
}

// MARK: - Helper Extensions

private extension Decimal {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: self)) ?? "$0.00"
    }
}
