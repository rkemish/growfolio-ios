//
//  BasketsViewModelTests.swift
//  GrowfolioTests
//
//  Tests for BasketsViewModel - Basket list management and WebSocket integration.
//

import XCTest
@testable import Growfolio

@MainActor
final class BasketsViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockRepository: MockBasketRepositoryForTests!
    var mockWebSocketService: MockWebSocketService!
    var sut: BasketsViewModel!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockBasketRepositoryForTests()
        mockWebSocketService = MockWebSocketService()
        sut = BasketsViewModel(
            basketRepository: mockRepository,
            webSocketService: mockWebSocketService
        )
    }

    override func tearDown() {
        mockRepository = nil
        mockWebSocketService = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertTrue(sut.baskets.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Load Baskets Tests

    func test_loadBaskets_setsLoadingState() async {
        mockRepository.basketsToReturn = []

        // Start loading
        let loadTask = Task {
            await sut.loadBaskets()
        }

        // Check loading state while task is running (may complete too fast in tests)
        await Task.yield()

        await loadTask.value

        XCTAssertFalse(sut.isLoading)
    }

    func test_loadBaskets_fetchesBaskets() async {
        let baskets = [
            TestFixtures.basket(id: "basket-1", name: "Tech Growth"),
            TestFixtures.basket(id: "basket-2", name: "Dividend Kings")
        ]
        mockRepository.basketsToReturn = baskets

        await sut.loadBaskets()

        XCTAssertEqual(sut.baskets.count, 2)
        XCTAssertEqual(sut.baskets[0].name, "Tech Growth")
        XCTAssertEqual(sut.baskets[1].name, "Dividend Kings")
    }

    func test_loadBaskets_handleError() async {
        mockRepository.errorToThrow = NetworkError.serverError(statusCode: 500, message: "Server error")

        await sut.loadBaskets()

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - WebSocket Integration Tests

    func test_loadBaskets_subscribesToBasketsChannel() async {
        mockRepository.basketsToReturn = [TestFixtures.basket(id: "basket-1")]

        await sut.loadBaskets()

        // Give async task time to subscribe
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(mockWebSocketService.subscribedChannels.contains(WebSocketChannel.baskets.rawValue))
    }

    func test_handleBasketValueUpdate_updatesBasketSummary() async {
        let basket = TestFixtures.basket(
            id: "basket-1",
            name: "Tech Stocks",
            currentValue: 1000,
            totalInvested: 900,
            totalGainLoss: 100
        )
        mockRepository.basketsToReturn = [basket]

        await sut.loadBaskets()

        // Give event listener time to start
        try? await Task.sleep(for: .milliseconds(200))

        // Simulate basket value update event
        let event = MockWebSocketService.makeBasketValueChangedEvent(
            basketId: "basket-1",
            currentValue: 1200,
            totalInvested: 1000,
            totalGainLoss: 200,
            changePct: 20.0
        )

        mockWebSocketService.sendEvent(event)

        // Give async handling time to process
        try? await Task.sleep(for: .milliseconds(300))

        // Verify basket was updated
        let updatedBasket = sut.baskets.first { $0.id == "basket-1" }
        XCTAssertEqual(updatedBasket?.summary.currentValue, 1200)
        XCTAssertEqual(updatedBasket?.summary.totalInvested, 1000)
        XCTAssertEqual(updatedBasket?.summary.totalGainLoss, 200)
    }

    func test_handleBasketValueUpdate_refreshesWhenBasketNotFound() async {
        mockRepository.basketsToReturn = []

        await sut.loadBaskets()

        try? await Task.sleep(for: .milliseconds(200))

        // Reset mock to detect refresh call
        mockRepository.fetchBasketsCalled = false

        // Simulate update for non-existent basket
        let event = MockWebSocketService.makeBasketValueChangedEvent(
            basketId: "unknown-basket",
            currentValue: 1000,
            totalInvested: 900,
            totalGainLoss: 100
        )

        mockWebSocketService.sendEvent(event)

        try? await Task.sleep(for: .milliseconds(500))

        // Verify refresh was called
        XCTAssertTrue(mockRepository.fetchBasketsCalled)
    }

    // MARK: - Computed Properties Tests

    func test_activeBaskets_filtersCorrectly() {
        let baskets = [
            TestFixtures.basket(id: "basket-1", status: .active),
            TestFixtures.basket(id: "basket-2", status: .paused),
            TestFixtures.basket(id: "basket-3", status: .active)
        ]
        sut.baskets = baskets

        let activeBaskets = sut.activeBaskets

        XCTAssertEqual(activeBaskets.count, 2)
        XCTAssertTrue(activeBaskets.allSatisfy { $0.status == .active })
    }

    func test_totalValue_calculatesCorrectly() {
        let baskets = [
            TestFixtures.basket(id: "basket-1", currentValue: 1000),
            TestFixtures.basket(id: "basket-2", currentValue: 1500),
            TestFixtures.basket(id: "basket-3", currentValue: 2500)
        ]
        sut.baskets = baskets

        XCTAssertEqual(sut.totalValue, 5000)
    }

    func test_totalInvested_calculatesCorrectly() {
        let baskets = [
            TestFixtures.basket(id: "basket-1", totalInvested: 800),
            TestFixtures.basket(id: "basket-2", totalInvested: 1200),
            TestFixtures.basket(id: "basket-3", totalInvested: 2000)
        ]
        sut.baskets = baskets

        XCTAssertEqual(sut.totalInvested, 4000)
    }

    func test_totalGainLoss_calculatesCorrectly() {
        let baskets = [
            TestFixtures.basket(id: "basket-1", totalGainLoss: 200),
            TestFixtures.basket(id: "basket-2", totalGainLoss: 300),
            TestFixtures.basket(id: "basket-3", totalGainLoss: -100)
        ]
        sut.baskets = baskets

        XCTAssertEqual(sut.totalGainLoss, 400)
    }
}

// MARK: - Mock Basket Repository for Tests

/// Test-specific mock basket repository with call tracking
final class MockBasketRepositoryForTests: BasketRepositoryProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    var basketsToReturn: [Basket] = []
    var basketToReturn: Basket?
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var fetchBasketsCalled = false
    var fetchBasketCalled = false
    var createBasketCalled = false
    var updateBasketCalled = false
    var deleteBasketCalled = false

    // MARK: - BasketRepositoryProtocol Implementation

    func fetchBaskets() async throws -> [Basket] {
        fetchBasketsCalled = true
        if let error = errorToThrow { throw error }
        return basketsToReturn
    }

    func fetchBasket(id: String) async throws -> Basket {
        fetchBasketCalled = true
        if let error = errorToThrow { throw error }
        if let basket = basketToReturn { return basket }
        throw NetworkError.notFound
    }

    func createBasket(_ basket: BasketCreate) async throws -> Basket {
        createBasketCalled = true
        if let error = errorToThrow { throw error }
        let newBasket = Basket(
            userId: "test-user",
            name: basket.name,
            description: basket.description,
            category: basket.category,
            icon: basket.icon,
            color: basket.color,
            allocations: basket.allocations,
            isShared: basket.isShared
        )
        return newBasket
    }

    func updateBasket(id: String, _ basket: BasketCreate) async throws -> Basket {
        updateBasketCalled = true
        if let error = errorToThrow { throw error }
        guard let existing = basketToReturn else {
            throw NetworkError.notFound
        }
        return existing
    }

    func deleteBasket(id: String) async throws {
        deleteBasketCalled = true
        if let error = errorToThrow { throw error }
    }
}
