//
//  WatchlistItemTests.swift
//  GrowfolioTests
//
//  Tests for WatchlistItem domain model.
//

import XCTest
@testable import Growfolio

final class WatchlistItemTests: XCTestCase {

    // MARK: - Identifiable Tests

    func testId_ReturnsSymbol() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        XCTAssertEqual(item.id, "AAPL")
    }

    // MARK: - Symbol Uppercasing Tests

    func testSymbol_LowercaseInput_ReturnsUppercased() {
        let item = WatchlistItem(symbol: "aapl")
        XCTAssertEqual(item.symbol, "AAPL")
    }

    func testSymbol_MixedCaseInput_ReturnsUppercased() {
        let item = WatchlistItem(symbol: "AaPl")
        XCTAssertEqual(item.symbol, "AAPL")
    }

    func testSymbol_AlreadyUppercase_RemainsUppercased() {
        let item = WatchlistItem(symbol: "AAPL")
        XCTAssertEqual(item.symbol, "AAPL")
    }

    // MARK: - Notes Tests

    func testNotes_WithValue_ReturnsValue() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL", notes: "Strong fundamentals")
        XCTAssertEqual(item.notes, "Strong fundamentals")
    }

    func testNotes_NilValue_ReturnsNil() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL", notes: nil)
        XCTAssertNil(item.notes)
    }

    // MARK: - Date Added Tests

    func testDateAdded_CustomDate_ReturnsDate() {
        let customDate = TestFixtures.pastDate
        let item = TestFixtures.watchlistItem(symbol: "AAPL", dateAdded: customDate)
        XCTAssertEqual(item.dateAdded, customDate)
    }

    func testDateAdded_DefaultDate_ReturnsReferenceDate() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        XCTAssertEqual(item.dateAdded, TestFixtures.referenceDate)
    }

    // MARK: - WatchlistItemWithQuote Tests

    func testWatchlistItemWithQuote_Id() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: nil)
        XCTAssertEqual(withQuote.id, "AAPL")
    }

    func testWatchlistItemWithQuote_Symbol() {
        let item = TestFixtures.watchlistItem(symbol: "MSFT")
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: nil)
        XCTAssertEqual(withQuote.symbol, "MSFT")
    }

    func testWatchlistItemWithQuote_DateAdded() {
        let customDate = TestFixtures.pastDate
        let item = TestFixtures.watchlistItem(symbol: "AAPL", dateAdded: customDate)
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: nil)
        XCTAssertEqual(withQuote.dateAdded, customDate)
    }

    func testWatchlistItemWithQuote_Notes() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL", notes: "Test note")
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: nil)
        XCTAssertEqual(withQuote.notes, "Test note")
    }

    // MARK: - CompanyName Tests

    func testWatchlistItemWithQuote_CompanyName_WithStock() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let stock = TestFixtures.stock(symbol: "AAPL", name: "Apple Inc.")
        let withQuote = WatchlistItemWithQuote(item: item, stock: stock, quote: nil)
        XCTAssertEqual(withQuote.companyName, "Apple Inc.")
    }

    func testWatchlistItemWithQuote_CompanyName_NoStock_ReturnsSymbol() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: nil)
        XCTAssertEqual(withQuote.companyName, "AAPL")
    }

    // MARK: - CurrentPrice Tests

    func testWatchlistItemWithQuote_CurrentPrice_FromQuote() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let quote = TestFixtures.stockQuote(symbol: "AAPL", price: 180.50)
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: quote)
        XCTAssertEqual(withQuote.currentPrice, 180.50)
    }

    func testWatchlistItemWithQuote_CurrentPrice_FromStock() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let stock = TestFixtures.stock(symbol: "AAPL", currentPrice: 175.00)
        let withQuote = WatchlistItemWithQuote(item: item, stock: stock, quote: nil)
        XCTAssertEqual(withQuote.currentPrice, 175.00)
    }

    func testWatchlistItemWithQuote_CurrentPrice_QuoteTakesPrecedence() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let stock = TestFixtures.stock(symbol: "AAPL", currentPrice: 175.00)
        let quote = TestFixtures.stockQuote(symbol: "AAPL", price: 180.50)
        let withQuote = WatchlistItemWithQuote(item: item, stock: stock, quote: quote)
        XCTAssertEqual(withQuote.currentPrice, 180.50)
    }

    func testWatchlistItemWithQuote_CurrentPrice_NilWhenNoneAvailable() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: nil)
        XCTAssertNil(withQuote.currentPrice)
    }

    // MARK: - PriceChange Tests

    func testWatchlistItemWithQuote_PriceChange_FromQuote() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let quote = TestFixtures.stockQuote(symbol: "AAPL", change: 5.25)
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: quote)
        XCTAssertEqual(withQuote.priceChange, 5.25)
    }

    func testWatchlistItemWithQuote_PriceChange_FromStock() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let stock = TestFixtures.stock(symbol: "AAPL", priceChange: 2.50)
        let withQuote = WatchlistItemWithQuote(item: item, stock: stock, quote: nil)
        XCTAssertEqual(withQuote.priceChange, 2.50)
    }

    func testWatchlistItemWithQuote_PriceChange_NilWhenNoneAvailable() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: nil)
        XCTAssertNil(withQuote.priceChange)
    }

    // MARK: - PriceChangePercent Tests

    func testWatchlistItemWithQuote_PriceChangePercent_FromQuote() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let quote = TestFixtures.stockQuote(symbol: "AAPL", changePercent: 2.95)
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: quote)
        XCTAssertEqual(withQuote.priceChangePercent, 2.95)
    }

    func testWatchlistItemWithQuote_PriceChangePercent_FromStock() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let stock = TestFixtures.stock(symbol: "AAPL", priceChangePercent: 1.45)
        let withQuote = WatchlistItemWithQuote(item: item, stock: stock, quote: nil)
        XCTAssertEqual(withQuote.priceChangePercent, 1.45)
    }

    // MARK: - IsPriceUp Tests

    func testWatchlistItemWithQuote_IsPriceUp_PositiveChange() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let quote = TestFixtures.stockQuote(symbol: "AAPL", change: 5.25)
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: quote)
        XCTAssertTrue(withQuote.isPriceUp)
    }

    func testWatchlistItemWithQuote_IsPriceUp_NegativeChange() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let quote = TestFixtures.stockQuote(symbol: "AAPL", change: -3.50)
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: quote)
        XCTAssertFalse(withQuote.isPriceUp)
    }

    func testWatchlistItemWithQuote_IsPriceUp_ZeroChange() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let quote = TestFixtures.stockQuote(symbol: "AAPL", change: 0)
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: quote)
        XCTAssertTrue(withQuote.isPriceUp)
    }

    func testWatchlistItemWithQuote_IsPriceUp_NilChange_ReturnsTrue() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let withQuote = WatchlistItemWithQuote(item: item, stock: nil, quote: nil)
        XCTAssertTrue(withQuote.isPriceUp) // Default when change is nil (treated as 0)
    }

    // MARK: - Codable Tests

    func testWatchlistItem_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.watchlistItem(
            symbol: "NVDA",
            notes: "AI play, strong growth"
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(WatchlistItem.self, from: data)

        XCTAssertEqual(decoded.symbol, original.symbol)
        XCTAssertEqual(decoded.notes, original.notes)
    }

    func testWatchlistItem_EncodeDecode_NilNotes() throws {
        let original = TestFixtures.watchlistItem(symbol: "AAPL", notes: nil)

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(WatchlistItem.self, from: data)

        XCTAssertEqual(decoded.symbol, original.symbol)
        XCTAssertNil(decoded.notes)
    }

    // MARK: - Equatable Tests

    func testWatchlistItem_Equatable_SameSymbol() {
        let item1 = TestFixtures.watchlistItem(symbol: "AAPL")
        let item2 = TestFixtures.watchlistItem(symbol: "AAPL")
        XCTAssertEqual(item1, item2)
    }

    func testWatchlistItem_Equatable_DifferentSymbol() {
        let item1 = TestFixtures.watchlistItem(symbol: "AAPL")
        let item2 = TestFixtures.watchlistItem(symbol: "MSFT")
        XCTAssertNotEqual(item1, item2)
    }

    func testWatchlistItemWithQuote_Equatable() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL")
        let stock = TestFixtures.stock(symbol: "AAPL")
        let withQuote1 = WatchlistItemWithQuote(item: item, stock: stock, quote: nil)
        let withQuote2 = WatchlistItemWithQuote(item: item, stock: stock, quote: nil)
        XCTAssertEqual(withQuote1, withQuote2)
    }

    // MARK: - Hashable Tests

    func testWatchlistItem_Hashable() {
        let item1 = TestFixtures.watchlistItem(symbol: "AAPL")
        let item2 = TestFixtures.watchlistItem(symbol: "MSFT")

        var set = Set<WatchlistItem>()
        set.insert(item1)
        set.insert(item2)

        XCTAssertEqual(set.count, 2)
    }

    func testWatchlistItem_Hashable_SameSymbolNotDuplicated() {
        // Note: WatchlistItem uses synthesized Equatable/Hashable which compares ALL properties.
        // Two items with the same symbol but different notes are NOT considered equal/duplicate.
        // This test verifies that items with identical properties are deduplicated.
        let item1 = TestFixtures.watchlistItem(symbol: "AAPL", notes: "Note 1")
        let item2 = TestFixtures.watchlistItem(symbol: "AAPL", notes: "Note 1")

        var set = Set<WatchlistItem>()
        set.insert(item1)
        set.insert(item2)

        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Sample Data Tests

    func testSampleWatchlistItems() {
        let samples = TestFixtures.sampleWatchlistItems
        XCTAssertEqual(samples.count, 3)

        let symbols = samples.map { $0.symbol }
        XCTAssertTrue(symbols.contains("AAPL"))
        XCTAssertTrue(symbols.contains("MSFT"))
        XCTAssertTrue(symbols.contains("NVDA"))
    }

    // MARK: - Edge Cases

    func testWatchlistItem_EmptySymbol() {
        let item = WatchlistItem(symbol: "")
        XCTAssertEqual(item.symbol, "")
        XCTAssertEqual(item.id, "")
    }

    func testWatchlistItem_SymbolWithNumbers() {
        let item = WatchlistItem(symbol: "brk.a")
        XCTAssertEqual(item.symbol, "BRK.A")
    }

    func testWatchlistItem_LongNotes() {
        let longNote = String(repeating: "A very long note about this stock. ", count: 100)
        let item = TestFixtures.watchlistItem(symbol: "AAPL", notes: longNote)
        XCTAssertEqual(item.notes, longNote)
    }

    func testWatchlistItemWithQuote_AllDataAvailable() {
        let item = TestFixtures.watchlistItem(symbol: "AAPL", notes: "Test")
        let stock = TestFixtures.stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            currentPrice: 175.00,
            priceChange: 2.50,
            priceChangePercent: 1.45
        )
        let quote = TestFixtures.stockQuote(
            symbol: "AAPL",
            price: 180.00,
            change: 5.00,
            changePercent: 2.86
        )

        let withQuote = WatchlistItemWithQuote(item: item, stock: stock, quote: quote)

        XCTAssertEqual(withQuote.symbol, "AAPL")
        XCTAssertEqual(withQuote.companyName, "Apple Inc.")
        XCTAssertEqual(withQuote.currentPrice, 180.00) // Quote takes precedence
        XCTAssertEqual(withQuote.priceChange, 5.00) // Quote takes precedence
        XCTAssertEqual(withQuote.priceChangePercent, 2.86) // Quote takes precedence
        XCTAssertTrue(withQuote.isPriceUp)
        XCTAssertEqual(withQuote.notes, "Test")
    }
}
