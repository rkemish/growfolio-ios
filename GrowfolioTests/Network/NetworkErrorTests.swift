//
//  NetworkErrorTests.swift
//  GrowfolioTests
//
//  Tests for network error handling.
//

import XCTest
@testable import Growfolio

final class NetworkErrorTests: XCTestCase {

    // MARK: - Error Equality Tests

    func testNetworkError_Unauthorized_IsEqual() {
        XCTAssertEqual(NetworkError.unauthorized, NetworkError.unauthorized)
    }

    func testNetworkError_Forbidden_IsEqual() {
        XCTAssertEqual(NetworkError.forbidden, NetworkError.forbidden)
    }

    func testNetworkError_NotFound_IsEqual() {
        XCTAssertEqual(NetworkError.notFound, NetworkError.notFound)
    }

    // MARK: - Error Description Tests

    func testNetworkError_Unauthorized_HasDescription() {
        let error = NetworkError.unauthorized
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testNetworkError_ServerError_IncludesStatusCode() {
        let error = NetworkError.serverError(statusCode: 503, message: "Service unavailable")
        let description = error.localizedDescription
        XCTAssertTrue(description.contains("503") || description.contains("Service"))
    }

    func testNetworkError_ClientError_IncludesMessage() {
        let error = NetworkError.clientError(statusCode: 400, message: "Bad request data")
        let description = error.localizedDescription
        XCTAssertTrue(description.contains("400") || description.contains("Bad"))
    }

    // MARK: - Retryable Tests

    func testNetworkError_Timeout_IsRetryable() {
        let error = NetworkError.timeout
        XCTAssertTrue(error.isRetryable)
    }

    func testNetworkError_NoConnection_IsRetryable() {
        let error = NetworkError.noConnection
        XCTAssertTrue(error.isRetryable)
    }

    func testNetworkError_Unauthorized_IsNotRetryable() {
        let error = NetworkError.unauthorized
        XCTAssertFalse(error.isRetryable)
    }

    func testNetworkError_ClientError_IsNotRetryable() {
        let error = NetworkError.clientError(statusCode: 400, message: nil)
        XCTAssertFalse(error.isRetryable)
    }

    func testNetworkError_ServerError_IsRetryable() {
        let error = NetworkError.serverError(statusCode: 500, message: nil)
        XCTAssertTrue(error.isRetryable)
    }

    func testNetworkError_RateLimited_IsRetryable() {
        let error = NetworkError.rateLimited(retryAfter: 60)
        XCTAssertTrue(error.isRetryable)
    }

    // MARK: - Rate Limit Tests

    func testNetworkError_RateLimited_HasRetryAfter() {
        let error = NetworkError.rateLimited(retryAfter: 30)
        if case .rateLimited(let retryAfter) = error {
            XCTAssertEqual(retryAfter, 30)
        } else {
            XCTFail("Expected rateLimited error")
        }
    }

    func testNetworkError_RateLimited_NilRetryAfter() {
        let error = NetworkError.rateLimited(retryAfter: nil)
        if case .rateLimited(let retryAfter) = error {
            XCTAssertNil(retryAfter)
        } else {
            XCTFail("Expected rateLimited error")
        }
    }

    // MARK: - URL Error Conversion Tests

    func testNetworkError_FromURLError_NotConnected() {
        let urlError = URLError(.notConnectedToInternet)
        let networkError = NetworkError.from(urlError)
        XCTAssertEqual(networkError, .noConnection)
    }

    func testNetworkError_FromURLError_TimedOut() {
        let urlError = URLError(.timedOut)
        let networkError = NetworkError.from(urlError)
        XCTAssertEqual(networkError, .timeout)
    }

    func testNetworkError_FromURLError_Cancelled() {
        let urlError = URLError(.cancelled)
        let networkError = NetworkError.from(urlError)
        XCTAssertEqual(networkError, .cancelled)
    }

    func testNetworkError_FromURLError_NetworkConnectionLost() {
        let urlError = URLError(.networkConnectionLost)
        let networkError = NetworkError.from(urlError)
        XCTAssertEqual(networkError, .noConnection)
    }

    func testNetworkError_FromURLError_SecureConnectionFailed() {
        let urlError = URLError(.secureConnectionFailed)
        let networkError = NetworkError.from(urlError)
        XCTAssertEqual(networkError, .sslError)
    }

    func testNetworkError_FromURLError_ServerCertificateUntrusted() {
        let urlError = URLError(.serverCertificateUntrusted)
        let networkError = NetworkError.from(urlError)
        XCTAssertEqual(networkError, .sslError)
    }

    func testNetworkError_FromURLError_BadURL() {
        let urlError = URLError(.badURL)
        let networkError = NetworkError.from(urlError)
        XCTAssertEqual(networkError, .invalidURL)
    }

    func testNetworkError_FromURLError_UnsupportedURL() {
        let urlError = URLError(.unsupportedURL)
        let networkError = NetworkError.from(urlError)
        XCTAssertEqual(networkError, .invalidURL)
    }

    func testNetworkError_FromURLError_Unknown() {
        let urlError = URLError(.cannotFindHost)
        let networkError = NetworkError.from(urlError)
        if case .unknown = networkError {
            // Expected
        } else {
            XCTFail("Expected unknown error")
        }
    }

    // MARK: - Error Description Tests (All Cases)

    func testNetworkError_InvalidURL_Description() {
        let error = NetworkError.invalidURL
        XCTAssertEqual(error.errorDescription, "The URL is invalid.")
    }

    func testNetworkError_InvalidRequest_Description() {
        let error = NetworkError.invalidRequest(reason: "Missing parameter")
        XCTAssertTrue(error.errorDescription!.contains("Missing parameter"))
    }

    func testNetworkError_NoConnection_Description() {
        let error = NetworkError.noConnection
        XCTAssertTrue(error.errorDescription!.contains("internet"))
    }

    func testNetworkError_Timeout_Description() {
        let error = NetworkError.timeout
        XCTAssertTrue(error.errorDescription!.contains("timed out"))
    }

    func testNetworkError_ServerError_WithMessage_Description() {
        let error = NetworkError.serverError(statusCode: 500, message: "Internal error")
        XCTAssertTrue(error.errorDescription!.contains("500"))
        XCTAssertTrue(error.errorDescription!.contains("Internal error"))
    }

    func testNetworkError_ServerError_WithoutMessage_Description() {
        let error = NetworkError.serverError(statusCode: 502, message: nil)
        XCTAssertTrue(error.errorDescription!.contains("502"))
    }

    func testNetworkError_ClientError_WithMessage_Description() {
        let error = NetworkError.clientError(statusCode: 422, message: "Validation failed")
        XCTAssertTrue(error.errorDescription!.contains("422"))
        XCTAssertTrue(error.errorDescription!.contains("Validation failed"))
    }

    func testNetworkError_ClientError_WithoutMessage_Description() {
        let error = NetworkError.clientError(statusCode: 400, message: nil)
        XCTAssertTrue(error.errorDescription!.contains("400"))
    }

    func testNetworkError_Unauthorized_Description() {
        let error = NetworkError.unauthorized
        XCTAssertTrue(error.errorDescription!.contains("session"))
    }

    func testNetworkError_Forbidden_Description() {
        let error = NetworkError.forbidden
        XCTAssertTrue(error.errorDescription!.contains("permission"))
    }

    func testNetworkError_NotFound_Description() {
        let error = NetworkError.notFound
        XCTAssertTrue(error.errorDescription!.contains("not found"))
    }

    func testNetworkError_RateLimited_WithRetryAfter_Description() {
        let error = NetworkError.rateLimited(retryAfter: 60)
        XCTAssertTrue(error.errorDescription!.contains("60"))
    }

    func testNetworkError_RateLimited_WithoutRetryAfter_Description() {
        let error = NetworkError.rateLimited(retryAfter: nil)
        XCTAssertTrue(error.errorDescription!.contains("try again"))
    }

    func testNetworkError_DecodingError_Description() {
        let error = NetworkError.decodingError(underlyingError: "Invalid JSON")
        XCTAssertTrue(error.errorDescription!.contains("process"))
    }

    func testNetworkError_EncodingError_Description() {
        let error = NetworkError.encodingError(underlyingError: "Invalid data")
        XCTAssertTrue(error.errorDescription!.contains("send"))
    }

    func testNetworkError_SSLError_Description() {
        let error = NetworkError.sslError
        XCTAssertTrue(error.errorDescription!.contains("Secure"))
    }

    func testNetworkError_Cancelled_Description() {
        let error = NetworkError.cancelled
        XCTAssertTrue(error.errorDescription!.contains("cancelled"))
    }

    func testNetworkError_Unknown_Description() {
        let error = NetworkError.unknown(underlyingError: "Something went wrong")
        XCTAssertTrue(error.errorDescription!.contains("Something went wrong"))
    }

    // MARK: - Failure Reason Tests

    func testNetworkError_NoConnection_FailureReason() {
        let error = NetworkError.noConnection
        XCTAssertNotNil(error.failureReason)
        XCTAssertTrue(error.failureReason!.contains("internet"))
    }

    func testNetworkError_Timeout_FailureReason() {
        let error = NetworkError.timeout
        XCTAssertNotNil(error.failureReason)
        XCTAssertTrue(error.failureReason!.contains("server"))
    }

    func testNetworkError_Unauthorized_FailureReason() {
        let error = NetworkError.unauthorized
        XCTAssertNotNil(error.failureReason)
        XCTAssertTrue(error.failureReason!.contains("token"))
    }

    func testNetworkError_SSLError_FailureReason() {
        let error = NetworkError.sslError
        XCTAssertNotNil(error.failureReason)
        XCTAssertTrue(error.failureReason!.contains("SSL"))
    }

    func testNetworkError_InvalidURL_FailureReason() {
        let error = NetworkError.invalidURL
        XCTAssertNil(error.failureReason)
    }

    // MARK: - Recovery Suggestion Tests

    func testNetworkError_NoConnection_RecoverySuggestion() {
        let error = NetworkError.noConnection
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("Wi-Fi"))
    }

    func testNetworkError_Timeout_RecoverySuggestion() {
        let error = NetworkError.timeout
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testNetworkError_Unauthorized_RecoverySuggestion() {
        let error = NetworkError.unauthorized
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("Sign"))
    }

    func testNetworkError_RateLimited_RecoverySuggestion() {
        let error = NetworkError.rateLimited(retryAfter: 30)
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("Wait"))
    }

    func testNetworkError_ServerError_RecoverySuggestion() {
        let error = NetworkError.serverError(statusCode: 500, message: nil)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testNetworkError_InvalidURL_RecoverySuggestion() {
        let error = NetworkError.invalidURL
        XCTAssertNil(error.recoverySuggestion)
    }

    // MARK: - Requires Reauthentication Tests

    func testNetworkError_Unauthorized_RequiresReauthentication() {
        let error = NetworkError.unauthorized
        XCTAssertTrue(error.requiresReauthentication)
    }

    func testNetworkError_Forbidden_DoesNotRequireReauthentication() {
        let error = NetworkError.forbidden
        XCTAssertFalse(error.requiresReauthentication)
    }

    func testNetworkError_ServerError_DoesNotRequireReauthentication() {
        let error = NetworkError.serverError(statusCode: 500, message: nil)
        XCTAssertFalse(error.requiresReauthentication)
    }

    // MARK: - Status Code Tests

    func testNetworkError_ServerError_StatusCode() {
        let error = NetworkError.serverError(statusCode: 503, message: nil)
        XCTAssertEqual(error.statusCode, 503)
    }

    func testNetworkError_ClientError_StatusCode() {
        let error = NetworkError.clientError(statusCode: 422, message: nil)
        XCTAssertEqual(error.statusCode, 422)
    }

    func testNetworkError_Unauthorized_StatusCode() {
        let error = NetworkError.unauthorized
        XCTAssertEqual(error.statusCode, 401)
    }

    func testNetworkError_Forbidden_StatusCode() {
        let error = NetworkError.forbidden
        XCTAssertEqual(error.statusCode, 403)
    }

    func testNetworkError_NotFound_StatusCode() {
        let error = NetworkError.notFound
        XCTAssertEqual(error.statusCode, 404)
    }

    func testNetworkError_Timeout_StatusCode() {
        let error = NetworkError.timeout
        XCTAssertNil(error.statusCode)
    }

    func testNetworkError_NoConnection_StatusCode() {
        let error = NetworkError.noConnection
        XCTAssertNil(error.statusCode)
    }

    // MARK: - Equatable Tests (All Cases)

    func testNetworkError_InvalidURL_Equality() {
        XCTAssertEqual(NetworkError.invalidURL, NetworkError.invalidURL)
    }

    func testNetworkError_NoConnection_Equality() {
        XCTAssertEqual(NetworkError.noConnection, NetworkError.noConnection)
    }

    func testNetworkError_Timeout_Equality() {
        XCTAssertEqual(NetworkError.timeout, NetworkError.timeout)
    }

    func testNetworkError_SSLError_Equality() {
        XCTAssertEqual(NetworkError.sslError, NetworkError.sslError)
    }

    func testNetworkError_Cancelled_Equality() {
        XCTAssertEqual(NetworkError.cancelled, NetworkError.cancelled)
    }

    func testNetworkError_InvalidRequest_Equality() {
        XCTAssertEqual(
            NetworkError.invalidRequest(reason: "test"),
            NetworkError.invalidRequest(reason: "test")
        )
        XCTAssertNotEqual(
            NetworkError.invalidRequest(reason: "test1"),
            NetworkError.invalidRequest(reason: "test2")
        )
    }

    func testNetworkError_ServerError_Equality() {
        XCTAssertEqual(
            NetworkError.serverError(statusCode: 500, message: "error"),
            NetworkError.serverError(statusCode: 500, message: "error")
        )
        XCTAssertNotEqual(
            NetworkError.serverError(statusCode: 500, message: "error1"),
            NetworkError.serverError(statusCode: 500, message: "error2")
        )
        XCTAssertNotEqual(
            NetworkError.serverError(statusCode: 500, message: nil),
            NetworkError.serverError(statusCode: 502, message: nil)
        )
    }

    func testNetworkError_ClientError_Equality() {
        XCTAssertEqual(
            NetworkError.clientError(statusCode: 400, message: "bad"),
            NetworkError.clientError(statusCode: 400, message: "bad")
        )
        XCTAssertNotEqual(
            NetworkError.clientError(statusCode: 400, message: nil),
            NetworkError.clientError(statusCode: 422, message: nil)
        )
    }

    func testNetworkError_RateLimited_Equality() {
        XCTAssertEqual(
            NetworkError.rateLimited(retryAfter: 60),
            NetworkError.rateLimited(retryAfter: 60)
        )
        XCTAssertNotEqual(
            NetworkError.rateLimited(retryAfter: 60),
            NetworkError.rateLimited(retryAfter: 30)
        )
    }

    func testNetworkError_DecodingError_Equality() {
        XCTAssertEqual(
            NetworkError.decodingError(underlyingError: "test"),
            NetworkError.decodingError(underlyingError: "test")
        )
        XCTAssertNotEqual(
            NetworkError.decodingError(underlyingError: "test1"),
            NetworkError.decodingError(underlyingError: "test2")
        )
    }

    func testNetworkError_EncodingError_Equality() {
        XCTAssertEqual(
            NetworkError.encodingError(underlyingError: "test"),
            NetworkError.encodingError(underlyingError: "test")
        )
    }

    func testNetworkError_Unknown_Equality() {
        XCTAssertEqual(
            NetworkError.unknown(underlyingError: "test"),
            NetworkError.unknown(underlyingError: "test")
        )
    }

    func testNetworkError_DifferentTypes_NotEqual() {
        XCTAssertNotEqual(NetworkError.unauthorized, NetworkError.forbidden)
        XCTAssertNotEqual(NetworkError.timeout, NetworkError.noConnection)
        XCTAssertNotEqual(NetworkError.invalidURL, NetworkError.notFound)
    }

    // MARK: - APIErrorResponse Tests

    func testAPIErrorResponse_Decoding() throws {
        let json = """
        {
            "error": "VALIDATION_ERROR",
            "message": "Invalid input",
            "details": {"field": "email"}
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(APIErrorResponse.self, from: json)

        XCTAssertEqual(response.error, "VALIDATION_ERROR")
        XCTAssertEqual(response.message, "Invalid input")
        XCTAssertEqual(response.details?["field"], "email")
    }

    func testAPIErrorResponse_DecodingWithoutDetails() throws {
        let json = """
        {
            "error": "SERVER_ERROR",
            "message": "Internal error"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(APIErrorResponse.self, from: json)

        XCTAssertEqual(response.error, "SERVER_ERROR")
        XCTAssertEqual(response.message, "Internal error")
        XCTAssertNil(response.details)
    }

    // MARK: - Additional Retryable Tests

    func testNetworkError_DecodingError_NotRetryable() {
        let error = NetworkError.decodingError(underlyingError: "test")
        XCTAssertFalse(error.isRetryable)
    }

    func testNetworkError_EncodingError_NotRetryable() {
        let error = NetworkError.encodingError(underlyingError: "test")
        XCTAssertFalse(error.isRetryable)
    }

    func testNetworkError_InvalidURL_NotRetryable() {
        let error = NetworkError.invalidURL
        XCTAssertFalse(error.isRetryable)
    }

    func testNetworkError_SSLError_NotRetryable() {
        let error = NetworkError.sslError
        XCTAssertFalse(error.isRetryable)
    }

    func testNetworkError_Cancelled_NotRetryable() {
        let error = NetworkError.cancelled
        XCTAssertFalse(error.isRetryable)
    }

    func testNetworkError_Forbidden_NotRetryable() {
        let error = NetworkError.forbidden
        XCTAssertFalse(error.isRetryable)
    }

    func testNetworkError_NotFound_NotRetryable() {
        let error = NetworkError.notFound
        XCTAssertFalse(error.isRetryable)
    }
}

// MARK: - Mock URL Protocol Tests

final class MockURLProtocolTests: XCTestCase {

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - Tests

    func testMockURLProtocol_ReturnsConfiguredResponse() async throws {
        // Arrange
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        let expectedData = """
        {"message": "success"}
        """.data(using: .utf8)!

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, expectedData)
        }

        // Act
        let url = URL(string: "https://api.test.com/endpoint")!
        let (data, response) = try await session.data(from: url)

        // Assert
        XCTAssertEqual(data, expectedData)
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
    }

    func testMockURLProtocol_ReturnsError() async {
        // Arrange
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        // Act & Assert
        let url = URL(string: "https://api.test.com/endpoint")!
        do {
            _ = try await session.data(from: url)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
}

// MARK: - Mock URL Protocol

class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func reset() {
        requestHandler = nil
    }
}
