//
//  WebSocketModelsTests.swift
//  GrowfolioTests
//
//  Tests for WebSocket models and decoding helpers.
//

import XCTest
@testable import Growfolio

final class WebSocketModelsTests: XCTestCase {

    func testWebSocketIncomingMessageDecodesQuotePayloadWithStringNumbers() throws {
        let json = """
        {
            "type": "event",
            "event": "quote_updated",
            "timestamp": "2024-01-01T12:00:00.123456",
            "data": {
                "symbol": "AAPL",
                "price_usd": "123.45",
                "timestamp": "2024-01-01T12:00:00.123456"
            }
        }
        """

        let message = try WebSocketIncomingMessage.decode(from: json)
        XCTAssertEqual(message.type, .event)
        XCTAssertEqual(message.event, "quote_updated")
        XCTAssertNotNil(message.timestamp)

        let payload = try message.decodeData(WebSocketQuoteUpdatePayload.self)
        XCTAssertEqual(payload.symbol, "AAPL")
        XCTAssertEqual(NSDecimalNumber(decimal: payload.priceUsd.value).stringValue, "123.45")
        XCTAssertNotNil(payload.timestamp)
    }

    func testFlexibleDecimalDecodesStringAndNumber() throws {
        let stringJSON = "\"12.34\"".data(using: .utf8)!
        let numberJSON = "12.34".data(using: .utf8)!

        let stringValue = try JSONDecoder().decode(FlexibleDecimal.self, from: stringJSON)
        let numberValue = try JSONDecoder().decode(FlexibleDecimal.self, from: numberJSON)

        XCTAssertEqual(NSDecimalNumber(decimal: stringValue.value).stringValue, "12.34")
        XCTAssertEqual(NSDecimalNumber(decimal: numberValue.value).stringValue, "12.34")
    }

    func testWebSocketDateParserHandlesMicroseconds() throws {
        let date = WebSocketDateParser.parse("2024-01-01T12:00:00.123456")
        XCTAssertNotNil(date)
    }

    func testAckPayloadDecoding() throws {
        let json = """
        {
            "type": "ack",
            "data": {
                "action": "subscribed",
                "channels": ["quotes"],
                "symbols": ["AAPL"]
            }
        }
        """

        let message = try WebSocketIncomingMessage.decode(from: json)
        let payload = try message.decodeData(WebSocketAckPayload.self)

        XCTAssertEqual(payload.action, "subscribed")
        XCTAssertEqual(payload.channels, ["quotes"])
        XCTAssertEqual(payload.symbols, ["AAPL"])
    }
}
