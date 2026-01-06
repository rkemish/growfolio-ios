//
//  GoalsViewModelTests.swift
//  GrowfolioTests
//
//  Tests for GoalsViewModel - goal management and tracking.
//

import XCTest
@testable import Growfolio

@MainActor
final class GoalsViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockRepository: MockGoalRepository!
    var sut: GoalsViewModel!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockGoalRepository()
        sut = GoalsViewModel(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isRefreshing)
        XCTAssertNil(sut.error)
        XCTAssertTrue(sut.goals.isEmpty)
        XCTAssertNil(sut.selectedGoal)
        XCTAssertFalse(sut.showArchived)
        XCTAssertNil(sut.filterCategory)
        XCTAssertEqual(sut.sortOrder, .progress)
    }

    func test_initialState_sheetPresentationIsFalse() {
        XCTAssertFalse(sut.showCreateGoal)
        XCTAssertFalse(sut.showGoalDetail)
        XCTAssertNil(sut.goalToEdit)
    }

    // MARK: - Computed Properties Tests

    func test_filteredGoals_excludesArchivedByDefault() {
        let goals = [
            TestFixtures.goal(id: "goal-1", isArchived: false),
            TestFixtures.goal(id: "goal-2", isArchived: true),
            TestFixtures.goal(id: "goal-3", isArchived: false)
        ]
        sut.goals = goals
        sut.showArchived = false

        XCTAssertEqual(sut.filteredGoals.count, 2)
        XCTAssertTrue(sut.filteredGoals.allSatisfy { !$0.isArchived })
    }

    func test_filteredGoals_includesArchivedWhenEnabled() {
        let goals = [
            TestFixtures.goal(id: "goal-1", isArchived: false),
            TestFixtures.goal(id: "goal-2", isArchived: true),
            TestFixtures.goal(id: "goal-3", isArchived: false)
        ]
        sut.goals = goals
        sut.showArchived = true

        XCTAssertEqual(sut.filteredGoals.count, 3)
    }

    func test_filteredGoals_filtersByCategory() {
        let goals = [
            TestFixtures.goal(id: "goal-1", category: .retirement),
            TestFixtures.goal(id: "goal-2", category: .education),
            TestFixtures.goal(id: "goal-3", category: .retirement)
        ]
        sut.goals = goals
        sut.filterCategory = .retirement

        XCTAssertEqual(sut.filteredGoals.count, 2)
        XCTAssertTrue(sut.filteredGoals.allSatisfy { $0.category == .retirement })
    }

    func test_activeGoalsCount_excludesArchivedAndAchieved() {
        let goals = [
            TestFixtures.goal(id: "goal-1", targetAmount: 10000, currentAmount: 5000, isArchived: false), // Active
            TestFixtures.goal(id: "goal-2", targetAmount: 5000, currentAmount: 5000, isArchived: false), // Achieved
            TestFixtures.goal(id: "goal-3", targetAmount: 10000, currentAmount: 2000, isArchived: true),  // Archived
            TestFixtures.goal(id: "goal-4", targetAmount: 10000, currentAmount: 3000, isArchived: false)  // Active
        ]
        sut.goals = goals

        XCTAssertEqual(sut.activeGoalsCount, 2)
    }

    func test_achievedGoalsCount_countsOnlyAchieved() {
        let goals = [
            TestFixtures.goal(id: "goal-1", targetAmount: 10000, currentAmount: 10000), // Achieved
            TestFixtures.goal(id: "goal-2", targetAmount: 5000, currentAmount: 2000),   // Not achieved
            TestFixtures.goal(id: "goal-3", targetAmount: 1000, currentAmount: 1500),   // Achieved (exceeded)
            TestFixtures.goal(id: "goal-4", targetAmount: 10000, currentAmount: 9999)   // Not achieved
        ]
        sut.goals = goals

        XCTAssertEqual(sut.achievedGoalsCount, 2)
    }

    func test_summary_calculatesFromNonArchivedGoals() {
        let goals = [
            TestFixtures.goal(id: "goal-1", targetAmount: 10000, currentAmount: 5000, isArchived: false),
            TestFixtures.goal(id: "goal-2", targetAmount: 5000, currentAmount: 2500, isArchived: false),
            TestFixtures.goal(id: "goal-3", targetAmount: 20000, currentAmount: 10000, isArchived: true) // Excluded
        ]
        sut.goals = goals

        let summary = sut.summary

        XCTAssertEqual(summary.totalGoals, 2)
        XCTAssertEqual(summary.totalTargetAmount, 15000)
        XCTAssertEqual(summary.totalCurrentAmount, 7500)
    }

    func test_hasGoals_returnsFalseWhenEmpty() {
        sut.goals = []
        XCTAssertFalse(sut.hasGoals)
    }

    func test_hasGoals_returnsTrueWhenNotEmpty() {
        sut.goals = [TestFixtures.goal()]
        XCTAssertTrue(sut.hasGoals)
    }

    func test_isEmpty_returnsFalseWhenLoading() {
        sut.isLoading = true
        sut.goals = []

        XCTAssertFalse(sut.isEmpty)
    }

    func test_isEmpty_returnsTrueWhenNotLoadingAndNoFilteredGoals() {
        sut.isLoading = false
        sut.goals = []

        XCTAssertTrue(sut.isEmpty)
    }

    func test_isEmpty_returnsTrueWhenAllGoalsFiltered() {
        let goals = [
            TestFixtures.goal(id: "goal-1", isArchived: true),
            TestFixtures.goal(id: "goal-2", isArchived: true)
        ]
        sut.goals = goals
        sut.showArchived = false
        sut.isLoading = false

        XCTAssertTrue(sut.isEmpty)
    }

    // MARK: - Sorting Tests

    func test_filteredGoals_sortsByProgress() {
        let goals = [
            TestFixtures.goal(id: "goal-1", targetAmount: 10000, currentAmount: 2500), // 25%
            TestFixtures.goal(id: "goal-2", targetAmount: 10000, currentAmount: 7500), // 75%
            TestFixtures.goal(id: "goal-3", targetAmount: 10000, currentAmount: 5000)  // 50%
        ]
        sut.goals = goals
        sut.sortOrder = .progress

        let filtered = sut.filteredGoals

        XCTAssertEqual(filtered[0].id, "goal-2") // 75% first
        XCTAssertEqual(filtered[1].id, "goal-3") // 50%
        XCTAssertEqual(filtered[2].id, "goal-1") // 25%
    }

    func test_filteredGoals_sortsByName() {
        let goals = [
            TestFixtures.goal(id: "goal-1", name: "Zebra"),
            TestFixtures.goal(id: "goal-2", name: "Alpha"),
            TestFixtures.goal(id: "goal-3", name: "Mango")
        ]
        sut.goals = goals
        sut.sortOrder = .name

        let filtered = sut.filteredGoals

        XCTAssertEqual(filtered[0].name, "Alpha")
        XCTAssertEqual(filtered[1].name, "Mango")
        XCTAssertEqual(filtered[2].name, "Zebra")
    }

    func test_filteredGoals_sortsByTargetAmount() {
        let goals = [
            TestFixtures.goal(id: "goal-1", targetAmount: 5000),
            TestFixtures.goal(id: "goal-2", targetAmount: 50000),
            TestFixtures.goal(id: "goal-3", targetAmount: 10000)
        ]
        sut.goals = goals
        sut.sortOrder = .targetAmount

        let filtered = sut.filteredGoals

        XCTAssertEqual(filtered[0].targetAmount, 50000) // Highest first
        XCTAssertEqual(filtered[1].targetAmount, 10000)
        XCTAssertEqual(filtered[2].targetAmount, 5000)
    }

    func test_filteredGoals_sortsByTargetDate() {
        let now = Date()
        let goals = [
            TestFixtures.goal(id: "goal-1", targetDate: now.addingTimeInterval(86400 * 365)), // 1 year
            TestFixtures.goal(id: "goal-2", targetDate: now.addingTimeInterval(86400 * 30)),  // 30 days
            TestFixtures.goal(id: "goal-3", targetDate: nil)                                   // No date
        ]
        sut.goals = goals
        sut.sortOrder = .targetDate

        let filtered = sut.filteredGoals

        XCTAssertEqual(filtered[0].id, "goal-2") // Earliest first
        XCTAssertEqual(filtered[1].id, "goal-1")
        // goal-3 with nil date goes to end
    }

    func test_filteredGoals_sortsByCreatedAt() {
        let now = Date()
        let goals = [
            TestFixtures.goal(id: "goal-1", createdAt: now.addingTimeInterval(-86400 * 30)), // 30 days ago
            TestFixtures.goal(id: "goal-2", createdAt: now),                                  // Now
            TestFixtures.goal(id: "goal-3", createdAt: now.addingTimeInterval(-86400 * 7))   // 7 days ago
        ]
        sut.goals = goals
        sut.sortOrder = .createdAt

        let filtered = sut.filteredGoals

        XCTAssertEqual(filtered[0].id, "goal-2") // Most recent first
        XCTAssertEqual(filtered[1].id, "goal-3")
        XCTAssertEqual(filtered[2].id, "goal-1")
    }

    // MARK: - Loading State Tests

    func test_loadGoals_setsIsLoadingDuringOperation() async {
        await sut.loadGoals()

        XCTAssertFalse(sut.isLoading)
    }

    func test_loadGoals_preventsMultipleSimultaneousLoads() async {
        sut.isLoading = true

        await sut.loadGoals()

        XCTAssertFalse(mockRepository.fetchGoalsCalled)
    }

    func test_refreshGoals_setsIsRefreshingDuringOperation() async {
        await sut.refreshGoals()

        XCTAssertFalse(sut.isRefreshing)
        XCTAssertTrue(mockRepository.invalidateCacheCalled)
    }

    // MARK: - Data Loading Tests

    func test_loadGoals_fetchesFromRepository() async {
        let goals = TestFixtures.sampleGoals
        mockRepository.goalsToReturn = goals

        await sut.loadGoals()

        XCTAssertTrue(mockRepository.fetchGoalsCalled)
        XCTAssertEqual(mockRepository.fetchGoalsIncludeArchived, true) // Should include archived
        XCTAssertEqual(sut.goals.count, goals.count)
    }

    func test_loadGoals_clearsErrorOnSuccess() async {
        sut.error = NetworkError.noConnection
        mockRepository.goalsToReturn = TestFixtures.sampleGoals

        await sut.loadGoals()

        XCTAssertNil(sut.error)
    }

    // MARK: - Error Handling Tests

    func test_loadGoals_setsErrorOnFailure() async {
        mockRepository.errorToThrow = NetworkError.serverError(statusCode: 500, message: nil)

        await sut.loadGoals()

        XCTAssertNotNil(sut.error)
    }

    // MARK: - CRUD Operations Tests

    func test_createGoal_callsRepositoryWithCorrectParams() async {
        let targetDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())

        try? await sut.createGoal(
            name: "Test Goal",
            targetAmount: 10000,
            targetDate: targetDate,
            category: .investment,
            notes: "Test notes"
        )

        XCTAssertTrue(mockRepository.createGoalCalled)
        XCTAssertEqual(mockRepository.lastCreateGoalParams?.name, "Test Goal")
        XCTAssertEqual(mockRepository.lastCreateGoalParams?.targetAmount, 10000)
        XCTAssertEqual(mockRepository.lastCreateGoalParams?.category, .investment)
        XCTAssertEqual(mockRepository.lastCreateGoalParams?.notes, "Test notes")
    }

    func test_createGoal_refreshesAfterSuccess() async {
        try? await sut.createGoal(
            name: "Test Goal",
            targetAmount: 10000,
            targetDate: nil,
            category: .other,
            notes: nil
        )

        XCTAssertTrue(mockRepository.invalidateCacheCalled)
        XCTAssertTrue(mockRepository.fetchGoalsCalled)
    }

    func test_updateGoal_callsRepository() async {
        var goal = TestFixtures.goal()
        goal.name = "Updated Name"

        try? await sut.updateGoal(goal)

        XCTAssertTrue(mockRepository.updateGoalCalled)
        XCTAssertEqual(mockRepository.lastUpdatedGoal?.name, "Updated Name")
    }

    func test_updateGoal_refreshesAfterSuccess() async {
        let goal = TestFixtures.goal()

        try? await sut.updateGoal(goal)

        XCTAssertTrue(mockRepository.invalidateCacheCalled)
    }

    func test_deleteGoal_callsRepository() async {
        let goal = TestFixtures.goal(id: "goal-to-delete")
        sut.goals = [goal]

        try? await sut.deleteGoal(goal)

        XCTAssertTrue(mockRepository.deleteGoalCalled)
        XCTAssertEqual(mockRepository.lastDeletedGoalId, "goal-to-delete")
    }

    func test_deleteGoal_removesFromLocalList() async {
        let goal = TestFixtures.goal(id: "goal-to-delete")
        sut.goals = [goal, TestFixtures.goal(id: "other-goal")]

        try? await sut.deleteGoal(goal)

        XCTAssertEqual(sut.goals.count, 1)
        XCTAssertFalse(sut.goals.contains { $0.id == "goal-to-delete" })
    }

    func test_archiveGoal_callsRepository() async {
        let goal = TestFixtures.goal(id: "goal-to-archive")
        mockRepository.goalToReturn = goal

        try? await sut.archiveGoal(goal)

        XCTAssertTrue(mockRepository.archiveGoalCalled)
        XCTAssertEqual(mockRepository.lastArchivedGoalId, "goal-to-archive")
    }

    func test_archiveGoal_refreshesAfterSuccess() async {
        let goal = TestFixtures.goal()
        mockRepository.goalToReturn = goal

        try? await sut.archiveGoal(goal)

        XCTAssertTrue(mockRepository.invalidateCacheCalled)
    }

    func test_unarchiveGoal_callsRepository() async {
        let goal = TestFixtures.goal(id: "goal-to-unarchive", isArchived: true)
        mockRepository.goalToReturn = goal

        try? await sut.unarchiveGoal(goal)

        XCTAssertTrue(mockRepository.unarchiveGoalCalled)
        XCTAssertEqual(mockRepository.lastUnarchivedGoalId, "goal-to-unarchive")
    }

    // MARK: - Selection Tests

    func test_selectGoal_setsSelectedGoalAndShowsDetail() {
        let goal = TestFixtures.goal()

        sut.selectGoal(goal)

        XCTAssertEqual(sut.selectedGoal?.id, goal.id)
        XCTAssertTrue(sut.showGoalDetail)
    }

    func test_editGoal_setsGoalToEditAndShowsCreateSheet() {
        let goal = TestFixtures.goal()

        sut.editGoal(goal)

        XCTAssertEqual(sut.goalToEdit?.id, goal.id)
        XCTAssertTrue(sut.showCreateGoal)
    }
}

// MARK: - GoalSortOrder Tests

final class GoalSortOrderTests: XCTestCase {

    func test_allCases_containsExpectedValues() {
        let cases = GoalSortOrder.allCases

        XCTAssertTrue(cases.contains(.progress))
        XCTAssertTrue(cases.contains(.name))
        XCTAssertTrue(cases.contains(.targetAmount))
        XCTAssertTrue(cases.contains(.targetDate))
        XCTAssertTrue(cases.contains(.createdAt))
    }

    func test_displayName_returnsNonEmptyString() {
        for sortOrder in GoalSortOrder.allCases {
            XCTAssertFalse(sortOrder.displayName.isEmpty)
        }
    }

    func test_iconName_returnsNonEmptyString() {
        for sortOrder in GoalSortOrder.allCases {
            XCTAssertFalse(sortOrder.iconName.isEmpty)
        }
    }
}

// MARK: - GoalCategory Tests

final class GoalCategoryTests: XCTestCase {

    func test_allCases_containsExpectedCategories() {
        let cases = GoalCategory.allCases

        XCTAssertTrue(cases.contains(.retirement))
        XCTAssertTrue(cases.contains(.education))
        XCTAssertTrue(cases.contains(.house))
        XCTAssertTrue(cases.contains(.car))
        XCTAssertTrue(cases.contains(.vacation))
        XCTAssertTrue(cases.contains(.emergency))
        XCTAssertTrue(cases.contains(.wedding))
        XCTAssertTrue(cases.contains(.investment))
        XCTAssertTrue(cases.contains(.other))
    }

    func test_displayName_returnsNonEmptyString() {
        for category in GoalCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
        }
    }

    func test_iconName_returnsNonEmptyString() {
        for category in GoalCategory.allCases {
            XCTAssertFalse(category.iconName.isEmpty)
        }
    }

    func test_defaultColorHex_returnsValidHexFormat() {
        for category in GoalCategory.allCases {
            let hex = category.defaultColorHex
            XCTAssertTrue(hex.hasPrefix("#"))
            XCTAssertEqual(hex.count, 7)
        }
    }
}

// MARK: - GoalStatus Tests

final class GoalStatusTests: XCTestCase {

    func test_goalStatus_derivedFromProgress() {
        // Not started
        let notStarted = TestFixtures.goal(targetAmount: 1000, currentAmount: 0)
        XCTAssertEqual(notStarted.status, .notStarted)

        // In progress (< 50%)
        let inProgress = TestFixtures.goal(targetAmount: 1000, currentAmount: 250)
        XCTAssertEqual(inProgress.status, .inProgress)

        // Halfway (>= 50%, < 75%)
        let halfway = TestFixtures.goal(targetAmount: 1000, currentAmount: 500)
        XCTAssertEqual(halfway.status, .halfway)

        // Almost there (>= 75%, < 100%)
        let almostThere = TestFixtures.goal(targetAmount: 1000, currentAmount: 800)
        XCTAssertEqual(almostThere.status, .almostThere)

        // Achieved (>= 100%)
        let achieved = TestFixtures.goal(targetAmount: 1000, currentAmount: 1000)
        XCTAssertEqual(achieved.status, .achieved)
    }

    func test_goalStatus_archivedTakesPrecedence() {
        let archivedWithProgress = TestFixtures.goal(
            targetAmount: 1000,
            currentAmount: 500,
            isArchived: true
        )
        XCTAssertEqual(archivedWithProgress.status, .archived)
    }
}

// MARK: - GoalsSummary Tests

final class GoalsSummaryTests: XCTestCase {

    func test_init_calculatesCorrectly() {
        let goals = [
            TestFixtures.goal(id: "1", targetAmount: 10000, currentAmount: 5000),
            TestFixtures.goal(id: "2", targetAmount: 5000, currentAmount: 5000), // Achieved
            TestFixtures.goal(id: "3", targetAmount: 20000, currentAmount: 10000)
        ]

        let summary = GoalsSummary(goals: goals)

        XCTAssertEqual(summary.totalGoals, 3)
        XCTAssertEqual(summary.achievedGoals, 1)
        XCTAssertEqual(summary.inProgressGoals, 2)
        XCTAssertEqual(summary.totalTargetAmount, 35000)
        XCTAssertEqual(summary.totalCurrentAmount, 20000)
    }

    func test_overallProgress_calculatesCorrectly() {
        let goals = [
            TestFixtures.goal(targetAmount: 10000, currentAmount: 5000), // 50%
            TestFixtures.goal(targetAmount: 10000, currentAmount: 5000)  // 50%
        ]

        let summary = GoalsSummary(goals: goals)

        XCTAssertEqual(summary.overallProgress, 0.5, accuracy: 0.01)
    }

    func test_overallProgress_returnsZeroWhenNoTargetAmount() {
        let summary = GoalsSummary(goals: [])

        XCTAssertEqual(summary.overallProgress, 0)
    }

    func test_achievementRate_calculatesCorrectly() {
        let goals = [
            TestFixtures.goal(id: "1", targetAmount: 100, currentAmount: 100), // Achieved
            TestFixtures.goal(id: "2", targetAmount: 100, currentAmount: 50),
            TestFixtures.goal(id: "3", targetAmount: 100, currentAmount: 100), // Achieved
            TestFixtures.goal(id: "4", targetAmount: 100, currentAmount: 25)
        ]

        let summary = GoalsSummary(goals: goals)

        XCTAssertEqual(summary.achievementRate, 0.5, accuracy: 0.01) // 2 of 4 achieved
    }
}
