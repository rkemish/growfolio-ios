//
//  FamilyViewModelTests.swift
//  GrowfolioTests
//
//  Tests for FamilyViewModel - family group management.
//

import XCTest
@testable import Growfolio

@MainActor
final class FamilyViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockRepository: MockFamilyRepository!
    var sut: FamilyViewModel!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockFamilyRepository()
        sut = FamilyViewModel(repository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
        // Clear any test user ID
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isRefreshing)
        XCTAssertFalse(sut.isCreatingFamily)
        XCTAssertFalse(sut.isInviting)
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.family)
        XCTAssertTrue(sut.pendingInvites.isEmpty)
        XCTAssertTrue(sut.receivedInvites.isEmpty)
        XCTAssertNil(sut.familyGoals)
        XCTAssertNil(sut.selectedMember)
    }

    func test_initialState_sheetPresentationIsFalse() {
        XCTAssertFalse(sut.showCreateFamily)
        XCTAssertFalse(sut.showInviteMember)
        XCTAssertFalse(sut.showMemberDetail)
        XCTAssertFalse(sut.showFamilyGoals)
        XCTAssertFalse(sut.showSettings)
        XCTAssertFalse(sut.showLeaveConfirmation)
        XCTAssertFalse(sut.showRemoveMemberConfirmation)
        XCTAssertNil(sut.memberToRemove)
    }

    // MARK: - Computed Properties Tests

    func test_hasFamily_returnsFalseWhenNoFamily() {
        XCTAssertFalse(sut.hasFamily)
    }

    func test_hasFamily_returnsTrueWhenFamilyExists() {
        sut.family = TestFixtures.family()
        XCTAssertTrue(sut.hasFamily)
    }

    func test_isOwner_returnsFalseWhenNoFamily() {
        XCTAssertFalse(sut.isOwner)
    }

    func test_isOwner_returnsTrueWhenUserIsOwner() {
        UserDefaults.standard.set("user-123", forKey: "currentUserId")
        UserDefaults.standard.synchronize()
        sut.family = TestFixtures.family(ownerId: "user-123")

        XCTAssertTrue(sut.isOwner)
    }

    func test_isOwner_returnsFalseWhenUserIsNotOwner() {
        UserDefaults.standard.set("user-456", forKey: "currentUserId")
        UserDefaults.standard.synchronize()
        sut.family = TestFixtures.family(ownerId: "user-123")

        XCTAssertFalse(sut.isOwner)
    }

    func test_isAdmin_returnsTrueWhenUserIsAdmin() {
        UserDefaults.standard.set("user-123", forKey: "currentUserId")
        UserDefaults.standard.synchronize()
        sut.family = TestFixtures.family(adminIds: ["user-123", "user-456"])

        XCTAssertTrue(sut.isAdmin)
    }

    func test_isAdmin_returnsFalseWhenUserIsNotAdmin() {
        UserDefaults.standard.set("user-789", forKey: "currentUserId")
        UserDefaults.standard.synchronize()
        sut.family = TestFixtures.family(adminIds: ["user-123"])

        XCTAssertFalse(sut.isAdmin)
    }

    func test_canInviteMembers_returnsFalseWhenNotAdmin() {
        UserDefaults.standard.set("user-789", forKey: "currentUserId")
        UserDefaults.standard.synchronize()
        sut.family = TestFixtures.family(adminIds: ["user-123"])

        XCTAssertFalse(sut.canInviteMembers)
    }

    func test_canInviteMembers_returnsFalseWhenNoFamily() {
        UserDefaults.standard.set("user-123", forKey: "currentUserId")
        UserDefaults.standard.synchronize()
        sut.family = nil

        XCTAssertFalse(sut.canInviteMembers)
    }

    func test_canManageMembers_returnsTrueWhenAdmin() {
        UserDefaults.standard.set("user-123", forKey: "currentUserId")
        UserDefaults.standard.synchronize()
        sut.family = TestFixtures.family(adminIds: ["user-123"])

        XCTAssertTrue(sut.canManageMembers)
    }

    func test_members_returnsEmptyWhenNoFamily() {
        XCTAssertTrue(sut.members.isEmpty)
    }

    func test_members_returnsFamilyMembers() {
        let members = TestFixtures.sampleFamilyMembers
        sut.family = TestFixtures.family(members: members)

        XCTAssertEqual(sut.members.count, members.count)
    }

    func test_activeMembers_returnsOnlyActiveMembers() {
        let members = [
            TestFixtures.familyMember(userId: "user-1", status: .active),
            TestFixtures.familyMember(userId: "user-2", status: .pending),
            TestFixtures.familyMember(userId: "user-3", status: .active)
        ]
        sut.family = TestFixtures.family(members: members)

        XCTAssertEqual(sut.activeMembers.count, 2)
        XCTAssertTrue(sut.activeMembers.allSatisfy { $0.status == .active })
    }

    func test_hasReceivedInvites_returnsFalseWhenEmpty() {
        sut.receivedInvites = []
        XCTAssertFalse(sut.hasReceivedInvites)
    }

    func test_hasReceivedInvites_returnsTrueWhenNotEmpty() {
        sut.receivedInvites = [TestFixtures.receivedInvite(
            invite: TestFixtures.familyInvite(id: "invite-1")
        )]
        XCTAssertTrue(sut.hasReceivedInvites)
    }

    func test_isEmpty_returnsTrueWhenNoFamilyAndNotLoading() {
        sut.family = nil
        sut.isLoading = false

        XCTAssertTrue(sut.isEmpty)
    }

    func test_isEmpty_returnsFalseWhenLoading() {
        sut.family = nil
        sut.isLoading = true

        XCTAssertFalse(sut.isEmpty)
    }

    func test_isEmpty_returnsFalseWhenHasFamily() {
        sut.family = TestFixtures.family()
        sut.isLoading = false

        XCTAssertFalse(sut.isEmpty)
    }

    // MARK: - Loading State Tests

    func test_loadFamily_setsIsLoadingDuringOperation() async {
        await sut.loadFamily()

        XCTAssertFalse(sut.isLoading)
    }

    func test_loadFamily_preventsMultipleSimultaneousLoads() async {
        sut.isLoading = true

        await sut.loadFamily()

        XCTAssertFalse(mockRepository.getFamilyCalled)
    }

    func test_refreshFamily_setsIsRefreshingDuringOperation() async {
        await sut.refreshFamily()

        XCTAssertFalse(sut.isRefreshing)
        XCTAssertTrue(mockRepository.invalidateCacheCalled)
    }

    // MARK: - Data Loading Tests

    func test_loadFamily_fetchesFromRepository() async {
        let family = TestFixtures.family()
        mockRepository.familyToReturn = family

        await sut.loadFamily()

        XCTAssertTrue(mockRepository.getFamilyCalled)
        XCTAssertEqual(sut.family?.id, family.id)
    }

    func test_loadFamily_loadsPendingInvitesWhenFamilyExists() async {
        let family = TestFixtures.family()
        let invites = [TestFixtures.familyInvite()]
        mockRepository.familyToReturn = family
        mockRepository.pendingInvitesToReturn = invites

        await sut.loadFamily()

        XCTAssertTrue(mockRepository.getPendingInvitesCalled)
        XCTAssertEqual(sut.pendingInvites.count, 1)
    }

    func test_loadFamily_loadsFamilyGoalsWhenFamilyExists() async {
        let family = TestFixtures.family()
        mockRepository.familyToReturn = family

        await sut.loadFamily()

        XCTAssertTrue(mockRepository.getFamilyGoalsCalled)
    }

    func test_loadFamily_alwaysLoadsReceivedInvites() async {
        mockRepository.familyToReturn = nil

        await sut.loadFamily()

        XCTAssertTrue(mockRepository.getReceivedInvitesCalled)
    }

    func test_loadFamily_clearsErrorOnSuccess() async {
        sut.error = NetworkError.noConnection
        mockRepository.familyToReturn = TestFixtures.family()

        await sut.loadFamily()

        XCTAssertNil(sut.error)
    }

    // MARK: - Error Handling Tests

    func test_loadFamily_setsErrorOnFailure() async {
        mockRepository.errorToThrow = NetworkError.serverError(statusCode: 500, message: nil)

        await sut.loadFamily()

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Create Family Tests

    func test_createFamily_callsRepositoryWithCorrectParams() async {
        try? await sut.createFamily(name: "Test Family", description: "Description")

        XCTAssertTrue(mockRepository.createFamilyCalled)
        XCTAssertEqual(mockRepository.lastCreateFamilyName, "Test Family")
        XCTAssertEqual(mockRepository.lastCreateFamilyDescription, "Description")
    }

    func test_createFamily_setsIsCreatingFamilyDuringOperation() async {
        try? await sut.createFamily(name: "Test", description: nil)

        XCTAssertFalse(sut.isCreatingFamily)
    }

    func test_createFamily_setsFamilyOnSuccess() async {
        let family = TestFixtures.family(name: "New Family")
        mockRepository.familyToReturn = family

        try? await sut.createFamily(name: "New Family", description: nil)

        XCTAssertEqual(sut.family?.name, "New Family")
    }

    func test_createFamily_dismissesSheetOnSuccess() async {
        sut.showCreateFamily = true
        mockRepository.familyToReturn = TestFixtures.family()

        try? await sut.createFamily(name: "Test", description: nil)

        XCTAssertFalse(sut.showCreateFamily)
    }

    func test_createFamily_throwsOnRepositoryError() async {
        mockRepository.errorToThrow = FamilyRepositoryError.familyNotFound

        do {
            try await sut.createFamily(name: "Test", description: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(sut.error)
        }
    }

    // MARK: - Update Family Tests

    func test_updateFamilySettings_callsRepository() async {
        sut.family = TestFixtures.family()

        try? await sut.updateFamilySettings(
            name: "Updated Family",
            description: "New Description",
            allowSharedGoals: true
        )

        XCTAssertTrue(mockRepository.updateFamilyCalled)
    }

    func test_updateFamilySettings_doesNothingWhenNoFamily() async {
        sut.family = nil

        try? await sut.updateFamilySettings(
            name: "Test",
            description: nil,
            allowSharedGoals: false
        )

        XCTAssertFalse(mockRepository.updateFamilyCalled)
    }

    // MARK: - Invite Member Tests

    func test_inviteMember_callsRepositoryWithCorrectParams() async {
        try? await sut.inviteMember(
            email: "test@example.com",
            role: .member,
            message: "Welcome!"
        )

        XCTAssertTrue(mockRepository.inviteMemberCalled)
        XCTAssertEqual(mockRepository.lastInvitedEmail, "test@example.com")
        XCTAssertEqual(mockRepository.lastInvitedRole, .member)
        XCTAssertEqual(mockRepository.lastInviteMessage, "Welcome!")
    }

    func test_inviteMember_setsIsInvitingDuringOperation() async {
        try? await sut.inviteMember(email: "test@example.com", role: .member, message: nil)

        XCTAssertFalse(sut.isInviting)
    }

    func test_inviteMember_addsInviteToPendingList() async {
        let invite = TestFixtures.familyInvite()
        mockRepository.familyInviteToReturn = invite
        sut.pendingInvites = []

        try? await sut.inviteMember(email: "test@example.com", role: .member, message: nil)

        XCTAssertEqual(sut.pendingInvites.count, 1)
    }

    func test_inviteMember_dismissesSheetOnSuccess() async {
        sut.showInviteMember = true

        try? await sut.inviteMember(email: "test@example.com", role: .member, message: nil)

        XCTAssertFalse(sut.showInviteMember)
    }

    func test_resendInvite_callsRepository() async {
        let invite = TestFixtures.familyInvite(id: "invite-123")
        sut.pendingInvites = [invite]

        try? await sut.resendInvite(invite)

        XCTAssertTrue(mockRepository.resendInviteCalled)
        XCTAssertEqual(mockRepository.lastResendInviteId, "invite-123")
    }

    func test_cancelInvite_removesFromPendingList() async {
        let invite = TestFixtures.familyInvite(id: "invite-to-cancel")
        sut.pendingInvites = [invite, TestFixtures.familyInvite(id: "other-invite")]

        try? await sut.cancelInvite(invite)

        XCTAssertTrue(mockRepository.cancelInviteCalled)
        XCTAssertEqual(sut.pendingInvites.count, 1)
        XCTAssertFalse(sut.pendingInvites.contains { $0.id == "invite-to-cancel" })
    }

    // MARK: - Handle Received Invites Tests

    func test_acceptInvite_callsRepository() async {
        let invite = TestFixtures.receivedInvite(
            invite: TestFixtures.familyInvite(id: "invite-to-accept")
        )
        sut.receivedInvites = [invite]
        mockRepository.familyToReturn = TestFixtures.family()

        try? await sut.acceptInvite(invite)

        XCTAssertTrue(mockRepository.acceptInviteCalled)
        XCTAssertEqual(mockRepository.lastAcceptedInviteId, "invite-to-accept")
    }

    func test_acceptInvite_removesFromReceivedList() async {
        let invite = TestFixtures.receivedInvite(
            invite: TestFixtures.familyInvite(id: "invite-to-accept")
        )
        sut.receivedInvites = [invite]
        mockRepository.familyToReturn = TestFixtures.family()

        try? await sut.acceptInvite(invite)

        XCTAssertFalse(sut.receivedInvites.contains { $0.id == "invite-to-accept" })
    }

    func test_declineInvite_removesFromReceivedList() async {
        let invite = TestFixtures.receivedInvite(
            invite: TestFixtures.familyInvite(id: "invite-to-decline")
        )
        sut.receivedInvites = [invite]

        try? await sut.declineInvite(invite)

        XCTAssertTrue(mockRepository.declineInviteCalled)
        XCTAssertFalse(sut.receivedInvites.contains { $0.id == "invite-to-decline" })
    }

    // MARK: - Member Management Tests

    func test_updateMemberRole_callsRepository() async {
        let member = TestFixtures.familyMember(userId: "member-123")
        sut.family = TestFixtures.family(members: [member])

        try? await sut.updateMemberRole(member, to: .admin)

        XCTAssertTrue(mockRepository.updateMemberRoleCalled)
        XCTAssertEqual(mockRepository.lastUpdatedMemberId, "member-123")
        XCTAssertEqual(mockRepository.lastUpdatedMemberRole, .admin)
    }

    func test_updateMemberPrivacy_callsRepository() async {
        let member = TestFixtures.familyMember(userId: "member-123")
        sut.family = TestFixtures.family(members: [member])
        let settings = MemberPrivacySettings(
            sharePortfolioValue: true,
            shareHoldings: false,
            sharePerformance: true
        )

        try? await sut.updateMemberPrivacy(member, settings: settings)

        XCTAssertTrue(mockRepository.updateMemberPrivacyCalled)
        XCTAssertEqual(mockRepository.lastPrivacySettings?.sharePortfolioValue, true)
        XCTAssertEqual(mockRepository.lastPrivacySettings?.shareHoldings, false)
    }

    func test_removeMember_callsRepository() async {
        let member = TestFixtures.familyMember(userId: "member-to-remove")
        sut.family = TestFixtures.family(members: [member, TestFixtures.familyMember(userId: "other")])

        try? await sut.removeMember(member)

        XCTAssertTrue(mockRepository.removeMemberCalled)
        XCTAssertEqual(mockRepository.lastRemovedMemberId, "member-to-remove")
    }

    func test_removeMember_removesFromLocalList() async {
        let member = TestFixtures.familyMember(userId: "member-to-remove")
        sut.family = TestFixtures.family(members: [member, TestFixtures.familyMember(userId: "other")])

        try? await sut.removeMember(member)

        XCTAssertFalse(sut.family?.members.contains { $0.userId == "member-to-remove" } ?? false)
    }

    func test_removeMember_clearsConfirmationState() async {
        let member = TestFixtures.familyMember()
        sut.family = TestFixtures.family(members: [member])
        sut.showRemoveMemberConfirmation = true
        sut.memberToRemove = member

        try? await sut.removeMember(member)

        XCTAssertFalse(sut.showRemoveMemberConfirmation)
        XCTAssertNil(sut.memberToRemove)
    }

    func test_confirmRemoveMember_setsConfirmationState() {
        let member = TestFixtures.familyMember()

        sut.confirmRemoveMember(member)

        XCTAssertTrue(sut.showRemoveMemberConfirmation)
        XCTAssertEqual(sut.memberToRemove?.userId, member.userId)
    }

    // MARK: - Leave/Delete Family Tests

    func test_leaveFamily_callsRepository() async {
        sut.family = TestFixtures.family()

        try? await sut.leaveFamily()

        XCTAssertTrue(mockRepository.leaveFamilyCalled)
    }

    func test_leaveFamily_clearsFamilyState() async {
        sut.family = TestFixtures.family()
        sut.showLeaveConfirmation = true

        try? await sut.leaveFamily()

        XCTAssertNil(sut.family)
        XCTAssertFalse(sut.showLeaveConfirmation)
    }

    func test_deleteFamily_callsRepositoryWithFamilyId() async {
        sut.family = TestFixtures.family(id: "family-to-delete")

        try? await sut.deleteFamily()

        XCTAssertTrue(mockRepository.deleteFamilyCalled)
        XCTAssertEqual(mockRepository.lastDeletedFamilyId, "family-to-delete")
    }

    func test_deleteFamily_clearsFamilyState() async {
        sut.family = TestFixtures.family()

        try? await sut.deleteFamily()

        XCTAssertNil(sut.family)
    }

    func test_deleteFamily_doesNothingWhenNoFamily() async {
        sut.family = nil

        try? await sut.deleteFamily()

        XCTAssertFalse(mockRepository.deleteFamilyCalled)
    }

    // MARK: - Family Goals Tests

    func test_loadFamilyGoals_callsRepository() async {
        await sut.loadFamilyGoals()

        XCTAssertTrue(mockRepository.getFamilyGoalsCalled)
    }

    func test_loadFamilyGoals_setsFamilyGoals() async {
        let goals = FamilyGoalsOverview(
            familyId: "family-123",
            totalGoals: 5,
            completedGoals: 2,
            totalTargetAmount: 100000,
            totalCurrentAmount: 50000,
            memberGoals: []
        )
        mockRepository.familyGoalsToReturn = goals

        await sut.loadFamilyGoals()

        XCTAssertEqual(sut.familyGoals?.totalGoals, 5)
        XCTAssertEqual(sut.familyGoals?.completedGoals, 2)
    }

    func test_loadFamilyGoals_setsErrorOnFailure() async {
        mockRepository.errorToThrow = NetworkError.noConnection

        await sut.loadFamilyGoals()

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Selection Tests

    func test_selectMember_setsSelectedMemberAndShowsDetail() {
        let member = TestFixtures.familyMember()

        sut.selectMember(member)

        XCTAssertEqual(sut.selectedMember?.userId, member.userId)
        XCTAssertTrue(sut.showMemberDetail)
    }
}
