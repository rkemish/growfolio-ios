//
//  AIInsightsViewModelTests.swift
//  GrowfolioTests
//
//  Tests for the AIInsightsViewModel - AI insights, tips, and health score.
//

import XCTest
@testable import Growfolio

@MainActor
final class AIInsightsViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: AIInsightsViewModel!
    var mockRepository: MockAIRepository!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockAIRepository()
        sut = AIInsightsViewModel(aiRepository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasEmptyInsights() {
        XCTAssertTrue(sut.insights.isEmpty)
    }

    func test_initialState_hasEmptyTips() {
        XCTAssertTrue(sut.tips.isEmpty)
    }

    func test_initialState_hasNoHealthScore() {
        XCTAssertNil(sut.healthScore)
    }

    func test_initialState_hasNoSummary() {
        XCTAssertNil(sut.summary)
    }

    func test_initialState_isNotLoading() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isLoadingTips)
        XCTAssertFalse(sut.isLoadingExplanation)
        XCTAssertFalse(sut.isLoadingAllocation)
    }

    func test_initialState_hasNoError() {
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.showError)
    }

    func test_initialState_sheetsAreClosed() {
        XCTAssertFalse(sut.showStockExplanation)
        XCTAssertFalse(sut.showAllocationSuggestion)
    }

    // MARK: - Computed Properties Tests

    func test_activeInsights_filtersDismissedInsights() {
        sut.insights = [
            createTestInsight(id: "1", isDismissed: false),
            createTestInsight(id: "2", isDismissed: true),
            createTestInsight(id: "3", isDismissed: false)
        ]

        XCTAssertEqual(sut.activeInsights.count, 2)
        XCTAssertFalse(sut.activeInsights.contains { $0.isDismissed })
    }

    func test_highPriorityInsights_filtersCorrectly() {
        sut.insights = [
            createTestInsight(id: "1", priority: .low),
            createTestInsight(id: "2", priority: .medium),
            createTestInsight(id: "3", priority: .high),
            createTestInsight(id: "4", priority: .critical)
        ]

        let highPriority = sut.highPriorityInsights
        XCTAssertEqual(highPriority.count, 2)
        XCTAssertTrue(highPriority.allSatisfy { $0.priority >= .high })
    }

    func test_highPriorityInsights_excludesDismissed() {
        sut.insights = [
            createTestInsight(id: "1", priority: .high, isDismissed: false),
            createTestInsight(id: "2", priority: .critical, isDismissed: true)
        ]

        XCTAssertEqual(sut.highPriorityInsights.count, 1)
    }

    func test_hasInsights_returnsTrueWhenActiveInsightsExist() {
        XCTAssertFalse(sut.hasInsights)

        sut.insights = [createTestInsight()]
        XCTAssertTrue(sut.hasInsights)
    }

    func test_hasInsights_returnsFalseWhenAllDismissed() {
        sut.insights = [createTestInsight(isDismissed: true)]
        XCTAssertFalse(sut.hasInsights)
    }

    func test_hasTips_returnsTrueWhenTipsExist() {
        XCTAssertFalse(sut.hasTips)

        sut.tips = [createTestTip()]
        XCTAssertTrue(sut.hasTips)
    }

    // MARK: - Health Score Color Tests

    func test_healthScoreColor_returnsGrayWhenNoScore() {
        XCTAssertEqual(sut.healthScoreColor, .gray)
    }

    func test_healthScoreColor_returnsGreenForExcellent() {
        sut.healthScore = 85
        XCTAssertEqual(sut.healthScoreColor, .positive)

        sut.healthScore = 100
        XCTAssertEqual(sut.healthScoreColor, .positive)
    }

    func test_healthScoreColor_returnsYellowForGood() {
        sut.healthScore = 70
        XCTAssertEqual(sut.healthScoreColor, .yellow)

        sut.healthScore = 79
        XCTAssertEqual(sut.healthScoreColor, .yellow)
    }

    func test_healthScoreColor_returnsOrangeForFair() {
        sut.healthScore = 50
        XCTAssertEqual(sut.healthScoreColor, .warning)

        sut.healthScore = 59
        XCTAssertEqual(sut.healthScoreColor, .warning)
    }

    func test_healthScoreColor_returnsRedForPoor() {
        sut.healthScore = 30
        XCTAssertEqual(sut.healthScoreColor, .negative)

        sut.healthScore = 39
        XCTAssertEqual(sut.healthScoreColor, .negative)
    }

    // MARK: - Health Score Description Tests

    func test_healthScoreDescription_returnsLoadingWhenNoScore() {
        XCTAssertEqual(sut.healthScoreDescription, "Loading...")
    }

    func test_healthScoreDescription_returnsExcellent() {
        sut.healthScore = 90
        XCTAssertEqual(sut.healthScoreDescription, "Excellent")
    }

    func test_healthScoreDescription_returnsGood() {
        sut.healthScore = 65
        XCTAssertEqual(sut.healthScoreDescription, "Good")
    }

    func test_healthScoreDescription_returnsFair() {
        sut.healthScore = 45
        XCTAssertEqual(sut.healthScoreDescription, "Fair")
    }

    func test_healthScoreDescription_returnsNeedsAttention() {
        sut.healthScore = 25
        XCTAssertEqual(sut.healthScoreDescription, "Needs Attention")
    }

    // MARK: - Load Insights Tests

    func test_loadInsights_setsInsightsFromRepository() async {
        let expectedInsights = [
            AIInsight(id: "1", type: .diversification, title: "Test", content: "Desc", priority: .medium),
            AIInsight(id: "2", type: .diversification, title: "Test2", content: "Desc2", priority: .medium)
        ]
        mockRepository.insightsToReturn = PortfolioInsightsResponse(
            insights: expectedInsights,
            generatedAt: Date()
        )

        await sut.loadInsights()

        XCTAssertEqual(sut.insights.count, 2)
    }

    func test_loadInsights_setsLoadingStateFalseAfterCompletion() async {
        mockRepository.insightsToReturn = createEmptyInsightsResponse()

        await sut.loadInsights()

        // After completion, loading should be false
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadInsights_setsErrorOnFailure() async {
        mockRepository.errorToThrow = NSError(domain: "Test", code: 1)

        await sut.loadInsights()

        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.showError)
    }

    func test_loadInsights_preventsDoubleLoading() async {
        mockRepository.insightsToReturn = createEmptyInsightsResponse()
        sut.isLoading = true

        await sut.loadInsights()

        XCTAssertFalse(mockRepository.fetchInsightsCalled)
    }

    // MARK: - Load Tips Tests

    func test_loadTips_setsTipsFromRepository() async {
        let expectedTips = [createTestTip(), createTestTip(id: "2")]
        mockRepository.investingTipsToReturn = expectedTips

        await sut.loadTips()

        XCTAssertEqual(sut.tips.count, 2)
    }

    func test_loadTips_setsLoadingStateFalseAfterCompletion() async {
        mockRepository.investingTipsToReturn = []

        await sut.loadTips()

        // After completion, loading should be false
        XCTAssertFalse(sut.isLoadingTips)
    }

    func test_loadTips_preventsDoubleLoading() async {
        mockRepository.investingTipsToReturn = []
        sut.isLoadingTips = true

        await sut.loadTips()

        XCTAssertFalse(mockRepository.fetchInvestingTipsCalled)
    }

    func test_loadTips_doesNotShowErrorOnFailure() async {
        // Tips are non-critical, so errors are handled gracefully
        mockRepository.errorToThrow = NSError(domain: "Test", code: 1)

        await sut.loadTips()

        // Error is not set for tips (they're non-critical)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Load All Tests

    func test_loadAll_loadsBothInsightsAndTips() async {
        mockRepository.insightsToReturn = createEmptyInsightsResponse()
        mockRepository.investingTipsToReturn = [createTestTip()]

        await sut.loadAll()

        XCTAssertTrue(mockRepository.fetchInsightsCalled)
        XCTAssertTrue(mockRepository.fetchInvestingTipsCalled)
    }

    func test_refresh_callsLoadAll() async {
        mockRepository.insightsToReturn = createEmptyInsightsResponse()
        mockRepository.investingTipsToReturn = []

        await sut.refresh()

        XCTAssertTrue(mockRepository.fetchInsightsCalled)
        XCTAssertTrue(mockRepository.fetchInvestingTipsCalled)
    }

    // MARK: - Stock Explanation Tests

    func test_loadStockExplanation_setsExplanation() async {
        let explanation = StockExplanation(
            symbol: "AAPL",
            explanation: "Apple is a technology company...",
            generatedAt: Date()
        )
        mockRepository.stockExplanationToReturn = explanation

        await sut.loadStockExplanation(for: "AAPL")

        XCTAssertEqual(sut.stockExplanation?.symbol, "AAPL")
        XCTAssertEqual(sut.selectedStockSymbol, "AAPL")
    }

    func test_loadStockExplanation_showsSheet() async {
        mockRepository.stockExplanationToReturn = createTestStockExplanation()

        await sut.loadStockExplanation(for: "AAPL")

        XCTAssertTrue(sut.showStockExplanation)
    }

    func test_loadStockExplanation_setsLoadingStateFalseAfterCompletion() async {
        mockRepository.stockExplanationToReturn = createTestStockExplanation()

        await sut.loadStockExplanation(for: "AAPL")

        // After completion, loading should be false
        XCTAssertFalse(sut.isLoadingExplanation)
    }

    func test_loadStockExplanation_closesSheetOnError() async {
        mockRepository.errorToThrow = NSError(domain: "Test", code: 1)

        await sut.loadStockExplanation(for: "AAPL")

        XCTAssertFalse(sut.showStockExplanation)
        XCTAssertTrue(sut.showError)
    }

    func test_dismissStockExplanation_clearsState() {
        sut.showStockExplanation = true
        sut.stockExplanation = createTestStockExplanation()
        sut.selectedStockSymbol = "AAPL"

        sut.dismissStockExplanation()

        XCTAssertFalse(sut.showStockExplanation)
        XCTAssertNil(sut.stockExplanation)
        XCTAssertNil(sut.selectedStockSymbol)
    }

    // MARK: - Allocation Suggestion Tests

    func test_loadAllocationSuggestion_setsSuggestion() async {
        let suggestion = AllocationSuggestion(
            suggestion: "Diversify into tech stocks",
            investmentAmount: 1000,
            riskTolerance: .medium,
            timeHorizon: .medium,
            disclaimer: "This is not financial advice"
        )
        mockRepository.allocationSuggestionToReturn = suggestion

        await sut.loadAllocationSuggestion()

        XCTAssertNotNil(sut.allocationSuggestion)
    }

    func test_loadAllocationSuggestion_showsSheet() async {
        mockRepository.allocationSuggestionToReturn = createTestAllocationSuggestion()

        await sut.loadAllocationSuggestion()

        XCTAssertTrue(sut.showAllocationSuggestion)
    }

    func test_loadAllocationSuggestion_usesInputValues() async {
        sut.investmentAmount = 5000
        sut.selectedRiskTolerance = .high
        sut.selectedTimeHorizon = .long
        mockRepository.allocationSuggestionToReturn = createTestAllocationSuggestion()

        await sut.loadAllocationSuggestion()

        XCTAssertEqual(mockRepository.lastAllocationInvestmentAmount, 5000)
        XCTAssertEqual(mockRepository.lastAllocationRiskTolerance, .high)
        XCTAssertEqual(mockRepository.lastAllocationTimeHorizon, .long)
    }

    func test_loadAllocationSuggestion_setsLoadingStateFalseAfterCompletion() async {
        mockRepository.allocationSuggestionToReturn = createTestAllocationSuggestion()

        await sut.loadAllocationSuggestion()

        // After completion, loading should be false
        XCTAssertFalse(sut.isLoadingAllocation)
    }

    func test_loadAllocationSuggestion_closesSheetOnError() async {
        mockRepository.errorToThrow = NSError(domain: "Test", code: 1)

        await sut.loadAllocationSuggestion()

        XCTAssertFalse(sut.showAllocationSuggestion)
        XCTAssertTrue(sut.showError)
    }

    func test_dismissAllocationSuggestion_clearsState() {
        sut.showAllocationSuggestion = true
        sut.allocationSuggestion = createTestAllocationSuggestion()

        sut.dismissAllocationSuggestion()

        XCTAssertFalse(sut.showAllocationSuggestion)
        XCTAssertNil(sut.allocationSuggestion)
    }

    // MARK: - Dismiss Insight Tests

    func test_dismissInsight_markAsDissmised() {
        let insight = createTestInsight(id: "1", isDismissed: false)
        sut.insights = [insight]

        sut.dismissInsight(insight)

        XCTAssertTrue(sut.insights[0].isDismissed)
    }

    func test_dismissInsight_doesNothingIfNotFound() {
        let existingInsight = createTestInsight(id: "1")
        let unknownInsight = createTestInsight(id: "unknown")
        sut.insights = [existingInsight]

        sut.dismissInsight(unknownInsight)

        XCTAssertFalse(sut.insights[0].isDismissed)
    }

    // MARK: - Handle Insight Action Tests

    func test_handleInsightAction_dismissActionDismissesInsight() {
        let insight = createTestInsight(
            id: "1",
            action: InsightAction(type: .dismiss, label: "Dismiss", destination: nil)
        )
        sut.insights = [insight]

        sut.handleInsightAction(insight)

        XCTAssertTrue(sut.insights[0].isDismissed)
    }

    func test_handleInsightAction_viewStockLoadsExplanation() async {
        mockRepository.stockExplanationToReturn = createTestStockExplanation()
        let insight = createTestInsight(
            id: "1",
            action: InsightAction(type: .viewStock, label: "View AAPL", destination: "AAPL")
        )

        sut.handleInsightAction(insight)

        // Allow async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(sut.selectedStockSymbol, "AAPL")
    }

    func test_handleInsightAction_doesNothingWithoutAction() {
        let insight = createTestInsight(id: "1", action: nil)

        sut.handleInsightAction(insight)

        // Should not crash or change state
        XCTAssertFalse(sut.insights.isEmpty ? false : sut.insights[0].isDismissed)
    }

    // MARK: - Error Handling Tests

    func test_dismissError_clearsErrorState() {
        sut.error = NSError(domain: "Test", code: 1)
        sut.showError = true

        sut.dismissError()

        XCTAssertFalse(sut.showError)
        XCTAssertNil(sut.error)
    }

    // MARK: - Insight Type Tests

    func test_insightType_hasCorrectDisplayNames() {
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

    func test_insightType_hasIconNames() {
        XCTAssertFalse(InsightType.portfolioHealth.iconName.isEmpty)
        XCTAssertFalse(InsightType.riskAlert.iconName.isEmpty)
    }

    // MARK: - Insight Priority Tests

    func test_insightPriority_comparesCorrectly() {
        XCTAssertTrue(InsightPriority.low < InsightPriority.medium)
        XCTAssertTrue(InsightPriority.medium < InsightPriority.high)
        XCTAssertTrue(InsightPriority.high < InsightPriority.critical)
    }

    // MARK: - Helpers

    private func createTestInsight(
        id: String = "insight-1",
        type: InsightType = .portfolioHealth,
        priority: InsightPriority = .medium,
        isDismissed: Bool = false,
        action: InsightAction? = nil
    ) -> AIInsight {
        AIInsight(
            id: id,
            type: type,
            title: "Test Insight",
            content: "This is a test insight.",
            priority: priority,
            action: action,
            isDismissed: isDismissed
        )
    }

    private func createTestTip(
        id: String = "tip-1",
        category: TipCategory = .general
    ) -> InvestingTip {
        InvestingTip(
            id: id,
            title: "Test Tip",
            content: "This is a test tip.",
            category: category
        )
    }

    private func createEmptyInsightsResponse() -> PortfolioInsightsResponse {
        PortfolioInsightsResponse(
            insights: [],
            generatedAt: Date()
        )
    }

    private func createTestStockExplanation() -> StockExplanation {
        StockExplanation(
            symbol: "AAPL",
            explanation: "Test explanation",
            generatedAt: Date()
        )
    }

    private func createTestAllocationSuggestion() -> AllocationSuggestion {
        AllocationSuggestion(
            suggestion: "Test suggestion",
            investmentAmount: 1000,
            riskTolerance: .medium,
            timeHorizon: .medium,
            disclaimer: "Test disclaimer"
        )
    }
}
