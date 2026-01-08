//
//  Order.swift
//  Growfolio
//
//  Domain model for stock orders.
//  Note: OrderSide, OrderType, OrderStatus, TimeInForce enums are defined in Stock.swift
//

import Foundation

// MARK: - Order Main Model

struct Order: Identifiable, Codable, Sendable, Equatable, Hashable {
    // MARK: - Properties
    let id: String
    let clientOrderId: String?
    let symbol: String
    let side: OrderSide
    let type: OrderType
    let status: OrderStatus
    let timeInForce: TimeInForce
    let quantity: Decimal?
    let notional: Decimal?
    let filledQuantity: Decimal?
    let filledAvgPrice: Decimal?
    let limitPrice: Decimal?
    let stopPrice: Decimal?
    let submittedAt: Date
    let filledAt: Date?
    let canceledAt: Date?
    let expiredAt: Date?

    // MARK: - Initialization
    init(
        id: String,
        clientOrderId: String? = nil,
        symbol: String,
        side: OrderSide,
        type: OrderType,
        status: OrderStatus,
        timeInForce: TimeInForce,
        quantity: Decimal? = nil,
        notional: Decimal? = nil,
        filledQuantity: Decimal? = nil,
        filledAvgPrice: Decimal? = nil,
        limitPrice: Decimal? = nil,
        stopPrice: Decimal? = nil,
        submittedAt: Date,
        filledAt: Date? = nil,
        canceledAt: Date? = nil,
        expiredAt: Date? = nil
    ) {
        self.id = id
        self.clientOrderId = clientOrderId
        self.symbol = symbol
        self.side = side
        self.type = type
        self.status = status
        self.timeInForce = timeInForce
        self.quantity = quantity
        self.notional = notional
        self.filledQuantity = filledQuantity
        self.filledAvgPrice = filledAvgPrice
        self.limitPrice = limitPrice
        self.stopPrice = stopPrice
        self.submittedAt = submittedAt
        self.filledAt = filledAt
        self.canceledAt = canceledAt
        self.expiredAt = expiredAt
    }

    // MARK: - Computed Properties

    var totalValue: Decimal? {
        guard let price = filledAvgPrice ?? limitPrice, let qty = quantity else { return nil }
        return qty * price
    }

    var displayName: String {
        let qtyString = quantity?.description ?? notional?.description ?? "unknown"
        let sideString = side == .buy ? "Buy" : "Sell"
        return "\(sideString) \(qtyString) \(symbol)"
    }

    var fillPercentage: Decimal {
        guard let total = quantity, let filled = filledQuantity, total > 0 else { return 0 }
        return (filled / total) * 100
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case clientOrderId = "client_order_id"
        case symbol
        case side
        case type
        case status
        case timeInForce = "time_in_force"
        case quantity
        case notional
        case filledQuantity = "filled_quantity"
        case filledAvgPrice = "filled_avg_price"
        case limitPrice = "limit_price"
        case stopPrice = "stop_price"
        case submittedAt = "submitted_at"
        case filledAt = "filled_at"
        case canceledAt = "canceled_at"
        case expiredAt = "expired_at"
    }
}
