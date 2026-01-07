//
//  MockPortfolioRepository.swift
//  Growfolio
//
//  Mock implementation of PortfolioRepositoryProtocol for demo mode.
//

import Foundation

/// Mock implementation of PortfolioRepositoryProtocol
final class MockPortfolioRepository: PortfolioRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let store = MockDataStore.shared
    private let config = MockConfiguration.shared

    // MARK: - Portfolio Operations

    func fetchPortfolios() async throws -> [Portfolio] {
        try await simulateNetwork()
        await ensureInitialized()
        return await store.portfolios
    }

    func fetchPortfolio(id: String) async throws -> Portfolio {
        try await simulateNetwork()
        await ensureInitialized()

        guard let portfolio = await store.portfolios.first(where: { $0.id == id }) else {
            throw PortfolioRepositoryError.portfolioNotFound(id: id)
        }
        return portfolio
    }

    func fetchDefaultPortfolio() async throws -> Portfolio? {
        try await simulateNetwork()
        await ensureInitialized()
        return await store.portfolios.first { $0.isDefault }
    }

    func createPortfolio(_ portfolio: Portfolio) async throws -> Portfolio {
        try await simulateNetwork()
        await ensureInitialized()

        let newPortfolio = Portfolio(
            id: MockDataGenerator.mockId(prefix: "portfolio"),
            userId: portfolio.userId,
            name: portfolio.name,
            description: portfolio.description,
            type: portfolio.type,
            currencyCode: portfolio.currencyCode,
            totalValue: 0,
            totalCostBasis: 0,
            cashBalance: portfolio.cashBalance,
            lastValuationDate: Date(),
            isDefault: portfolio.isDefault,
            colorHex: portfolio.colorHex,
            iconName: portfolio.iconName,
            createdAt: Date(),
            updatedAt: Date()
        )

        // If this is set as default, unset others
        if newPortfolio.isDefault {
            await store.setDefaultPortfolio(id: newPortfolio.id)
        }

        await store.addPortfolio(newPortfolio)
        return newPortfolio
    }

    func updatePortfolio(_ portfolio: Portfolio) async throws -> Portfolio {
        try await simulateNetwork()

        var updatedPortfolio = portfolio
        updatedPortfolio.updatedAt = Date()
        await store.updatePortfolio(updatedPortfolio)
        return updatedPortfolio
    }

    func setDefaultPortfolio(id: String) async throws -> Portfolio {
        try await simulateNetwork()

        await store.setDefaultPortfolio(id: id)

        guard let portfolio = await store.portfolios.first(where: { $0.id == id }) else {
            throw PortfolioRepositoryError.portfolioNotFound(id: id)
        }
        return portfolio
    }

    func deletePortfolio(id: String) async throws {
        try await simulateNetwork()

        let portfolios = await store.portfolios
        guard let portfolio = portfolios.first(where: { $0.id == id }) else {
            throw PortfolioRepositoryError.portfolioNotFound(id: id)
        }

        if portfolio.isDefault && portfolios.count > 1 {
            throw PortfolioRepositoryError.cannotDeleteDefaultPortfolio
        }

        let holdings = await store.getHoldings(for: id)
        if !holdings.isEmpty {
            throw PortfolioRepositoryError.cannotDeletePortfolioWithHoldings
        }

        await store.deletePortfolio(id: id)
    }

    // MARK: - Holdings Operations

    func fetchHoldings(for portfolioId: String) async throws -> [Holding] {
        try await simulateNetwork()
        await ensureInitialized()

        var holdings = await store.getHoldings(for: portfolioId)

        // Refresh prices if enabled
        if config.simulatePriceFluctuations {
            holdings = holdings.map { holding in
                var updated = holding
                updated.currentPricePerShare = MockStockDataProvider.currentPrice(for: holding.stockSymbol)
                updated.priceUpdatedAt = Date()
                return updated
            }

            // Update store with new prices
            for holding in holdings {
                await store.updateHolding(holding)
            }
        }

        return holdings
    }

    func fetchHolding(id holdingId: String, in portfolioId: String) async throws -> Holding {
        try await simulateNetwork()

        let holdings = await store.getHoldings(for: portfolioId)
        guard let holding = holdings.first(where: { $0.id == holdingId }) else {
            throw PortfolioRepositoryError.holdingNotFound(id: holdingId)
        }
        return holding
    }

    func addHolding(_ holding: Holding, to portfolioId: String) async throws -> Holding {
        try await simulateNetwork()

        let existingHoldings = await store.getHoldings(for: portfolioId)
        if existingHoldings.contains(where: { $0.stockSymbol == holding.stockSymbol }) {
            throw PortfolioRepositoryError.duplicateHolding(symbol: holding.stockSymbol)
        }

        let newHolding = Holding(
            id: MockDataGenerator.mockId(prefix: "holding"),
            portfolioId: portfolioId,
            stockSymbol: holding.stockSymbol,
            stockName: holding.stockName ?? MockStockDataProvider.stockProfiles[holding.stockSymbol]?.name,
            quantity: holding.quantity,
            averageCostPerShare: holding.averageCostPerShare,
            currentPricePerShare: MockStockDataProvider.currentPrice(for: holding.stockSymbol),
            firstPurchaseDate: Date(),
            sector: holding.sector ?? MockStockDataProvider.stockProfiles[holding.stockSymbol]?.sector,
            industry: holding.industry ?? MockStockDataProvider.stockProfiles[holding.stockSymbol]?.industry,
            assetType: holding.assetType,
            createdAt: Date(),
            updatedAt: Date()
        )

        await store.addHolding(newHolding, to: portfolioId)
        return newHolding
    }

    func updateHolding(_ holding: Holding) async throws -> Holding {
        try await simulateNetwork()

        var updatedHolding = holding
        updatedHolding.updatedAt = Date()
        await store.updateHolding(updatedHolding)
        return updatedHolding
    }

    func removeHolding(id holdingId: String, from portfolioId: String) async throws {
        try await simulateNetwork()
        await store.deleteHolding(id: holdingId, from: portfolioId)
    }

    func refreshHoldingPrices(for portfolioId: String) async throws -> [Holding] {
        try await simulateNetwork()
        return try await fetchHoldings(for: portfolioId)
    }

    // MARK: - Performance Operations

    func fetchPerformance(for portfolioId: String, period: PerformancePeriod) async throws -> PortfolioPerformance {
        try await simulateNetwork()
        await ensureInitialized()

        guard let portfolio = await store.portfolios.first(where: { $0.id == portfolioId }) else {
            throw PortfolioRepositoryError.portfolioNotFound(id: portfolioId)
        }

        return generatePerformance(for: portfolio, period: period)
    }

    func fetchCombinedPerformance(period: PerformancePeriod) async throws -> PortfolioPerformance {
        try await simulateNetwork()
        await ensureInitialized()

        let portfolios = await store.portfolios
        let totalValue = portfolios.reduce(Decimal.zero) { $0 + $1.totalValue }
        let totalCostBasis = portfolios.reduce(Decimal.zero) { $0 + $1.totalCostBasis }

        let combinedPortfolio = Portfolio(
            id: "combined",
            userId: await store.currentUser?.id ?? "mock",
            name: "All Portfolios",
            totalValue: totalValue,
            totalCostBasis: totalCostBasis
        )

        return generatePerformance(for: combinedPortfolio, period: period)
    }

    // MARK: - Allocation Operations

    func fetchAllocation(for portfolioId: String, groupBy: AllocationGrouping) async throws -> PortfolioAllocation {
        try await simulateNetwork()

        let holdings = await store.getHoldings(for: portfolioId)
        return generateAllocation(from: holdings, portfolioId: portfolioId, groupBy: groupBy)
    }

    func fetchCombinedAllocation(groupBy: AllocationGrouping) async throws -> PortfolioAllocation {
        try await simulateNetwork()

        var allHoldings: [Holding] = []
        for portfolio in await store.portfolios {
            let portfolioHoldings = await store.getHoldings(for: portfolio.id)
            allHoldings.append(contentsOf: portfolioHoldings)
        }

        return generateAllocation(from: allHoldings, portfolioId: "combined", groupBy: groupBy)
    }

    // MARK: - Ledger Operations

    func fetchLedgerEntries(for portfolioId: String, page: Int, limit: Int) async throws -> PaginatedResponse<LedgerEntry> {
        try await simulateNetwork()

        let allEntries = await store.getLedgerEntries(for: portfolioId)
            .sorted { $0.transactionDate > $1.transactionDate }

        let startIndex = (page - 1) * limit
        let endIndex = min(startIndex + limit, allEntries.count)

        guard startIndex < allEntries.count else {
            let totalPages = allEntries.isEmpty ? 1 : (allEntries.count + limit - 1) / limit
            return PaginatedResponse(
                data: [],
                pagination: PaginatedResponse.Pagination(page: page, limit: limit, totalPages: totalPages, totalItems: allEntries.count)
            )
        }

        let pageItems = Array(allEntries[startIndex..<endIndex])
        let totalPages = (allEntries.count + limit - 1) / limit
        return PaginatedResponse(
            data: pageItems,
            pagination: PaginatedResponse.Pagination(page: page, limit: limit, totalPages: totalPages, totalItems: allEntries.count)
        )
    }

    func fetchLedgerEntries(for portfolioId: String, types: [LedgerEntryType]) async throws -> [LedgerEntry] {
        try await simulateNetwork()

        return await store.getLedgerEntries(for: portfolioId)
            .filter { types.contains($0.type) }
            .sorted { $0.transactionDate > $1.transactionDate }
    }

    func fetchLedgerEntries(for portfolioId: String, from startDate: Date, to endDate: Date) async throws -> [LedgerEntry] {
        try await simulateNetwork()

        return await store.getLedgerEntries(for: portfolioId)
            .filter { $0.transactionDate >= startDate && $0.transactionDate <= endDate }
            .sorted { $0.transactionDate > $1.transactionDate }
    }

    func addLedgerEntry(_ entry: LedgerEntry, to portfolioId: String) async throws -> LedgerEntry {
        try await simulateNetwork()

        let newEntry = LedgerEntry(
            id: MockDataGenerator.mockId(prefix: "ledger"),
            portfolioId: portfolioId,
            userId: entry.userId,
            type: entry.type,
            stockSymbol: entry.stockSymbol,
            stockName: entry.stockName,
            quantity: entry.quantity,
            pricePerShare: entry.pricePerShare,
            totalAmount: entry.totalAmount,
            fees: entry.fees,
            currencyCode: entry.currencyCode,
            transactionDate: entry.transactionDate,
            notes: entry.notes,
            source: entry.source,
            referenceId: entry.referenceId,
            createdAt: Date(),
            updatedAt: Date()
        )

        await store.addLedgerEntry(newEntry, to: portfolioId)
        return newEntry
    }

    func updateLedgerEntry(_ entry: LedgerEntry) async throws -> LedgerEntry {
        try await simulateNetwork()
        // For mock, we don't actually update - just return the entry
        return entry
    }

    func deleteLedgerEntry(id entryId: String, from portfolioId: String) async throws {
        try await simulateNetwork()
        // For mock, no-op
    }

    // MARK: - Cost Basis Operations

    func getCostBasis(symbol: String) async throws -> CostBasisSummary {
        try await simulateNetwork()

        // Aggregate across all portfolios
        var totalShares: Decimal = 0
        var totalCostUsd: Decimal = 0
        var lots: [CostBasisLot] = []
        let fxRate: Decimal = 1.27 // Mock GBP/USD rate

        for portfolio in await store.portfolios {
            let holdings = await store.getHoldings(for: portfolio.id)
            if let holding = holdings.first(where: { $0.stockSymbol == symbol }) {
                totalShares += holding.quantity
                totalCostUsd += holding.costBasis

                // Generate mock lots for this holding
                let purchasePrice = holding.costBasis / holding.quantity
                let lot = CostBasisLot(
                    date: MockDataGenerator.pastDate(daysAgo: Int.random(in: 30...365)),
                    shares: holding.quantity,
                    priceUsd: purchasePrice,
                    totalUsd: holding.costBasis,
                    totalGbp: holding.costBasis / fxRate,
                    fxRate: fxRate
                )
                lots.append(lot)
            }
        }

        let totalCostGbp = totalCostUsd / fxRate
        let avgCostUsd = totalShares > 0 ? totalCostUsd / totalShares : 0
        let avgCostGbp = totalShares > 0 ? totalCostGbp / totalShares : 0
        let currentPrice = MockStockDataProvider.currentPrice(for: symbol)

        return CostBasisSummary(
            symbol: symbol,
            totalShares: totalShares,
            totalCostUsd: totalCostUsd,
            totalCostGbp: totalCostGbp,
            averageCostUsd: avgCostUsd,
            averageCostGbp: avgCostGbp,
            lots: lots,
            currentPriceUsd: currentPrice,
            currentFxRate: fxRate
        )
    }

    // MARK: - Cash Operations

    func depositCash(amount: Decimal, to portfolioId: String, notes: String?) async throws -> LedgerEntry {
        try await simulateNetwork()

        let userId = await store.currentUser?.id ?? "mock"
        let entry = LedgerEntry(
            portfolioId: portfolioId,
            userId: userId,
            type: .deposit,
            totalAmount: amount,
            transactionDate: Date(),
            notes: notes,
            source: .manual
        )

        await store.addLedgerEntry(entry, to: portfolioId)

        // Update portfolio cash balance
        if var portfolio = await store.portfolios.first(where: { $0.id == portfolioId }) {
            portfolio.cashBalance += amount
            portfolio.updatedAt = Date()
            await store.updatePortfolio(portfolio)
        }

        return entry
    }

    func withdrawCash(amount: Decimal, from portfolioId: String, notes: String?) async throws -> LedgerEntry {
        try await simulateNetwork()

        guard let portfolio = await store.portfolios.first(where: { $0.id == portfolioId }) else {
            throw PortfolioRepositoryError.portfolioNotFound(id: portfolioId)
        }

        guard portfolio.cashBalance >= amount else {
            throw PortfolioRepositoryError.insufficientCash
        }

        let userId = await store.currentUser?.id ?? "mock"
        let entry = LedgerEntry(
            portfolioId: portfolioId,
            userId: userId,
            type: .withdrawal,
            totalAmount: amount,
            transactionDate: Date(),
            notes: notes,
            source: .manual
        )

        await store.addLedgerEntry(entry, to: portfolioId)

        // Update portfolio cash balance
        var updatedPortfolio = portfolio
        updatedPortfolio.cashBalance -= amount
        updatedPortfolio.updatedAt = Date()
        await store.updatePortfolio(updatedPortfolio)

        return entry
    }

    func transferCash(amount: Decimal, from sourcePortfolioId: String, to destinationPortfolioId: String, notes: String?) async throws {
        try await simulateNetwork()

        // Withdraw from source
        _ = try await withdrawCash(amount: amount, from: sourcePortfolioId, notes: "Transfer to another portfolio")

        // Deposit to destination
        _ = try await depositCash(amount: amount, to: destinationPortfolioId, notes: "Transfer from another portfolio")
    }

    // MARK: - Summary Operations

    func fetchPortfoliosSummary() async throws -> PortfoliosSummary {
        try await simulateNetwork()
        await ensureInitialized()
        return PortfoliosSummary(portfolios: await store.portfolios)
    }

    func fetchHoldingsSummary(for portfolioId: String) async throws -> HoldingsSummary {
        try await simulateNetwork()
        let holdings = await store.getHoldings(for: portfolioId)
        return HoldingsSummary(holdings: holdings)
    }

    func fetchLedgerSummary(for portfolioId: String) async throws -> LedgerSummary {
        try await simulateNetwork()
        let entries = await store.getLedgerEntries(for: portfolioId)
        return LedgerSummary(entries: entries)
    }

    // MARK: - Cache Operations

    func invalidateCache() async {
        // No-op for mock
    }

    func invalidateCache(for portfolioId: String) async {
        // No-op for mock
    }

    func prefetchPortfolios() async throws {
        await ensureInitialized()
    }

    // MARK: - Private Methods

    private func simulateNetwork() async throws {
        try await config.simulateNetworkDelay()
        try config.maybeThrowSimulatedError()
    }

    private func ensureInitialized() async {
        if await store.portfolios.isEmpty {
            await store.initialize(for: config.demoPersona)
        }
    }

    private func generatePerformance(for portfolio: Portfolio, period: PerformancePeriod) -> PortfolioPerformance {
        let endValue = portfolio.totalValue
        let startValue = portfolio.totalCostBasis > 0 ? portfolio.totalCostBasis : endValue * Decimal(0.9)
        let absoluteReturn = endValue - startValue
        let percentageReturn = startValue > 0 ? (absoluteReturn / startValue) * 100 : 0

        // Generate data points
        let dataPoints = generatePerformanceDataPoints(startValue: startValue, endValue: endValue, period: period)

        return PortfolioPerformance(
            portfolioId: portfolio.id,
            period: period,
            startValue: startValue,
            endValue: endValue,
            absoluteReturn: absoluteReturn,
            percentageReturn: percentageReturn,
            annualizedReturn: percentageReturn, // Simplified
            benchmarkReturn: MockDataGenerator.percentageChange(min: 5, max: 15),
            dataPoints: dataPoints,
            calculatedAt: Date()
        )
    }

    private func generatePerformanceDataPoints(startValue: Decimal, endValue: Decimal, period: PerformancePeriod) -> [PerformanceDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        let intervalDays: Int

        switch period {
        case .oneDay:
            startDate = calendar.date(byAdding: .day, value: -1, to: endDate)!
            intervalDays = 1
        case .oneWeek:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: endDate)!
            intervalDays = 1
        case .oneMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
            intervalDays = 1
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: endDate)!
            intervalDays = 2
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: endDate)!
            intervalDays = 3
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
            intervalDays = 5
        case .yearToDate:
            var components = calendar.dateComponents([.year], from: endDate)
            components.month = 1
            components.day = 1
            startDate = calendar.date(from: components)!
            intervalDays = 3
        case .all:
            startDate = calendar.date(byAdding: .year, value: -5, to: endDate)!
            intervalDays = 14
        }

        var dataPoints: [PerformanceDataPoint] = []
        var currentDate = startDate
        var currentValue = NSDecimalNumber(decimal: startValue).doubleValue

        let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
        let dailyGrowth = (NSDecimalNumber(decimal: endValue).doubleValue / currentValue - 1) / Double(totalDays)

        while currentDate <= endDate {
            // Random walk with bias toward end value
            let noise = Double.random(in: -0.01...0.01)
            currentValue = currentValue * (1 + dailyGrowth + noise)

            let cumulativeReturn = startValue > 0 ? ((Decimal(currentValue) - startValue) / startValue) * 100 : 0

            dataPoints.append(PerformanceDataPoint(
                date: currentDate,
                value: Decimal(currentValue).rounded(places: 2),
                cumulativeReturn: cumulativeReturn.rounded(places: 2)
            ))

            currentDate = calendar.date(byAdding: .day, value: intervalDays, to: currentDate) ?? endDate
        }

        return dataPoints
    }

    private func generateAllocation(from holdings: [Holding], portfolioId: String, groupBy: AllocationGrouping) -> PortfolioAllocation {
        let totalValue = holdings.reduce(Decimal.zero) { $0 + $1.marketValue }

        let colors = ["#007AFF", "#34C759", "#FF9500", "#FF2D55", "#5856D6", "#AF52DE", "#00C7BE", "#FF3B30"]
        var colorIndex = 0

        let grouped: [String: [Holding]]

        switch groupBy {
        case .sector:
            grouped = Dictionary(grouping: holdings) { $0.sector ?? "Other" }
        case .assetType:
            grouped = Dictionary(grouping: holdings) { $0.assetType.displayName }
        case .industry:
            grouped = Dictionary(grouping: holdings) { $0.industry ?? "Other" }
        case .holding:
            grouped = Dictionary(grouping: holdings) { $0.stockSymbol }
        }

        let allocations = grouped.map { (category, categoryHoldings) -> AllocationItem in
            let value = categoryHoldings.reduce(Decimal.zero) { $0 + $1.marketValue }
            let percentage = totalValue > 0 ? (value / totalValue) * 100 : 0
            let color = colors[colorIndex % colors.count]
            colorIndex += 1

            return AllocationItem(
                category: category,
                value: value,
                percentage: percentage,
                colorHex: color
            )
        }.sorted { $0.percentage > $1.percentage }

        return PortfolioAllocation(
            portfolioId: portfolioId,
            allocations: allocations,
            calculatedAt: Date()
        )
    }
}


