//
//  MockAIRepository.swift
//  Growfolio
//
//  Mock implementation of AIRepositoryProtocol for demo mode.
//

import Foundation

/// Mock implementation of AIRepositoryProtocol
final class MockAIRepository: AIRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let store = MockDataStore.shared
    private let config = MockConfiguration.shared

    // MARK: - Chat

    func sendMessage(
        _ message: String,
        conversationHistory: [ChatMessage],
        includePortfolioContext: Bool
    ) async throws -> ChatMessage {
        // Simulate AI thinking time
        try await simulateTypingDelay()

        // Get appropriate response based on message content
        let response = MockUserDataProvider.aiResponse(for: message)

        // Add suggested actions based on context
        var suggestedActions: [String]? = nil
        let lowercased = message.lowercased()

        if lowercased.contains("portfolio") || lowercased.contains("holding") {
            suggestedActions = ["View Portfolio", "Check Performance"]
        } else if lowercased.contains("dca") || lowercased.contains("schedule") {
            suggestedActions = ["View DCA Schedules", "Create New Schedule"]
        } else if lowercased.contains("goal") {
            suggestedActions = ["View Goals", "Create Goal"]
        }

        let assistantMessage = ChatMessage.assistant(response, suggestedActions: suggestedActions)
        await store.addChatMessage(assistantMessage)

        return assistantMessage
    }

    // MARK: - Insights

    func fetchInsights(includeGoals: Bool) async throws -> PortfolioInsightsResponse {
        try await simulateNetwork()
        await ensureInitialized()

        var insights: [AIInsight] = []

        // Portfolio health insight
        let portfolios = await store.portfolios
        if !portfolios.isEmpty {
            let totalValue = portfolios.reduce(Decimal.zero) { $0 + $1.totalValue }
            let totalCostBasis = portfolios.reduce(Decimal.zero) { $0 + $1.totalCostBasis }
            let gainPercent = totalCostBasis > 0 ? ((totalValue - totalCostBasis) / totalCostBasis) * 100 : 0

            insights.append(AIInsight(
                type: .portfolioHealth,
                title: "Portfolio Performance",
                content: "Your portfolio is \(gainPercent >= 0 ? "up" : "down") \(abs(gainPercent).formatted(.number.precision(.fractionLength(1))))% overall. \(gainPercent >= 0 ? "Great job staying invested!" : "Stay the course - markets recover over time.")",
                priority: gainPercent >= 0 ? .medium : .high
            ))
        }

        // Diversification insight
        if let mainPortfolio = portfolios.first {
            let holdings = await store.getHoldings(for: mainPortfolio.id)
            if holdings.count > 0 {
                let techHoldings = holdings.filter { $0.sector == "Technology" }
                let techAllocation = holdings.isEmpty ? 0 : (techHoldings.reduce(Decimal.zero) { $0 + $1.marketValue } / holdings.reduce(Decimal.zero) { $0 + $1.marketValue }) * 100

                if techAllocation > 40 {
                    insights.append(AIInsight(
                        type: .diversification,
                        title: "High Tech Exposure",
                        content: "Technology stocks make up \(techAllocation.formatted(.number.precision(.fractionLength(0))))% of your portfolio. Consider diversifying into other sectors for reduced risk.",
                        priority: techAllocation > 50 ? .high : .medium,
                        action: InsightAction(type: .viewPortfolio, label: "View Allocation", destination: nil)
                    ))
                }
            }
        }

        // DCA insight
        let schedules = await store.dcaSchedules.filter { $0.isActive }
        if !schedules.isEmpty {
            let monthlyTotal = schedules.reduce(Decimal.zero) { $0 + $1.monthlyEquivalent }
            insights.append(AIInsight(
                type: .dcaSuggestion,
                title: "DCA Progress",
                content: "You're investing approximately \(monthlyTotal.currencyString) monthly through \(schedules.count) active DCA schedule\(schedules.count == 1 ? "" : "s"). Consistency is key to long-term success!",
                priority: .medium,
                action: InsightAction(type: .setupDCA, label: "Manage Schedules", destination: nil)
            ))
        }

        // Goal insights
        if includeGoals {
            let goals = await store.goals.filter { !$0.isArchived }
            for goal in goals.prefix(2) {
                if goal.progressPercentage >= 100 {
                    insights.append(AIInsight(
                        type: .milestone,
                        title: "Goal Achieved!",
                        content: "Congratulations! You've reached your \(goal.name) goal of \(goal.targetAmount.currencyString)!",
                        priority: .high,
                        action: InsightAction(type: .viewGoal, label: "View Goal", destination: goal.id)
                    ))
                } else if goal.progressPercentage >= 75 {
                    let progressInt = NSDecimalNumber(decimal: goal.progressPercentage).intValue
                    insights.append(AIInsight(
                        type: .goalProgress,
                        title: "Almost There!",
                        content: "Your \(goal.name) goal is \(progressInt)% complete. Just \(goal.remainingAmount.currencyString) to go!",
                        priority: .medium,
                        action: InsightAction(type: .viewGoal, label: "View Goal", destination: goal.id)
                    ))
                }
            }
        }

        // Add a tip
        insights.append(AIInsight(
            type: .tip,
            title: "Investment Tip",
            content: MockUserDataProvider.aiInsights.randomElement()!,
            priority: .low
        ))

        // Calculate health score
        let healthScore = await calculateHealthScore()

        return PortfolioInsightsResponse(
            insights: insights.sorted { $0.priority > $1.priority },
            generatedAt: Date(),
            healthScore: healthScore,
            summary: "Your portfolio is performing \(healthScore >= 70 ? "well" : healthScore >= 50 ? "adequately" : "below expectations"). Keep investing consistently for best results."
        )
    }

    // MARK: - Stock Explanation

    func fetchStockExplanation(symbol: String) async throws -> StockExplanation {
        try await simulateNetwork()

        let upperSymbol = symbol.uppercased()
        let profile = MockStockDataProvider.stockProfiles[upperSymbol]

        let explanation: String
        if let profile = profile {
            let marketCapStr = profile.marketCap?.compactCurrencyString ?? "Large Cap"
            explanation = """
            **\(profile.name) (\(upperSymbol))**

            \(profile.name) is a \(profile.sector) company in the \(profile.industry) industry.

            **Key Points:**
            - Market Cap: \(marketCapStr)
            - Current Price: ~$\(profile.basePrice)
            - Volatility: \(profile.volatility < 0.02 ? "Low" : profile.volatility < 0.04 ? "Moderate" : "High")

            \(profile.assetType == .etf ? "As an ETF, this provides diversified exposure to multiple holdings, reducing individual stock risk." : "As an individual stock, returns depend on company performance and market conditions.")

            **Investment Considerations:**
            - Dollar-cost averaging can help manage volatility
            - Consider your overall portfolio allocation before investing
            - Past performance doesn't guarantee future results

            *This is educational content only, not financial advice.*
            """
        } else {
            explanation = """
            **\(upperSymbol)**

            I don't have detailed information about this stock. Here are some general considerations:

            - Research the company's business model and financials
            - Understand the sector and industry dynamics
            - Consider how it fits your portfolio strategy
            - Use dollar-cost averaging to manage entry price risk

            *This is educational content only, not financial advice. Please do your own research before investing.*
            """
        }

        return StockExplanation(symbol: upperSymbol, explanation: explanation)
    }

    // MARK: - Allocation Suggestion

    func fetchAllocationSuggestion(
        investmentAmount: Decimal,
        riskTolerance: RiskTolerance,
        timeHorizon: TimeHorizon
    ) async throws -> AllocationSuggestion {
        try await simulateTypingDelay()

        let suggestion: String

        switch (riskTolerance, timeHorizon) {
        case (.low, .short):
            suggestion = """
            For a conservative short-term approach with \(investmentAmount.currencyString):

            **Suggested Allocation:**
            - 70% Bonds (BND): Stability and income
            - 20% Total Stock Market (VTI): Some growth potential
            - 10% Cash: Liquidity

            This allocation prioritizes capital preservation while maintaining modest growth potential.
            """

        case (.low, .medium), (.low, .long):
            suggestion = """
            For a conservative \(timeHorizon == .medium ? "medium" : "long")-term approach with \(investmentAmount.currencyString):

            **Suggested Allocation:**
            - 50% Bonds (BND): Stability and income
            - 35% Total Stock Market (VTI): Domestic growth
            - 15% International (VXUS): Global diversification

            This provides stability while capturing long-term equity growth.
            """

        case (.medium, .short):
            suggestion = """
            For a moderate short-term approach with \(investmentAmount.currencyString):

            **Suggested Allocation:**
            - 40% Bonds (BND): Stability
            - 40% S&P 500 (VOO): Large cap growth
            - 20% Cash: Flexibility

            Balanced approach that manages risk while seeking reasonable returns.
            """

        case (.medium, .medium), (.medium, .long):
            suggestion = """
            For a balanced \(timeHorizon == .medium ? "medium" : "long")-term approach with \(investmentAmount.currencyString):

            **Suggested Allocation:**
            - 60% Total Stock Market (VTI): US equity growth
            - 20% International (VXUS): Global diversification
            - 20% Bonds (BND): Stability

            Classic balanced allocation suitable for most long-term investors.
            """

        case (.high, .short):
            suggestion = """
            For an aggressive short-term approach with \(investmentAmount.currencyString):

            **Suggested Allocation:**
            - 60% S&P 500 (VOO): Large cap growth
            - 30% Growth stocks (QQQ): Tech-heavy growth
            - 10% Cash: Dry powder for opportunities

            Higher risk approach with significant equity exposure.
            """

        case (.high, .medium), (.high, .long):
            suggestion = """
            For an aggressive \(timeHorizon == .medium ? "medium" : "long")-term approach with \(investmentAmount.currencyString):

            **Suggested Allocation:**
            - 50% Total Stock Market (VTI): Broad US exposure
            - 25% Growth (QQQ): Tech and innovation
            - 15% International (VXUS): Global growth
            - 10% Small Cap (VB): Higher growth potential

            Maximizes growth potential with full equity exposure.
            """
        }

        return AllocationSuggestion(
            suggestion: suggestion,
            investmentAmount: investmentAmount,
            riskTolerance: riskTolerance,
            timeHorizon: timeHorizon,
            disclaimer: "This is educational content only, not personalized financial advice. Consider consulting a qualified financial advisor for recommendations tailored to your specific situation."
        )
    }

    // MARK: - Investing Tips

    func fetchInvestingTips() async throws -> [InvestingTip] {
        try await simulateNetwork()

        return [
            InvestingTip(
                title: "Dollar-Cost Averaging",
                content: "Investing a fixed amount regularly helps smooth out market volatility. You buy more shares when prices are low and fewer when prices are high, potentially lowering your average cost over time.",
                category: .dca
            ),
            InvestingTip(
                title: "Diversify Your Portfolio",
                content: "Don't put all your eggs in one basket. Spreading investments across different asset classes, sectors, and geographies helps reduce risk and smooth out returns.",
                category: .diversification
            ),
            InvestingTip(
                title: "Think Long-Term",
                content: "Markets can be volatile in the short term, but historically they've trended upward over decades. Staying invested through market ups and downs often leads to better outcomes than trying to time the market.",
                category: .longTerm
            ),
            InvestingTip(
                title: "Keep Investment Costs Low",
                content: "High fees can significantly eat into your returns over time. Low-cost index funds and ETFs are excellent options for most investors.",
                category: .fees
            ),
            InvestingTip(
                title: "Automate Your Investments",
                content: "Setting up automatic investments ensures you stay consistent with your financial goals, removes emotional decision-making, and takes advantage of dollar-cost averaging.",
                category: .automation
            ),
            InvestingTip(
                title: "Understand Your Risk Tolerance",
                content: "Know how much volatility you can handle both financially and emotionally. Your portfolio should let you sleep at night while still working toward your goals.",
                category: .risk
            )
        ]
    }

    // MARK: - AI Insights

    func getAIInsights() async throws -> PortfolioInsightsResponse {
        // Delegate to fetchInsights with includeGoals: true
        return try await fetchInsights(includeGoals: true)
    }

    // MARK: - Goal Insights

    func getGoalInsights(goalId: String) async throws -> PortfolioInsightsResponse {
        try await simulateNetwork()
        await ensureInitialized()

        // Find the specific goal
        guard let goal = await store.goals.first(where: { $0.id == goalId }) else {
            throw NetworkError.notFound
        }

        var insights: [AIInsight] = []

        // Add goal-specific insights
        if goal.progressPercentage >= 100 {
            insights.append(AIInsight(
                type: .milestone,
                title: "Goal Achieved!",
                content: "Congratulations! You've reached your \(goal.name) goal of \(goal.targetAmount.currencyString)!",
                priority: .high,
                action: InsightAction(type: .viewGoal, label: "View Goal", destination: goal.id)
            ))
        } else {
            let progressInt = NSDecimalNumber(decimal: goal.progressPercentage).intValue
            insights.append(AIInsight(
                type: .goalProgress,
                title: "Goal Progress",
                content: "Your \(goal.name) goal is \(progressInt)% complete. You have \(goal.remainingAmount.currencyString) remaining to reach your target of \(goal.targetAmount.currencyString).",
                priority: .medium,
                action: InsightAction(type: .viewGoal, label: "View Goal", destination: goal.id)
            ))

            // Add recommendation if there's a target date
            if let targetDate = goal.targetDate, let monthlyContribution = goal.estimatedMonthlyContribution {
                let daysRemaining = targetDate.daysFromNow
                if daysRemaining > 0 {
                    insights.append(AIInsight(
                        type: .dcaSuggestion,
                        title: "Monthly Contribution Needed",
                        content: "To reach this goal on time, consider contributing approximately \(monthlyContribution.currencyString) per month. You have \(daysRemaining) days remaining.",
                        priority: .high,
                        action: InsightAction(type: .setupDCA, label: "Set Up DCA", destination: nil)
                    ))
                }
            }
        }

        let progressInt = NSDecimalNumber(decimal: goal.progressPercentage).intValue
        return PortfolioInsightsResponse(
            insights: insights,
            generatedAt: Date(),
            healthScore: progressInt >= 75 ? 85 : progressInt >= 50 ? 70 : 60,
            summary: "AI-generated insights for your \(goal.name) goal."
        )
    }

    // MARK: - Private Methods

    private func simulateNetwork() async throws {
        try await config.simulateNetworkDelay()
        try config.maybeThrowSimulatedError()
    }

    private func simulateTypingDelay() async throws {
        // Simulate AI "thinking" time (1-2 seconds)
        let delay = UInt64(Double.random(in: 1.0...2.0) * 1_000_000_000)
        try await Task.sleep(nanoseconds: delay)
        try config.maybeThrowSimulatedError()
    }

    private func ensureInitialized() async {
        if await store.portfolios.isEmpty {
            await store.initialize(for: config.demoPersona)
        }
    }

    private func calculateHealthScore() async -> Int {
        var score = 70 // Base score

        let portfolios = await store.portfolios
        let schedules = await store.dcaSchedules
        let goals = await store.goals

        // Boost for active DCA schedules
        if !schedules.filter({ $0.isActive }).isEmpty {
            score += 10
        }

        // Boost for having goals
        if !goals.isEmpty {
            score += 5
        }

        // Boost for goal progress
        let avgProgress: Double = goals.isEmpty ? 0 : goals.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.progressPercentage).doubleValue } / Double(goals.count)
        if avgProgress > 50 {
            score += 5
        }

        // Boost for diversification (multiple holdings)
        if let mainPortfolio = portfolios.first {
            let holdings = await store.getHoldings(for: mainPortfolio.id)
            if holdings.count >= 5 {
                score += 5
            }
            if holdings.count >= 10 {
                score += 5
            }
        }

        return min(100, max(0, score))
    }
}

// MARK: - Helper Extensions

private extension DCASchedule {
    var monthlyEquivalent: Decimal {
        switch frequency {
        case .daily:
            return amount * 30
        case .weekly:
            return amount * 4
        case .biweekly:
            return amount * 2
        case .monthly:
            return amount
        }
    }
}
