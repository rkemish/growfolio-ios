//
//  FamilyAccount.swift
//  Growfolio
//
//  Family account domain model for family subscription tier.
//

import Foundation

/// Represents a family member's account linked to the primary account
struct FamilyAccount: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Primary account holder's user ID
    let primaryUserId: String

    /// Member's user ID (if they have signed up)
    var memberUserId: String?

    /// Member's name
    var name: String

    /// Member's email address
    var email: String?

    /// Relationship to primary account holder
    var relationship: FamilyRelationship

    /// Date of birth (for minors/custodial accounts)
    var dateOfBirth: Date?

    /// Role within the family account
    var role: FamilyRole

    /// Permissions granted to this member
    var permissions: FamilyPermissions

    /// Portfolios accessible by this member
    var accessiblePortfolioIds: [String]

    /// Profile picture URL
    var profilePictureURL: URL?

    /// Status of the invitation/membership
    var status: FamilyMemberStatus

    /// Date when the invitation was sent
    var invitedAt: Date?

    /// Date when the member joined
    var joinedAt: Date?

    /// Date when the account was created
    let createdAt: Date

    /// Date when the account was last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        primaryUserId: String,
        memberUserId: String? = nil,
        name: String,
        email: String? = nil,
        relationship: FamilyRelationship = .other,
        dateOfBirth: Date? = nil,
        role: FamilyRole = .viewer,
        permissions: FamilyPermissions = .viewOnly,
        accessiblePortfolioIds: [String] = [],
        profilePictureURL: URL? = nil,
        status: FamilyMemberStatus = .pending,
        invitedAt: Date? = nil,
        joinedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.primaryUserId = primaryUserId
        self.memberUserId = memberUserId
        self.name = name
        self.email = email
        self.relationship = relationship
        self.dateOfBirth = dateOfBirth
        self.role = role
        self.permissions = permissions
        self.accessiblePortfolioIds = accessiblePortfolioIds
        self.profilePictureURL = profilePictureURL
        self.status = status
        self.invitedAt = invitedAt
        self.joinedAt = joinedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Member's initials for avatar
    /// Extracts first letter of first name and last name for avatar display
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }

    /// Whether the member is a minor
    /// US legal age is 18 - important for custodial account handling
    var isMinor: Bool {
        guard let dob = dateOfBirth else { return false }
        let years = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
        return years < 18
    }

    /// Age of the member
    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year
    }

    /// Whether the member has joined
    var hasJoined: Bool {
        status == .active && memberUserId != nil
    }

    /// Whether the member can manage portfolios
    var canManagePortfolios: Bool {
        permissions.canManagePortfolios && role != .viewer
    }

    /// Whether the member can execute trades
    var canTrade: Bool {
        permissions.canTrade && role == .admin
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case primaryUserId
        case memberUserId
        case name
        case email
        case relationship
        case dateOfBirth
        case role
        case permissions
        case accessiblePortfolioIds
        case profilePictureURL = "profilePictureUrl"
        case status
        case invitedAt
        case joinedAt
        case createdAt
        case updatedAt
    }
}

// MARK: - Family Relationship

/// Relationship types for family members
enum FamilyRelationship: String, Codable, Sendable, CaseIterable {
    case spouse
    case partner
    case child
    case parent
    case sibling
    case grandparent
    case grandchild
    case guardian
    case other

    var displayName: String {
        switch self {
        case .spouse:
            return "Spouse"
        case .partner:
            return "Partner"
        case .child:
            return "Child"
        case .parent:
            return "Parent"
        case .sibling:
            return "Sibling"
        case .grandparent:
            return "Grandparent"
        case .grandchild:
            return "Grandchild"
        case .guardian:
            return "Guardian"
        case .other:
            return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .spouse, .partner:
            return "heart.fill"
        case .child:
            return "figure.and.child.holdinghands"
        case .parent:
            return "person.2.fill"
        case .sibling:
            return "person.3.fill"
        case .grandparent:
            return "person.crop.circle.badge.clock"
        case .grandchild:
            return "figure.2.and.child.holdinghands"
        case .guardian:
            return "shield.fill"
        case .other:
            return "person.fill"
        }
    }
}

// MARK: - Family Role

/// Roles for family members
enum FamilyRole: String, Codable, Sendable, CaseIterable {
    case admin
    case manager
    case viewer

    var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .manager:
            return "Manager"
        case .viewer:
            return "Viewer"
        }
    }

    var description: String {
        switch self {
        case .admin:
            return "Full access including trading and settings"
        case .manager:
            return "Can view and manage portfolios"
        case .viewer:
            return "View-only access to shared portfolios"
        }
    }
}

// MARK: - Family Permissions

/// Permissions for family members
struct FamilyPermissions: Codable, Sendable, Equatable, Hashable {
    var canViewPortfolios: Bool
    var canManagePortfolios: Bool
    var canViewGoals: Bool
    var canManageGoals: Bool
    var canViewDCASchedules: Bool
    var canManageDCASchedules: Bool
    var canTrade: Bool
    var canInviteMembers: Bool

    init(
        canViewPortfolios: Bool = true,
        canManagePortfolios: Bool = false,
        canViewGoals: Bool = true,
        canManageGoals: Bool = false,
        canViewDCASchedules: Bool = true,
        canManageDCASchedules: Bool = false,
        canTrade: Bool = false,
        canInviteMembers: Bool = false
    ) {
        self.canViewPortfolios = canViewPortfolios
        self.canManagePortfolios = canManagePortfolios
        self.canViewGoals = canViewGoals
        self.canManageGoals = canManageGoals
        self.canViewDCASchedules = canViewDCASchedules
        self.canManageDCASchedules = canManageDCASchedules
        self.canTrade = canTrade
        self.canInviteMembers = canInviteMembers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Try both snake_case (API) and camelCase (auto-converted) keys for compatibility
        // Defaults favor safety: view permissions default to true, modify permissions default to false
        canViewPortfolios = try container.decodeIfPresent(Bool.self, forKey: .canViewPortfolios) ?? true
        canManagePortfolios = try container.decodeIfPresent(Bool.self, forKey: .canManagePortfolios) ?? false
        canViewGoals = try container.decodeIfPresent(Bool.self, forKey: .canViewGoals) ?? true
        canManageGoals = try container.decodeIfPresent(Bool.self, forKey: .canManageGoals) ?? false
        // Handle DCA acronym specially - Swift's auto snake_case converter may produce different results
        // for acronyms (DCA vs Dca), so we try both variations for robustness
        if let value = try? container.decodeIfPresent(Bool.self, forKey: .canViewDCASchedules) {
            canViewDCASchedules = value ?? true
        } else if let value = try? container.decodeIfPresent(Bool.self, forKey: .canViewDcaSchedules) {
            canViewDCASchedules = value ?? true
        } else {
            canViewDCASchedules = true
        }
        if let value = try? container.decodeIfPresent(Bool.self, forKey: .canManageDCASchedules) {
            canManageDCASchedules = value ?? false
        } else if let value = try? container.decodeIfPresent(Bool.self, forKey: .canManageDcaSchedules) {
            canManageDCASchedules = value ?? false
        } else {
            canManageDCASchedules = false
        }
        canTrade = try container.decodeIfPresent(Bool.self, forKey: .canTrade) ?? false
        canInviteMembers = try container.decodeIfPresent(Bool.self, forKey: .canInviteMembers) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(canViewPortfolios, forKey: .canViewPortfolios)
        try container.encode(canManagePortfolios, forKey: .canManagePortfolios)
        try container.encode(canViewGoals, forKey: .canViewGoals)
        try container.encode(canManageGoals, forKey: .canManageGoals)
        try container.encode(canViewDCASchedules, forKey: .canViewDCASchedules)
        try container.encode(canManageDCASchedules, forKey: .canManageDCASchedules)
        try container.encode(canTrade, forKey: .canTrade)
        try container.encode(canInviteMembers, forKey: .canInviteMembers)
    }

    private enum CodingKeys: String, CodingKey {
        case canViewPortfolios
        case canManagePortfolios
        case canViewGoals
        case canManageGoals
        case canViewDCASchedules
        case canManageDCASchedules
        // Alternative keys for DCA when converted from snake_case
        case canViewDcaSchedules
        case canManageDcaSchedules
        case canTrade
        case canInviteMembers
    }

    // MARK: - Presets

    static var viewOnly: FamilyPermissions {
        FamilyPermissions()
    }

    static var manager: FamilyPermissions {
        FamilyPermissions(
            canViewPortfolios: true,
            canManagePortfolios: true,
            canViewGoals: true,
            canManageGoals: true,
            canViewDCASchedules: true,
            canManageDCASchedules: true,
            canTrade: false,
            canInviteMembers: false
        )
    }

    static var admin: FamilyPermissions {
        FamilyPermissions(
            canViewPortfolios: true,
            canManagePortfolios: true,
            canViewGoals: true,
            canManageGoals: true,
            canViewDCASchedules: true,
            canManageDCASchedules: true,
            canTrade: true,
            canInviteMembers: true
        )
    }
}

// MARK: - Family Member Status

/// Status of a family member
enum FamilyMemberStatus: String, Codable, Sendable {
    case pending
    case invited
    case active
    case suspended
    case removed

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .invited:
            return "Invited"
        case .active:
            return "Active"
        case .suspended:
            return "Suspended"
        case .removed:
            return "Removed"
        }
    }

    var iconName: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .invited:
            return "envelope.fill"
        case .active:
            return "checkmark.circle.fill"
        case .suspended:
            return "pause.circle.fill"
        case .removed:
            return "xmark.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .pending:
            return "#FF9500"
        case .invited:
            return "#007AFF"
        case .active:
            return "#34C759"
        case .suspended:
            return "#FF9500"
        case .removed:
            return "#FF3B30"
        }
    }
}

// MARK: - Family Summary

/// Summary of family account
struct FamilySummary: Sendable {
    let totalMembers: Int
    let activeMembers: Int
    let pendingInvitations: Int
    let totalSharedPortfolios: Int
    let combinedPortfolioValue: Decimal

    init(
        members: [FamilyAccount],
        sharedPortfolios: [Portfolio]
    ) {
        self.totalMembers = members.count
        self.activeMembers = members.filter { $0.status == .active }.count
        self.pendingInvitations = members.filter { $0.status == .invited || $0.status == .pending }.count
        self.totalSharedPortfolios = sharedPortfolios.count
        self.combinedPortfolioValue = sharedPortfolios.reduce(0) { $0 + $1.totalValue }
    }
}

// MARK: - Family Activity

/// Activity log entry for family accounts
struct FamilyActivity: Identifiable, Codable, Sendable {
    let id: String
    let familyAccountId: String
    let memberName: String
    let action: FamilyActivityAction
    let details: String?
    let timestamp: Date

    init(
        id: String = UUID().uuidString,
        familyAccountId: String,
        memberName: String,
        action: FamilyActivityAction,
        details: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.familyAccountId = familyAccountId
        self.memberName = memberName
        self.action = action
        self.details = details
        self.timestamp = timestamp
    }
}

/// Types of family account activities
enum FamilyActivityAction: String, Codable, Sendable {
    case memberJoined
    case memberRemoved
    case permissionsChanged
    case portfolioShared
    case portfolioUnshared
    case goalCreated
    case dcaScheduleCreated
    case transactionRecorded
}
