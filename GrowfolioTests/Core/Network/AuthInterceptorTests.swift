//
//  AuthInterceptorTests.swift
//  GrowfolioTests
//
//  Tests for AuthInterceptor, TokenResponse, HeaderInterceptor, and InterceptorChain.
//

import XCTest
@testable import Growfolio

final class AuthInterceptorTests: XCTestCase {

    // MARK: - TokenResponse Tests

    func testTokenResponseDecoding() throws {
        let json = """
        {
            "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9",
            "refresh_token": "v1.refresh-token",
            "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.id",
            "token_type": "Bearer",
            "expires_in": 86400
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)

        XCTAssertEqual(response.accessToken, "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9")
        XCTAssertEqual(response.refreshToken, "v1.refresh-token")
        XCTAssertEqual(response.idToken, "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.id")
        XCTAssertEqual(response.tokenType, "Bearer")
        XCTAssertEqual(response.expiresIn, 86400)
    }

    func testTokenResponseDecodingWithNullOptionals() throws {
        let json = """
        {
            "access_token": "access-token",
            "refresh_token": null,
            "id_token": null,
            "token_type": "Bearer",
            "expires_in": 3600
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)

        XCTAssertEqual(response.accessToken, "access-token")
        XCTAssertNil(response.refreshToken)
        XCTAssertNil(response.idToken)
        XCTAssertEqual(response.tokenType, "Bearer")
        XCTAssertEqual(response.expiresIn, 3600)
    }

    func testTokenResponseDecodingWithMissingOptionals() throws {
        let json = """
        {
            "access_token": "token123",
            "token_type": "Bearer",
            "expires_in": 7200
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)

        XCTAssertEqual(response.accessToken, "token123")
        XCTAssertNil(response.refreshToken)
        XCTAssertNil(response.idToken)
        XCTAssertEqual(response.tokenType, "Bearer")
        XCTAssertEqual(response.expiresIn, 7200)
    }

    func testTokenResponseEncoding() throws {
        let response = TokenResponse(
            accessToken: "access",
            refreshToken: "refresh",
            idToken: "id",
            tokenType: "Bearer",
            expiresIn: 3600
        )

        let data = try JSONEncoder().encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["access_token"] as? String, "access")
        XCTAssertEqual(json["refresh_token"] as? String, "refresh")
        XCTAssertEqual(json["id_token"] as? String, "id")
        XCTAssertEqual(json["token_type"] as? String, "Bearer")
        XCTAssertEqual(json["expires_in"] as? Int, 3600)
    }

    func testTokenResponseIsSendable() {
        let response = TokenResponse(
            accessToken: "token",
            refreshToken: nil,
            idToken: nil,
            tokenType: "Bearer",
            expiresIn: 3600
        )

        Task {
            let copy = response
            XCTAssertEqual(copy.accessToken, "token")
        }
    }

    // MARK: - HeaderInterceptor Tests

    func testHeaderInterceptorAddsSingleHeader() async throws {
        let interceptor = HeaderInterceptor(headers: ["X-Custom-Header": "custom-value"])
        var request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Custom-Header"), "custom-value")
    }

    func testHeaderInterceptorAddsMultipleHeaders() async throws {
        let interceptor = HeaderInterceptor(headers: [
            "X-Header-1": "value-1",
            "X-Header-2": "value-2",
            "X-Header-3": "value-3"
        ])
        var request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Header-1"), "value-1")
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Header-2"), "value-2")
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Header-3"), "value-3")
    }

    func testHeaderInterceptorPreservesExistingHeaders() async throws {
        let interceptor = HeaderInterceptor(headers: ["X-New-Header": "new-value"])
        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        request.setValue("existing-value", forHTTPHeaderField: "X-Existing-Header")

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Existing-Header"), "existing-value")
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-New-Header"), "new-value")
    }

    func testHeaderInterceptorOverwritesHeader() async throws {
        let interceptor = HeaderInterceptor(headers: ["Content-Type": "application/json"])
        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testHeaderInterceptorWithEmptyHeaders() async throws {
        let interceptor = HeaderInterceptor(headers: [:])
        var request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modifiedRequest = try await interceptor.intercept(request: request)

        // Request should be unchanged
        XCTAssertEqual(modifiedRequest.url, request.url)
    }

    // MARK: - InterceptorChain Tests

    func testInterceptorChainAppliesAllInterceptors() async throws {
        let interceptor1 = HeaderInterceptor(headers: ["X-Header-1": "value-1"])
        let interceptor2 = HeaderInterceptor(headers: ["X-Header-2": "value-2"])
        let chain = InterceptorChain(interceptors: [interceptor1, interceptor2])

        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        let modifiedRequest = try await chain.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Header-1"), "value-1")
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Header-2"), "value-2")
    }

    func testInterceptorChainAppliesInOrder() async throws {
        // First interceptor sets a value, second overwrites it
        let interceptor1 = HeaderInterceptor(headers: ["X-Order-Test": "first"])
        let interceptor2 = HeaderInterceptor(headers: ["X-Order-Test": "second"])
        let chain = InterceptorChain(interceptors: [interceptor1, interceptor2])

        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        let modifiedRequest = try await chain.intercept(request: request)

        // Second interceptor should win since it runs last
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Order-Test"), "second")
    }

    func testInterceptorChainWithEmptyInterceptors() async throws {
        let chain = InterceptorChain(interceptors: [])

        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        let modifiedRequest = try await chain.intercept(request: request)

        // Request should be unchanged
        XCTAssertEqual(modifiedRequest.url, request.url)
    }

    func testInterceptorChainWithSingleInterceptor() async throws {
        let interceptor = HeaderInterceptor(headers: ["X-Single": "value"])
        let chain = InterceptorChain(interceptors: [interceptor])

        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        let modifiedRequest = try await chain.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Single"), "value")
    }

    // MARK: - AuthInterceptor Tests

    func testAuthInterceptorClearsTokens() async {
        let keychain = KeychainWrapper(service: "com.growfolio.tests.\(UUID().uuidString)")
        let tokenManager = TokenManager(keychain: keychain)
        let authInterceptor = AuthInterceptor(tokenManager: tokenManager)

        // Store tokens first
        await tokenManager.storeTokens(
            accessToken: "access",
            refreshToken: "refresh",
            idToken: nil,
            expiresIn: 3600
        )

        // Clear tokens
        await authInterceptor.clearTokens()

        // Verify tokens are cleared
        let accessToken = await tokenManager.accessToken

        XCTAssertNil(accessToken)

        // Clean up
        keychain.deleteAll()
    }

    // MARK: - RequestInterceptor Protocol Tests

    func testRequestInterceptorProtocolConformance() {
        // Verify types conform to RequestInterceptor
        let _: RequestInterceptor = HeaderInterceptor(headers: [:])

        // Compile-time check that the protocol is properly defined
        XCTAssertTrue(true)
    }

    // MARK: - Edge Cases

    func testHeaderInterceptorWithSpecialCharacters() async throws {
        let interceptor = HeaderInterceptor(headers: [
            "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczovL2V4YW1wbGUuY29tIn0",
            "X-Request-Id": "req-123-abc-456"
        ])
        var request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertNotNil(modifiedRequest.value(forHTTPHeaderField: "Authorization"))
        XCTAssertNotNil(modifiedRequest.value(forHTTPHeaderField: "X-Request-Id"))
    }

    func testHeaderInterceptorPreservesRequestMethod() async throws {
        let interceptor = HeaderInterceptor(headers: ["X-Test": "value"])
        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        request.httpMethod = "POST"

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.httpMethod, "POST")
    }

    func testHeaderInterceptorPreservesRequestBody() async throws {
        let interceptor = HeaderInterceptor(headers: ["X-Test": "value"])
        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        request.httpBody = "test-body".data(using: .utf8)

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.httpBody, "test-body".data(using: .utf8))
    }

    func testHeaderInterceptorPreservesURL() async throws {
        let interceptor = HeaderInterceptor(headers: ["X-Test": "value"])
        let url = URL(string: "https://api.example.com/path?query=param")!
        var request = URLRequest(url: url)

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.url, url)
    }

    func testTokenResponseWithLargeExpiresIn() throws {
        let json = """
        {
            "access_token": "token",
            "token_type": "Bearer",
            "expires_in": 2147483647
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)

        XCTAssertEqual(response.expiresIn, 2147483647)
    }

    func testTokenResponseWithZeroExpiresIn() throws {
        let json = """
        {
            "access_token": "token",
            "token_type": "Bearer",
            "expires_in": 0
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)

        XCTAssertEqual(response.expiresIn, 0)
    }

    func testTokenResponseWithEmptyAccessToken() throws {
        let json = """
        {
            "access_token": "",
            "token_type": "Bearer",
            "expires_in": 3600
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)

        XCTAssertEqual(response.accessToken, "")
    }

    // MARK: - Concurrent Access Tests

    func testInterceptorChainConcurrentAccess() async throws {
        let chain = InterceptorChain(interceptors: [
            HeaderInterceptor(headers: ["X-Test": "value"])
        ])

        await withTaskGroup(of: URLRequest?.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    var request = URLRequest(url: URL(string: "https://api.example.com")!)
                    return try? await chain.intercept(request: request)
                }
            }

            var results: [URLRequest?] = []
            for await result in group {
                results.append(result)
            }

            // All results should be valid
            XCTAssertEqual(results.count, 100)
            for result in results {
                XCTAssertNotNil(result)
                XCTAssertEqual(result?.value(forHTTPHeaderField: "X-Test"), "value")
            }
        }
    }

    // MARK: - LoggingInterceptor Tests

    func testLoggingInterceptorReturnsUnmodifiedRequest() async throws {
        let interceptor = LoggingInterceptor()
        let originalURL = URL(string: "https://api.example.com/path?query=value")!
        var request = URLRequest(url: originalURL)
        request.httpMethod = "POST"
        request.httpBody = "test body".data(using: .utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let modifiedRequest = try await interceptor.intercept(request: request)

        // LoggingInterceptor should not modify the request
        XCTAssertEqual(modifiedRequest.url, originalURL)
        XCTAssertEqual(modifiedRequest.httpMethod, "POST")
        XCTAssertEqual(modifiedRequest.httpBody, "test body".data(using: .utf8))
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testLoggingInterceptorWithNoBody() async throws {
        let interceptor = LoggingInterceptor()
        let request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertNil(modifiedRequest.httpBody)
    }

    func testLoggingInterceptorWithLargeBody() async throws {
        let interceptor = LoggingInterceptor()
        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        let largeBody = String(repeating: "a", count: 10000).data(using: .utf8)
        request.httpBody = largeBody

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.httpBody, largeBody)
    }

    // MARK: - AuthInterceptor with TokenManager Integration Tests

    func testAuthInterceptorAddsAuthorizationHeader() async throws {
        let keychain = KeychainWrapper(service: "com.growfolio.tests.\(UUID().uuidString)")
        let tokenManager = TokenManager(keychain: keychain)
        let authInterceptor = AuthInterceptor(tokenManager: tokenManager)

        // Store a valid token
        await tokenManager.storeTokens(
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            idToken: nil,
            expiresIn: 3600
        )

        var request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modifiedRequest = try await authInterceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "Authorization"), "Bearer test-access-token")

        // Clean up
        keychain.deleteAll()
    }

    func testAuthInterceptorPreservesExistingHeaders() async throws {
        let keychain = KeychainWrapper(service: "com.growfolio.tests.\(UUID().uuidString)")
        let tokenManager = TokenManager(keychain: keychain)
        let authInterceptor = AuthInterceptor(tokenManager: tokenManager)

        await tokenManager.storeTokens(
            accessToken: "token",
            refreshToken: "refresh",
            idToken: nil,
            expiresIn: 3600
        )

        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("custom-value", forHTTPHeaderField: "X-Custom-Header")

        let modifiedRequest = try await authInterceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Custom-Header"), "custom-value")
        XCTAssertNotNil(modifiedRequest.value(forHTTPHeaderField: "Authorization"))

        keychain.deleteAll()
    }

    func testAuthInterceptorPreservesRequestProperties() async throws {
        let keychain = KeychainWrapper(service: "com.growfolio.tests.\(UUID().uuidString)")
        let tokenManager = TokenManager(keychain: keychain)
        let authInterceptor = AuthInterceptor(tokenManager: tokenManager)

        await tokenManager.storeTokens(
            accessToken: "token",
            refreshToken: "refresh",
            idToken: nil,
            expiresIn: 3600
        )

        var request = URLRequest(url: URL(string: "https://api.example.com/path")!)
        request.httpMethod = "POST"
        request.httpBody = "request body".data(using: .utf8)
        request.timeoutInterval = 120

        let modifiedRequest = try await authInterceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.url?.absoluteString, "https://api.example.com/path")
        XCTAssertEqual(modifiedRequest.httpMethod, "POST")
        XCTAssertEqual(modifiedRequest.httpBody, "request body".data(using: .utf8))
        XCTAssertEqual(modifiedRequest.timeoutInterval, 120)

        keychain.deleteAll()
    }

    // MARK: - InterceptorChain Complex Scenarios

    func testInterceptorChainWithManyInterceptors() async throws {
        var interceptors: [RequestInterceptor] = []
        for i in 0..<10 {
            interceptors.append(HeaderInterceptor(headers: ["X-Header-\(i)": "value-\(i)"]))
        }
        let chain = InterceptorChain(interceptors: interceptors)

        let request = URLRequest(url: URL(string: "https://api.example.com")!)
        let modifiedRequest = try await chain.intercept(request: request)

        for i in 0..<10 {
            XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Header-\(i)"), "value-\(i)")
        }
    }

    func testInterceptorChainWithLoggingAndHeaders() async throws {
        let chain = InterceptorChain(interceptors: [
            LoggingInterceptor(),
            HeaderInterceptor(headers: ["X-After-Logging": "value"])
        ])

        let request = URLRequest(url: URL(string: "https://api.example.com")!)
        let modifiedRequest = try await chain.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-After-Logging"), "value")
    }

    // MARK: - TokenResponse Additional Tests

    func testTokenResponseWithAllFields() throws {
        let json = """
        {
            "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.access",
            "refresh_token": "v1.refresh-token-value",
            "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.id",
            "token_type": "Bearer",
            "expires_in": 86400
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)

        XCTAssertTrue(response.accessToken.contains("eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9"))
        XCTAssertTrue(response.refreshToken?.contains("v1.refresh") ?? false)
        XCTAssertNotNil(response.idToken)
        XCTAssertEqual(response.tokenType, "Bearer")
        XCTAssertEqual(response.expiresIn, 86400) // 1 day
    }

    func testTokenResponseEquality() throws {
        let json = """
        {
            "access_token": "token",
            "token_type": "Bearer",
            "expires_in": 3600
        }
        """.data(using: .utf8)!

        let response1 = try JSONDecoder().decode(TokenResponse.self, from: json)
        let response2 = try JSONDecoder().decode(TokenResponse.self, from: json)

        XCTAssertEqual(response1.accessToken, response2.accessToken)
        XCTAssertEqual(response1.tokenType, response2.tokenType)
        XCTAssertEqual(response1.expiresIn, response2.expiresIn)
    }

    func testTokenResponseWithDifferentTokenTypes() throws {
        let bearerJSON = """
        {"access_token": "token", "token_type": "Bearer", "expires_in": 3600}
        """.data(using: .utf8)!

        let macJSON = """
        {"access_token": "token", "token_type": "mac", "expires_in": 3600}
        """.data(using: .utf8)!

        let bearerResponse = try JSONDecoder().decode(TokenResponse.self, from: bearerJSON)
        let macResponse = try JSONDecoder().decode(TokenResponse.self, from: macJSON)

        XCTAssertEqual(bearerResponse.tokenType, "Bearer")
        XCTAssertEqual(macResponse.tokenType, "mac")
    }

    func testTokenResponseCodingKeys() {
        // Verify coding keys are correctly defined
        XCTAssertEqual(TokenResponse.CodingKeys.accessToken.rawValue, "access_token")
        XCTAssertEqual(TokenResponse.CodingKeys.refreshToken.rawValue, "refresh_token")
        XCTAssertEqual(TokenResponse.CodingKeys.idToken.rawValue, "id_token")
        XCTAssertEqual(TokenResponse.CodingKeys.tokenType.rawValue, "token_type")
        XCTAssertEqual(TokenResponse.CodingKeys.expiresIn.rawValue, "expires_in")
    }

    // MARK: - HeaderInterceptor Edge Cases

    func testHeaderInterceptorWithLongHeaderValue() async throws {
        let longValue = String(repeating: "x", count: 8000)
        let interceptor = HeaderInterceptor(headers: ["X-Long-Header": longValue])
        let request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Long-Header"), longValue)
    }

    func testHeaderInterceptorWithStandardHeaders() async throws {
        let interceptor = HeaderInterceptor(headers: [
            "Accept": "application/json",
            "Accept-Language": "en-US",
            "Cache-Control": "no-cache",
            "User-Agent": "GrowfolioApp/1.0"
        ])
        let request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "Accept-Language"), "en-US")
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "Cache-Control"), "no-cache")
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "User-Agent"), "GrowfolioApp/1.0")
    }

    func testHeaderInterceptorWithCaseInsensitiveHeaders() async throws {
        let interceptor = HeaderInterceptor(headers: ["content-type": "application/json"])
        var request = URLRequest(url: URL(string: "https://api.example.com")!)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        let modifiedRequest = try await interceptor.intercept(request: request)

        // HTTP headers are case-insensitive, but URLRequest may treat them separately
        XCTAssertNotNil(modifiedRequest.value(forHTTPHeaderField: "content-type"))
    }

    // MARK: - RequestInterceptor Protocol Tests

    func testRequestInterceptorConformanceForAllTypes() {
        // Verify all interceptor types conform to RequestInterceptor
        let _: RequestInterceptor = HeaderInterceptor(headers: [:])
        let _: RequestInterceptor = LoggingInterceptor()
        let _: RequestInterceptor = InterceptorChain(interceptors: [])

        XCTAssertTrue(true)
    }

    // MARK: - Token Expiration Edge Cases

    func testAuthInterceptorWithNegativeExpiresIn() async throws {
        let json = """
        {
            "access_token": "token",
            "token_type": "Bearer",
            "expires_in": -100
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)

        XCTAssertEqual(response.expiresIn, -100)
    }

    // MARK: - InterceptorChain Order Verification

    func testInterceptorChainExecutionOrder() async throws {
        // Create interceptors that each append to a shared header
        let interceptor1 = HeaderInterceptor(headers: ["X-Execution-Order": "1"])
        let interceptor2 = HeaderInterceptor(headers: ["X-Execution-Order": "2"])
        let interceptor3 = HeaderInterceptor(headers: ["X-Execution-Order": "3"])

        let chain = InterceptorChain(interceptors: [interceptor1, interceptor2, interceptor3])
        let request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modifiedRequest = try await chain.intercept(request: request)

        // Last interceptor wins for same header
        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Execution-Order"), "3")
    }

    // MARK: - URL Preservation Tests

    func testInterceptorsPreserveComplexURLs() async throws {
        let complexURL = URL(string: "https://api.example.com:8080/v1/users/123/profile?include=settings&expand=preferences#section")!
        var request = URLRequest(url: complexURL)

        let interceptor = HeaderInterceptor(headers: ["X-Test": "value"])
        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.url?.scheme, "https")
        XCTAssertEqual(modifiedRequest.url?.host, "api.example.com")
        XCTAssertEqual(modifiedRequest.url?.port, 8080)
        XCTAssertEqual(modifiedRequest.url?.path, "/v1/users/123/profile")
        XCTAssertTrue(modifiedRequest.url?.query?.contains("include=settings") ?? false)
        XCTAssertEqual(modifiedRequest.url?.fragment, "section")
    }

    // MARK: - Multiple Interceptor Instances

    func testMultipleHeaderInterceptorInstances() async throws {
        let interceptor1 = HeaderInterceptor(headers: ["X-First": "1"])
        let interceptor2 = HeaderInterceptor(headers: ["X-Second": "2"])

        let request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modified1 = try await interceptor1.intercept(request: request)
        let modified2 = try await interceptor2.intercept(request: modified1)

        XCTAssertEqual(modified2.value(forHTTPHeaderField: "X-First"), "1")
        XCTAssertEqual(modified2.value(forHTTPHeaderField: "X-Second"), "2")
    }

    // MARK: - Empty and Nil Values

    func testHeaderInterceptorWithEmptyStringValue() async throws {
        let interceptor = HeaderInterceptor(headers: ["X-Empty": ""])
        let request = URLRequest(url: URL(string: "https://api.example.com")!)

        let modifiedRequest = try await interceptor.intercept(request: request)

        XCTAssertEqual(modifiedRequest.value(forHTTPHeaderField: "X-Empty"), "")
    }

    func testTokenResponseWithEmptyStrings() throws {
        let json = """
        {
            "access_token": "",
            "refresh_token": "",
            "id_token": "",
            "token_type": "",
            "expires_in": 0
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TokenResponse.self, from: json)

        XCTAssertEqual(response.accessToken, "")
        XCTAssertEqual(response.refreshToken, "")
        XCTAssertEqual(response.idToken, "")
        XCTAssertEqual(response.tokenType, "")
        XCTAssertEqual(response.expiresIn, 0)
    }

    // MARK: - Concurrent Access Safety

    func testHeaderInterceptorConcurrentAccess() async throws {
        let interceptor = HeaderInterceptor(headers: ["X-Concurrent": "value"])

        await withTaskGroup(of: URLRequest?.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    let request = URLRequest(url: URL(string: "https://api.example.com")!)
                    return try? await interceptor.intercept(request: request)
                }
            }

            var results: [URLRequest?] = []
            for await result in group {
                results.append(result)
            }

            XCTAssertEqual(results.count, 50)
            for result in results {
                XCTAssertEqual(result?.value(forHTTPHeaderField: "X-Concurrent"), "value")
            }
        }
    }

    func testLoggingInterceptorConcurrentAccess() async throws {
        let interceptor = LoggingInterceptor()

        await withTaskGroup(of: URLRequest?.self) { group in
            for i in 0..<50 {
                group.addTask {
                    let request = URLRequest(url: URL(string: "https://api.example.com/\(i)")!)
                    return try? await interceptor.intercept(request: request)
                }
            }

            var results: [URLRequest?] = []
            for await result in group {
                results.append(result)
            }

            XCTAssertEqual(results.count, 50)
            // All requests should be returned unmodified
            for result in results {
                XCTAssertNotNil(result)
            }
        }
    }
}
