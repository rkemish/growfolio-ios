//
//  MockWebSocketService.swift
//  GrowfolioTests
//
//  Mock WebSocketService for testing WebSocket integration in ViewModels.
//

import Foundation
@testable import Growfolio

@MainActor
final class MockWebSocketService: WebSocketServiceProtocol {

    // MARK: - Properties

    var connectCalled = false
    var disconnectCalled = false
    var subscribedChannels: [String] = []
    var unsubscribedChannels: [String] = []
    var subscribedQuoteSymbols: [String] = []
    var unsubscribedQuoteSymbols: [String] = []

    // Continuations for streaming events
    private var eventContinuation: AsyncStream<WebSocketEvent>.Continuation?
    private var quoteContinuation: AsyncStream<StockQuote>.Continuation?
    private var ackContinuation: AsyncStream<WebSocketAckPayload>.Continuation?

    // MARK: - WebSocketServiceProtocol

    func connect() async {
        connectCalled = true
    }

    func disconnect() async {
        disconnectCalled = true
        eventContinuation?.finish()
        quoteContinuation?.finish()
        ackContinuation?.finish()
    }

    func subscribe(channels: [String]) async {
        subscribedChannels.append(contentsOf: channels)
    }

    func unsubscribe(channels: [String]) async {
        unsubscribedChannels.append(contentsOf: channels)
    }

    func subscribeToQuotes(symbols: [String]) async {
        subscribedQuoteSymbols.append(contentsOf: symbols)
    }

    func unsubscribeFromQuotes(symbols: [String]) async {
        unsubscribedQuoteSymbols.append(contentsOf: symbols)
    }

    func quoteUpdates() -> AsyncStream<StockQuote> {
        AsyncStream { continuation in
            self.quoteContinuation = continuation
        }
    }

    func eventUpdates() -> AsyncStream<WebSocketEvent> {
        AsyncStream { continuation in
            self.eventContinuation = continuation
        }
    }

    func ackUpdates() -> AsyncStream<WebSocketAckPayload> {
        AsyncStream { continuation in
            self.ackContinuation = continuation
        }
    }

    // MARK: - Test Helpers

    /// Simulate sending an event to subscribers
    func sendEvent(_ event: WebSocketEvent) {
        eventContinuation?.yield(event)
    }

    /// Simulate sending a quote update to subscribers
    func sendQuote(_ quote: StockQuote) {
        quoteContinuation?.yield(quote)
    }

    /// Simulate sending an acknowledgment to subscribers
    func sendAck(_ ack: WebSocketAckPayload) {
        ackContinuation?.yield(ack)
    }

    /// Reset all tracking properties
    func reset() {
        connectCalled = false
        disconnectCalled = false
        subscribedChannels = []
        unsubscribedChannels = []
        subscribedQuoteSymbols = []
        unsubscribedQuoteSymbols = []
    }

    /// Create a position update event
    static func makePositionUpdateEvent(
        symbol: String,
        quantity: Decimal,
        marketValueUsd: Decimal,
        marketValueGbp: Decimal,
        unrealizedPnlUsd: Decimal,
        unrealizedPnlGbp: Decimal,
        changePct: Decimal? = nil
    ) -> WebSocketEvent {
        let json: [String: Any] = [
            "symbol": symbol,
            "quantity": NSDecimalNumber(decimal: quantity).doubleValue,
            "market_value_usd": NSDecimalNumber(decimal: marketValueUsd).doubleValue,
            "market_value_gbp": NSDecimalNumber(decimal: marketValueGbp).doubleValue,
            "unrealized_pnl_usd": NSDecimalNumber(decimal: unrealizedPnlUsd).doubleValue,
            "unrealized_pnl_gbp": NSDecimalNumber(decimal: unrealizedPnlGbp).doubleValue,
            "change_pct": changePct.map { NSDecimalNumber(decimal: $0).doubleValue } as Any
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.positionUpdated.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create an account update event
    static func makeAccountUpdateEvent(
        cashUsd: Decimal,
        cashGbp: Decimal,
        buyingPowerUsd: Decimal,
        portfolioValueUsd: Decimal,
        portfolioValueGbp: Decimal
    ) -> WebSocketEvent {
        let json: [String: Any] = [
            "cash_usd": NSDecimalNumber(decimal: cashUsd).doubleValue,
            "cash_gbp": NSDecimalNumber(decimal: cashGbp).doubleValue,
            "buying_power_usd": NSDecimalNumber(decimal: buyingPowerUsd).doubleValue,
            "portfolio_value_usd": NSDecimalNumber(decimal: portfolioValueUsd).doubleValue,
            "portfolio_value_gbp": NSDecimalNumber(decimal: portfolioValueGbp).doubleValue
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.cashChanged.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create an FX rate update event
    static func makeFXRateUpdateEvent(
        pair: String = "GBP/USD",
        rate: Decimal,
        previousRate: Decimal? = nil,
        changePct: Decimal? = nil
    ) -> WebSocketEvent {
        var json: [String: Any] = [
            "pair": pair,
            "rate": NSDecimalNumber(decimal: rate).doubleValue
        ]

        if let previousRate {
            json["previous_rate"] = NSDecimalNumber(decimal: previousRate).doubleValue
        }
        if let changePct {
            json["change_pct"] = NSDecimalNumber(decimal: changePct).doubleValue
        }

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.fxRateUpdated.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create a transfer complete event
    static func makeTransferCompleteEvent(transferId: String) -> WebSocketEvent {
        let json: [String: Any] = [
            "transfer_id": transferId,
            "direction": "deposit",
            "amount": 1000,
            "currency": "GBP",
            "status": "completed"
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.transferComplete.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create an order created event
    static func makeOrderCreatedEvent(
        orderId: String,
        symbol: String,
        side: String = "buy",
        type: String = "market",
        status: String = "new",
        quantity: Decimal? = 10,
        submittedAt: Date = Date()
    ) -> WebSocketEvent {
        var json: [String: Any] = [
            "order_id": orderId,
            "symbol": symbol,
            "side": side,
            "type": type,
            "status": status,
            "time_in_force": "day",
            "filled_qty": 0,
            "submitted_at": ISO8601DateFormatter().string(from: submittedAt)
        ]

        if let quantity {
            json["qty"] = NSDecimalNumber(decimal: quantity).doubleValue
        }

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.orderCreated.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create an order status event
    static func makeOrderStatusEvent(
        orderId: String,
        symbol: String,
        side: String = "buy",
        type: String = "market",
        status: String,
        quantity: Decimal = 10,
        filledQty: Decimal = 0,
        submittedAt: Date = Date()
    ) -> WebSocketEvent {
        let json: [String: Any] = [
            "order_id": orderId,
            "symbol": symbol,
            "side": side,
            "type": type,
            "status": status,
            "time_in_force": "day",
            "qty": NSDecimalNumber(decimal: quantity).doubleValue,
            "filled_qty": NSDecimalNumber(decimal: filledQty).doubleValue,
            "submitted_at": ISO8601DateFormatter().string(from: submittedAt)
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.orderStatus.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create an order fill event
    static func makeOrderFillEvent(
        orderId: String,
        symbol: String,
        side: String = "buy",
        type: String = "market",
        status: String = "filled",
        quantity: Decimal = 10,
        filledQty: Decimal = 10,
        filledAvgPrice: Decimal = 150.50,
        submittedAt: Date = Date(),
        filledAt: Date = Date()
    ) -> WebSocketEvent {
        let json: [String: Any] = [
            "order_id": orderId,
            "symbol": symbol,
            "side": side,
            "type": type,
            "status": status,
            "time_in_force": "day",
            "qty": NSDecimalNumber(decimal: quantity).doubleValue,
            "filled_qty": NSDecimalNumber(decimal: filledQty).doubleValue,
            "filled_avg_price": NSDecimalNumber(decimal: filledAvgPrice).doubleValue,
            "submitted_at": ISO8601DateFormatter().string(from: submittedAt),
            "filled_at": ISO8601DateFormatter().string(from: filledAt)
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.orderFill.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create an order cancelled event
    static func makeOrderCancelledEvent(
        orderId: String,
        symbol: String,
        side: String = "buy",
        type: String = "market",
        status: String = "canceled",
        quantity: Decimal = 10,
        submittedAt: Date = Date(),
        canceledAt: Date = Date()
    ) -> WebSocketEvent {
        let json: [String: Any] = [
            "order_id": orderId,
            "symbol": symbol,
            "side": side,
            "type": type,
            "status": status,
            "time_in_force": "day",
            "qty": NSDecimalNumber(decimal: quantity).doubleValue,
            "filled_qty": 0,
            "submitted_at": ISO8601DateFormatter().string(from: submittedAt),
            "canceled_at": ISO8601DateFormatter().string(from: canceledAt)
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.orderCancelled.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create a DCA executed event
    static func makeDCAExecutedEvent(
        scheduleId: String,
        scheduleName: String,
        basketId: String = "basket-123",
        totalAmountGbp: Decimal = 100,
        totalAmountUsd: Decimal = 127,
        status: String = "success"
    ) -> WebSocketEvent {
        let json: [String: Any] = [
            "schedule_id": scheduleId,
            "schedule_name": scheduleName,
            "basket_id": basketId,
            "total_amount_gbp": NSDecimalNumber(decimal: totalAmountGbp).doubleValue,
            "total_amount_usd": NSDecimalNumber(decimal: totalAmountUsd).doubleValue,
            "status": status,
            "orders": [
                [
                    "symbol": "AAPL",
                    "amount_usd": 63.5,
                    "status": "filled"
                ],
                [
                    "symbol": "MSFT",
                    "amount_usd": 63.5,
                    "status": "filled"
                ]
            ]
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.dcaExecuted.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create a DCA failed event
    static func makeDCAFailedEvent(
        scheduleId: String,
        scheduleName: String,
        basketId: String = "basket-123",
        totalAmountGbp: Decimal = 100,
        errorMessage: String = "Insufficient funds"
    ) -> WebSocketEvent {
        let json: [String: Any] = [
            "schedule_id": scheduleId,
            "schedule_name": scheduleName,
            "basket_id": basketId,
            "total_amount_gbp": NSDecimalNumber(decimal: totalAmountGbp).doubleValue,
            "total_amount_usd": 0,
            "status": "failed",
            "orders": [[String: Any]](),
            "error_message": errorMessage
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.dcaFailed.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create a position created event
    static func makePositionCreatedEvent(
        symbol: String,
        quantity: Decimal,
        marketValueUsd: Decimal,
        marketValueGbp: Decimal,
        unrealizedPnlUsd: Decimal = 0,
        unrealizedPnlGbp: Decimal = 0
    ) -> WebSocketEvent {
        let json: [String: Any] = [
            "symbol": symbol,
            "quantity": NSDecimalNumber(decimal: quantity).doubleValue,
            "market_value_usd": NSDecimalNumber(decimal: marketValueUsd).doubleValue,
            "market_value_gbp": NSDecimalNumber(decimal: marketValueGbp).doubleValue,
            "unrealized_pnl_usd": NSDecimalNumber(decimal: unrealizedPnlUsd).doubleValue,
            "unrealized_pnl_gbp": NSDecimalNumber(decimal: unrealizedPnlGbp).doubleValue
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.positionCreated.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create a position closed event
    static func makePositionClosedEvent(
        symbol: String,
        quantity: Decimal = 0,
        marketValueUsd: Decimal = 0,
        marketValueGbp: Decimal = 0,
        unrealizedPnlUsd: Decimal,
        unrealizedPnlGbp: Decimal
    ) -> WebSocketEvent {
        let json: [String: Any] = [
            "symbol": symbol,
            "quantity": NSDecimalNumber(decimal: quantity).doubleValue,
            "market_value_usd": NSDecimalNumber(decimal: marketValueUsd).doubleValue,
            "market_value_gbp": NSDecimalNumber(decimal: marketValueGbp).doubleValue,
            "unrealized_pnl_usd": NSDecimalNumber(decimal: unrealizedPnlUsd).doubleValue,
            "unrealized_pnl_gbp": NSDecimalNumber(decimal: unrealizedPnlGbp).doubleValue
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.positionClosed.rawValue,
            timestamp: Date(),
            data: data
        )
    }

    /// Create a basket value changed event
    static func makeBasketValueChangedEvent(
        basketId: String,
        currentValue: Decimal,
        totalInvested: Decimal,
        totalGainLoss: Decimal,
        changePct: Decimal? = nil
    ) -> WebSocketEvent {
        var json: [String: Any] = [
            "basket_id": basketId,
            "current_value": NSDecimalNumber(decimal: currentValue).doubleValue,
            "total_invested": NSDecimalNumber(decimal: totalInvested).doubleValue,
            "total_gain_loss": NSDecimalNumber(decimal: totalGainLoss).doubleValue
        ]

        if let changePct {
            json["change_pct"] = NSDecimalNumber(decimal: changePct).doubleValue
        }

        let data = try! JSONSerialization.data(withJSONObject: json)
        return WebSocketEvent(
            id: UUID().uuidString,
            event: WebSocketEventName.basketValueChanged.rawValue,
            timestamp: Date(),
            data: data
        )
    }
}
