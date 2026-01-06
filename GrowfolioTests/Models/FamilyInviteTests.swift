//
//  FamilyInviteTests.swift
//  GrowfolioTests
//
//  Tests for FamilyInvite domain model.
//

import XCTest
@testable import Growfolio

final class FamilyInviteTests: XCTestCase {

    // MARK: - IsPending Tests

    func testIsPending_PendingStatus_ReturnsTrue() {
        let invite = TestFixtures.familyInvite(status: .pending)
        XCTAssertTrue(invite.isPending)
    }

    func testIsPending_AcceptedStatus_ReturnsFalse() {
        let invite = TestFixtures.familyInvite(status: .accepted)
        XCTAssertFalse(invite.isPending)
    }

    func testIsPending_DeclinedStatus_ReturnsFalse() {
        let invite = TestFixtures.familyInvite(status: .declined)
        XCTAssertFalse(invite.isPending)
    }

    func testIsPending_ExpiredStatus_ReturnsFalse() {
        let invite = TestFixtures.familyInvite(status: .expired)
        XCTAssertFalse(invite.isPending)
    }

    // MARK: - IsExpired Tests

    func testIsExpired_ExpiredStatus_ReturnsTrue() {
        let invite = TestFixtures.familyInvite(status: .expired)
        XCTAssertTrue(invite.isExpired)
    }

    func testIsExpired_PastExpirationDate_ReturnsTrue() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let invite = TestFixtures.familyInvite(
            status: .pending,
            createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            expiresAt: pastDate
        )
        XCTAssertTrue(invite.isExpired)
    }

    func testIsExpired_FutureExpirationDate_ReturnsFalse() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let invite = TestFixtures.familyInvite(
            status: .pending,
            expiresAt: futureDate
        )
        XCTAssertFalse(invite.isExpired)
    }

    func testIsExpired_PendingButDatePassed_ReturnsTrue() {
        let pastDate = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        let invite = TestFixtures.familyInvite(
            status: .pending,
            expiresAt: pastDate
        )
        XCTAssertTrue(invite.isExpired)
    }

    // MARK: - CanBeAccepted Tests

    func testCanBeAccepted_PendingAndNotExpired_ReturnsTrue() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let invite = TestFixtures.familyInvite(
            status: .pending,
            expiresAt: futureDate
        )
        XCTAssertTrue(invite.canBeAccepted)
    }

    func testCanBeAccepted_PendingButExpired_ReturnsFalse() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let invite = TestFixtures.familyInvite(
            status: .pending,
            expiresAt: pastDate
        )
        XCTAssertFalse(invite.canBeAccepted)
    }

    func testCanBeAccepted_AcceptedStatus_ReturnsFalse() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let invite = TestFixtures.familyInvite(
            status: .accepted,
            expiresAt: futureDate
        )
        XCTAssertFalse(invite.canBeAccepted)
    }

    func testCanBeAccepted_DeclinedStatus_ReturnsFalse() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let invite = TestFixtures.familyInvite(
            status: .declined,
            expiresAt: futureDate
        )
        XCTAssertFalse(invite.canBeAccepted)
    }

    // MARK: - TimeRemaining Tests

    func testTimeRemaining_FutureDate_ReturnsPositive() {
        let futureDate = Calendar.current.date(byAdding: .hour, value: 5, to: Date())!
        let invite = TestFixtures.familyInvite(expiresAt: futureDate)
        XCTAssertGreaterThan(invite.timeRemaining, 0)
    }

    func testTimeRemaining_PastDate_ReturnsZero() {
        let pastDate = Calendar.current.date(byAdding: .hour, value: -5, to: Date())!
        let invite = TestFixtures.familyInvite(expiresAt: pastDate)
        XCTAssertEqual(invite.timeRemaining, 0)
    }

    // MARK: - TimeRemainingString Tests

    func testTimeRemainingString_Expired_ReturnsExpired() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let invite = TestFixtures.familyInvite(expiresAt: pastDate)
        XCTAssertEqual(invite.timeRemainingString, "Expired")
    }

    func testTimeRemainingString_MultipleDays_ReturnsDaysLeft() {
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let invite = TestFixtures.familyInvite(expiresAt: futureDate)
        XCTAssertTrue(invite.timeRemainingString.contains("days left"))
    }

    func testTimeRemainingString_SingleDay_ReturnsDayLeft() {
        let futureDate = Calendar.current.date(byAdding: .hour, value: 30, to: Date())!
        let invite = TestFixtures.familyInvite(expiresAt: futureDate)
        XCTAssertTrue(invite.timeRemainingString.contains("day left"))
    }

    func testTimeRemainingString_Hours_ReturnsHoursLeft() {
        let futureDate = Calendar.current.date(byAdding: .hour, value: 5, to: Date())!
        let invite = TestFixtures.familyInvite(expiresAt: futureDate)
        XCTAssertTrue(invite.timeRemainingString.contains("hours left") || invite.timeRemainingString.contains("hour left"))
    }

    func testTimeRemainingString_LessThanOneHour_ReturnsLessThanHour() {
        let futureDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let invite = TestFixtures.familyInvite(expiresAt: futureDate)
        XCTAssertEqual(invite.timeRemainingString, "Less than an hour left")
    }

    // MARK: - ShareLink Tests

    func testShareLink_ValidInviteCode_ReturnsURL() {
        let invite = TestFixtures.familyInvite(inviteCode: "ABC12345")
        XCTAssertNotNil(invite.shareLink)
        XCTAssertEqual(invite.shareLink?.absoluteString, "growfolio://family/invite/ABC12345")
    }

    // MARK: - ShareText Tests

    func testShareText_WithMessage_IncludesMessage() {
        let invite = TestFixtures.familyInvite(
            familyName: "Smith Family",
            inviterName: "John Smith",
            inviteCode: "ABC12345",
            message: "Please join us!"
        )
        XCTAssertTrue(invite.shareText.contains("John Smith"))
        XCTAssertTrue(invite.shareText.contains("Smith Family"))
        XCTAssertTrue(invite.shareText.contains("ABC12345"))
        XCTAssertTrue(invite.shareText.contains("Please join us!"))
    }

    func testShareText_NoMessage_ExcludesMessageQuotes() {
        let invite = TestFixtures.familyInvite(
            familyName: "Smith Family",
            inviterName: "John Smith",
            inviteCode: "ABC12345",
            message: nil
        )
        XCTAssertTrue(invite.shareText.contains("John Smith"))
        XCTAssertTrue(invite.shareText.contains("Smith Family"))
        XCTAssertTrue(invite.shareText.contains("ABC12345"))
        XCTAssertFalse(invite.shareText.contains("\"\""))
    }

    func testShareText_EmptyMessage_ExcludesMessageQuotes() {
        let invite = TestFixtures.familyInvite(
            familyName: "Smith Family",
            inviterName: "John Smith",
            inviteCode: "ABC12345",
            message: ""
        )
        XCTAssertFalse(invite.shareText.contains("\"\""))
    }

    // MARK: - InviteStatus Tests

    func testInviteStatus_DisplayName() {
        XCTAssertEqual(InviteStatus.pending.displayName, "Pending")
        XCTAssertEqual(InviteStatus.accepted.displayName, "Accepted")
        XCTAssertEqual(InviteStatus.declined.displayName, "Declined")
        XCTAssertEqual(InviteStatus.expired.displayName, "Expired")
    }

    func testInviteStatus_IconName() {
        XCTAssertFalse(InviteStatus.pending.iconName.isEmpty)
        XCTAssertFalse(InviteStatus.accepted.iconName.isEmpty)
        XCTAssertFalse(InviteStatus.declined.iconName.isEmpty)
        XCTAssertFalse(InviteStatus.expired.iconName.isEmpty)
    }

    func testInviteStatus_ColorHex() {
        XCTAssertEqual(InviteStatus.pending.colorHex, "#FF9500")
        XCTAssertEqual(InviteStatus.accepted.colorHex, "#34C759")
        XCTAssertEqual(InviteStatus.declined.colorHex, "#FF3B30")
        XCTAssertEqual(InviteStatus.expired.colorHex, "#8E8E93")
    }

    func testInviteStatus_AllCases() {
        XCTAssertEqual(InviteStatus.allCases.count, 4)
    }

    // MARK: - Codable Tests

    func testFamilyInvite_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.familyInvite(
            familyId: "family-456",
            familyName: "Test Family",
            inviterId: "user-123",
            inviterName: "John Doe",
            inviteeEmail: "jane@example.com",
            role: .member,
            status: .pending,
            inviteCode: "ABCD1234",
            message: "Join our family!"
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(FamilyInvite.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.familyId, original.familyId)
        XCTAssertEqual(decoded.familyName, original.familyName)
        XCTAssertEqual(decoded.inviterId, original.inviterId)
        XCTAssertEqual(decoded.inviterName, original.inviterName)
        XCTAssertEqual(decoded.inviteeEmail, original.inviteeEmail)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.inviteCode, original.inviteCode)
        XCTAssertEqual(decoded.message, original.message)
    }

    func testFamilyInvite_EncodeDecode_NilMessage() throws {
        let original = TestFixtures.familyInvite(message: nil)

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(FamilyInvite.self, from: data)

        XCTAssertNil(decoded.message)
    }

    func testFamilyInvite_EncodeDecode_NilInviteeUserId() throws {
        let original = TestFixtures.familyInvite(inviteeUserId: nil)

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(FamilyInvite.self, from: data)

        XCTAssertNil(decoded.inviteeUserId)
    }

    func testInviteStatus_Codable() throws {
        for status in InviteStatus.allCases {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(InviteStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - Equatable Tests

    func testFamilyInvite_Equatable_SameId() {
        let invite1 = TestFixtures.familyInvite(id: "inv1")
        let invite2 = TestFixtures.familyInvite(id: "inv1")
        XCTAssertEqual(invite1, invite2)
    }

    func testFamilyInvite_Equatable_DifferentId() {
        let invite1 = TestFixtures.familyInvite(id: "inv1")
        let invite2 = TestFixtures.familyInvite(id: "inv2")
        XCTAssertNotEqual(invite1, invite2)
    }

    // MARK: - Hashable Tests

    func testFamilyInvite_Hashable() {
        let invite1 = TestFixtures.familyInvite(id: "inv1")
        let invite2 = TestFixtures.familyInvite(id: "inv2")

        var set = Set<FamilyInvite>()
        set.insert(invite1)
        set.insert(invite2)

        XCTAssertEqual(set.count, 2)
    }

    func testFamilyInvite_Hashable_SameIdNotDuplicated() {
        // Note: FamilyInvite uses synthesized Equatable/Hashable which compares ALL properties.
        // Two invites with the same ID but different names are NOT considered equal/duplicate.
        // This test verifies that invites with identical properties are deduplicated.
        let invite1 = TestFixtures.familyInvite(id: "inv1", familyName: "Family 1")
        let invite2 = TestFixtures.familyInvite(id: "inv1", familyName: "Family 1")

        var set = Set<FamilyInvite>()
        set.insert(invite1)
        set.insert(invite2)

        XCTAssertEqual(set.count, 1)
    }

    // MARK: - CreateInviteRequest Tests

    func testCreateInviteRequest_DefaultValues() {
        let request = CreateInviteRequest(email: "test@example.com")
        XCTAssertEqual(request.email, "test@example.com")
        XCTAssertEqual(request.role, .member)
        XCTAssertNil(request.message)
    }

    func testCreateInviteRequest_CustomValues() {
        let request = CreateInviteRequest(
            email: "test@example.com",
            role: .admin,
            message: "Welcome!"
        )
        XCTAssertEqual(request.email, "test@example.com")
        XCTAssertEqual(request.role, .admin)
        XCTAssertEqual(request.message, "Welcome!")
    }

    // MARK: - InviteResponse Tests

    func testInviteResponse_Accepted() {
        let response = InviteResponse(inviteId: "inv-123", accepted: true)
        XCTAssertEqual(response.inviteId, "inv-123")
        XCTAssertTrue(response.accepted)
    }

    func testInviteResponse_Declined() {
        let response = InviteResponse(inviteId: "inv-123", accepted: false)
        XCTAssertEqual(response.inviteId, "inv-123")
        XCTAssertFalse(response.accepted)
    }

    // MARK: - ReceivedInvite Tests

    func testReceivedInvite_Id() {
        let invite = TestFixtures.familyInvite(id: "inv-123")
        let received = ReceivedInvite(
            invite: invite,
            familyMemberCount: 5,
            familyOwnerName: "John",
            familyDescription: "A great family"
        )
        XCTAssertEqual(received.id, "inv-123")
    }

    func testReceivedInvite_SummaryText_SingleMember() {
        let invite = TestFixtures.familyInvite()
        let received = ReceivedInvite(
            invite: invite,
            familyMemberCount: 1,
            familyOwnerName: "John",
            familyDescription: nil
        )
        XCTAssertEqual(received.summaryText, "1 member")
    }

    func testReceivedInvite_SummaryText_MultipleMembers() {
        let invite = TestFixtures.familyInvite()
        let received = ReceivedInvite(
            invite: invite,
            familyMemberCount: 5,
            familyOwnerName: "John",
            familyDescription: nil
        )
        XCTAssertEqual(received.summaryText, "5 members")
    }

    // MARK: - Edge Cases

    func testFamilyInvite_EmptyInviteCode() {
        let invite = TestFixtures.familyInvite(inviteCode: "")
        XCTAssertEqual(invite.inviteCode, "")
        XCTAssertNotNil(invite.shareLink)
    }

    func testFamilyInvite_RespondedAtSet() {
        let respondedDate = Date()
        let invite = TestFixtures.familyInvite(
            status: .accepted,
            respondedAt: respondedDate
        )
        XCTAssertNotNil(invite.respondedAt)
    }
}
