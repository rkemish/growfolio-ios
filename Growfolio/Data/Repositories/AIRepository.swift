//
//  AIRepository.swift
//  Growfolio
//
//  Repository for AI-related API calls.
//

import Foundation

// MARK: - AI Repository Protocol

/// Protocol defining the AI repository interface
protocol AIRepositoryProtocol: Sendable {

    /// Send a chat message and get AI response
    func sendMessage(
        _ message: String,
        conversationHistory: [ChatMessage],
        includePortfolioContext: Bool
    ) async throws -> ChatMessage

    /// Get portfolio insights
    func fetchInsights(includeGoals: Bool) async throws -> PortfolioInsightsResponse

    /// Get AI explanation for a stock
    func fetchStockExplanation(symbol: String) async throws -> StockExplanation

    /// Get allocation suggestion
    func fetchAllocationSuggestion(
        investmentAmount: Decimal,
        riskTolerance: RiskTolerance,
        timeHorizon: TimeHorizon
    ) async throws -> AllocationSuggestion

    /// Get investing tips
    func fetchInvestingTips() async throws -> [InvestingTip]

    /// Get AI insights for the user's portfolio
    func getAIInsights() async throws -> PortfolioInsightsResponse

    /// Get AI insights for a specific goal
    func getGoalInsights(goalId: String) async throws -> PortfolioInsightsResponse
}

// MARK: - AI Repository Implementation

/// Implementation of the AI repository using the API client
final class AIRepository: AIRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let apiClient: APIClientProtocol

    // Cache
    private var cachedInsights: PortfolioInsightsResponse?
    private var cachedInsightsTime: Date?
    private var cachedTips: [InvestingTip]?
    private var cachedTipsTime: Date?
    private var stockExplanationCache: [String: StockExplanation] = [:]

    private let insightsCacheDuration: TimeInterval = 300 // 5 minutes
    private let tipsCacheDuration: TimeInterval = 3600 // 1 hour

    // MARK: - Initialization

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - Chat

    func sendMessage(
        _ message: String,
        conversationHistory: [ChatMessage],
        includePortfolioContext: Bool
    ) async throws -> ChatMessage {
        // Convert conversation history to API format
        let historyDTO: [AIChatMessageDTO]? = conversationHistory.isEmpty ? nil : conversationHistory.map { msg in
            AIChatMessageDTO(role: msg.role.rawValue, content: msg.content)
        }

        let request = AIChatRequest(
            message: message,
            conversationHistory: historyDTO,
            includePortfolioContext: includePortfolioContext
        )

        let response: AIChatResponse = try await apiClient.request(
            try Endpoints.AIChat(request: request)
        )

        return ChatMessage.assistant(
            response.message,
            suggestedActions: response.suggestedActions
        )
    }

    // MARK: - Insights

    func fetchInsights(includeGoals: Bool) async throws -> PortfolioInsightsResponse {
        // Check cache
        if let cached = cachedInsights,
           let cacheTime = cachedInsightsTime,
           Date().timeIntervalSince(cacheTime) < insightsCacheDuration {
            return cached
        }

        let response: PortfolioInsightsResponse = try await apiClient.request(
            Endpoints.GetPortfolioInsights(includeGoals: includeGoals)
        )

        // Update cache
        cachedInsights = response
        cachedInsightsTime = Date()

        return response
    }

    // MARK: - Stock Explanation

    func fetchStockExplanation(symbol: String) async throws -> StockExplanation {
        let upperSymbol = symbol.uppercased()

        // Check cache
        if let cached = stockExplanationCache[upperSymbol] {
            return cached
        }

        let response: StockExplanation = try await apiClient.request(
            Endpoints.GetStockExplanation(symbol: upperSymbol)
        )

        // Update cache
        stockExplanationCache[upperSymbol] = response

        return response
    }

    // MARK: - Allocation Suggestion

    func fetchAllocationSuggestion(
        investmentAmount: Decimal,
        riskTolerance: RiskTolerance,
        timeHorizon: TimeHorizon
    ) async throws -> AllocationSuggestion {
        let request = AllocationRequest(
            investmentAmount: investmentAmount,
            riskTolerance: riskTolerance,
            timeHorizon: timeHorizon
        )

        let response: AllocationSuggestionResponse = try await apiClient.request(
            try Endpoints.SuggestAllocation(request: request)
        )

        return AllocationSuggestion(
            suggestion: response.suggestion,
            investmentAmount: investmentAmount,
            riskTolerance: riskTolerance,
            timeHorizon: timeHorizon,
            disclaimer: response.disclaimer
        )
    }

    // MARK: - Investing Tips

    func fetchInvestingTips() async throws -> [InvestingTip] {
        // Check cache
        if let cached = cachedTips,
           let cacheTime = cachedTipsTime,
           Date().timeIntervalSince(cacheTime) < tipsCacheDuration {
            return cached
        }

        let response: InvestingTipsResponse = try await apiClient.request(
            Endpoints.GetInvestingTips()
        )

        // Update cache
        cachedTips = response.tips
        cachedTipsTime = Date()

        return response.tips
    }

    // MARK: - AI Insights

    func getAIInsights() async throws -> PortfolioInsightsResponse {
        return try await apiClient.request(Endpoints.GetAIInsights())
    }

    // MARK: - Goal Insights

    func getGoalInsights(goalId: String) async throws -> PortfolioInsightsResponse {
        return try await apiClient.request(Endpoints.GetGoalInsights(goalId: goalId))
    }

    // MARK: - Cache Management

    /// Clear all cached data
    func clearCache() {
        cachedInsights = nil
        cachedInsightsTime = nil
        cachedTips = nil
        cachedTipsTime = nil
        stockExplanationCache.removeAll()
    }

    /// Clear insights cache only
    func clearInsightsCache() {
        cachedInsights = nil
        cachedInsightsTime = nil
    }
}

// MARK: - AI Repository Error

enum AIRepositoryError: LocalizedError {
    case invalidResponse
    case emptyMessage
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Received an invalid response from the AI service."
        case .emptyMessage:
            return "Cannot send an empty message."
        case .rateLimited:
            return "You've sent too many messages. Please wait a moment and try again."
        }
    }
}
