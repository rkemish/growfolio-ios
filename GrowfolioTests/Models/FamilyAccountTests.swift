//
//  FamilyAccountTests.swift
//  GrowfolioTests
//
//  Tests for FamilyAccount domain model.
//

import XCTest
@testable import Growfolio

final class FamilyAccountTests: XCTestCase {

    // MARK: - Initials Tests

    func testInitials_TwoNames_ReturnsTwoLetters() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "John Doe"
        )
        XCTAssertEqual(account.initials, "JD")
    }

    func testInitials_SingleName_ReturnsSingleLetter() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Madonna"
        )
        XCTAssertEqual(account.initials, "M")
    }

    func testInitials_ThreeNames_ReturnsFirstAndLast() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "John Paul Jones"
        )
        XCTAssertEqual(account.initials, "JJ")
    }

    func testInitials_LowercaseName_ReturnsUppercased() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "john doe"
        )
        XCTAssertEqual(account.initials, "JD")
    }

    func testInitials_EmptyName_ReturnsEmpty() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: ""
        )
        XCTAssertEqual(account.initials, "")
    }

    // MARK: - IsMinor Tests

    func testIsMinor_Under18_ReturnsTrue() {
        let dob = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Young Kid",
            dateOfBirth: dob
        )
        XCTAssertTrue(account.isMinor)
    }

    func testIsMinor_Over18_ReturnsFalse() {
        let dob = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Adult Person",
            dateOfBirth: dob
        )
        XCTAssertFalse(account.isMinor)
    }

    func testIsMinor_Exactly18_ReturnsFalse() {
        let dob = Calendar.current.date(byAdding: .year, value: -18, to: Date())!
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "New Adult",
            dateOfBirth: dob
        )
        XCTAssertFalse(account.isMinor)
    }

    func testIsMinor_NilDateOfBirth_ReturnsFalse() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Unknown Age",
            dateOfBirth: nil
        )
        XCTAssertFalse(account.isMinor)
    }

    // MARK: - Age Tests

    func testAge_ValidDateOfBirth_ReturnsAge() {
        let dob = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Adult",
            dateOfBirth: dob
        )
        XCTAssertEqual(account.age, 30)
    }

    func testAge_NilDateOfBirth_ReturnsNil() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Unknown Age",
            dateOfBirth: nil
        )
        XCTAssertNil(account.age)
    }

    // MARK: - HasJoined Tests

    func testHasJoined_ActiveWithMemberUserId_ReturnsTrue() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            memberUserId: "member-456",
            name: "Active Member",
            status: .active
        )
        XCTAssertTrue(account.hasJoined)
    }

    func testHasJoined_ActiveWithoutMemberUserId_ReturnsFalse() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            memberUserId: nil,
            name: "Pending Member",
            status: .active
        )
        XCTAssertFalse(account.hasJoined)
    }

    func testHasJoined_PendingWithMemberUserId_ReturnsFalse() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            memberUserId: "member-456",
            name: "Pending Member",
            status: .pending
        )
        XCTAssertFalse(account.hasJoined)
    }

    func testHasJoined_InvitedStatus_ReturnsFalse() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            memberUserId: "member-456",
            name: "Invited Member",
            status: .invited
        )
        XCTAssertFalse(account.hasJoined)
    }

    // MARK: - CanManagePortfolios Tests

    func testCanManagePortfolios_AdminWithPermission_ReturnsTrue() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Admin User",
            role: .admin,
            permissions: .admin
        )
        XCTAssertTrue(account.canManagePortfolios)
    }

    func testCanManagePortfolios_ManagerWithPermission_ReturnsTrue() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Manager User",
            role: .manager,
            permissions: .manager
        )
        XCTAssertTrue(account.canManagePortfolios)
    }

    func testCanManagePortfolios_ViewerWithPermission_ReturnsFalse() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Viewer User",
            role: .viewer,
            permissions: FamilyPermissions(canManagePortfolios: true)
        )
        XCTAssertFalse(account.canManagePortfolios)
    }

    func testCanManagePortfolios_AdminWithoutPermission_ReturnsFalse() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Limited Admin",
            role: .admin,
            permissions: .viewOnly
        )
        XCTAssertFalse(account.canManagePortfolios)
    }

    // MARK: - CanTrade Tests

    func testCanTrade_AdminWithPermission_ReturnsTrue() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Trading Admin",
            role: .admin,
            permissions: .admin
        )
        XCTAssertTrue(account.canTrade)
    }

    func testCanTrade_ManagerWithPermission_ReturnsFalse() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "Manager User",
            role: .manager,
            permissions: FamilyPermissions(canTrade: true)
        )
        XCTAssertFalse(account.canTrade)
    }

    func testCanTrade_AdminWithoutPermission_ReturnsFalse() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "View-only Admin",
            role: .admin,
            permissions: .viewOnly
        )
        XCTAssertFalse(account.canTrade)
    }

    // MARK: - FamilyRelationship Tests

    func testFamilyRelationship_DisplayName() {
        XCTAssertEqual(FamilyRelationship.spouse.displayName, "Spouse")
        XCTAssertEqual(FamilyRelationship.partner.displayName, "Partner")
        XCTAssertEqual(FamilyRelationship.child.displayName, "Child")
        XCTAssertEqual(FamilyRelationship.parent.displayName, "Parent")
        XCTAssertEqual(FamilyRelationship.sibling.displayName, "Sibling")
        XCTAssertEqual(FamilyRelationship.grandparent.displayName, "Grandparent")
        XCTAssertEqual(FamilyRelationship.grandchild.displayName, "Grandchild")
        XCTAssertEqual(FamilyRelationship.guardian.displayName, "Guardian")
        XCTAssertEqual(FamilyRelationship.other.displayName, "Other")
    }

    func testFamilyRelationship_IconName() {
        for relationship in FamilyRelationship.allCases {
            XCTAssertFalse(relationship.iconName.isEmpty)
        }
    }

    func testFamilyRelationship_AllCases() {
        XCTAssertEqual(FamilyRelationship.allCases.count, 9)
    }

    // MARK: - FamilyRole Tests

    func testFamilyRole_DisplayName() {
        XCTAssertEqual(FamilyRole.admin.displayName, "Admin")
        XCTAssertEqual(FamilyRole.manager.displayName, "Manager")
        XCTAssertEqual(FamilyRole.viewer.displayName, "Viewer")
    }

    func testFamilyRole_Description() {
        XCTAssertFalse(FamilyRole.admin.description.isEmpty)
        XCTAssertFalse(FamilyRole.manager.description.isEmpty)
        XCTAssertFalse(FamilyRole.viewer.description.isEmpty)
    }

    func testFamilyRole_AllCases() {
        XCTAssertEqual(FamilyRole.allCases.count, 3)
    }

    // MARK: - FamilyPermissions Tests

    func testFamilyPermissions_ViewOnly() {
        let permissions = FamilyPermissions.viewOnly
        XCTAssertTrue(permissions.canViewPortfolios)
        XCTAssertFalse(permissions.canManagePortfolios)
        XCTAssertTrue(permissions.canViewGoals)
        XCTAssertFalse(permissions.canManageGoals)
        XCTAssertFalse(permissions.canTrade)
        XCTAssertFalse(permissions.canInviteMembers)
    }

    func testFamilyPermissions_Manager() {
        let permissions = FamilyPermissions.manager
        XCTAssertTrue(permissions.canViewPortfolios)
        XCTAssertTrue(permissions.canManagePortfolios)
        XCTAssertTrue(permissions.canViewGoals)
        XCTAssertTrue(permissions.canManageGoals)
        XCTAssertFalse(permissions.canTrade)
        XCTAssertFalse(permissions.canInviteMembers)
    }

    func testFamilyPermissions_Admin() {
        let permissions = FamilyPermissions.admin
        XCTAssertTrue(permissions.canViewPortfolios)
        XCTAssertTrue(permissions.canManagePortfolios)
        XCTAssertTrue(permissions.canViewGoals)
        XCTAssertTrue(permissions.canManageGoals)
        XCTAssertTrue(permissions.canTrade)
        XCTAssertTrue(permissions.canInviteMembers)
    }

    func testFamilyPermissions_Codable() throws {
        let original = FamilyPermissions(
            canViewPortfolios: true,
            canManagePortfolios: true,
            canViewGoals: false,
            canManageGoals: false,
            canViewDCASchedules: true,
            canManageDCASchedules: false,
            canTrade: false,
            canInviteMembers: true
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(FamilyPermissions.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Codable Tests

    func testFamilyAccount_EncodeDecode_RoundTrip() throws {
        let dob = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
        let original = FamilyAccount(
            id: "account-123",
            primaryUserId: "user-123",
            memberUserId: "member-456",
            name: "John Doe",
            email: "john@example.com",
            relationship: .spouse,
            dateOfBirth: dob,
            role: .admin,
            permissions: .admin,
            accessiblePortfolioIds: ["p1", "p2"],
            status: .active
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(FamilyAccount.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.primaryUserId, original.primaryUserId)
        XCTAssertEqual(decoded.memberUserId, original.memberUserId)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.email, original.email)
        XCTAssertEqual(decoded.relationship, original.relationship)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.permissions, original.permissions)
        XCTAssertEqual(decoded.accessiblePortfolioIds, original.accessiblePortfolioIds)
        XCTAssertEqual(decoded.status, original.status)
    }

    func testFamilyAccount_EncodeDecode_NilOptionals() throws {
        let original = FamilyAccount(
            primaryUserId: "user-123",
            memberUserId: nil,
            name: "Jane Doe",
            email: nil,
            dateOfBirth: nil,
            profilePictureURL: nil,
            invitedAt: nil,
            joinedAt: nil
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(FamilyAccount.self, from: data)

        XCTAssertNil(decoded.memberUserId)
        XCTAssertNil(decoded.email)
        XCTAssertNil(decoded.dateOfBirth)
        XCTAssertNil(decoded.profilePictureURL)
        XCTAssertNil(decoded.invitedAt)
        XCTAssertNil(decoded.joinedAt)
    }

    func testFamilyRelationship_Codable() throws {
        for relationship in FamilyRelationship.allCases {
            let data = try JSONEncoder().encode(relationship)
            let decoded = try JSONDecoder().decode(FamilyRelationship.self, from: data)
            XCTAssertEqual(decoded, relationship)
        }
    }

    func testFamilyRole_Codable() throws {
        for role in FamilyRole.allCases {
            let data = try JSONEncoder().encode(role)
            let decoded = try JSONDecoder().decode(FamilyRole.self, from: data)
            XCTAssertEqual(decoded, role)
        }
    }

    // MARK: - Equatable Tests

    func testFamilyAccount_Equatable_SameId() {
        let sharedDate = Date()
        let account1 = FamilyAccount(id: "a1", primaryUserId: "user-123", name: "John", createdAt: sharedDate, updatedAt: sharedDate)
        let account2 = FamilyAccount(id: "a1", primaryUserId: "user-123", name: "John", createdAt: sharedDate, updatedAt: sharedDate)
        XCTAssertEqual(account1, account2)
    }

    func testFamilyAccount_Equatable_DifferentId() {
        let account1 = FamilyAccount(id: "a1", primaryUserId: "user-123", name: "John")
        let account2 = FamilyAccount(id: "a2", primaryUserId: "user-123", name: "John")
        XCTAssertNotEqual(account1, account2)
    }

    // MARK: - Hashable Tests

    func testFamilyAccount_Hashable() {
        let account1 = FamilyAccount(id: "a1", primaryUserId: "user-123", name: "John")
        let account2 = FamilyAccount(id: "a2", primaryUserId: "user-123", name: "Jane")

        var set = Set<FamilyAccount>()
        set.insert(account1)
        set.insert(account2)

        XCTAssertEqual(set.count, 2)
    }

    func testFamilyAccount_Hashable_SameIdNotDuplicated() {
        // Note: FamilyAccount uses synthesized Equatable/Hashable which compares ALL properties.
        // Two accounts with the same ID but different names are NOT considered equal/duplicate.
        // This test verifies that accounts with identical properties are deduplicated.
        let sharedDate = Date()
        let account1 = FamilyAccount(id: "a1", primaryUserId: "user-123", name: "John", createdAt: sharedDate, updatedAt: sharedDate)
        let account2 = FamilyAccount(id: "a1", primaryUserId: "user-123", name: "John", createdAt: sharedDate, updatedAt: sharedDate)

        var set = Set<FamilyAccount>()
        set.insert(account1)
        set.insert(account2)

        XCTAssertEqual(set.count, 1)
    }

    // MARK: - FamilySummary Tests

    func testFamilySummary_Init() {
        let members = [
            FamilyAccount(primaryUserId: "user-1", name: "John", status: .active),
            FamilyAccount(primaryUserId: "user-2", name: "Jane", status: .active),
            FamilyAccount(primaryUserId: "user-3", name: "Bob", status: .pending),
            FamilyAccount(primaryUserId: "user-4", name: "Alice", status: .invited)
        ]
        let portfolios = [
            TestFixtures.portfolio(id: "p1", totalValue: 10000),
            TestFixtures.portfolio(id: "p2", totalValue: 20000)
        ]

        let summary = FamilySummary(members: members, sharedPortfolios: portfolios)

        XCTAssertEqual(summary.totalMembers, 4)
        XCTAssertEqual(summary.activeMembers, 2)
        XCTAssertEqual(summary.pendingInvitations, 2)
        XCTAssertEqual(summary.totalSharedPortfolios, 2)
        XCTAssertEqual(summary.combinedPortfolioValue, 30000)
    }

    func testFamilySummary_EmptyMembers() {
        let summary = FamilySummary(members: [], sharedPortfolios: [])

        XCTAssertEqual(summary.totalMembers, 0)
        XCTAssertEqual(summary.activeMembers, 0)
        XCTAssertEqual(summary.pendingInvitations, 0)
        XCTAssertEqual(summary.totalSharedPortfolios, 0)
        XCTAssertEqual(summary.combinedPortfolioValue, 0)
    }

    // MARK: - FamilyActivity Tests

    func testFamilyActivity_Init() {
        let activity = FamilyActivity(
            familyAccountId: "account-123",
            memberName: "John Doe",
            action: .memberJoined,
            details: "Welcome message"
        )

        XCTAssertFalse(activity.id.isEmpty)
        XCTAssertEqual(activity.familyAccountId, "account-123")
        XCTAssertEqual(activity.memberName, "John Doe")
        XCTAssertEqual(activity.action, .memberJoined)
        XCTAssertEqual(activity.details, "Welcome message")
    }

    func testFamilyActivityAction_AllCases() {
        let actions: [FamilyActivityAction] = [
            .memberJoined,
            .memberRemoved,
            .permissionsChanged,
            .portfolioShared,
            .portfolioUnshared,
            .goalCreated,
            .dcaScheduleCreated,
            .transactionRecorded
        ]
        XCTAssertEqual(actions.count, 8)
    }

    // MARK: - Edge Cases

    func testFamilyAccount_EmptyAccessiblePortfolioIds() {
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "John Doe",
            accessiblePortfolioIds: []
        )
        XCTAssertTrue(account.accessiblePortfolioIds.isEmpty)
    }

    func testFamilyAccount_ManyAccessiblePortfolioIds() {
        let portfolioIds = (0..<100).map { "portfolio-\($0)" }
        let account = FamilyAccount(
            primaryUserId: "user-123",
            name: "John Doe",
            accessiblePortfolioIds: portfolioIds
        )
        XCTAssertEqual(account.accessiblePortfolioIds.count, 100)
    }
}
