//
//  FamilyMemberTests.swift
//  GrowfolioTests
//
//  Tests for FamilyMember domain model.
//

import XCTest
@testable import Growfolio

final class FamilyMemberTests: XCTestCase {

    // MARK: - Identifiable Tests

    func testId_ReturnsUniqueId() {
        let member = TestFixtures.familyMember(uniqueId: "member-abc")
        XCTAssertEqual(member.id, "member-abc")
    }

    // MARK: - Initials Tests

    func testInitials_TwoNames_ReturnsTwoLetters() {
        let member = TestFixtures.familyMember(name: "John Doe")
        XCTAssertEqual(member.initials, "JD")
    }

    func testInitials_SingleName_ReturnsSingleLetter() {
        let member = TestFixtures.familyMember(name: "Madonna")
        XCTAssertEqual(member.initials, "M")
    }

    func testInitials_ThreeNames_ReturnsFirstAndLast() {
        let member = TestFixtures.familyMember(name: "John Paul Jones")
        XCTAssertEqual(member.initials, "JJ")
    }

    func testInitials_LowercaseName_ReturnsUppercased() {
        let member = TestFixtures.familyMember(name: "john doe")
        XCTAssertEqual(member.initials, "JD")
    }

    func testInitials_EmptyName_ReturnsEmpty() {
        let member = TestFixtures.familyMember(name: "")
        XCTAssertEqual(member.initials, "")
    }

    // MARK: - IsActive Tests

    func testIsActive_ActiveStatus_ReturnsTrue() {
        let member = TestFixtures.familyMember(status: .active)
        XCTAssertTrue(member.isActive)
    }

    func testIsActive_PendingStatus_ReturnsFalse() {
        let member = TestFixtures.familyMember(status: .pending)
        XCTAssertFalse(member.isActive)
    }

    func testIsActive_InvitedStatus_ReturnsFalse() {
        let member = TestFixtures.familyMember(status: .invited)
        XCTAssertFalse(member.isActive)
    }

    func testIsActive_SuspendedStatus_ReturnsFalse() {
        let member = TestFixtures.familyMember(status: .suspended)
        XCTAssertFalse(member.isActive)
    }

    func testIsActive_RemovedStatus_ReturnsFalse() {
        let member = TestFixtures.familyMember(status: .removed)
        XCTAssertFalse(member.isActive)
    }

    // MARK: - IsAdmin Tests

    func testIsAdmin_AdminRole_ReturnsTrue() {
        let member = TestFixtures.familyMember(role: .admin)
        XCTAssertTrue(member.isAdmin)
    }

    func testIsAdmin_MemberRole_ReturnsFalse() {
        let member = TestFixtures.familyMember(role: .member)
        XCTAssertFalse(member.isAdmin)
    }

    func testIsAdmin_ViewerRole_ReturnsFalse() {
        let member = TestFixtures.familyMember(role: .viewer)
        XCTAssertFalse(member.isAdmin)
    }

    // MARK: - CanInvite Tests

    func testCanInvite_AdminRole_ReturnsTrue() {
        let member = TestFixtures.familyMember(role: .admin)
        XCTAssertTrue(member.canInvite)
    }

    func testCanInvite_MemberRole_ReturnsTrue() {
        let member = TestFixtures.familyMember(role: .member)
        XCTAssertTrue(member.canInvite)
    }

    func testCanInvite_ViewerRole_ReturnsFalse() {
        let member = TestFixtures.familyMember(role: .viewer)
        XCTAssertFalse(member.canInvite)
    }

    // MARK: - StatusDescription Tests

    func testStatusDescription_ReturnsDisplayName() {
        let activeMember = TestFixtures.familyMember(status: .active)
        XCTAssertEqual(activeMember.statusDescription, "Active")

        let pendingMember = TestFixtures.familyMember(status: .pending)
        XCTAssertEqual(pendingMember.statusDescription, "Pending")
    }

    // MARK: - StatusColorHex Tests

    func testStatusColorHex_Active_ReturnsGreen() {
        let member = TestFixtures.familyMember(status: .active)
        XCTAssertEqual(member.statusColorHex, "#34C759")
    }

    func testStatusColorHex_Pending_ReturnsOrange() {
        let member = TestFixtures.familyMember(status: .pending)
        XCTAssertEqual(member.statusColorHex, "#FF9500")
    }

    func testStatusColorHex_Removed_ReturnsRed() {
        let member = TestFixtures.familyMember(status: .removed)
        XCTAssertEqual(member.statusColorHex, "#FF3B30")
    }

    // MARK: - Privacy Settings Tests

    func testPrivacySettings_DefaultValues() {
        let member = TestFixtures.familyMember(
            sharePortfolioValue: true,
            shareHoldings: false,
            sharePerformance: true
        )
        XCTAssertTrue(member.sharePortfolioValue)
        XCTAssertFalse(member.shareHoldings)
        XCTAssertTrue(member.sharePerformance)
    }

    func testPrivacySettings_AllEnabled() {
        let member = TestFixtures.familyMember(
            sharePortfolioValue: true,
            shareHoldings: true,
            sharePerformance: true
        )
        XCTAssertTrue(member.sharePortfolioValue)
        XCTAssertTrue(member.shareHoldings)
        XCTAssertTrue(member.sharePerformance)
    }

    func testPrivacySettings_AllDisabled() {
        let member = TestFixtures.familyMember(
            sharePortfolioValue: false,
            shareHoldings: false,
            sharePerformance: false
        )
        XCTAssertFalse(member.sharePortfolioValue)
        XCTAssertFalse(member.shareHoldings)
        XCTAssertFalse(member.sharePerformance)
    }

    // MARK: - FamilyMemberRole Tests

    func testFamilyMemberRole_DisplayName() {
        XCTAssertEqual(FamilyMemberRole.admin.displayName, "Admin")
        XCTAssertEqual(FamilyMemberRole.member.displayName, "Member")
        XCTAssertEqual(FamilyMemberRole.viewer.displayName, "Viewer")
    }

    func testFamilyMemberRole_Description() {
        XCTAssertFalse(FamilyMemberRole.admin.description.isEmpty)
        XCTAssertFalse(FamilyMemberRole.member.description.isEmpty)
        XCTAssertFalse(FamilyMemberRole.viewer.description.isEmpty)
    }

    func testFamilyMemberRole_IconName() {
        XCTAssertFalse(FamilyMemberRole.admin.iconName.isEmpty)
        XCTAssertFalse(FamilyMemberRole.member.iconName.isEmpty)
        XCTAssertFalse(FamilyMemberRole.viewer.iconName.isEmpty)
    }

    func testFamilyMemberRole_ColorHex() {
        XCTAssertEqual(FamilyMemberRole.admin.colorHex, "#007AFF")
        XCTAssertEqual(FamilyMemberRole.member.colorHex, "#34C759")
        XCTAssertEqual(FamilyMemberRole.viewer.colorHex, "#8E8E93")
    }

    func testFamilyMemberRole_AllCases() {
        XCTAssertEqual(FamilyMemberRole.allCases.count, 3)
    }

    // MARK: - FamilyMemberStatus Tests

    func testFamilyMemberStatus_DisplayName() {
        XCTAssertEqual(FamilyMemberStatus.pending.displayName, "Pending")
        XCTAssertEqual(FamilyMemberStatus.invited.displayName, "Invited")
        XCTAssertEqual(FamilyMemberStatus.active.displayName, "Active")
        XCTAssertEqual(FamilyMemberStatus.suspended.displayName, "Suspended")
        XCTAssertEqual(FamilyMemberStatus.removed.displayName, "Removed")
    }

    func testFamilyMemberStatus_IconName() {
        XCTAssertFalse(FamilyMemberStatus.pending.iconName.isEmpty)
        XCTAssertFalse(FamilyMemberStatus.active.iconName.isEmpty)
    }

    func testFamilyMemberStatus_ColorHex() {
        XCTAssertEqual(FamilyMemberStatus.active.colorHex, "#34C759")
        XCTAssertEqual(FamilyMemberStatus.invited.colorHex, "#007AFF")
    }

    // MARK: - Codable Tests

    func testFamilyMember_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.familyMember(
            uniqueId: "member-123",
            userId: "user-456",
            name: "John Doe",
            email: "john@example.com",
            role: .admin,
            status: .active,
            sharePortfolioValue: true,
            shareHoldings: true,
            sharePerformance: false
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(FamilyMember.self, from: data)

        XCTAssertEqual(decoded.uniqueId, original.uniqueId)
        XCTAssertEqual(decoded.userId, original.userId)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.email, original.email)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.sharePortfolioValue, original.sharePortfolioValue)
        XCTAssertEqual(decoded.shareHoldings, original.shareHoldings)
        XCTAssertEqual(decoded.sharePerformance, original.sharePerformance)
    }

    func testFamilyMember_EncodeDecode_NilPictureUrl() throws {
        let original = TestFixtures.familyMember(pictureUrl: nil)

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(FamilyMember.self, from: data)

        XCTAssertNil(decoded.pictureUrl)
    }

    func testFamilyMemberRole_Codable() throws {
        for role in FamilyMemberRole.allCases {
            let data = try JSONEncoder().encode(role)
            let decoded = try JSONDecoder().decode(FamilyMemberRole.self, from: data)
            XCTAssertEqual(decoded, role)
        }
    }

    // MARK: - Equatable Tests

    func testFamilyMember_Equatable_SameUniqueId() {
        let member1 = TestFixtures.familyMember(uniqueId: "m1", name: "John")
        let member2 = TestFixtures.familyMember(uniqueId: "m1", name: "John")
        XCTAssertEqual(member1, member2)
    }

    func testFamilyMember_Equatable_DifferentUniqueId() {
        let member1 = TestFixtures.familyMember(uniqueId: "m1")
        let member2 = TestFixtures.familyMember(uniqueId: "m2")
        XCTAssertNotEqual(member1, member2)
    }

    // MARK: - Hashable Tests

    func testFamilyMember_Hashable() {
        let member1 = TestFixtures.familyMember(uniqueId: "m1")
        let member2 = TestFixtures.familyMember(uniqueId: "m2")

        var set = Set<FamilyMember>()
        set.insert(member1)
        set.insert(member2)

        XCTAssertEqual(set.count, 2)
    }

    func testFamilyMember_Hashable_SameIdNotDuplicated() {
        // Note: FamilyMember uses synthesized Equatable/Hashable which compares ALL properties.
        // Two members with the same ID but different names are NOT considered equal/duplicate.
        // This test verifies that members with identical properties are deduplicated.
        let member1 = TestFixtures.familyMember(uniqueId: "m1", name: "Name 1")
        let member2 = TestFixtures.familyMember(uniqueId: "m1", name: "Name 1")

        var set = Set<FamilyMember>()
        set.insert(member1)
        set.insert(member2)

        XCTAssertEqual(set.count, 1)
    }

    // MARK: - MemberPrivacySettings Tests

    func testMemberPrivacySettings_Default() {
        let settings = MemberPrivacySettings.default
        XCTAssertTrue(settings.sharePortfolioValue)
        XCTAssertFalse(settings.shareHoldings)
        XCTAssertTrue(settings.sharePerformance)
        XCTAssertTrue(settings.shareGoals)
        XCTAssertFalse(settings.shareDCASchedules)
    }

    func testMemberPrivacySettings_ShareAll() {
        let settings = MemberPrivacySettings.shareAll
        XCTAssertTrue(settings.sharePortfolioValue)
        XCTAssertTrue(settings.shareHoldings)
        XCTAssertTrue(settings.sharePerformance)
        XCTAssertTrue(settings.shareGoals)
        XCTAssertTrue(settings.shareDCASchedules)
    }

    func testMemberPrivacySettings_Minimal() {
        let settings = MemberPrivacySettings.minimal
        XCTAssertFalse(settings.sharePortfolioValue)
        XCTAssertFalse(settings.shareHoldings)
        XCTAssertFalse(settings.sharePerformance)
        XCTAssertFalse(settings.shareGoals)
        XCTAssertFalse(settings.shareDCASchedules)
    }

    func testMemberPrivacySettings_Codable() throws {
        let original = MemberPrivacySettings(
            sharePortfolioValue: true,
            shareHoldings: true,
            sharePerformance: false,
            shareGoals: true,
            shareDCASchedules: false
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(MemberPrivacySettings.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Edge Cases

    func testFamilyMember_EmptyEmail() {
        let member = TestFixtures.familyMember(email: "")
        XCTAssertEqual(member.email, "")
    }

    func testFamilyMember_SpecialCharactersInName() {
        let member = TestFixtures.familyMember(name: "O'Brien-Smith Jr.")
        XCTAssertEqual(member.name, "O'Brien-Smith Jr.")
        XCTAssertEqual(member.initials, "OJ")
    }
}
