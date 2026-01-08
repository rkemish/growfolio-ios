//
//  StockExplanation.swift
//  Growfolio
//
//  AI-generated stock explanation model.
//

import Foundation

/// Represents an AI-generated explanation of a stock
struct StockExplanation: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Stock symbol
    let symbol: String

    /// Full explanation text
    let explanation: String

    /// Timestamp when the explanation was generated
    let generatedAt: Date

    // MARK: - Identifiable

    var id: String { symbol }

    // MARK: - Initialization

    init(
        symbol: String,
        explanation: String,
        generatedAt: Date = Date()
    ) {
        self.symbol = symbol
        self.explanation = explanation
        self.generatedAt = generatedAt
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case symbol
        case explanation
        case generatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.explanation = try container.decode(String.self, forKey: .explanation)
        self.generatedAt = (try? container.decode(Date.self, forKey: .generatedAt)) ?? Date()
    }
}

// MARK: - Allocation Suggestion

/// Represents an AI-generated portfolio allocation suggestion
struct AllocationSuggestion: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Suggestion content
    let suggestion: String

    /// Investment amount this suggestion is for
    let investmentAmount: Decimal

    /// Risk tolerance level
    let riskTolerance: RiskTolerance

    /// Time horizon
    let timeHorizon: TimeHorizon

    /// Disclaimer text
    let disclaimer: String

    /// Timestamp when the suggestion was generated
    let generatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        suggestion: String,
        investmentAmount: Decimal,
        riskTolerance: RiskTolerance,
        timeHorizon: TimeHorizon,
        disclaimer: String = "This is educational content only, not financial advice. Please consult a qualified financial advisor.",
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.suggestion = suggestion
        self.investmentAmount = investmentAmount
        self.riskTolerance = riskTolerance
        self.timeHorizon = timeHorizon
        self.disclaimer = disclaimer
        self.generatedAt = generatedAt
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case suggestion
        case investmentAmount
        case riskTolerance
        case timeHorizon
        case disclaimer
        case generatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Provide sensible defaults for all optional fields to handle incomplete API responses
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.suggestion = try container.decode(String.self, forKey: .suggestion)
        self.investmentAmount = (try? container.decode(Decimal.self, forKey: .investmentAmount)) ?? 0
        self.riskTolerance = (try? container.decode(RiskTolerance.self, forKey: .riskTolerance)) ?? .medium
        self.timeHorizon = (try? container.decode(TimeHorizon.self, forKey: .timeHorizon)) ?? .medium
        self.disclaimer = (try? container.decode(String.self, forKey: .disclaimer)) ?? "This is educational content only, not financial advice."
        self.generatedAt = (try? container.decode(Date.self, forKey: .generatedAt)) ?? Date()
    }
}

// MARK: - Risk Tolerance

/// User's risk tolerance level
enum RiskTolerance: String, Codable, Sendable, CaseIterable {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low:
            return "Conservative"
        case .medium:
            return "Moderate"
        case .high:
            return "Aggressive"
        }
    }

    var description: String {
        switch self {
        case .low:
            return "Prioritize capital preservation with lower expected returns"
        case .medium:
            return "Balance between growth and stability"
        case .high:
            return "Maximize growth potential with higher volatility"
        }
    }

    var iconName: String {
        switch self {
        case .low:
            return "shield.fill"
        case .medium:
            return "scale.3d"
        case .high:
            return "bolt.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .low:
            return "#34C759"
        case .medium:
            return "#FF9500"
        case .high:
            return "#FF3B30"
        }
    }
}

// MARK: - Time Horizon

/// Investment time horizon
enum TimeHorizon: String, Codable, Sendable, CaseIterable {
    case short
    case medium
    case long

    var displayName: String {
        switch self {
        case .short:
            return "Short-term"
        case .medium:
            return "Medium-term"
        case .long:
            return "Long-term"
        }
    }

    var description: String {
        switch self {
        case .short:
            return "Less than 3 years"
        case .medium:
            return "3-10 years"
        case .long:
            return "More than 10 years"
        }
    }

    var iconName: String {
        switch self {
        case .short:
            return "clock"
        case .medium:
            return "calendar"
        case .long:
            return "calendar.badge.clock"
        }
    }
}

// MARK: - Allocation Suggestion Response

/// Response model for allocation suggestion API
struct AllocationSuggestionResponse: Codable, Sendable {
    let suggestion: String
    let disclaimer: String

    enum CodingKeys: String, CodingKey {
        case suggestion
        case disclaimer
    }
}
