//
//  WebSocketModels.swift
//  Growfolio
//
//  Models and helpers for WebSocket messaging.
//

import Foundation

// MARK: - Message Types

enum WebSocketMessageType: String, Sendable {
    case event
    case system
    case ack
    case error
    case unknown
}

enum WebSocketChannel: String, CaseIterable, Sendable {
    case orders
    case positions
    case account
    case dca
    case transfers
    case fx
    case quotes
    case baskets
}

enum WebSocketEventName: String, CaseIterable, Sendable {
    case orderCreated = "order_created"
    case orderStatus = "order_status"
    case orderFill = "order_fill"
    case orderCancelled = "order_cancelled"
    case positionCreated = "position_created"
    case positionUpdated = "position_updated"
    case positionClosed = "position_closed"
    case cashChanged = "cash_changed"
    case buyingPowerChanged = "buying_power_changed"
    case accountStatusChanged = "account_status_changed"
    case dcaExecuted = "dca_executed"
    case dcaFailed = "dca_failed"
    case dcaStatusChanged = "dca_status_changed"
    case transferComplete = "transfer_complete"
    case transferFailed = "transfer_failed"
    case fxRateUpdated = "fx_rate_updated"
    case quoteUpdated = "quote_updated"
    case basketValueChanged = "basket_value_changed"
    case tokenExpiring = "token_expiring"
    case tokenRefreshed = "token_refreshed"
}

struct WebSocketIncomingMessage: Sendable {
    let id: String?
    let type: WebSocketMessageType
    let event: String?
    let timestamp: Date?
    let data: Data?

    static func decode(from text: String) throws -> WebSocketIncomingMessage {
        guard let payload = text.data(using: .utf8) else {
            throw WebSocketError.invalidMessage
        }

        let object = try JSONSerialization.jsonObject(with: payload)
        guard let dictionary = object as? [String: Any] else {
            throw WebSocketError.invalidMessage
        }

        let typeString = dictionary["type"] as? String ?? "unknown"
        let type = WebSocketMessageType(rawValue: typeString) ?? .unknown
        let event = dictionary["event"] as? String
        let id = dictionary["id"] as? String

        let timestampString = dictionary["timestamp"] as? String
        let timestamp = timestampString.flatMap { WebSocketDateParser.parse($0) }

        let dataObject = dictionary["data"]
        let data: Data?
        if let dataObject, !(dataObject is NSNull) {
            data = try? JSONSerialization.data(withJSONObject: dataObject)
        } else {
            data = nil
        }

        return WebSocketIncomingMessage(
            id: id,
            type: type,
            event: event,
            timestamp: timestamp,
            data: data
        )
    }

    func decodeData<T: Decodable>(
        _ type: T.Type,
        decoder: JSONDecoder = WebSocketDecoder.make()
    ) throws -> T {
        guard let data else {
            throw WebSocketError.missingData
        }
        return try decoder.decode(T.self, from: data)
    }
}

struct WebSocketEvent: Sendable {
    let id: String?
    let event: String
    let timestamp: Date?
    let data: Data?

    var name: WebSocketEventName? {
        WebSocketEventName(rawValue: event)
    }

    func decodeData<T: Decodable>(
        _ type: T.Type,
        decoder: JSONDecoder = WebSocketDecoder.make()
    ) throws -> T {
        guard let data else {
            throw WebSocketError.missingData
        }
        return try decoder.decode(T.self, from: data)
    }
}

struct WebSocketOutgoingMessage: Encodable, Sendable {
    let type: String
    let channels: [String]?
    let symbols: [String]?
    let token: String?

    static func subscribe(channels: [String], symbols: [String]? = nil) -> WebSocketOutgoingMessage {
        WebSocketOutgoingMessage(type: "subscribe", channels: channels, symbols: symbols, token: nil)
    }

    static func unsubscribe(channels: [String], symbols: [String]? = nil) -> WebSocketOutgoingMessage {
        WebSocketOutgoingMessage(type: "unsubscribe", channels: channels, symbols: symbols, token: nil)
    }

    static var pong: WebSocketOutgoingMessage {
        WebSocketOutgoingMessage(type: "pong", channels: nil, symbols: nil, token: nil)
    }

    static func refreshToken(_ token: String) -> WebSocketOutgoingMessage {
        WebSocketOutgoingMessage(type: "refresh_token", channels: nil, symbols: nil, token: token)
    }
}

// MARK: - Payloads

struct WebSocketSystemWelcomePayload: Decodable, Sendable {
    let connectionId: String
    let subscriptions: [String]
    let heartbeatInterval: Int

    enum CodingKeys: String, CodingKey {
        case connectionId = "connection_id"
        case subscriptions
        case heartbeatInterval = "heartbeat_interval"
    }
}

struct WebSocketQuoteUpdatePayload: Decodable, Sendable {
    let symbol: String
    let priceUsd: FlexibleDecimal
    let priceGbp: FlexibleDecimal?
    let bid: FlexibleDecimal?
    let ask: FlexibleDecimal?
    let changePercent: FlexibleDecimal?
    let fxRate: FlexibleDecimal?
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case symbol
        case priceUsd = "price_usd"
        case priceGbp = "price_gbp"
        case bid
        case ask
        case changePercent = "change_percent"
        case fxRate = "fx_rate"
        case timestamp
    }
}

struct WebSocketTokenExpiringPayload: Decodable, Sendable {
    let expiresInSeconds: FlexibleInt
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case expiresInSeconds = "expires_in_seconds"
        case expiresAt = "expires_at"
    }
}

struct WebSocketTokenRefreshedPayload: Decodable, Sendable {
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case expiresAt = "expires_at"
    }
}

struct WebSocketAckPayload: Decodable, Sendable {
    let action: String
    let channels: [String]
    let symbols: [String]?
}

struct WebSocketServerShutdownPayload: Decodable, Sendable {
    let message: String
}

struct WebSocketErrorPayload: Decodable, Sendable {
    let error: String
}

// MARK: - Flexible Decoding Helpers

struct FlexibleDecimal: Codable, Sendable {
    let value: Decimal

    init(_ value: Decimal) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let decimal = try? container.decode(Decimal.self) {
            value = decimal
            return
        }

        if let doubleValue = try? container.decode(Double.self) {
            value = Decimal(doubleValue)
            return
        }

        if let stringValue = try? container.decode(String.self),
           let decimal = Decimal(string: stringValue) {
            value = decimal
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Expected decimal or numeric string"
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(NSDecimalNumber(decimal: value).stringValue)
    }
}

struct FlexibleInt: Codable, Sendable {
    let value: Int

    init(_ value: Int) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
            return
        }

        if let stringValue = try? container.decode(String.self),
           let intValue = Int(stringValue) {
            value = intValue
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Expected int or numeric string"
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Decoder Helpers

enum WebSocketDecoder {
    static func make() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = WebSocketDateParser.parse(value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(value)"
            )
        }
        return decoder
    }
}

struct WebSocketDateParser {
    private static let isoFormatter = ISO8601DateFormatter()

    private static let microsecondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return formatter
    }()

    private static let millisecondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return formatter
    }()

    private static let secondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    static func parse(_ value: String) -> Date? {
        if let date = isoFormatter.date(from: value) {
            return date
        }
        if let date = microsecondsFormatter.date(from: value) {
            return date
        }
        if let date = millisecondsFormatter.date(from: value) {
            return date
        }
        if let date = secondsFormatter.date(from: value) {
            return date
        }
        return nil
    }
}

// MARK: - Errors

enum WebSocketError: LocalizedError, Sendable {
    case invalidMessage
    case missingData
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidMessage:
            return "The WebSocket message could not be parsed."
        case .missingData:
            return "The WebSocket message contained no data payload."
        case .invalidURL:
            return "The WebSocket URL is invalid."
        }
    }
}
