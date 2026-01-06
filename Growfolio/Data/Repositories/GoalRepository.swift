//
//  GoalRepository.swift
//  Growfolio
//
//  Implementation of GoalRepositoryProtocol using the API client.
//

import Foundation

/// Implementation of the goal repository using the API client
final class GoalRepository: GoalRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let apiClient: APIClientProtocol
    private var cachedGoals: [Goal] = []
    private var lastFetchTime: Date?
    private let cacheDuration: TimeInterval = 60 // 1 minute cache

    // MARK: - Initialization

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - Fetch Operations

    func fetchGoals(includeArchived: Bool) async throws -> [Goal] {
        // Check cache first
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheDuration,
           !cachedGoals.isEmpty {
            return includeArchived ? cachedGoals : cachedGoals.filter { !$0.isArchived }
        }

        let response: PaginatedResponse<Goal> = try await apiClient.request(
            Endpoints.GetGoals(page: 1, limit: Constants.API.maxPageSize)
        )

        cachedGoals = response.data
        lastFetchTime = Date()

        return includeArchived ? response.data : response.data.filter { !$0.isArchived }
    }

    func fetchGoal(id: String) async throws -> Goal {
        // Check cache first
        if let cached = cachedGoals.first(where: { $0.id == id }) {
            return cached
        }

        return try await apiClient.request(Endpoints.GetGoal(id: id))
    }

    func fetchGoals(page: Int, limit: Int, includeArchived: Bool) async throws -> PaginatedResponse<Goal> {
        let response: PaginatedResponse<Goal> = try await apiClient.request(
            Endpoints.GetGoals(page: page, limit: limit)
        )

        // Update cache if fetching first page
        if page == 1 {
            cachedGoals = response.data
            lastFetchTime = Date()
        }

        // Filter archived if needed
        if !includeArchived {
            let filteredData = response.data.filter { !$0.isArchived }
            return PaginatedResponse(
                data: filteredData,
                pagination: response.pagination
            )
        }

        return response
    }

    func fetchGoals(category: GoalCategory) async throws -> [Goal] {
        let goals = try await fetchGoals(includeArchived: false)
        return goals.filter { $0.category == category }
    }

    func fetchGoals(linkedToPortfolio portfolioId: String) async throws -> [Goal] {
        let goals = try await fetchGoals(includeArchived: false)
        return goals.filter { $0.linkedPortfolioId == portfolioId }
    }

    // MARK: - Create Operations

    func createGoal(_ goal: Goal) async throws -> Goal {
        let request = GoalCreateRequest(
            name: goal.name,
            targetAmount: goal.targetAmount,
            targetDate: goal.targetDate,
            linkedPortfolioId: goal.linkedPortfolioId,
            notes: goal.notes
        )

        let createdGoal: Goal = try await apiClient.request(
            try Endpoints.CreateGoal(goal: request)
        )

        // Update cache
        cachedGoals.append(createdGoal)

        return createdGoal
    }

    func createGoal(
        name: String,
        targetAmount: Decimal,
        targetDate: Date?,
        category: GoalCategory,
        linkedPortfolioId: String?,
        notes: String?
    ) async throws -> Goal {
        let request = GoalCreateRequest(
            name: name,
            targetAmount: targetAmount,
            targetDate: targetDate,
            linkedPortfolioId: linkedPortfolioId,
            notes: notes
        )

        let createdGoal: Goal = try await apiClient.request(
            try Endpoints.CreateGoal(goal: request)
        )

        // Update cache
        cachedGoals.append(createdGoal)

        return createdGoal
    }

    // MARK: - Update Operations

    func updateGoal(_ goal: Goal) async throws -> Goal {
        let request = GoalUpdateRequest(
            name: goal.name,
            targetAmount: goal.targetAmount,
            targetDate: goal.targetDate,
            notes: goal.notes,
            isArchived: goal.isArchived
        )

        let updatedGoal: Goal = try await apiClient.request(
            try Endpoints.UpdateGoal(id: goal.id, update: request)
        )

        // Update cache
        if let index = cachedGoals.firstIndex(where: { $0.id == goal.id }) {
            cachedGoals[index] = updatedGoal
        }

        return updatedGoal
    }

    func updateGoalProgress(id: String, currentAmount: Decimal) async throws -> Goal {
        // Fetch current goal to get other fields
        var goal = try await fetchGoal(id: id)
        goal.currentAmount = currentAmount
        return try await updateGoal(goal)
    }

    func archiveGoal(id: String) async throws -> Goal {
        let request = GoalUpdateRequest(isArchived: true)

        let updatedGoal: Goal = try await apiClient.request(
            try Endpoints.UpdateGoal(id: id, update: request)
        )

        // Update cache
        if let index = cachedGoals.firstIndex(where: { $0.id == id }) {
            cachedGoals[index] = updatedGoal
        }

        return updatedGoal
    }

    func unarchiveGoal(id: String) async throws -> Goal {
        let request = GoalUpdateRequest(isArchived: false)

        let updatedGoal: Goal = try await apiClient.request(
            try Endpoints.UpdateGoal(id: id, update: request)
        )

        // Update cache
        if let index = cachedGoals.firstIndex(where: { $0.id == id }) {
            cachedGoals[index] = updatedGoal
        }

        return updatedGoal
    }

    func linkGoalToPortfolio(goalId: String, portfolioId: String) async throws -> Goal {
        var goal = try await fetchGoal(id: goalId)
        goal.linkedPortfolioId = portfolioId
        return try await updateGoal(goal)
    }

    func unlinkGoalFromPortfolio(goalId: String) async throws -> Goal {
        var goal = try await fetchGoal(id: goalId)
        goal.linkedPortfolioId = nil
        return try await updateGoal(goal)
    }

    // MARK: - Delete Operations

    func deleteGoal(id: String) async throws {
        try await apiClient.request(Endpoints.DeleteGoal(id: id))

        // Update cache
        cachedGoals.removeAll { $0.id == id }
    }

    func deleteGoals(ids: [String]) async throws {
        // Delete each goal
        for id in ids {
            try await deleteGoal(id: id)
        }
    }

    // MARK: - Milestone Operations

    func fetchMilestones(for goalId: String) async throws -> [GoalMilestone] {
        // Milestones are embedded in the goal model
        let goal = try await fetchGoal(id: goalId)
        // For now, return empty array - milestones would need to be added to Goal model or fetched separately
        return []
    }

    func addMilestone(_ milestone: GoalMilestone, to goalId: String) async throws -> GoalMilestone {
        // This would require a separate API endpoint
        throw GoalRepositoryError.invalidGoalData
    }

    func updateMilestone(_ milestone: GoalMilestone) async throws -> GoalMilestone {
        // This would require a separate API endpoint
        throw GoalRepositoryError.milestoneNotFound(id: milestone.id)
    }

    func deleteMilestone(id milestoneId: String, from goalId: String) async throws {
        // This would require a separate API endpoint
        throw GoalRepositoryError.milestoneNotFound(id: milestoneId)
    }

    // MARK: - Positions Operations

    func fetchGoalPositions(goalId: String) async throws -> GoalPositionsSummary? {
        // This would require integration with DCA repository to aggregate positions
        // For now, return nil - positions data comes from linked DCA schedules
        return nil
    }

    // MARK: - Summary Operations

    func fetchGoalsSummary() async throws -> GoalsSummary {
        let goals = try await fetchGoals(includeArchived: false)
        return GoalsSummary(goals: goals)
    }

    func syncGoalProgress(goalId: String) async throws -> Goal {
        // Fetch latest data from server
        await invalidateCache()
        return try await fetchGoal(id: goalId)
    }

    // MARK: - Cache Operations

    func invalidateCache() async {
        cachedGoals = []
        lastFetchTime = nil
    }

    func prefetchGoals() async throws {
        _ = try await fetchGoals(includeArchived: true)
    }
}
