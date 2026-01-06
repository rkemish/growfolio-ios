//
//  Stock.swift
//  Growfolio
//
//  Stock domain model for market data.
//

import Foundation

/// Represents a stock/security
struct Stock: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Stock symbol (ticker)
    let symbol: String

    /// Company/security name
    var name: String

    /// Exchange where the stock is listed
    var exchange: String?

    /// Asset type
    var assetType: AssetType

    /// Current price
    var currentPrice: Decimal?

    /// Price change from previous close
    var priceChange: Decimal?

    /// Price change percentage
    var priceChangePercent: Decimal?

    /// Previous closing price
    var previousClose: Decimal?

    /// Today's opening price
    var openPrice: Decimal?

    /// Today's high price
    var dayHigh: Decimal?

    /// Today's low price
    var dayLow: Decimal?

    /// 52-week high
    var weekHigh52: Decimal?

    /// 52-week low
    var weekLow52: Decimal?

    /// Trading volume
    var volume: Int?

    /// Average trading volume
    var averageVolume: Int?

    /// Market capitalization
    var marketCap: Decimal?

    /// Price-to-earnings ratio
    var peRatio: Decimal?

    /// Dividend yield percentage
    var dividendYield: Decimal?

    /// Earnings per share
    var eps: Decimal?

    /// Beta (volatility measure)
    var beta: Decimal?

    /// Sector
    var sector: String?

    /// Industry
    var industry: String?

    /// Company description
    var companyDescription: String?

    /// Company website URL
    var websiteURL: URL?

    /// Logo URL
    var logoURL: URL?

    /// Currency code for prices
    var currencyCode: String

    /// Date when the data was last updated
    var lastUpdated: Date?

    // MARK: - Identifiable

    var id: String { symbol }

    // MARK: - Initialization

    init(
        symbol: String,
        name: String,
        exchange: String? = nil,
        assetType: AssetType = .stock,
        currentPrice: Decimal? = nil,
        priceChange: Decimal? = nil,
        priceChangePercent: Decimal? = nil,
        previousClose: Decimal? = nil,
        openPrice: Decimal? = nil,
        dayHigh: Decimal? = nil,
        dayLow: Decimal? = nil,
        weekHigh52: Decimal? = nil,
        weekLow52: Decimal? = nil,
        volume: Int? = nil,
        averageVolume: Int? = nil,
        marketCap: Decimal? = nil,
        peRatio: Decimal? = nil,
        dividendYield: Decimal? = nil,
        eps: Decimal? = nil,
        beta: Decimal? = nil,
        sector: String? = nil,
        industry: String? = nil,
        companyDescription: String? = nil,
        websiteURL: URL? = nil,
        logoURL: URL? = nil,
        currencyCode: String = "USD",
        lastUpdated: Date? = nil
    ) {
        self.symbol = symbol
        self.name = name
        self.exchange = exchange
        self.assetType = assetType
        self.currentPrice = currentPrice
        self.priceChange = priceChange
        self.priceChangePercent = priceChangePercent
        self.previousClose = previousClose
        self.openPrice = openPrice
        self.dayHigh = dayHigh
        self.dayLow = dayLow
        self.weekHigh52 = weekHigh52
        self.weekLow52 = weekLow52
        self.volume = volume
        self.averageVolume = averageVolume
        self.marketCap = marketCap
        self.peRatio = peRatio
        self.dividendYield = dividendYield
        self.eps = eps
        self.beta = beta
        self.sector = sector
        self.industry = industry
        self.companyDescription = companyDescription
        self.websiteURL = websiteURL
        self.logoURL = logoURL
        self.currencyCode = currencyCode
        self.lastUpdated = lastUpdated
    }

    // MARK: - Computed Properties

    /// Display name with symbol
    var displayName: String {
        "\(name) (\(symbol))"
    }

    /// Whether the price has increased today
    var isPriceUp: Bool {
        (priceChange ?? 0) > 0
    }

    /// Whether the price has decreased today
    var isPriceDown: Bool {
        (priceChange ?? 0) < 0
    }

    /// Day's trading range
    var dayRange: String? {
        guard let low = dayLow, let high = dayHigh else { return nil }
        return "\(low.currencyString) - \(high.currencyString)"
    }

    /// 52-week trading range
    var weekRange52: String? {
        guard let low = weekLow52, let high = weekHigh52 else { return nil }
        return "\(low.currencyString) - \(high.currencyString)"
    }

    /// Formatted market cap
    var formattedMarketCap: String? {
        marketCap?.compactCurrencyString
    }

    /// Formatted volume
    var formattedVolume: String? {
        guard let vol = volume else { return nil }
        return formatLargeNumber(vol)
    }

    /// Distance from 52-week high (percentage)
    var distanceFrom52WeekHigh: Decimal? {
        guard let current = currentPrice, let high = weekHigh52, high > 0 else { return nil }
        return ((high - current) / high) * 100
    }

    /// Distance from 52-week low (percentage)
    var distanceFrom52WeekLow: Decimal? {
        guard let current = currentPrice, let low = weekLow52, low > 0 else { return nil }
        return ((current - low) / low) * 100
    }

    /// Whether the stock pays dividends
    var paysDividends: Bool {
        (dividendYield ?? 0) > 0
    }

    // MARK: - Private Methods

    private func formatLargeNumber(_ number: Int) -> String {
        let absNumber = abs(number)
        let sign = number < 0 ? "-" : ""

        if absNumber >= 1_000_000_000 {
            let value = Double(absNumber) / 1_000_000_000
            return "\(sign)\(String(format: "%.2f", value))B"
        } else if absNumber >= 1_000_000 {
            let value = Double(absNumber) / 1_000_000
            return "\(sign)\(String(format: "%.2f", value))M"
        } else if absNumber >= 1_000 {
            let value = Double(absNumber) / 1_000
            return "\(sign)\(String(format: "%.2f", value))K"
        } else {
            return "\(sign)\(absNumber)"
        }
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case symbol
        case name
        case exchange
        case assetType
        case currentPrice
        case priceChange
        case priceChangePercent
        case previousClose
        case openPrice
        case dayHigh
        case dayLow
        case weekHigh52
        case weekLow52
        case volume
        case averageVolume
        case marketCap
        case peRatio
        case dividendYield
        case eps
        case beta
        case sector
        case industry
        case companyDescription
        case websiteURL = "websiteUrl"
        case logoURL = "logoUrl"
        case currencyCode
        case lastUpdated
    }
}

// MARK: - Stock Quote

/// Real-time quote data for a stock
struct StockQuote: Codable, Sendable, Equatable {
    let symbol: String
    let price: Decimal
    let change: Decimal
    let changePercent: Decimal
    let volume: Int
    let timestamp: Date

    var isPriceUp: Bool {
        change > 0
    }

    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(change.currencyString)"
    }

    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(changePercent.rounded(places: 2))%"
    }
}

// MARK: - Stock History

/// Historical price data for a stock
struct StockHistory: Codable, Sendable {
    let symbol: String
    let period: HistoryPeriod
    let dataPoints: [StockHistoryDataPoint]

    var startPrice: Decimal? {
        dataPoints.first?.close
    }

    var endPrice: Decimal? {
        dataPoints.last?.close
    }

    var periodReturn: Decimal? {
        guard let start = startPrice, let end = endPrice, start > 0 else { return nil }
        return ((end - start) / start) * 100
    }

    var highestPrice: Decimal? {
        dataPoints.map(\.high).max()
    }

    var lowestPrice: Decimal? {
        dataPoints.map(\.low).min()
    }
}

/// A single data point in stock history
struct StockHistoryDataPoint: Identifiable, Codable, Sendable, Equatable {
    var id: Date { date }
    let date: Date
    let open: Decimal
    let high: Decimal
    let low: Decimal
    let close: Decimal
    let volume: Int

    var range: Decimal {
        high - low
    }

    var changeFromOpen: Decimal {
        close - open
    }

    var changeFromOpenPercent: Decimal {
        guard open > 0 else { return 0 }
        return ((close - open) / open) * 100
    }
}

// MARK: - Stock Search Result

/// Search result for stock lookup
struct StockSearchResult: Identifiable, Codable, Sendable, Equatable, Hashable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let exchange: String?
    let assetType: AssetType
    let currencyCode: String?

    var displayName: String {
        if let exchange = exchange {
            return "\(symbol) - \(name) (\(exchange))"
        }
        return "\(symbol) - \(name)"
    }
}

// MARK: - Watchlist

/// User's stock watchlist
struct Watchlist: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let userId: String
    var name: String
    var symbols: [String]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String = "Watchlist",
        symbols: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.symbols = symbols
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    mutating func addSymbol(_ symbol: String) {
        guard !symbols.contains(symbol) else { return }
        symbols.append(symbol)
        updatedAt = Date()
    }

    mutating func removeSymbol(_ symbol: String) {
        symbols.removeAll { $0 == symbol }
        updatedAt = Date()
    }

    func contains(_ symbol: String) -> Bool {
        symbols.contains(symbol)
    }
}

// MARK: - Market Hours

/// Market session type
enum MarketSession: String, Codable, Sendable {
    case pre = "pre"
    case regular = "regular"
    case after = "after"
    case closed = "closed"

    var displayName: String {
        switch self {
        case .pre:
            return "Pre-Market"
        case .regular:
            return "Regular Hours"
        case .after:
            return "After Hours"
        case .closed:
            return "Closed"
        }
    }
}

/// Trading hours information
struct MarketHours: Codable, Sendable {
    let exchange: String
    let isOpen: Bool
    let session: MarketSession
    let nextOpen: Date?
    let nextClose: Date?
    let timestamp: Date?

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case exchange
        case isOpen
        case session
        case nextOpen
        case nextClose
        case timestamp
    }

    // MARK: - Initialization

    init(
        exchange: String,
        isOpen: Bool,
        session: MarketSession,
        nextOpen: Date? = nil,
        nextClose: Date? = nil,
        timestamp: Date? = nil
    ) {
        self.exchange = exchange
        self.isOpen = isOpen
        self.session = session
        self.nextOpen = nextOpen
        self.nextClose = nextClose
        self.timestamp = timestamp
    }

    // MARK: - Computed Properties

    var statusText: String {
        if isOpen {
            return "Market Open"
        } else if let nextOpen = nextOpen {
            return "Opens \(nextOpen.relativeString)"
        } else {
            return "Market Closed"
        }
    }

    var shortStatusText: String {
        isOpen ? "Open" : "Closed"
    }

    var sessionStatusText: String {
        switch session {
        case .pre:
            return "Pre-Market Trading"
        case .regular:
            return "Market Open"
        case .after:
            return "After Hours Trading"
        case .closed:
            if let nextOpen = nextOpen {
                return "Opens \(nextOpen.relativeString)"
            }
            return "Market Closed"
        }
    }

    var nextEventTime: Date? {
        isOpen ? nextClose : nextOpen
    }

    var nextEventLabel: String {
        if isOpen {
            if let close = nextClose {
                return "Closes \(close.relativeString)"
            }
            return ""
        } else {
            if let open = nextOpen {
                return "Opens \(open.relativeString)"
            }
            return ""
        }
    }

    /// Returns true if in extended hours (pre-market or after-hours)
    var isExtendedHours: Bool {
        session == .pre || session == .after
    }

    /// Static fallback for when API is unavailable
    static func fallback() -> MarketHours {
        let calendar = Calendar.current
        let now = Date()

        // Create a timezone for New York
        let nyTimeZone = TimeZone(identifier: "America/New_York") ?? TimeZone.current
        var nyCalendar = Calendar.current
        nyCalendar.timeZone = nyTimeZone

        let hour = nyCalendar.component(.hour, from: now)
        let minute = nyCalendar.component(.minute, from: now)
        let weekday = nyCalendar.component(.weekday, from: now)

        // Check if weekend
        let isWeekend = weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7

        // Market hours: 9:30 AM - 4:00 PM ET
        let currentMinutes = hour * 60 + minute
        let marketOpen = 9 * 60 + 30  // 9:30 AM
        let marketClose = 16 * 60     // 4:00 PM
        let preMarketOpen = 4 * 60    // 4:00 AM
        let afterHoursClose = 20 * 60 // 8:00 PM

        let session: MarketSession
        let isOpen: Bool

        if isWeekend {
            session = .closed
            isOpen = false
        } else if currentMinutes >= marketOpen && currentMinutes < marketClose {
            session = .regular
            isOpen = true
        } else if currentMinutes >= preMarketOpen && currentMinutes < marketOpen {
            session = .pre
            isOpen = false // Pre-market doesn't count as "open" for most purposes
        } else if currentMinutes >= marketClose && currentMinutes < afterHoursClose {
            session = .after
            isOpen = false // After-hours doesn't count as "open" for most purposes
        } else {
            session = .closed
            isOpen = false
        }

        return MarketHours(
            exchange: "NYSE",
            isOpen: isOpen,
            session: session,
            nextOpen: nil,
            nextClose: nil,
            timestamp: now
        )
    }
}

// MARK: - Stock Order

/// Represents a submitted stock order
struct StockOrder: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let symbol: String
    let side: OrderSide
    let type: OrderType
    let status: OrderStatus
    let notional: Decimal?
    let quantity: Decimal?
    let filledQuantity: Decimal?
    let filledAvgPrice: Decimal?
    let submittedAt: Date
    let filledAt: Date?
    let cancelledAt: Date?
    let expiredAt: Date?
    let clientOrderId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case side
        case type
        case status
        case notional
        case quantity = "qty"
        case filledQuantity = "filledQty"
        case filledAvgPrice
        case submittedAt
        case filledAt
        case cancelledAt
        case expiredAt
        case clientOrderId
    }
}

/// Order side (buy/sell)
enum OrderSide: String, Codable, Sendable {
    case buy
    case sell
}

/// Order type
enum OrderType: String, Codable, Sendable {
    case market
    case limit
    case stop
    case stopLimit = "stop_limit"
}

/// Order status
enum OrderStatus: String, Codable, Sendable {
    case new
    case accepted
    case pendingNew = "pending_new"
    case acceptedForBidding = "accepted_for_bidding"
    case filled
    case partiallyFilled = "partially_filled"
    case cancelled = "canceled"
    case expired
    case rejected
    case pendingCancel = "pending_cancel"
    case pendingReplace = "pending_replace"
    case stopped
    case suspended
    case calculated

    var displayName: String {
        switch self {
        case .new, .accepted, .pendingNew, .acceptedForBidding:
            return "Pending"
        case .filled:
            return "Filled"
        case .partiallyFilled:
            return "Partially Filled"
        case .cancelled:
            return "Cancelled"
        case .expired:
            return "Expired"
        case .rejected:
            return "Rejected"
        case .pendingCancel:
            return "Cancelling"
        case .pendingReplace:
            return "Modifying"
        case .stopped, .suspended:
            return "Halted"
        case .calculated:
            return "Calculating"
        }
    }

    var isActive: Bool {
        switch self {
        case .new, .accepted, .pendingNew, .acceptedForBidding, .partiallyFilled, .pendingCancel, .pendingReplace:
            return true
        default:
            return false
        }
    }

    var isComplete: Bool {
        switch self {
        case .filled:
            return true
        default:
            return false
        }
    }
}
