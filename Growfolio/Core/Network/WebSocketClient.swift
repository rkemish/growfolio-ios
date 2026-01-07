//
//  WebSocketClient.swift
//  Growfolio
//
//  Low-level WebSocket client backed by URLSessionWebSocketTask.
//

import Foundation

protocol WebSocketClientProtocol: Sendable {
    var events: AsyncStream<WebSocketClientEvent> { get }
    func connect(url: URL) async
    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode) async
    func send(_ message: WebSocketOutgoingMessage) async throws
}

enum WebSocketClientEvent: Sendable {
    case message(WebSocketIncomingMessage)
    case disconnected(closeCode: URLSessionWebSocketTask.CloseCode?)
}

enum WebSocketClientError: LocalizedError, Sendable {
    case notConnected
    case invalidMessage

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "The WebSocket is not connected."
        case .invalidMessage:
            return "The WebSocket message could not be encoded."
        }
    }
}

actor WebSocketClient: WebSocketClientProtocol {

    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var readTask: Task<Void, Never>?

    private let eventStream: AsyncStream<WebSocketClientEvent>
    private let eventContinuation: AsyncStream<WebSocketClientEvent>.Continuation

    private(set) var isConnected = false

    init(configuration: URLSessionConfiguration = .default) {
        var continuation: AsyncStream<WebSocketClientEvent>.Continuation!
        self.eventStream = AsyncStream { streamContinuation in
            continuation = streamContinuation
        }
        self.eventContinuation = continuation
        self.session = URLSession(configuration: configuration)
    }

    nonisolated var events: AsyncStream<WebSocketClientEvent> {
        eventStream
    }

    func connect(url: URL) async {
        if isConnected {
            return
        }

        task?.cancel(with: .goingAway, reason: nil)

        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        isConnected = true

        startListening(on: task)
    }

    func disconnect(closeCode: URLSessionWebSocketTask.CloseCode = .normalClosure) async {
        isConnected = false
        readTask?.cancel()
        readTask = nil

        guard let task else { return }
        task.cancel(with: closeCode, reason: nil)
        self.task = nil
    }

    func send(_ message: WebSocketOutgoingMessage) async throws {
        guard let task else {
            throw WebSocketClientError.notConnected
        }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(message)

        guard let text = String(data: data, encoding: .utf8) else {
            throw WebSocketClientError.invalidMessage
        }

        try await task.send(.string(text))
    }

    private func startListening(on task: URLSessionWebSocketTask) {
        readTask?.cancel()
        readTask = Task { [weak self] in
            await self?.receiveLoop(task: task)
        }
    }

    private func receiveLoop(task: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                let text: String?

                switch message {
                case .string(let string):
                    text = string
                case .data(let data):
                    text = String(data: data, encoding: .utf8)
                @unknown default:
                    text = nil
                }

                guard let text else { continue }

                if let incoming = try? WebSocketIncomingMessage.decode(from: text) {
                    eventContinuation.yield(.message(incoming))
                }
            } catch {
                let closeCode = task.closeCode == .invalid ? nil : task.closeCode
                isConnected = false
                eventContinuation.yield(.disconnected(closeCode: closeCode))
                self.task = nil
                break
            }
        }
    }
}
