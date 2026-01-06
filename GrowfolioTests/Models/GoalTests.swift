//
//  GoalTests.swift
//  GrowfolioTests
//
//  Tests for Goal domain model.
//

import XCTest
@testable import Growfolio

final class GoalTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithDefaults() {
        let goal = Goal(
            userId: "user-123",
            name: "Test Goal",
            targetAmount: 10000
        )

        XCTAssertFalse(goal.id.isEmpty)
        XCTAssertEqual(goal.userId, "user-123")
        XCTAssertEqual(goal.name, "Test Goal")
        XCTAssertEqual(goal.targetAmount, 10000)
        XCTAssertEqual(goal.currentAmount, 0)
        XCTAssertNil(goal.targetDate)
        XCTAssertNil(goal.linkedPortfolioId)
        XCTAssertEqual(goal.category, .other)
        XCTAssertEqual(goal.iconName, "target")
        XCTAssertEqual(goal.colorHex, "#007AFF")
        XCTAssertNil(goal.notes)
        XCTAssertFalse(goal.isArchived)
    }

    func testInit_WithAllParameters() {
        let goal = TestFixtures.goal(
            id: "goal-456",
            userId: "user-456",
            name: "Retirement Fund",
            targetAmount: 500000,
            currentAmount: 125000,
            targetDate: TestFixtures.futureDate,
            linkedPortfolioId: "portfolio-123",
            category: .retirement,
            iconName: "sun.horizon.fill",
            colorHex: "#FF9500",
            notes: "Long-term retirement savings",
            isArchived: false
        )

        XCTAssertEqual(goal.id, "goal-456")
        XCTAssertEqual(goal.userId, "user-456")
        XCTAssertEqual(goal.name, "Retirement Fund")
        XCTAssertEqual(goal.targetAmount, 500000)
        XCTAssertEqual(goal.currentAmount, 125000)
        XCTAssertNotNil(goal.targetDate)
        XCTAssertEqual(goal.linkedPortfolioId, "portfolio-123")
        XCTAssertEqual(goal.category, .retirement)
        XCTAssertEqual(goal.iconName, "sun.horizon.fill")
        XCTAssertEqual(goal.colorHex, "#FF9500")
        XCTAssertEqual(goal.notes, "Long-term retirement savings")
        XCTAssertFalse(goal.isArchived)
    }

    // MARK: - Progress Tests

    func testProgress_PartialProgress() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 2500
        )

        XCTAssertEqual(goal.progress, 0.25, accuracy: 0.001)
    }

    func testProgress_ZeroProgress() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 0
        )

        XCTAssertEqual(goal.progress, 0)
    }

    func testProgress_HalfwayProgress() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 5000
        )

        XCTAssertEqual(goal.progress, 0.5, accuracy: 0.001)
    }

    func testProgress_FullProgress() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 10000
        )

        XCTAssertEqual(goal.progress, 1.0, accuracy: 0.001)
    }

    func testProgress_OverTarget() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 15000
        )

        XCTAssertEqual(goal.progress, 1.5, accuracy: 0.001)
    }

    func testProgress_ZeroTarget_ReturnsZero() {
        let goal = TestFixtures.goal(
            targetAmount: 0,
            currentAmount: 5000
        )

        XCTAssertEqual(goal.progress, 0)
    }

    // MARK: - Progress Percentage Tests

    func testProgressPercentage() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 2500
        )

        XCTAssertEqual(goal.progressPercentage, 25)
    }

    func testProgressPercentage_ZeroTarget_ReturnsZero() {
        let goal = TestFixtures.goal(
            targetAmount: 0,
            currentAmount: 5000
        )

        XCTAssertEqual(goal.progressPercentage, 0)
    }

    // MARK: - Clamped Progress Tests

    func testClampedProgress_UnderOne() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 5000
        )

        XCTAssertEqual(goal.clampedProgress, 0.5, accuracy: 0.001)
    }

    func testClampedProgress_OverOne_ClampedToOne() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 15000
        )

        XCTAssertEqual(goal.clampedProgress, 1.0, accuracy: 0.001)
    }

    func testClampedProgress_Negative_ClampedToZero() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: -1000
        )

        XCTAssertEqual(goal.clampedProgress, 0)
    }

    // MARK: - Remaining Amount Tests

    func testRemainingAmount_PartialProgress() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 2500
        )

        XCTAssertEqual(goal.remainingAmount, 7500)
    }

    func testRemainingAmount_Achieved() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 10000
        )

        XCTAssertEqual(goal.remainingAmount, 0)
    }

    func testRemainingAmount_OverTarget_ReturnsZero() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 15000
        )

        XCTAssertEqual(goal.remainingAmount, 0)
    }

    // MARK: - IsAchieved Tests

    func testIsAchieved_UnderTarget_ReturnsFalse() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 9999
        )

        XCTAssertFalse(goal.isAchieved)
    }

    func testIsAchieved_AtTarget_ReturnsTrue() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 10000
        )

        XCTAssertTrue(goal.isAchieved)
    }

    func testIsAchieved_OverTarget_ReturnsTrue() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 15000
        )

        XCTAssertTrue(goal.isAchieved)
    }

    // MARK: - IsOverdue Tests

    func testIsOverdue_NoTargetDate_ReturnsFalse() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 5000,
            targetDate: nil
        )

        XCTAssertFalse(goal.isOverdue)
    }

    func testIsOverdue_FutureTargetDate_ReturnsFalse() {
        // Use current-relative date to ensure it's always in the future
        let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 5000,
            targetDate: futureDate
        )

        XCTAssertFalse(goal.isOverdue)
    }

    func testIsOverdue_PastTargetDateAndNotAchieved_ReturnsTrue() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 5000,
            targetDate: TestFixtures.pastDate
        )

        XCTAssertTrue(goal.isOverdue)
    }

    func testIsOverdue_PastTargetDateButAchieved_ReturnsFalse() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 10000,
            targetDate: TestFixtures.pastDate
        )

        XCTAssertFalse(goal.isOverdue)
    }

    // MARK: - DaysRemaining Tests

    func testDaysRemaining_NoTargetDate_ReturnsNil() {
        let goal = TestFixtures.goal(targetDate: nil)

        XCTAssertNil(goal.daysRemaining)
    }

    func testDaysRemaining_FutureDate() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        let goal = TestFixtures.goal(targetDate: futureDate)

        XCTAssertNotNil(goal.daysRemaining)
        XCTAssertGreaterThanOrEqual(goal.daysRemaining ?? 0, 9)
    }

    func testDaysRemaining_PastDate() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let goal = TestFixtures.goal(targetDate: pastDate)

        XCTAssertNotNil(goal.daysRemaining)
        XCTAssertLessThan(goal.daysRemaining ?? 0, 0)
    }

    // MARK: - EstimatedMonthlyContribution Tests

    func testEstimatedMonthlyContribution_NoTargetDate_ReturnsNil() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 5000,
            targetDate: nil
        )

        XCTAssertNil(goal.estimatedMonthlyContribution)
    }

    func testEstimatedMonthlyContribution_AlreadyAchieved_ReturnsNil() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 10000,
            targetDate: TestFixtures.futureDate
        )

        XCTAssertNil(goal.estimatedMonthlyContribution)
    }

    func testEstimatedMonthlyContribution_PastTargetDate_ReturnsNil() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 5000,
            targetDate: TestFixtures.pastDate
        )

        XCTAssertNil(goal.estimatedMonthlyContribution)
    }

    func testEstimatedMonthlyContribution_FutureDate() {
        let futureDate = Calendar.current.date(byAdding: .month, value: 10, to: Date())!
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 0,
            targetDate: futureDate
        )

        XCTAssertNotNil(goal.estimatedMonthlyContribution)
    }

    // MARK: - Status Tests

    func testStatus_Archived() {
        let goal = TestFixtures.goal(isArchived: true)

        XCTAssertEqual(goal.status, .archived)
    }

    func testStatus_Achieved() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 10000,
            isArchived: false
        )

        XCTAssertEqual(goal.status, .achieved)
    }

    func testStatus_Overdue() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 5000,
            targetDate: TestFixtures.pastDate,
            isArchived: false
        )

        XCTAssertEqual(goal.status, .overdue)
    }

    func testStatus_AlmostThere() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 7500, // 75%
            isArchived: false
        )

        XCTAssertEqual(goal.status, .almostThere)
    }

    func testStatus_Halfway() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 5000, // 50%
            isArchived: false
        )

        XCTAssertEqual(goal.status, .halfway)
    }

    func testStatus_InProgress() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 2500, // 25%
            isArchived: false
        )

        XCTAssertEqual(goal.status, .inProgress)
    }

    func testStatus_NotStarted() {
        let goal = TestFixtures.goal(
            targetAmount: 10000,
            currentAmount: 0,
            isArchived: false
        )

        XCTAssertEqual(goal.status, .notStarted)
    }

    // MARK: - GoalCategory Tests

    func testGoalCategory_DisplayName() {
        XCTAssertEqual(GoalCategory.retirement.displayName, "Retirement")
        XCTAssertEqual(GoalCategory.education.displayName, "Education")
        XCTAssertEqual(GoalCategory.house.displayName, "Home Purchase")
        XCTAssertEqual(GoalCategory.car.displayName, "Vehicle")
        XCTAssertEqual(GoalCategory.vacation.displayName, "Vacation")
        XCTAssertEqual(GoalCategory.emergency.displayName, "Emergency Fund")
        XCTAssertEqual(GoalCategory.wedding.displayName, "Wedding")
        XCTAssertEqual(GoalCategory.investment.displayName, "Investment")
        XCTAssertEqual(GoalCategory.other.displayName, "Other")
    }

    func testGoalCategory_IconName_NotEmpty() {
        for category in GoalCategory.allCases {
            XCTAssertFalse(category.iconName.isEmpty, "Icon name for \(category) should not be empty")
        }
    }

    func testGoalCategory_DefaultColorHex_ValidFormat() {
        for category in GoalCategory.allCases {
            XCTAssertTrue(category.defaultColorHex.hasPrefix("#"), "Color hex for \(category) should start with #")
            XCTAssertEqual(category.defaultColorHex.count, 7, "Color hex for \(category) should be 7 characters")
        }
    }

    func testGoalCategory_AllCases() {
        XCTAssertEqual(GoalCategory.allCases.count, 9)
    }

    // MARK: - GoalStatus Tests

    func testGoalStatus_DisplayName() {
        XCTAssertEqual(GoalStatus.notStarted.displayName, "Not Started")
        XCTAssertEqual(GoalStatus.inProgress.displayName, "In Progress")
        XCTAssertEqual(GoalStatus.halfway.displayName, "Halfway There")
        XCTAssertEqual(GoalStatus.almostThere.displayName, "Almost There")
        XCTAssertEqual(GoalStatus.achieved.displayName, "Achieved")
        XCTAssertEqual(GoalStatus.overdue.displayName, "Overdue")
        XCTAssertEqual(GoalStatus.archived.displayName, "Archived")
    }

    func testGoalStatus_IconName_NotEmpty() {
        let statuses: [GoalStatus] = [.notStarted, .inProgress, .halfway, .almostThere, .achieved, .overdue, .archived]
        for status in statuses {
            XCTAssertFalse(status.iconName.isEmpty, "Icon name for \(status) should not be empty")
        }
    }

    func testGoalStatus_ColorHex_ValidFormat() {
        let statuses: [GoalStatus] = [.notStarted, .inProgress, .halfway, .almostThere, .achieved, .overdue, .archived]
        for status in statuses {
            XCTAssertTrue(status.colorHex.hasPrefix("#"), "Color hex for \(status) should start with #")
            XCTAssertEqual(status.colorHex.count, 7, "Color hex for \(status) should be 7 characters")
        }
    }

    // MARK: - GoalMilestone Tests

    func testGoalMilestone_Initialization() {
        let milestone = GoalMilestone(
            goalId: "goal-123",
            name: "First $1000",
            targetAmount: 1000
        )

        XCTAssertFalse(milestone.id.isEmpty)
        XCTAssertEqual(milestone.goalId, "goal-123")
        XCTAssertEqual(milestone.name, "First $1000")
        XCTAssertEqual(milestone.targetAmount, 1000)
        XCTAssertNil(milestone.reachedAt)
        XCTAssertFalse(milestone.isReached)
    }

    func testGoalMilestone_IsReached_WithDate() {
        let milestone = GoalMilestone(
            goalId: "goal-123",
            name: "First $1000",
            targetAmount: 1000,
            reachedAt: Date()
        )

        XCTAssertTrue(milestone.isReached)
    }

    // MARK: - GoalsSummary Tests

    func testGoalsSummary_Initialization() {
        let goals = TestFixtures.sampleGoals
        let summary = GoalsSummary(goals: goals)

        XCTAssertEqual(summary.totalGoals, 4)
        XCTAssertGreaterThan(summary.achievedGoals, 0)
        XCTAssertGreaterThan(summary.totalTargetAmount, 0)
        XCTAssertGreaterThan(summary.totalCurrentAmount, 0)
    }

    func testGoalsSummary_OverallProgress() {
        let goals = [
            TestFixtures.goal(targetAmount: 10000, currentAmount: 5000),
            TestFixtures.goal(targetAmount: 10000, currentAmount: 5000)
        ]
        let summary = GoalsSummary(goals: goals)

        XCTAssertEqual(summary.overallProgress, 0.5, accuracy: 0.001)
    }

    func testGoalsSummary_AchievementRate() {
        let goals = [
            TestFixtures.goal(targetAmount: 10000, currentAmount: 10000),
            TestFixtures.goal(targetAmount: 10000, currentAmount: 5000)
        ]
        let summary = GoalsSummary(goals: goals)

        XCTAssertEqual(summary.achievementRate, 0.5, accuracy: 0.001)
    }

    func testGoalsSummary_EmptyGoals() {
        let summary = GoalsSummary(goals: [])

        XCTAssertEqual(summary.totalGoals, 0)
        XCTAssertEqual(summary.achievedGoals, 0)
        XCTAssertEqual(summary.inProgressGoals, 0)
        XCTAssertEqual(summary.totalTargetAmount, 0)
        XCTAssertEqual(summary.totalCurrentAmount, 0)
        XCTAssertEqual(summary.overallProgress, 0)
        XCTAssertEqual(summary.achievementRate, 0)
    }

    // MARK: - Codable Tests

    func testGoal_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.goal(
            id: "goal-test",
            name: "Test Goal",
            targetAmount: 50000,
            currentAmount: 12500,
            category: .house
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(Goal.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.targetAmount, original.targetAmount)
        XCTAssertEqual(decoded.currentAmount, original.currentAmount)
        XCTAssertEqual(decoded.category, original.category)
    }

    func testGoalCategory_Codable() throws {
        for category in GoalCategory.allCases {
            let data = try JSONEncoder().encode(category)
            let decoded = try JSONDecoder().decode(GoalCategory.self, from: data)
            XCTAssertEqual(decoded, category)
        }
    }

    func testGoalStatus_Codable() throws {
        let statuses: [GoalStatus] = [.notStarted, .inProgress, .halfway, .almostThere, .achieved, .overdue, .archived]
        for status in statuses {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(GoalStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - Equatable Tests

    func testGoal_Equatable() {
        let goal1 = TestFixtures.goal(id: "goal-1", name: "Test")
        let goal2 = TestFixtures.goal(id: "goal-1", name: "Test")
        let goal3 = TestFixtures.goal(id: "goal-2", name: "Different")

        XCTAssertEqual(goal1, goal2)
        XCTAssertNotEqual(goal1, goal3)
    }

    // MARK: - Hashable Tests

    func testGoal_Hashable() {
        let goal1 = TestFixtures.goal(id: "goal-1")
        let goal2 = TestFixtures.goal(id: "goal-2")

        var set = Set<Goal>()
        set.insert(goal1)
        set.insert(goal2)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Edge Cases

    func testGoal_ZeroTargetAmount() {
        let goal = TestFixtures.goal(
            targetAmount: 0,
            currentAmount: 0
        )

        XCTAssertEqual(goal.progress, 0)
        XCTAssertEqual(goal.progressPercentage, 0)
        XCTAssertEqual(goal.remainingAmount, 0)
    }

    func testGoal_VeryLargeValues() {
        let goal = TestFixtures.goal(
            targetAmount: 999_999_999_999,
            currentAmount: 500_000_000_000
        )

        XCTAssertGreaterThan(goal.progress, 0)
        XCTAssertGreaterThan(goal.remainingAmount, 0)
    }

    func testGoal_VerySmallValues() {
        let goal = TestFixtures.goal(
            targetAmount: Decimal(string: "0.01")!,
            currentAmount: Decimal(string: "0.005")!
        )

        XCTAssertEqual(goal.progress, 0.5, accuracy: 0.001)
    }
}
