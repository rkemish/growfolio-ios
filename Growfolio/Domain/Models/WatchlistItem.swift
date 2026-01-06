//
//  WatchlistItem.swift
//  Growfolio
//
//  Watchlist item domain model for tracking watched stocks.
//

import Foundation

/// Represents a single item in the user's watchlist
struct WatchlistItem: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Stock symbol (ticker)
    let symbol: String

    /// Date when the stock was added to the watchlist
    let dateAdded: Date

    /// Optional notes about why the user is watching this stock
    var notes: String?

    // MARK: - Identifiable

    var id: String { symbol }

    // MARK: - Initialization

    init(
        symbol: String,
        dateAdded: Date = Date(),
        notes: String? = nil
    ) {
        self.symbol = symbol.uppercased()
        self.dateAdded = dateAdded
        self.notes = notes
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case symbol
        case dateAdded
        case notes
    }
}

// MARK: - Watchlist Summary

/// Summary information about a watchlist item with current stock data
struct WatchlistItemWithQuote: Identifiable, Sendable, Equatable {
    let item: WatchlistItem
    let stock: Stock?
    let quote: StockQuote?

    var id: String { item.id }
    var symbol: String { item.symbol }
    var dateAdded: Date { item.dateAdded }
    var notes: String? { item.notes }

    /// Company name from stock data
    var companyName: String {
        stock?.name ?? symbol
    }

    /// Current price
    var currentPrice: Decimal? {
        quote?.price ?? stock?.currentPrice
    }

    /// Price change
    var priceChange: Decimal? {
        quote?.change ?? stock?.priceChange
    }

    /// Price change percentage
    var priceChangePercent: Decimal? {
        quote?.changePercent ?? stock?.priceChangePercent
    }

    /// Whether price is up
    var isPriceUp: Bool {
        (priceChange ?? 0) >= 0
    }

    /// Formatted price string
    var formattedPrice: String {
        currentPrice?.currencyString ?? "--"
    }

    /// Formatted change string
    var formattedChange: String {
        guard let change = priceChange else { return "--" }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(change.currencyString)"
    }

    /// Formatted change percent string
    var formattedChangePercent: String {
        guard let percent = priceChangePercent else { return "--" }
        let sign = percent >= 0 ? "+" : ""
        return "\(sign)\(percent.rounded(places: 2))%"
    }
}
