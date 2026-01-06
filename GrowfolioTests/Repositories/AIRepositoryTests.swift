//
//  AIRepositoryTests.swift
//  GrowfolioTests
//
//  Tests for AIRepository.
//

import XCTest
@testable import Growfolio

final class AIRepositoryTests: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var sut: AIRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = AIRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        mockAPIClient.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeChatMessage(
        role: MessageRole = .assistant,
        content: String = "This is a test response."
    ) -> ChatMessage {
        ChatMessage(role: role, content: content)
    }

    private func makeAIChatResponse(
        message: String = "This is the AI response.",
        suggestedActions: [String]? = nil
    ) -> AIChatResponse {
        AIChatResponse(
            message: message,
            suggestedActions: suggestedActions
        )
    }

    private func makeInsight(
        id: String = "insight-1",
        type: InsightType = .portfolioHealth,
        title: String = "Portfolio Looking Healthy",
        content: String = "Your portfolio is well diversified."
    ) -> AIInsight {
        AIInsight(
            id: id,
            type: type,
            title: title,
            content: content,
            priority: .medium
        )
    }

    private func makePortfolioInsightsResponse(
        insights: [AIInsight] = [],
        healthScore: Int? = 85
    ) -> PortfolioInsightsResponse {
        // Create a mock response by encoding and decoding
        let json: [String: Any] = [
            "insights": insights.map { [
                "id": $0.id,
                "type": $0.type.rawValue,
                "title": $0.title,
                "content": $0.content,
                "priority": $0.priority.rawValue,
                "generatedAt": ISO8601DateFormatter().string(from: $0.generatedAt),
                "isDismissed": $0.isDismissed
            ] },
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "healthScore": healthScore ?? NSNull(),
            "summary": "Your portfolio summary"
        ]

        let data = try! JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return try! decoder.decode(PortfolioInsightsResponse.self, from: data)
    }

    private func makeStockExplanation(
        symbol: String = "AAPL",
        explanation: String = "Apple Inc. is a technology company..."
    ) -> StockExplanation {
        StockExplanation(
            symbol: symbol,
            explanation: explanation
        )
    }

    private func makeAllocationSuggestionResponse(
        suggestion: String = "Based on your profile...",
        disclaimer: String = "This is not financial advice."
    ) -> AllocationSuggestionResponse {
        AllocationSuggestionResponse(
            suggestion: suggestion,
            disclaimer: disclaimer
        )
    }

    private func makeInvestingTip(
        id: String = "tip-1",
        title: String = "Diversification",
        content: String = "Diversifying your portfolio helps reduce risk."
    ) -> InvestingTip {
        InvestingTip(
            id: id,
            title: title,
            content: content,
            category: .diversification
        )
    }

    // MARK: - Send Message Tests

    func test_sendMessage_returnsAssistantMessage() async throws {
        // Arrange
        let response = makeAIChatResponse(message: "Hello! How can I help you today?")
        mockAPIClient.setResponse(response, for: Endpoints.AIChat.self)

        // Act
        let result = try await sut.sendMessage(
            "Hello",
            conversationHistory: [],
            includePortfolioContext: false
        )

        // Assert
        XCTAssertEqual(result.role, .assistant)
        XCTAssertEqual(result.content, "Hello! How can I help you today?")
    }

    func test_sendMessage_includesSuggestedActions() async throws {
        // Arrange
        let response = makeAIChatResponse(
            message: "Here are some options:",
            suggestedActions: ["View Portfolio", "Create Goal", "Set up DCA"]
        )
        mockAPIClient.setResponse(response, for: Endpoints.AIChat.self)

        // Act
        let result = try await sut.sendMessage(
            "What can I do?",
            conversationHistory: [],
            includePortfolioContext: false
        )

        // Assert
        XCTAssertNotNil(result.suggestedActions)
        XCTAssertEqual(result.suggestedActions?.count, 3)
    }

    func test_sendMessage_passesConversationHistory() async throws {
        // Arrange
        let history = [
            makeChatMessage(role: .user, content: "Hello"),
            makeChatMessage(role: .assistant, content: "Hi there!")
        ]
        let response = makeAIChatResponse(message: "How can I help?")
        mockAPIClient.setResponse(response, for: Endpoints.AIChat.self)

        // Act
        _ = try await sut.sendMessage(
            "What's my portfolio worth?",
            conversationHistory: history,
            includePortfolioContext: true
        )

        // Assert
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_sendMessage_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "AI service unavailable"), for: Endpoints.AIChat.self)

        // Act & Assert
        do {
            _ = try await sut.sendMessage(
                "Hello",
                conversationHistory: [],
                includePortfolioContext: false
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Fetch Insights Tests

    func test_fetchInsights_returnsInsightsFromAPI() async throws {
        // Arrange
        let insights = [
            makeInsight(id: "i1", type: .portfolioHealth),
            makeInsight(id: "i2", type: .diversification)
        ]
        let response = makePortfolioInsightsResponse(insights: insights)
        mockAPIClient.setResponse(response, for: Endpoints.GetPortfolioInsights.self)

        // Act
        let result = try await sut.fetchInsights(includeGoals: true)

        // Assert
        XCTAssertEqual(result.insights.count, 2)
    }

    func test_fetchInsights_usesCache() async throws {
        // Arrange
        let insights = [makeInsight()]
        let response = makePortfolioInsightsResponse(insights: insights)
        mockAPIClient.setResponse(response, for: Endpoints.GetPortfolioInsights.self)

        // Act - First call populates cache
        _ = try await sut.fetchInsights(includeGoals: true)

        // Act - Second call should use cache (within 5 minutes)
        let result = try await sut.fetchInsights(includeGoals: true)

        // Assert
        XCTAssertEqual(result.insights.count, 1)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchInsights_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Error"), for: Endpoints.GetPortfolioInsights.self)

        // Act & Assert
        do {
            _ = try await sut.fetchInsights(includeGoals: false)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Fetch Stock Explanation Tests

    func test_fetchStockExplanation_returnsExplanationFromAPI() async throws {
        // Arrange
        let explanation = makeStockExplanation(symbol: "AAPL")
        mockAPIClient.setResponse(explanation, for: Endpoints.GetStockExplanation.self)

        // Act
        let result = try await sut.fetchStockExplanation(symbol: "AAPL")

        // Assert
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertFalse(result.explanation.isEmpty)
    }

    func test_fetchStockExplanation_usesCache() async throws {
        // Arrange
        let explanation = makeStockExplanation(symbol: "AAPL")
        mockAPIClient.setResponse(explanation, for: Endpoints.GetStockExplanation.self)

        // Act - First call populates cache
        _ = try await sut.fetchStockExplanation(symbol: "AAPL")

        // Act - Second call should use cache
        let result = try await sut.fetchStockExplanation(symbol: "AAPL")

        // Assert
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchStockExplanation_convertsToUppercase() async throws {
        // Arrange
        let explanation = makeStockExplanation(symbol: "AAPL")
        mockAPIClient.setResponse(explanation, for: Endpoints.GetStockExplanation.self)

        // Act
        _ = try await sut.fetchStockExplanation(symbol: "aapl")

        // Assert - Should normalize to uppercase and cache
        mockAPIClient.reset()
        let result = try await sut.fetchStockExplanation(symbol: "AAPL")
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    func test_fetchStockExplanation_cachesBySymbol() async throws {
        // Arrange
        let appleExplanation = makeStockExplanation(symbol: "AAPL")
        let googleExplanation = makeStockExplanation(symbol: "GOOGL")
        mockAPIClient.setResponse(appleExplanation, for: Endpoints.GetStockExplanation.self)

        // Act - Fetch AAPL
        _ = try await sut.fetchStockExplanation(symbol: "AAPL")

        // Set up GOOGL response
        mockAPIClient.setResponse(googleExplanation, for: Endpoints.GetStockExplanation.self)

        // Act - Fetch GOOGL (should make new request)
        let googleResult = try await sut.fetchStockExplanation(symbol: "GOOGL")

        // Assert
        XCTAssertEqual(googleResult.symbol, "GOOGL")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 2)
    }

    // MARK: - Fetch Allocation Suggestion Tests

    func test_fetchAllocationSuggestion_returnsSuggestion() async throws {
        // Arrange
        let response = makeAllocationSuggestionResponse(
            suggestion: "Consider a 60/40 portfolio split."
        )
        mockAPIClient.setResponse(response, for: Endpoints.SuggestAllocation.self)

        // Act
        let result = try await sut.fetchAllocationSuggestion(
            investmentAmount: 10000,
            riskTolerance: .medium,
            timeHorizon: .long
        )

        // Assert
        XCTAssertEqual(result.investmentAmount, 10000)
        XCTAssertEqual(result.riskTolerance, .medium)
        XCTAssertEqual(result.timeHorizon, .long)
        XCTAssertFalse(result.suggestion.isEmpty)
        XCTAssertFalse(result.disclaimer.isEmpty)
    }

    func test_fetchAllocationSuggestion_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Error"), for: Endpoints.SuggestAllocation.self)

        // Act & Assert
        do {
            _ = try await sut.fetchAllocationSuggestion(
                investmentAmount: 1000,
                riskTolerance: .low,
                timeHorizon: .short
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Fetch Investing Tips Tests

    func test_fetchInvestingTips_returnsTipsFromAPI() async throws {
        // Arrange
        let tips = [
            makeInvestingTip(id: "tip-1", title: "Tip 1"),
            makeInvestingTip(id: "tip-2", title: "Tip 2"),
            makeInvestingTip(id: "tip-3", title: "Tip 3")
        ]
        let response = InvestingTipsResponse(tips: tips)
        mockAPIClient.setResponse(response, for: Endpoints.GetInvestingTips.self)

        // Act
        let result = try await sut.fetchInvestingTips()

        // Assert
        XCTAssertEqual(result.count, 3)
    }

    func test_fetchInvestingTips_usesCache() async throws {
        // Arrange
        let tips = [makeInvestingTip()]
        let response = InvestingTipsResponse(tips: tips)
        mockAPIClient.setResponse(response, for: Endpoints.GetInvestingTips.self)

        // Act - First call populates cache
        _ = try await sut.fetchInvestingTips()

        // Act - Second call should use cache (within 1 hour)
        let result = try await sut.fetchInvestingTips()

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchInvestingTips_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Error"), for: Endpoints.GetInvestingTips.self)

        // Act & Assert
        do {
            _ = try await sut.fetchInvestingTips()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Cache Management Tests

    func test_clearCache_clearsAllCachedData() async throws {
        // Arrange - Populate caches
        let insights = [makeInsight()]
        let insightsResponse = makePortfolioInsightsResponse(insights: insights)
        mockAPIClient.setResponse(insightsResponse, for: Endpoints.GetPortfolioInsights.self)
        _ = try await sut.fetchInsights(includeGoals: true)

        let explanation = makeStockExplanation()
        mockAPIClient.setResponse(explanation, for: Endpoints.GetStockExplanation.self)
        _ = try await sut.fetchStockExplanation(symbol: "AAPL")

        let tips = [makeInvestingTip()]
        let tipsResponse = InvestingTipsResponse(tips: tips)
        mockAPIClient.setResponse(tipsResponse, for: Endpoints.GetInvestingTips.self)
        _ = try await sut.fetchInvestingTips()

        // Act
        sut.clearCache()

        // Reset and set up new responses
        mockAPIClient.reset()
        let newInsights = [makeInsight(id: "new-insight")]
        let newInsightsResponse = makePortfolioInsightsResponse(insights: newInsights)
        mockAPIClient.setResponse(newInsightsResponse, for: Endpoints.GetPortfolioInsights.self)

        // Assert - New API call should be made
        let fetchedInsights = try await sut.fetchInsights(includeGoals: true)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_clearInsightsCache_clearsOnlyInsightsCache() async throws {
        // Arrange - Populate caches
        let insights = [makeInsight()]
        let insightsResponse = makePortfolioInsightsResponse(insights: insights)
        mockAPIClient.setResponse(insightsResponse, for: Endpoints.GetPortfolioInsights.self)
        _ = try await sut.fetchInsights(includeGoals: true)

        let explanation = makeStockExplanation()
        mockAPIClient.setResponse(explanation, for: Endpoints.GetStockExplanation.self)
        _ = try await sut.fetchStockExplanation(symbol: "AAPL")

        // Act
        sut.clearInsightsCache()

        // Assert - Stock explanation should still be cached
        mockAPIClient.reset()
        let cachedExplanation = try await sut.fetchStockExplanation(symbol: "AAPL")
        XCTAssertEqual(cachedExplanation.symbol, "AAPL")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    // MARK: - Empty Response Tests

    func test_fetchInsights_returnsEmptyArrayWhenNoInsights() async throws {
        // Arrange
        let response = makePortfolioInsightsResponse(insights: [])
        mockAPIClient.setResponse(response, for: Endpoints.GetPortfolioInsights.self)

        // Act
        let result = try await sut.fetchInsights(includeGoals: true)

        // Assert
        XCTAssertTrue(result.insights.isEmpty)
    }

    func test_fetchInvestingTips_returnsEmptyArrayWhenNoTips() async throws {
        // Arrange
        let response = InvestingTipsResponse(tips: [])
        mockAPIClient.setResponse(response, for: Endpoints.GetInvestingTips.self)

        // Act
        let result = try await sut.fetchInvestingTips()

        // Assert
        XCTAssertTrue(result.isEmpty)
    }
}
