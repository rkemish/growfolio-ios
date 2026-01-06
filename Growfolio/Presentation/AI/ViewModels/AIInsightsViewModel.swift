//
//  AIInsightsViewModel.swift
//  Growfolio
//
//  View model for the AI insights feature.
//

import Foundation
import SwiftUI

@Observable
final class AIInsightsViewModel: @unchecked Sendable {

    // MARK: - Dependencies

    private let aiRepository: AIRepositoryProtocol

    // MARK: - Properties

    // State
    var insights: [AIInsight] = []
    var tips: [InvestingTip] = []
    var healthScore: Int?
    var summary: String?
    var isLoading = false
    var isLoadingTips = false
    var error: Error?
    var showError = false

    // Stock Explanation
    var selectedStockSymbol: String?
    var stockExplanation: StockExplanation?
    var isLoadingExplanation = false
    var showStockExplanation = false

    // Allocation Suggestion
    var allocationSuggestion: AllocationSuggestion?
    var isLoadingAllocation = false
    var showAllocationSuggestion = false

    // Allocation Input
    var investmentAmount: Decimal = 1000
    var selectedRiskTolerance: RiskTolerance = .medium
    var selectedTimeHorizon: TimeHorizon = .medium

    // MARK: - Computed Properties

    var activeInsights: [AIInsight] {
        insights.filter { !$0.isDismissed }
    }

    var highPriorityInsights: [AIInsight] {
        activeInsights.filter { $0.priority >= .high }
    }

    var hasInsights: Bool {
        !activeInsights.isEmpty
    }

    var hasTips: Bool {
        !tips.isEmpty
    }

    var healthScoreColor: Color {
        guard let score = healthScore else { return .gray }

        switch score {
        case 80...100:
            return Color.positive
        case 60..<80:
            return .yellow
        case 40..<60:
            return Color.warning
        default:
            return Color.negative
        }
    }

    var healthScoreDescription: String {
        guard let score = healthScore else { return "Loading..." }

        switch score {
        case 80...100:
            return "Excellent"
        case 60..<80:
            return "Good"
        case 40..<60:
            return "Fair"
        default:
            return "Needs Attention"
        }
    }

    // MARK: - Initialization

    init(aiRepository: AIRepositoryProtocol = RepositoryContainer.aiRepository) {
        self.aiRepository = aiRepository
    }

    // MARK: - Data Loading

    @MainActor
    func loadInsights() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let response = try await aiRepository.fetchInsights(includeGoals: true)
            insights = response.insights
            healthScore = response.healthScore
            summary = response.summary
        } catch {
            self.error = error
            self.showError = true

            // Show error toast with retry option
            Task { @MainActor in
                ToastManager.shared.showError(error) { [weak self] in
                    guard let self else { return }
                    Task { await self.loadInsights() }
                }
            }
        }

        isLoading = false
    }

    @MainActor
    func loadTips() async {
        guard !isLoadingTips else { return }

        isLoadingTips = true

        do {
            tips = try await aiRepository.fetchInvestingTips()
        } catch {
            // Tips are non-critical, show info toast instead of error
            Task { @MainActor in
                ToastManager.shared.showInfo("Investment tips temporarily unavailable")
            }
        }

        isLoadingTips = false
    }

    @MainActor
    func loadAll() async {
        async let insightsTask: () = loadInsights()
        async let tipsTask: () = loadTips()

        _ = await (insightsTask, tipsTask)
    }

    @MainActor
    func refresh() async {
        await loadAll()
    }

    // MARK: - Stock Explanation

    @MainActor
    func loadStockExplanation(for symbol: String) async {
        selectedStockSymbol = symbol
        isLoadingExplanation = true
        stockExplanation = nil
        showStockExplanation = true

        do {
            stockExplanation = try await aiRepository.fetchStockExplanation(symbol: symbol)
        } catch {
            self.error = error
            self.showError = true
            showStockExplanation = false

            // Show error toast for stock explanation failures
            Task { @MainActor in
                ToastManager.shared.showError(
                    "Unable to load AI analysis for \(symbol)",
                    actionTitle: "Retry"
                ) { [weak self] in
                    guard let self else { return }
                    Task { await self.loadStockExplanation(for: symbol) }
                }
            }
        }

        isLoadingExplanation = false
    }

    func dismissStockExplanation() {
        showStockExplanation = false
        stockExplanation = nil
        selectedStockSymbol = nil
    }

    // MARK: - Allocation Suggestion

    @MainActor
    func loadAllocationSuggestion() async {
        isLoadingAllocation = true
        allocationSuggestion = nil
        showAllocationSuggestion = true

        do {
            allocationSuggestion = try await aiRepository.fetchAllocationSuggestion(
                investmentAmount: investmentAmount,
                riskTolerance: selectedRiskTolerance,
                timeHorizon: selectedTimeHorizon
            )
        } catch {
            self.error = error
            self.showError = true
            showAllocationSuggestion = false

            // Show error toast for allocation suggestion failures
            Task { @MainActor in
                ToastManager.shared.showError(error) { [weak self] in
                    guard let self else { return }
                    Task { await self.loadAllocationSuggestion() }
                }
            }
        }

        isLoadingAllocation = false
    }

    func dismissAllocationSuggestion() {
        showAllocationSuggestion = false
        allocationSuggestion = nil
    }

    // MARK: - Insight Actions

    @MainActor
    func dismissInsight(_ insight: AIInsight) {
        if let index = insights.firstIndex(where: { $0.id == insight.id }) {
            insights[index].isDismissed = true
        }
    }

    @MainActor
    func handleInsightAction(_ insight: AIInsight) {
        guard let action = insight.action else { return }

        switch action.type {
        case .viewGoal:
            // Navigate to goal
            break
        case .createGoal:
            // Show create goal sheet
            break
        case .setupDCA:
            // Show DCA setup
            break
        case .viewStock:
            if let symbol = action.destination {
                Task {
                    await loadStockExplanation(for: symbol)
                }
            }
        case .viewPortfolio:
            // Navigate to portfolio
            break
        case .learnMore:
            // Show more info
            break
        case .dismiss:
            dismissInsight(insight)
        }
    }

    // MARK: - Error Handling

    func dismissError() {
        showError = false
        error = nil
    }
}
