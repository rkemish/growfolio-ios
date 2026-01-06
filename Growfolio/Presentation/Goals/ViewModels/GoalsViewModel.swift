//
//  GoalsViewModel.swift
//  Growfolio
//
//  View model for the goals list and management.
//

import Foundation
import SwiftUI

@Observable
final class GoalsViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Loading State
    var isLoading = false
    var isRefreshing = false
    var error: Error?

    // Goals Data
    var goals: [Goal] = []
    var selectedGoal: Goal?
    var selectedGoalPositions: GoalPositionsSummary?

    // Filter State
    var showArchived = false
    var filterCategory: GoalCategory?
    var sortOrder: GoalSortOrder = .progress

    // Sheet Presentation
    var showCreateGoal = false
    var showGoalDetail = false
    var goalToEdit: Goal?

    // Repository
    private let repository: GoalRepositoryProtocol

    // MARK: - Computed Properties

    var filteredGoals: [Goal] {
        var filtered = showArchived ? goals : goals.filter { !$0.isArchived }

        if let category = filterCategory {
            filtered = filtered.filter { $0.category == category }
        }

        return sortGoals(filtered, by: sortOrder)
    }

    var activeGoalsCount: Int {
        goals.filter { !$0.isArchived && !$0.isAchieved }.count
    }

    var achievedGoalsCount: Int {
        goals.filter { $0.isAchieved }.count
    }

    var summary: GoalsSummary {
        GoalsSummary(goals: goals.filter { !$0.isArchived })
    }

    var hasGoals: Bool {
        !goals.isEmpty
    }

    var isEmpty: Bool {
        filteredGoals.isEmpty && !isLoading
    }

    // MARK: - Initialization

    init(repository: GoalRepositoryProtocol = RepositoryContainer.goalRepository) {
        self.repository = repository
    }

    // MARK: - Data Loading

    @MainActor
    func loadGoals() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            goals = try await repository.fetchGoals(includeArchived: true)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func refreshGoals() async {
        isRefreshing = true
        await repository.invalidateCache()
        await loadGoals()
        isRefreshing = false
    }

    func refresh() {
        Task { @MainActor in
            await refreshGoals()
        }
    }

    // MARK: - CRUD Operations

    @MainActor
    func createGoal(
        name: String,
        targetAmount: Decimal,
        targetDate: Date?,
        category: GoalCategory,
        notes: String?
    ) async throws {
        let _ = try await repository.createGoal(
            name: name,
            targetAmount: targetAmount,
            targetDate: targetDate,
            category: category,
            linkedPortfolioId: nil,
            notes: notes
        )

        // Refresh to get updated list
        await refreshGoals()
    }

    @MainActor
    func updateGoal(_ goal: Goal) async throws {
        let _ = try await repository.updateGoal(goal)
        await refreshGoals()
    }

    @MainActor
    func deleteGoal(_ goal: Goal) async throws {
        try await repository.deleteGoal(id: goal.id)
        goals.removeAll { $0.id == goal.id }
    }

    @MainActor
    func archiveGoal(_ goal: Goal) async throws {
        let _ = try await repository.archiveGoal(id: goal.id)
        await refreshGoals()
    }

    @MainActor
    func unarchiveGoal(_ goal: Goal) async throws {
        let _ = try await repository.unarchiveGoal(id: goal.id)
        await refreshGoals()
    }

    // MARK: - Selection

    func selectGoal(_ goal: Goal) {
        selectedGoal = goal
        selectedGoalPositions = nil
        showGoalDetail = true

        // Fetch positions in background if goal has linked DCA schedules
        if goal.hasLinkedDCASchedules {
            Task { @MainActor in
                await fetchGoalPositions(for: goal)
            }
        }
    }

    @MainActor
    func fetchGoalPositions(for goal: Goal) async {
        do {
            selectedGoalPositions = try await repository.fetchGoalPositions(goalId: goal.id)
        } catch {
            // Silently fail - positions are supplementary data
            print("Failed to fetch goal positions: \(error)")
        }
    }

    func editGoal(_ goal: Goal) {
        goalToEdit = goal
        showCreateGoal = true
    }

    // MARK: - Sorting

    private func sortGoals(_ goals: [Goal], by order: GoalSortOrder) -> [Goal] {
        switch order {
        case .name:
            return goals.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .targetAmount:
            return goals.sorted { $0.targetAmount > $1.targetAmount }
        case .progress:
            return goals.sorted { $0.progress > $1.progress }
        case .targetDate:
            return goals.sorted { goal1, goal2 in
                guard let date1 = goal1.targetDate else { return false }
                guard let date2 = goal2.targetDate else { return true }
                return date1 < date2
            }
        case .createdAt:
            return goals.sorted { $0.createdAt > $1.createdAt }
        }
    }
}

// MARK: - Goal Sort Order

enum GoalSortOrder: String, CaseIterable, Sendable {
    case progress
    case name
    case targetAmount
    case targetDate
    case createdAt

    var displayName: String {
        switch self {
        case .progress:
            return "Progress"
        case .name:
            return "Name"
        case .targetAmount:
            return "Target Amount"
        case .targetDate:
            return "Target Date"
        case .createdAt:
            return "Date Created"
        }
    }

    var iconName: String {
        switch self {
        case .progress:
            return "chart.bar.fill"
        case .name:
            return "textformat.abc"
        case .targetAmount:
            return "dollarsign.circle.fill"
        case .targetDate:
            return "calendar"
        case .createdAt:
            return "clock.fill"
        }
    }
}
