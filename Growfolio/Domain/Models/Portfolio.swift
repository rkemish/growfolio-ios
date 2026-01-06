//
//  Portfolio.swift
//  Growfolio
//
//  Investment portfolio domain model.
//

import Foundation

/// Represents an investment portfolio
struct Portfolio: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// User ID who owns this portfolio
    let userId: String

    /// Portfolio name
    var name: String

    /// Portfolio description
    var description: String?

    /// Portfolio type
    var type: PortfolioType

    /// Currency code for the portfolio
    var currencyCode: String

    /// Total market value of all holdings
    var totalValue: Decimal

    /// Total cost basis of all holdings
    var totalCostBasis: Decimal

    /// Cash balance available in the portfolio
    var cashBalance: Decimal

    /// Date of the last valuation
    var lastValuationDate: Date?

    /// Whether this is the default portfolio
    var isDefault: Bool

    /// Color for display (hex string)
    var colorHex: String

    /// Icon name (SF Symbol)
    var iconName: String

    /// Date when the portfolio was created
    let createdAt: Date

    /// Date when the portfolio was last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        description: String? = nil,
        type: PortfolioType = .personal,
        currencyCode: String = "USD",
        totalValue: Decimal = 0,
        totalCostBasis: Decimal = 0,
        cashBalance: Decimal = 0,
        lastValuationDate: Date? = nil,
        isDefault: Bool = false,
        colorHex: String = "#007AFF",
        iconName: String = "briefcase.fill",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.type = type
        self.currencyCode = currencyCode
        self.totalValue = totalValue
        self.totalCostBasis = totalCostBasis
        self.cashBalance = cashBalance
        self.lastValuationDate = lastValuationDate
        self.isDefault = isDefault
        self.colorHex = colorHex
        self.iconName = iconName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Total return in currency
    var totalReturn: Decimal {
        totalValue - totalCostBasis
    }

    /// Total return percentage
    var totalReturnPercentage: Decimal {
        guard totalCostBasis > 0 else { return 0 }
        return ((totalValue - totalCostBasis) / totalCostBasis) * 100
    }

    /// Whether the portfolio is profitable
    var isProfitable: Bool {
        totalReturn > 0
    }

    /// Total assets including cash
    var totalAssets: Decimal {
        totalValue + cashBalance
    }

    /// Percentage of portfolio in cash
    var cashPercentage: Decimal {
        guard totalAssets > 0 else { return 0 }
        return (cashBalance / totalAssets) * 100
    }

    /// Percentage of portfolio invested
    var investedPercentage: Decimal {
        guard totalAssets > 0 else { return 0 }
        return (totalValue / totalAssets) * 100
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case description
        case type
        case currencyCode
        case totalValue
        case totalCostBasis
        case cashBalance
        case lastValuationDate
        case isDefault
        case colorHex
        case iconName
        case createdAt
        case updatedAt
    }
}

// MARK: - Portfolio Type

/// Types of investment portfolios
enum PortfolioType: String, Codable, Sendable, CaseIterable {
    case personal
    case retirement
    case education
    case brokerage
    case ira
    case roth
    case hsa
    case trust
    case joint
    case custodial
    case other

    var displayName: String {
        switch self {
        case .personal:
            return "Personal"
        case .retirement:
            return "Retirement"
        case .education:
            return "Education"
        case .brokerage:
            return "Brokerage"
        case .ira:
            return "Traditional IRA"
        case .roth:
            return "Roth IRA"
        case .hsa:
            return "HSA"
        case .trust:
            return "Trust"
        case .joint:
            return "Joint"
        case .custodial:
            return "Custodial"
        case .other:
            return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .personal:
            return "person.fill"
        case .retirement:
            return "sun.horizon.fill"
        case .education:
            return "graduationcap.fill"
        case .brokerage:
            return "chart.line.uptrend.xyaxis"
        case .ira, .roth:
            return "building.columns.fill"
        case .hsa:
            return "cross.case.fill"
        case .trust:
            return "shield.fill"
        case .joint:
            return "person.2.fill"
        case .custodial:
            return "figure.and.child.holdinghands"
        case .other:
            return "briefcase.fill"
        }
    }

    var isTaxAdvantaged: Bool {
        switch self {
        case .retirement, .ira, .roth, .hsa, .education:
            return true
        default:
            return false
        }
    }
}

// MARK: - Portfolio Performance

/// Performance metrics for a portfolio
struct PortfolioPerformance: Codable, Sendable, Equatable {
    let portfolioId: String
    let period: PerformancePeriod
    let startValue: Decimal
    let endValue: Decimal
    let absoluteReturn: Decimal
    let percentageReturn: Decimal
    let annualizedReturn: Decimal?
    let benchmarkReturn: Decimal?
    let alpha: Decimal?
    let dataPoints: [PerformanceDataPoint]
    let calculatedAt: Date

    var outperformsBenchmark: Bool {
        guard let benchmark = benchmarkReturn else { return false }
        return percentageReturn > benchmark
    }

    init(
        portfolioId: String,
        period: PerformancePeriod,
        startValue: Decimal,
        endValue: Decimal,
        absoluteReturn: Decimal,
        percentageReturn: Decimal,
        annualizedReturn: Decimal? = nil,
        benchmarkReturn: Decimal? = nil,
        alpha: Decimal? = nil,
        dataPoints: [PerformanceDataPoint] = [],
        calculatedAt: Date = Date()
    ) {
        self.portfolioId = portfolioId
        self.period = period
        self.startValue = startValue
        self.endValue = endValue
        self.absoluteReturn = absoluteReturn
        self.percentageReturn = percentageReturn
        self.annualizedReturn = annualizedReturn
        self.benchmarkReturn = benchmarkReturn
        self.alpha = alpha
        self.dataPoints = dataPoints
        self.calculatedAt = calculatedAt
    }
}

/// A single data point for performance charts
struct PerformanceDataPoint: Codable, Sendable, Equatable, Identifiable {
    var id: Date { date }
    let date: Date
    let value: Decimal
    let cumulativeReturn: Decimal?

    init(
        date: Date,
        value: Decimal,
        cumulativeReturn: Decimal? = nil
    ) {
        self.date = date
        self.value = value
        self.cumulativeReturn = cumulativeReturn
    }
}

// MARK: - Portfolio Allocation

/// Allocation breakdown for a portfolio
struct PortfolioAllocation: Codable, Sendable, Equatable {
    let portfolioId: String
    let allocations: [AllocationItem]
    let calculatedAt: Date

    init(
        portfolioId: String,
        allocations: [AllocationItem],
        calculatedAt: Date = Date()
    ) {
        self.portfolioId = portfolioId
        self.allocations = allocations
        self.calculatedAt = calculatedAt
    }
}

/// A single allocation item
struct AllocationItem: Codable, Sendable, Equatable, Identifiable {
    var id: String { category }
    let category: String
    let value: Decimal
    let percentage: Decimal
    let colorHex: String

    init(
        category: String,
        value: Decimal,
        percentage: Decimal,
        colorHex: String
    ) {
        self.category = category
        self.value = value
        self.percentage = percentage
        self.colorHex = colorHex
    }
}

// MARK: - Portfolio Summary

/// Summary of all portfolios
struct PortfoliosSummary: Sendable {
    let totalPortfolios: Int
    let totalValue: Decimal
    let totalCostBasis: Decimal
    let totalCashBalance: Decimal
    let totalReturn: Decimal
    let totalReturnPercentage: Decimal

    init(portfolios: [Portfolio]) {
        self.totalPortfolios = portfolios.count
        self.totalValue = portfolios.reduce(0) { $0 + $1.totalValue }
        self.totalCostBasis = portfolios.reduce(0) { $0 + $1.totalCostBasis }
        self.totalCashBalance = portfolios.reduce(0) { $0 + $1.cashBalance }
        self.totalReturn = totalValue - totalCostBasis
        self.totalReturnPercentage = totalCostBasis > 0
            ? ((totalValue - totalCostBasis) / totalCostBasis) * 100
            : 0
    }
}
