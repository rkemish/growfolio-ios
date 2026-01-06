//
//  MockPortfolioRepository.swift
//  GrowfolioTests
//
//  Mock portfolio repository for testing.
//

import Foundation
@testable import Growfolio

/// Mock portfolio repository that returns predefined responses for testing
final class MockPortfolioRepository: PortfolioRepositoryProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    var portfoliosToReturn: [Portfolio] = []
    var portfolioToReturn: Portfolio?
    var holdingsToReturn: [Holding] = []
    var holdingToReturn: Holding?
    var performanceToReturn: PortfolioPerformance?
    var allocationToReturn: PortfolioAllocation?
    var ledgerEntriesToReturn: [LedgerEntry] = []
    var ledgerEntryToReturn: LedgerEntry?
    var costBasisSummaryToReturn: CostBasisSummary?
    var portfoliosSummaryToReturn: PortfoliosSummary?
    var holdingsSummaryToReturn: HoldingsSummary?
    var ledgerSummaryToReturn: LedgerSummary?
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var fetchPortfoliosCalled = false
    var fetchPortfolioIdCalled: String?
    var fetchDefaultPortfolioCalled = false
    var createPortfolioCalled = false
    var updatePortfolioCalled = false
    var setDefaultPortfolioIdCalled: String?
    var deletePortfolioIdCalled: String?
    var fetchHoldingsPortfolioIdCalled: String?
    var fetchHoldingIdCalled: String?
    var addHoldingCalled = false
    var updateHoldingCalled = false
    var removeHoldingIdCalled: String?
    var refreshHoldingPricesPortfolioIdCalled: String?
    var fetchPerformancePortfolioIdCalled: String?
    var fetchPerformancePeriodCalled: PerformancePeriod?
    var fetchCombinedPerformanceCalled = false
    var fetchAllocationPortfolioIdCalled: String?
    var fetchAllocationGroupByCalled: AllocationGrouping?
    var fetchCombinedAllocationCalled = false
    var fetchLedgerEntriesPortfolioIdCalled: String?
    var fetchLedgerEntriesPageCalled: Int?
    var fetchLedgerEntriesLimitCalled: Int?
    var addLedgerEntryCalled = false
    var lastAddedLedgerEntry: LedgerEntry?
    var updateLedgerEntryCalled = false
    var deleteLedgerEntryIdCalled: String?
    var getCostBasisSymbolCalled: String?
    var depositCashAmountCalled: Decimal?
    var depositCashPortfolioIdCalled: String?
    var withdrawCashAmountCalled: Decimal?
    var withdrawCashPortfolioIdCalled: String?
    var transferCashCalled = false
    var invalidateCacheCalled = false
    var invalidateCachePortfolioIdCalled: String?
    var prefetchPortfoliosCalled = false

    // MARK: - Reset

    func reset() {
        portfoliosToReturn = []
        portfolioToReturn = nil
        holdingsToReturn = []
        holdingToReturn = nil
        performanceToReturn = nil
        allocationToReturn = nil
        ledgerEntriesToReturn = []
        ledgerEntryToReturn = nil
        costBasisSummaryToReturn = nil
        portfoliosSummaryToReturn = nil
        holdingsSummaryToReturn = nil
        ledgerSummaryToReturn = nil
        errorToThrow = nil

        fetchPortfoliosCalled = false
        fetchPortfolioIdCalled = nil
        fetchDefaultPortfolioCalled = false
        createPortfolioCalled = false
        updatePortfolioCalled = false
        setDefaultPortfolioIdCalled = nil
        deletePortfolioIdCalled = nil
        fetchHoldingsPortfolioIdCalled = nil
        fetchHoldingIdCalled = nil
        addHoldingCalled = false
        updateHoldingCalled = false
        removeHoldingIdCalled = nil
        refreshHoldingPricesPortfolioIdCalled = nil
        fetchPerformancePortfolioIdCalled = nil
        fetchPerformancePeriodCalled = nil
        fetchCombinedPerformanceCalled = false
        fetchAllocationPortfolioIdCalled = nil
        fetchAllocationGroupByCalled = nil
        fetchCombinedAllocationCalled = false
        fetchLedgerEntriesPortfolioIdCalled = nil
        fetchLedgerEntriesPageCalled = nil
        fetchLedgerEntriesLimitCalled = nil
        addLedgerEntryCalled = false
        lastAddedLedgerEntry = nil
        updateLedgerEntryCalled = false
        deleteLedgerEntryIdCalled = nil
        getCostBasisSymbolCalled = nil
        depositCashAmountCalled = nil
        depositCashPortfolioIdCalled = nil
        withdrawCashAmountCalled = nil
        withdrawCashPortfolioIdCalled = nil
        transferCashCalled = false
        invalidateCacheCalled = false
        invalidateCachePortfolioIdCalled = nil
        prefetchPortfoliosCalled = false
    }

    // MARK: - PortfolioRepositoryProtocol Implementation

    func fetchPortfolios() async throws -> [Portfolio] {
        fetchPortfoliosCalled = true
        if let error = errorToThrow { throw error }
        return portfoliosToReturn
    }

    func fetchPortfolio(id: String) async throws -> Portfolio {
        fetchPortfolioIdCalled = id
        if let error = errorToThrow { throw error }
        if let portfolio = portfolioToReturn { return portfolio }
        return MockPortfolioRepository.samplePortfolio(id: id)
    }

    func fetchDefaultPortfolio() async throws -> Portfolio? {
        fetchDefaultPortfolioCalled = true
        if let error = errorToThrow { throw error }
        return portfolioToReturn ?? portfoliosToReturn.first { $0.isDefault }
    }

    func createPortfolio(_ portfolio: Portfolio) async throws -> Portfolio {
        createPortfolioCalled = true
        if let error = errorToThrow { throw error }
        return portfolioToReturn ?? portfolio
    }

    func updatePortfolio(_ portfolio: Portfolio) async throws -> Portfolio {
        updatePortfolioCalled = true
        if let error = errorToThrow { throw error }
        return portfolioToReturn ?? portfolio
    }

    func setDefaultPortfolio(id: String) async throws -> Portfolio {
        setDefaultPortfolioIdCalled = id
        if let error = errorToThrow { throw error }
        if let portfolio = portfolioToReturn { return portfolio }
        return MockPortfolioRepository.samplePortfolio(id: id, isDefault: true)
    }

    func deletePortfolio(id: String) async throws {
        deletePortfolioIdCalled = id
        if let error = errorToThrow { throw error }
    }

    func fetchHoldings(for portfolioId: String) async throws -> [Holding] {
        fetchHoldingsPortfolioIdCalled = portfolioId
        if let error = errorToThrow { throw error }
        return holdingsToReturn
    }

    func fetchHolding(id holdingId: String, in portfolioId: String) async throws -> Holding {
        fetchHoldingIdCalled = holdingId
        if let error = errorToThrow { throw error }
        if let holding = holdingToReturn { return holding }
        return MockPortfolioRepository.sampleHolding(id: holdingId, portfolioId: portfolioId)
    }

    func addHolding(_ holding: Holding, to portfolioId: String) async throws -> Holding {
        addHoldingCalled = true
        if let error = errorToThrow { throw error }
        return holdingToReturn ?? holding
    }

    func updateHolding(_ holding: Holding) async throws -> Holding {
        updateHoldingCalled = true
        if let error = errorToThrow { throw error }
        return holdingToReturn ?? holding
    }

    func removeHolding(id holdingId: String, from portfolioId: String) async throws {
        removeHoldingIdCalled = holdingId
        if let error = errorToThrow { throw error }
    }

    func refreshHoldingPrices(for portfolioId: String) async throws -> [Holding] {
        refreshHoldingPricesPortfolioIdCalled = portfolioId
        if let error = errorToThrow { throw error }
        return holdingsToReturn
    }

    func fetchPerformance(for portfolioId: String, period: PerformancePeriod) async throws -> PortfolioPerformance {
        fetchPerformancePortfolioIdCalled = portfolioId
        fetchPerformancePeriodCalled = period
        if let error = errorToThrow { throw error }
        if let performance = performanceToReturn { return performance }
        return MockPortfolioRepository.samplePerformance(portfolioId: portfolioId, period: period)
    }

    func fetchCombinedPerformance(period: PerformancePeriod) async throws -> PortfolioPerformance {
        fetchCombinedPerformanceCalled = true
        fetchPerformancePeriodCalled = period
        if let error = errorToThrow { throw error }
        if let performance = performanceToReturn { return performance }
        return MockPortfolioRepository.samplePerformance(portfolioId: "combined", period: period)
    }

    func fetchAllocation(for portfolioId: String, groupBy: AllocationGrouping) async throws -> PortfolioAllocation {
        fetchAllocationPortfolioIdCalled = portfolioId
        fetchAllocationGroupByCalled = groupBy
        if let error = errorToThrow { throw error }
        if let allocation = allocationToReturn { return allocation }
        return MockPortfolioRepository.sampleAllocation(portfolioId: portfolioId)
    }

    func fetchCombinedAllocation(groupBy: AllocationGrouping) async throws -> PortfolioAllocation {
        fetchCombinedAllocationCalled = true
        fetchAllocationGroupByCalled = groupBy
        if let error = errorToThrow { throw error }
        if let allocation = allocationToReturn { return allocation }
        return MockPortfolioRepository.sampleAllocation(portfolioId: "combined")
    }

    func fetchLedgerEntries(for portfolioId: String, page: Int, limit: Int) async throws -> PaginatedResponse<LedgerEntry> {
        fetchLedgerEntriesPortfolioIdCalled = portfolioId
        fetchLedgerEntriesPageCalled = page
        fetchLedgerEntriesLimitCalled = limit
        if let error = errorToThrow { throw error }
        return PaginatedResponse(
            data: ledgerEntriesToReturn,
            pagination: PaginatedResponse.Pagination(
                page: page,
                limit: limit,
                totalPages: 1,
                totalItems: ledgerEntriesToReturn.count
            )
        )
    }

    func fetchLedgerEntries(for portfolioId: String, types: [LedgerEntryType]) async throws -> [LedgerEntry] {
        fetchLedgerEntriesPortfolioIdCalled = portfolioId
        if let error = errorToThrow { throw error }
        return ledgerEntriesToReturn.filter { types.contains($0.type) }
    }

    func fetchLedgerEntries(for portfolioId: String, from startDate: Date, to endDate: Date) async throws -> [LedgerEntry] {
        fetchLedgerEntriesPortfolioIdCalled = portfolioId
        if let error = errorToThrow { throw error }
        return ledgerEntriesToReturn.filter { $0.transactionDate >= startDate && $0.transactionDate <= endDate }
    }

    func addLedgerEntry(_ entry: LedgerEntry, to portfolioId: String) async throws -> LedgerEntry {
        addLedgerEntryCalled = true
        lastAddedLedgerEntry = entry
        if let error = errorToThrow { throw error }
        return ledgerEntryToReturn ?? entry
    }

    func updateLedgerEntry(_ entry: LedgerEntry) async throws -> LedgerEntry {
        updateLedgerEntryCalled = true
        if let error = errorToThrow { throw error }
        return ledgerEntryToReturn ?? entry
    }

    func deleteLedgerEntry(id entryId: String, from portfolioId: String) async throws {
        deleteLedgerEntryIdCalled = entryId
        if let error = errorToThrow { throw error }
    }

    func getCostBasis(symbol: String) async throws -> CostBasisSummary {
        getCostBasisSymbolCalled = symbol
        if let error = errorToThrow { throw error }
        if let summary = costBasisSummaryToReturn { return summary }
        return MockPortfolioRepository.sampleCostBasisSummary(symbol: symbol)
    }

    func depositCash(amount: Decimal, to portfolioId: String, notes: String?) async throws -> LedgerEntry {
        depositCashAmountCalled = amount
        depositCashPortfolioIdCalled = portfolioId
        if let error = errorToThrow { throw error }
        return ledgerEntryToReturn ?? MockPortfolioRepository.sampleLedgerEntry(portfolioId: portfolioId, type: .deposit, amount: amount)
    }

    func withdrawCash(amount: Decimal, from portfolioId: String, notes: String?) async throws -> LedgerEntry {
        withdrawCashAmountCalled = amount
        withdrawCashPortfolioIdCalled = portfolioId
        if let error = errorToThrow { throw error }
        return ledgerEntryToReturn ?? MockPortfolioRepository.sampleLedgerEntry(portfolioId: portfolioId, type: .withdrawal, amount: amount)
    }

    func transferCash(amount: Decimal, from sourcePortfolioId: String, to destinationPortfolioId: String, notes: String?) async throws {
        transferCashCalled = true
        if let error = errorToThrow { throw error }
    }

    func fetchPortfoliosSummary() async throws -> PortfoliosSummary {
        if let error = errorToThrow { throw error }
        if let summary = portfoliosSummaryToReturn { return summary }
        return PortfoliosSummary(portfolios: portfoliosToReturn)
    }

    func fetchHoldingsSummary(for portfolioId: String) async throws -> HoldingsSummary {
        if let error = errorToThrow { throw error }
        if let summary = holdingsSummaryToReturn { return summary }
        return HoldingsSummary(holdings: holdingsToReturn)
    }

    func fetchLedgerSummary(for portfolioId: String) async throws -> LedgerSummary {
        if let error = errorToThrow { throw error }
        if let summary = ledgerSummaryToReturn { return summary }
        return LedgerSummary(entries: ledgerEntriesToReturn)
    }

    func invalidateCache() async {
        invalidateCacheCalled = true
    }

    func invalidateCache(for portfolioId: String) async {
        invalidateCachePortfolioIdCalled = portfolioId
    }

    func prefetchPortfolios() async throws {
        prefetchPortfoliosCalled = true
        if let error = errorToThrow { throw error }
    }

    // MARK: - Sample Data Generators

    static func samplePortfolio(
        id: String = "portfolio-1",
        userId: String = "user-1",
        name: String = "Main Portfolio",
        totalValue: Decimal = 10000,
        totalCostBasis: Decimal = 8000,
        cashBalance: Decimal = 1000,
        isDefault: Bool = true
    ) -> Portfolio {
        Portfolio(
            id: id,
            userId: userId,
            name: name,
            type: .personal,
            totalValue: totalValue,
            totalCostBasis: totalCostBasis,
            cashBalance: cashBalance,
            isDefault: isDefault
        )
    }

    static func sampleHolding(
        id: String = "holding-1",
        portfolioId: String = "portfolio-1",
        symbol: String = "AAPL",
        name: String = "Apple Inc.",
        quantity: Decimal = 10,
        averageCost: Decimal = 150,
        currentPrice: Decimal = 185
    ) -> Holding {
        Holding(
            id: id,
            portfolioId: portfolioId,
            stockSymbol: symbol,
            stockName: name,
            quantity: quantity,
            averageCostPerShare: averageCost,
            currentPricePerShare: currentPrice
        )
    }

    static func samplePerformance(
        portfolioId: String,
        period: PerformancePeriod
    ) -> PortfolioPerformance {
        PortfolioPerformance(
            portfolioId: portfolioId,
            period: period,
            startValue: 8000,
            endValue: 10000,
            absoluteReturn: 2000,
            percentageReturn: 25
        )
    }

    static func sampleAllocation(portfolioId: String) -> PortfolioAllocation {
        PortfolioAllocation(
            portfolioId: portfolioId,
            allocations: [
                AllocationItem(category: "Technology", value: 6000, percentage: 60, colorHex: "#007AFF"),
                AllocationItem(category: "Healthcare", value: 4000, percentage: 40, colorHex: "#34C759")
            ]
        )
    }

    static func sampleLedgerEntry(
        portfolioId: String = "portfolio-1",
        type: LedgerEntryType = .deposit,
        amount: Decimal = 1000
    ) -> LedgerEntry {
        LedgerEntry(
            portfolioId: portfolioId,
            userId: "user-1",
            type: type,
            totalAmount: amount
        )
    }

    static func sampleCostBasisSummary(symbol: String) -> CostBasisSummary {
        CostBasisSummary(
            symbol: symbol,
            totalShares: 10,
            totalCostUsd: 1500,
            totalCostGbp: 1200,
            averageCostUsd: 150,
            averageCostGbp: 120,
            lots: [],
            currentPriceUsd: 185,
            currentFxRate: 1.25
        )
    }
}
