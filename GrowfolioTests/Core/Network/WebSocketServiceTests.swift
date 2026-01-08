//
//  WebSocketServiceTests.swift
//  GrowfolioTests
//
//  Tests for WebSocketService behavior.
//

import Foundation
import XCTest
@testable import Growfolio

@MainActor
final class WebSocketServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        MockConfiguration.shared.isEnabled = false
    }

    override func tearDown() {
        MockConfiguration.shared.reset()
        super.tearDown()
    }

    func testConnectBuildsWebSocketURLWithQueryItems() async throws {
        let client = MockWebSocketClient()
        let tokenProvider = MockTokenProvider(validTokenValue: "token-123", refreshTokenValue: "token-456")
        let service = WebSocketService(client: client, tokenProvider: tokenProvider)

        await service.connect()

        guard let url = client.connectedURL else {
            return XCTFail("Expected WebSocket URL to be set")
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []

        XCTAssertEqual(items.first { $0.name == "token" }?.value, "token-123")
        XCTAssertEqual(items.first { $0.name == "device_type" }?.value, "ios")
        XCTAssertEqual(items.first { $0.name == "app_version" }?.value, Constants.App.version)
    }

    func testHeartbeatSendsPong() async throws {
        let client = MockWebSocketClient()
        let tokenProvider = MockTokenProvider()
        let service = WebSocketService(client: client, tokenProvider: tokenProvider)

        let expectation = XCTestExpectation(description: "Pong message sent")
        client.onMessageSent = { message in
            if message.type == "pong" {
                expectation.fulfill()
            }
        }

        await service.connect()

        let json = """
        {
            "type": "system",
            "event": "heartbeat",
            "data": { "ping": true }
        }
        """
        let message = try WebSocketIncomingMessage.decode(from: json)
        client.emit(.message(message))

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertTrue(client.sentMessages.contains { $0.type == "pong" })
    }

    func testTokenExpiringTriggersRefreshTokenMessage() async throws {
        let client = MockWebSocketClient()
        let tokenProvider = MockTokenProvider(validTokenValue: "token-123", refreshTokenValue: "token-456")
        let service = WebSocketService(client: client, tokenProvider: tokenProvider)

        let expectation = XCTestExpectation(description: "Refresh token message sent")
        client.onMessageSent = { message in
            if message.type == "refresh_token" {
                expectation.fulfill()
            }
        }

        await service.connect()

        let json = """
        {
            "type": "event",
            "event": "token_expiring",
            "data": {
                "expires_in_seconds": 45,
                "expires_at": "2024-01-01T12:00:45.000000"
            }
        }
        """
        let message = try WebSocketIncomingMessage.decode(from: json)
        client.emit(.message(message))

        await fulfillment(of: [expectation], timeout: 1.0)

        let refreshMessage = client.sentMessages.first { $0.type == "refresh_token" }
        XCTAssertEqual(refreshMessage?.token, "token-456")
        XCTAssertEqual(tokenProvider.refreshTokenCallCount, 1)
    }

    func testAckUpdatesAreBroadcast() async throws {
        let client = MockWebSocketClient()
        let tokenProvider = MockTokenProvider()
        let service = WebSocketService(client: client, tokenProvider: tokenProvider)

        await service.connect()

        let expectation = XCTestExpectation(description: "Ack received")
        let stream = service.ackUpdates()
        var received: WebSocketAckPayload?

        let task = Task {
            for await payload in stream {
                received = payload
                expectation.fulfill()
                break
            }
        }

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
        client.emit(.message(message))

        await fulfillment(of: [expectation], timeout: 1.0)
        task.cancel()

        XCTAssertEqual(received?.action, "subscribed")
        XCTAssertEqual(service.lastAck?.action, "subscribed")
    }

    func testEventUpdatesBroadcastMessages() async throws {
        let client = MockWebSocketClient()
        let tokenProvider = MockTokenProvider()
        let service = WebSocketService(client: client, tokenProvider: tokenProvider)

        await service.connect()

        let expectation = XCTestExpectation(description: "Event received")
        let stream = service.eventUpdates()
        var received: WebSocketEvent?

        let task = Task {
            for await event in stream {
                received = event
                expectation.fulfill()
                break
            }
        }

        let json = """
        {
            "type": "event",
            "event": "transfer_complete",
            "data": { "id": "transfer-1" }
        }
        """
        let message = try WebSocketIncomingMessage.decode(from: json)
        client.emit(.message(message))

        await fulfillment(of: [expectation], timeout: 1.0)
        task.cancel()

        XCTAssertEqual(received?.event, "transfer_complete")
    }
}

// MARK: - Mocks

@MainActor
private final class MockTokenProvider: WebSocketTokenProvider, @unchecked Sendable {
    let tokenManager: TokenManager
    let validTokenValue: String
    let refreshTokenValue: String
    private(set) var validTokenCallCount = 0
    private(set) var refreshTokenCallCount = 0

    init(validTokenValue: String = "token", refreshTokenValue: String = "refresh") {
        self.tokenManager = TokenManager(keychain: KeychainWrapper(service: "test.websocket"))
        self.validTokenValue = validTokenValue
        self.refreshTokenValue = refreshTokenValue
    }

    func validToken() async throws -> String {
        validTokenCallCount += 1
        return validTokenValue
    }

    func refreshToken() async throws -> String {
        refreshTokenCallCount += 1
        return refreshTokenValue
    }
}

@MainActor
private final class MockWebSocketClient: @preconcurrency WebSocketClientProtocol, @unchecked Sendable {
    private let eventStream: AsyncStream<WebSocketClientEvent>
    private var continuation: AsyncStream<WebSocketClientEvent>.Continuation?

    private(set) var connectedURL: URL?
    private(set) var sentMessages: [WebSocketOutgoingMessage] = []
    private(set) var disconnectCodes: [URLSessionWebSocketTask.CloseCode] = []

    var onMessageSent: ((WebSocketOutgoingMessage) -> Void)?

    init() {
        var localContinuation: AsyncStream<WebSocketClientEvent>.Continuation?
        self.eventStream = AsyncStream { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation
    }

    var events: AsyncStream<WebSocketClientEvent> {
        eventStream
    }

    func connect(url: URL) async {
        connectedURL = url
    }

    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) async {
        disconnectCodes.append(closeCode)
    }

    func send(_ message: WebSocketOutgoingMessage) async throws {
        sentMessages.append(message)
        onMessageSent?(message)
    }

    func emit(_ event: WebSocketClientEvent) {
        continuation?.yield(event)
    }
}
