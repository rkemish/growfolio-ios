//
//  TokenManagerTests.swift
//  GrowfolioTests
//
//  Tests for TokenManager, KeychainWrapper, and SecureStorage.
//

import XCTest
@testable import Growfolio

final class TokenManagerTests: XCTestCase {

    private var keychain: KeychainWrapper!
    private var tokenManager: TokenManager!

    override func setUp() {
        super.setUp()
        // Use a unique service name for testing to avoid conflicts
        keychain = KeychainWrapper(service: "com.growfolio.tests.\(UUID().uuidString)")
        tokenManager = TokenManager(keychain: keychain)
    }

    override func tearDown() {
        keychain.deleteAll()
        keychain = nil
        tokenManager = nil
        super.tearDown()
    }

    // MARK: - KeychainWrapper Tests

    func testKeychainWrapperSetAndGet() {
        keychain.set("test-value", forKey: "test-key")
        let retrieved = keychain.get("test-key")

        XCTAssertEqual(retrieved, "test-value")
    }

    func testKeychainWrapperGetNonexistentKey() {
        let retrieved = keychain.get("nonexistent-key")

        XCTAssertNil(retrieved)
    }

    func testKeychainWrapperDelete() {
        keychain.set("test-value", forKey: "test-key")
        keychain.delete("test-key")
        let retrieved = keychain.get("test-key")

        XCTAssertNil(retrieved)
    }

    func testKeychainWrapperDeleteAll() {
        // Use unique keys to avoid interference from other tests
        let uniquePrefix = UUID().uuidString
        keychain.set("value1", forKey: "\(uniquePrefix)-key1")
        keychain.set("value2", forKey: "\(uniquePrefix)-key2")
        keychain.set("value3", forKey: "\(uniquePrefix)-key3")

        // Verify they were set
        XCTAssertNotNil(keychain.get("\(uniquePrefix)-key1"))

        keychain.deleteAll()

        // After deleteAll, keys should be gone
        XCTAssertNil(keychain.get("\(uniquePrefix)-key1"))
    }

    func testKeychainWrapperOverwriteValue() {
        keychain.set("original", forKey: "test-key")
        keychain.set("updated", forKey: "test-key")
        let retrieved = keychain.get("test-key")

        XCTAssertEqual(retrieved, "updated")
    }

    func testKeychainWrapperSpecialCharacters() {
        let value = "password!@#$%^&*()_+-=[]{}|;':\",./<>?"
        keychain.set(value, forKey: "special-key")
        let retrieved = keychain.get("special-key")

        XCTAssertEqual(retrieved, value)
    }

    func testKeychainWrapperUnicodeCharacters() {
        let value = "密码 Пароль 비밀번호 🔐"
        keychain.set(value, forKey: "unicode-key")
        let retrieved = keychain.get("unicode-key")

        XCTAssertEqual(retrieved, value)
    }

    func testKeychainWrapperLongValue() {
        let value = String(repeating: "a", count: 10000)
        keychain.set(value, forKey: "long-key")
        let retrieved = keychain.get("long-key")

        XCTAssertEqual(retrieved, value)
    }

    func testKeychainWrapperEmptyValue() {
        keychain.set("", forKey: "empty-key")
        let retrieved = keychain.get("empty-key")

        XCTAssertEqual(retrieved, "")
    }

    func testKeychainWrapperDeleteNonexistentKey() {
        // Should not throw or crash
        keychain.delete("nonexistent-key")

        XCTAssertNil(keychain.get("nonexistent-key"))
    }

    // MARK: - TokenManager Tests

    func testTokenManagerStoreAndRetrieveTokens() async {
        await tokenManager.storeTokens(
            accessToken: "access-token-123",
            refreshToken: "refresh-token-456",
            idToken: "id-token-789",
            expiresIn: 3600
        )

        let accessToken = await tokenManager.accessToken
        let refreshToken = await tokenManager.refreshToken
        let idToken = await tokenManager.idToken

        XCTAssertEqual(accessToken, "access-token-123")
        XCTAssertEqual(refreshToken, "refresh-token-456")
        XCTAssertEqual(idToken, "id-token-789")
    }

    func testTokenManagerStoreTokensWithNilOptionals() async {
        await tokenManager.storeTokens(
            accessToken: "access-only",
            refreshToken: nil,
            idToken: nil,
            expiresIn: 3600
        )

        let accessToken = await tokenManager.accessToken
        let refreshToken = await tokenManager.refreshToken
        let idToken = await tokenManager.idToken

        XCTAssertEqual(accessToken, "access-only")
        XCTAssertNil(refreshToken)
        XCTAssertNil(idToken)
    }

    func testTokenManagerClearTokens() async {
        await tokenManager.storeTokens(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            idToken: "id-token",
            expiresIn: 3600
        )

        await tokenManager.clearTokens()

        let accessToken = await tokenManager.accessToken
        let refreshToken = await tokenManager.refreshToken
        let idToken = await tokenManager.idToken

        XCTAssertNil(accessToken)
        XCTAssertNil(refreshToken)
        XCTAssertNil(idToken)
    }

    func testTokenManagerIsTokenExpiredWithValidToken() async {
        await tokenManager.storeTokens(
            accessToken: "access-token",
            refreshToken: nil,
            idToken: nil,
            expiresIn: 7200 // 2 hours
        )

        let isExpired = await tokenManager.isTokenExpired

        XCTAssertFalse(isExpired)
    }

    func testTokenManagerIsTokenExpiredWithExpiredToken() async {
        await tokenManager.storeTokens(
            accessToken: "access-token",
            refreshToken: nil,
            idToken: nil,
            expiresIn: 0 // Immediately expires
        )

        let isExpired = await tokenManager.isTokenExpired

        XCTAssertTrue(isExpired)
    }

    func testTokenManagerHasValidTokensWithValidToken() async {
        await tokenManager.storeTokens(
            accessToken: "access-token",
            refreshToken: nil,
            idToken: nil,
            expiresIn: 3600
        )

        let hasValidTokens = await tokenManager.hasValidTokens

        XCTAssertTrue(hasValidTokens)
    }

    func testTokenManagerHasValidTokensWithoutToken() async {
        await tokenManager.clearTokens()

        let hasValidTokens = await tokenManager.hasValidTokens

        XCTAssertFalse(hasValidTokens)
    }

    // MARK: - JWT Decoding Tests

    func testTokenManagerDecodeJWTValidToken() async {
        // Create a simple JWT with base64url encoded payload
        // Header: {"alg":"HS256","typ":"JWT"}
        // Payload: {"sub":"user-123","email":"test@example.com","name":"Test User"}
        // Signature: test

        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "eyJzdWIiOiJ1c2VyLTEyMyIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsIm5hbWUiOiJUZXN0IFVzZXIifQ"
        let signature = "test-signature"
        let token = "\(header).\(payload).\(signature)"

        let claims = await tokenManager.decodeJWT(token)

        XCTAssertNotNil(claims)
        XCTAssertEqual(claims?["sub"] as? String, "user-123")
        XCTAssertEqual(claims?["email"] as? String, "test@example.com")
        XCTAssertEqual(claims?["name"] as? String, "Test User")
    }

    func testTokenManagerDecodeJWTInvalidToken() async {
        let invalidToken = "not-a-valid-jwt"

        let claims = await tokenManager.decodeJWT(invalidToken)

        XCTAssertNil(claims)
    }

    func testTokenManagerDecodeJWTMissingSegments() async {
        let twoSegments = "header.payload"

        let claims = await tokenManager.decodeJWT(twoSegments)

        XCTAssertNil(claims)
    }

    func testTokenManagerDecodeJWTInvalidBase64() async {
        let invalidBase64 = "header.!!!invalid-base64!!!.signature"

        let claims = await tokenManager.decodeJWT(invalidBase64)

        XCTAssertNil(claims)
    }

    func testTokenManagerGetUserIdWithToken() async {
        // Store a token with user ID in claims
        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "eyJzdWIiOiJhcHBsZXwxMjM0NTYifQ" // {"sub":"apple|123456"}
        let signature = "sig"
        let idToken = "\(header).\(payload).\(signature)"

        await tokenManager.storeTokens(
            accessToken: "access",
            refreshToken: nil,
            idToken: idToken,
            expiresIn: 3600
        )

        let userId = await tokenManager.getUserId()

        XCTAssertEqual(userId, "apple|123456")
    }

    func testTokenManagerGetUserIdWithoutToken() async {
        await tokenManager.clearTokens()

        let userId = await tokenManager.getUserId()

        XCTAssertNil(userId)
    }

    func testTokenManagerGetUserEmailWithToken() async {
        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20ifQ" // {"email":"user@example.com"}
        let signature = "sig"
        let idToken = "\(header).\(payload).\(signature)"

        await tokenManager.storeTokens(
            accessToken: "access",
            refreshToken: nil,
            idToken: idToken,
            expiresIn: 3600
        )

        let email = await tokenManager.getUserEmail()

        XCTAssertEqual(email, "user@example.com")
    }

    func testTokenManagerGetUserEmailWithoutToken() async {
        await tokenManager.clearTokens()

        let email = await tokenManager.getUserEmail()

        XCTAssertNil(email)
    }

    // MARK: - StorageError Tests

    func testStorageErrorEncodingFailed() {
        let error = StorageError.encodingFailed
        XCTAssertNotNil(error)
    }

    func testStorageErrorDecodingFailed() {
        let error = StorageError.decodingFailed
        XCTAssertNotNil(error)
    }

    func testStorageErrorNotFound() {
        let error = StorageError.notFound
        XCTAssertNotNil(error)
    }

    // MARK: - KeychainSecureStorage Tests

    func testKeychainSecureStorageStoreAndRetrieve() async throws {
        let storage = KeychainSecureStorage(keychain: keychain)
        let testData = "test-data".data(using: .utf8)!

        try await storage.store(testData, forKey: "secure-key")
        let retrieved = try await storage.retrieve(forKey: "secure-key")

        XCTAssertEqual(retrieved, testData)
    }

    func testKeychainSecureStorageRetrieveNonexistent() async throws {
        let storage = KeychainSecureStorage(keychain: keychain)

        let retrieved = try await storage.retrieve(forKey: "nonexistent")

        XCTAssertNil(retrieved)
    }

    func testKeychainSecureStorageDelete() async throws {
        let storage = KeychainSecureStorage(keychain: keychain)
        let testData = "test-data".data(using: .utf8)!

        try await storage.store(testData, forKey: "delete-key")
        try await storage.delete(forKey: "delete-key")
        let retrieved = try await storage.retrieve(forKey: "delete-key")

        XCTAssertNil(retrieved)
    }

    // MARK: - TokenManager Shared Instance

    func testTokenManagerSharedInstance() async {
        let instance1 = TokenManager.shared
        let instance2 = TokenManager.shared

        // Both should access the same actor
        let token1 = await instance1.accessToken
        let token2 = await instance2.accessToken

        XCTAssertEqual(token1, token2)
    }

    // MARK: - Edge Cases

    func testTokenManagerTokenExpirationEdgeCase() async {
        // Token that expires in exactly the threshold time
        await tokenManager.storeTokens(
            accessToken: "token",
            refreshToken: nil,
            idToken: nil,
            expiresIn: Int(Constants.Auth.tokenRefreshThreshold)
        )

        let isExpired = await tokenManager.isTokenExpired

        // Should be considered expired because it's within the threshold
        XCTAssertTrue(isExpired)
    }

    func testTokenManagerOverwriteTokens() async {
        await tokenManager.storeTokens(
            accessToken: "first-token",
            refreshToken: "first-refresh",
            idToken: nil,
            expiresIn: 3600
        )

        await tokenManager.storeTokens(
            accessToken: "second-token",
            refreshToken: "second-refresh",
            idToken: nil,
            expiresIn: 7200
        )

        let accessToken = await tokenManager.accessToken
        let refreshToken = await tokenManager.refreshToken

        XCTAssertEqual(accessToken, "second-token")
        XCTAssertEqual(refreshToken, "second-refresh")
    }

    func testKeychainWrapperThreadSafety() async {
        // Concurrent writes and reads
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    self.keychain.set("value-\(i)", forKey: "concurrent-key")
                }
                group.addTask {
                    _ = self.keychain.get("concurrent-key")
                }
            }
        }

        // Should not crash - final value should be one of the written values
        let finalValue = keychain.get("concurrent-key")
        XCTAssertNotNil(finalValue)
        XCTAssertTrue(finalValue?.hasPrefix("value-") ?? false)
    }
}
