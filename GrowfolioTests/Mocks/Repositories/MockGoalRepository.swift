//
//  MockGoalRepository.swift
//  GrowfolioTests
//
//  Mock goal repository for testing.
//

import Foundation
@testable import Growfolio

/// Mock goal repository that returns predefined responses for testing
final class MockGoalRepository: GoalRepositoryProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    var goalsToReturn: [Goal] = []
    var goalToReturn: Goal?
    var paginatedGoalsToReturn: PaginatedResponse<Goal>?
    var goalsSummaryToReturn: GoalsSummary?
    var goalPositionsToReturn: GoalPositionsSummary?
    var milestonesToReturn: [GoalMilestone] = []
    var milestoneToReturn: GoalMilestone?
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var fetchGoalsCalled = false
    var fetchGoalsIncludeArchived: Bool?
    var fetchGoalCalled = false
    var lastFetchedGoalId: String?
    var fetchGoalsPaginatedCalled = false
    var fetchGoalsByCategoryCalled = false
    var lastFetchedCategory: GoalCategory?
    var fetchGoalsLinkedToPortfolioCalled = false
    var lastLinkedPortfolioId: String?
    var createGoalCalled = false
    var lastCreatedGoal: Goal?
    var lastCreateGoalParams: (name: String, targetAmount: Decimal, targetDate: Date?, category: GoalCategory, linkedPortfolioId: String?, notes: String?)?
    var updateGoalCalled = false
    var lastUpdatedGoal: Goal?
    var updateGoalProgressCalled = false
    var lastProgressUpdateId: String?
    var lastProgressAmount: Decimal?
    var archiveGoalCalled = false
    var lastArchivedGoalId: String?
    var unarchiveGoalCalled = false
    var lastUnarchivedGoalId: String?
    var linkGoalToPortfolioCalled = false
    var unlinkGoalFromPortfolioCalled = false
    var deleteGoalCalled = false
    var lastDeletedGoalId: String?
    var deleteGoalsCalled = false
    var lastDeletedGoalIds: [String]?
    var fetchMilestonesCalled = false
    var addMilestoneCalled = false
    var updateMilestoneCalled = false
    var deleteMilestoneCalled = false
    var fetchGoalPositionsCalled = false
    var lastFetchedGoalPositionsId: String?
    var fetchGoalsSummaryCalled = false
    var syncGoalProgressCalled = false
    var invalidateCacheCalled = false
    var prefetchGoalsCalled = false

    // MARK: - Reset

    func reset() {
        goalsToReturn = []
        goalToReturn = nil
        paginatedGoalsToReturn = nil
        goalsSummaryToReturn = nil
        goalPositionsToReturn = nil
        milestonesToReturn = []
        milestoneToReturn = nil
        errorToThrow = nil

        fetchGoalsCalled = false
        fetchGoalsIncludeArchived = nil
        fetchGoalCalled = false
        lastFetchedGoalId = nil
        fetchGoalsPaginatedCalled = false
        fetchGoalsByCategoryCalled = false
        lastFetchedCategory = nil
        fetchGoalsLinkedToPortfolioCalled = false
        lastLinkedPortfolioId = nil
        createGoalCalled = false
        lastCreatedGoal = nil
        lastCreateGoalParams = nil
        updateGoalCalled = false
        lastUpdatedGoal = nil
        updateGoalProgressCalled = false
        lastProgressUpdateId = nil
        lastProgressAmount = nil
        archiveGoalCalled = false
        lastArchivedGoalId = nil
        unarchiveGoalCalled = false
        lastUnarchivedGoalId = nil
        linkGoalToPortfolioCalled = false
        unlinkGoalFromPortfolioCalled = false
        deleteGoalCalled = false
        lastDeletedGoalId = nil
        deleteGoalsCalled = false
        lastDeletedGoalIds = nil
        fetchMilestonesCalled = false
        addMilestoneCalled = false
        updateMilestoneCalled = false
        deleteMilestoneCalled = false
        fetchGoalPositionsCalled = false
        lastFetchedGoalPositionsId = nil
        fetchGoalsSummaryCalled = false
        syncGoalProgressCalled = false
        invalidateCacheCalled = false
        prefetchGoalsCalled = false
    }

    // MARK: - GoalRepositoryProtocol Implementation

    func fetchGoals(includeArchived: Bool) async throws -> [Goal] {
        fetchGoalsCalled = true
        fetchGoalsIncludeArchived = includeArchived
        if let error = errorToThrow { throw error }
        return goalsToReturn
    }

    func fetchGoal(id: String) async throws -> Goal {
        fetchGoalCalled = true
        lastFetchedGoalId = id
        if let error = errorToThrow { throw error }
        if let goal = goalToReturn { return goal }
        throw GoalRepositoryError.goalNotFound(id: id)
    }

    func fetchGoals(page: Int, limit: Int, includeArchived: Bool) async throws -> PaginatedResponse<Goal> {
        fetchGoalsPaginatedCalled = true
        fetchGoalsIncludeArchived = includeArchived
        if let error = errorToThrow { throw error }
        if let paginated = paginatedGoalsToReturn { return paginated }
        return PaginatedResponse(
            data: goalsToReturn,
            pagination: PaginatedResponse<Goal>.Pagination(
                page: page,
                limit: limit,
                totalPages: 1,
                totalItems: goalsToReturn.count
            )
        )
    }

    func fetchGoals(category: GoalCategory) async throws -> [Goal] {
        fetchGoalsByCategoryCalled = true
        lastFetchedCategory = category
        if let error = errorToThrow { throw error }
        return goalsToReturn.filter { $0.category == category }
    }

    func fetchGoals(linkedToPortfolio portfolioId: String) async throws -> [Goal] {
        fetchGoalsLinkedToPortfolioCalled = true
        lastLinkedPortfolioId = portfolioId
        if let error = errorToThrow { throw error }
        return goalsToReturn.filter { $0.linkedPortfolioId == portfolioId }
    }

    func createGoal(_ goal: Goal) async throws -> Goal {
        createGoalCalled = true
        lastCreatedGoal = goal
        if let error = errorToThrow { throw error }
        return goal
    }

    func createGoal(
        name: String,
        targetAmount: Decimal,
        targetDate: Date?,
        category: GoalCategory,
        linkedPortfolioId: String?,
        notes: String?
    ) async throws -> Goal {
        createGoalCalled = true
        lastCreateGoalParams = (name, targetAmount, targetDate, category, linkedPortfolioId, notes)
        if let error = errorToThrow { throw error }
        let goal = Goal(
            userId: "user-123",
            name: name,
            targetAmount: targetAmount,
            targetDate: targetDate,
            linkedPortfolioId: linkedPortfolioId,
            category: category,
            notes: notes
        )
        return goal
    }

    func updateGoal(_ goal: Goal) async throws -> Goal {
        updateGoalCalled = true
        lastUpdatedGoal = goal
        if let error = errorToThrow { throw error }
        return goal
    }

    func updateGoalProgress(id: String, currentAmount: Decimal) async throws -> Goal {
        updateGoalProgressCalled = true
        lastProgressUpdateId = id
        lastProgressAmount = currentAmount
        if let error = errorToThrow { throw error }
        if var goal = goalToReturn {
            goal.currentAmount = currentAmount
            return goal
        }
        throw GoalRepositoryError.goalNotFound(id: id)
    }

    func archiveGoal(id: String) async throws -> Goal {
        archiveGoalCalled = true
        lastArchivedGoalId = id
        if let error = errorToThrow { throw error }
        if var goal = goalToReturn {
            goal.isArchived = true
            return goal
        }
        throw GoalRepositoryError.goalNotFound(id: id)
    }

    func unarchiveGoal(id: String) async throws -> Goal {
        unarchiveGoalCalled = true
        lastUnarchivedGoalId = id
        if let error = errorToThrow { throw error }
        if var goal = goalToReturn {
            goal.isArchived = false
            return goal
        }
        throw GoalRepositoryError.goalNotFound(id: id)
    }

    func linkGoalToPortfolio(goalId: String, portfolioId: String) async throws -> Goal {
        linkGoalToPortfolioCalled = true
        if let error = errorToThrow { throw error }
        if var goal = goalToReturn {
            goal.linkedPortfolioId = portfolioId
            return goal
        }
        throw GoalRepositoryError.goalNotFound(id: goalId)
    }

    func unlinkGoalFromPortfolio(goalId: String) async throws -> Goal {
        unlinkGoalFromPortfolioCalled = true
        if let error = errorToThrow { throw error }
        if var goal = goalToReturn {
            goal.linkedPortfolioId = nil
            return goal
        }
        throw GoalRepositoryError.goalNotFound(id: goalId)
    }

    func deleteGoal(id: String) async throws {
        deleteGoalCalled = true
        lastDeletedGoalId = id
        if let error = errorToThrow { throw error }
    }

    func deleteGoals(ids: [String]) async throws {
        deleteGoalsCalled = true
        lastDeletedGoalIds = ids
        if let error = errorToThrow { throw error }
    }

    func fetchMilestones(for goalId: String) async throws -> [GoalMilestone] {
        fetchMilestonesCalled = true
        if let error = errorToThrow { throw error }
        return milestonesToReturn
    }

    func addMilestone(_ milestone: GoalMilestone, to goalId: String) async throws -> GoalMilestone {
        addMilestoneCalled = true
        if let error = errorToThrow { throw error }
        return milestone
    }

    func updateMilestone(_ milestone: GoalMilestone) async throws -> GoalMilestone {
        updateMilestoneCalled = true
        if let error = errorToThrow { throw error }
        return milestone
    }

    func deleteMilestone(id milestoneId: String, from goalId: String) async throws {
        deleteMilestoneCalled = true
        if let error = errorToThrow { throw error }
    }

    func fetchGoalPositions(goalId: String) async throws -> GoalPositionsSummary? {
        fetchGoalPositionsCalled = true
        lastFetchedGoalPositionsId = goalId
        if let error = errorToThrow { throw error }
        return goalPositionsToReturn
    }

    func fetchGoalsSummary() async throws -> GoalsSummary {
        fetchGoalsSummaryCalled = true
        if let error = errorToThrow { throw error }
        if let summary = goalsSummaryToReturn { return summary }
        return GoalsSummary(goals: goalsToReturn)
    }

    func syncGoalProgress(goalId: String) async throws -> Goal {
        syncGoalProgressCalled = true
        if let error = errorToThrow { throw error }
        if let goal = goalToReturn { return goal }
        throw GoalRepositoryError.goalNotFound(id: goalId)
    }

    func invalidateCache() async {
        invalidateCacheCalled = true
    }

    func prefetchGoals() async throws {
        prefetchGoalsCalled = true
        if let error = errorToThrow { throw error }
    }
}
