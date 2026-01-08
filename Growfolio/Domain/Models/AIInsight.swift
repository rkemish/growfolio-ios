//
//  AIInsight.swift
//  Growfolio
//
//  AI-generated insight model for portfolio analysis.
//

import Foundation

/// Represents an AI-generated insight about the portfolio
struct AIInsight: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Insight type/category
    let type: InsightType

    /// Insight title
    let title: String

    /// Detailed content/description
    let content: String

    /// Priority level (higher = more important)
    let priority: InsightPriority

    /// Associated action if any
    let action: InsightAction?

    /// Timestamp when the insight was generated
    let generatedAt: Date

    /// Whether the insight has been dismissed by the user
    var isDismissed: Bool

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        type: InsightType,
        title: String,
        content: String,
        priority: InsightPriority = .medium,
        action: InsightAction? = nil,
        generatedAt: Date = Date(),
        isDismissed: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.priority = priority
        self.action = action
        self.generatedAt = generatedAt
        self.isDismissed = isDismissed
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case content
        case priority
        case action
        case generatedAt
        case isDismissed
    }
}

// MARK: - Insight Type

/// Types of AI insights
enum InsightType: String, Codable, Sendable, CaseIterable {
    case portfolioHealth
    case diversification
    case goalProgress
    case dcaSuggestion
    case marketTrend
    case riskAlert
    case opportunity
    case milestone
    case tip

    var displayName: String {
        switch self {
        case .portfolioHealth:
            return "Portfolio Health"
        case .diversification:
            return "Diversification"
        case .goalProgress:
            return "Goal Progress"
        case .dcaSuggestion:
            return "DCA Suggestion"
        case .marketTrend:
            return "Market Trend"
        case .riskAlert:
            return "Risk Alert"
        case .opportunity:
            return "Opportunity"
        case .milestone:
            return "Milestone"
        case .tip:
            return "Tip"
        }
    }

    var iconName: String {
        switch self {
        case .portfolioHealth:
            return "heart.fill"
        case .diversification:
            return "chart.pie.fill"
        case .goalProgress:
            return "target"
        case .dcaSuggestion:
            return "arrow.triangle.2.circlepath"
        case .marketTrend:
            return "chart.line.uptrend.xyaxis"
        case .riskAlert:
            return "exclamationmark.triangle.fill"
        case .opportunity:
            return "lightbulb.fill"
        case .milestone:
            return "flag.fill"
        case .tip:
            return "sparkles"
        }
    }

    var colorHex: String {
        switch self {
        case .portfolioHealth:
            return "#30D158"
        case .diversification:
            return "#5856D6"
        case .goalProgress:
            return "#007AFF"
        case .dcaSuggestion:
            return "#FF9500"
        case .marketTrend:
            return "#32ADE6"
        case .riskAlert:
            return "#FF3B30"
        case .opportunity:
            return "#FFD60A"
        case .milestone:
            return "#34C759"
        case .tip:
            return "#AF52DE"
        }
    }
}

// MARK: - Insight Priority

/// Priority level for insights
enum InsightPriority: Int, Codable, Sendable, Comparable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4

    static func < (lhs: InsightPriority, rhs: InsightPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }
}

// MARK: - Insight Action

/// Actionable item associated with an insight
struct InsightAction: Codable, Sendable, Equatable {

    /// Action type
    let type: ActionType

    /// Action label text
    let label: String

    /// Optional destination (e.g., goal ID, stock symbol)
    let destination: String?

    enum ActionType: String, Codable, Sendable {
        case viewGoal
        case createGoal
        case setupDCA
        case viewStock
        case viewPortfolio
        case learnMore
        case dismiss
    }
}

// MARK: - Portfolio Insights Response

/// Response model for portfolio insights API
struct PortfolioInsightsResponse: Codable, Sendable {

    /// List of insights
    let insights: [AIInsight]

    /// Timestamp when insights were generated
    let generatedAt: Date

    /// Overall portfolio health score (0-100)
    let healthScore: Int?

    /// Summary text
    let summary: String?

    enum CodingKeys: String, CodingKey {
        case insights
        case generatedAt
        case healthScore
        case summary
    }

    init(
        insights: [AIInsight],
        generatedAt: Date = Date(),
        healthScore: Int? = nil,
        summary: String? = nil
    ) {
        self.insights = insights
        self.generatedAt = generatedAt
        self.healthScore = healthScore
        self.summary = summary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try to decode insights as structured data first
        if let structuredInsights = try? container.decode([AIInsight].self, forKey: .insights) {
            self.insights = structuredInsights
        } else if let insightString = try? container.decode(String.self, forKey: .insights) {
            // Fallback: Backend may return a plain string instead of structured insights
            // Wrap the string into a generic portfolio health insight for graceful handling
            self.insights = [
                AIInsight(
                    type: .portfolioHealth,
                    title: "Portfolio Analysis",
                    content: insightString,
                    priority: .medium
                )
            ]
        } else {
            // No insights data available - return empty array to avoid decoding failure
            self.insights = []
        }

        // Use current date as fallback if generatedAt is missing
        self.generatedAt = (try? container.decode(Date.self, forKey: .generatedAt)) ?? Date()
        self.healthScore = try? container.decode(Int.self, forKey: .healthScore)
        self.summary = try? container.decode(String.self, forKey: .summary)
    }
}

// MARK: - Investing Tip

/// Represents an investing tip
struct InvestingTip: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    let id: String
    let title: String
    let content: String
    let category: TipCategory?

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        category: TipCategory? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Generate a UUID if the backend doesn't provide an ID
        self.id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        // Category is optional - backend may not categorize all tips
        self.category = try? container.decode(TipCategory.self, forKey: .category)
    }
}

// MARK: - Tip Category

enum TipCategory: String, Codable, Sendable {
    case dca
    case diversification
    case longTerm
    case fees
    case automation
    case risk
    case general

    var iconName: String {
        switch self {
        case .dca:
            return "arrow.triangle.2.circlepath"
        case .diversification:
            return "chart.pie"
        case .longTerm:
            return "calendar"
        case .fees:
            return "dollarsign.circle"
        case .automation:
            return "gear"
        case .risk:
            return "exclamationmark.shield"
        case .general:
            return "lightbulb"
        }
    }

    var colorHex: String {
        switch self {
        case .dca:
            return "#FF9500"
        case .diversification:
            return "#5856D6"
        case .longTerm:
            return "#007AFF"
        case .fees:
            return "#34C759"
        case .automation:
            return "#32ADE6"
        case .risk:
            return "#FF3B30"
        case .general:
            return "#AF52DE"
        }
    }
}

// MARK: - Tips Response

/// Response model for investing tips API
struct InvestingTipsResponse: Codable, Sendable {
    let tips: [InvestingTip]
}
