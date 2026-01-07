//
//  MockFamilyRepository.swift
//  Growfolio
//
//  Mock implementation of FamilyRepositoryProtocol for demo mode.
//

import Foundation

/// Mock implementation of FamilyRepositoryProtocol
final class MockFamilyRepository: FamilyRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let store = MockDataStore.shared
    private let config = MockConfiguration.shared

    // MARK: - Get Family

    func getFamily() async throws -> Family? {
        try await simulateNetwork()
        await ensureInitialized()
        return await store.family
    }

    // MARK: - Create Family

    func createFamily(name: String, description: String?) async throws -> Family {
        try await simulateNetwork()

        guard let user = await store.currentUser else {
            throw FamilyRepositoryError.familyNotFound
        }

        let family = Family(
            id: MockDataGenerator.mockId(prefix: "family"),
            name: name,
            familyDescription: description,
            ownerId: user.id,
            members: [
                FamilyMember(
                    uniqueId: user.id,
                    userId: user.id,
                    name: user.displayName ?? "Owner",
                    email: user.email,
                    role: .admin,
                    joinedAt: Date(),
                    status: .active
                )
            ]
        )

        await store.setFamily(family)
        return family
    }

    // MARK: - Update Family

    func updateFamily(_ family: Family) async throws -> Family {
        try await simulateNetwork()

        var updatedFamily = family
        updatedFamily.updatedAt = Date()
        await store.setFamily(updatedFamily)
        return updatedFamily
    }

    // MARK: - Delete Family

    func deleteFamily(id: String) async throws {
        try await simulateNetwork()

        guard let family = await store.family, family.id == id else {
            throw FamilyRepositoryError.familyNotFound
        }

        await store.setFamily(nil)
    }

    // MARK: - Invite Member

    func inviteMember(email: String, role: FamilyMemberRole, message: String?) async throws -> FamilyInvite {
        try await simulateNetwork()

        guard let family = await store.family else {
            throw FamilyRepositoryError.familyNotFound
        }

        guard let user = await store.currentUser else {
            throw FamilyRepositoryError.insufficientPermissions
        }

        // Check if already a member
        if family.members.contains(where: { $0.email == email }) {
            throw FamilyRepositoryError.alreadyMember
        }

        // Check member limit
        guard family.canAddMembers else {
            throw FamilyRepositoryError.memberLimitReached
        }

        let invite = FamilyInvite(
            id: MockDataGenerator.mockId(prefix: "invite"),
            familyId: family.id,
            familyName: family.name,
            inviterId: user.id,
            inviterName: user.displayName ?? "Family Admin",
            inviteeEmail: email,
            role: role,
            status: .pending,
            inviteCode: "INV\(Int.random(in: 100000...999999))",
            message: message,
            expiresAt: MockDataGenerator.futureDate(daysFromNow: 7)
        )

        await store.addFamilyInvite(invite)
        return invite
    }

    // MARK: - Resend Invite

    func resendInvite(inviteId: String) async throws -> FamilyInvite {
        try await simulateNetwork()

        guard var invite = await store.familyInvites.first(where: { $0.id == inviteId }) else {
            throw FamilyRepositoryError.familyNotFound
        }

        // Extend expiration
        invite = FamilyInvite(
            id: invite.id,
            familyId: invite.familyId,
            familyName: invite.familyName,
            inviterId: invite.inviterId,
            inviterName: invite.inviterName,
            inviteeEmail: invite.inviteeEmail,
            inviteeUserId: invite.inviteeUserId,
            role: invite.role,
            status: .pending,
            inviteCode: invite.inviteCode,
            message: invite.message,
            createdAt: invite.createdAt,
            expiresAt: MockDataGenerator.futureDate(daysFromNow: 7),
            respondedAt: nil
        )

        await store.updateFamilyInvite(invite)
        return invite
    }

    // MARK: - Cancel Invite

    func cancelInvite(inviteId: String) async throws {
        try await simulateNetwork()

        guard var invite = await store.familyInvites.first(where: { $0.id == inviteId }) else {
            throw FamilyRepositoryError.familyNotFound
        }

        invite.status = .expired
        invite.respondedAt = Date()
        await store.updateFamilyInvite(invite)
    }

    // MARK: - Get Pending Invites

    func getPendingInvites() async throws -> [FamilyInvite] {
        try await simulateNetwork()
        return await store.familyInvites.filter { $0.status == .pending }
    }

    // MARK: - Get Received Invites

    func getReceivedInvites() async throws -> [ReceivedInvite] {
        try await simulateNetwork()

        guard let user = await store.currentUser else {
            return []
        }

        // Filter invites sent to the current user
        let invites = await store.familyInvites.filter {
            $0.inviteeEmail == user.email && $0.status == .pending
        }

        return invites.map { invite in
            ReceivedInvite(
                invite: invite,
                familyMemberCount: 3, // Mock value
                familyOwnerName: invite.inviterName,
                familyDescription: nil
            )
        }
    }

    // MARK: - Accept Invite

    func acceptInvite(inviteId: String) async throws -> Family {
        try await simulateNetwork()

        guard var invite = await store.familyInvites.first(where: { $0.id == inviteId }) else {
            throw FamilyRepositoryError.invalidInviteCode
        }

        guard invite.canBeAccepted else {
            throw FamilyRepositoryError.inviteExpired
        }

        guard let user = await store.currentUser else {
            throw FamilyRepositoryError.notAMember
        }

        // Update invite status
        invite.status = .accepted
        invite.respondedAt = Date()
        await store.updateFamilyInvite(invite)

        // If there's an existing family with this ID, add the member
        if var family = await store.family, family.id == invite.familyId {
            let newMember = FamilyMember(
                uniqueId: user.id,
                userId: user.id,
                name: user.displayName ?? "New Member",
                email: user.email,
                role: invite.role,
                joinedAt: Date(),
                status: .active
            )

            family.members.append(newMember)
            family.updatedAt = Date()
            await store.setFamily(family)
            return family
        }

        // Create a new family representation
        let family = Family(
            id: invite.familyId,
            name: invite.familyName,
            ownerId: invite.inviterId,
            members: [
                FamilyMember(
                    uniqueId: user.id,
                    userId: user.id,
                    name: user.displayName ?? "New Member",
                    email: user.email,
                    role: invite.role,
                    joinedAt: Date(),
                    status: .active
                )
            ]
        )

        await store.setFamily(family)
        return family
    }

    // MARK: - Decline Invite

    func declineInvite(inviteId: String) async throws {
        try await simulateNetwork()

        guard var invite = await store.familyInvites.first(where: { $0.id == inviteId }) else {
            throw FamilyRepositoryError.invalidInviteCode
        }

        invite.status = .declined
        invite.respondedAt = Date()
        await store.updateFamilyInvite(invite)
    }

    // MARK: - Update Member Role

    func updateMemberRole(memberId: String, role: FamilyMemberRole) async throws -> FamilyMember {
        try await simulateNetwork()

        guard var family = await store.family else {
            throw FamilyRepositoryError.familyNotFound
        }

        guard let memberIndex = family.members.firstIndex(where: { $0.userId == memberId }) else {
            throw FamilyRepositoryError.notAMember
        }

        // Can't change owner's role
        if family.members[memberIndex].userId == family.ownerId && role != .admin {
            throw FamilyRepositoryError.cannotRemoveOwner
        }

        family.members[memberIndex].role = role
        family.updatedAt = Date()

        await store.setFamily(family)
        return family.members[memberIndex]
    }

    // MARK: - Update Member Privacy

    func updateMemberPrivacy(memberId: String, settings: MemberPrivacySettings) async throws -> FamilyMember {
        try await simulateNetwork()

        guard var family = await store.family else {
            throw FamilyRepositoryError.familyNotFound
        }

        guard let memberIndex = family.members.firstIndex(where: { $0.userId == memberId }) else {
            throw FamilyRepositoryError.notAMember
        }

        family.members[memberIndex].sharePortfolioValue = settings.sharePortfolioValue
        family.members[memberIndex].shareHoldings = settings.shareHoldings
        family.members[memberIndex].sharePerformance = settings.sharePerformance
        family.updatedAt = Date()

        await store.setFamily(family)
        return family.members[memberIndex]
    }

    // MARK: - Remove Member

    func removeMember(memberId: String) async throws {
        try await simulateNetwork()

        guard var family = await store.family else {
            throw FamilyRepositoryError.familyNotFound
        }

        // Can't remove owner
        if memberId == family.ownerId {
            throw FamilyRepositoryError.cannotRemoveOwner
        }

        family.members.removeAll { $0.userId == memberId }
        family.updatedAt = Date()

        await store.setFamily(family)
    }

    // MARK: - Leave Family

    func leaveFamily() async throws {
        try await simulateNetwork()

        guard let family = await store.family else {
            throw FamilyRepositoryError.familyNotFound
        }

        guard let user = await store.currentUser else {
            throw FamilyRepositoryError.notAMember
        }

        // Owner can't leave, they must delete the family
        if user.id == family.ownerId {
            throw FamilyRepositoryError.cannotRemoveOwner
        }

        var updatedFamily = family
        updatedFamily.members.removeAll { $0.userId == user.id }
        updatedFamily.updatedAt = Date()

        await store.setFamily(updatedFamily)
    }

    // MARK: - Get Family Goals

    func getFamilyGoals() async throws -> FamilyGoalsOverview {
        try await simulateNetwork()
        await ensureInitialized()

        guard let family = await store.family else {
            throw FamilyRepositoryError.familyNotFound
        }

        let goals = await store.goals.filter { !$0.isArchived }

        var memberGoals: [MemberGoalSummary] = []

        for member in family.activeMembers {
            // For mock, assume all goals belong to all members (simplified)
            let memberGoalItems = goals.map { goal in
                let progressDouble = NSDecimalNumber(decimal: goal.progressPercentage).doubleValue
                return GoalSummaryItem(
                    id: goal.id,
                    name: goal.name,
                    targetAmount: goal.targetAmount,
                    currentAmount: goal.currentAmount,
                    progress: progressDouble,
                    isOnTrack: progressDouble >= 50,
                    targetDate: goal.targetDate
                )
            }

            if !memberGoalItems.isEmpty {
                let avgProgress = memberGoalItems.reduce(0.0) { $0 + $1.progress } / Double(memberGoalItems.count)
                memberGoals.append(MemberGoalSummary(
                    memberId: member.userId,
                    memberName: member.name,
                    memberPictureUrl: member.pictureUrl,
                    goals: memberGoalItems,
                    totalProgress: avgProgress / 100
                ))
            }
        }

        let totalTarget = goals.reduce(Decimal.zero) { $0 + $1.targetAmount }
        let totalCurrent = goals.reduce(Decimal.zero) { $0 + $1.currentAmount }
        let completedCount = goals.filter { $0.progressPercentage >= 100 }.count

        return FamilyGoalsOverview(
            familyId: family.id,
            totalGoals: goals.count,
            completedGoals: completedCount,
            totalTargetAmount: totalTarget,
            totalCurrentAmount: totalCurrent,
            memberGoals: memberGoals
        )
    }

    // MARK: - Get Family Accounts

    func getFamilyAccounts() async throws -> [FamilyAccount] {
        try await simulateNetwork()
        await ensureInitialized()

        guard let family = await store.family else {
            throw FamilyRepositoryError.familyNotFound
        }

        // Return mock family accounts for family members
        return family.activeMembers.prefix(3).map { member in
            // Convert FamilyMemberRole to FamilyRole
            let familyRole: FamilyRole = member.role == .admin ? .admin : .viewer

            return FamilyAccount(
                id: MockDataGenerator.mockId(prefix: "facct"),
                primaryUserId: family.ownerId,
                memberUserId: member.userId,
                name: member.name,
                email: member.email,
                relationship: member.userId == family.ownerId ? .parent : .child,
                role: familyRole,
                permissions: FamilyPermissions(
                    canViewPortfolios: true,
                    canManagePortfolios: member.role == .admin,
                    canViewGoals: true,
                    canManageGoals: member.role == .admin,
                    canViewDCASchedules: true,
                    canManageDCASchedules: member.role == .admin,
                    canTrade: member.role == .admin,
                    canInviteMembers: member.role == .admin
                ),
                status: member.status,
                joinedAt: member.joinedAt,
                createdAt: member.joinedAt,
                updatedAt: Date()
            )
        }
    }

    // MARK: - Create Family Account

    func createFamilyAccount(name: String, relationship: String, email: String?) async throws -> FamilyAccount {
        try await simulateNetwork()

        guard await store.family != nil else {
            throw FamilyRepositoryError.familyNotFound
        }

        guard let user = await store.currentUser else {
            throw FamilyRepositoryError.notAMember
        }

        let account = FamilyAccount(
            id: MockDataGenerator.mockId(prefix: "facct"),
            primaryUserId: user.id,
            memberUserId: MockDataGenerator.mockId(prefix: "user"),
            name: name,
            email: email,
            relationship: FamilyRelationship(rawValue: relationship) ?? .other,
            role: .viewer,
            permissions: FamilyPermissions(
                canViewPortfolios: true,
                canManagePortfolios: false,
                canViewGoals: true,
                canManageGoals: false,
                canViewDCASchedules: true,
                canManageDCASchedules: false,
                canTrade: false,
                canInviteMembers: false
            ),
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )

        return account
    }

    // MARK: - Cache Operations

    func invalidateCache() async {
        // No-op for mock
    }

    // MARK: - Private Methods

    private func simulateNetwork() async throws {
        try await config.simulateNetworkDelay()
        try config.maybeThrowSimulatedError()
    }

    private func ensureInitialized() async {
        if await store.family == nil && config.demoPersona == .familyAccount {
            await store.initialize(for: config.demoPersona)
        }
    }
}
