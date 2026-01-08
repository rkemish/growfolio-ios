//
//  PortfolioRepository.swift
//  Growfolio
//
//  Implementation of PortfolioRepositoryProtocol using the API client.
//

import Foundation

/// Implementation of the portfolio repository using the API client
final class PortfolioRepository: PortfolioRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let apiClient: APIClientProtocol
    private var cachedPortfolios: [Portfolio] = []
    private var cachedHoldings: [String: [Holding]] = [:] // portfolioId -> holdings
    private var lastFetchTime: Date?
    private let cacheDuration: TimeInterval = 60 // 1 minute cache

    // MARK: - Initialization

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - Portfolio Operations

    func fetchPortfolios() async throws -> [Portfolio] {
        // Check cache first to reduce API calls
        // Cache is valid for 1 minute and must not be empty
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheDuration,
           !cachedPortfolios.isEmpty {
            return cachedPortfolios
        }

        // Cache miss or expired - fetch fresh data from API
        let portfolios: [Portfolio] = try await apiClient.request(Endpoints.GetPortfolios())

        // Update cache with fresh data
        cachedPortfolios = portfolios
        lastFetchTime = Date()

        return portfolios
    }

    func fetchPortfolio(id: String) async throws -> Portfolio {
        // Check cache first
        if let cached = cachedPortfolios.first(where: { $0.id == id }) {
            return cached
        }

        return try await apiClient.request(Endpoints.GetPortfolio(id: id))
    }

    func fetchDefaultPortfolio() async throws -> Portfolio? {
        let portfolios = try await fetchPortfolios()
        return portfolios.first { $0.isDefault }
    }

    func createPortfolio(_ portfolio: Portfolio) async throws -> Portfolio {
        // Portfolio creation is handled server-side through Alpaca brokerage account setup
        // Users don't directly create portfolios - they're auto-created during onboarding
        // This method exists for protocol conformance but isn't used in the current flow
        throw PortfolioRepositoryError.invalidPortfolioData
    }

    func updatePortfolio(_ portfolio: Portfolio) async throws -> Portfolio {
        // This would need a dedicated endpoint
        throw PortfolioRepositoryError.invalidPortfolioData
    }

    func setDefaultPortfolio(id: String) async throws -> Portfolio {
        // This would need a dedicated endpoint
        throw PortfolioRepositoryError.portfolioNotFound(id: id)
    }

    func deletePortfolio(id: String) async throws {
        throw PortfolioRepositoryError.cannotDeleteDefaultPortfolio
    }

    // MARK: - Holdings Operations

    func fetchHoldings(for portfolioId: String) async throws -> [Holding] {
        // Check cache first
        if let cached = cachedHoldings[portfolioId], !cached.isEmpty {
            return cached
        }

        let holdings: [Holding] = try await apiClient.request(
            Endpoints.GetPortfolioHoldings(portfolioId: portfolioId)
        )

        cachedHoldings[portfolioId] = holdings

        return holdings
    }

    func fetchHolding(id holdingId: String, in portfolioId: String) async throws -> Holding {
        let holdings = try await fetchHoldings(for: portfolioId)

        guard let holding = holdings.first(where: { $0.id == holdingId }) else {
            throw PortfolioRepositoryError.holdingNotFound(id: holdingId)
        }

        return holding
    }

    func addHolding(_ holding: Holding, to portfolioId: String) async throws -> Holding {
        // Holdings are created through trades, not directly
        throw PortfolioRepositoryError.invalidHoldingData
    }

    func updateHolding(_ holding: Holding) async throws -> Holding {
        throw PortfolioRepositoryError.invalidHoldingData
    }

    func removeHolding(id holdingId: String, from portfolioId: String) async throws {
        throw PortfolioRepositoryError.holdingNotFound(id: holdingId)
    }

    func refreshHoldingPrices(for portfolioId: String) async throws -> [Holding] {
        // Invalidate cache and refetch
        cachedHoldings.removeValue(forKey: portfolioId)
        return try await fetchHoldings(for: portfolioId)
    }

    // MARK: - Performance Operations

    func fetchPerformance(for portfolioId: String, period: PerformancePeriod) async throws -> PortfolioPerformance {
        return try await apiClient.request(
            Endpoints.GetPortfolioPerformance(portfolioId: portfolioId, period: period)
        )
    }

    func fetchCombinedPerformance(period: PerformancePeriod) async throws -> PortfolioPerformance {
        // This would aggregate across all portfolios
        let portfolios = try await fetchPortfolios()

        guard let defaultPortfolio = portfolios.first else {
            throw PortfolioRepositoryError.portfolioNotFound(id: "default")
        }

        return try await fetchPerformance(for: defaultPortfolio.id, period: period)
    }

    // MARK: - Allocation Operations

    func fetchAllocation(for portfolioId: String, groupBy: AllocationGrouping) async throws -> PortfolioAllocation {
        let holdings = try await fetchHoldings(for: portfolioId)

        let totalValue = holdings.reduce(Decimal.zero) { $0 + $1.marketValue }

        let allocations: [AllocationItem]

        switch groupBy {
        case .sector:
            let grouped = Dictionary(grouping: holdings) { $0.sector ?? "Unknown" }
            allocations = grouped.map { sector, sectorHoldings in
                let sectorValue = sectorHoldings.reduce(Decimal.zero) { $0 + $1.marketValue }
                let percentage = totalValue > 0 ? (sectorValue / totalValue) * 100 : 0
                return AllocationItem(
                    category: sector,
                    value: sectorValue,
                    percentage: percentage,
                    colorHex: sectorColorHex(for: sector)
                )
            }.sorted { $0.percentage > $1.percentage }

        case .assetType:
            let grouped = Dictionary(grouping: holdings) { $0.assetType.displayName }
            allocations = grouped.map { type, typeHoldings in
                let typeValue = typeHoldings.reduce(Decimal.zero) { $0 + $1.marketValue }
                let percentage = totalValue > 0 ? (typeValue / totalValue) * 100 : 0
                return AllocationItem(
                    category: type,
                    value: typeValue,
                    percentage: percentage,
                    colorHex: "#007AFF"
                )
            }.sorted { $0.percentage > $1.percentage }

        case .industry:
            let grouped = Dictionary(grouping: holdings) { $0.industry ?? "Unknown" }
            allocations = grouped.map { industry, industryHoldings in
                let industryValue = industryHoldings.reduce(Decimal.zero) { $0 + $1.marketValue }
                let percentage = totalValue > 0 ? (industryValue / totalValue) * 100 : 0
                return AllocationItem(
                    category: industry,
                    value: industryValue,
                    percentage: percentage,
                    colorHex: "#34C759"
                )
            }.sorted { $0.percentage > $1.percentage }

        case .holding:
            allocations = holdings.map { holding in
                let percentage = totalValue > 0 ? (holding.marketValue / totalValue) * 100 : 0
                return AllocationItem(
                    category: holding.displayName,
                    value: holding.marketValue,
                    percentage: percentage,
                    colorHex: "#007AFF"
                )
            }.sorted { $0.percentage > $1.percentage }
        }

        return PortfolioAllocation(
            portfolioId: portfolioId,
            allocations: allocations
        )
    }

    func fetchCombinedAllocation(groupBy: AllocationGrouping) async throws -> PortfolioAllocation {
        let portfolios = try await fetchPortfolios()

        guard let defaultPortfolio = portfolios.first else {
            throw PortfolioRepositoryError.portfolioNotFound(id: "default")
        }

        return try await fetchAllocation(for: defaultPortfolio.id, groupBy: groupBy)
    }

    // MARK: - Ledger Operations

    func fetchLedgerEntries(for portfolioId: String, page: Int, limit: Int) async throws -> PaginatedResponse<LedgerEntry> {
        return try await apiClient.request(
            Endpoints.GetLedgerEntries(portfolioId: portfolioId, page: page, limit: limit)
        )
    }

    func fetchLedgerEntries(for portfolioId: String, types: [LedgerEntryType]) async throws -> [LedgerEntry] {
        let response = try await fetchLedgerEntries(for: portfolioId, page: 1, limit: Constants.API.maxPageSize)
        return response.data.filter { types.contains($0.type) }
    }

    func fetchLedgerEntries(for portfolioId: String, from startDate: Date, to endDate: Date) async throws -> [LedgerEntry] {
        let response = try await fetchLedgerEntries(for: portfolioId, page: 1, limit: Constants.API.maxPageSize)
        return response.data.filter {
            $0.transactionDate >= startDate && $0.transactionDate <= endDate
        }
    }

    func addLedgerEntry(_ entry: LedgerEntry, to portfolioId: String) async throws -> LedgerEntry {
        let request = LedgerEntryCreateRequest(
            type: entry.type.rawValue,
            stockSymbol: entry.stockSymbol,
            quantity: entry.quantity,
            pricePerShare: entry.pricePerShare,
            totalAmount: entry.totalAmount,
            date: entry.transactionDate,
            notes: entry.notes
        )

        return try await apiClient.request(
            try Endpoints.CreateLedgerEntry(portfolioId: portfolioId, entry: request)
        )
    }

    func updateLedgerEntry(_ entry: LedgerEntry) async throws -> LedgerEntry {
        throw PortfolioRepositoryError.invalidLedgerEntry
    }

    func deleteLedgerEntry(id entryId: String, from portfolioId: String) async throws {
        throw PortfolioRepositoryError.ledgerEntryNotFound(id: entryId)
    }

    // MARK: - Cost Basis Operations

    func getCostBasis(symbol: String) async throws -> CostBasisSummary {
        let response: CostBasisResponse = try await apiClient.request(
            Endpoints.GetCostBasis(symbol: symbol)
        )
        return response.toCostBasisSummary()
    }

    // MARK: - Cash Operations

    func depositCash(amount: Decimal, to portfolioId: String, notes: String?) async throws -> LedgerEntry {
        let entry = LedgerEntry(
            portfolioId: portfolioId,
            userId: "", // Will be set by backend
            type: .deposit,
            totalAmount: amount,
            notes: notes
        )

        return try await addLedgerEntry(entry, to: portfolioId)
    }

    func withdrawCash(amount: Decimal, from portfolioId: String, notes: String?) async throws -> LedgerEntry {
        let entry = LedgerEntry(
            portfolioId: portfolioId,
            userId: "", // Will be set by backend
            type: .withdrawal,
            totalAmount: amount,
            notes: notes
        )

        return try await addLedgerEntry(entry, to: portfolioId)
    }

    func transferCash(amount: Decimal, from sourcePortfolioId: String, to destinationPortfolioId: String, notes: String?) async throws {
        // Withdraw from source
        _ = try await withdrawCash(amount: amount, from: sourcePortfolioId, notes: "Transfer to another portfolio - \(notes ?? "")")

        // Deposit to destination
        _ = try await depositCash(amount: amount, to: destinationPortfolioId, notes: "Transfer from another portfolio - \(notes ?? "")")
    }

    // MARK: - Summary Operations

    func fetchPortfoliosSummary() async throws -> PortfoliosSummary {
        let portfolios = try await fetchPortfolios()
        return PortfoliosSummary(portfolios: portfolios)
    }

    func fetchHoldingsSummary(for portfolioId: String) async throws -> HoldingsSummary {
        let holdings = try await fetchHoldings(for: portfolioId)
        return HoldingsSummary(holdings: holdings)
    }

    func fetchLedgerSummary(for portfolioId: String) async throws -> LedgerSummary {
        let response = try await fetchLedgerEntries(for: portfolioId, page: 1, limit: Constants.API.maxPageSize)
        return LedgerSummary(entries: response.data)
    }

    // MARK: - Cache Operations

    func invalidateCache() async {
        cachedPortfolios = []
        cachedHoldings = [:]
        lastFetchTime = nil
    }

    func invalidateCache(for portfolioId: String) async {
        cachedHoldings.removeValue(forKey: portfolioId)
    }

    func prefetchPortfolios() async throws {
        _ = try await fetchPortfolios()
    }

    // MARK: - Private Helpers

    private func sectorColorHex(for sector: String) -> String {
        switch sector.lowercased() {
        case "technology":
            return "#007AFF"
        case "healthcare":
            return "#30D158"
        case "financials", "financial":
            return "#FF9500"
        case "consumer discretionary":
            return "#FF2D55"
        case "communication services":
            return "#5856D6"
        case "industrials":
            return "#8E8E93"
        case "consumer staples":
            return "#34C759"
        case "energy":
            return "#FF3B30"
        case "utilities":
            return "#AF52DE"
        case "real estate":
            return "#00C7BE"
        case "materials":
            return "#5AC8FA"
        default:
            return "#8E8E93"
        }
    }
}

// MARK: - Cost Basis API Response

/// Response DTO for cost basis endpoint matching backend format
struct CostBasisResponse: Codable, Sendable {
    let symbol: String
    let totalShares: Double
    let totalCostUsd: Double
    let totalCostGbp: Double
    let averageCostUsd: Double
    let averageCostGbp: Double
    let lots: [CostBasisLotResponse]

    struct CostBasisLotResponse: Codable, Sendable {
        let date: String
        let shares: Double
        let priceUsd: Double
        let totalUsd: Double
        let totalGbp: Double
        let fxRate: Double
    }

    /// Convert to domain model
    func toCostBasisSummary() -> CostBasisSummary {
        let domainLots = lots.map { lot -> CostBasisLot in
            let date = Date.fromISO8601(lot.date) ?? Date()
            return CostBasisLot(
                date: date,
                shares: Decimal(lot.shares),
                priceUsd: Decimal(lot.priceUsd),
                totalUsd: Decimal(lot.totalUsd),
                totalGbp: Decimal(lot.totalGbp),
                fxRate: Decimal(lot.fxRate)
            )
        }

        return CostBasisSummary(
            symbol: symbol,
            totalShares: Decimal(totalShares),
            totalCostUsd: Decimal(totalCostUsd),
            totalCostGbp: Decimal(totalCostGbp),
            averageCostUsd: Decimal(averageCostUsd),
            averageCostGbp: Decimal(averageCostGbp),
            lots: domainLots
        )
    }
}
