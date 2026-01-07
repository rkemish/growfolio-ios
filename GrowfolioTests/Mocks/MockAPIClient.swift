//
//  MockAPIClient.swift
//  GrowfolioTests
//
//  Mock API client for testing repositories.
//

import Foundation
@testable import Growfolio

/// Mock API client that returns predefined responses for testing
final class MockAPIClient: APIClientProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// Responses to return for specific endpoint types
    var responses: [String: Any] = [:]

    /// Errors to throw for specific endpoint types
    var errors: [String: Error] = [:]

    /// Track all requests made
    var requestsMade: [Any] = []

    /// Default error to throw if no response is configured
    var defaultError: Error?

    private let lock = NSLock()

    // MARK: - APIClientProtocol

    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        lock.lock()
        defer { lock.unlock() }

        requestsMade.append(endpoint)

        let key = String(describing: type(of: endpoint))

        if let error = errors[key] {
            throw error
        }

        if let response = responses[key] as? T {
            return response
        }

        if let error = defaultError {
            throw error
        }

        throw MockAPIError.noResponseConfigured(endpoint: key)
    }

    func request(_ endpoint: Endpoint) async throws {
        lock.lock()
        defer { lock.unlock() }

        requestsMade.append(endpoint)

        let key = String(describing: type(of: endpoint))

        if let error = errors[key] {
            throw error
        }
    }

    func requestData(_ endpoint: Endpoint) async throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        requestsMade.append(endpoint)

        let key = String(describing: type(of: endpoint))

        if let error = errors[key] {
            throw error
        }

        if let data = responses[key] as? Data {
            return data
        }

        return Data()
    }

    func upload<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        data: Data,
        fileName: String,
        mimeType: String
    ) async throws -> T {
        lock.lock()
        defer { lock.unlock() }

        requestsMade.append(endpoint)

        let key = String(describing: type(of: endpoint))

        if let error = errors[key] {
            throw error
        }

        if let response = responses[key] as? T {
            return response
        }

        throw MockAPIError.noResponseConfigured(endpoint: key)
    }

    // MARK: - Configuration Helpers

    func setResponse<T>(_ response: T, for endpointType: Any.Type) {
        let key = String(describing: endpointType)
        lock.lock()
        defer { lock.unlock() }
        responses[key] = response
    }

    func setError(_ error: Error, for endpointType: Any.Type) {
        let key = String(describing: endpointType)
        lock.lock()
        defer { lock.unlock() }
        errors[key] = error
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        responses.removeAll()
        errors.removeAll()
        requestsMade.removeAll()
        defaultError = nil
    }
}

// MARK: - Mock Error

enum MockAPIError: Error, LocalizedError {
    case noResponseConfigured(endpoint: String)

    var errorDescription: String? {
        switch self {
        case .noResponseConfigured(let endpoint):
            return "No response configured for endpoint: \(endpoint)"
        }
    }
}
