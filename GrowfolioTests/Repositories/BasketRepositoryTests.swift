//
//  BasketRepositoryTests.swift
//  GrowfolioTests
//
//  Tests for BasketRepository.
//

import XCTest
@testable import Growfolio

final class BasketRepositoryTests: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var sut: BasketRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = BasketRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        mockAPIClient.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeBasketAllocation(
        symbol: String = "AAPL",
        name: String = "Apple Inc.",
        percentage: Decimal = 25
    ) -> BasketAllocation {
        BasketAllocation(
            symbol: symbol,
            name: name,
            percentage: percentage,
            targetShares: nil
        )
    }

    private func makeBasket(
        id: String = "basket-1",
        name: String = "Tech Portfolio",
        description: String? = "My technology stocks",
        category: String? = "Technology",
        allocations: [BasketAllocation]? = nil
    ) -> Basket {
        let defaultAllocations = allocations ?? [
            makeBasketAllocation(symbol: "AAPL", name: "Apple Inc.", percentage: 25),
            makeBasketAllocation(symbol: "MSFT", name: "Microsoft Corporation", percentage: 25),
            makeBasketAllocation(symbol: "GOOGL", name: "Alphabet Inc.", percentage: 25),
            makeBasketAllocation(symbol: "AMZN", name: "Amazon.com Inc.", percentage: 25)
        ]

        return Basket(
            id: id,
            userId: "user-1",
            familyId: nil,
            name: name,
            description: description,
            category: category,
            icon: "chart.bar.fill",
            color: "#007AFF",
            allocations: defaultAllocations,
            dcaEnabled: false,
            dcaScheduleId: nil,
            status: .active,
            summary: BasketSummary(
                currentValue: 10000,
                totalInvested: 9000,
                totalGainLoss: 1000
            ),
            isShared: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func makeBasketCreate(
        name: String = "Tech Portfolio",
        description: String? = "My technology stocks",
        category: String? = "Technology",
        allocations: [BasketAllocation]? = nil
    ) -> BasketCreate {
        let defaultAllocations = allocations ?? [
            makeBasketAllocation(symbol: "AAPL", name: "Apple Inc.", percentage: 25),
            makeBasketAllocation(symbol: "MSFT", name: "Microsoft Corporation", percentage: 25),
            makeBasketAllocation(symbol: "GOOGL", name: "Alphabet Inc.", percentage: 25),
            makeBasketAllocation(symbol: "AMZN", name: "Amazon.com Inc.", percentage: 25)
        ]

        return BasketCreate(
            name: name,
            description: description,
            category: category,
            icon: "chart.bar.fill",
            color: "#007AFF",
            allocations: defaultAllocations,
            isShared: false
        )
    }

    // MARK: - Fetch Baskets Tests

    func test_fetchBaskets_returnsBaskets() async throws {
        // Arrange
        let expectedBaskets = [
            makeBasket(id: "basket-1", name: "Tech Portfolio"),
            makeBasket(id: "basket-2", name: "Dividend Stocks")
        ]
        mockAPIClient.setResponse(expectedBaskets, for: Endpoints.GetBaskets.self)

        // Act
        let result = try await sut.fetchBaskets()

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "basket-1")
        XCTAssertEqual(result[0].name, "Tech Portfolio")
        XCTAssertEqual(result[1].id, "basket-2")
        XCTAssertEqual(result[1].name, "Dividend Stocks")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchBaskets_returnsEmptyArrayWhenNoBaskets() async throws {
        // Arrange
        let emptyBaskets: [Basket] = []
        mockAPIClient.setResponse(emptyBaskets, for: Endpoints.GetBaskets.self)

        // Act
        let result = try await sut.fetchBaskets()

        // Assert
        XCTAssertEqual(result.count, 0)
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchBaskets_throwsOnNetworkError() async {
        // Arrange
        mockAPIClient.setError(
            NetworkError.serverError(statusCode: 500, message: "Internal error"),
            for: Endpoints.GetBaskets.self
        )

        // Act & Assert
        do {
            _ = try await sut.fetchBaskets()
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .serverError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("Expected serverError")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_fetchBaskets_throwsOnUnauthorized() async {
        // Arrange
        mockAPIClient.setError(
            NetworkError.unauthorized,
            for: Endpoints.GetBaskets.self
        )

        // Act & Assert
        do {
            _ = try await sut.fetchBaskets()
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .unauthorized = error {
                // Success
            } else {
                XCTFail("Expected unauthorized error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Fetch Basket by ID Tests

    func test_fetchBasket_returnsBasket() async throws {
        // Arrange
        let expectedBasket = makeBasket(id: "basket-123", name: "My Basket")
        mockAPIClient.setResponse(expectedBasket, for: Endpoints.GetBasket.self)

        // Act
        let result = try await sut.fetchBasket(id: "basket-123")

        // Assert
        XCTAssertEqual(result.id, "basket-123")
        XCTAssertEqual(result.name, "My Basket")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchBasket_throwsOnNotFound() async {
        // Arrange
        mockAPIClient.setError(
            NetworkError.notFound,
            for: Endpoints.GetBasket.self
        )

        // Act & Assert
        do {
            _ = try await sut.fetchBasket(id: "non-existent")
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .notFound = error {
                // Success
            } else {
                XCTFail("Expected notFound error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_fetchBasket_includesAllocations() async throws {
        // Arrange
        let allocations = [
            makeBasketAllocation(symbol: "AAPL", percentage: 50),
            makeBasketAllocation(symbol: "MSFT", percentage: 50)
        ]
        let basket = makeBasket(allocations: allocations)
        mockAPIClient.setResponse(basket, for: Endpoints.GetBasket.self)

        // Act
        let result = try await sut.fetchBasket(id: "basket-1")

        // Assert
        XCTAssertEqual(result.allocations.count, 2)
        XCTAssertEqual(result.allocations[0].symbol, "AAPL")
        XCTAssertEqual(result.allocations[0].percentage, 50)
        XCTAssertEqual(result.allocations[1].symbol, "MSFT")
        XCTAssertEqual(result.allocations[1].percentage, 50)
    }

    func test_fetchBasket_includesSummary() async throws {
        // Arrange
        let basket = makeBasket(id: "basket-1")
        mockAPIClient.setResponse(basket, for: Endpoints.GetBasket.self)

        // Act
        let result = try await sut.fetchBasket(id: "basket-1")

        // Assert
        XCTAssertEqual(result.summary.currentValue, 10000)
        XCTAssertEqual(result.summary.totalInvested, 9000)
        XCTAssertEqual(result.summary.totalGainLoss, 1000)
    }

    // MARK: - Create Basket Tests

    func test_createBasket_returnsCreatedBasket() async throws {
        // Arrange
        let basketCreate = makeBasketCreate(name: "New Basket")
        let expectedBasket = makeBasket(id: "new-basket-1", name: "New Basket")
        mockAPIClient.setResponse(expectedBasket, for: Endpoints.CreateBasket.self)

        // Act
        let result = try await sut.createBasket(basketCreate)

        // Assert
        XCTAssertEqual(result.name, "New Basket")
        XCTAssertEqual(result.id, "new-basket-1")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_createBasket_sendsCorrectData() async throws {
        // Arrange
        let allocations = [
            makeBasketAllocation(symbol: "AAPL", percentage: 60),
            makeBasketAllocation(symbol: "MSFT", percentage: 40)
        ]
        let basketCreate = makeBasketCreate(
            name: "Test Basket",
            description: "Test Description",
            category: "Test Category",
            allocations: allocations
        )
        let basket = makeBasket(id: "basket-1", name: "Test Basket")
        mockAPIClient.setResponse(basket, for: Endpoints.CreateBasket.self)

        // Act
        let result = try await sut.createBasket(basketCreate)

        // Assert
        XCTAssertEqual(result.name, "Test Basket")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_createBasket_throwsOnValidationError() async {
        // Arrange
        let basketCreate = makeBasketCreate()
        mockAPIClient.setError(
            NetworkError.clientError(statusCode: 400, message: "Allocations must sum to 100%"),
            for: Endpoints.CreateBasket.self
        )

        // Act & Assert
        do {
            _ = try await sut.createBasket(basketCreate)
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .clientError(let statusCode, let message) = error {
                XCTAssertEqual(statusCode, 400)
                XCTAssertEqual(message, "Allocations must sum to 100%")
            } else {
                XCTFail("Expected clientError")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_createBasket_handlesEmptyDescription() async throws {
        // Arrange
        let basketCreate = makeBasketCreate(name: "Minimal Basket", description: nil)
        let basket = makeBasket(id: "minimal-1", name: "Minimal Basket", description: nil)
        mockAPIClient.setResponse(basket, for: Endpoints.CreateBasket.self)

        // Act
        let result = try await sut.createBasket(basketCreate)

        // Assert
        XCTAssertEqual(result.name, "Minimal Basket")
        XCTAssertNil(result.description)
    }

    // MARK: - Update Basket Tests

    func test_updateBasket_returnsUpdatedBasket() async throws {
        // Arrange
        let basketUpdate = makeBasketCreate(name: "Updated Name")
        let expectedBasket = makeBasket(id: "basket-1", name: "Updated Name")
        mockAPIClient.setResponse(expectedBasket, for: Endpoints.UpdateBasket.self)

        // Act
        let result = try await sut.updateBasket(id: "basket-1", basketUpdate)

        // Assert
        XCTAssertEqual(result.id, "basket-1")
        XCTAssertEqual(result.name, "Updated Name")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_updateBasket_updatesAllocations() async throws {
        // Arrange
        let newAllocations = [
            makeBasketAllocation(symbol: "AAPL", percentage: 100)
        ]
        let basketUpdate = makeBasketCreate(allocations: newAllocations)
        let updatedBasket = makeBasket(allocations: newAllocations)
        mockAPIClient.setResponse(updatedBasket, for: Endpoints.UpdateBasket.self)

        // Act
        let result = try await sut.updateBasket(id: "basket-1", basketUpdate)

        // Assert
        XCTAssertEqual(result.allocations.count, 1)
        XCTAssertEqual(result.allocations[0].symbol, "AAPL")
        XCTAssertEqual(result.allocations[0].percentage, 100)
    }

    func test_updateBasket_throwsOnNotFound() async {
        // Arrange
        let basketUpdate = makeBasketCreate()
        mockAPIClient.setError(
            NetworkError.notFound,
            for: Endpoints.UpdateBasket.self
        )

        // Act & Assert
        do {
            _ = try await sut.updateBasket(id: "non-existent", basketUpdate)
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .notFound = error {
                // Success
            } else {
                XCTFail("Expected notFound error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_updateBasket_throwsOnValidationError() async {
        // Arrange
        let basketUpdate = makeBasketCreate()
        mockAPIClient.setError(
            NetworkError.clientError(statusCode: 400, message: "Name cannot be empty"),
            for: Endpoints.UpdateBasket.self
        )

        // Act & Assert
        do {
            _ = try await sut.updateBasket(id: "basket-1", basketUpdate)
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .clientError(let statusCode, let message) = error {
                XCTAssertEqual(statusCode, 400)
                XCTAssertEqual(message, "Name cannot be empty")
            } else {
                XCTFail("Expected clientError")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Delete Basket Tests

    func test_deleteBasket_succeeds() async throws {
        // Act
        try await sut.deleteBasket(id: "basket-1")

        // Assert
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_deleteBasket_throwsOnNotFound() async {
        // Arrange
        mockAPIClient.setError(
            NetworkError.notFound,
            for: Endpoints.DeleteBasket.self
        )

        // Act & Assert
        do {
            try await sut.deleteBasket(id: "non-existent")
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .notFound = error {
                // Success
            } else {
                XCTFail("Expected notFound error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_deleteBasket_throwsOnForbidden() async {
        // Arrange
        mockAPIClient.setError(
            NetworkError.forbidden,
            for: Endpoints.DeleteBasket.self
        )

        // Act & Assert
        do {
            try await sut.deleteBasket(id: "basket-1")
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .forbidden = error {
                // Success
            } else {
                XCTFail("Expected forbidden error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Edge Case Tests

    func test_createBasket_withMaxAllocations() async throws {
        // Arrange - Create basket with many allocations
        let allocations = (1...20).map { i in
            makeBasketAllocation(
                symbol: "STOCK\(i)",
                name: "Company \(i)",
                percentage: 5
            )
        }
        let basketCreate = makeBasketCreate(allocations: allocations)
        let basket = makeBasket(allocations: allocations)
        mockAPIClient.setResponse(basket, for: Endpoints.CreateBasket.self)

        // Act
        let result = try await sut.createBasket(basketCreate)

        // Assert
        XCTAssertEqual(result.allocations.count, 20)
    }

    func test_fetchBaskets_withLargeResponseSet() async throws {
        // Arrange - Create large number of baskets
        let baskets = (1...100).map { i in
            makeBasket(id: "basket-\(i)", name: "Basket \(i)")
        }
        mockAPIClient.setResponse(baskets, for: Endpoints.GetBaskets.self)

        // Act
        let result = try await sut.fetchBaskets()

        // Assert
        XCTAssertEqual(result.count, 100)
    }

    func test_basket_withSpecialCharactersInName() async throws {
        // Arrange
        let basketCreate = makeBasketCreate(
            name: "Portfolio with émojis 💰📈 & symbols!",
            description: "Test €£¥ symbols"
        )
        let basket = makeBasket(
            name: "Portfolio with émojis 💰📈 & symbols!",
            description: "Test €£¥ symbols"
        )
        mockAPIClient.setResponse(basket, for: Endpoints.CreateBasket.self)

        // Act
        let result = try await sut.createBasket(basketCreate)

        // Assert
        XCTAssertEqual(result.name, "Portfolio with émojis 💰📈 & symbols!")
        XCTAssertEqual(result.description, "Test €£¥ symbols")
    }
}
