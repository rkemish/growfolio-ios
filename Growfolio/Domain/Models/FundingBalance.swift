//
//  FundingBalance.swift
//  Growfolio
//
//  Domain model for account funding balance with FX support.
//

import Foundation

/// Represents the funding balance in both USD and GBP
struct FundingBalance: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// User ID this balance belongs to
    let userId: String

    /// Portfolio ID this balance belongs to
    let portfolioId: String

    /// Available balance in USD
    var availableUSD: Decimal

    /// Available balance in GBP
    var availableGBP: Decimal

    /// Pending deposits in USD
    var pendingDepositsUSD: Decimal

    /// Pending deposits in GBP
    var pendingDepositsGBP: Decimal

    /// Pending withdrawals in USD
    var pendingWithdrawalsUSD: Decimal

    /// Pending withdrawals in GBP
    var pendingWithdrawalsGBP: Decimal

    /// Last updated timestamp
    let updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        userId: String,
        portfolioId: String,
        availableUSD: Decimal = 0,
        availableGBP: Decimal = 0,
        pendingDepositsUSD: Decimal = 0,
        pendingDepositsGBP: Decimal = 0,
        pendingWithdrawalsUSD: Decimal = 0,
        pendingWithdrawalsGBP: Decimal = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.portfolioId = portfolioId
        self.availableUSD = availableUSD
        self.availableGBP = availableGBP
        self.pendingDepositsUSD = pendingDepositsUSD
        self.pendingDepositsGBP = pendingDepositsGBP
        self.pendingWithdrawalsUSD = pendingWithdrawalsUSD
        self.pendingWithdrawalsGBP = pendingWithdrawalsGBP
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Total available balance in USD (including GBP converted)
    func totalAvailableUSD(fxRate: Decimal) -> Decimal {
        availableUSD + (availableGBP * fxRate)
    }

    /// Total pending in USD
    var totalPendingUSD: Decimal {
        pendingDepositsUSD - pendingWithdrawalsUSD
    }

    /// Total pending in GBP
    var totalPendingGBP: Decimal {
        pendingDepositsGBP - pendingWithdrawalsGBP
    }

    /// Whether there are any pending transactions
    var hasPendingTransactions: Bool {
        pendingDepositsUSD != 0 || pendingDepositsGBP != 0 ||
        pendingWithdrawalsUSD != 0 || pendingWithdrawalsGBP != 0
    }

    /// Whether there is available balance
    var hasAvailableBalance: Bool {
        availableUSD > 0 || availableGBP > 0
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case portfolioId
        case availableUSD = "availableUsd"
        case availableGBP = "availableGbp"
        case pendingDepositsUSD = "pendingDepositsUsd"
        case pendingDepositsGBP = "pendingDepositsGbp"
        case pendingWithdrawalsUSD = "pendingWithdrawalsUsd"
        case pendingWithdrawalsGBP = "pendingWithdrawalsGbp"
        case updatedAt
    }
}

// MARK: - FX Rate

/// Represents a foreign exchange rate
struct FXRate: Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Source currency code (e.g., "GBP")
    let fromCurrency: String

    /// Target currency code (e.g., "USD")
    let toCurrency: String

    /// Exchange rate (how many target currency units per source unit)
    let rate: Decimal

    /// Spread applied to the rate
    let spread: Decimal

    /// The effective rate after spread
    /// Spread is applied as a multiplier (e.g., 0.01 = 1% spread reduces the rate)
    var effectiveRate: Decimal {
        rate * (1 - spread)
    }

    /// Inverse rate (target to source)
    var inverseRate: Decimal {
        guard rate != 0 else { return 0 }
        return 1 / rate
    }

    /// Timestamp when rate was fetched
    let timestamp: Date

    /// Rate expiry time
    let expiresAt: Date

    /// Whether the rate is still valid
    var isValid: Bool {
        Date() < expiresAt
    }

    // MARK: - Initialization

    init(
        fromCurrency: String = "GBP",
        toCurrency: String = "USD",
        rate: Decimal,
        spread: Decimal = 0,
        timestamp: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.rate = rate
        self.spread = spread
        self.timestamp = timestamp
        // FX rates expire after 5 minutes by default (or fallback to timestamp if date math fails)
        self.expiresAt = expiresAt ?? timestamp.adding(minutes: 5) ?? timestamp
    }

    // MARK: - Conversion Methods

    /// Convert amount from source to target currency
    func convert(_ amount: Decimal) -> Decimal {
        amount * effectiveRate
    }

    /// Convert amount from target back to source currency
    func convertBack(_ amount: Decimal) -> Decimal {
        guard effectiveRate != 0 else { return 0 }
        return amount / effectiveRate
    }

    /// Display string for the rate
    var displayString: String {
        "1 \(fromCurrency) = \(rate.rounded(places: 4)) \(toCurrency)"
    }

    /// Display string for effective rate (after spread)
    var effectiveDisplayString: String {
        "1 \(fromCurrency) = \(effectiveRate.rounded(places: 4)) \(toCurrency)"
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case fromCurrency
        case toCurrency
        case rate
        case spread
        case timestamp
        case expiresAt
    }
}

// MARK: - Date Extension Helper

private extension Date {
    func adding(minutes: Int) -> Date? {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self)
    }
}
