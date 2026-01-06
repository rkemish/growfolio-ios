//
//  PortfolioRepositoryProtocol.swift
//  Growfolio
//
//  Protocol defining the portfolio repository interface.
//

import Foundation

/// Protocol for portfolio data operations
protocol PortfolioRepositoryProtocol: Sendable {

    // MARK: - Portfolio Operations

    /// Fetch all portfolios for the current user
    /// - Returns: Array of portfolios
    func fetchPortfolios() async throws -> [Portfolio]

    /// Fetch a specific portfolio by ID
    /// - Parameter id: Portfolio identifier
    /// - Returns: The portfolio if found
    func fetchPortfolio(id: String) async throws -> Portfolio

    /// Fetch the default portfolio
    /// - Returns: The default portfolio, or nil if not set
    func fetchDefaultPortfolio() async throws -> Portfolio?

    /// Create a new portfolio
    /// - Parameter portfolio: Portfolio to create
    /// - Returns: The created portfolio with server-assigned ID
    func createPortfolio(_ portfolio: Portfolio) async throws -> Portfolio

    /// Update an existing portfolio
    /// - Parameter portfolio: Portfolio with updated values
    /// - Returns: The updated portfolio
    func updatePortfolio(_ portfolio: Portfolio) async throws -> Portfolio

    /// Set a portfolio as the default
    /// - Parameter id: Portfolio identifier
    /// - Returns: The updated portfolio
    func setDefaultPortfolio(id: String) async throws -> Portfolio

    /// Delete a portfolio
    /// - Parameter id: Portfolio identifier
    func deletePortfolio(id: String) async throws

    // MARK: - Holdings Operations

    /// Fetch all holdings for a portfolio
    /// - Parameter portfolioId: Portfolio identifier
    /// - Returns: Array of holdings
    func fetchHoldings(for portfolioId: String) async throws -> [Holding]

    /// Fetch a specific holding
    /// - Parameters:
    ///   - holdingId: Holding identifier
    ///   - portfolioId: Portfolio identifier
    /// - Returns: The holding if found
    func fetchHolding(id holdingId: String, in portfolioId: String) async throws -> Holding

    /// Add a holding to a portfolio
    /// - Parameters:
    ///   - holding: Holding to add
    ///   - portfolioId: Portfolio identifier
    /// - Returns: The created holding
    func addHolding(_ holding: Holding, to portfolioId: String) async throws -> Holding

    /// Update a holding
    /// - Parameter holding: Holding with updated values
    /// - Returns: The updated holding
    func updateHolding(_ holding: Holding) async throws -> Holding

    /// Remove a holding from a portfolio
    /// - Parameters:
    ///   - holdingId: Holding identifier
    ///   - portfolioId: Portfolio identifier
    func removeHolding(id holdingId: String, from portfolioId: String) async throws

    /// Update holding prices from market data
    /// - Parameter portfolioId: Portfolio identifier
    /// - Returns: Array of updated holdings
    func refreshHoldingPrices(for portfolioId: String) async throws -> [Holding]

    // MARK: - Performance Operations

    /// Fetch portfolio performance for a period
    /// - Parameters:
    ///   - portfolioId: Portfolio identifier
    ///   - period: Performance period
    /// - Returns: Performance data
    func fetchPerformance(for portfolioId: String, period: PerformancePeriod) async throws -> PortfolioPerformance

    /// Fetch combined performance for all portfolios
    /// - Parameter period: Performance period
    /// - Returns: Combined performance data
    func fetchCombinedPerformance(period: PerformancePeriod) async throws -> PortfolioPerformance

    // MARK: - Allocation Operations

    /// Fetch allocation breakdown for a portfolio
    /// - Parameters:
    ///   - portfolioId: Portfolio identifier
    ///   - groupBy: How to group allocations (sector, asset type, etc.)
    /// - Returns: Allocation data
    func fetchAllocation(for portfolioId: String, groupBy: AllocationGrouping) async throws -> PortfolioAllocation

    /// Fetch combined allocation for all portfolios
    /// - Parameter groupBy: How to group allocations
    /// - Returns: Combined allocation data
    func fetchCombinedAllocation(groupBy: AllocationGrouping) async throws -> PortfolioAllocation

    // MARK: - Ledger Operations

    /// Fetch ledger entries for a portfolio
    /// - Parameters:
    ///   - portfolioId: Portfolio identifier
    ///   - page: Page number (1-indexed)
    ///   - limit: Number of items per page
    /// - Returns: Paginated ledger entries
    func fetchLedgerEntries(for portfolioId: String, page: Int, limit: Int) async throws -> PaginatedResponse<LedgerEntry>

    /// Fetch ledger entries filtered by type
    /// - Parameters:
    ///   - portfolioId: Portfolio identifier
    ///   - types: Types of entries to fetch
    /// - Returns: Array of ledger entries
    func fetchLedgerEntries(for portfolioId: String, types: [LedgerEntryType]) async throws -> [LedgerEntry]

    /// Fetch ledger entries for a date range
    /// - Parameters:
    ///   - portfolioId: Portfolio identifier
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Array of ledger entries
    func fetchLedgerEntries(for portfolioId: String, from startDate: Date, to endDate: Date) async throws -> [LedgerEntry]

    /// Add a ledger entry
    /// - Parameters:
    ///   - entry: Ledger entry to add
    ///   - portfolioId: Portfolio identifier
    /// - Returns: The created ledger entry
    func addLedgerEntry(_ entry: LedgerEntry, to portfolioId: String) async throws -> LedgerEntry

    /// Update a ledger entry
    /// - Parameter entry: Ledger entry with updated values
    /// - Returns: The updated ledger entry
    func updateLedgerEntry(_ entry: LedgerEntry) async throws -> LedgerEntry

    /// Delete a ledger entry
    /// - Parameters:
    ///   - entryId: Ledger entry identifier
    ///   - portfolioId: Portfolio identifier
    func deleteLedgerEntry(id entryId: String, from portfolioId: String) async throws

    // MARK: - Cost Basis Operations

    /// Fetch cost basis for a specific symbol
    /// - Parameter symbol: Stock symbol
    /// - Returns: Cost basis summary including lots and P&L
    func getCostBasis(symbol: String) async throws -> CostBasisSummary

    // MARK: - Cash Operations

    /// Deposit cash into a portfolio
    /// - Parameters:
    ///   - amount: Amount to deposit
    ///   - portfolioId: Portfolio identifier
    ///   - notes: Optional notes
    /// - Returns: The created ledger entry
    func depositCash(amount: Decimal, to portfolioId: String, notes: String?) async throws -> LedgerEntry

    /// Withdraw cash from a portfolio
    /// - Parameters:
    ///   - amount: Amount to withdraw
    ///   - portfolioId: Portfolio identifier
    ///   - notes: Optional notes
    /// - Returns: The created ledger entry
    func withdrawCash(amount: Decimal, from portfolioId: String, notes: String?) async throws -> LedgerEntry

    /// Transfer cash between portfolios
    /// - Parameters:
    ///   - amount: Amount to transfer
    ///   - sourcePortfolioId: Source portfolio identifier
    ///   - destinationPortfolioId: Destination portfolio identifier
    ///   - notes: Optional notes
    func transferCash(amount: Decimal, from sourcePortfolioId: String, to destinationPortfolioId: String, notes: String?) async throws

    // MARK: - Summary Operations

    /// Get summary for all portfolios
    /// - Returns: Portfolios summary
    func fetchPortfoliosSummary() async throws -> PortfoliosSummary

    /// Get holdings summary for a portfolio
    /// - Parameter portfolioId: Portfolio identifier
    /// - Returns: Holdings summary
    func fetchHoldingsSummary(for portfolioId: String) async throws -> HoldingsSummary

    /// Get ledger summary for a portfolio
    /// - Parameter portfolioId: Portfolio identifier
    /// - Returns: Ledger summary
    func fetchLedgerSummary(for portfolioId: String) async throws -> LedgerSummary

    // MARK: - Cache Operations

    /// Invalidate cached portfolio data
    func invalidateCache() async

    /// Invalidate cached data for a specific portfolio
    /// - Parameter portfolioId: Portfolio identifier
    func invalidateCache(for portfolioId: String) async

    /// Prefetch portfolio data for offline access
    func prefetchPortfolios() async throws
}

// MARK: - Allocation Grouping

/// Ways to group portfolio allocations
enum AllocationGrouping: String, Sendable {
    case sector
    case assetType
    case industry
    case holding
}

// MARK: - Default Implementations

extension PortfolioRepositoryProtocol {
    func fetchLedgerEntries(for portfolioId: String, page: Int = 1, limit: Int = Constants.API.defaultPageSize) async throws -> PaginatedResponse<LedgerEntry> {
        try await fetchLedgerEntries(for: portfolioId, page: page, limit: limit)
    }
}

// MARK: - Portfolio Repository Error

/// Errors specific to portfolio operations
enum PortfolioRepositoryError: LocalizedError {
    case portfolioNotFound(id: String)
    case holdingNotFound(id: String)
    case ledgerEntryNotFound(id: String)
    case insufficientCash
    case insufficientShares
    case invalidPortfolioData
    case invalidHoldingData
    case invalidLedgerEntry
    case cannotDeleteDefaultPortfolio
    case cannotDeletePortfolioWithHoldings
    case duplicateHolding(symbol: String)

    var errorDescription: String? {
        switch self {
        case .portfolioNotFound(let id):
            return "Portfolio with ID '\(id)' was not found"
        case .holdingNotFound(let id):
            return "Holding with ID '\(id)' was not found"
        case .ledgerEntryNotFound(let id):
            return "Ledger entry with ID '\(id)' was not found"
        case .insufficientCash:
            return "Insufficient cash balance for this transaction"
        case .insufficientShares:
            return "Insufficient shares for this transaction"
        case .invalidPortfolioData:
            return "The portfolio data is invalid"
        case .invalidHoldingData:
            return "The holding data is invalid"
        case .invalidLedgerEntry:
            return "The ledger entry data is invalid"
        case .cannotDeleteDefaultPortfolio:
            return "Cannot delete the default portfolio. Set another portfolio as default first."
        case .cannotDeletePortfolioWithHoldings:
            return "Cannot delete a portfolio with existing holdings. Remove holdings first."
        case .duplicateHolding(let symbol):
            return "A holding for '\(symbol)' already exists in this portfolio"
        }
    }
}
