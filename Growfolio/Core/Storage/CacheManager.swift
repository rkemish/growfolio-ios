//
//  CacheManager.swift
//  Growfolio
//
//  Cache management for storing and retrieving cached data.
//

import Foundation

// MARK: - Cache Protocol

/// Protocol for cache storage
protocol CacheProtocol: Sendable {
    func get<T: Codable & Sendable>(forKey key: String) async -> T?
    func set<T: Codable & Sendable>(_ value: T, forKey key: String, expiration: TimeInterval?) async
    func remove(forKey key: String) async
    func removeAll() async
    func isExpired(forKey key: String) async -> Bool
}

// MARK: - Cache Entry

/// Wrapper for cached items with expiration
struct CacheEntry<T: Codable & Sendable>: Codable, Sendable {
    let value: T
    let createdAt: Date
    let expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

// MARK: - Cache Manager

/// Actor-based cache manager for thread-safe caching
actor CacheManager: CacheProtocol {

    // MARK: - Singleton

    static let shared = CacheManager()

    // MARK: - Properties

    private let memoryCache = NSCache<NSString, CacheBox>()
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent(Constants.Cache.cacheDirectoryName, isDirectory: true)
    }

    // MARK: - Initialization

    init() {
        memoryCache.totalCostLimit = Constants.Cache.maxCacheSize
        Task { await self.createCacheDirectoryIfNeeded() }
    }

    // MARK: - CacheProtocol

    func get<T: Codable & Sendable>(forKey key: String) async -> T? {
        // Check memory cache first
        if let box = memoryCache.object(forKey: key as NSString),
           let entry = box.entry as? CacheEntry<T>,
           !entry.isExpired {
            return entry.value
        }

        // Check disk cache
        guard let entry: CacheEntry<T> = readFromDisk(forKey: key) else {
            return nil
        }

        guard !entry.isExpired else {
            // Remove expired entry
            await remove(forKey: key)
            return nil
        }

        // Update memory cache
        let box = CacheBox(entry: entry)
        memoryCache.setObject(box, forKey: key as NSString)

        return entry.value
    }

    func set<T: Codable & Sendable>(_ value: T, forKey key: String, expiration: TimeInterval? = nil) async {
        let expiresAt = expiration.map { Date().addingTimeInterval($0) }
        let entry = CacheEntry(value: value, createdAt: Date(), expiresAt: expiresAt)

        // Update memory cache
        let box = CacheBox(entry: entry)
        memoryCache.setObject(box, forKey: key as NSString)

        // Write to disk
        writeToDisk(entry, forKey: key)
    }

    func remove(forKey key: String) async {
        memoryCache.removeObject(forKey: key as NSString)
        removeFromDisk(forKey: key)
    }

    func removeAll() async {
        memoryCache.removeAllObjects()
        removeAllFromDisk()
    }

    func isExpired(forKey key: String) async -> Bool {
        // Check memory cache
        if let box = memoryCache.object(forKey: key as NSString) {
            return box.isExpired
        }

        // We can't determine expiration without knowing the type
        // Return true to be safe
        return true
    }

    // MARK: - Convenience Methods

    /// Get cached value or fetch from source if not available
    func getOrFetch<T: Codable & Sendable>(
        forKey key: String,
        expiration: TimeInterval? = nil,
        fetch: () async throws -> T
    ) async throws -> T {
        // Try cache first
        if let cached: T = await get(forKey: key) {
            return cached
        }

        // Fetch from source
        let value = try await fetch()

        // Cache the result
        await set(value, forKey: key, expiration: expiration)

        return value
    }

    /// Invalidate cache entries matching a prefix
    func invalidatePrefix(_ prefix: String) async {
        // Clear matching items from disk
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        for url in contents {
            let filename = url.lastPathComponent
            if filename.hasPrefix(prefix) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    /// Get cache size in bytes
    func cacheSize() -> Int {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + size
        }
    }

    /// Prune expired entries
    func pruneExpired() async {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        for url in contents {
            if let data = try? Data(contentsOf: url),
               let metadata = try? decoder.decode(CacheMetadata.self, from: data),
               metadata.isExpired {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    // MARK: - Private Methods

    private func createCacheDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: cacheDirectory.path) else { return }
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func fileURL(forKey key: String) -> URL {
        let sanitizedKey = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return cacheDirectory.appendingPathComponent(sanitizedKey)
    }

    private func writeToDisk<T: Codable>(_ entry: CacheEntry<T>, forKey key: String) {
        let url = fileURL(forKey: key)
        guard let data = try? encoder.encode(entry) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func readFromDisk<T: Codable>(forKey key: String) -> CacheEntry<T>? {
        let url = fileURL(forKey: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(CacheEntry<T>.self, from: data)
    }

    private func removeFromDisk(forKey key: String) {
        let url = fileURL(forKey: key)
        try? fileManager.removeItem(at: url)
    }

    private func removeAllFromDisk() {
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }
}

// MARK: - Cache Box

/// Box class for storing cache entries in NSCache
private final class CacheBox: @unchecked Sendable {
    let entry: Any
    let expiresAt: Date?

    init<T: Codable & Sendable>(entry: CacheEntry<T>) {
        self.entry = entry
        self.expiresAt = entry.expiresAt
    }

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

// MARK: - Cache Metadata

/// Minimal metadata for checking expiration without full deserialization
private struct CacheMetadata: Codable {
    let createdAt: Date
    let expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

// MARK: - Cache Keys

/// Standardized cache keys
enum CacheKeys {
    static func portfolio(_ id: String) -> String {
        "portfolio_\(id)"
    }

    static func portfolioHoldings(_ id: String) -> String {
        "portfolio_holdings_\(id)"
    }

    static func goals(page: Int) -> String {
        "goals_page_\(page)"
    }

    static func goal(_ id: String) -> String {
        "goal_\(id)"
    }

    static var dcaSchedules: String {
        "dca_schedules"
    }

    static func stock(_ symbol: String) -> String {
        "stock_\(symbol)"
    }

    static func stockQuote(_ symbol: String) -> String {
        "stock_quote_\(symbol)"
    }

    static func stockHistory(_ symbol: String, period: String) -> String {
        "stock_history_\(symbol)_\(period)"
    }

    static var userProfile: String {
        "user_profile"
    }

    static var familyAccounts: String {
        "family_accounts"
    }
}

// MARK: - Image Cache

/// Specialized cache for images
actor ImageCache {

    // MARK: - Singleton

    static let shared = ImageCache()

    // MARK: - Properties

    private let memoryCache = NSCache<NSString, ImageBox>()
    private let fileManager = FileManager.default

    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("ImageCache", isDirectory: true)
    }

    // MARK: - Initialization

    init() {
        memoryCache.totalCostLimit = 100 * 1024 * 1024  // 100 MB
        Task { await self.createCacheDirectoryIfNeeded() }
    }

    // MARK: - Public Methods

    func get(forKey key: String) -> Data? {
        // Check memory cache
        if let box = memoryCache.object(forKey: key as NSString) {
            return box.data
        }

        // Check disk cache
        let url = fileURL(forKey: key)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        // Update memory cache
        let box = ImageBox(data: data)
        memoryCache.setObject(box, forKey: key as NSString, cost: data.count)

        return data
    }

    func set(_ data: Data, forKey key: String) {
        // Update memory cache
        let box = ImageBox(data: data)
        memoryCache.setObject(box, forKey: key as NSString, cost: data.count)

        // Write to disk
        let url = fileURL(forKey: key)
        try? data.write(to: url, options: .atomic)
    }

    func remove(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        let url = fileURL(forKey: key)
        try? fileManager.removeItem(at: url)
    }

    func removeAll() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectoryIfNeeded()
    }

    // MARK: - Private Methods

    private func createCacheDirectoryIfNeeded() {
        guard !fileManager.fileExists(atPath: cacheDirectory.path) else { return }
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func fileURL(forKey key: String) -> URL {
        let hashedKey = key.data(using: .utf8)?.base64EncodedString() ?? key
        return cacheDirectory.appendingPathComponent(hashedKey)
    }
}

// MARK: - Image Box

private final class ImageBox: @unchecked Sendable {
    let data: Data

    init(data: Data) {
        self.data = data
    }
}
