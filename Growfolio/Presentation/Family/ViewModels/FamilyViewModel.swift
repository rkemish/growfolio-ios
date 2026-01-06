//
//  FamilyViewModel.swift
//  Growfolio
//
//  View model for family group management.
//

import Foundation
import SwiftUI

@Observable
final class FamilyViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Loading States
    var isLoading = false
    var isRefreshing = false
    var isCreatingFamily = false
    var isInviting = false
    var error: Error?

    // Family Data
    var family: Family?
    var pendingInvites: [FamilyInvite] = []
    var receivedInvites: [ReceivedInvite] = []
    var familyGoals: FamilyGoalsOverview?

    // Selection
    var selectedMember: FamilyMember?

    // Sheet Presentation
    var showCreateFamily = false
    var showInviteMember = false
    var showMemberDetail = false
    var showFamilyGoals = false
    var showSettings = false
    var showLeaveConfirmation = false
    var showRemoveMemberConfirmation = false
    var memberToRemove: FamilyMember?

    // Repository
    private let repository: FamilyRepositoryProtocol

    // MARK: - Computed Properties

    var hasFamily: Bool {
        family != nil
    }

    var isOwner: Bool {
        guard let family = family, let currentUserId = currentUserId else { return false }
        return family.isOwner(userId: currentUserId)
    }

    var isAdmin: Bool {
        guard let family = family, let currentUserId = currentUserId else { return false }
        return family.isAdmin(userId: currentUserId)
    }

    var canInviteMembers: Bool {
        guard let family = family else { return false }
        return isAdmin && family.canAddMembers
    }

    var canManageMembers: Bool {
        isAdmin
    }

    var members: [FamilyMember] {
        family?.members ?? []
    }

    var activeMembers: [FamilyMember] {
        family?.activeMembers ?? []
    }

    var pendingMembersCount: Int {
        family?.pendingInvitesCount ?? 0
    }

    var hasReceivedInvites: Bool {
        !receivedInvites.isEmpty
    }

    var isEmpty: Bool {
        !hasFamily && !isLoading
    }

    private var currentUserId: String? {
        // This would typically come from AuthService or UserDefaults
        UserDefaults.standard.string(forKey: "currentUserId")
    }

    // MARK: - Initialization

    init(repository: FamilyRepositoryProtocol = RepositoryContainer.familyRepository) {
        self.repository = repository
    }

    // MARK: - Data Loading

    @MainActor
    func loadFamily() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            family = try await repository.getFamily()

            // Load additional data if family exists
            if family != nil {
                async let invites = repository.getPendingInvites()
                async let goals = repository.getFamilyGoals()

                pendingInvites = try await invites
                familyGoals = try? await goals
            }

            // Always check for received invites
            receivedInvites = try await repository.getReceivedInvites()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func refreshFamily() async {
        isRefreshing = true
        await repository.invalidateCache()
        await loadFamily()
        isRefreshing = false
    }

    func refresh() {
        Task { @MainActor in
            await refreshFamily()
        }
    }

    // MARK: - Create Family

    @MainActor
    func createFamily(name: String, description: String?) async throws {
        isCreatingFamily = true
        error = nil

        do {
            family = try await repository.createFamily(name: name, description: description)
            showCreateFamily = false
        } catch {
            self.error = error
            throw error
        }

        isCreatingFamily = false
    }

    // MARK: - Update Family

    @MainActor
    func updateFamilySettings(name: String, description: String?, allowSharedGoals: Bool) async throws {
        guard var updatedFamily = family else { return }

        updatedFamily.name = name
        updatedFamily.familyDescription = description
        updatedFamily.allowSharedGoals = allowSharedGoals

        family = try await repository.updateFamily(updatedFamily)
    }

    // MARK: - Invite Member

    @MainActor
    func inviteMember(email: String, role: FamilyMemberRole, message: String?) async throws {
        isInviting = true
        error = nil

        do {
            let invite = try await repository.inviteMember(email: email, role: role, message: message)
            pendingInvites.append(invite)
            showInviteMember = false
        } catch {
            self.error = error
            throw error
        }

        isInviting = false
    }

    @MainActor
    func resendInvite(_ invite: FamilyInvite) async throws {
        let updatedInvite = try await repository.resendInvite(inviteId: invite.id)
        if let index = pendingInvites.firstIndex(where: { $0.id == invite.id }) {
            pendingInvites[index] = updatedInvite
        }
    }

    @MainActor
    func cancelInvite(_ invite: FamilyInvite) async throws {
        try await repository.cancelInvite(inviteId: invite.id)
        pendingInvites.removeAll { $0.id == invite.id }
    }

    // MARK: - Handle Received Invites

    @MainActor
    func acceptInvite(_ invite: ReceivedInvite) async throws {
        family = try await repository.acceptInvite(inviteId: invite.id)
        receivedInvites.removeAll { $0.id == invite.id }
        await refreshFamily()
    }

    @MainActor
    func declineInvite(_ invite: ReceivedInvite) async throws {
        try await repository.declineInvite(inviteId: invite.id)
        receivedInvites.removeAll { $0.id == invite.id }
    }

    // MARK: - Member Management

    @MainActor
    func updateMemberRole(_ member: FamilyMember, to role: FamilyMemberRole) async throws {
        let updatedMember = try await repository.updateMemberRole(memberId: member.userId, role: role)

        if let index = family?.members.firstIndex(where: { $0.userId == member.userId }) {
            family?.members[index] = updatedMember
        }
    }

    @MainActor
    func updateMemberPrivacy(_ member: FamilyMember, settings: MemberPrivacySettings) async throws {
        let updatedMember = try await repository.updateMemberPrivacy(memberId: member.userId, settings: settings)

        if let index = family?.members.firstIndex(where: { $0.userId == member.userId }) {
            family?.members[index] = updatedMember
        }
    }

    @MainActor
    func removeMember(_ member: FamilyMember) async throws {
        try await repository.removeMember(memberId: member.userId)
        family?.members.removeAll { $0.userId == member.userId }
        showRemoveMemberConfirmation = false
        memberToRemove = nil
    }

    func confirmRemoveMember(_ member: FamilyMember) {
        memberToRemove = member
        showRemoveMemberConfirmation = true
    }

    // MARK: - Leave/Delete Family

    @MainActor
    func leaveFamily() async throws {
        try await repository.leaveFamily()
        family = nil
        showLeaveConfirmation = false
    }

    @MainActor
    func deleteFamily() async throws {
        guard let familyId = family?.id else { return }
        try await repository.deleteFamily(id: familyId)
        family = nil
    }

    // MARK: - Family Goals

    @MainActor
    func loadFamilyGoals() async {
        do {
            familyGoals = try await repository.getFamilyGoals()
        } catch {
            self.error = error
        }
    }

    // MARK: - Selection

    func selectMember(_ member: FamilyMember) {
        selectedMember = member
        showMemberDetail = true
    }
}

// MARK: - Preview Helper

extension FamilyViewModel {
    static var preview: FamilyViewModel {
        let viewModel = FamilyViewModel()
        viewModel.family = Family(
            id: "preview-family",
            name: "The Smiths",
            familyDescription: "Our family investment group",
            ownerId: "user-1",
            adminIds: ["user-1"],
            members: [
                FamilyMember(
                    userId: "user-1",
                    name: "John Smith",
                    email: "john@example.com",
                    role: .admin,
                    pictureUrl: nil,
                    joinedAt: Date(),
                    status: .active
                ),
                FamilyMember(
                    userId: "user-2",
                    name: "Jane Smith",
                    email: "jane@example.com",
                    role: .member,
                    pictureUrl: nil,
                    joinedAt: Date(),
                    status: .active
                ),
                FamilyMember(
                    userId: "user-3",
                    name: "Tom Smith",
                    email: "tom@example.com",
                    role: .viewer,
                    pictureUrl: nil,
                    status: .pending
                )
            ]
        )
        return viewModel
    }
}
