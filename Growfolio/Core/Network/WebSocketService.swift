//
//  WebSocketService.swift
//  Growfolio
//
//  High-level WebSocket service for real-time updates.
//

import Foundation
import Observation

@MainActor
protocol WebSocketServiceProtocol {
    func connect() async
    func disconnect() async
    func subscribe(channels: [String]) async
    func unsubscribe(channels: [String]) async
    func subscribeToQuotes(symbols: [String]) async
    func unsubscribeFromQuotes(symbols: [String]) async
    func quoteUpdates() -> AsyncStream<StockQuote>
    func eventUpdates() -> AsyncStream<WebSocketEvent>
    func ackUpdates() -> AsyncStream<WebSocketAckPayload>
}

@Observable
@MainActor
final class WebSocketService: @unchecked Sendable, WebSocketServiceProtocol {

    enum ConnectionState: String, Sendable {
        case disconnected
        case connecting
        case connected
    }

    static let shared = WebSocketService()

    private let client: WebSocketClientProtocol
    private let tokenProvider: WebSocketTokenProvider

    private var connectionTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempt = 0
    private var shouldReconnect = true

    private var quoteSymbolRefCounts: [String: Int] = [:]
    private var channelRefCounts: [String: Int] = [:]
    private var quoteContinuations: [UUID: AsyncStream<StockQuote>.Continuation] = [:]
    private var eventContinuations: [UUID: AsyncStream<WebSocketEvent>.Continuation] = [:]
    private var ackContinuations: [UUID: AsyncStream<WebSocketAckPayload>.Continuation] = [:]

    private(set) var connectionState: ConnectionState = .disconnected
    private(set) var lastError: Error?
    private(set) var connectionId: String?
    private(set) var heartbeatInterval: TimeInterval = 30
    private(set) var lastHeartbeatAt: Date?
    private(set) var serverSubscriptions: [String] = []
    private(set) var tokenExpiresAt: Date?
    private(set) var lastAck: WebSocketAckPayload?

    init(
        client: WebSocketClientProtocol = WebSocketClient(),
        tokenProvider: WebSocketTokenProvider? = nil
    ) {
        self.client = client
        self.tokenProvider = tokenProvider ?? WebSocketTokenProviderFactory.makeDefault()
        startEventLoop()
    }

    func connect() async {
        guard !MockConfiguration.shared.isEnabled else { return }
        guard connectionState != .connected && connectionState != .connecting else { return }

        shouldReconnect = true
        connectionState = .connecting

        await establishConnection()
    }

    func disconnect() async {
        shouldReconnect = false
        reconnectTask?.cancel()
        reconnectTask = nil

        await client.disconnect(closeCode: .normalClosure)
        connectionState = .disconnected
    }

    func subscribe(channels: [String]) async {
        let normalizedChannels = channels.map { $0.lowercased() }
        let newChannels = addChannels(normalizedChannels)
        guard !newChannels.isEmpty else { return }
        await sendSubscribe(channels: newChannels, symbols: nil)
    }

    func unsubscribe(channels: [String]) async {
        let normalizedChannels = channels.map { $0.lowercased() }
        let removedChannels = removeChannels(normalizedChannels)
        guard !removedChannels.isEmpty else { return }
        await sendUnsubscribe(channels: removedChannels, symbols: nil)
    }

    func subscribeToQuotes(symbols: [String]) async {
        let normalizedSymbols = symbols.map { $0.uppercased() }
        let newSymbols = addQuoteSymbols(normalizedSymbols)
        guard !newSymbols.isEmpty else { return }

        await sendSubscribe(channels: ["quotes"], symbols: newSymbols)
    }

    func unsubscribeFromQuotes(symbols: [String]) async {
        let normalizedSymbols = symbols.map { $0.uppercased() }
        let removedSymbols = removeQuoteSymbols(normalizedSymbols)
        guard !removedSymbols.isEmpty else { return }

        await sendUnsubscribe(channels: ["quotes"], symbols: removedSymbols)
    }

    func quoteUpdates() -> AsyncStream<StockQuote> {
        AsyncStream { continuation in
            let id = UUID()
            quoteContinuations[id] = continuation

            continuation.onTermination = { [weak self, id] _ in
                Task { @MainActor in
                    self?.quoteContinuations.removeValue(forKey: id)
                }
            }
        }
    }

    func eventUpdates() -> AsyncStream<WebSocketEvent> {
        AsyncStream { continuation in
            let id = UUID()
            eventContinuations[id] = continuation

            continuation.onTermination = { [weak self, id] _ in
                Task { @MainActor in
                    self?.eventContinuations.removeValue(forKey: id)
                }
            }
        }
    }

    func ackUpdates() -> AsyncStream<WebSocketAckPayload> {
        AsyncStream { continuation in
            let id = UUID()
            ackContinuations[id] = continuation

            continuation.onTermination = { [weak self, id] _ in
                Task { @MainActor in
                    self?.ackContinuations.removeValue(forKey: id)
                }
            }
        }
    }

    // MARK: - Private Connection Handling

    private func startEventLoop() {
        guard connectionTask == nil else { return }

        let events = client.events
        connectionTask = Task { [weak self] in
            for await event in events {
                await self?.handle(event)
            }
        }
    }

    private func establishConnection() async {
        do {
            let token = try await tokenProvider.validToken()
            let url = try buildWebSocketURL(token: token)
            await client.connect(url: url)
            connectionState = .connected
            reconnectAttempt = 0

            await resubscribeIfNeeded()
        } catch {
            lastError = error
            connectionState = .disconnected
            scheduleReconnect(closeCode: nil)
        }
    }

    // SECURITY NOTE: Tokens passed in URL query parameters may be logged by intermediate
    // servers, proxies, or the backend itself. Ensure the backend is configured to NOT log
    // query parameters containing authentication tokens to prevent credential exposure.
    private func buildWebSocketURL(token: String) throws -> URL {
        let baseURL = EnvironmentConfiguration.current.websocketURL
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw WebSocketError.invalidURL
        }

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "token", value: token))
        queryItems.append(URLQueryItem(name: "device_type", value: "ios"))
        queryItems.append(URLQueryItem(name: "app_version", value: Constants.App.version))
        components.queryItems = queryItems

        guard let url = components.url else {
            throw WebSocketError.invalidURL
        }

        return url
    }

    private func resubscribeIfNeeded() async {
        let channels = Array(channelRefCounts.keys)
        if !channels.isEmpty {
            await sendSubscribe(channels: channels, symbols: nil)
        }

        let symbols = Array(quoteSymbolRefCounts.keys)
        guard !symbols.isEmpty else { return }
        await sendSubscribe(channels: ["quotes"], symbols: symbols)
    }

    // MARK: - Event Handling

    private func handle(_ event: WebSocketClientEvent) async {
        switch event {
        case .message(let message):
            await handleIncomingMessage(message)
        case .disconnected(let closeCode):
            connectionState = .disconnected
            scheduleReconnect(closeCode: closeCode)
        }
    }

    private func handleIncomingMessage(_ message: WebSocketIncomingMessage) async {
        switch message.type {
        case .system:
            await handleSystemMessage(message)
        case .event:
            await handleEventMessage(message)
        case .error:
            await handleErrorMessage(message)
        case .ack:
            await handleAckMessage(message)
        case .unknown:
            break
        }
    }

    private func handleSystemMessage(_ message: WebSocketIncomingMessage) async {
        if message.event == "heartbeat" {
            lastHeartbeatAt = Date()
            await sendPong()
            return
        }

        if message.event == "server_shutdown" {
            scheduleReconnect(closeCode: nil)
            return
        }

        if message.event == nil,
           let payload = try? message.decodeData(WebSocketSystemWelcomePayload.self) {
            connectionId = payload.connectionId
            heartbeatInterval = TimeInterval(payload.heartbeatInterval)
            serverSubscriptions = payload.subscriptions
        }
    }

    private func handleEventMessage(_ message: WebSocketIncomingMessage) async {
        let eventName = message.event
        if let eventName {
            broadcastEvent(
                WebSocketEvent(
                    id: message.id,
                    event: eventName,
                    timestamp: message.timestamp,
                    data: message.data
                )
            )
        }

        switch message.event {
        case "quote_updated":
            if let payload = try? message.decodeData(WebSocketQuoteUpdatePayload.self) {
                let quote = payload.asStockQuote()
                broadcastQuote(quote)
            }
        case "token_expiring":
            if let payload = try? message.decodeData(WebSocketTokenExpiringPayload.self) {
                tokenExpiresAt = payload.expiresAt
            }
            await refreshToken()
        case "token_refreshed":
            if let payload = try? message.decodeData(WebSocketTokenRefreshedPayload.self) {
                tokenExpiresAt = payload.expiresAt
            }
        case "server_shutdown":
            scheduleReconnect(closeCode: nil)
        default:
            break
        }
    }

    private func handleErrorMessage(_ message: WebSocketIncomingMessage) async {
        if let payload = try? message.decodeData(WebSocketErrorPayload.self) {
            lastError = WebSocketServiceError.serverMessage(payload.error)
        }
    }

    private func handleAckMessage(_ message: WebSocketIncomingMessage) async {
        guard let payload = try? message.decodeData(WebSocketAckPayload.self) else {
            return
        }
        lastAck = payload
        for continuation in ackContinuations.values {
            continuation.yield(payload)
        }
    }

    // MARK: - Outgoing Messages

    private func sendSubscribe(channels: [String], symbols: [String]?) async {
        guard connectionState == .connected else { return }
        let message = WebSocketOutgoingMessage.subscribe(channels: channels, symbols: symbols)
        do {
            try await client.send(message)
        } catch {
            lastError = error
        }
    }

    private func sendUnsubscribe(channels: [String], symbols: [String]?) async {
        guard connectionState == .connected else { return }
        let message = WebSocketOutgoingMessage.unsubscribe(channels: channels, symbols: symbols)
        do {
            try await client.send(message)
        } catch {
            lastError = error
        }
    }

    private func sendPong() async {
        guard connectionState == .connected else { return }
        do {
            try await client.send(.pong)
        } catch {
            lastError = error
        }
    }

    private func refreshToken() async {
        do {
            let newToken = try await tokenProvider.refreshToken()
            do {
                try await client.send(.refreshToken(newToken))
            } catch {
                lastError = error
            }
        } catch {
            lastError = WebSocketServiceError.tokenRefreshFailed(error.localizedDescription)
            scheduleReconnect(closeCode: nil)
        }
    }

    // MARK: - Reconnect Strategy

    private enum WebSocketCloseCode: Int {
        case unauthorized = 4001
        case tokenExpired = 4002
        case userNotFound = 4003
        case accountInactive = 4004
        case rateLimited = 4005
        case serverShutdown = 4006
    }

    private func scheduleReconnect(closeCode: URLSessionWebSocketTask.CloseCode?) {
        guard shouldReconnect else { return }

        if let closeCode, let wsCloseCode = WebSocketCloseCode(rawValue: closeCode.rawValue) {
            switch wsCloseCode {
            case .userNotFound, .accountInactive:
                lastError = WebSocketServiceError.connectionClosed(code: closeCode.rawValue)
                shouldReconnect = false
                return
            case .rateLimited, .serverShutdown:
                lastError = WebSocketServiceError.connectionClosed(code: closeCode.rawValue)
            case .unauthorized, .tokenExpired:
                break
            }
        }

        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            guard let self else { return }

            if let closeCode, let wsCloseCode = WebSocketCloseCode(rawValue: closeCode.rawValue) {
                switch wsCloseCode {
                case .unauthorized, .tokenExpired:
                    _ = try? await tokenProvider.refreshToken()
                default:
                    break
                }
            }

            let delay = backoffDelay(for: reconnectAttempt)
            reconnectAttempt += 1
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            await establishConnection()
        }
    }

    private func backoffDelay(for attempt: Int) -> TimeInterval {
        let baseDelay: TimeInterval = 1
        let maxDelay: TimeInterval = 30
        let exponent = min(attempt, 5)
        let jitter = Double.random(in: 0...0.5)
        return min(maxDelay, baseDelay * pow(2, Double(exponent)) + jitter)
    }

    // MARK: - Quote Subscription Helpers

    private func addChannels(_ channels: [String]) -> [String] {
        var newChannels: [String] = []

        for channel in channels {
            let count = channelRefCounts[channel] ?? 0
            channelRefCounts[channel] = count + 1
            if count == 0 {
                newChannels.append(channel)
            }
        }

        return newChannels
    }

    private func removeChannels(_ channels: [String]) -> [String] {
        var removedChannels: [String] = []

        for channel in channels {
            let count = channelRefCounts[channel] ?? 0
            if count <= 1 {
                channelRefCounts.removeValue(forKey: channel)
                removedChannels.append(channel)
            } else {
                channelRefCounts[channel] = count - 1
            }
        }

        return removedChannels
    }

    private func addQuoteSymbols(_ symbols: [String]) -> [String] {
        var newSymbols: [String] = []

        for symbol in symbols {
            let count = quoteSymbolRefCounts[symbol] ?? 0
            quoteSymbolRefCounts[symbol] = count + 1
            if count == 0 {
                newSymbols.append(symbol)
            }
        }

        return newSymbols
    }

    private func removeQuoteSymbols(_ symbols: [String]) -> [String] {
        var removedSymbols: [String] = []

        for symbol in symbols {
            let count = quoteSymbolRefCounts[symbol] ?? 0
            if count <= 1 {
                quoteSymbolRefCounts.removeValue(forKey: symbol)
                removedSymbols.append(symbol)
            } else {
                quoteSymbolRefCounts[symbol] = count - 1
            }
        }

        return removedSymbols
    }

    private func broadcastQuote(_ quote: StockQuote) {
        for continuation in quoteContinuations.values {
            continuation.yield(quote)
        }
    }

    private func broadcastEvent(_ event: WebSocketEvent) {
        for continuation in eventContinuations.values {
            continuation.yield(event)
        }
    }
}

// MARK: - WebSocket Payload Mapping

private extension WebSocketQuoteUpdatePayload {
    func asStockQuote() -> StockQuote {
        let price = priceUsd.value
        let percent = changePercent?.value ?? 0
        let change = price.applying(percentage: percent)

        return StockQuote(
            symbol: symbol.uppercased(),
            price: price,
            change: change,
            changePercent: percent,
            volume: 0,
            timestamp: timestamp
        )
    }
}

// MARK: - Service Errors

enum WebSocketServiceError: LocalizedError, Sendable {
    case serverMessage(String)
    case tokenRefreshFailed(String)
    case connectionClosed(code: Int)

    var errorDescription: String? {
        switch self {
        case .serverMessage(let message):
            return message
        case .tokenRefreshFailed(let message):
            return "Token refresh failed: \(message)"
        case .connectionClosed(let code):
            switch code {
            case 4001:
                return "WebSocket unauthorized. Please sign in again."
            case 4002:
                return "WebSocket token expired. Please refresh authentication."
            case 4003:
                return "WebSocket user not found."
            case 4004:
                return "WebSocket account inactive."
            case 4005:
                return "WebSocket rate limited. Please retry later."
            case 4006:
                return "WebSocket server shutdown. Reconnecting..."
            default:
                return "WebSocket disconnected (code \(code))."
            }
        }
    }
}

// MARK: - Channel Convenience

extension WebSocketServiceProtocol {
    func subscribe(channels: [WebSocketChannel]) async {
        await subscribe(channels: channels.map { $0.rawValue })
    }

    func unsubscribe(channels: [WebSocketChannel]) async {
        await unsubscribe(channels: channels.map { $0.rawValue })
    }
}
