//
//  AIInsightTests.swift
//  GrowfolioTests
//
//  Tests for AIInsight domain model.
//

import XCTest
@testable import Growfolio

final class AIInsightTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithDefaults() {
        let insight = AIInsight(
            type: .portfolioHealth,
            title: "Test Title",
            content: "Test Content"
        )

        XCTAssertFalse(insight.id.isEmpty)
        XCTAssertEqual(insight.type, .portfolioHealth)
        XCTAssertEqual(insight.title, "Test Title")
        XCTAssertEqual(insight.content, "Test Content")
        XCTAssertEqual(insight.priority, .medium)
        XCTAssertNil(insight.action)
        XCTAssertFalse(insight.isDismissed)
    }

    func testInit_WithAllParameters() {
        let action = InsightAction(type: .viewGoal, label: "View Goal", destination: "goal-123")
        let insight = TestFixtures.aiInsight(
            id: "insight-456",
            type: .riskAlert,
            title: "Risk Alert",
            content: "High concentration detected",
            priority: .high,
            action: action,
            isDismissed: true
        )

        XCTAssertEqual(insight.id, "insight-456")
        XCTAssertEqual(insight.type, .riskAlert)
        XCTAssertEqual(insight.title, "Risk Alert")
        XCTAssertEqual(insight.content, "High concentration detected")
        XCTAssertEqual(insight.priority, .high)
        XCTAssertEqual(insight.action?.type, .viewGoal)
        XCTAssertEqual(insight.action?.label, "View Goal")
        XCTAssertEqual(insight.action?.destination, "goal-123")
        XCTAssertTrue(insight.isDismissed)
    }

    // MARK: - InsightType Tests

    func testInsightType_DisplayName() {
        XCTAssertEqual(InsightType.portfolioHealth.displayName, "Portfolio Health")
        XCTAssertEqual(InsightType.diversification.displayName, "Diversification")
        XCTAssertEqual(InsightType.goalProgress.displayName, "Goal Progress")
        XCTAssertEqual(InsightType.dcaSuggestion.displayName, "DCA Suggestion")
        XCTAssertEqual(InsightType.marketTrend.displayName, "Market Trend")
        XCTAssertEqual(InsightType.riskAlert.displayName, "Risk Alert")
        XCTAssertEqual(InsightType.opportunity.displayName, "Opportunity")
        XCTAssertEqual(InsightType.milestone.displayName, "Milestone")
        XCTAssertEqual(InsightType.tip.displayName, "Tip")
    }

    func testInsightType_IconName_NotEmpty() {
        for type in InsightType.allCases {
            XCTAssertFalse(type.iconName.isEmpty, "Icon name for \(type) should not be empty")
        }
    }

    func testInsightType_ColorHex_ValidFormat() {
        for type in InsightType.allCases {
            XCTAssertTrue(type.colorHex.hasPrefix("#"), "Color hex for \(type) should start with #")
            XCTAssertEqual(type.colorHex.count, 7, "Color hex for \(type) should be 7 characters")
        }
    }

    func testInsightType_AllCases() {
        XCTAssertEqual(InsightType.allCases.count, 9)
    }

    // MARK: - InsightPriority Tests

    func testInsightPriority_RawValues() {
        XCTAssertEqual(InsightPriority.low.rawValue, 1)
        XCTAssertEqual(InsightPriority.medium.rawValue, 2)
        XCTAssertEqual(InsightPriority.high.rawValue, 3)
        XCTAssertEqual(InsightPriority.critical.rawValue, 4)
    }

    func testInsightPriority_DisplayName() {
        XCTAssertEqual(InsightPriority.low.displayName, "Low")
        XCTAssertEqual(InsightPriority.medium.displayName, "Medium")
        XCTAssertEqual(InsightPriority.high.displayName, "High")
        XCTAssertEqual(InsightPriority.critical.displayName, "Critical")
    }

    func testInsightPriority_Comparable() {
        XCTAssertTrue(InsightPriority.low < InsightPriority.medium)
        XCTAssertTrue(InsightPriority.medium < InsightPriority.high)
        XCTAssertTrue(InsightPriority.high < InsightPriority.critical)
        XCTAssertFalse(InsightPriority.critical < InsightPriority.low)
    }

    func testInsightPriority_Sorting() {
        let priorities: [InsightPriority] = [.high, .low, .critical, .medium]
        let sorted = priorities.sorted()

        XCTAssertEqual(sorted, [.low, .medium, .high, .critical])
    }

    // MARK: - InsightAction Tests

    func testInsightAction_AllActionTypes() {
        let actionTypes: [InsightAction.ActionType] = [
            .viewGoal,
            .createGoal,
            .setupDCA,
            .viewStock,
            .viewPortfolio,
            .learnMore,
            .dismiss
        ]

        for actionType in actionTypes {
            let action = InsightAction(type: actionType, label: "Test", destination: nil)
            XCTAssertEqual(action.type, actionType)
        }
    }

    func testInsightAction_WithDestination() {
        let action = InsightAction(type: .viewStock, label: "View AAPL", destination: "AAPL")

        XCTAssertEqual(action.type, .viewStock)
        XCTAssertEqual(action.label, "View AAPL")
        XCTAssertEqual(action.destination, "AAPL")
    }

    func testInsightAction_WithoutDestination() {
        let action = InsightAction(type: .learnMore, label: "Learn More", destination: nil)

        XCTAssertEqual(action.type, .learnMore)
        XCTAssertEqual(action.label, "Learn More")
        XCTAssertNil(action.destination)
    }

    func testInsightAction_Equatable() {
        let action1 = InsightAction(type: .viewGoal, label: "View", destination: "goal-1")
        let action2 = InsightAction(type: .viewGoal, label: "View", destination: "goal-1")
        let action3 = InsightAction(type: .viewGoal, label: "View", destination: "goal-2")

        XCTAssertEqual(action1, action2)
        XCTAssertNotEqual(action1, action3)
    }

    // MARK: - isDismissed Mutation Tests

    func testIsDismissed_Mutable() {
        var insight = TestFixtures.aiInsight(isDismissed: false)

        XCTAssertFalse(insight.isDismissed)

        insight.isDismissed = true

        XCTAssertTrue(insight.isDismissed)
    }

    // MARK: - Codable Tests

    func testAIInsight_EncodeDecode_RoundTrip() throws {
        let action = InsightAction(type: .setupDCA, label: "Set Up DCA", destination: "VOO")
        let original = TestFixtures.aiInsight(
            id: "insight-test",
            type: .dcaSuggestion,
            title: "Start DCA",
            content: "Consider setting up DCA for VOO",
            priority: .medium,
            action: action,
            isDismissed: false
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(AIInsight.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.priority, original.priority)
        XCTAssertEqual(decoded.action, original.action)
        XCTAssertEqual(decoded.isDismissed, original.isDismissed)
    }

    func testAIInsight_EncodeDecode_WithNilAction() throws {
        let original = TestFixtures.aiInsight(action: nil)

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(AIInsight.self, from: data)

        XCTAssertNil(decoded.action)
    }

    func testInsightType_Codable() throws {
        for type in InsightType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(InsightType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    func testInsightPriority_Codable() throws {
        let priorities: [InsightPriority] = [.low, .medium, .high, .critical]
        for priority in priorities {
            let data = try JSONEncoder().encode(priority)
            let decoded = try JSONDecoder().decode(InsightPriority.self, from: data)
            XCTAssertEqual(decoded, priority)
        }
    }

    func testInsightAction_Codable() throws {
        let original = InsightAction(type: .viewPortfolio, label: "View Portfolio", destination: "portfolio-123")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(InsightAction.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Equatable Tests

    func testAIInsight_Equatable() {
        let insight1 = TestFixtures.aiInsight(id: "insight-1", title: "Test")
        let insight2 = TestFixtures.aiInsight(id: "insight-1", title: "Test")
        let insight3 = TestFixtures.aiInsight(id: "insight-2", title: "Different")

        XCTAssertEqual(insight1, insight2)
        XCTAssertNotEqual(insight1, insight3)
    }

    // MARK: - PortfolioInsightsResponse Tests

    func testPortfolioInsightsResponse_Initialization() {
        let insights = TestFixtures.sampleInsights
        let response = PortfolioInsightsResponse(
            insights: insights,
            healthScore: 85,
            summary: "Your portfolio is healthy"
        )

        XCTAssertEqual(response.insights.count, 3)
        XCTAssertEqual(response.healthScore, 85)
        XCTAssertEqual(response.summary, "Your portfolio is healthy")
    }

    func testPortfolioInsightsResponse_WithNilOptionals() {
        let response = PortfolioInsightsResponse(insights: [])

        XCTAssertTrue(response.insights.isEmpty)
        XCTAssertNil(response.healthScore)
        XCTAssertNil(response.summary)
    }

    // MARK: - InvestingTip Tests

    func testInvestingTip_Initialization() {
        let tip = InvestingTip(
            id: "tip-1",
            title: "Dollar Cost Averaging",
            content: "Invest regularly to reduce timing risk",
            category: .dca
        )

        XCTAssertEqual(tip.id, "tip-1")
        XCTAssertEqual(tip.title, "Dollar Cost Averaging")
        XCTAssertEqual(tip.content, "Invest regularly to reduce timing risk")
        XCTAssertEqual(tip.category, .dca)
    }

    func testInvestingTip_WithNilCategory() {
        let tip = InvestingTip(
            title: "General Tip",
            content: "Some general advice"
        )

        XCTAssertFalse(tip.id.isEmpty)
        XCTAssertNil(tip.category)
    }

    // MARK: - TipCategory Tests

    func testTipCategory_IconName_NotEmpty() {
        let categories: [TipCategory] = [.dca, .diversification, .longTerm, .fees, .automation, .risk, .general]
        for category in categories {
            XCTAssertFalse(category.iconName.isEmpty, "Icon name for \(category) should not be empty")
        }
    }

    func testTipCategory_ColorHex_ValidFormat() {
        let categories: [TipCategory] = [.dca, .diversification, .longTerm, .fees, .automation, .risk, .general]
        for category in categories {
            XCTAssertTrue(category.colorHex.hasPrefix("#"), "Color hex for \(category) should start with #")
            XCTAssertEqual(category.colorHex.count, 7, "Color hex for \(category) should be 7 characters")
        }
    }

    // MARK: - Edge Cases

    func testAIInsight_EmptyContent() {
        let insight = TestFixtures.aiInsight(content: "")

        XCTAssertTrue(insight.content.isEmpty)
    }

    func testAIInsight_LongContent() {
        let longContent = String(repeating: "A", count: 10000)
        let insight = TestFixtures.aiInsight(content: longContent)

        XCTAssertEqual(insight.content.count, 10000)
    }

    func testAIInsight_SpecialCharactersInContent() {
        let specialContent = "Test with special chars: <>&\"' and unicode: ..."
        let insight = TestFixtures.aiInsight(content: specialContent)

        XCTAssertEqual(insight.content, specialContent)
    }
}
