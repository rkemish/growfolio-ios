//
//  TokenManager.swift
//  Growfolio
//
//  Secure token storage and management using Keychain.
//

import Foundation
import Security

// MARK: - Token Manager

/// Manages secure storage and retrieval of authentication tokens
actor TokenManager {

    // MARK: - Singleton

    static let shared = TokenManager()

    // MARK: - Properties

    private let keychain: KeychainWrapper
    private var cachedAccessToken: String?
    private var cachedRefreshToken: String?
    private var cachedIdToken: String?
    private var tokenExpirationDate: Date?

    // MARK: - Initialization

    init(keychain: KeychainWrapper = KeychainWrapper()) {
        self.keychain = keychain
        loadCachedTokens()
    }

    // MARK: - Public Properties

    var accessToken: String? {
        cachedAccessToken ?? keychain.get(Constants.Auth.accessTokenKey)
    }

    var refreshToken: String? {
        cachedRefreshToken ?? keychain.get(Constants.Auth.refreshTokenKey)
    }

    var idToken: String? {
        cachedIdToken ?? keychain.get(Constants.Auth.idTokenKey)
    }

    var isTokenExpired: Bool {
        guard let expirationDate = tokenExpirationDate else {
            return true
        }
        // Consider token expired if it expires within the threshold
        let thresholdDate = Date().addingTimeInterval(Constants.Auth.tokenRefreshThreshold)
        return expirationDate <= thresholdDate
    }

    var hasValidTokens: Bool {
        accessToken != nil && !isTokenExpired
    }

    // MARK: - Token Storage

    func storeTokens(
        accessToken: String,
        refreshToken: String?,
        idToken: String?,
        expiresIn: Int
    ) {
        // Store in keychain
        keychain.set(accessToken, forKey: Constants.Auth.accessTokenKey)

        if let refreshToken = refreshToken {
            keychain.set(refreshToken, forKey: Constants.Auth.refreshTokenKey)
        }

        if let idToken = idToken {
            keychain.set(idToken, forKey: Constants.Auth.idTokenKey)
        }

        // Cache tokens in memory
        self.cachedAccessToken = accessToken
        self.cachedRefreshToken = refreshToken
        self.cachedIdToken = idToken

        // Calculate expiration date
        self.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))

        // Store expiration date
        let expirationTimestamp = tokenExpirationDate?.timeIntervalSince1970 ?? 0
        UserDefaults.standard.set(expirationTimestamp, forKey: "tokenExpirationTimestamp")
    }

    func clearTokens() {
        // Clear keychain
        keychain.delete(Constants.Auth.accessTokenKey)
        keychain.delete(Constants.Auth.refreshTokenKey)
        keychain.delete(Constants.Auth.idTokenKey)

        // Clear cache
        cachedAccessToken = nil
        cachedRefreshToken = nil
        cachedIdToken = nil
        tokenExpirationDate = nil

        // Clear stored expiration
        UserDefaults.standard.removeObject(forKey: "tokenExpirationTimestamp")
    }

    // MARK: - Token Parsing

    /// Decode JWT token to extract claims (without verification)
    func decodeJWT(_ token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else { return nil }

        let payloadSegment = segments[1]

        // Add padding if needed
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddingLength = 4 - (base64.count % 4)
        if paddingLength < 4 {
            base64 += String(repeating: "=", count: paddingLength)
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return json
    }

    /// Get user ID from the current ID token
    func getUserId() -> String? {
        guard let token = idToken,
              let claims = decodeJWT(token) else {
            return nil
        }
        return claims["sub"] as? String
    }

    /// Get user email from the current ID token
    func getUserEmail() -> String? {
        guard let token = idToken,
              let claims = decodeJWT(token) else {
            return nil
        }
        return claims["email"] as? String
    }

    // MARK: - Private Methods

    private func loadCachedTokens() {
        cachedAccessToken = keychain.get(Constants.Auth.accessTokenKey)
        cachedRefreshToken = keychain.get(Constants.Auth.refreshTokenKey)
        cachedIdToken = keychain.get(Constants.Auth.idTokenKey)

        let expirationTimestamp = UserDefaults.standard.double(forKey: "tokenExpirationTimestamp")
        if expirationTimestamp > 0 {
            tokenExpirationDate = Date(timeIntervalSince1970: expirationTimestamp)
        }
    }
}

// MARK: - Keychain Wrapper

/// Wrapper for Keychain operations
final class KeychainWrapper: @unchecked Sendable {

    private let service: String
    private let accessGroup: String?
    private let queue = DispatchQueue(label: "com.growfolio.keychain", qos: .userInitiated)

    init(service: String = Constants.Auth.keychainService, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    // MARK: - CRUD Operations

    func set(_ value: String, forKey key: String) {
        queue.sync {
            guard let data = value.data(using: .utf8) else { return }

            // Delete existing item first
            deleteSync(key)

            var query = baseQuery(for: key)
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("Keychain write failed: \(status)")
            }
        }
    }

    func get(_ key: String) -> String? {
        queue.sync {
            var query = baseQuery(for: key)
            query[kSecReturnData as String] = kCFBooleanTrue
            query[kSecMatchLimit as String] = kSecMatchLimitOne

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            guard status == errSecSuccess,
                  let data = result as? Data,
                  let string = String(data: data, encoding: .utf8) else {
                return nil
            }

            return string
        }
    }

    func delete(_ key: String) {
        queue.sync {
            deleteSync(key)
        }
    }

    private func deleteSync(_ key: String) {
        let query = baseQuery(for: key)
        SecItemDelete(query as CFDictionary)
    }

    func deleteAll() {
        queue.sync {
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service
            ]

            if let accessGroup = accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }

            SecItemDelete(query as CFDictionary)
        }
    }

    // MARK: - Helper Methods

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

// MARK: - Secure Data Storage

/// Protocol for secure data storage
protocol SecureStorage: Sendable {
    func store(_ data: Data, forKey key: String) async throws
    func retrieve(forKey key: String) async throws -> Data?
    func delete(forKey key: String) async throws
}

/// Keychain-based secure storage implementation
actor KeychainSecureStorage: SecureStorage {
    private let keychain: KeychainWrapper

    init(keychain: KeychainWrapper = KeychainWrapper()) {
        self.keychain = keychain
    }

    func store(_ data: Data, forKey key: String) async throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw StorageError.encodingFailed
        }
        keychain.set(string, forKey: key)
    }

    func retrieve(forKey key: String) async throws -> Data? {
        guard let string = keychain.get(key) else {
            return nil
        }
        return string.data(using: .utf8)
    }

    func delete(forKey key: String) async throws {
        keychain.delete(key)
    }
}

enum StorageError: Error {
    case encodingFailed
    case decodingFailed
    case notFound
}
