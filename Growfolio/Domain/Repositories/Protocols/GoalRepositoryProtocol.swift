//
//  GoalRepositoryProtocol.swift
//  Growfolio
//
//  Protocol defining the goal repository interface.
//

import Foundation

/// Protocol for goal data operations
protocol GoalRepositoryProtocol: Sendable {

    // MARK: - Fetch Operations

    /// Fetch all goals for the current user
    /// - Parameters:
    ///   - includeArchived: Whether to include archived goals
    /// - Returns: Array of goals
    func fetchGoals(includeArchived: Bool) async throws -> [Goal]

    /// Fetch a specific goal by ID
    /// - Parameter id: Goal identifier
    /// - Returns: The goal if found
    func fetchGoal(id: String) async throws -> Goal

    /// Fetch goals with pagination
    /// - Parameters:
    ///   - page: Page number (1-indexed)
    ///   - limit: Number of items per page
    ///   - includeArchived: Whether to include archived goals
    /// - Returns: Paginated response containing goals
    func fetchGoals(page: Int, limit: Int, includeArchived: Bool) async throws -> PaginatedResponse<Goal>

    /// Fetch goals by category
    /// - Parameter category: Goal category to filter by
    /// - Returns: Array of goals in the category
    func fetchGoals(category: GoalCategory) async throws -> [Goal]

    /// Fetch goals linked to a specific portfolio
    /// - Parameter portfolioId: Portfolio identifier
    /// - Returns: Array of goals linked to the portfolio
    func fetchGoals(linkedToPortfolio portfolioId: String) async throws -> [Goal]

    // MARK: - Create Operations

    /// Create a new goal
    /// - Parameter goal: Goal to create
    /// - Returns: The created goal with server-assigned ID
    func createGoal(_ goal: Goal) async throws -> Goal

    /// Create a goal with the specified parameters
    /// - Parameters:
    ///   - name: Goal name
    ///   - targetAmount: Target amount to reach
    ///   - targetDate: Optional target date
    ///   - category: Goal category
    ///   - linkedPortfolioId: Optional linked portfolio ID
    ///   - notes: Optional notes
    /// - Returns: The created goal
    func createGoal(
        name: String,
        targetAmount: Decimal,
        targetDate: Date?,
        category: GoalCategory,
        linkedPortfolioId: String?,
        notes: String?
    ) async throws -> Goal

    // MARK: - Update Operations

    /// Update an existing goal
    /// - Parameter goal: Goal with updated values
    /// - Returns: The updated goal
    func updateGoal(_ goal: Goal) async throws -> Goal

    /// Update goal progress (current amount)
    /// - Parameters:
    ///   - id: Goal identifier
    ///   - currentAmount: New current amount
    /// - Returns: The updated goal
    func updateGoalProgress(id: String, currentAmount: Decimal) async throws -> Goal

    /// Archive a goal
    /// - Parameter id: Goal identifier
    /// - Returns: The archived goal
    func archiveGoal(id: String) async throws -> Goal

    /// Unarchive a goal
    /// - Parameter id: Goal identifier
    /// - Returns: The unarchived goal
    func unarchiveGoal(id: String) async throws -> Goal

    /// Link a goal to a portfolio
    /// - Parameters:
    ///   - goalId: Goal identifier
    ///   - portfolioId: Portfolio identifier
    /// - Returns: The updated goal
    func linkGoalToPortfolio(goalId: String, portfolioId: String) async throws -> Goal

    /// Unlink a goal from its portfolio
    /// - Parameter goalId: Goal identifier
    /// - Returns: The updated goal
    func unlinkGoalFromPortfolio(goalId: String) async throws -> Goal

    // MARK: - Delete Operations

    /// Delete a goal
    /// - Parameter id: Goal identifier
    func deleteGoal(id: String) async throws

    /// Delete multiple goals
    /// - Parameter ids: Array of goal identifiers
    func deleteGoals(ids: [String]) async throws

    // MARK: - Milestone Operations

    /// Fetch milestones for a goal
    /// - Parameter goalId: Goal identifier
    /// - Returns: Array of milestones
    func fetchMilestones(for goalId: String) async throws -> [GoalMilestone]

    /// Add a milestone to a goal
    /// - Parameters:
    ///   - milestone: Milestone to add
    ///   - goalId: Goal identifier
    /// - Returns: The created milestone
    func addMilestone(_ milestone: GoalMilestone, to goalId: String) async throws -> GoalMilestone

    /// Update a milestone
    /// - Parameter milestone: Milestone with updated values
    /// - Returns: The updated milestone
    func updateMilestone(_ milestone: GoalMilestone) async throws -> GoalMilestone

    /// Delete a milestone
    /// - Parameters:
    ///   - milestoneId: Milestone identifier
    ///   - goalId: Goal identifier
    func deleteMilestone(id milestoneId: String, from goalId: String) async throws

    // MARK: - Positions Operations

    /// Fetch positions summary for a goal with linked DCA schedules
    /// - Parameter goalId: Goal identifier
    /// - Returns: Positions summary if goal has linked DCA schedules, nil otherwise
    func fetchGoalPositions(goalId: String) async throws -> GoalPositionsSummary?

    // MARK: - Summary Operations

    /// Get summary statistics for all goals
    /// - Returns: Goals summary
    func fetchGoalsSummary() async throws -> GoalsSummary

    /// Sync goal progress from linked portfolio
    /// - Parameter goalId: Goal identifier
    /// - Returns: The updated goal with synced progress
    func syncGoalProgress(goalId: String) async throws -> Goal

    // MARK: - Cache Operations

    /// Invalidate cached goals
    func invalidateCache() async

    /// Prefetch goals for offline access
    func prefetchGoals() async throws
}

// MARK: - Default Implementations

extension GoalRepositoryProtocol {
    func fetchGoals(includeArchived: Bool = false) async throws -> [Goal] {
        try await fetchGoals(includeArchived: includeArchived)
    }

    func fetchGoals(page: Int = 1, limit: Int = Constants.API.defaultPageSize, includeArchived: Bool = false) async throws -> PaginatedResponse<Goal> {
        try await fetchGoals(page: page, limit: limit, includeArchived: includeArchived)
    }
}

// MARK: - Goal Repository Error

/// Errors specific to goal operations
enum GoalRepositoryError: LocalizedError {
    case goalNotFound(id: String)
    case invalidGoalData
    case portfolioNotFound(id: String)
    case milestoneNotFound(id: String)
    case cannotDeleteAchievedGoal
    case duplicateGoalName
    case invalidTargetAmount
    case invalidTargetDate

    var errorDescription: String? {
        switch self {
        case .goalNotFound(let id):
            return "Goal with ID '\(id)' was not found"
        case .invalidGoalData:
            return "The goal data is invalid"
        case .portfolioNotFound(let id):
            return "Portfolio with ID '\(id)' was not found"
        case .milestoneNotFound(let id):
            return "Milestone with ID '\(id)' was not found"
        case .cannotDeleteAchievedGoal:
            return "Achieved goals cannot be deleted. Archive instead."
        case .duplicateGoalName:
            return "A goal with this name already exists"
        case .invalidTargetAmount:
            return "Target amount must be greater than zero"
        case .invalidTargetDate:
            return "Target date must be in the future"
        }
    }
}
