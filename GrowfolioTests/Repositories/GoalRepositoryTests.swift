//
//  GoalRepositoryTests.swift
//  GrowfolioTests
//
//  Tests for GoalRepository.
//

import XCTest
@testable import Growfolio

final class GoalRepositoryTests: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var sut: GoalRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = GoalRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        mockAPIClient.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeGoal(
        id: String = "goal-1",
        name: String = "Retirement Fund",
        targetAmount: Decimal = 100000,
        currentAmount: Decimal = 25000,
        isArchived: Bool = false
    ) -> Goal {
        Goal(
            id: id,
            userId: "user-1",
            name: name,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: Date().addingTimeInterval(86400 * 365),
            category: .retirement,
            isArchived: isArchived
        )
    }

    private func makePaginatedResponse(goals: [Goal]) -> PaginatedResponse<Goal> {
        PaginatedResponse(
            data: goals,
            pagination: PaginatedResponse<Goal>.Pagination(
                page: 1,
                limit: 50,
                totalPages: 1,
                totalItems: goals.count
            )
        )
    }

    // MARK: - Fetch Goals Tests

    func test_fetchGoals_returnsGoalsFromAPI() async throws {
        // Arrange
        let expectedGoals = [
            makeGoal(id: "goal-1", name: "Retirement"),
            makeGoal(id: "goal-2", name: "Education")
        ]
        let response = makePaginatedResponse(goals: expectedGoals)
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)

        // Act
        let goals = try await sut.fetchGoals(includeArchived: true)

        // Assert
        XCTAssertEqual(goals.count, expectedGoals.count)
        XCTAssertEqual(goals[0].id, "goal-1")
        XCTAssertEqual(goals[1].id, "goal-2")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchGoals_filtersArchivedWhenNotIncluded() async throws {
        // Arrange
        let goals = [
            makeGoal(id: "goal-1", isArchived: false),
            makeGoal(id: "goal-2", isArchived: true),
            makeGoal(id: "goal-3", isArchived: false)
        ]
        let response = makePaginatedResponse(goals: goals)
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)

        // Act
        let result = try await sut.fetchGoals(includeArchived: false)

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertFalse(result.contains(where: { $0.id == "goal-2" }))
    }

    func test_fetchGoals_usesCache() async throws {
        // Arrange
        let expectedGoals = [makeGoal()]
        let response = makePaginatedResponse(goals: expectedGoals)
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)

        // Act - First call populates cache
        _ = try await sut.fetchGoals(includeArchived: true)

        // Act - Second call should use cache
        let result = try await sut.fetchGoals(includeArchived: true)

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1) // Only one API call made
    }

    func test_fetchGoals_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Internal error"), for: Endpoints.GetGoals.self)

        // Act & Assert
        do {
            _ = try await sut.fetchGoals(includeArchived: true)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Fetch Goal by ID Tests

    func test_fetchGoal_returnsGoalFromAPI() async throws {
        // Arrange
        let expectedGoal = makeGoal(id: "goal-123")
        mockAPIClient.setResponse(expectedGoal, for: Endpoints.GetGoal.self)

        // Act
        let goal = try await sut.fetchGoal(id: "goal-123")

        // Assert
        XCTAssertEqual(goal.id, "goal-123")
    }

    func test_fetchGoal_returnsCachedGoalIfAvailable() async throws {
        // Arrange - First populate the cache
        let cachedGoal = makeGoal(id: "goal-cached")
        let response = makePaginatedResponse(goals: [cachedGoal])
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)
        _ = try await sut.fetchGoals(includeArchived: true)
        mockAPIClient.reset()

        // Act - Fetch by ID should use cache
        let goal = try await sut.fetchGoal(id: "goal-cached")

        // Assert
        XCTAssertEqual(goal.id, "goal-cached")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0) // No API call made
    }

    // MARK: - Fetch Goals by Category Tests

    func test_fetchGoals_byCategory_filtersCorrectly() async throws {
        // Arrange
        let retirementGoal = Goal(
            id: "goal-1",
            userId: "user-1",
            name: "Retirement",
            targetAmount: 100000,
            category: .retirement
        )
        let educationGoal = Goal(
            id: "goal-2",
            userId: "user-1",
            name: "College",
            targetAmount: 50000,
            category: .education
        )
        let response = makePaginatedResponse(goals: [retirementGoal, educationGoal])
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)

        // Act
        let result = try await sut.fetchGoals(category: .retirement)

        // Assert
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.category, .retirement)
    }

    // MARK: - Create Goal Tests

    func test_createGoal_returnsCreatedGoal() async throws {
        // Arrange
        let goalToCreate = makeGoal(id: "new-goal")
        mockAPIClient.setResponse(goalToCreate, for: Endpoints.CreateGoal.self)

        // Act
        let created = try await sut.createGoal(goalToCreate)

        // Assert
        XCTAssertEqual(created.id, "new-goal")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_createGoal_updatesCache() async throws {
        // Arrange - First populate cache
        let existingGoal = makeGoal(id: "existing")
        let response = makePaginatedResponse(goals: [existingGoal])
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)
        _ = try await sut.fetchGoals(includeArchived: true)

        // Create new goal
        let newGoal = makeGoal(id: "new-goal")
        mockAPIClient.setResponse(newGoal, for: Endpoints.CreateGoal.self)

        // Act
        _ = try await sut.createGoal(newGoal)

        // Assert - Cache should now include both goals
        mockAPIClient.reset()
        let goals = try await sut.fetchGoals(includeArchived: true)
        XCTAssertEqual(goals.count, 2)
    }

    // MARK: - Update Goal Tests

    func test_updateGoal_returnsUpdatedGoal() async throws {
        // Arrange
        var goal = makeGoal(id: "goal-1", name: "Original")
        goal.name = "Updated Name"
        mockAPIClient.setResponse(goal, for: Endpoints.UpdateGoal.self)

        // Act
        let updated = try await sut.updateGoal(goal)

        // Assert
        XCTAssertEqual(updated.name, "Updated Name")
    }

    func test_archiveGoal_setsIsArchivedToTrue() async throws {
        // Arrange
        var goal = makeGoal(id: "goal-1", isArchived: false)
        goal.isArchived = true
        mockAPIClient.setResponse(goal, for: Endpoints.UpdateGoal.self)

        // Act
        let archived = try await sut.archiveGoal(id: "goal-1")

        // Assert
        XCTAssertTrue(archived.isArchived)
    }

    func test_unarchiveGoal_setsIsArchivedToFalse() async throws {
        // Arrange
        var goal = makeGoal(id: "goal-1", isArchived: true)
        goal.isArchived = false
        mockAPIClient.setResponse(goal, for: Endpoints.UpdateGoal.self)

        // Act
        let unarchived = try await sut.unarchiveGoal(id: "goal-1")

        // Assert
        XCTAssertFalse(unarchived.isArchived)
    }

    // MARK: - Delete Goal Tests

    func test_deleteGoal_removesFromCache() async throws {
        // Arrange - First populate cache
        let goal1 = makeGoal(id: "goal-1")
        let goal2 = makeGoal(id: "goal-2")
        let response = makePaginatedResponse(goals: [goal1, goal2])
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)
        _ = try await sut.fetchGoals(includeArchived: true)

        // Act
        try await sut.deleteGoal(id: "goal-1")

        // Assert - Cache should have only one goal
        mockAPIClient.reset()
        let goals = try await sut.fetchGoals(includeArchived: true)
        XCTAssertEqual(goals.count, 1)
        XCTAssertEqual(goals.first?.id, "goal-2")
    }

    // MARK: - Cache Invalidation Tests

    func test_invalidateCache_clearsCache() async throws {
        // Arrange - First populate cache
        let goal = makeGoal()
        let response = makePaginatedResponse(goals: [goal])
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)
        _ = try await sut.fetchGoals(includeArchived: true)

        // Act
        await sut.invalidateCache()

        // Reset and set up new response
        mockAPIClient.reset()
        let newResponse = makePaginatedResponse(goals: [makeGoal(id: "new-goal")])
        mockAPIClient.setResponse(newResponse, for: Endpoints.GetGoals.self)

        // Act - Should make new API call
        let goals = try await sut.fetchGoals(includeArchived: true)

        // Assert
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
        XCTAssertEqual(goals.first?.id, "new-goal")
    }

    // MARK: - Empty Response Tests

    func test_fetchGoals_returnsEmptyArrayWhenNoGoals() async throws {
        // Arrange
        let response = makePaginatedResponse(goals: [])
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)

        // Act
        let goals = try await sut.fetchGoals(includeArchived: true)

        // Assert
        XCTAssertTrue(goals.isEmpty)
    }

    // MARK: - Paginated Fetch Tests

    func test_fetchGoalsWithPagination_returnsCorrectPage() async throws {
        // Arrange
        let goals = [makeGoal(id: "goal-1"), makeGoal(id: "goal-2")]
        let response = PaginatedResponse(
            data: goals,
            pagination: PaginatedResponse<Goal>.Pagination(
                page: 2,
                limit: 10,
                totalPages: 5,
                totalItems: 50
            )
        )
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)

        // Act
        let result = try await sut.fetchGoals(page: 2, limit: 10, includeArchived: true)

        // Assert
        XCTAssertEqual(result.data.count, 2)
        XCTAssertEqual(result.pagination.page, 2)
        XCTAssertEqual(result.pagination.totalPages, 5)
    }

    // MARK: - Goals Summary Tests

    func test_fetchGoalsSummary_calculatesSummaryCorrectly() async throws {
        // Arrange
        let goals = [
            makeGoal(id: "goal-1", targetAmount: 100, currentAmount: 100), // Achieved
            makeGoal(id: "goal-2", targetAmount: 100, currentAmount: 50),  // In progress
            makeGoal(id: "goal-3", targetAmount: 100, currentAmount: 25)   // In progress
        ]
        let response = makePaginatedResponse(goals: goals)
        mockAPIClient.setResponse(response, for: Endpoints.GetGoals.self)

        // Act
        let summary = try await sut.fetchGoalsSummary()

        // Assert
        XCTAssertEqual(summary.totalGoals, 3)
        XCTAssertEqual(summary.achievedGoals, 1)
        XCTAssertEqual(summary.inProgressGoals, 2)
        XCTAssertEqual(summary.totalTargetAmount, 300)
        XCTAssertEqual(summary.totalCurrentAmount, 175)
    }
}
