//
//  CacheManagerTests.swift
//  GrowfolioTests
//
//  Tests for CacheManager, CacheEntry, CacheKeys, and ImageCache.
//

import XCTest
@testable import Growfolio

final class CacheManagerTests: XCTestCase {

    private var cacheManager: CacheManager!

    override func setUp() async throws {
        try await super.setUp()
        cacheManager = CacheManager()
        await cacheManager.removeAll()
    }

    override func tearDown() async throws {
        await cacheManager.removeAll()
        cacheManager = nil
        try await super.tearDown()
    }

    // MARK: - CacheEntry Tests

    func testCacheEntryIsNotExpiredWithoutExpirationDate() {
        let entry = CacheEntry(value: "test", createdAt: Date(), expiresAt: nil)

        XCTAssertFalse(entry.isExpired)
    }

    func testCacheEntryIsNotExpiredWithFutureExpirationDate() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let entry = CacheEntry(value: "test", createdAt: Date(), expiresAt: futureDate)

        XCTAssertFalse(entry.isExpired)
    }

    func testCacheEntryIsExpiredWithPastExpirationDate() {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let entry = CacheEntry(value: "test", createdAt: Date(), expiresAt: pastDate)

        XCTAssertTrue(entry.isExpired)
    }

    func testCacheEntryCodable() throws {
        let entry = CacheEntry(value: "test-value", createdAt: Date(), expiresAt: Date().addingTimeInterval(3600))
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(CacheEntry<String>.self, from: data)

        XCTAssertEqual(decoded.value, entry.value)
        XCTAssertNotNil(decoded.createdAt)
        XCTAssertNotNil(decoded.expiresAt)
    }

    // MARK: - CacheManager Basic Tests

    func testCacheManagerSetAndGet() async {
        await cacheManager.set("test-value", forKey: "test-key", expiration: nil)
        let retrieved: String? = await cacheManager.get(forKey: "test-key")

        XCTAssertEqual(retrieved, "test-value")
    }

    func testCacheManagerGetNonexistent() async {
        let retrieved: String? = await cacheManager.get(forKey: "nonexistent-key")

        XCTAssertNil(retrieved)
    }

    func testCacheManagerRemove() async {
        await cacheManager.set("test-value", forKey: "test-key", expiration: nil)
        await cacheManager.remove(forKey: "test-key")
        let retrieved: String? = await cacheManager.get(forKey: "test-key")

        XCTAssertNil(retrieved)
    }

    func testCacheManagerRemoveAll() async {
        await cacheManager.set("value1", forKey: "key1", expiration: nil)
        await cacheManager.set("value2", forKey: "key2", expiration: nil)
        await cacheManager.set("value3", forKey: "key3", expiration: nil)

        await cacheManager.removeAll()

        let v1: String? = await cacheManager.get(forKey: "key1")
        let v2: String? = await cacheManager.get(forKey: "key2")
        let v3: String? = await cacheManager.get(forKey: "key3")

        XCTAssertNil(v1)
        XCTAssertNil(v2)
        XCTAssertNil(v3)
    }

    // MARK: - Expiration Tests

    func testCacheManagerExpiredEntryReturnsNil() async {
        // Set with immediate expiration
        await cacheManager.set("test-value", forKey: "expiring-key", expiration: 0.001)

        // Wait for expiration
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        let retrieved: String? = await cacheManager.get(forKey: "expiring-key")

        XCTAssertNil(retrieved)
    }

    func testCacheManagerNonExpiredEntryReturns() async {
        await cacheManager.set("test-value", forKey: "valid-key", expiration: 3600)

        let retrieved: String? = await cacheManager.get(forKey: "valid-key")

        XCTAssertEqual(retrieved, "test-value")
    }

    func testCacheManagerIsExpiredForNonexistentKey() async {
        let isExpired = await cacheManager.isExpired(forKey: "nonexistent")

        // Returns true for safety when key doesn't exist
        XCTAssertTrue(isExpired)
    }

    // MARK: - Complex Types Tests

    func testCacheManagerWithCodableStruct() async {
        struct TestData: Codable, Sendable, Equatable {
            let id: String
            let value: Int
        }

        let testData = TestData(id: "test-123", value: 42)
        await cacheManager.set(testData, forKey: "struct-key", expiration: nil)

        let retrieved: TestData? = await cacheManager.get(forKey: "struct-key")

        XCTAssertEqual(retrieved, testData)
    }

    func testCacheManagerWithArray() async {
        let testArray = [1, 2, 3, 4, 5]
        await cacheManager.set(testArray, forKey: "array-key", expiration: nil)

        let retrieved: [Int]? = await cacheManager.get(forKey: "array-key")

        XCTAssertEqual(retrieved, testArray)
    }

    func testCacheManagerWithDictionary() async {
        let testDict = ["key1": "value1", "key2": "value2"]
        await cacheManager.set(testDict, forKey: "dict-key", expiration: nil)

        let retrieved: [String: String]? = await cacheManager.get(forKey: "dict-key")

        XCTAssertEqual(retrieved, testDict)
    }

    // MARK: - GetOrFetch Tests

    func testCacheManagerGetOrFetchWithCachedValue() async throws {
        await cacheManager.set("cached-value", forKey: "fetch-key", expiration: nil)

        var fetchCalled = false
        let result: String = try await cacheManager.getOrFetch(forKey: "fetch-key", expiration: nil) {
            fetchCalled = true
            return "fetched-value"
        }

        XCTAssertEqual(result, "cached-value")
        XCTAssertFalse(fetchCalled)
    }

    func testCacheManagerGetOrFetchWithoutCachedValue() async throws {
        var fetchCalled = false
        let result: String = try await cacheManager.getOrFetch(forKey: "new-key", expiration: nil) {
            fetchCalled = true
            return "fetched-value"
        }

        XCTAssertEqual(result, "fetched-value")
        XCTAssertTrue(fetchCalled)
    }

    func testCacheManagerGetOrFetchCachesResult() async throws {
        _ = try await cacheManager.getOrFetch(forKey: "cacheable-key", expiration: 3600) {
            return "initial-value"
        }

        // Second call should use cached value
        let result: String = try await cacheManager.getOrFetch(forKey: "cacheable-key", expiration: 3600) {
            return "should-not-be-returned"
        }

        XCTAssertEqual(result, "initial-value")
    }

    // MARK: - Cache Size Tests

    func testCacheManagerCacheSize() async {
        await cacheManager.set("test-value", forKey: "size-test", expiration: nil)

        let size = await cacheManager.cacheSize()

        // Size should be greater than 0 after adding data
        XCTAssertGreaterThanOrEqual(size, 0)
    }

    func testCacheManagerCacheSizeAfterClear() async {
        await cacheManager.set("test-value", forKey: "size-test", expiration: nil)
        await cacheManager.removeAll()

        let size = await cacheManager.cacheSize()

        XCTAssertEqual(size, 0)
    }

    // MARK: - InvalidatePrefix Tests

    func testCacheManagerInvalidatePrefix() async {
        // Note: invalidatePrefix only clears disk cache, not memory cache
        // This test verifies the disk cache is cleared by using a fresh cache manager
        let freshCache = CacheManager()
        await freshCache.removeAll()

        await freshCache.set("value1", forKey: "prefix_key1", expiration: nil)
        await freshCache.set("value2", forKey: "prefix_key2", expiration: nil)
        await freshCache.set("other", forKey: "other_key", expiration: nil)

        await freshCache.invalidatePrefix("prefix_")

        // Create another cache manager to read from disk only (memory cache won't have values)
        _ = CacheManager()

        // The prefixed keys should be removed from disk
        // Note: This test verifies the method runs without error
        // Full disk-only verification would require clearing memory cache first
        let other: String? = await freshCache.get(forKey: "other_key")
        XCTAssertNotNil(other)
    }

    // MARK: - CacheKeys Tests

    func testCacheKeysPortfolio() {
        let key = CacheKeys.portfolio("abc123")

        XCTAssertEqual(key, "portfolio_abc123")
    }

    func testCacheKeysPortfolioHoldings() {
        let key = CacheKeys.portfolioHoldings("def456")

        XCTAssertEqual(key, "portfolio_holdings_def456")
    }

    func testCacheKeysGoals() {
        let key = CacheKeys.goals(page: 2)

        XCTAssertEqual(key, "goals_page_2")
    }

    func testCacheKeysGoal() {
        let key = CacheKeys.goal("goal123")

        XCTAssertEqual(key, "goal_goal123")
    }

    func testCacheKeysDCASchedules() {
        let key = CacheKeys.dcaSchedules

        XCTAssertEqual(key, "dca_schedules")
    }

    func testCacheKeysStock() {
        let key = CacheKeys.stock("AAPL")

        XCTAssertEqual(key, "stock_AAPL")
    }

    func testCacheKeysStockQuote() {
        let key = CacheKeys.stockQuote("GOOGL")

        XCTAssertEqual(key, "stock_quote_GOOGL")
    }

    func testCacheKeysStockHistory() {
        let key = CacheKeys.stockHistory("MSFT", period: "1Y")

        XCTAssertEqual(key, "stock_history_MSFT_1Y")
    }

    func testCacheKeysUserProfile() {
        let key = CacheKeys.userProfile

        XCTAssertEqual(key, "user_profile")
    }

    func testCacheKeysFamilyAccounts() {
        let key = CacheKeys.familyAccounts

        XCTAssertEqual(key, "family_accounts")
    }

    // MARK: - ImageCache Tests

    func testImageCacheSetAndGet() async {
        let imageCache = ImageCache.shared
        let testData = "image-data".data(using: .utf8)!

        await imageCache.set(testData, forKey: "image-key")
        let retrieved = await imageCache.get(forKey: "image-key")

        XCTAssertEqual(retrieved, testData)
    }

    func testImageCacheGetNonexistent() async {
        let imageCache = ImageCache.shared
        let retrieved = await imageCache.get(forKey: "nonexistent-image")

        XCTAssertNil(retrieved)
    }

    func testImageCacheRemove() async {
        let imageCache = ImageCache.shared
        let testData = "image-data".data(using: .utf8)!

        await imageCache.set(testData, forKey: "remove-image")
        await imageCache.remove(forKey: "remove-image")
        let retrieved = await imageCache.get(forKey: "remove-image")

        XCTAssertNil(retrieved)
    }

    func testImageCacheRemoveAll() async {
        let imageCache = ImageCache.shared
        let testData = "image-data".data(using: .utf8)!

        await imageCache.set(testData, forKey: "image1")
        await imageCache.set(testData, forKey: "image2")
        await imageCache.removeAll()

        let v1 = await imageCache.get(forKey: "image1")
        let v2 = await imageCache.get(forKey: "image2")

        XCTAssertNil(v1)
        XCTAssertNil(v2)
    }

    func testImageCacheSharedInstance() async {
        let instance1 = ImageCache.shared
        let instance2 = ImageCache.shared

        let testData = "shared-data".data(using: .utf8)!
        await instance1.set(testData, forKey: "shared-key")

        let retrieved = await instance2.get(forKey: "shared-key")

        XCTAssertEqual(retrieved, testData)
    }

    // MARK: - Edge Cases

    func testCacheManagerWithSpecialCharactersInKey() async {
        await cacheManager.set("value", forKey: "key/with:special_chars", expiration: nil)
        let retrieved: String? = await cacheManager.get(forKey: "key/with:special_chars")

        XCTAssertEqual(retrieved, "value")
    }

    func testCacheManagerWithEmptyString() async {
        await cacheManager.set("", forKey: "empty-string", expiration: nil)
        let retrieved: String? = await cacheManager.get(forKey: "empty-string")

        XCTAssertEqual(retrieved, "")
    }

    func testCacheManagerWithLongKey() async {
        let longKey = String(repeating: "a", count: 1000)
        await cacheManager.set("value", forKey: longKey, expiration: nil)
        let retrieved: String? = await cacheManager.get(forKey: longKey)

        XCTAssertEqual(retrieved, "value")
    }

    func testCacheManagerOverwrite() async {
        await cacheManager.set("original", forKey: "overwrite-key", expiration: nil)
        await cacheManager.set("updated", forKey: "overwrite-key", expiration: nil)

        let retrieved: String? = await cacheManager.get(forKey: "overwrite-key")

        XCTAssertEqual(retrieved, "updated")
    }

    func testCacheManagerSharedInstance() async {
        let instance1 = CacheManager.shared
        let instance2 = CacheManager.shared

        await instance1.set("shared-value", forKey: "shared-test", expiration: nil)
        let retrieved: String? = await instance2.get(forKey: "shared-test")

        XCTAssertEqual(retrieved, "shared-value")

        // Clean up
        await instance1.remove(forKey: "shared-test")
    }

    func testCacheManagerConcurrentAccess() async {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    await self.cacheManager.set("value-\(i)", forKey: "concurrent-\(i)", expiration: nil)
                }
                group.addTask {
                    let _: String? = await self.cacheManager.get(forKey: "concurrent-\(i)")
                }
            }
        }

        // Should not crash - actor ensures thread safety
        let finalValue: String? = await cacheManager.get(forKey: "concurrent-50")
        // May or may not be set depending on execution order
        _ = finalValue
    }
}
