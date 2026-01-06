//
//  FamilyTests.swift
//  GrowfolioTests
//
//  Tests for Family domain model.
//

import XCTest
@testable import Growfolio

final class FamilyTests: XCTestCase {

    // MARK: - Member Count Tests

    func testMemberCount_EmptyMembers_ReturnsZero() {
        let family = TestFixtures.family(members: [])
        XCTAssertEqual(family.memberCount, 0)
    }

    func testMemberCount_WithMembers_ReturnsCorrectCount() {
        let members = TestFixtures.sampleFamilyMembers
        let family = TestFixtures.family(members: members)
        XCTAssertEqual(family.memberCount, 3)
    }

    func testMemberCount_SingleMember_ReturnsOne() {
        let member = TestFixtures.familyMember()
        let family = TestFixtures.family(members: [member])
        XCTAssertEqual(family.memberCount, 1)
    }

    // MARK: - Active Members Tests

    func testActiveMembers_NoActiveMembers_ReturnsEmpty() {
        let pendingMember = TestFixtures.familyMember(status: .pending)
        let invitedMember = TestFixtures.familyMember(uniqueId: "member-2", status: .invited)
        let family = TestFixtures.family(members: [pendingMember, invitedMember])
        XCTAssertTrue(family.activeMembers.isEmpty)
    }

    func testActiveMembers_AllActive_ReturnsAll() {
        let member1 = TestFixtures.familyMember(uniqueId: "m1", status: .active)
        let member2 = TestFixtures.familyMember(uniqueId: "m2", status: .active)
        let family = TestFixtures.family(members: [member1, member2])
        XCTAssertEqual(family.activeMembers.count, 2)
    }

    func testActiveMembers_MixedStatuses_ReturnsOnlyActive() {
        let activeMember = TestFixtures.familyMember(uniqueId: "m1", status: .active)
        let pendingMember = TestFixtures.familyMember(uniqueId: "m2", status: .pending)
        let suspendedMember = TestFixtures.familyMember(uniqueId: "m3", status: .suspended)
        let family = TestFixtures.family(members: [activeMember, pendingMember, suspendedMember])
        XCTAssertEqual(family.activeMembers.count, 1)
        XCTAssertEqual(family.activeMembers.first?.uniqueId, "m1")
    }

    // MARK: - Pending Invites Count Tests

    func testPendingInvitesCount_NoPending_ReturnsZero() {
        let activeMember = TestFixtures.familyMember(status: .active)
        let family = TestFixtures.family(members: [activeMember])
        XCTAssertEqual(family.pendingInvitesCount, 0)
    }

    func testPendingInvitesCount_WithPending_ReturnsCount() {
        let pendingMember = TestFixtures.familyMember(uniqueId: "m1", status: .pending)
        let invitedMember = TestFixtures.familyMember(uniqueId: "m2", status: .invited)
        let activeMember = TestFixtures.familyMember(uniqueId: "m3", status: .active)
        let family = TestFixtures.family(members: [pendingMember, invitedMember, activeMember])
        XCTAssertEqual(family.pendingInvitesCount, 2)
    }

    // MARK: - Can Add Members Tests

    func testCanAddMembers_BelowMax_ReturnsTrue() {
        let member = TestFixtures.familyMember()
        let family = TestFixtures.family(members: [member], maxMembers: 10)
        XCTAssertTrue(family.canAddMembers)
    }

    func testCanAddMembers_AtMax_ReturnsFalse() {
        let members = (0..<5).map { TestFixtures.familyMember(uniqueId: "m\($0)", userId: "u\($0)") }
        let family = TestFixtures.family(members: members, maxMembers: 5)
        XCTAssertFalse(family.canAddMembers)
    }

    func testCanAddMembers_EmptyFamily_ReturnsTrue() {
        let family = TestFixtures.family(members: [], maxMembers: 10)
        XCTAssertTrue(family.canAddMembers)
    }

    // MARK: - Remaining Slots Tests

    func testRemainingSlots_EmptyFamily_ReturnsMax() {
        let family = TestFixtures.family(members: [], maxMembers: 10)
        XCTAssertEqual(family.remainingSlots, 10)
    }

    func testRemainingSlots_PartiallyFilled_ReturnsCorrectCount() {
        let members = (0..<3).map { TestFixtures.familyMember(uniqueId: "m\($0)", userId: "u\($0)") }
        let family = TestFixtures.family(members: members, maxMembers: 10)
        XCTAssertEqual(family.remainingSlots, 7)
    }

    func testRemainingSlots_FullFamily_ReturnsZero() {
        let members = (0..<5).map { TestFixtures.familyMember(uniqueId: "m\($0)", userId: "u\($0)") }
        let family = TestFixtures.family(members: members, maxMembers: 5)
        XCTAssertEqual(family.remainingSlots, 0)
    }

    func testRemainingSlots_OverMax_ReturnsZero() {
        let members = (0..<7).map { TestFixtures.familyMember(uniqueId: "m\($0)", userId: "u\($0)") }
        let family = TestFixtures.family(members: members, maxMembers: 5)
        XCTAssertEqual(family.remainingSlots, 0)
    }

    // MARK: - Is Admin Tests

    func testIsAdmin_WithAdminId_ReturnsTrue() {
        let family = TestFixtures.family(ownerId: "owner-123", adminIds: ["owner-123", "admin-456"])
        XCTAssertTrue(family.isAdmin(userId: "admin-456"))
    }

    func testIsAdmin_WithOwnerId_ReturnsTrue() {
        let family = TestFixtures.family(ownerId: "owner-123", adminIds: ["owner-123"])
        XCTAssertTrue(family.isAdmin(userId: "owner-123"))
    }

    func testIsAdmin_NonAdmin_ReturnsFalse() {
        let family = TestFixtures.family(ownerId: "owner-123", adminIds: ["owner-123"])
        XCTAssertFalse(family.isAdmin(userId: "user-999"))
    }

    // MARK: - Is Owner Tests

    func testIsOwner_WithOwnerId_ReturnsTrue() {
        let family = TestFixtures.family(ownerId: "owner-123")
        XCTAssertTrue(family.isOwner(userId: "owner-123"))
    }

    func testIsOwner_NonOwner_ReturnsFalse() {
        let family = TestFixtures.family(ownerId: "owner-123")
        XCTAssertFalse(family.isOwner(userId: "user-456"))
    }

    // MARK: - Member Lookup Tests

    func testMember_ExistingUserId_ReturnsMember() {
        let member = TestFixtures.familyMember(uniqueId: "m1", userId: "user-456", name: "John Doe")
        let family = TestFixtures.family(members: [member])

        let found = family.member(userId: "user-456")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "John Doe")
    }

    func testMember_NonExistingUserId_ReturnsNil() {
        let member = TestFixtures.familyMember(userId: "user-456")
        let family = TestFixtures.family(members: [member])

        XCTAssertNil(family.member(userId: "user-999"))
    }

    func testMember_EmptyMembers_ReturnsNil() {
        let family = TestFixtures.family(members: [])
        XCTAssertNil(family.member(userId: "user-123"))
    }

    // MARK: - Owner Always In AdminIds Tests

    func testInit_OwnerNotInAdminIds_AddsOwner() {
        let family = Family(
            name: "Test Family",
            ownerId: "owner-123",
            adminIds: ["admin-456"]
        )
        XCTAssertTrue(family.adminIds.contains("owner-123"))
        XCTAssertTrue(family.adminIds.contains("admin-456"))
    }

    func testInit_OwnerAlreadyInAdminIds_DoesNotDuplicate() {
        let family = Family(
            name: "Test Family",
            ownerId: "owner-123",
            adminIds: ["owner-123", "admin-456"]
        )
        let ownerCount = family.adminIds.filter { $0 == "owner-123" }.count
        XCTAssertEqual(ownerCount, 1)
    }

    // MARK: - Codable Tests

    func testFamily_EncodeDecode_RoundTrip() throws {
        let member = TestFixtures.familyMember()
        let original = TestFixtures.family(
            name: "Test Family",
            familyDescription: "A test family group",
            members: [member],
            maxMembers: 15,
            allowSharedGoals: true
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(Family.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.familyDescription, original.familyDescription)
        XCTAssertEqual(decoded.ownerId, original.ownerId)
        XCTAssertEqual(decoded.maxMembers, original.maxMembers)
        XCTAssertEqual(decoded.allowSharedGoals, original.allowSharedGoals)
        XCTAssertEqual(decoded.members.count, original.members.count)
    }

    func testFamily_EncodeDecode_NilDescription() throws {
        let original = TestFixtures.family(familyDescription: nil)

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(Family.self, from: data)

        XCTAssertNil(decoded.familyDescription)
    }

    // MARK: - Equatable Tests

    func testFamily_Equatable_SameId() {
        let family1 = TestFixtures.family(id: "f1", name: "Family 1")
        let family2 = TestFixtures.family(id: "f1", name: "Family 1")
        XCTAssertEqual(family1, family2)
    }

    func testFamily_Equatable_DifferentId() {
        let family1 = TestFixtures.family(id: "f1")
        let family2 = TestFixtures.family(id: "f2")
        XCTAssertNotEqual(family1, family2)
    }

    // MARK: - Hashable Tests

    func testFamily_Hashable() {
        let family1 = TestFixtures.family(id: "f1")
        let family2 = TestFixtures.family(id: "f2")

        var set = Set<Family>()
        set.insert(family1)
        set.insert(family2)

        XCTAssertEqual(set.count, 2)
    }

    func testFamily_Hashable_SameIdNotDuplicated() {
        // Note: Family uses synthesized Equatable/Hashable which compares ALL properties.
        // Two families with the same ID but different names are NOT considered equal/duplicate.
        // This test verifies that families with identical properties are deduplicated.
        let family1 = TestFixtures.family(id: "f1", name: "Name 1")
        let family2 = TestFixtures.family(id: "f1", name: "Name 1")

        var set = Set<Family>()
        set.insert(family1)
        set.insert(family2)

        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Edge Cases

    func testFamily_MaxMembersZero() {
        let family = TestFixtures.family(members: [], maxMembers: 0)
        XCTAssertFalse(family.canAddMembers)
        XCTAssertEqual(family.remainingSlots, 0)
    }

    func testFamily_LargeNumberOfMembers() {
        let members = (0..<100).map { TestFixtures.familyMember(uniqueId: "m\($0)", userId: "u\($0)") }
        let family = TestFixtures.family(members: members, maxMembers: 100)
        XCTAssertEqual(family.memberCount, 100)
        XCTAssertFalse(family.canAddMembers)
    }

    // MARK: - FamilyGoalsOverview Tests

    func testFamilyGoalsOverview_OverallProgress_ZeroTarget() {
        let overview = FamilyGoalsOverview(
            familyId: "family-123",
            totalGoals: 0,
            completedGoals: 0,
            totalTargetAmount: 0,
            totalCurrentAmount: 0,
            memberGoals: []
        )
        XCTAssertEqual(overview.overallProgress, 0)
    }

    func testFamilyGoalsOverview_OverallProgress_PartialProgress() {
        let overview = FamilyGoalsOverview(
            familyId: "family-123",
            totalGoals: 2,
            completedGoals: 1,
            totalTargetAmount: 10000,
            totalCurrentAmount: 5000,
            memberGoals: []
        )
        XCTAssertEqual(overview.overallProgress, 0.5, accuracy: 0.001)
    }

    func testFamilyGoalsOverview_GoalsOnTrack() {
        let goals = [
            GoalSummaryItem(id: "g1", name: "Goal 1", targetAmount: 1000, currentAmount: 500, progress: 0.5, isOnTrack: true, targetDate: nil),
            GoalSummaryItem(id: "g2", name: "Goal 2", targetAmount: 2000, currentAmount: 500, progress: 0.25, isOnTrack: false, targetDate: nil)
        ]
        let memberGoal = MemberGoalSummary(memberId: "m1", memberName: "John", memberPictureUrl: nil, goals: goals, totalProgress: 0.375)
        let overview = FamilyGoalsOverview(
            familyId: "family-123",
            totalGoals: 2,
            completedGoals: 0,
            totalTargetAmount: 3000,
            totalCurrentAmount: 1000,
            memberGoals: [memberGoal]
        )
        XCTAssertEqual(overview.goalsOnTrack, 1)
    }
}
