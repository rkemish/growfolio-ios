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

    // Thread-safe access using os_unfair_lock for async-compatible locking
    private var _lock = os_unfair_lock()

    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        os_unfair_lock_lock(&_lock)
        defer { os_unfair_lock_unlock(&_lock) }
        return try body()
    }

    // MARK: - APIClientProtocol

    func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let (key, errorToThrow, responseToReturn, defaultErr): (String, Error?, T?, Error?) = withLock {
            requestsMade.append(endpoint)
            let key = String(describing: type(of: endpoint))
            return (key, errors[key], responses[key] as? T, defaultError)
        }

        if let error = errorToThrow {
            throw error
        }

        if let response = responseToReturn {
            return response
        }

        if let error = defaultErr {
            throw error
        }

        throw MockAPIError.noResponseConfigured(endpoint: key)
    }

    func request(_ endpoint: Endpoint) async throws {
        let errorToThrow: Error? = withLock {
            requestsMade.append(endpoint)
            let key = String(describing: type(of: endpoint))
            return errors[key]
        }

        if let error = errorToThrow {
            throw error
        }
    }

    func requestData(_ endpoint: Endpoint) async throws -> Data {
        let (errorToThrow, dataToReturn): (Error?, Data?) = withLock {
            requestsMade.append(endpoint)
            let key = String(describing: type(of: endpoint))
            return (errors[key], responses[key] as? Data)
        }

        if let error = errorToThrow {
            throw error
        }

        if let data = dataToReturn {
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
        let (key, errorToThrow, responseToReturn): (String, Error?, T?) = withLock {
            requestsMade.append(endpoint)
            let key = String(describing: type(of: endpoint))
            return (key, errors[key], responses[key] as? T)
        }

        if let error = errorToThrow {
            throw error
        }

        if let response = responseToReturn {
            return response
        }

        throw MockAPIError.noResponseConfigured(endpoint: key)
    }

    // MARK: - Configuration Helpers

    func setResponse<T>(_ response: T, for endpointType: Any.Type) {
        withLock {
            let key = String(describing: endpointType)
            responses[key] = response
        }
    }

    func setError(_ error: Error, for endpointType: Any.Type) {
        withLock {
            let key = String(describing: endpointType)
            errors[key] = error
        }
    }

    func reset() {
        withLock {
            responses.removeAll()
            errors.removeAll()
            requestsMade.removeAll()
            defaultError = nil
        }
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
