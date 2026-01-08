//
//  OrdersViewModel.swift
//  Growfolio
//
//  View model for order management and history.
//

import Foundation
import SwiftUI

@Observable
final class OrdersViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Loading State
    var isLoading = false
    var isRefreshing = false
    var error: Error?
    var showError = false

    // Order Data
    var orders: [Order] = []
    var selectedOrder: Order?

    // Filters
    var selectedStatus: OrderStatus?
    var dateFilter: DateFilterOption = .all

    // View State
    var showOrderDetail = false
    var showCancelConfirmation = false
    var orderToCancel: Order?

    // Repository
    private let orderRepository: OrderRepositoryProtocol
    private let webSocketService: WebSocketServiceProtocol

    // WebSocket Tasks
    nonisolated(unsafe) private var eventUpdatesTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var filteredOrders: [Order] {
        var filtered = orders

        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }

        switch dateFilter {
        case .all:
            break
        case .today:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.submittedAt) }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            filtered = filtered.filter { $0.submittedAt >= weekAgo }
        case .thisMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            filtered = filtered.filter { $0.submittedAt >= monthAgo }
        }

        return filtered.sorted { $0.submittedAt > $1.submittedAt }
    }

    var activeOrders: [Order] {
        orders.filter { $0.status == .new || $0.status == .accepted || $0.status == .pendingNew || $0.status == .partiallyFilled }
    }

    var completedOrders: [Order] {
        orders.filter { $0.status == .filled }
    }

    var cancelledOrders: [Order] {
        orders.filter { $0.status == .cancelled }
    }

    var hasActiveOrders: Bool {
        !activeOrders.isEmpty
    }

    var isEmpty: Bool {
        orders.isEmpty && !isLoading
    }

    var totalOrderValue: Decimal {
        orders.reduce(Decimal.zero) { sum, order in
            sum + (order.totalValue ?? 0)
        }
    }

    // MARK: - Initialization

    nonisolated(unsafe) init(
        orderRepository: OrderRepositoryProtocol = RepositoryContainer.orderRepository,
        webSocketService: WebSocketServiceProtocol? = nil
    ) {
        self.orderRepository = orderRepository
        if let webSocketService {
            self.webSocketService = webSocketService
        } else {
            self.webSocketService = MainActor.assumeIsolated { WebSocketService.shared }
        }
    }

    // MARK: - Data Loading

    @MainActor
    func loadOrders() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            orders = try await orderRepository.fetchOrders(
                status: selectedStatus,
                limit: nil,
                after: nil,
                until: nil
            )

            // Start WebSocket updates after successful load
            await startRealtimeUpdates()
        } catch {
            self.error = error
            showError = true
            ToastManager.shared.showError(
                "Failed to load orders",
                actionTitle: "Retry"
            ) { [weak self] in
                guard let self else { return }
                Task { await self.loadOrders() }
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
            orders = try await orderRepository.fetchOrders(
                status: selectedStatus,
                limit: nil,
                after: nil,
                until: nil
            )
        } catch {
            self.error = error
            ToastManager.shared.showError("Failed to refresh orders")
        }

        isRefreshing = false
    }

    @MainActor
    func loadOrderDetails(id: String) async {
        do {
            let order = try await orderRepository.fetchOrder(id: id)
            selectedOrder = order
            showOrderDetail = true
        } catch {
            ToastManager.shared.showError("Failed to load order details")
        }
    }

    // MARK: - Actions

    @MainActor
    func cancelOrder(_ order: Order) async {
        guard order.status != .filled && order.status != .cancelled else {
            ToastManager.shared.showError("Cannot cancel this order")
            return
        }

        do {
            try await orderRepository.cancelOrder(id: order.id)

            // Update local state
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                var updatedOrder = order
                updatedOrder = Order(
                    id: updatedOrder.id,
                    clientOrderId: updatedOrder.clientOrderId,
                    symbol: updatedOrder.symbol,
                    side: updatedOrder.side,
                    type: updatedOrder.type,
                    status: .cancelled,
                    timeInForce: updatedOrder.timeInForce,
                    quantity: updatedOrder.quantity,
                    notional: updatedOrder.notional,
                    filledQuantity: updatedOrder.filledQuantity,
                    filledAvgPrice: updatedOrder.filledAvgPrice,
                    limitPrice: updatedOrder.limitPrice,
                    stopPrice: updatedOrder.stopPrice,
                    submittedAt: updatedOrder.submittedAt,
                    filledAt: updatedOrder.filledAt,
                    canceledAt: Date(),
                    expiredAt: updatedOrder.expiredAt
                )
                orders[index] = updatedOrder
            }

            ToastManager.shared.showSuccess("Order cancelled successfully")
            orderToCancel = nil
            showCancelConfirmation = false
        } catch {
            ToastManager.shared.showError(
                "Failed to cancel order",
                actionTitle: "Retry"
            ) { [weak self] in
                guard let self else { return }
                Task { await self.cancelOrder(order) }
            }
        }
    }

    @MainActor
    func confirmCancelOrder(_ order: Order) {
        orderToCancel = order
        showCancelConfirmation = true
    }

    @MainActor
    func applyStatusFilter(_ status: OrderStatus?) {
        selectedStatus = status
        Task {
            await refresh()
        }
    }

    @MainActor
    func applyDateFilter(_ filter: DateFilterOption) {
        dateFilter = filter
    }

    // MARK: - WebSocket Real-Time Updates

    @MainActor
    func startRealtimeUpdates() async {
        // Subscribe to orders channel
        await webSocketService.subscribe(channels: [WebSocketChannel.orders.rawValue])

        // Start event listener
        startOrderUpdatesListener()
    }

    @MainActor
    func stopRealtimeUpdates() async {
        eventUpdatesTask?.cancel()
        eventUpdatesTask = nil

        await webSocketService.unsubscribe(channels: [WebSocketChannel.orders.rawValue])
    }

    @MainActor
    private func startOrderUpdatesListener() {
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
        case .orderCreated:
            if let payload = try? event.decodeData(WebSocketOrderPayload.self) {
                handleOrderCreated(payload)
            }
        case .orderStatus:
            if let payload = try? event.decodeData(WebSocketOrderPayload.self) {
                handleOrderStatusUpdate(payload)
            }
        case .orderFill:
            if let payload = try? event.decodeData(WebSocketOrderFillPayload.self) {
                handleOrderFill(payload)
            }
        case .orderCancelled:
            if let payload = try? event.decodeData(WebSocketOrderPayload.self) {
                handleOrderCancelled(payload)
            }
        default:
            break
        }
    }

    @MainActor
    private func handleOrderCreated(_ payload: WebSocketOrderPayload) {
        // Add new order to the list
        let newOrder = Order(
            id: payload.orderId,
            clientOrderId: payload.clientOrderId,
            symbol: payload.symbol,
            side: payload.side.toOrderSide(),
            type: payload.type.toOrderType(),
            status: payload.status.toOrderStatus(),
            timeInForce: payload.timeInForce.toTimeInForce(),
            quantity: payload.quantity?.value,
            notional: payload.notional?.value,
            filledQuantity: payload.filledQty.value,
            filledAvgPrice: payload.filledAvgPrice?.value,
            limitPrice: payload.limitPrice?.value,
            stopPrice: payload.stopPrice?.value,
            submittedAt: payload.submittedAt,
            filledAt: payload.filledAt,
            canceledAt: payload.canceledAt,
            expiredAt: payload.expiredAt
        )

        if !orders.contains(where: { $0.id == newOrder.id }) {
            orders.insert(newOrder, at: 0)
            ToastManager.shared.showSuccess("New order: \(payload.side) \(payload.symbol)")
        }
    }

    @MainActor
    private func handleOrderStatusUpdate(_ payload: WebSocketOrderPayload) {
        if let index = orders.firstIndex(where: { $0.id == payload.orderId }) {
            var updatedOrder = orders[index]
            updatedOrder = Order(
                id: updatedOrder.id,
                clientOrderId: updatedOrder.clientOrderId,
                symbol: updatedOrder.symbol,
                side: updatedOrder.side,
                type: updatedOrder.type,
                status: payload.status.toOrderStatus(),
                timeInForce: updatedOrder.timeInForce,
                quantity: updatedOrder.quantity,
                notional: updatedOrder.notional,
                filledQuantity: payload.filledQty.value,
                filledAvgPrice: payload.filledAvgPrice?.value ?? updatedOrder.filledAvgPrice,
                limitPrice: updatedOrder.limitPrice,
                stopPrice: updatedOrder.stopPrice,
                submittedAt: updatedOrder.submittedAt,
                filledAt: updatedOrder.filledAt,
                canceledAt: updatedOrder.canceledAt,
                expiredAt: updatedOrder.expiredAt
            )
            orders[index] = updatedOrder
        }
    }

    @MainActor
    private func handleOrderFill(_ payload: WebSocketOrderFillPayload) {
        if let index = orders.firstIndex(where: { $0.id == payload.orderId }) {
            var updatedOrder = orders[index]
            updatedOrder = Order(
                id: updatedOrder.id,
                clientOrderId: updatedOrder.clientOrderId,
                symbol: updatedOrder.symbol,
                side: updatedOrder.side,
                type: updatedOrder.type,
                status: .filled,
                timeInForce: updatedOrder.timeInForce,
                quantity: updatedOrder.quantity,
                notional: updatedOrder.notional,
                filledQuantity: payload.filledQty.value,
                filledAvgPrice: payload.filledPrice.value,
                limitPrice: updatedOrder.limitPrice,
                stopPrice: updatedOrder.stopPrice,
                submittedAt: updatedOrder.submittedAt,
                filledAt: Date(),
                canceledAt: updatedOrder.canceledAt,
                expiredAt: updatedOrder.expiredAt
            )
            orders[index] = updatedOrder

            ToastManager.shared.showSuccess("✅ Order filled: \(updatedOrder.symbol)")
        }
    }

    @MainActor
    private func handleOrderCancelled(_ payload: WebSocketOrderPayload) {
        if let index = orders.firstIndex(where: { $0.id == payload.orderId }) {
            var updatedOrder = orders[index]
            updatedOrder = Order(
                id: updatedOrder.id,
                clientOrderId: updatedOrder.clientOrderId,
                symbol: updatedOrder.symbol,
                side: updatedOrder.side,
                type: updatedOrder.type,
                status: .cancelled,
                timeInForce: updatedOrder.timeInForce,
                quantity: updatedOrder.quantity,
                notional: updatedOrder.notional,
                filledQuantity: updatedOrder.filledQuantity,
                filledAvgPrice: updatedOrder.filledAvgPrice,
                limitPrice: updatedOrder.limitPrice,
                stopPrice: updatedOrder.stopPrice,
                submittedAt: updatedOrder.submittedAt,
                filledAt: updatedOrder.filledAt,
                canceledAt: Date(),
                expiredAt: updatedOrder.expiredAt
            )
            orders[index] = updatedOrder

            ToastManager.shared.showInfo("Order cancelled: \(updatedOrder.symbol)")
        }
    }

    deinit {
        eventUpdatesTask?.cancel()
    }
}

// MARK: - Supporting Types

extension OrdersViewModel {
    enum DateFilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"

        var id: String { rawValue }
    }
}

// MARK: - WebSocket Payload Conversions

private extension String {
    func toOrderSide() -> OrderSide {
        self.lowercased() == "buy" ? .buy : .sell
    }

    func toOrderType() -> OrderType {
        switch self.lowercased() {
        case "market": return .market
        case "limit": return .limit
        case "stop": return .stop
        case "stop_limit": return .stopLimit
        default: return .market
        }
    }

    func toOrderStatus() -> OrderStatus {
        switch self.lowercased() {
        case "new": return .new
        case "accepted": return .accepted
        case "pending_new": return .pendingNew
        case "filled": return .filled
        case "partially_filled": return .partiallyFilled
        case "canceled", "cancelled": return .cancelled
        case "expired": return .expired
        default: return .new
        }
    }

    func toTimeInForce() -> TimeInForce {
        switch self.lowercased() {
        case "day": return .day
        case "gtc": return .gtc
        case "ioc": return .ioc
        case "fok": return .fok
        case "opg": return .opg
        case "cls": return .cls
        default: return .day
        }
    }
}

