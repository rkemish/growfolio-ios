//
//  FamilyMember.swift
//  Growfolio
//
//  Family member domain model representing a member of a family group.
//

import Foundation

/// Represents a member of a family group
struct FamilyMember: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier (same as userId)
    var id: String { uniqueId }

    /// Member's unique identifier
    let uniqueId: String

    /// User ID
    let userId: String

    /// Display name
    var name: String

    /// Email address
    var email: String

    /// Role in the family
    var role: FamilyMemberRole

    /// Profile picture URL
    var pictureUrl: String?

    /// Date when the member joined
    var joinedAt: Date

    /// Member status
    var status: FamilyMemberStatus

    /// Privacy: share portfolio total value
    var sharePortfolioValue: Bool

    /// Privacy: share individual holdings
    var shareHoldings: Bool

    /// Privacy: share performance metrics
    var sharePerformance: Bool

    // MARK: - Initialization

    init(
        uniqueId: String = UUID().uuidString,
        userId: String,
        name: String,
        email: String,
        role: FamilyMemberRole = .member,
        pictureUrl: String? = nil,
        joinedAt: Date = Date(),
        status: FamilyMemberStatus = .pending,
        sharePortfolioValue: Bool = true,
        shareHoldings: Bool = false,
        sharePerformance: Bool = true
    ) {
        self.uniqueId = uniqueId
        self.userId = userId
        self.name = name
        self.email = email
        self.role = role
        self.pictureUrl = pictureUrl
        self.joinedAt = joinedAt
        self.status = status
        self.sharePortfolioValue = sharePortfolioValue
        self.shareHoldings = shareHoldings
        self.sharePerformance = sharePerformance
    }

    // MARK: - Computed Properties

    /// Member's initials for avatar display
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }

    /// Whether the member is currently active
    var isActive: Bool {
        status == .active
    }

    /// Whether the member has admin privileges
    var isAdmin: Bool {
        role == .admin
    }

    /// Whether the member can invite others
    var canInvite: Bool {
        role == .admin || role == .member
    }

    /// Human-readable status string
    var statusDescription: String {
        status.displayName
    }

    /// Color for the member's status badge
    var statusColorHex: String {
        status.colorHex
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case uniqueId = "id"
        case userId
        case name
        case email
        case role
        case pictureUrl
        case joinedAt
        case status
        case sharePortfolioValue
        case shareHoldings
        case sharePerformance
    }
}

// MARK: - Family Member Role

/// Role of a member within a family group
enum FamilyMemberRole: String, Codable, Sendable, CaseIterable {
    case admin
    case member
    case viewer

    var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .member:
            return "Member"
        case .viewer:
            return "Viewer"
        }
    }

    var description: String {
        switch self {
        case .admin:
            return "Can manage family settings, members, and view all data"
        case .member:
            return "Can view shared data and contribute to family goals"
        case .viewer:
            return "Can only view shared family information"
        }
    }

    var iconName: String {
        switch self {
        case .admin:
            return "shield.fill"
        case .member:
            return "person.fill"
        case .viewer:
            return "eye.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .admin:
            return "#007AFF"
        case .member:
            return "#34C759"
        case .viewer:
            return "#8E8E93"
        }
    }
}

// MARK: - Family Member Status (Extended)

/// Extended status for family members
extension FamilyMemberStatus {
    var description: String {
        switch self {
        case .pending:
            return "Invitation sent, awaiting response"
        case .invited:
            return "Email invitation sent"
        case .active:
            return "Active member"
        case .suspended:
            return "Membership temporarily suspended"
        case .removed:
            return "Member has been removed"
        }
    }
}

// MARK: - Member Profile Card Data

/// Data for displaying a member profile card
struct MemberProfileCardData: Sendable {
    let member: FamilyMember
    let portfolioValue: Decimal?
    let goalProgress: Double?
    let activeDCASchedules: Int?
    let recentActivity: String?

    init(
        member: FamilyMember,
        portfolioValue: Decimal? = nil,
        goalProgress: Double? = nil,
        activeDCASchedules: Int? = nil,
        recentActivity: String? = nil
    ) {
        self.member = member
        self.portfolioValue = portfolioValue
        self.goalProgress = goalProgress
        self.activeDCASchedules = activeDCASchedules
        self.recentActivity = recentActivity
    }
}

// MARK: - Member Privacy Settings

/// Privacy settings for a family member
struct MemberPrivacySettings: Codable, Sendable, Equatable {
    var sharePortfolioValue: Bool
    var shareHoldings: Bool
    var sharePerformance: Bool
    var shareGoals: Bool
    var shareDCASchedules: Bool

    init(
        sharePortfolioValue: Bool = true,
        shareHoldings: Bool = false,
        sharePerformance: Bool = true,
        shareGoals: Bool = true,
        shareDCASchedules: Bool = false
    ) {
        self.sharePortfolioValue = sharePortfolioValue
        self.shareHoldings = shareHoldings
        self.sharePerformance = sharePerformance
        self.shareGoals = shareGoals
        self.shareDCASchedules = shareDCASchedules
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sharePortfolioValue = try container.decodeIfPresent(Bool.self, forKey: .sharePortfolioValue) ?? true
        shareHoldings = try container.decodeIfPresent(Bool.self, forKey: .shareHoldings) ?? false
        sharePerformance = try container.decodeIfPresent(Bool.self, forKey: .sharePerformance) ?? true
        shareGoals = try container.decodeIfPresent(Bool.self, forKey: .shareGoals) ?? true
        // Handle DCA acronym specially - may come as share_dca_schedules or shareDcaSchedules
        if let value = try? container.decodeIfPresent(Bool.self, forKey: .shareDCASchedules) {
            shareDCASchedules = value ?? false
        } else if let value = try? container.decodeIfPresent(Bool.self, forKey: .shareDcaSchedules) {
            shareDCASchedules = value ?? false
        } else {
            shareDCASchedules = false
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sharePortfolioValue, forKey: .sharePortfolioValue)
        try container.encode(shareHoldings, forKey: .shareHoldings)
        try container.encode(sharePerformance, forKey: .sharePerformance)
        try container.encode(shareGoals, forKey: .shareGoals)
        try container.encode(shareDCASchedules, forKey: .shareDCASchedules)
    }

    private enum CodingKeys: String, CodingKey {
        case sharePortfolioValue
        case shareHoldings
        case sharePerformance
        case shareGoals
        case shareDCASchedules
        // Alternative key for DCA when converted from snake_case
        case shareDcaSchedules
    }

    static var `default`: MemberPrivacySettings {
        MemberPrivacySettings()
    }

    static var shareAll: MemberPrivacySettings {
        MemberPrivacySettings(
            sharePortfolioValue: true,
            shareHoldings: true,
            sharePerformance: true,
            shareGoals: true,
            shareDCASchedules: true
        )
    }

    static var minimal: MemberPrivacySettings {
        MemberPrivacySettings(
            sharePortfolioValue: false,
            shareHoldings: false,
            sharePerformance: false,
            shareGoals: false,
            shareDCASchedules: false
        )
    }
}
