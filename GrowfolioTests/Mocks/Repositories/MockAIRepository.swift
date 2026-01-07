//
//  MockAIRepository.swift
//  GrowfolioTests
//
//  Mock AI repository for testing.
//

import Foundation
@testable import Growfolio

/// Mock AI repository that returns predefined responses for testing
final class MockAIRepository: AIRepositoryProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    var chatMessageToReturn: ChatMessage?
    var insightsToReturn: PortfolioInsightsResponse?
    var stockExplanationToReturn: StockExplanation?
    var allocationSuggestionToReturn: AllocationSuggestion?
    var investingTipsToReturn: [InvestingTip] = []
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var sendMessageCalled = false
    var lastSentMessage: String?
    var lastConversationHistory: [ChatMessage]?
    var lastIncludePortfolioContext: Bool?
    var fetchInsightsCalled = false
    var lastFetchInsightsIncludeGoals: Bool?
    var fetchStockExplanationCalled = false
    var lastFetchStockExplanationSymbol: String?
    var fetchAllocationSuggestionCalled = false
    var lastAllocationInvestmentAmount: Decimal?
    var lastAllocationRiskTolerance: RiskTolerance?
    var lastAllocationTimeHorizon: TimeHorizon?
    var fetchInvestingTipsCalled = false
    var getAIInsightsCalled = false
    var getGoalInsightsCalled = false
    var lastGoalInsightsGoalId: String?

    // MARK: - Reset

    func reset() {
        chatMessageToReturn = nil
        insightsToReturn = nil
        stockExplanationToReturn = nil
        allocationSuggestionToReturn = nil
        investingTipsToReturn = []
        errorToThrow = nil

        sendMessageCalled = false
        lastSentMessage = nil
        lastConversationHistory = nil
        lastIncludePortfolioContext = nil
        fetchInsightsCalled = false
        lastFetchInsightsIncludeGoals = nil
        fetchStockExplanationCalled = false
        lastFetchStockExplanationSymbol = nil
        fetchAllocationSuggestionCalled = false
        lastAllocationInvestmentAmount = nil
        lastAllocationRiskTolerance = nil
        lastAllocationTimeHorizon = nil
        fetchInvestingTipsCalled = false
        getAIInsightsCalled = false
        getGoalInsightsCalled = false
        lastGoalInsightsGoalId = nil
    }

    // MARK: - AIRepositoryProtocol Implementation

    func sendMessage(
        _ message: String,
        conversationHistory: [ChatMessage],
        includePortfolioContext: Bool
    ) async throws -> ChatMessage {
        sendMessageCalled = true
        lastSentMessage = message
        lastConversationHistory = conversationHistory
        lastIncludePortfolioContext = includePortfolioContext
        if let error = errorToThrow { throw error }
        if let chatMessage = chatMessageToReturn { return chatMessage }
        return ChatMessage.assistant(
            "This is a mock AI response to: \(message)",
            suggestedActions: nil
        )
    }

    func fetchInsights(includeGoals: Bool) async throws -> PortfolioInsightsResponse {
        fetchInsightsCalled = true
        lastFetchInsightsIncludeGoals = includeGoals
        if let error = errorToThrow { throw error }
        if let insights = insightsToReturn { return insights }
        return PortfolioInsightsResponse(
            insights: [
                AIInsight(
                    id: UUID().uuidString,
                    type: .diversification,
                    title: "Mock Insight",
                    content: "This is a mock insight for testing.",
                    priority: .medium
                )
            ],
            generatedAt: Date()
        )
    }

    func fetchStockExplanation(symbol: String) async throws -> StockExplanation {
        fetchStockExplanationCalled = true
        lastFetchStockExplanationSymbol = symbol
        if let error = errorToThrow { throw error }
        if let explanation = stockExplanationToReturn { return explanation }
        return StockExplanation(
            symbol: symbol,
            explanation: "This is a mock explanation for \(symbol).",
            generatedAt: Date()
        )
    }

    func fetchAllocationSuggestion(
        investmentAmount: Decimal,
        riskTolerance: RiskTolerance,
        timeHorizon: TimeHorizon
    ) async throws -> AllocationSuggestion {
        fetchAllocationSuggestionCalled = true
        lastAllocationInvestmentAmount = investmentAmount
        lastAllocationRiskTolerance = riskTolerance
        lastAllocationTimeHorizon = timeHorizon
        if let error = errorToThrow { throw error }
        if let suggestion = allocationSuggestionToReturn { return suggestion }
        return AllocationSuggestion(
            suggestion: "This is a mock allocation suggestion based on your \(riskTolerance) risk tolerance and \(timeHorizon) time horizon.",
            investmentAmount: investmentAmount,
            riskTolerance: riskTolerance,
            timeHorizon: timeHorizon,
            disclaimer: "This is a mock disclaimer. Not financial advice."
        )
    }

    func fetchInvestingTips() async throws -> [InvestingTip] {
        fetchInvestingTipsCalled = true
        if let error = errorToThrow { throw error }
        if !investingTipsToReturn.isEmpty { return investingTipsToReturn }
        return [
            InvestingTip(
                id: UUID().uuidString,
                title: "Mock Investing Tip",
                content: "This is a mock investing tip for testing purposes.",
                category: .general
            )
        ]
    }

    func getAIInsights() async throws -> PortfolioInsightsResponse {
        getAIInsightsCalled = true
        if let error = errorToThrow { throw error }
        if let insights = insightsToReturn { return insights }
        return PortfolioInsightsResponse(
            insights: [
                AIInsight(
                    id: UUID().uuidString,
                    type: .portfolioHealth,
                    title: "Mock AI Insight",
                    content: "This is a mock AI insight.",
                    priority: .medium
                )
            ],
            generatedAt: Date()
        )
    }

    func getGoalInsights(goalId: String) async throws -> PortfolioInsightsResponse {
        getGoalInsightsCalled = true
        lastGoalInsightsGoalId = goalId
        if let error = errorToThrow { throw error }
        if let insights = insightsToReturn { return insights }
        return PortfolioInsightsResponse(
            insights: [
                AIInsight(
                    id: UUID().uuidString,
                    type: .goalProgress,
                    title: "Mock Goal Insight",
                    content: "This is a mock goal insight for goal \(goalId).",
                    priority: .medium
                )
            ],
            generatedAt: Date()
        )
    }
}
