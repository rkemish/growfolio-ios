//
//  NetworkError.swift
//  Growfolio
//
//  Custom error types for network operations.
//

import Foundation

/// Network-related errors that can occur during API communication
enum NetworkError: LocalizedError, Equatable, Sendable {
    /// Invalid URL construction
    case invalidURL

    /// Invalid request parameters or body
    case invalidRequest(reason: String)

    /// No network connection available
    case noConnection

    /// Request timed out
    case timeout

    /// Server returned an error response
    case serverError(statusCode: Int, message: String?)

    /// Client error (4xx status codes)
    case clientError(statusCode: Int, message: String?)

    /// Unauthorized - authentication required or token expired
    case unauthorized

    /// Forbidden - user doesn't have permission
    case forbidden

    /// Resource not found
    case notFound

    /// Rate limit exceeded
    case rateLimited(retryAfter: TimeInterval?)

    /// Response data couldn't be decoded
    case decodingError(underlyingError: String)

    /// Response data couldn't be encoded
    case encodingError(underlyingError: String)

    /// SSL/TLS certificate validation failed
    case sslError

    /// Request was cancelled
    case cancelled

    /// Unknown error occurred
    case unknown(underlyingError: String)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid."
        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "The request timed out. Please try again."
        case .serverError(let statusCode, let message):
            if let message = message {
                return "Server error (\(statusCode)): \(message)"
            }
            return "Server error (\(statusCode)). Please try again later."
        case .clientError(let statusCode, let message):
            if let message = message {
                return "Request error (\(statusCode)): \(message)"
            }
            return "Request error (\(statusCode))."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Please wait \(Int(seconds)) seconds."
            }
            return "Too many requests. Please try again later."
        case .decodingError:
            return "Unable to process the server response."
        case .encodingError:
            return "Unable to send the request data."
        case .sslError:
            return "Secure connection could not be established."
        case .cancelled:
            return "The request was cancelled."
        case .unknown(let error):
            return "An unexpected error occurred: \(error)"
        }
    }

    var failureReason: String? {
        switch self {
        case .noConnection:
            return "The device is not connected to the internet."
        case .timeout:
            return "The server took too long to respond."
        case .unauthorized:
            return "The authentication token is invalid or expired."
        case .sslError:
            return "SSL certificate validation failed."
        default:
            return nil
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your Wi-Fi or cellular connection and try again."
        case .timeout:
            return "Check your internet connection and try again."
        case .unauthorized:
            return "Sign out and sign back in to refresh your session."
        case .rateLimited:
            return "Wait a moment before making another request."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        default:
            return nil
        }
    }

    // MARK: - Equatable

    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.noConnection, .noConnection),
             (.timeout, .timeout),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.sslError, .sslError),
             (.cancelled, .cancelled):
            return true
        case (.invalidRequest(let lhsReason), .invalidRequest(let rhsReason)):
            return lhsReason == rhsReason
        case (.serverError(let lhsCode, let lhsMsg), .serverError(let rhsCode, let rhsMsg)):
            return lhsCode == rhsCode && lhsMsg == rhsMsg
        case (.clientError(let lhsCode, let lhsMsg), .clientError(let rhsCode, let rhsMsg)):
            return lhsCode == rhsCode && lhsMsg == rhsMsg
        case (.rateLimited(let lhsRetry), .rateLimited(let rhsRetry)):
            return lhsRetry == rhsRetry
        case (.decodingError(let lhsError), .decodingError(let rhsError)):
            return lhsError == rhsError
        case (.encodingError(let lhsError), .encodingError(let rhsError)):
            return lhsError == rhsError
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }

    // MARK: - Convenience Properties

    /// Whether the error is recoverable through retry
    var isRetryable: Bool {
        switch self {
        case .timeout, .noConnection, .serverError, .rateLimited:
            return true
        default:
            return false
        }
    }

    /// Whether the error requires re-authentication
    var requiresReauthentication: Bool {
        switch self {
        case .unauthorized:
            return true
        default:
            return false
        }
    }

    /// HTTP status code if applicable
    var statusCode: Int? {
        switch self {
        case .serverError(let code, _), .clientError(let code, _):
            return code
        case .unauthorized:
            return 401
        case .forbidden:
            return 403
        case .notFound:
            return 404
        default:
            return nil
        }
    }
}

// MARK: - Error Response

/// Standard error response structure from the API
/// Supports both flat format (AsyncAPI spec) and nested format
struct APIErrorResponse: Sendable {
    let error: String
    let message: String
    let details: [String: String]?
}

extension APIErrorResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case error
        case message
        case details
    }

    enum NestedErrorKeys: String, CodingKey {
        case error
    }

    enum ErrorDetailKeys: String, CodingKey {
        case code
        case message
        case details
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try flat format first (AsyncAPI spec)
        if let errorString = try? container.decode(String.self, forKey: .error) {
            self.error = errorString
            self.message = try container.decode(String.self, forKey: .message)
            self.details = try container.decodeIfPresent([String: String].self, forKey: .details)
        }
        // Fall back to nested format
        else if let errorDetail = try? container.decode(ErrorDetail.self, forKey: .error) {
            self.error = errorDetail.code
            self.message = errorDetail.message
            self.details = errorDetail.details
        }
        // Fail if neither format matches
        else {
            throw DecodingError.dataCorruptedError(
                forKey: .error,
                in: container,
                debugDescription: "Error field must be either a string or nested object"
            )
        }
    }

    private struct ErrorDetail: Decodable {
        let code: String
        let message: String
        let details: [String: String]?
    }
}

extension APIErrorResponse: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(error, forKey: .error)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(details, forKey: .details)
    }
}

// MARK: - URLError Extension

extension NetworkError {
    /// Create a NetworkError from a URLError
    static func from(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        case .secureConnectionFailed, .serverCertificateUntrusted:
            return .sslError
        case .badURL, .unsupportedURL:
            return .invalidURL
        default:
            return .unknown(underlyingError: urlError.localizedDescription)
        }
    }
}
