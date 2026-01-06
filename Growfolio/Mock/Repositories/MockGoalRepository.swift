//
//  MockGoalRepository.swift
//  Growfolio
//
//  Mock implementation of GoalRepositoryProtocol for demo mode.
//

import Foundation

/// Mock implementation of GoalRepositoryProtocol
final class MockGoalRepository: GoalRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let store = MockDataStore.shared
    private let config = MockConfiguration.shared

    // MARK: - Fetch Operations

    func fetchGoals(includeArchived: Bool = false) async throws -> [Goal] {
        try await simulateNetwork()
        await ensureInitialized()

        let goals = await store.goals
        if includeArchived {
            return goals
        }
        return goals.filter { !$0.isArchived }
    }

    func fetchGoal(id: String) async throws -> Goal {
        try await simulateNetwork()

        guard let goal = await store.goals.first(where: { $0.id == id }) else {
            throw GoalRepositoryError.goalNotFound(id: id)
        }
        return goal
    }

    func fetchGoals(page: Int, limit: Int, includeArchived: Bool = false) async throws -> PaginatedResponse<Goal> {
        try await simulateNetwork()
        await ensureInitialized()

        var allGoals = await store.goals
        if !includeArchived {
            allGoals = allGoals.filter { !$0.isArchived }
        }

        let startIndex = (page - 1) * limit
        let endIndex = min(startIndex + limit, allGoals.count)

        guard startIndex < allGoals.count else {
            let totalPages = allGoals.isEmpty ? 1 : (allGoals.count + limit - 1) / limit
            return PaginatedResponse(
                data: [],
                pagination: PaginatedResponse.Pagination(page: page, limit: limit, totalPages: totalPages, totalItems: allGoals.count)
            )
        }

        let pageItems = Array(allGoals[startIndex..<endIndex])
        let totalPages = (allGoals.count + limit - 1) / limit
        return PaginatedResponse(
            data: pageItems,
            pagination: PaginatedResponse.Pagination(page: page, limit: limit, totalPages: totalPages, totalItems: allGoals.count)
        )
    }

    func fetchGoals(category: GoalCategory) async throws -> [Goal] {
        try await simulateNetwork()
        await ensureInitialized()

        return await store.goals.filter { $0.category == category && !$0.isArchived }
    }

    func fetchGoals(linkedToPortfolio portfolioId: String) async throws -> [Goal] {
        try await simulateNetwork()

        return await store.goals.filter { $0.linkedPortfolioId == portfolioId && !$0.isArchived }
    }

    // MARK: - Create Operations

    func createGoal(_ goal: Goal) async throws -> Goal {
        try await simulateNetwork()
        await ensureInitialized()

        let userId = await store.currentUser?.id ?? "mock"

        let newGoal = Goal(
            id: MockDataGenerator.mockId(prefix: "goal"),
            userId: userId,
            name: goal.name,
            targetAmount: goal.targetAmount,
            currentAmount: goal.currentAmount,
            targetDate: goal.targetDate,
            linkedPortfolioId: goal.linkedPortfolioId,
            category: goal.category,
            iconName: goal.iconName,
            colorHex: goal.colorHex,
            notes: goal.notes,
            createdAt: Date(),
            updatedAt: Date()
        )

        await store.addGoal(newGoal)
        return newGoal
    }

    func createGoal(
        name: String,
        targetAmount: Decimal,
        targetDate: Date?,
        category: GoalCategory,
        linkedPortfolioId: String?,
        notes: String?
    ) async throws -> Goal {
        let goal = Goal(
            userId: await store.currentUser?.id ?? "mock",
            name: name,
            targetAmount: targetAmount,
            currentAmount: 0,
            targetDate: targetDate,
            linkedPortfolioId: linkedPortfolioId,
            category: category,
            iconName: category.iconName,
            colorHex: category.defaultColorHex,
            notes: notes
        )
        return try await createGoal(goal)
    }

    // MARK: - Update Operations

    func updateGoal(_ goal: Goal) async throws -> Goal {
        try await simulateNetwork()

        var updatedGoal = goal
        updatedGoal.updatedAt = Date()
        await store.updateGoal(updatedGoal)
        return updatedGoal
    }

    func updateGoalProgress(id: String, currentAmount: Decimal) async throws -> Goal {
        try await simulateNetwork()

        guard var goal = await store.goals.first(where: { $0.id == id }) else {
            throw GoalRepositoryError.goalNotFound(id: id)
        }

        goal.currentAmount = currentAmount
        goal.updatedAt = Date()
        await store.updateGoal(goal)
        return goal
    }

    func archiveGoal(id: String) async throws -> Goal {
        try await simulateNetwork()

        guard var goal = await store.goals.first(where: { $0.id == id }) else {
            throw GoalRepositoryError.goalNotFound(id: id)
        }

        goal.isArchived = true
        goal.updatedAt = Date()
        await store.updateGoal(goal)
        return goal
    }

    func unarchiveGoal(id: String) async throws -> Goal {
        try await simulateNetwork()

        guard var goal = await store.goals.first(where: { $0.id == id }) else {
            throw GoalRepositoryError.goalNotFound(id: id)
        }

        goal.isArchived = false
        goal.updatedAt = Date()
        await store.updateGoal(goal)
        return goal
    }

    func linkGoalToPortfolio(goalId: String, portfolioId: String) async throws -> Goal {
        try await simulateNetwork()

        guard var goal = await store.goals.first(where: { $0.id == goalId }) else {
            throw GoalRepositoryError.goalNotFound(id: goalId)
        }

        goal.linkedPortfolioId = portfolioId
        goal.updatedAt = Date()
        await store.updateGoal(goal)
        return goal
    }

    func unlinkGoalFromPortfolio(goalId: String) async throws -> Goal {
        try await simulateNetwork()

        guard var goal = await store.goals.first(where: { $0.id == goalId }) else {
            throw GoalRepositoryError.goalNotFound(id: goalId)
        }

        goal.linkedPortfolioId = nil
        goal.updatedAt = Date()
        await store.updateGoal(goal)
        return goal
    }

    // MARK: - Delete Operations

    func deleteGoal(id: String) async throws {
        try await simulateNetwork()
        await store.deleteGoal(id: id)
    }

    func deleteGoals(ids: [String]) async throws {
        try await simulateNetwork()
        for id in ids {
            await store.deleteGoal(id: id)
        }
    }

    // MARK: - Milestone Operations

    func fetchMilestones(for goalId: String) async throws -> [GoalMilestone] {
        try await simulateNetwork()
        return await store.getMilestones(for: goalId)
    }

    func addMilestone(_ milestone: GoalMilestone, to goalId: String) async throws -> GoalMilestone {
        try await simulateNetwork()

        let newMilestone = GoalMilestone(
            id: MockDataGenerator.mockId(prefix: "milestone"),
            goalId: goalId,
            name: milestone.name,
            targetAmount: milestone.targetAmount
        )

        await store.addMilestone(newMilestone, to: goalId)
        return newMilestone
    }

    func updateMilestone(_ milestone: GoalMilestone) async throws -> GoalMilestone {
        try await simulateNetwork()
        // For mock, just return the milestone
        return milestone
    }

    func deleteMilestone(id milestoneId: String, from goalId: String) async throws {
        try await simulateNetwork()
        // No-op for mock
    }

    // MARK: - Positions Operations

    func fetchGoalPositions(goalId: String) async throws -> GoalPositionsSummary? {
        try await simulateNetwork()
        return await store.getGoalPositions(for: goalId)
    }

    // MARK: - Summary Operations

    func fetchGoalsSummary() async throws -> GoalsSummary {
        try await simulateNetwork()
        await ensureInitialized()
        return GoalsSummary(goals: await store.goals)
    }

    func syncGoalProgress(goalId: String) async throws -> Goal {
        try await simulateNetwork()

        guard var goal = await store.goals.first(where: { $0.id == goalId }) else {
            throw GoalRepositoryError.goalNotFound(id: goalId)
        }

        // Sync from linked portfolio if any
        if let portfolioId = goal.linkedPortfolioId {
            let holdings = await store.getHoldings(for: portfolioId)
            let portfolioValue = holdings.reduce(Decimal.zero) { $0 + $1.marketValue }
            goal.currentAmount = portfolioValue
            goal.updatedAt = Date()
            await store.updateGoal(goal)
        }

        return goal
    }

    // MARK: - Cache Operations

    func invalidateCache() async {
        // No-op for mock
    }

    func prefetchGoals() async throws {
        await ensureInitialized()
    }

    // MARK: - Private Methods

    private func simulateNetwork() async throws {
        try await config.simulateNetworkDelay()
        try config.maybeThrowSimulatedError()
    }

    private func ensureInitialized() async {
        if await store.goals.isEmpty {
            await store.initialize(for: config.demoPersona)
        }
    }
}
