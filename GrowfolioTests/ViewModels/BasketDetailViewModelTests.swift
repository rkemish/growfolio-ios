//
//  BasketDetailViewModelTests.swift
//  GrowfolioTests
//
//  Tests for BasketDetailViewModel - Basket detail view and WebSocket integration.
//

import XCTest
@testable import Growfolio

@MainActor
final class BasketDetailViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockRepository: MockBasketDetailRepositoryForTests!
    var mockWebSocketService: MockWebSocketService!
    var sut: BasketDetailViewModel!
    var testBasket: Basket!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockBasketDetailRepositoryForTests()
        mockWebSocketService = MockWebSocketService()
        testBasket = TestFixtures.basket(
            id: "basket-1",
            name: "Tech Growth",
            currentValue: 1000,
            totalInvested: 900,
            totalGainLoss: 100
        )
        sut = BasketDetailViewModel(
            basket: testBasket,
            basketRepository: mockRepository,
            webSocketService: mockWebSocketService
        )
    }

    override func tearDown() {
        mockRepository = nil
        mockWebSocketService = nil
        testBasket = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasBasket() {
        XCTAssertEqual(sut.basket.id, "basket-1")
        XCTAssertEqual(sut.basket.name, "Tech Growth")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Computed Properties Tests

    func test_returnPercentage_calculatesCorrectly() {
        let basket = TestFixtures.basket(
            id: "basket-1",
            currentValue: 1500,
            totalInvested: 1000,
            totalGainLoss: 500
        )
        sut.basket = basket

        // returnPercentage should be (500 / 1000) * 100 = 50%
        XCTAssertEqual(sut.returnPercentage, 50.0)
    }

    func test_isGaining_returnsTrueForPositiveGainLoss() {
        let basket = TestFixtures.basket(
            id: "basket-1",
            totalGainLoss: 100
        )
        sut.basket = basket

        XCTAssertTrue(sut.isGaining)
    }

    func test_isGaining_returnsFalseForNegativeGainLoss() {
        let basket = TestFixtures.basket(
            id: "basket-1",
            totalGainLoss: -100
        )
        sut.basket = basket

        XCTAssertFalse(sut.isGaining)
    }

    // MARK: - WebSocket Integration Tests

    func test_startRealtimeUpdates_subscribesToBasketsChannel() async {
        await sut.startRealtimeUpdates()

        // Give async task time to subscribe
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(mockWebSocketService.subscribedChannels.contains(WebSocketChannel.baskets.rawValue))
    }

    func test_handleBasketValueUpdate_updatesCurrentBasket() async {
        await sut.startRealtimeUpdates()

        // Give event listener time to start
        try? await Task.sleep(for: .milliseconds(200))

        // Simulate value update
        let event = MockWebSocketService.makeBasketValueChangedEvent(
            basketId: "basket-1",
            currentValue: 1150,
            totalInvested: 1000,
            totalGainLoss: 150,
            changePct: 15.0
        )

        mockWebSocketService.sendEvent(event)

        // Give async handling time to process
        try? await Task.sleep(for: .milliseconds(300))

        // Verify basket updated
        XCTAssertEqual(sut.basket.summary.currentValue, 1150)
        XCTAssertEqual(sut.basket.summary.totalInvested, 1000)
        XCTAssertEqual(sut.basket.summary.totalGainLoss, 150)
        XCTAssertEqual(sut.returnPercentage, 15.0) // Computed property should auto-update
    }

    func test_handleBasketValueUpdate_ignoresOtherBaskets() async {
        await sut.startRealtimeUpdates()

        // Give event listener time to start
        try? await Task.sleep(for: .milliseconds(200))

        let originalValue = sut.basket.summary.currentValue
        let originalGainLoss = sut.basket.summary.totalGainLoss

        // Simulate update for different basket
        let event = MockWebSocketService.makeBasketValueChangedEvent(
            basketId: "basket-2",
            currentValue: 2000,
            totalInvested: 1500,
            totalGainLoss: 500
        )

        mockWebSocketService.sendEvent(event)

        // Give async handling time to process
        try? await Task.sleep(for: .milliseconds(300))

        // Verify basket NOT updated
        XCTAssertEqual(sut.basket.summary.currentValue, originalValue)
        XCTAssertEqual(sut.basket.summary.totalGainLoss, originalGainLoss)
    }

    // MARK: - Refresh Tests

    func test_refresh_updatesBasket() async {
        let updatedBasket = TestFixtures.basket(
            id: "basket-1",
            name: "Updated Tech Growth",
            currentValue: 1200,
            totalInvested: 1000,
            totalGainLoss: 200
        )
        mockRepository.basketToReturn = updatedBasket

        await sut.refresh()

        XCTAssertEqual(sut.basket.name, "Updated Tech Growth")
        XCTAssertEqual(sut.basket.summary.currentValue, 1200)
        XCTAssertEqual(sut.basket.summary.totalGainLoss, 200)
    }

    func test_refresh_handleError() async {
        mockRepository.errorToThrow = NetworkError.serverError(statusCode: 500, message: "Server error")

        await sut.refresh()

        XCTAssertTrue(sut.showError)
        XCTAssertNotNil(sut.errorMessage)
    }
}

// MARK: - Mock Basket Repository for Detail Tests

/// Test-specific mock basket repository with call tracking
final class MockBasketDetailRepositoryForTests: BasketRepositoryProtocol, @unchecked Sendable {

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
