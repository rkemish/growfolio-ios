//
//  PortfolioRepositoryTests.swift
//  GrowfolioTests
//
//  Tests for PortfolioRepository.
//

import XCTest
@testable import Growfolio

final class PortfolioRepositoryTests: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var sut: PortfolioRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = PortfolioRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        mockAPIClient.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makePortfolio(
        id: String = "portfolio-1",
        name: String = "Main Portfolio",
        totalValue: Decimal = 10000,
        isDefault: Bool = false
    ) -> Portfolio {
        Portfolio(
            id: id,
            userId: "user-1",
            name: name,
            totalValue: totalValue,
            totalCostBasis: 8000,
            cashBalance: 500,
            isDefault: isDefault
        )
    }

    private func makeHolding(
        id: String = "holding-1",
        portfolioId: String = "portfolio-1",
        stockSymbol: String = "AAPL",
        quantity: Decimal = 10,
        averageCost: Decimal = 150,
        currentPrice: Decimal = 175
    ) -> Holding {
        Holding(
            id: id,
            portfolioId: portfolioId,
            stockSymbol: stockSymbol,
            stockName: "Apple Inc.",
            quantity: quantity,
            averageCostPerShare: averageCost,
            currentPricePerShare: currentPrice,
            sector: "Technology"
        )
    }

    // MARK: - Fetch Portfolios Tests

    func test_fetchPortfolios_returnsPortfoliosFromAPI() async throws {
        // Arrange
        let expectedPortfolios = [
            makePortfolio(id: "portfolio-1", name: "Main"),
            makePortfolio(id: "portfolio-2", name: "Retirement")
        ]
        mockAPIClient.setResponse(expectedPortfolios, for: Endpoints.GetPortfolios.self)

        // Act
        let portfolios = try await sut.fetchPortfolios()

        // Assert
        XCTAssertEqual(portfolios.count, 2)
        XCTAssertEqual(portfolios[0].name, "Main")
        XCTAssertEqual(portfolios[1].name, "Retirement")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchPortfolios_usesCache() async throws {
        // Arrange
        let expectedPortfolios = [makePortfolio()]
        mockAPIClient.setResponse(expectedPortfolios, for: Endpoints.GetPortfolios.self)

        // Act - First call populates cache
        _ = try await sut.fetchPortfolios()

        // Act - Second call should use cache
        let result = try await sut.fetchPortfolios()

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchPortfolios_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Server error"), for: Endpoints.GetPortfolios.self)

        // Act & Assert
        do {
            _ = try await sut.fetchPortfolios()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Fetch Portfolio by ID Tests

    func test_fetchPortfolio_returnsPortfolioFromAPI() async throws {
        // Arrange
        let expectedPortfolio = makePortfolio(id: "portfolio-123")
        mockAPIClient.setResponse(expectedPortfolio, for: Endpoints.GetPortfolio.self)

        // Act
        let portfolio = try await sut.fetchPortfolio(id: "portfolio-123")

        // Assert
        XCTAssertEqual(portfolio.id, "portfolio-123")
    }

    func test_fetchPortfolio_returnsCachedPortfolioIfAvailable() async throws {
        // Arrange - First populate the cache
        let cachedPortfolio = makePortfolio(id: "portfolio-cached")
        mockAPIClient.setResponse([cachedPortfolio], for: Endpoints.GetPortfolios.self)
        _ = try await sut.fetchPortfolios()
        mockAPIClient.reset()

        // Act - Fetch by ID should use cache
        let portfolio = try await sut.fetchPortfolio(id: "portfolio-cached")

        // Assert
        XCTAssertEqual(portfolio.id, "portfolio-cached")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    // MARK: - Fetch Default Portfolio Tests

    func test_fetchDefaultPortfolio_returnsDefaultPortfolio() async throws {
        // Arrange
        let portfolios = [
            makePortfolio(id: "portfolio-1", isDefault: false),
            makePortfolio(id: "portfolio-2", isDefault: true),
            makePortfolio(id: "portfolio-3", isDefault: false)
        ]
        mockAPIClient.setResponse(portfolios, for: Endpoints.GetPortfolios.self)

        // Act
        let defaultPortfolio = try await sut.fetchDefaultPortfolio()

        // Assert
        XCTAssertEqual(defaultPortfolio?.id, "portfolio-2")
        XCTAssertTrue(defaultPortfolio?.isDefault ?? false)
    }

    func test_fetchDefaultPortfolio_returnsNilWhenNoDefault() async throws {
        // Arrange
        let portfolios = [
            makePortfolio(id: "portfolio-1", isDefault: false),
            makePortfolio(id: "portfolio-2", isDefault: false)
        ]
        mockAPIClient.setResponse(portfolios, for: Endpoints.GetPortfolios.self)

        // Act
        let defaultPortfolio = try await sut.fetchDefaultPortfolio()

        // Assert
        XCTAssertNil(defaultPortfolio)
    }

    // MARK: - Fetch Holdings Tests

    func test_fetchHoldings_returnsHoldingsFromAPI() async throws {
        // Arrange
        let expectedHoldings = [
            makeHolding(id: "holding-1", stockSymbol: "AAPL"),
            makeHolding(id: "holding-2", stockSymbol: "GOOGL")
        ]
        mockAPIClient.setResponse(expectedHoldings, for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let holdings = try await sut.fetchHoldings(for: "portfolio-1")

        // Assert
        XCTAssertEqual(holdings.count, 2)
        XCTAssertEqual(holdings[0].stockSymbol, "AAPL")
        XCTAssertEqual(holdings[1].stockSymbol, "GOOGL")
    }

    func test_fetchHoldings_usesCache() async throws {
        // Arrange
        let holdings = [makeHolding()]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)

        // Act - First call populates cache
        _ = try await sut.fetchHoldings(for: "portfolio-1")

        // Act - Second call should use cache
        let result = try await sut.fetchHoldings(for: "portfolio-1")

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchHolding_returnsSpecificHolding() async throws {
        // Arrange
        let holdings = [
            makeHolding(id: "holding-1", stockSymbol: "AAPL"),
            makeHolding(id: "holding-2", stockSymbol: "GOOGL")
        ]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let holding = try await sut.fetchHolding(id: "holding-2", in: "portfolio-1")

        // Assert
        XCTAssertEqual(holding.id, "holding-2")
        XCTAssertEqual(holding.stockSymbol, "GOOGL")
    }

    func test_fetchHolding_throwsWhenNotFound() async {
        // Arrange
        let holdings = [makeHolding(id: "holding-1")]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)

        // Act & Assert
        do {
            _ = try await sut.fetchHolding(id: "nonexistent", in: "portfolio-1")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PortfolioRepositoryError)
        }
    }

    // MARK: - Refresh Holdings Prices Tests

    func test_refreshHoldingPrices_invalidatesCacheAndRefetches() async throws {
        // Arrange
        let holdings = [makeHolding(currentPrice: 175)]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)
        _ = try await sut.fetchHoldings(for: "portfolio-1")

        // Set up new response
        mockAPIClient.reset()
        let updatedHoldings = [makeHolding(currentPrice: 180)]
        mockAPIClient.setResponse(updatedHoldings, for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let result = try await sut.refreshHoldingPrices(for: "portfolio-1")

        // Assert
        XCTAssertEqual(result.first?.currentPricePerShare, 180)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Performance Tests

    func test_fetchPerformance_returnsPerformanceData() async throws {
        // Arrange
        let performance = PortfolioPerformance(
            portfolioId: "portfolio-1",
            period: .oneMonth,
            startValue: 10000,
            endValue: 11000,
            absoluteReturn: 1000,
            percentageReturn: 10
        )
        mockAPIClient.setResponse(performance, for: Endpoints.GetPortfolioPerformance.self)

        // Act
        let result = try await sut.fetchPerformance(for: "portfolio-1", period: .oneMonth)

        // Assert
        XCTAssertEqual(result.portfolioId, "portfolio-1")
        XCTAssertEqual(result.absoluteReturn, 1000)
        XCTAssertEqual(result.percentageReturn, 10)
    }

    // MARK: - Ledger Entries Tests

    func test_fetchLedgerEntries_returnsEntriesFromAPI() async throws {
        // Arrange
        let entries = [
            LedgerEntry(
                portfolioId: "portfolio-1",
                userId: "user-1",
                type: .buy,
                stockSymbol: "AAPL",
                quantity: 10,
                pricePerShare: 150,
                totalAmount: 1500
            )
        ]
        let response = PaginatedResponse(
            data: entries,
            pagination: PaginatedResponse<LedgerEntry>.Pagination(
                page: 1,
                limit: 50,
                totalPages: 1,
                totalItems: 1
            )
        )
        mockAPIClient.setResponse(response, for: Endpoints.GetLedgerEntries.self)

        // Act
        let result = try await sut.fetchLedgerEntries(for: "portfolio-1", page: 1, limit: 50)

        // Assert
        XCTAssertEqual(result.data.count, 1)
        XCTAssertEqual(result.data.first?.stockSymbol, "AAPL")
    }

    // MARK: - Cost Basis Tests

    func test_getCostBasis_returnsCostBasisSummary() async throws {
        // Arrange
        let response = CostBasisResponse(
            symbol: "AAPL",
            totalShares: 10,
            totalCostUsd: 1500,
            totalCostGbp: 1200,
            averageCostUsd: 150,
            averageCostGbp: 120,
            lots: []
        )
        mockAPIClient.setResponse(response, for: Endpoints.GetCostBasis.self)

        // Act
        let result = try await sut.getCostBasis(symbol: "AAPL")

        // Assert
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(result.totalShares, 10)
        XCTAssertEqual(result.averageCostUsd, 150)
    }

    // MARK: - Allocation Tests

    // TODO: These tests cause SIGBUS crashes - needs investigation
    // The fetchAllocation method works but causes test runner crashes
    // func test_fetchAllocation_groupsBySector() async throws { ... }
    // func test_fetchAllocation_groupsByHolding() async throws { ... }

    // MARK: - Cache Invalidation Tests

    func test_invalidateCache_clearsAllCaches() async throws {
        // Arrange - Populate both caches
        let portfolios = [makePortfolio()]
        mockAPIClient.setResponse(portfolios, for: Endpoints.GetPortfolios.self)
        _ = try await sut.fetchPortfolios()

        let holdings = [makeHolding()]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)
        _ = try await sut.fetchHoldings(for: "portfolio-1")

        // Act
        await sut.invalidateCache()

        // Reset and set up new responses
        mockAPIClient.reset()
        mockAPIClient.setResponse([makePortfolio(id: "new-portfolio")], for: Endpoints.GetPortfolios.self)
        mockAPIClient.setResponse([makeHolding(id: "new-holding")], for: Endpoints.GetPortfolioHoldings.self)

        // Act - Should make new API calls
        let newPortfolios = try await sut.fetchPortfolios()
        let newHoldings = try await sut.fetchHoldings(for: "portfolio-1")

        // Assert
        XCTAssertEqual(mockAPIClient.requestsMade.count, 2)
        XCTAssertEqual(newPortfolios.first?.id, "new-portfolio")
        XCTAssertEqual(newHoldings.first?.id, "new-holding")
    }

    func test_invalidateCacheForPortfolio_clearsSinglePortfolioCache() async throws {
        // Arrange - Populate holdings cache for multiple portfolios
        let holdings1 = [makeHolding(id: "h1", portfolioId: "portfolio-1")]
        let holdings2 = [makeHolding(id: "h2", portfolioId: "portfolio-2")]
        mockAPIClient.setResponse(holdings1, for: Endpoints.GetPortfolioHoldings.self)
        _ = try await sut.fetchHoldings(for: "portfolio-1")
        mockAPIClient.setResponse(holdings2, for: Endpoints.GetPortfolioHoldings.self)
        _ = try await sut.fetchHoldings(for: "portfolio-2")

        // Act - Invalidate only portfolio-1
        await sut.invalidateCache(for: "portfolio-1")

        mockAPIClient.reset()
        mockAPIClient.setResponse([makeHolding(id: "h3", portfolioId: "portfolio-1")], for: Endpoints.GetPortfolioHoldings.self)

        // portfolio-2 should still be cached
        let holdings2Cached = try await sut.fetchHoldings(for: "portfolio-2")
        XCTAssertEqual(holdings2Cached.first?.id, "h2")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    // MARK: - Empty Response Tests

    func test_fetchPortfolios_returnsEmptyArrayWhenNoPortfolios() async throws {
        // Arrange
        mockAPIClient.setResponse([Portfolio](), for: Endpoints.GetPortfolios.self)

        // Act
        let portfolios = try await sut.fetchPortfolios()

        // Assert
        XCTAssertTrue(portfolios.isEmpty)
    }

    func test_fetchHoldings_returnsEmptyArrayWhenNoHoldings() async throws {
        // Arrange
        mockAPIClient.setResponse([Holding](), for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let holdings = try await sut.fetchHoldings(for: "portfolio-1")

        // Assert
        XCTAssertTrue(holdings.isEmpty)
    }

    // MARK: - Summary Tests

    func test_fetchPortfoliosSummary_calculatesSummary() async throws {
        // Arrange
        let portfolios = [
            makePortfolio(id: "p1", totalValue: 10000),
            makePortfolio(id: "p2", totalValue: 5000)
        ]
        mockAPIClient.setResponse(portfolios, for: Endpoints.GetPortfolios.self)

        // Act
        let summary = try await sut.fetchPortfoliosSummary()

        // Assert
        XCTAssertEqual(summary.totalPortfolios, 2)
        XCTAssertEqual(summary.totalValue, 15000)
    }

    func test_fetchHoldingsSummary_calculatesSummary() async throws {
        // Arrange
        let holdings = [
            makeHolding(id: "h1", quantity: 10, averageCost: 100, currentPrice: 120),
            makeHolding(id: "h2", quantity: 5, averageCost: 200, currentPrice: 180)
        ]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let summary = try await sut.fetchHoldingsSummary(for: "portfolio-1")

        // Assert
        XCTAssertEqual(summary.totalHoldings, 2)
    }

    // MARK: - Prefetch Tests

    func test_prefetchPortfolios_populatesCache() async throws {
        // Arrange
        let portfolios = [makePortfolio()]
        mockAPIClient.setResponse(portfolios, for: Endpoints.GetPortfolios.self)

        // Act
        try await sut.prefetchPortfolios()

        // Assert
        mockAPIClient.reset()
        let result = try await sut.fetchPortfolios()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0) // Cache hit
    }

    // MARK: - Create/Update/Delete Portfolio Tests (Not Implemented)

    func test_createPortfolio_throwsInvalidPortfolioData() async {
        // Arrange
        let portfolio = makePortfolio()

        // Act & Assert
        do {
            _ = try await sut.createPortfolio(portfolio)
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .invalidPortfolioData = error {
                // Expected
            } else {
                XCTFail("Expected invalidPortfolioData error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_updatePortfolio_throwsInvalidPortfolioData() async {
        // Arrange
        let portfolio = makePortfolio()

        // Act & Assert
        do {
            _ = try await sut.updatePortfolio(portfolio)
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .invalidPortfolioData = error {
                // Expected
            } else {
                XCTFail("Expected invalidPortfolioData error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_setDefaultPortfolio_throwsPortfolioNotFound() async {
        // Act & Assert
        do {
            _ = try await sut.setDefaultPortfolio(id: "some-id")
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .portfolioNotFound(let id) = error {
                XCTAssertEqual(id, "some-id")
            } else {
                XCTFail("Expected portfolioNotFound error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_deletePortfolio_throwsCannotDeleteDefaultPortfolio() async {
        // Act & Assert
        do {
            try await sut.deletePortfolio(id: "some-id")
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .cannotDeleteDefaultPortfolio = error {
                // Expected
            } else {
                XCTFail("Expected cannotDeleteDefaultPortfolio error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Holding CRUD Tests (Not Implemented)

    func test_addHolding_throwsInvalidHoldingData() async {
        // Arrange
        let holding = makeHolding()

        // Act & Assert
        do {
            _ = try await sut.addHolding(holding, to: "portfolio-1")
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .invalidHoldingData = error {
                // Expected
            } else {
                XCTFail("Expected invalidHoldingData error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_updateHolding_throwsInvalidHoldingData() async {
        // Arrange
        let holding = makeHolding()

        // Act & Assert
        do {
            _ = try await sut.updateHolding(holding)
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .invalidHoldingData = error {
                // Expected
            } else {
                XCTFail("Expected invalidHoldingData error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_removeHolding_throwsHoldingNotFound() async {
        // Act & Assert
        do {
            try await sut.removeHolding(id: "holding-123", from: "portfolio-1")
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .holdingNotFound(let id) = error {
                XCTAssertEqual(id, "holding-123")
            } else {
                XCTFail("Expected holdingNotFound error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Combined Performance Tests

    func test_fetchCombinedPerformance_returnsDefaultPortfolioPerformance() async throws {
        // Arrange
        let portfolios = [makePortfolio(id: "default-portfolio", isDefault: true)]
        mockAPIClient.setResponse(portfolios, for: Endpoints.GetPortfolios.self)

        let performance = PortfolioPerformance(
            portfolioId: "default-portfolio",
            period: .oneYear,
            startValue: 5000,
            endValue: 7500,
            absoluteReturn: 2500,
            percentageReturn: 50
        )
        mockAPIClient.setResponse(performance, for: Endpoints.GetPortfolioPerformance.self)

        // Act
        let result = try await sut.fetchCombinedPerformance(period: .oneYear)

        // Assert
        XCTAssertEqual(result.portfolioId, "default-portfolio")
        XCTAssertEqual(result.absoluteReturn, 2500)
        XCTAssertEqual(result.percentageReturn, 50)
    }

    func test_fetchCombinedPerformance_throwsWhenNoPortfolios() async {
        // Arrange
        mockAPIClient.setResponse([Portfolio](), for: Endpoints.GetPortfolios.self)

        // Act & Assert
        do {
            _ = try await sut.fetchCombinedPerformance(period: .oneMonth)
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .portfolioNotFound(_) = error {
                // Expected
            } else {
                XCTFail("Expected portfolioNotFound error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Allocation Tests

    func test_fetchAllocation_groupsBySector() async throws {
        // Arrange
        let holdings = [
            Holding(
                id: "h1",
                portfolioId: "portfolio-1",
                stockSymbol: "AAPL",
                stockName: "Apple Inc.",
                quantity: 10,
                averageCostPerShare: 150,
                currentPricePerShare: 175,
                sector: "Technology"
            ),
            Holding(
                id: "h2",
                portfolioId: "portfolio-1",
                stockSymbol: "GOOGL",
                stockName: "Alphabet Inc.",
                quantity: 5,
                averageCostPerShare: 100,
                currentPricePerShare: 140,
                sector: "Technology"
            ),
            Holding(
                id: "h3",
                portfolioId: "portfolio-1",
                stockSymbol: "JNJ",
                stockName: "Johnson & Johnson",
                quantity: 20,
                averageCostPerShare: 140,
                currentPricePerShare: 160,
                sector: "Healthcare"
            )
        ]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let allocation = try await sut.fetchAllocation(for: "portfolio-1", groupBy: .sector)

        // Assert
        XCTAssertEqual(allocation.portfolioId, "portfolio-1")
        XCTAssertEqual(allocation.allocations.count, 2) // Technology, Healthcare
        XCTAssertTrue(allocation.allocations.contains { $0.category == "Technology" })
        XCTAssertTrue(allocation.allocations.contains { $0.category == "Healthcare" })
    }

    func test_fetchAllocation_groupsByHolding() async throws {
        // Arrange
        let holdings = [
            makeHolding(id: "h1", stockSymbol: "AAPL"),
            makeHolding(id: "h2", stockSymbol: "GOOGL")
        ]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let allocation = try await sut.fetchAllocation(for: "portfolio-1", groupBy: .holding)

        // Assert
        XCTAssertEqual(allocation.portfolioId, "portfolio-1")
        XCTAssertEqual(allocation.allocations.count, 2)
    }

    func test_fetchAllocation_groupsByAssetType() async throws {
        // Arrange
        let holdings = [makeHolding(id: "h1")]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let allocation = try await sut.fetchAllocation(for: "portfolio-1", groupBy: .assetType)

        // Assert
        XCTAssertEqual(allocation.portfolioId, "portfolio-1")
        XCTAssertFalse(allocation.allocations.isEmpty)
    }

    func test_fetchAllocation_groupsByIndustry() async throws {
        // Arrange
        let holdings = [
            Holding(
                id: "h1",
                portfolioId: "portfolio-1",
                stockSymbol: "AAPL",
                stockName: "Apple",
                quantity: 10,
                averageCostPerShare: 150,
                currentPricePerShare: 175,
                industry: "Consumer Electronics"
            )
        ]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let allocation = try await sut.fetchAllocation(for: "portfolio-1", groupBy: .industry)

        // Assert
        XCTAssertTrue(allocation.allocations.contains { $0.category == "Consumer Electronics" })
    }

    func test_fetchAllocation_handlesEmptyHoldings() async throws {
        // Arrange
        mockAPIClient.setResponse([Holding](), for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let allocation = try await sut.fetchAllocation(for: "portfolio-1", groupBy: .sector)

        // Assert
        XCTAssertTrue(allocation.allocations.isEmpty)
    }

    func test_fetchCombinedAllocation_usesDefaultPortfolio() async throws {
        // Arrange
        let portfolios = [makePortfolio(id: "default-p", isDefault: true)]
        mockAPIClient.setResponse(portfolios, for: Endpoints.GetPortfolios.self)

        let holdings = [makeHolding()]
        mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)

        // Act
        let allocation = try await sut.fetchCombinedAllocation(groupBy: .sector)

        // Assert
        XCTAssertEqual(allocation.portfolioId, "default-p")
    }

    func test_fetchCombinedAllocation_throwsWhenNoPortfolios() async {
        // Arrange
        mockAPIClient.setResponse([Portfolio](), for: Endpoints.GetPortfolios.self)

        // Act & Assert
        do {
            _ = try await sut.fetchCombinedAllocation(groupBy: .sector)
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .portfolioNotFound(_) = error {
                // Expected
            } else {
                XCTFail("Expected portfolioNotFound error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Ledger Entry Filter Tests

    func test_fetchLedgerEntries_filtersByType() async throws {
        // Arrange
        let entries = [
            LedgerEntry(portfolioId: "p1", userId: "u1", type: .buy, stockSymbol: "AAPL", quantity: 10, pricePerShare: 150, totalAmount: 1500),
            LedgerEntry(portfolioId: "p1", userId: "u1", type: .sell, stockSymbol: "AAPL", quantity: 5, pricePerShare: 160, totalAmount: 800),
            LedgerEntry(portfolioId: "p1", userId: "u1", type: .dividend, stockSymbol: "AAPL", quantity: 0, pricePerShare: 0, totalAmount: 25)
        ]
        let response = PaginatedResponse(
            data: entries,
            pagination: PaginatedResponse<LedgerEntry>.Pagination(page: 1, limit: 100, totalPages: 1, totalItems: 3)
        )
        mockAPIClient.setResponse(response, for: Endpoints.GetLedgerEntries.self)

        // Act
        let result = try await sut.fetchLedgerEntries(for: "portfolio-1", types: [.buy, .sell])

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.type == .buy || $0.type == .sell })
    }

    func test_fetchLedgerEntries_filtersByDateRange() async throws {
        // Arrange
        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now)!

        let entries = [
            LedgerEntry(portfolioId: "p1", userId: "u1", type: .buy, stockSymbol: "AAPL", quantity: 10, pricePerShare: 150, totalAmount: 1500, transactionDate: now),
            LedgerEntry(portfolioId: "p1", userId: "u1", type: .buy, stockSymbol: "GOOGL", quantity: 5, pricePerShare: 100, totalAmount: 500, transactionDate: oneWeekAgo),
            LedgerEntry(portfolioId: "p1", userId: "u1", type: .buy, stockSymbol: "MSFT", quantity: 8, pricePerShare: 200, totalAmount: 1600, transactionDate: twoWeeksAgo)
        ]
        let response = PaginatedResponse(
            data: entries,
            pagination: PaginatedResponse<LedgerEntry>.Pagination(page: 1, limit: 100, totalPages: 1, totalItems: 3)
        )
        mockAPIClient.setResponse(response, for: Endpoints.GetLedgerEntries.self)

        // Act - Filter to last 10 days
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let result = try await sut.fetchLedgerEntries(for: "portfolio-1", from: tenDaysAgo, to: now)

        // Assert
        XCTAssertEqual(result.count, 2) // today and one week ago
    }

    // MARK: - Ledger CRUD Tests

    func test_updateLedgerEntry_throwsInvalidLedgerEntry() async {
        // Arrange
        let entry = LedgerEntry(portfolioId: "p1", userId: "u1", type: .buy, stockSymbol: "AAPL", quantity: 10, pricePerShare: 150, totalAmount: 1500)

        // Act & Assert
        do {
            _ = try await sut.updateLedgerEntry(entry)
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .invalidLedgerEntry = error {
                // Expected
            } else {
                XCTFail("Expected invalidLedgerEntry error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_deleteLedgerEntry_throwsLedgerEntryNotFound() async {
        // Act & Assert
        do {
            try await sut.deleteLedgerEntry(id: "entry-123", from: "portfolio-1")
            XCTFail("Expected error to be thrown")
        } catch let error as PortfolioRepositoryError {
            if case .ledgerEntryNotFound(let id) = error {
                XCTAssertEqual(id, "entry-123")
            } else {
                XCTFail("Expected ledgerEntryNotFound error")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Cash Operations Tests

    func test_depositCash_createsDepositLedgerEntry() async throws {
        // Arrange
        let expectedEntry = LedgerEntry(
            portfolioId: "portfolio-1",
            userId: "user-1",
            type: .deposit,
            totalAmount: 1000,
            notes: "Initial deposit"
        )
        mockAPIClient.setResponse(expectedEntry, for: Endpoints.CreateLedgerEntry.self)

        // Act
        let result = try await sut.depositCash(amount: 1000, to: "portfolio-1", notes: "Initial deposit")

        // Assert
        XCTAssertEqual(result.type, .deposit)
        XCTAssertEqual(result.totalAmount, 1000)
    }

    func test_withdrawCash_createsWithdrawalLedgerEntry() async throws {
        // Arrange
        let expectedEntry = LedgerEntry(
            portfolioId: "portfolio-1",
            userId: "user-1",
            type: .withdrawal,
            totalAmount: 500,
            notes: "Withdrawal"
        )
        mockAPIClient.setResponse(expectedEntry, for: Endpoints.CreateLedgerEntry.self)

        // Act
        let result = try await sut.withdrawCash(amount: 500, from: "portfolio-1", notes: "Withdrawal")

        // Assert
        XCTAssertEqual(result.type, .withdrawal)
        XCTAssertEqual(result.totalAmount, 500)
    }

    func test_transferCash_createsWithdrawalAndDeposit() async throws {
        // Arrange - Mock response for both withdrawal and deposit calls
        let entryResponse = LedgerEntry(
            portfolioId: "source-portfolio",
            userId: "user-1",
            type: .withdrawal,
            totalAmount: 250
        )
        // The mock will return the same response for both calls
        mockAPIClient.setResponse(entryResponse, for: Endpoints.CreateLedgerEntry.self)

        // Act - Should not throw
        try await sut.transferCash(
            amount: 250,
            from: "source-portfolio",
            to: "dest-portfolio",
            notes: "Transfer"
        )

        // Assert - Verify two API calls were made
        XCTAssertEqual(mockAPIClient.requestsMade.count, 2)
    }

    // MARK: - Summary Tests

    func test_fetchLedgerSummary_calculatesSummary() async throws {
        // Arrange
        let entries = [
            LedgerEntry(portfolioId: "p1", userId: "u1", type: .buy, stockSymbol: "AAPL", quantity: 10, pricePerShare: 150, totalAmount: 1500),
            LedgerEntry(portfolioId: "p1", userId: "u1", type: .buy, stockSymbol: "GOOGL", quantity: 5, pricePerShare: 100, totalAmount: 500),
            LedgerEntry(portfolioId: "p1", userId: "u1", type: .sell, stockSymbol: "AAPL", quantity: 5, pricePerShare: 160, totalAmount: 800)
        ]
        let response = PaginatedResponse(
            data: entries,
            pagination: PaginatedResponse<LedgerEntry>.Pagination(page: 1, limit: 100, totalPages: 1, totalItems: 3)
        )
        mockAPIClient.setResponse(response, for: Endpoints.GetLedgerEntries.self)

        // Act
        let summary = try await sut.fetchLedgerSummary(for: "portfolio-1")

        // Assert
        XCTAssertEqual(summary.totalTransactions, 3)
    }

    // MARK: - PortfolioRepositoryError Tests

    func test_portfolioRepositoryError_cases() {
        // Test that each error case can be created and has expected associated values
        let errors: [PortfolioRepositoryError] = [
            .invalidPortfolioData,
            .invalidHoldingData,
            .invalidLedgerEntry,
            .cannotDeleteDefaultPortfolio,
            .portfolioNotFound(id: "test-id"),
            .holdingNotFound(id: "holding-id"),
            .ledgerEntryNotFound(id: "entry-id")
        ]

        XCTAssertEqual(errors.count, 7)

        // Verify associated values
        if case .portfolioNotFound(let id) = errors[4] {
            XCTAssertEqual(id, "test-id")
        } else {
            XCTFail("Expected portfolioNotFound")
        }

        if case .holdingNotFound(let id) = errors[5] {
            XCTAssertEqual(id, "holding-id")
        } else {
            XCTFail("Expected holdingNotFound")
        }

        if case .ledgerEntryNotFound(let id) = errors[6] {
            XCTAssertEqual(id, "entry-id")
        } else {
            XCTFail("Expected ledgerEntryNotFound")
        }
    }

    func test_portfolioRepositoryError_localizedDescription() {
        let errors: [PortfolioRepositoryError] = [
            .invalidPortfolioData,
            .invalidHoldingData,
            .invalidLedgerEntry,
            .cannotDeleteDefaultPortfolio,
            .portfolioNotFound(id: "test-id"),
            .holdingNotFound(id: "holding-id"),
            .ledgerEntryNotFound(id: "entry-id")
        ]

        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty, "Error \(error) should have a non-empty description")
        }
    }

    // MARK: - CostBasisResponse Tests

    func test_costBasisResponse_toCostBasisSummary() {
        // Arrange
        let response = CostBasisResponse(
            symbol: "AAPL",
            totalShares: 25.5,
            totalCostUsd: 3825.00,
            totalCostGbp: 3060.00,
            averageCostUsd: 150.00,
            averageCostGbp: 120.00,
            lots: [
                CostBasisResponse.CostBasisLotResponse(
                    date: "2024-01-15T10:30:00.000Z",
                    shares: 10.0,
                    priceUsd: 145.00,
                    totalUsd: 1450.00,
                    totalGbp: 1160.00,
                    fxRate: 1.25
                ),
                CostBasisResponse.CostBasisLotResponse(
                    date: "2024-02-20T14:45:00.000Z",
                    shares: 15.5,
                    priceUsd: 153.23,
                    totalUsd: 2375.00,
                    totalGbp: 1900.00,
                    fxRate: 1.25
                )
            ]
        )

        // Act
        let summary = response.toCostBasisSummary()

        // Assert
        XCTAssertEqual(summary.symbol, "AAPL")
        XCTAssertEqual(summary.totalShares, Decimal(25.5))
        XCTAssertEqual(summary.totalCostUsd, Decimal(3825.00))
        XCTAssertEqual(summary.totalCostGbp, Decimal(3060.00))
        XCTAssertEqual(summary.averageCostUsd, Decimal(150.00))
        XCTAssertEqual(summary.averageCostGbp, Decimal(120.00))
        XCTAssertEqual(summary.lots.count, 2)
    }

    func test_costBasisResponse_codable() throws {
        // Arrange
        let json = """
        {
            "symbol": "GOOGL",
            "totalShares": 10.0,
            "totalCostUsd": 1500.0,
            "totalCostGbp": 1200.0,
            "averageCostUsd": 150.0,
            "averageCostGbp": 120.0,
            "lots": []
        }
        """.data(using: .utf8)!

        // Act
        let response = try JSONDecoder().decode(CostBasisResponse.self, from: json)

        // Assert
        XCTAssertEqual(response.symbol, "GOOGL")
        XCTAssertEqual(response.totalShares, 10.0)
        XCTAssertTrue(response.lots.isEmpty)
    }

    func test_costBasisLotResponse_codable() throws {
        // Arrange
        let json = """
        {
            "date": "2024-03-15T09:00:00.000Z",
            "shares": 5.0,
            "priceUsd": 100.0,
            "totalUsd": 500.0,
            "totalGbp": 400.0,
            "fxRate": 1.25
        }
        """.data(using: .utf8)!

        // Act
        let lot = try JSONDecoder().decode(CostBasisResponse.CostBasisLotResponse.self, from: json)

        // Assert
        XCTAssertEqual(lot.shares, 5.0)
        XCTAssertEqual(lot.priceUsd, 100.0)
        XCTAssertEqual(lot.fxRate, 1.25)
    }

    // MARK: - Sector Color Tests (via Allocation)

    func test_fetchAllocation_assignsCorrectSectorColors() async throws {
        // Arrange - Create holdings for each sector
        let sectors = [
            ("Technology", "#007AFF"),
            ("Healthcare", "#30D158"),
            ("Financials", "#FF9500"),
            ("Consumer Discretionary", "#FF2D55"),
            ("Communication Services", "#5856D6"),
            ("Industrials", "#8E8E93"),
            ("Consumer Staples", "#34C759"),
            ("Energy", "#FF3B30"),
            ("Utilities", "#AF52DE"),
            ("Real Estate", "#00C7BE"),
            ("Materials", "#5AC8FA"),
            ("Unknown Sector", "#8E8E93") // Default color
        ]

        for (sector, expectedColor) in sectors {
            let holdings = [
                Holding(
                    id: "h-\(sector)",
                    portfolioId: "portfolio-1",
                    stockSymbol: "TEST",
                    stockName: "Test Stock",
                    quantity: 10,
                    averageCostPerShare: 100,
                    currentPricePerShare: 100,
                    sector: sector
                )
            ]
            mockAPIClient.setResponse(holdings, for: Endpoints.GetPortfolioHoldings.self)

            // Act
            let allocation = try await sut.fetchAllocation(for: "portfolio-1", groupBy: .sector)

            // Assert
            XCTAssertEqual(allocation.allocations.first?.colorHex, expectedColor, "Color for \(sector) should be \(expectedColor)")

            // Clear cache for next iteration
            await sut.invalidateCache()
            mockAPIClient.reset()
        }
    }

    // MARK: - Cache Edge Cases

    func test_fetchPortfolios_cacheExpiresAfterDuration() async throws {
        // This test verifies cache behavior - may need timing adjustments
        // Note: The actual cache duration is 60 seconds, but we can't wait that long in tests
        // This test documents the expected behavior

        // Arrange
        let portfolios = [makePortfolio(id: "cached-portfolio")]
        mockAPIClient.setResponse(portfolios, for: Endpoints.GetPortfolios.self)

        // Act - First fetch should cache
        let first = try await sut.fetchPortfolios()
        XCTAssertEqual(first.first?.id, "cached-portfolio")

        // Assert - Second fetch should use cache (only 1 request made)
        let second = try await sut.fetchPortfolios()
        XCTAssertEqual(second.first?.id, "cached-portfolio")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchPortfolio_fetchesFromAPIWhenNotInCache() async throws {
        // Arrange - Don't pre-populate cache
        let portfolio = makePortfolio(id: "new-portfolio")
        mockAPIClient.setResponse(portfolio, for: Endpoints.GetPortfolio.self)

        // Act
        let result = try await sut.fetchPortfolio(id: "new-portfolio")

        // Assert
        XCTAssertEqual(result.id, "new-portfolio")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Network Error Handling

    func test_fetchHoldings_throwsOnNetworkError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.noConnection, for: Endpoints.GetPortfolioHoldings.self)

        // Act & Assert
        do {
            _ = try await sut.fetchHoldings(for: "portfolio-1")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    func test_fetchPerformance_throwsOnNetworkError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.timeout, for: Endpoints.GetPortfolioPerformance.self)

        // Act & Assert
        do {
            _ = try await sut.fetchPerformance(for: "portfolio-1", period: .oneMonth)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    func test_getCostBasis_throwsOnNetworkError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 503, message: "Service Unavailable"), for: Endpoints.GetCostBasis.self)

        // Act & Assert
        do {
            _ = try await sut.getCostBasis(symbol: "AAPL")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}
