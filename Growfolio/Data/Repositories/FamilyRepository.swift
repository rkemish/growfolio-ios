//
//  FamilyRepository.swift
//  Growfolio
//
//  Repository for family group operations.
//

import Foundation

// MARK: - Family Repository Protocol

/// Protocol defining family data operations
protocol FamilyRepositoryProtocol: Sendable {
    /// Get the current user's family (if any)
    func getFamily() async throws -> Family?

    /// Create a new family group
    func createFamily(name: String, description: String?) async throws -> Family

    /// Update family settings
    func updateFamily(_ family: Family) async throws -> Family

    /// Delete the family group
    func deleteFamily(id: String) async throws

    /// Invite a member to the family
    func inviteMember(email: String, role: FamilyMemberRole, message: String?) async throws -> FamilyInvite

    /// Resend an invitation
    func resendInvite(inviteId: String) async throws -> FamilyInvite

    /// Cancel a pending invitation
    func cancelInvite(inviteId: String) async throws

    /// Get pending invites for the family
    func getPendingInvites() async throws -> [FamilyInvite]

    /// Get invites received by the current user
    func getReceivedInvites() async throws -> [ReceivedInvite]

    /// Accept an invitation
    func acceptInvite(inviteId: String) async throws -> Family

    /// Decline an invitation
    func declineInvite(inviteId: String) async throws

    /// Update a member's role
    func updateMemberRole(memberId: String, role: FamilyMemberRole) async throws -> FamilyMember

    /// Update member privacy settings
    func updateMemberPrivacy(memberId: String, settings: MemberPrivacySettings) async throws -> FamilyMember

    /// Remove a member from the family
    func removeMember(memberId: String) async throws

    /// Leave the family
    func leaveFamily() async throws

    /// Get family goals overview
    func getFamilyGoals() async throws -> FamilyGoalsOverview

    /// Get family member accounts
    func getFamilyAccounts() async throws -> [FamilyAccount]

    /// Create a new family member account
    func createFamilyAccount(name: String, relationship: String, email: String?) async throws -> FamilyAccount

    /// Invalidate cached data
    func invalidateCache() async
}

// MARK: - Family Repository Implementation

/// Implementation of the family repository using the API client
final class FamilyRepository: FamilyRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let apiClient: APIClientProtocol
    private var cachedFamily: Family?
    private var lastFetchTime: Date?
    private let cacheDuration: TimeInterval = 120 // 2 minutes cache

    // MARK: - Initialization

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: - Get Family

    func getFamily() async throws -> Family? {
        // Check cache first
        if let cached = cachedFamily,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheDuration {
            return cached
        }

        do {
            let family: Family = try await apiClient.request(Endpoints.GetFamily())
            cachedFamily = family
            lastFetchTime = Date()
            return family
        } catch let error as NetworkError {
            if case .notFound = error {
                cachedFamily = nil
                lastFetchTime = Date()
                return nil
            }
            throw error
        }
    }

    // MARK: - Create Family

    func createFamily(name: String, description: String?) async throws -> Family {
        let request = FamilyCreateRequest(name: name, description: description)
        let family: Family = try await apiClient.request(
            try Endpoints.CreateFamily(request: request)
        )
        cachedFamily = family
        lastFetchTime = Date()
        return family
    }

    // MARK: - Update Family

    func updateFamily(_ family: Family) async throws -> Family {
        let request = FamilyUpdateRequest(
            name: family.name,
            description: family.familyDescription,
            allowSharedGoals: family.allowSharedGoals
        )
        let updated: Family = try await apiClient.request(
            try Endpoints.UpdateFamily(id: family.id, request: request)
        )
        cachedFamily = updated
        return updated
    }

    // MARK: - Delete Family

    func deleteFamily(id: String) async throws {
        try await apiClient.request(Endpoints.DeleteFamily(id: id))
        cachedFamily = nil
        lastFetchTime = nil
    }

    // MARK: - Invite Member

    func inviteMember(email: String, role: FamilyMemberRole, message: String?) async throws -> FamilyInvite {
        let request = FamilyInviteRequest(email: email, role: role.rawValue, message: message)
        let invite: FamilyInvite = try await apiClient.request(
            try Endpoints.InviteFamilyMember(request: request)
        )

        // Invalidate cache to refresh member list
        await invalidateCache()

        return invite
    }

    // MARK: - Resend Invite

    func resendInvite(inviteId: String) async throws -> FamilyInvite {
        return try await apiClient.request(Endpoints.ResendFamilyInvite(inviteId: inviteId))
    }

    // MARK: - Cancel Invite

    func cancelInvite(inviteId: String) async throws {
        try await apiClient.request(Endpoints.CancelFamilyInvite(inviteId: inviteId))
        await invalidateCache()
    }

    // MARK: - Get Pending Invites

    func getPendingInvites() async throws -> [FamilyInvite] {
        return try await apiClient.request(Endpoints.GetFamilyInvites())
    }

    // MARK: - Get Received Invites

    func getReceivedInvites() async throws -> [ReceivedInvite] {
        return try await apiClient.request(Endpoints.GetReceivedInvites())
    }

    // MARK: - Accept Invite

    func acceptInvite(inviteId: String) async throws -> Family {
        let family: Family = try await apiClient.request(
            Endpoints.AcceptFamilyInvite(inviteId: inviteId)
        )
        cachedFamily = family
        lastFetchTime = Date()
        return family
    }

    // MARK: - Decline Invite

    func declineInvite(inviteId: String) async throws {
        try await apiClient.request(Endpoints.DeclineFamilyInvite(inviteId: inviteId))
    }

    // MARK: - Update Member Role

    func updateMemberRole(memberId: String, role: FamilyMemberRole) async throws -> FamilyMember {
        let request = FamilyMemberUpdateRequest(role: role.rawValue)
        let member: FamilyMember = try await apiClient.request(
            try Endpoints.UpdateFamilyMember(memberId: memberId, request: request)
        )
        await invalidateCache()
        return member
    }

    // MARK: - Update Member Privacy

    func updateMemberPrivacy(memberId: String, settings: MemberPrivacySettings) async throws -> FamilyMember {
        let request = FamilyMemberUpdateRequest(
            sharePortfolioValue: settings.sharePortfolioValue,
            shareHoldings: settings.shareHoldings,
            sharePerformance: settings.sharePerformance
        )
        let member: FamilyMember = try await apiClient.request(
            try Endpoints.UpdateFamilyMember(memberId: memberId, request: request)
        )
        await invalidateCache()
        return member
    }

    // MARK: - Remove Member

    func removeMember(memberId: String) async throws {
        try await apiClient.request(Endpoints.RemoveFamilyMember(memberId: memberId))
        await invalidateCache()
    }

    // MARK: - Leave Family

    func leaveFamily() async throws {
        try await apiClient.request(Endpoints.LeaveFamily())
        cachedFamily = nil
        lastFetchTime = nil
    }

    // MARK: - Get Family Goals

    func getFamilyGoals() async throws -> FamilyGoalsOverview {
        return try await apiClient.request(Endpoints.GetFamilyGoals())
    }

    // MARK: - Get Family Accounts

    func getFamilyAccounts() async throws -> [FamilyAccount] {
        return try await apiClient.request(Endpoints.GetFamilyAccounts())
    }

    // MARK: - Create Family Account

    func createFamilyAccount(name: String, relationship: String, email: String?) async throws -> FamilyAccount {
        let request = FamilyAccountCreateRequest(
            name: name,
            relationship: relationship,
            email: email
        )
        let account: FamilyAccount = try await apiClient.request(
            try Endpoints.CreateFamilyAccount(account: request)
        )
        await invalidateCache()
        return account
    }

    // MARK: - Cache

    func invalidateCache() async {
        cachedFamily = nil
        lastFetchTime = nil
    }
}

// MARK: - Family Repository Error

/// Errors specific to family operations
enum FamilyRepositoryError: LocalizedError {
    case familyNotFound
    case notAMember
    case insufficientPermissions
    case memberLimitReached
    case inviteExpired
    case alreadyMember
    case cannotRemoveOwner
    case invalidInviteCode

    var errorDescription: String? {
        switch self {
        case .familyNotFound:
            return "Family group not found"
        case .notAMember:
            return "You are not a member of this family"
        case .insufficientPermissions:
            return "You don't have permission to perform this action"
        case .memberLimitReached:
            return "This family has reached its member limit"
        case .inviteExpired:
            return "This invitation has expired"
        case .alreadyMember:
            return "This person is already a member of the family"
        case .cannotRemoveOwner:
            return "The family owner cannot be removed"
        case .invalidInviteCode:
            return "Invalid invitation code"
        }
    }
}

// MARK: - Request DTOs

struct FamilyCreateRequest: Codable, Sendable {
    let name: String
    let description: String?
}

struct FamilyUpdateRequest: Codable, Sendable {
    var name: String?
    var description: String?
    var allowSharedGoals: Bool?
}

struct FamilyInviteRequest: Codable, Sendable {
    let email: String
    let role: String
    let message: String?
}

struct FamilyMemberUpdateRequest: Codable, Sendable {
    var role: String?
    var sharePortfolioValue: Bool?
    var shareHoldings: Bool?
    var sharePerformance: Bool?
}
