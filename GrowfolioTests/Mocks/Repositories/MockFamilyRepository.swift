//
//  MockFamilyRepository.swift
//  GrowfolioTests
//
//  Mock family repository for testing.
//

import Foundation
@testable import Growfolio

/// Mock family repository that returns predefined responses for testing
final class MockFamilyRepository: FamilyRepositoryProtocol, @unchecked Sendable {

    // MARK: - Configurable Responses

    var familyToReturn: Family?
    var pendingInvitesToReturn: [FamilyInvite] = []
    var receivedInvitesToReturn: [ReceivedInvite] = []
    var familyGoalsToReturn: FamilyGoalsOverview?
    var familyInviteToReturn: FamilyInvite?
    var familyMemberToReturn: FamilyMember?
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var getFamilyCalled = false
    var createFamilyCalled = false
    var lastCreateFamilyName: String?
    var lastCreateFamilyDescription: String?
    var updateFamilyCalled = false
    var lastUpdatedFamily: Family?
    var deleteFamilyCalled = false
    var lastDeletedFamilyId: String?
    var inviteMemberCalled = false
    var lastInvitedEmail: String?
    var lastInvitedRole: FamilyMemberRole?
    var lastInviteMessage: String?
    var resendInviteCalled = false
    var lastResendInviteId: String?
    var cancelInviteCalled = false
    var lastCancelledInviteId: String?
    var getPendingInvitesCalled = false
    var getReceivedInvitesCalled = false
    var acceptInviteCalled = false
    var lastAcceptedInviteId: String?
    var declineInviteCalled = false
    var lastDeclinedInviteId: String?
    var updateMemberRoleCalled = false
    var lastUpdatedMemberId: String?
    var lastUpdatedMemberRole: FamilyMemberRole?
    var updateMemberPrivacyCalled = false
    var lastPrivacySettings: MemberPrivacySettings?
    var removeMemberCalled = false
    var lastRemovedMemberId: String?
    var leaveFamilyCalled = false
    var getFamilyGoalsCalled = false
    var invalidateCacheCalled = false

    // MARK: - Reset

    func reset() {
        familyToReturn = nil
        pendingInvitesToReturn = []
        receivedInvitesToReturn = []
        familyGoalsToReturn = nil
        familyInviteToReturn = nil
        familyMemberToReturn = nil
        errorToThrow = nil

        getFamilyCalled = false
        createFamilyCalled = false
        lastCreateFamilyName = nil
        lastCreateFamilyDescription = nil
        updateFamilyCalled = false
        lastUpdatedFamily = nil
        deleteFamilyCalled = false
        lastDeletedFamilyId = nil
        inviteMemberCalled = false
        lastInvitedEmail = nil
        lastInvitedRole = nil
        lastInviteMessage = nil
        resendInviteCalled = false
        lastResendInviteId = nil
        cancelInviteCalled = false
        lastCancelledInviteId = nil
        getPendingInvitesCalled = false
        getReceivedInvitesCalled = false
        acceptInviteCalled = false
        lastAcceptedInviteId = nil
        declineInviteCalled = false
        lastDeclinedInviteId = nil
        updateMemberRoleCalled = false
        lastUpdatedMemberId = nil
        lastUpdatedMemberRole = nil
        updateMemberPrivacyCalled = false
        lastPrivacySettings = nil
        removeMemberCalled = false
        lastRemovedMemberId = nil
        leaveFamilyCalled = false
        getFamilyGoalsCalled = false
        invalidateCacheCalled = false
    }

    // MARK: - FamilyRepositoryProtocol Implementation

    func getFamily() async throws -> Family? {
        getFamilyCalled = true
        if let error = errorToThrow { throw error }
        return familyToReturn
    }

    func createFamily(name: String, description: String?) async throws -> Family {
        createFamilyCalled = true
        lastCreateFamilyName = name
        lastCreateFamilyDescription = description
        if let error = errorToThrow { throw error }
        if let family = familyToReturn { return family }
        return Family(
            id: "family-123",
            name: name,
            familyDescription: description,
            ownerId: "user-123",
            adminIds: ["user-123"],
            members: [
                FamilyMember(
                    userId: "user-123",
                    name: "Test User",
                    email: "test@example.com",
                    role: .admin,
                    status: .active
                )
            ]
        )
    }

    func updateFamily(_ family: Family) async throws -> Family {
        updateFamilyCalled = true
        lastUpdatedFamily = family
        if let error = errorToThrow { throw error }
        return family
    }

    func deleteFamily(id: String) async throws {
        deleteFamilyCalled = true
        lastDeletedFamilyId = id
        if let error = errorToThrow { throw error }
    }

    func inviteMember(email: String, role: FamilyMemberRole, message: String?) async throws -> FamilyInvite {
        inviteMemberCalled = true
        lastInvitedEmail = email
        lastInvitedRole = role
        lastInviteMessage = message
        if let error = errorToThrow { throw error }
        if let invite = familyInviteToReturn { return invite }
        return FamilyInvite(
            id: "invite-123",
            familyId: "family-123",
            familyName: "Test Family",
            inviterId: "user-123",
            inviterName: "Test User",
            inviteeEmail: email,
            role: role,
            status: .pending,
            inviteCode: "ABC12345",
            message: message,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
    }

    func resendInvite(inviteId: String) async throws -> FamilyInvite {
        resendInviteCalled = true
        lastResendInviteId = inviteId
        if let error = errorToThrow { throw error }
        if let invite = familyInviteToReturn { return invite }
        return FamilyInvite(
            id: inviteId,
            familyId: "family-123",
            familyName: "Test Family",
            inviterId: "user-123",
            inviterName: "Test User",
            inviteeEmail: "invitee@example.com",
            role: .member,
            status: .pending,
            inviteCode: "ABC12345",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
    }

    func cancelInvite(inviteId: String) async throws {
        cancelInviteCalled = true
        lastCancelledInviteId = inviteId
        if let error = errorToThrow { throw error }
    }

    func getPendingInvites() async throws -> [FamilyInvite] {
        getPendingInvitesCalled = true
        if let error = errorToThrow { throw error }
        return pendingInvitesToReturn
    }

    func getReceivedInvites() async throws -> [ReceivedInvite] {
        getReceivedInvitesCalled = true
        if let error = errorToThrow { throw error }
        return receivedInvitesToReturn
    }

    func acceptInvite(inviteId: String) async throws -> Family {
        acceptInviteCalled = true
        lastAcceptedInviteId = inviteId
        if let error = errorToThrow { throw error }
        if let family = familyToReturn { return family }
        return Family(
            id: "family-123",
            name: "Test Family",
            ownerId: "owner-123",
            adminIds: ["owner-123"],
            members: []
        )
    }

    func declineInvite(inviteId: String) async throws {
        declineInviteCalled = true
        lastDeclinedInviteId = inviteId
        if let error = errorToThrow { throw error }
    }

    func updateMemberRole(memberId: String, role: FamilyMemberRole) async throws -> FamilyMember {
        updateMemberRoleCalled = true
        lastUpdatedMemberId = memberId
        lastUpdatedMemberRole = role
        if let error = errorToThrow { throw error }
        if let member = familyMemberToReturn { return member }
        return FamilyMember(
            userId: memberId,
            name: "Test Member",
            email: "member@example.com",
            role: role,
            status: .active
        )
    }

    func updateMemberPrivacy(memberId: String, settings: MemberPrivacySettings) async throws -> FamilyMember {
        updateMemberPrivacyCalled = true
        lastUpdatedMemberId = memberId
        lastPrivacySettings = settings
        if let error = errorToThrow { throw error }
        if let member = familyMemberToReturn { return member }
        return FamilyMember(
            userId: memberId,
            name: "Test Member",
            email: "member@example.com",
            role: .member,
            status: .active,
            sharePortfolioValue: settings.sharePortfolioValue,
            shareHoldings: settings.shareHoldings,
            sharePerformance: settings.sharePerformance
        )
    }

    func removeMember(memberId: String) async throws {
        removeMemberCalled = true
        lastRemovedMemberId = memberId
        if let error = errorToThrow { throw error }
    }

    func leaveFamily() async throws {
        leaveFamilyCalled = true
        if let error = errorToThrow { throw error }
    }

    func getFamilyGoals() async throws -> FamilyGoalsOverview {
        getFamilyGoalsCalled = true
        if let error = errorToThrow { throw error }
        if let goals = familyGoalsToReturn { return goals }
        return FamilyGoalsOverview(
            familyId: "family-123",
            totalGoals: 0,
            completedGoals: 0,
            totalTargetAmount: 0,
            totalCurrentAmount: 0,
            memberGoals: []
        )
    }

    func invalidateCache() async {
        invalidateCacheCalled = true
    }
}
