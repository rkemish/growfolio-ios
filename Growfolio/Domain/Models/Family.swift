//
//  Family.swift
//  Growfolio
//
//  Family group domain model for family sharing features.
//

import Foundation

/// Represents a family group
struct Family: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Family group name
    var name: String

    /// Optional description
    var familyDescription: String?

    /// Owner user ID
    let ownerId: String

    /// Admin user IDs
    var adminIds: [String]

    /// List of family members
    var members: [FamilyMember]

    /// Maximum allowed members
    var maxMembers: Int

    /// Whether shared goals are allowed
    var allowSharedGoals: Bool

    /// Creation timestamp
    let createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        name: String,
        familyDescription: String? = nil,
        ownerId: String,
        adminIds: [String] = [],
        members: [FamilyMember] = [],
        maxMembers: Int = 10,
        allowSharedGoals: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.familyDescription = familyDescription
        self.ownerId = ownerId
        // Ensure the owner is always included in the admin list
        self.adminIds = adminIds.contains(ownerId) ? adminIds : [ownerId] + adminIds
        self.members = members
        self.maxMembers = maxMembers
        self.allowSharedGoals = allowSharedGoals
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Total number of members
    var memberCount: Int {
        members.count
    }

    /// Active members only
    var activeMembers: [FamilyMember] {
        members.filter { $0.status == .active }
    }

    /// Pending invites count
    var pendingInvitesCount: Int {
        members.filter { $0.status == .pending || $0.status == .invited }.count
    }

    /// Whether more members can be added
    var canAddMembers: Bool {
        memberCount < maxMembers
    }

    /// Number of remaining slots
    var remainingSlots: Int {
        max(0, maxMembers - memberCount)
    }

    /// Check if a user is an admin
    func isAdmin(userId: String) -> Bool {
        adminIds.contains(userId)
    }

    /// Check if a user is the owner
    func isOwner(userId: String) -> Bool {
        ownerId == userId
    }

    /// Get member by user ID
    func member(userId: String) -> FamilyMember? {
        members.first { $0.userId == userId }
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case familyDescription = "description"
        case ownerId
        case adminIds
        case members
        case maxMembers
        case allowSharedGoals
        case createdAt
        case updatedAt
    }
}

// MARK: - Family Goals Overview

/// Overview of family goals and progress
struct FamilyGoalsOverview: Codable, Sendable, Equatable {
    let familyId: String
    let totalGoals: Int
    let completedGoals: Int
    let totalTargetAmount: Decimal
    let totalCurrentAmount: Decimal
    let memberGoals: [MemberGoalSummary]

    /// Overall family progress percentage
    var overallProgress: Double {
        guard totalTargetAmount > 0 else { return 0 }
        // Convert Decimal to Double via NSNumber for UI display
        return Double(truncating: (totalCurrentAmount / totalTargetAmount) as NSNumber)
    }

    /// Goals that are on track
    var goalsOnTrack: Int {
        memberGoals.flatMap { $0.goals }.filter { $0.isOnTrack }.count
    }
}

/// Summary of a member's goals
struct MemberGoalSummary: Codable, Sendable, Equatable, Identifiable {
    var id: String { memberId }
    let memberId: String
    let memberName: String
    let memberPictureUrl: String?
    let goals: [GoalSummaryItem]
    let totalProgress: Double
}

/// Summary item for a single goal
struct GoalSummaryItem: Codable, Sendable, Equatable, Identifiable {
    let id: String
    let name: String
    let targetAmount: Decimal
    let currentAmount: Decimal
    let progress: Double
    let isOnTrack: Bool
    let targetDate: Date?
}

// MARK: - Family Statistics

/// Aggregated family statistics
struct FamilyStatistics: Sendable {
    let totalPortfolioValue: Decimal
    let totalGoals: Int
    let completedGoals: Int
    let activeDCASchedules: Int
    let memberContributions: [MemberContribution]

    struct MemberContribution: Sendable, Identifiable {
        var id: String { memberId }
        let memberId: String
        let memberName: String
        let portfolioValue: Decimal
        let percentageOfTotal: Double
    }
}
