//
//  MockStockDataProvider.swift
//  Growfolio
//
//  Provides realistic stock data for mock implementations.
//

import Foundation

/// Stock profile for mock data generation
struct MockStockProfile: Sendable {
    let symbol: String
    let name: String
    let sector: String
    let industry: String
    let basePrice: Decimal
    let volatility: Double
    let assetType: AssetType
    let marketCap: Decimal?
    let peRatio: Decimal?
    let dividendYield: Decimal?
    let description: String

    init(
        symbol: String,
        name: String,
        sector: String,
        industry: String,
        basePrice: Decimal,
        volatility: Double = 0.02,
        assetType: AssetType = .stock,
        marketCap: Decimal? = nil,
        peRatio: Decimal? = nil,
        dividendYield: Decimal? = nil,
        description: String = ""
    ) {
        self.symbol = symbol
        self.name = name
        self.sector = sector
        self.industry = industry
        self.basePrice = basePrice
        self.volatility = volatility
        self.assetType = assetType
        self.marketCap = marketCap
        self.peRatio = peRatio
        self.dividendYield = dividendYield
        self.description = description
    }
}

/// Provides realistic stock data for mock implementations
enum MockStockDataProvider {

    // MARK: - Stock Profiles

    /// Well-known stock profiles with realistic data
    static let stockProfiles: [String: MockStockProfile] = [
        // Tech Giants
        "AAPL": MockStockProfile(
            symbol: "AAPL", name: "Apple Inc.", sector: "Technology",
            industry: "Consumer Electronics", basePrice: 178,
            volatility: 0.02, marketCap: 2800000000000, peRatio: 28.5, dividendYield: 0.5,
            description: "Apple designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide."
        ),
        "MSFT": MockStockProfile(
            symbol: "MSFT", name: "Microsoft Corporation", sector: "Technology",
            industry: "Software - Infrastructure", basePrice: 380,
            volatility: 0.018, marketCap: 2700000000000, peRatio: 35.2, dividendYield: 0.8,
            description: "Microsoft develops and licenses consumer and enterprise software, and manufactures electronic devices."
        ),
        "GOOGL": MockStockProfile(
            symbol: "GOOGL", name: "Alphabet Inc.", sector: "Technology",
            industry: "Internet Content & Information", basePrice: 142,
            volatility: 0.022, marketCap: 1800000000000, peRatio: 25.3,
            description: "Alphabet provides online advertising services and operates Google Search, YouTube, Google Cloud, and other platforms."
        ),
        "AMZN": MockStockProfile(
            symbol: "AMZN", name: "Amazon.com Inc.", sector: "Consumer Cyclical",
            industry: "Internet Retail", basePrice: 178,
            volatility: 0.025, marketCap: 1850000000000, peRatio: 62.5,
            description: "Amazon engages in the retail sale of consumer products and subscriptions, and operates AWS cloud services."
        ),
        "NVDA": MockStockProfile(
            symbol: "NVDA", name: "NVIDIA Corporation", sector: "Technology",
            industry: "Semiconductors", basePrice: 485,
            volatility: 0.035, marketCap: 1200000000000, peRatio: 65.8,
            description: "NVIDIA designs and manufactures graphics processing units for gaming, professional visualization, and data centers."
        ),
        "META": MockStockProfile(
            symbol: "META", name: "Meta Platforms Inc.", sector: "Technology",
            industry: "Internet Content & Information", basePrice: 505,
            volatility: 0.028, marketCap: 1300000000000, peRatio: 28.9, dividendYield: 0.4,
            description: "Meta operates social networking platforms including Facebook, Instagram, and WhatsApp."
        ),
        "TSLA": MockStockProfile(
            symbol: "TSLA", name: "Tesla Inc.", sector: "Consumer Cyclical",
            industry: "Auto Manufacturers", basePrice: 248,
            volatility: 0.04, marketCap: 780000000000, peRatio: 72.5,
            description: "Tesla designs, manufactures, and sells electric vehicles, energy storage systems, and solar products."
        ),
        "AMD": MockStockProfile(
            symbol: "AMD", name: "Advanced Micro Devices", sector: "Technology",
            industry: "Semiconductors", basePrice: 155,
            volatility: 0.032, marketCap: 250000000000, peRatio: 45.2,
            description: "AMD designs and manufactures microprocessors and graphics technologies for computing and gaming."
        ),

        // Financials
        "JPM": MockStockProfile(
            symbol: "JPM", name: "JPMorgan Chase & Co.", sector: "Financial Services",
            industry: "Banks - Diversified", basePrice: 195,
            volatility: 0.018, marketCap: 560000000000, peRatio: 11.5, dividendYield: 2.3,
            description: "JPMorgan Chase is a leading global financial services firm and one of the largest banking institutions."
        ),
        "V": MockStockProfile(
            symbol: "V", name: "Visa Inc.", sector: "Financial Services",
            industry: "Credit Services", basePrice: 275,
            volatility: 0.015, marketCap: 560000000000, peRatio: 30.2, dividendYield: 0.75,
            description: "Visa operates as a payments technology company worldwide, facilitating digital payments."
        ),
        "MA": MockStockProfile(
            symbol: "MA", name: "Mastercard Incorporated", sector: "Financial Services",
            industry: "Credit Services", basePrice: 458,
            volatility: 0.016, marketCap: 420000000000, peRatio: 35.8, dividendYield: 0.55,
            description: "Mastercard is a technology company in the global payments industry connecting consumers, merchants, and financial institutions."
        ),
        "SQ": MockStockProfile(
            symbol: "SQ", name: "Block Inc.", sector: "Financial Services",
            industry: "Software - Infrastructure", basePrice: 72,
            volatility: 0.035, marketCap: 45000000000, peRatio: 85.2,
            description: "Block provides financial services and mobile payment solutions through Square, Cash App, and other platforms."
        ),
        "PYPL": MockStockProfile(
            symbol: "PYPL", name: "PayPal Holdings Inc.", sector: "Financial Services",
            industry: "Credit Services", basePrice: 68,
            volatility: 0.028, marketCap: 72000000000, peRatio: 18.5,
            description: "PayPal operates a technology platform enabling digital payments and financial services for consumers and merchants."
        ),

        // Healthcare
        "JNJ": MockStockProfile(
            symbol: "JNJ", name: "Johnson & Johnson", sector: "Healthcare",
            industry: "Drug Manufacturers", basePrice: 155,
            volatility: 0.012, marketCap: 380000000000, peRatio: 15.8, dividendYield: 3.0,
            description: "Johnson & Johnson researches, develops, manufactures, and sells health care products worldwide."
        ),
        "UNH": MockStockProfile(
            symbol: "UNH", name: "UnitedHealth Group", sector: "Healthcare",
            industry: "Healthcare Plans", basePrice: 525,
            volatility: 0.016, marketCap: 480000000000, peRatio: 22.5, dividendYield: 1.4,
            description: "UnitedHealth Group is a healthcare and insurance company operating through health benefits and services."
        ),
        "ISRG": MockStockProfile(
            symbol: "ISRG", name: "Intuitive Surgical Inc.", sector: "Healthcare",
            industry: "Medical Devices", basePrice: 385,
            volatility: 0.022, marketCap: 135000000000, peRatio: 68.5,
            description: "Intuitive Surgical designs, manufactures, and markets da Vinci surgical systems for minimally invasive robotic-assisted surgery."
        ),

        // Industrial/Robotics
        "HON": MockStockProfile(
            symbol: "HON", name: "Honeywell International Inc.", sector: "Industrials",
            industry: "Conglomerates", basePrice: 205,
            volatility: 0.015, marketCap: 135000000000, peRatio: 24.2, dividendYield: 2.1,
            description: "Honeywell operates as a diversified technology and manufacturing company with aerospace, building technologies, and safety solutions."
        ),
        "ROK": MockStockProfile(
            symbol: "ROK", name: "Rockwell Automation Inc.", sector: "Industrials",
            industry: "Specialty Industrial Machinery", basePrice: 285,
            volatility: 0.022, marketCap: 32000000000, peRatio: 28.5, dividendYield: 1.8,
            description: "Rockwell Automation provides industrial automation and digital transformation solutions for manufacturing."
        ),
        "TER": MockStockProfile(
            symbol: "TER", name: "Teradyne Inc.", sector: "Technology",
            industry: "Semiconductor Equipment", basePrice: 105,
            volatility: 0.028, marketCap: 16000000000, peRatio: 32.5, dividendYield: 0.4,
            description: "Teradyne designs and manufactures automatic test equipment and collaborative robots for various industries."
        ),

        // Consumer
        "KO": MockStockProfile(
            symbol: "KO", name: "The Coca-Cola Company", sector: "Consumer Defensive",
            industry: "Beverages - Non-Alcoholic", basePrice: 60,
            volatility: 0.01, marketCap: 260000000000, peRatio: 24.5, dividendYield: 3.1,
            description: "Coca-Cola manufactures, markets, and sells various nonalcoholic beverages worldwide."
        ),
        "DIS": MockStockProfile(
            symbol: "DIS", name: "The Walt Disney Company", sector: "Communication Services",
            industry: "Entertainment", basePrice: 112,
            volatility: 0.022, marketCap: 205000000000, peRatio: 72.8,
            description: "Disney operates as an entertainment company worldwide with theme parks, media networks, and streaming."
        ),
        "NFLX": MockStockProfile(
            symbol: "NFLX", name: "Netflix Inc.", sector: "Communication Services",
            industry: "Entertainment", basePrice: 625,
            volatility: 0.028, marketCap: 270000000000, peRatio: 45.2,
            description: "Netflix provides entertainment services, primarily streaming content globally."
        ),

        // Clean Energy
        "NEE": MockStockProfile(
            symbol: "NEE", name: "NextEra Energy Inc.", sector: "Utilities",
            industry: "Utilities - Renewable", basePrice: 72,
            volatility: 0.018, marketCap: 148000000000, peRatio: 22.5, dividendYield: 2.8,
            description: "NextEra Energy is a leading clean energy company generating electricity from wind, solar, and nuclear sources."
        ),
        "ENPH": MockStockProfile(
            symbol: "ENPH", name: "Enphase Energy Inc.", sector: "Technology",
            industry: "Solar", basePrice: 125,
            volatility: 0.045, marketCap: 17000000000, peRatio: 42.5,
            description: "Enphase Energy designs and manufactures solar microinverters, battery storage, and energy management technology."
        ),
        "FSLR": MockStockProfile(
            symbol: "FSLR", name: "First Solar Inc.", sector: "Technology",
            industry: "Solar", basePrice: 185,
            volatility: 0.038, marketCap: 20000000000, peRatio: 18.2,
            description: "First Solar manufactures solar panels and provides utility-scale photovoltaic power plant solutions."
        ),
        "PLUG": MockStockProfile(
            symbol: "PLUG", name: "Plug Power Inc.", sector: "Industrials",
            industry: "Specialty Industrial Machinery", basePrice: 3.50,
            volatility: 0.06, marketCap: 2500000000,
            description: "Plug Power provides hydrogen fuel cell solutions for material handling, stationary power, and on-road applications."
        ),

        // ETFs
        "VOO": MockStockProfile(
            symbol: "VOO", name: "Vanguard S&P 500 ETF", sector: "ETF",
            industry: "Index Fund", basePrice: 435,
            volatility: 0.01, assetType: .etf, dividendYield: 1.4,
            description: "The Vanguard S&P 500 ETF tracks the S&P 500 Index, providing broad U.S. large-cap stock exposure."
        ),
        "VTI": MockStockProfile(
            symbol: "VTI", name: "Vanguard Total Stock Market ETF", sector: "ETF",
            industry: "Index Fund", basePrice: 242,
            volatility: 0.01, assetType: .etf, dividendYield: 1.45,
            description: "The Vanguard Total Stock Market ETF tracks the entire U.S. stock market, including small, mid, and large-cap stocks."
        ),
        "QQQ": MockStockProfile(
            symbol: "QQQ", name: "Invesco QQQ Trust", sector: "ETF",
            industry: "Index Fund", basePrice: 425,
            volatility: 0.015, assetType: .etf, dividendYield: 0.55,
            description: "The Invesco QQQ Trust tracks the Nasdaq-100 Index, focusing on large-cap technology companies."
        ),
        "VXUS": MockStockProfile(
            symbol: "VXUS", name: "Vanguard Total International Stock ETF", sector: "ETF",
            industry: "Index Fund", basePrice: 58,
            volatility: 0.012, assetType: .etf, dividendYield: 3.2,
            description: "The Vanguard Total International Stock ETF provides exposure to stocks issued by companies located outside the U.S."
        ),
        "BND": MockStockProfile(
            symbol: "BND", name: "Vanguard Total Bond Market ETF", sector: "ETF",
            industry: "Bond Fund", basePrice: 72,
            volatility: 0.005, assetType: .etf, dividendYield: 3.8,
            description: "The Vanguard Total Bond Market ETF tracks the Bloomberg U.S. Aggregate Float Adjusted Index."
        ),
        "SCHD": MockStockProfile(
            symbol: "SCHD", name: "Schwab U.S. Dividend Equity ETF", sector: "ETF",
            industry: "Dividend Fund", basePrice: 78,
            volatility: 0.01, assetType: .etf, dividendYield: 3.5,
            description: "The Schwab U.S. Dividend Equity ETF tracks an index of high-dividend-yielding U.S. stocks."
        ),
    ]

    /// All available symbols
    static var allSymbols: [String] {
        Array(stockProfiles.keys).sorted()
    }

    /// Popular symbols for suggestions
    static let popularSymbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "VOO", "VTI", "QQQ", "TSLA", "META"]

    /// Watchlist symbols for demo
    static let watchlistSymbols = ["TSLA", "AMD", "META", "DIS", "NFLX"]

    // MARK: - Price Generation

    /// Generate current price with daily fluctuation
    static func currentPrice(for symbol: String) -> Decimal {
        guard let profile = stockProfiles[symbol] else {
            // Return a random price for unknown symbols
            return MockDataGenerator.decimal(min: 10, max: 500, precision: 2)
        }

        // Add daily fluctuation based on volatility
        let volatilityRange = NSDecimalNumber(decimal: profile.basePrice).doubleValue * profile.volatility
        let fluctuation = Double.random(in: -volatilityRange...volatilityRange)
        let price = NSDecimalNumber(decimal: profile.basePrice).doubleValue + fluctuation

        return Decimal(max(price, 0.01)).rounded(places: 2)
    }

    /// Generate a quote for a symbol
    static func quote(for symbol: String) -> StockQuote {
        let price = currentPrice(for: symbol)
        let profile = stockProfiles[symbol]
        let volatility = profile?.volatility ?? 0.02

        // Generate change based on volatility
        let changePercent = MockDataGenerator.decimal(
            min: Decimal(-volatility * 100),
            max: Decimal(volatility * 100),
            precision: 2
        )
        let change = (price * changePercent / 100).rounded(places: 2)
        let volume = Int.random(in: 1_000_000...50_000_000)

        return StockQuote(
            symbol: symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            volume: volume,
            timestamp: Date()
        )
    }

    /// Generate a full Stock model
    static func stock(for symbol: String) -> Stock {
        guard let profile = stockProfiles[symbol] else {
            return Stock(
                symbol: symbol,
                name: "Unknown Company",
                assetType: .stock,
                currentPrice: currentPrice(for: symbol),
                currencyCode: "USD"
            )
        }

        let price = currentPrice(for: symbol)
        let changePercent = MockDataGenerator.percentageChange(min: -3, max: 3)
        let change = (price * changePercent / 100).rounded(places: 2)

        return Stock(
            symbol: profile.symbol,
            name: profile.name,
            exchange: "NASDAQ",
            assetType: profile.assetType,
            currentPrice: price,
            priceChange: change,
            priceChangePercent: changePercent,
            previousClose: price - change,
            openPrice: price - MockDataGenerator.decimal(min: -2, max: 2),
            dayHigh: price + MockDataGenerator.decimal(min: 0, max: 5),
            dayLow: price - MockDataGenerator.decimal(min: 0, max: 5),
            weekHigh52: price * Decimal(1.2),
            weekLow52: price * Decimal(0.7),
            volume: Int.random(in: 1_000_000...50_000_000),
            averageVolume: Int.random(in: 5_000_000...30_000_000),
            marketCap: profile.marketCap,
            peRatio: profile.peRatio,
            dividendYield: profile.dividendYield,
            sector: profile.sector,
            industry: profile.industry,
            companyDescription: profile.description,
            currencyCode: "USD",
            lastUpdated: Date()
        )
    }

    /// Generate search results for a query
    static func searchResults(for query: String, limit: Int = 10) -> [StockSearchResult] {
        let lowercaseQuery = query.lowercased()

        return stockProfiles.values
            .filter { profile in
                profile.symbol.lowercased().contains(lowercaseQuery) ||
                profile.name.lowercased().contains(lowercaseQuery)
            }
            .prefix(limit)
            .map { profile in
                StockSearchResult(
                    symbol: profile.symbol,
                    name: profile.name,
                    exchange: "NASDAQ",
                    assetType: profile.assetType,
                    status: nil,
                    currencyCode: "USD"
                )
            }
    }

    /// Generate historical price data
    static func historicalPrices(for symbol: String, period: HistoryPeriod) -> [StockHistoryDataPoint] {
        let profile = stockProfiles[symbol]
        let basePrice = profile?.basePrice ?? 100
        let volatility = profile?.volatility ?? 0.02

        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        let intervalDays: Int

        switch period {
        case .oneWeek:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: endDate)!
            intervalDays = 1
        case .oneMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
            intervalDays = 1
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: endDate)!
            intervalDays = 1
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: endDate)!
            intervalDays = 2
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
            intervalDays = 3
        case .fiveYears:
            startDate = calendar.date(byAdding: .year, value: -5, to: endDate)!
            intervalDays = 7
        case .all:
            startDate = calendar.date(byAdding: .year, value: -10, to: endDate)!
            intervalDays = 14
        }

        var dataPoints: [StockHistoryDataPoint] = []
        var currentDate = startDate
        var currentPrice = NSDecimalNumber(decimal: basePrice).doubleValue * 0.85 // Start lower

        while currentDate <= endDate {
            // Random walk with slight upward bias
            let dailyReturn = Double.random(in: -volatility...volatility * 1.1)
            currentPrice = currentPrice * (1 + dailyReturn)
            currentPrice = max(currentPrice, 1.0)

            let open = Decimal(currentPrice * Double.random(in: 0.99...1.01))
            let close = Decimal(currentPrice)
            let high = max(open, close) * Decimal(Double.random(in: 1.0...1.02))
            let low = min(open, close) * Decimal(Double.random(in: 0.98...1.0))

            dataPoints.append(StockHistoryDataPoint(
                date: currentDate,
                open: open.rounded(places: 2),
                high: high.rounded(places: 2),
                low: low.rounded(places: 2),
                close: close.rounded(places: 2),
                volume: Int.random(in: 1_000_000...50_000_000)
            ))

            currentDate = calendar.date(byAdding: .day, value: intervalDays, to: currentDate) ?? endDate
        }

        return dataPoints
    }

    /// Generate current market hours based on actual time
    static func marketHours() -> MarketHours {
        MarketHours.fallback()
    }
}

