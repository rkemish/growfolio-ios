//
//  StockTests.swift
//  GrowfolioTests
//
//  Tests for Stock domain model and related types.
//

import XCTest
@testable import Growfolio

final class StockTests: XCTestCase {

    // MARK: - Price Change Tests

    func testIsPriceUp_PositiveChange_ReturnsTrue() {
        let stock = TestFixtures.stock(priceChange: 2.50)
        XCTAssertTrue(stock.isPriceUp)
    }

    func testIsPriceUp_NegativeChange_ReturnsFalse() {
        let stock = TestFixtures.stock(priceChange: -2.50)
        XCTAssertFalse(stock.isPriceUp)
    }

    func testIsPriceUp_ZeroChange_ReturnsFalse() {
        let stock = TestFixtures.stock(priceChange: 0)
        XCTAssertFalse(stock.isPriceUp)
    }

    func testIsPriceUp_NilChange_ReturnsFalse() {
        let stock = TestFixtures.stock(priceChange: nil)
        XCTAssertFalse(stock.isPriceUp)
    }

    // MARK: - Stock ID Tests

    func testStockId_ReturnsSymbol() {
        let stock = TestFixtures.stock(symbol: "AAPL")
        XCTAssertEqual(stock.id, "AAPL")
    }

    // MARK: - MarketHours Tests

    func testMarketHours_IsOpen_True() {
        let marketHours = TestFixtures.marketHours(isOpen: true, session: .regular)
        XCTAssertTrue(marketHours.isOpen)
    }

    func testMarketHours_IsOpen_False() {
        let marketHours = TestFixtures.marketHours(isOpen: false)
        XCTAssertFalse(marketHours.isOpen)
    }

    func testMarketHours_Sessions() {
        XCTAssertEqual(MarketSession.pre.rawValue, "pre")
        XCTAssertEqual(MarketSession.regular.rawValue, "regular")
        XCTAssertEqual(MarketSession.after.rawValue, "after")
        XCTAssertEqual(MarketSession.closed.rawValue, "closed")
    }

    func testMarketHours_Fallback() {
        let fallback = MarketHours.fallback()
        XCTAssertEqual(fallback.exchange, "NYSE")
    }

    func testMarketSession_DisplayName() {
        XCTAssertEqual(MarketSession.pre.displayName, "Pre-Market")
        XCTAssertEqual(MarketSession.regular.displayName, "Regular Hours")
        XCTAssertEqual(MarketSession.after.displayName, "After Hours")
        XCTAssertEqual(MarketSession.closed.displayName, "Closed")
    }

    // MARK: - StockQuote Tests

    func testStockQuote_Symbol() {
        let quote = TestFixtures.stockQuote(symbol: "AAPL")
        XCTAssertEqual(quote.symbol, "AAPL")
    }

    func testStockQuote_IsPriceUp_Positive() {
        let quote = TestFixtures.stockQuote(change: 5)
        XCTAssertTrue(quote.isPriceUp)
    }

    func testStockQuote_IsPriceUp_Negative() {
        let quote = TestFixtures.stockQuote(change: -5)
        XCTAssertFalse(quote.isPriceUp)
    }

    func testStockQuote_IsPriceUp_Zero() {
        let quote = TestFixtures.stockQuote(change: 0)
        XCTAssertFalse(quote.isPriceUp)
    }

    // MARK: - StockSearchResult Tests

    func testStockSearchResult_Id() {
        let result = StockSearchResult(
            symbol: "AAPL",
            name: "Apple Inc.",
            exchange: "NASDAQ",
            assetType: .stock, status: nil,
            currencyCode: "USD"
        )
        XCTAssertEqual(result.id, "AAPL")
    }

    // MARK: - StockHistoryDataPoint Tests

    func testStockHistoryDataPoint_Id() {
        let date = Date()
        let dataPoint = StockHistoryDataPoint(
            date: date,
            open: 174.00,
            high: 176.00,
            low: 173.50,
            close: 175.50,
            volume: 45_000_000
        )
        XCTAssertEqual(dataPoint.id, date)
    }

    // MARK: - AssetType Tests

    func testAssetType_DisplayName() {
        XCTAssertEqual(AssetType.stock.displayName, "Stock")
        XCTAssertEqual(AssetType.etf.displayName, "ETF")
        XCTAssertEqual(AssetType.mutualFund.displayName, "Mutual Fund")
    }

    func testAssetType_Codable() throws {
        for type in AssetType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(AssetType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    // MARK: - Codable Tests

    func testStock_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.stock(
            symbol: "GOOGL",
            name: "Alphabet Inc.",
            currentPrice: 140,
            priceChange: -2.50,
            sector: "Technology"
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(Stock.self, from: data)

        XCTAssertEqual(decoded.symbol, original.symbol)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.currentPrice, original.currentPrice)
        XCTAssertEqual(decoded.sector, original.sector)
    }

    func testStockQuote_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.stockQuote(
            symbol: "MSFT",
            price: 350,
            change: 5.25,
            changePercent: 1.52
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(StockQuote.self, from: data)

        XCTAssertEqual(decoded.symbol, original.symbol)
        XCTAssertEqual(decoded.price, original.price)
        XCTAssertEqual(decoded.change, original.change)
    }

    func testMarketHours_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.marketHours(
            exchange: "NYSE",
            isOpen: true,
            session: .regular
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(MarketHours.self, from: data)

        XCTAssertEqual(decoded.exchange, original.exchange)
        XCTAssertEqual(decoded.isOpen, original.isOpen)
        XCTAssertEqual(decoded.session, original.session)
    }

    // MARK: - WatchlistItem Tests

    func testWatchlistItem_Id_ReturnsSymbol() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        XCTAssertEqual(item.id, "AAPL")
    }

    func testWatchlistItem_SymbolUppercased() {
        let item = WatchlistItem(symbol: "aapl")
        XCTAssertEqual(item.symbol, "AAPL")
    }

    func testWatchlistItem_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.watchlistItem(
            symbol: "NVDA",
            notes: "AI play"
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(WatchlistItem.self, from: data)

        XCTAssertEqual(decoded.symbol, original.symbol)
        XCTAssertEqual(decoded.notes, original.notes)
    }

    // MARK: - WatchlistItemWithQuote Tests

    func testWatchlistItemWithQuote_CompanyName_WithStock() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let stock = TestFixtures.stock(symbol: "AAPL", name: "Apple Inc.")
        let withQuote = WatchlistItemWithQuote(item: item, stock: stock, quote: nil)

        XCTAssertEqual(withQuote.companyName, "Apple Inc.")
    }

    func testWatchlistItemWithQuote_CompanyName_NoStock() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: nil)

        XCTAssertEqual(withQuote.companyName, "AAPL")
    }

    func testWatchlistItemWithQuote_CurrentPrice_FromQuote() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let quote = TestFixtures.stockQuote(symbol: "AAPL", price: 180)
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: quote)

        XCTAssertEqual(withQuote.currentPrice, 180)
    }

    func testWatchlistItemWithQuote_CurrentPrice_FromStock() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let stock = TestFixtures.stock(symbol: "AAPL", currentPrice: 175)
        let withQuote = WatchlistItemWithQuote(item: item, stock: stock, quote: nil)

        XCTAssertEqual(withQuote.currentPrice, 175)
    }

    func testWatchlistItemWithQuote_IsPriceUp_Positive() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let quote = TestFixtures.stockQuote(symbol: "AAPL", change: 5)
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: quote)

        XCTAssertTrue(withQuote.isPriceUp)
    }

    func testWatchlistItemWithQuote_IsPriceUp_Negative() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let quote = TestFixtures.stockQuote(symbol: "AAPL", change: -5)
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: quote)

        XCTAssertFalse(withQuote.isPriceUp)
    }

    func testWatchlistItemWithQuote_IsPriceUp_NilChange() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: nil)

        XCTAssertTrue(withQuote.isPriceUp) // Default when change is 0
    }

    // MARK: - Equatable Tests

    func testStock_Equatable() {
        let stock1 = TestFixtures.stock(symbol: "AAPL")
        let stock2 = TestFixtures.stock(symbol: "AAPL")
        let stock3 = TestFixtures.stock(symbol: "MSFT")

        XCTAssertEqual(stock1, stock2)
        XCTAssertNotEqual(stock1, stock3)
    }

    func testStockQuote_Equatable() {
        let quote1 = TestFixtures.stockQuote(symbol: "AAPL", price: 175)
        let quote2 = TestFixtures.stockQuote(symbol: "AAPL", price: 175)
        let quote3 = TestFixtures.stockQuote(symbol: "MSFT", price: 350)

        XCTAssertEqual(quote1, quote2)
        XCTAssertNotEqual(quote1, quote3)
    }

    func testWatchlistItem_Equatable() {
        let item1 = TestFixtures.watchlistItem(symbol: "AAPL")
        let item2 = TestFixtures.watchlistItem(symbol: "AAPL")
        let item3 = TestFixtures.watchlistItem(symbol: "MSFT")

        XCTAssertEqual(item1, item2)
        XCTAssertNotEqual(item1, item3)
    }

    // MARK: - Hashable Tests

    func testStock_Hashable() {
        let stock1 = TestFixtures.stock(symbol: "AAPL")
        let stock2 = TestFixtures.stock(symbol: "MSFT")

        var set = Set<Stock>()
        set.insert(stock1)
        set.insert(stock2)

        XCTAssertEqual(set.count, 2)
    }

    func testWatchlistItem_Hashable() {
        let item1 = TestFixtures.watchlistItem(symbol: "AAPL")
        let item2 = TestFixtures.watchlistItem(symbol: "MSFT")

        var set = Set<WatchlistItem>()
        set.insert(item1)
        set.insert(item2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Edge Cases

    func testStock_AllNilOptionals() {
        let stock = Stock(
            symbol: "TEST",
            name: "Test Corp",
            exchange: nil,
            assetType: .stock,
            currentPrice: nil,
            priceChange: nil,
            priceChangePercent: nil,
            previousClose: nil,
            openPrice: nil,
            dayHigh: nil,
            dayLow: nil,
            weekHigh52: nil,
            weekLow52: nil,
            volume: nil,
            averageVolume: nil,
            marketCap: nil,
            peRatio: nil,
            dividendYield: nil,
            eps: nil,
            beta: nil,
            sector: nil,
            industry: nil,
            companyDescription: nil,
            websiteURL: nil,
            logoURL: nil,
            currencyCode: "USD",
            lastUpdated: nil
        )

        // Test that computed properties handle nil values gracefully
        XCTAssertFalse(stock.isPriceUp) // priceChange is nil, so 0 > 0 is false
        XCTAssertFalse(stock.paysDividends) // dividendYield is nil
    }

    func testStock_VeryLargeMarketCap() {
        let stock = TestFixtures.stock(marketCap: 3_000_000_000_000) // $3 trillion
        XCTAssertEqual(stock.marketCap, 3_000_000_000_000)
    }

    func testStock_VerySmallPrice() {
        let stock = TestFixtures.stock(currentPrice: Decimal(string: "0.0001")!)
        XCTAssertEqual(stock.currentPrice, Decimal(string: "0.0001")!)
    }

    // MARK: - Stock Computed Properties Tests

    func testStock_DisplayName() {
        let stock = TestFixtures.stock(symbol: "AAPL", name: "Apple Inc.")
        XCTAssertEqual(stock.displayName, "Apple Inc. (AAPL)")
    }

    func testStock_IsPriceDown_Negative() {
        let stock = TestFixtures.stock(priceChange: -5.50)
        XCTAssertTrue(stock.isPriceDown)
    }

    func testStock_IsPriceDown_Positive() {
        let stock = TestFixtures.stock(priceChange: 5.50)
        XCTAssertFalse(stock.isPriceDown)
    }

    func testStock_IsPriceDown_Zero() {
        let stock = TestFixtures.stock(priceChange: 0)
        XCTAssertFalse(stock.isPriceDown)
    }

    func testStock_IsPriceDown_Nil() {
        let stock = TestFixtures.stock(priceChange: nil)
        XCTAssertFalse(stock.isPriceDown)
    }

    func testStock_DayRange_WithValues() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple",
            dayHigh: 180,
            dayLow: 175
        )
        XCTAssertNotNil(stock.dayRange)
        XCTAssertTrue(stock.dayRange!.contains("-"))
    }

    func testStock_DayRange_NilHigh() {
        let stock = Stock(symbol: "AAPL", name: "Apple", dayHigh: nil, dayLow: 175)
        XCTAssertNil(stock.dayRange)
    }

    func testStock_DayRange_NilLow() {
        let stock = Stock(symbol: "AAPL", name: "Apple", dayHigh: 180, dayLow: nil)
        XCTAssertNil(stock.dayRange)
    }

    func testStock_WeekRange52_WithValues() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple",
            weekHigh52: 200,
            weekLow52: 150
        )
        XCTAssertNotNil(stock.weekRange52)
        XCTAssertTrue(stock.weekRange52!.contains("-"))
    }

    func testStock_WeekRange52_NilValues() {
        let stock = Stock(symbol: "AAPL", name: "Apple", weekHigh52: nil, weekLow52: nil)
        XCTAssertNil(stock.weekRange52)
    }

    func testStock_FormattedMarketCap_Billions() {
        let stock = TestFixtures.stock(marketCap: 2_500_000_000_000)
        XCTAssertNotNil(stock.formattedMarketCap)
        XCTAssertTrue(stock.formattedMarketCap!.contains("T") || stock.formattedMarketCap!.contains("B"))
    }

    func testStock_FormattedMarketCap_Millions() {
        let stock = TestFixtures.stock(marketCap: 500_000_000)
        XCTAssertNotNil(stock.formattedMarketCap)
        XCTAssertTrue(stock.formattedMarketCap!.contains("M"))
    }

    func testStock_FormattedMarketCap_Nil() {
        let stock = Stock(symbol: "TEST", name: "Test", marketCap: nil)
        XCTAssertNil(stock.formattedMarketCap)
    }

    func testStock_FormattedVolume_Millions() {
        let stock = Stock(symbol: "AAPL", name: "Apple", volume: 50_000_000)
        XCTAssertNotNil(stock.formattedVolume)
        XCTAssertTrue(stock.formattedVolume!.contains("M"))
    }

    func testStock_FormattedVolume_Thousands() {
        let stock = Stock(symbol: "AAPL", name: "Apple", volume: 500_000)
        XCTAssertNotNil(stock.formattedVolume)
        XCTAssertTrue(stock.formattedVolume!.contains("K"))
    }

    func testStock_FormattedVolume_Billions() {
        let stock = Stock(symbol: "AAPL", name: "Apple", volume: 1_500_000_000)
        XCTAssertNotNil(stock.formattedVolume)
        XCTAssertTrue(stock.formattedVolume!.contains("B"))
    }

    func testStock_FormattedVolume_Small() {
        let stock = Stock(symbol: "AAPL", name: "Apple", volume: 500)
        XCTAssertEqual(stock.formattedVolume, "500")
    }

    func testStock_FormattedVolume_Nil() {
        let stock = Stock(symbol: "TEST", name: "Test", volume: nil)
        XCTAssertNil(stock.formattedVolume)
    }

    func testStock_DistanceFrom52WeekHigh() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple",
            currentPrice: 180,
            weekHigh52: 200
        )
        XCTAssertNotNil(stock.distanceFrom52WeekHigh)
        XCTAssertEqual(stock.distanceFrom52WeekHigh!, 10, accuracy: 0.01) // 10% from high
    }

    func testStock_DistanceFrom52WeekHigh_NilCurrent() {
        let stock = Stock(symbol: "AAPL", name: "Apple", currentPrice: nil, weekHigh52: 200)
        XCTAssertNil(stock.distanceFrom52WeekHigh)
    }

    func testStock_DistanceFrom52WeekHigh_NilHigh() {
        let stock = Stock(symbol: "AAPL", name: "Apple", currentPrice: 180, weekHigh52: nil)
        XCTAssertNil(stock.distanceFrom52WeekHigh)
    }

    func testStock_DistanceFrom52WeekHigh_ZeroHigh() {
        let stock = Stock(symbol: "AAPL", name: "Apple", currentPrice: 180, weekHigh52: 0)
        XCTAssertNil(stock.distanceFrom52WeekHigh)
    }

    func testStock_DistanceFrom52WeekLow() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple",
            currentPrice: 165,
            weekLow52: 150
        )
        XCTAssertNotNil(stock.distanceFrom52WeekLow)
        XCTAssertEqual(stock.distanceFrom52WeekLow!, 10, accuracy: 0.01) // 10% above low
    }

    func testStock_DistanceFrom52WeekLow_NilValues() {
        let stock = Stock(symbol: "AAPL", name: "Apple", currentPrice: nil, weekLow52: nil)
        XCTAssertNil(stock.distanceFrom52WeekLow)
    }

    func testStock_DistanceFrom52WeekLow_ZeroLow() {
        let stock = Stock(symbol: "AAPL", name: "Apple", currentPrice: 180, weekLow52: 0)
        XCTAssertNil(stock.distanceFrom52WeekLow)
    }

    func testStock_PaysDividends_True() {
        let stock = Stock(symbol: "AAPL", name: "Apple", dividendYield: 0.5)
        XCTAssertTrue(stock.paysDividends)
    }

    func testStock_PaysDividends_False() {
        let stock = Stock(symbol: "TSLA", name: "Tesla", dividendYield: 0)
        XCTAssertFalse(stock.paysDividends)
    }

    func testStock_PaysDividends_Nil() {
        let stock = Stock(symbol: "TEST", name: "Test", dividendYield: nil)
        XCTAssertFalse(stock.paysDividends)
    }

    // MARK: - StockQuote Computed Properties Tests

    func testStockQuote_FormattedChange_Positive() {
        let quote = TestFixtures.stockQuote(change: 5.25)
        XCTAssertTrue(quote.formattedChange.hasPrefix("+"))
    }

    func testStockQuote_FormattedChange_Negative() {
        let quote = TestFixtures.stockQuote(change: -5.25)
        XCTAssertFalse(quote.formattedChange.hasPrefix("+"))
    }

    func testStockQuote_FormattedChange_Zero() {
        let quote = TestFixtures.stockQuote(change: 0)
        XCTAssertTrue(quote.formattedChange.hasPrefix("+"))
    }

    func testStockQuote_FormattedChangePercent_Positive() {
        let quote = TestFixtures.stockQuote(changePercent: 2.5)
        XCTAssertTrue(quote.formattedChangePercent.hasPrefix("+"))
        XCTAssertTrue(quote.formattedChangePercent.contains("%"))
    }

    func testStockQuote_FormattedChangePercent_Negative() {
        let quote = TestFixtures.stockQuote(changePercent: -2.5)
        XCTAssertTrue(quote.formattedChangePercent.contains("-"))
        XCTAssertTrue(quote.formattedChangePercent.contains("%"))
    }

    // MARK: - StockHistory Tests

    func testStockHistory_StartPrice() {
        let dataPoints = [
            StockHistoryDataPoint(date: Date(), open: 100, high: 105, low: 98, close: 102, volume: 1000),
            StockHistoryDataPoint(date: Date().addingTimeInterval(86400), open: 102, high: 108, low: 101, close: 107, volume: 1200)
        ]
        let history = StockHistory(symbol: "AAPL", period: .oneMonth, dataPoints: dataPoints)
        XCTAssertEqual(history.startPrice, 102) // First close
    }

    func testStockHistory_EndPrice() {
        let dataPoints = [
            StockHistoryDataPoint(date: Date(), open: 100, high: 105, low: 98, close: 102, volume: 1000),
            StockHistoryDataPoint(date: Date().addingTimeInterval(86400), open: 102, high: 108, low: 101, close: 107, volume: 1200)
        ]
        let history = StockHistory(symbol: "AAPL", period: .oneMonth, dataPoints: dataPoints)
        XCTAssertEqual(history.endPrice, 107) // Last close
    }

    func testStockHistory_PeriodReturn() {
        let dataPoints = [
            StockHistoryDataPoint(date: Date(), open: 100, high: 105, low: 98, close: 100, volume: 1000),
            StockHistoryDataPoint(date: Date().addingTimeInterval(86400), open: 100, high: 115, low: 99, close: 110, volume: 1200)
        ]
        let history = StockHistory(symbol: "AAPL", period: .oneMonth, dataPoints: dataPoints)
        XCTAssertEqual(history.periodReturn!, 10, accuracy: 0.01) // 10% return
    }

    func testStockHistory_PeriodReturn_Empty() {
        let history = StockHistory(symbol: "AAPL", period: .oneMonth, dataPoints: [])
        XCTAssertNil(history.periodReturn)
    }

    func testStockHistory_HighestPrice() {
        let dataPoints = [
            StockHistoryDataPoint(date: Date(), open: 100, high: 105, low: 98, close: 102, volume: 1000),
            StockHistoryDataPoint(date: Date().addingTimeInterval(86400), open: 102, high: 115, low: 101, close: 107, volume: 1200)
        ]
        let history = StockHistory(symbol: "AAPL", period: .oneMonth, dataPoints: dataPoints)
        XCTAssertEqual(history.highestPrice, 115)
    }

    func testStockHistory_LowestPrice() {
        let dataPoints = [
            StockHistoryDataPoint(date: Date(), open: 100, high: 105, low: 98, close: 102, volume: 1000),
            StockHistoryDataPoint(date: Date().addingTimeInterval(86400), open: 102, high: 115, low: 101, close: 107, volume: 1200)
        ]
        let history = StockHistory(symbol: "AAPL", period: .oneMonth, dataPoints: dataPoints)
        XCTAssertEqual(history.lowestPrice, 98)
    }

    // MARK: - StockHistoryDataPoint Computed Properties Tests

    func testStockHistoryDataPoint_Range() {
        let dataPoint = StockHistoryDataPoint(date: Date(), open: 100, high: 110, low: 95, close: 105, volume: 1000)
        XCTAssertEqual(dataPoint.range, 15)
    }

    func testStockHistoryDataPoint_ChangeFromOpen() {
        let dataPoint = StockHistoryDataPoint(date: Date(), open: 100, high: 110, low: 95, close: 108, volume: 1000)
        XCTAssertEqual(dataPoint.changeFromOpen, 8)
    }

    func testStockHistoryDataPoint_ChangeFromOpenPercent() {
        let dataPoint = StockHistoryDataPoint(date: Date(), open: 100, high: 110, low: 95, close: 110, volume: 1000)
        XCTAssertEqual(dataPoint.changeFromOpenPercent, 10)
    }

    func testStockHistoryDataPoint_ChangeFromOpenPercent_ZeroOpen() {
        let dataPoint = StockHistoryDataPoint(date: Date(), open: 0, high: 10, low: 0, close: 5, volume: 1000)
        XCTAssertEqual(dataPoint.changeFromOpenPercent, 0)
    }

    // MARK: - StockSearchResult Tests

    func testStockSearchResult_DisplayName_WithExchange() {
        let result = StockSearchResult(
            symbol: "AAPL",
            name: "Apple Inc.",
            exchange: "NASDAQ",
            assetType: .stock, status: nil,
            currencyCode: "USD"
        )
        XCTAssertEqual(result.displayName, "AAPL - Apple Inc. (NASDAQ)")
    }

    func testStockSearchResult_DisplayName_WithoutExchange() {
        let result = StockSearchResult(
            symbol: "AAPL",
            name: "Apple Inc.",
            exchange: nil,
            assetType: .stock, status: nil,
            currencyCode: "USD"
        )
        XCTAssertEqual(result.displayName, "AAPL - Apple Inc.")
    }

    func testStockSearchResult_Hashable() {
        let result1 = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, assetType: .stock, status: nil, currencyCode: "USD")
        let result2 = StockSearchResult(symbol: "MSFT", name: "Microsoft", exchange: nil, assetType: .stock, status: nil, currencyCode: "USD")

        var set = Set<StockSearchResult>()
        set.insert(result1)
        set.insert(result2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Watchlist Tests

    func testWatchlist_Initialization() {
        let watchlist = Watchlist(userId: "user-123", name: "Tech Stocks", symbols: ["AAPL", "MSFT"])
        XCTAssertEqual(watchlist.userId, "user-123")
        XCTAssertEqual(watchlist.name, "Tech Stocks")
        XCTAssertEqual(watchlist.symbols, ["AAPL", "MSFT"])
    }

    func testWatchlist_AddSymbol() {
        var watchlist = Watchlist(userId: "user-123")
        watchlist.addSymbol("AAPL")

        XCTAssertTrue(watchlist.symbols.contains("AAPL"))
    }

    func testWatchlist_AddSymbol_NoDuplicates() {
        var watchlist = Watchlist(userId: "user-123", symbols: ["AAPL"])
        watchlist.addSymbol("AAPL")

        XCTAssertEqual(watchlist.symbols.count, 1)
    }

    func testWatchlist_RemoveSymbol() {
        var watchlist = Watchlist(userId: "user-123", symbols: ["AAPL", "MSFT"])
        watchlist.removeSymbol("AAPL")

        XCTAssertFalse(watchlist.symbols.contains("AAPL"))
        XCTAssertTrue(watchlist.symbols.contains("MSFT"))
    }

    func testWatchlist_Contains() {
        let watchlist = Watchlist(userId: "user-123", symbols: ["AAPL", "MSFT"])

        XCTAssertTrue(watchlist.contains("AAPL"))
        XCTAssertFalse(watchlist.contains("GOOGL"))
    }

    // MARK: - MarketHours Computed Properties Tests

    func testMarketHours_StatusText_Open() {
        let hours = MarketHours(exchange: "NYSE", isOpen: true, session: .regular)
        XCTAssertEqual(hours.statusText, "Market Open")
    }

    func testMarketHours_StatusText_Closed() {
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .closed, nextOpen: nil)
        XCTAssertEqual(hours.statusText, "Market Closed")
    }

    func testMarketHours_StatusText_ClosedWithNextOpen() {
        let nextOpen = Date().addingTimeInterval(3600)
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .closed, nextOpen: nextOpen)
        XCTAssertTrue(hours.statusText.contains("Opens"))
    }

    func testMarketHours_ShortStatusText_Open() {
        let hours = MarketHours(exchange: "NYSE", isOpen: true, session: .regular)
        XCTAssertEqual(hours.shortStatusText, "Open")
    }

    func testMarketHours_ShortStatusText_Closed() {
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .closed)
        XCTAssertEqual(hours.shortStatusText, "Closed")
    }

    func testMarketHours_SessionStatusText_Pre() {
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .pre)
        XCTAssertEqual(hours.sessionStatusText, "Pre-Market Trading")
    }

    func testMarketHours_SessionStatusText_Regular() {
        let hours = MarketHours(exchange: "NYSE", isOpen: true, session: .regular)
        XCTAssertEqual(hours.sessionStatusText, "Market Open")
    }

    func testMarketHours_SessionStatusText_After() {
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .after)
        XCTAssertEqual(hours.sessionStatusText, "After Hours Trading")
    }

    func testMarketHours_SessionStatusText_Closed() {
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .closed)
        XCTAssertEqual(hours.sessionStatusText, "Market Closed")
    }

    func testMarketHours_NextEventTime_WhenOpen() {
        let nextClose = Date().addingTimeInterval(7200)
        let hours = MarketHours(exchange: "NYSE", isOpen: true, session: .regular, nextClose: nextClose)
        XCTAssertEqual(hours.nextEventTime, nextClose)
    }

    func testMarketHours_NextEventTime_WhenClosed() {
        let nextOpen = Date().addingTimeInterval(3600)
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .closed, nextOpen: nextOpen)
        XCTAssertEqual(hours.nextEventTime, nextOpen)
    }

    func testMarketHours_NextEventLabel_WhenOpen() {
        let nextClose = Date().addingTimeInterval(7200)
        let hours = MarketHours(exchange: "NYSE", isOpen: true, session: .regular, nextClose: nextClose)
        XCTAssertTrue(hours.nextEventLabel.contains("Closes"))
    }

    func testMarketHours_NextEventLabel_WhenClosed() {
        let nextOpen = Date().addingTimeInterval(3600)
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .closed, nextOpen: nextOpen)
        XCTAssertTrue(hours.nextEventLabel.contains("Opens"))
    }

    func testMarketHours_NextEventLabel_NoNextEvent() {
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .closed, nextOpen: nil, nextClose: nil)
        XCTAssertEqual(hours.nextEventLabel, "")
    }

    func testMarketHours_IsExtendedHours_Pre() {
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .pre)
        XCTAssertTrue(hours.isExtendedHours)
    }

    func testMarketHours_IsExtendedHours_After() {
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .after)
        XCTAssertTrue(hours.isExtendedHours)
    }

    func testMarketHours_IsExtendedHours_Regular() {
        let hours = MarketHours(exchange: "NYSE", isOpen: true, session: .regular)
        XCTAssertFalse(hours.isExtendedHours)
    }

    func testMarketHours_IsExtendedHours_Closed() {
        let hours = MarketHours(exchange: "NYSE", isOpen: false, session: .closed)
        XCTAssertFalse(hours.isExtendedHours)
    }

    // MARK: - OrderStatus Tests

    func testOrderStatus_DisplayName() {
        XCTAssertEqual(OrderStatus.new.displayName, "Pending")
        XCTAssertEqual(OrderStatus.filled.displayName, "Filled")
        XCTAssertEqual(OrderStatus.partiallyFilled.displayName, "Partially Filled")
        XCTAssertEqual(OrderStatus.cancelled.displayName, "Cancelled")
        XCTAssertEqual(OrderStatus.expired.displayName, "Expired")
        XCTAssertEqual(OrderStatus.rejected.displayName, "Rejected")
        XCTAssertEqual(OrderStatus.pendingCancel.displayName, "Cancelling")
        XCTAssertEqual(OrderStatus.pendingReplace.displayName, "Modifying")
        XCTAssertEqual(OrderStatus.stopped.displayName, "Halted")
        XCTAssertEqual(OrderStatus.suspended.displayName, "Halted")
        XCTAssertEqual(OrderStatus.calculated.displayName, "Calculating")
    }

    func testOrderStatus_IsActive() {
        XCTAssertTrue(OrderStatus.new.isActive)
        XCTAssertTrue(OrderStatus.accepted.isActive)
        XCTAssertTrue(OrderStatus.pendingNew.isActive)
        XCTAssertTrue(OrderStatus.partiallyFilled.isActive)
        XCTAssertTrue(OrderStatus.pendingCancel.isActive)

        XCTAssertFalse(OrderStatus.filled.isActive)
        XCTAssertFalse(OrderStatus.cancelled.isActive)
        XCTAssertFalse(OrderStatus.expired.isActive)
        XCTAssertFalse(OrderStatus.rejected.isActive)
    }

    func testOrderStatus_IsComplete() {
        XCTAssertTrue(OrderStatus.filled.isComplete)

        XCTAssertFalse(OrderStatus.new.isComplete)
        XCTAssertFalse(OrderStatus.partiallyFilled.isComplete)
        XCTAssertFalse(OrderStatus.cancelled.isComplete)
    }

    func testOrderStatus_Codable() throws {
        let statuses: [OrderStatus] = [.new, .filled, .cancelled, .partiallyFilled]
        for status in statuses {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(OrderStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    func testOrderSide_Codable() throws {
        let sides: [OrderSide] = [.buy, .sell]
        for side in sides {
            let data = try JSONEncoder().encode(side)
            let decoded = try JSONDecoder().decode(OrderSide.self, from: data)
            XCTAssertEqual(decoded, side)
        }
    }

    func testOrderType_Codable() throws {
        let types: [OrderType] = [.market, .limit, .stop, .stopLimit]
        for type in types {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(OrderType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    // MARK: - HistoryPeriod Tests

    func testHistoryPeriod_Codable() throws {
        let periods: [HistoryPeriod] = [.oneWeek, .oneMonth, .threeMonths, .sixMonths, .oneYear, .fiveYears, .all]
        for period in periods {
            let data = try JSONEncoder().encode(period)
            let decoded = try JSONDecoder().decode(HistoryPeriod.self, from: data)
            XCTAssertEqual(decoded, period)
        }
    }

    func testHistoryPeriod_RawValues() {
        XCTAssertEqual(HistoryPeriod.oneWeek.rawValue, "1w")
        XCTAssertEqual(HistoryPeriod.oneMonth.rawValue, "1m")
        XCTAssertEqual(HistoryPeriod.threeMonths.rawValue, "3m")
        XCTAssertEqual(HistoryPeriod.sixMonths.rawValue, "6m")
        XCTAssertEqual(HistoryPeriod.oneYear.rawValue, "1y")
        XCTAssertEqual(HistoryPeriod.fiveYears.rawValue, "5y")
        XCTAssertEqual(HistoryPeriod.all.rawValue, "all")
    }
}
