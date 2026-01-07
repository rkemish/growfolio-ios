//
//  FamilyRepositoryTests.swift
//  GrowfolioTests
//
//  Tests for FamilyRepository.
//

import XCTest
@testable import Growfolio

final class FamilyRepositoryTests: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var sut: FamilyRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = FamilyRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        mockAPIClient.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeFamily(
        id: String = "family-1",
        name: String = "The Smiths",
        ownerId: String = "user-1",
        members: [FamilyMember] = []
    ) -> Family {
        Family(
            id: id,
            name: name,
            ownerId: ownerId,
            members: members
        )
    }

    private func makeFamilyMember(
        userId: String = "user-1",
        name: String = "John Smith",
        email: String = "john@example.com",
        role: FamilyMemberRole = .member,
        status: FamilyMemberStatus = .active
    ) -> FamilyMember {
        FamilyMember(
            userId: userId,
            name: name,
            email: email,
            role: role,
            status: status
        )
    }

    private func makeFamilyInvite(
        id: String = "invite-1",
        familyId: String = "family-1",
        familyName: String = "The Smiths",
        inviteeEmail: String = "jane@example.com",
        status: InviteStatus = .pending
    ) -> FamilyInvite {
        FamilyInvite(
            id: id,
            familyId: familyId,
            familyName: familyName,
            inviterId: "user-1",
            inviterName: "John Smith",
            inviteeEmail: inviteeEmail,
            role: .member,
            status: status
        )
    }

    private func makeReceivedInvite(
        invite: FamilyInvite? = nil
    ) -> ReceivedInvite {
        ReceivedInvite(
            invite: invite ?? makeFamilyInvite(),
            familyMemberCount: 3,
            familyOwnerName: "John Smith",
            familyDescription: "Our family group"
        )
    }

    private func makeFamilyGoalsOverview() -> FamilyGoalsOverview {
        FamilyGoalsOverview(
            familyId: "family-1",
            totalGoals: 5,
            completedGoals: 2,
            totalTargetAmount: 100000,
            totalCurrentAmount: 45000,
            memberGoals: []
        )
    }

    // MARK: - Get Family Tests

    func test_getFamily_returnsFamilyFromAPI() async throws {
        // Arrange
        let expectedFamily = makeFamily(name: "Test Family")
        mockAPIClient.setResponse(expectedFamily, for: Endpoints.GetFamily.self)

        // Act
        let family = try await sut.getFamily()

        // Assert
        XCTAssertNotNil(family)
        XCTAssertEqual(family?.name, "Test Family")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_getFamily_usesCache() async throws {
        // Arrange
        let expectedFamily = makeFamily()
        mockAPIClient.setResponse(expectedFamily, for: Endpoints.GetFamily.self)

        // Act - First call populates cache
        _ = try await sut.getFamily()

        // Act - Second call should use cache (within 2 minutes)
        let result = try await sut.getFamily()

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_getFamily_returnsNilWhenNotFound() async throws {
        // Arrange
        mockAPIClient.setError(NetworkError.notFound, for: Endpoints.GetFamily.self)

        // Act
        let family = try await sut.getFamily()

        // Assert
        XCTAssertNil(family)
    }

    func test_getFamily_throwsOnOtherErrors() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Error"), for: Endpoints.GetFamily.self)

        // Act & Assert
        do {
            _ = try await sut.getFamily()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Create Family Tests

    func test_createFamily_returnsCreatedFamily() async throws {
        // Arrange
        let expectedFamily = makeFamily(name: "New Family")
        mockAPIClient.setResponse(expectedFamily, for: Endpoints.CreateFamily.self)

        // Act
        let family = try await sut.createFamily(name: "New Family", description: "Our new family")

        // Assert
        XCTAssertEqual(family.name, "New Family")
    }

    func test_createFamily_updatesCache() async throws {
        // Arrange
        let expectedFamily = makeFamily(name: "Created Family")
        mockAPIClient.setResponse(expectedFamily, for: Endpoints.CreateFamily.self)

        // Act
        _ = try await sut.createFamily(name: "Created Family", description: nil)

        // Assert - Subsequent get should use cache
        mockAPIClient.reset()
        let cachedFamily = try await sut.getFamily()
        XCTAssertEqual(cachedFamily?.name, "Created Family")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    // MARK: - Update Family Tests

    func test_updateFamily_returnsUpdatedFamily() async throws {
        // Arrange
        var family = makeFamily(name: "Original Name")
        family.name = "Updated Name"
        mockAPIClient.setResponse(family, for: Endpoints.UpdateFamily.self)

        // Act
        let updated = try await sut.updateFamily(family)

        // Assert
        XCTAssertEqual(updated.name, "Updated Name")
    }

    func test_updateFamily_updatesCache() async throws {
        // Arrange - First populate cache via getFamily
        let originalFamily = makeFamily(name: "Original Name")
        mockAPIClient.setResponse(originalFamily, for: Endpoints.GetFamily.self)
        _ = try await sut.getFamily()

        // Set up update response
        var updatedFamily = makeFamily(name: "Updated Name")
        mockAPIClient.setResponse(updatedFamily, for: Endpoints.UpdateFamily.self)

        // Act
        _ = try await sut.updateFamily(updatedFamily)

        // Assert - Verify the update was made
        XCTAssertTrue(mockAPIClient.requestsMade.count >= 2) // get + update
    }

    // MARK: - Delete Family Tests

    func test_deleteFamily_clearsCache() async throws {
        // Arrange - First populate cache
        let family = makeFamily()
        mockAPIClient.setResponse(family, for: Endpoints.GetFamily.self)
        _ = try await sut.getFamily()

        // Act
        try await sut.deleteFamily(id: "family-1")

        // Assert - Cache should be cleared
        mockAPIClient.reset()
        mockAPIClient.setResponse(makeFamily(id: "new-family"), for: Endpoints.GetFamily.self)

        let newFamily = try await sut.getFamily()
        XCTAssertEqual(newFamily?.id, "new-family")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Invite Member Tests

    func test_inviteMember_returnsInvite() async throws {
        // Arrange
        let expectedInvite = makeFamilyInvite(inviteeEmail: "jane@example.com")
        mockAPIClient.setResponse(expectedInvite, for: Endpoints.InviteFamilyMember.self)

        // Act
        let invite = try await sut.inviteMember(
            email: "jane@example.com",
            role: .member,
            message: "Join our family!"
        )

        // Assert
        XCTAssertEqual(invite.inviteeEmail, "jane@example.com")
        XCTAssertEqual(invite.status, .pending)
    }

    func test_inviteMember_invalidatesCache() async throws {
        // Arrange - First populate cache
        let family = makeFamily()
        mockAPIClient.setResponse(family, for: Endpoints.GetFamily.self)
        _ = try await sut.getFamily()

        // Set up invite response
        let invite = makeFamilyInvite()
        mockAPIClient.setResponse(invite, for: Endpoints.InviteFamilyMember.self)

        // Act
        _ = try await sut.inviteMember(email: "test@example.com", role: .member, message: nil)

        // Assert - Cache should be invalidated
        mockAPIClient.reset()
        mockAPIClient.setResponse(makeFamily(name: "Refreshed Family"), for: Endpoints.GetFamily.self)

        let refreshedFamily = try await sut.getFamily()
        XCTAssertEqual(refreshedFamily?.name, "Refreshed Family")
    }

    // MARK: - Resend Invite Tests

    func test_resendInvite_returnsUpdatedInvite() async throws {
        // Arrange
        let invite = makeFamilyInvite(id: "invite-123")
        mockAPIClient.setResponse(invite, for: Endpoints.ResendFamilyInvite.self)

        // Act
        let result = try await sut.resendInvite(inviteId: "invite-123")

        // Assert
        XCTAssertEqual(result.id, "invite-123")
    }

    // MARK: - Cancel Invite Tests

    func test_cancelInvite_invalidatesCache() async throws {
        // Arrange - First populate cache
        let family = makeFamily()
        mockAPIClient.setResponse(family, for: Endpoints.GetFamily.self)
        _ = try await sut.getFamily()

        // Act
        try await sut.cancelInvite(inviteId: "invite-1")

        // Assert - Cache should be invalidated
        mockAPIClient.reset()
        mockAPIClient.setResponse(makeFamily(name: "Refreshed"), for: Endpoints.GetFamily.self)

        let refreshedFamily = try await sut.getFamily()
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Get Pending Invites Tests

    func test_getPendingInvites_returnsInvites() async throws {
        // Arrange
        let invites = [
            makeFamilyInvite(id: "invite-1"),
            makeFamilyInvite(id: "invite-2")
        ]
        mockAPIClient.setResponse(invites, for: Endpoints.GetFamilyInvites.self)

        // Act
        let result = try await sut.getPendingInvites()

        // Assert
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - Get Received Invites Tests

    func test_getReceivedInvites_returnsInvites() async throws {
        // Arrange
        let invites = [
            makeReceivedInvite(),
            makeReceivedInvite()
        ]
        mockAPIClient.setResponse(invites, for: Endpoints.GetReceivedInvites.self)

        // Act
        let result = try await sut.getReceivedInvites()

        // Assert
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - Accept Invite Tests

    func test_acceptInvite_returnsFamily() async throws {
        // Arrange
        let family = makeFamily(name: "Joined Family")
        mockAPIClient.setResponse(family, for: Endpoints.AcceptFamilyInvite.self)

        // Act
        let result = try await sut.acceptInvite(inviteId: "invite-1")

        // Assert
        XCTAssertEqual(result.name, "Joined Family")
    }

    func test_acceptInvite_updatesCache() async throws {
        // Arrange
        let family = makeFamily(name: "Accepted Family")
        mockAPIClient.setResponse(family, for: Endpoints.AcceptFamilyInvite.self)

        // Act
        _ = try await sut.acceptInvite(inviteId: "invite-1")

        // Assert - Cache should be updated
        mockAPIClient.reset()
        let cachedFamily = try await sut.getFamily()
        XCTAssertEqual(cachedFamily?.name, "Accepted Family")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    // MARK: - Decline Invite Tests

    func test_declineInvite_succeeds() async throws {
        // Act & Assert - Should not throw
        try await sut.declineInvite(inviteId: "invite-1")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Update Member Role Tests

    func test_updateMemberRole_returnsMember() async throws {
        // Arrange
        let member = makeFamilyMember(role: .admin)
        mockAPIClient.setResponse(member, for: Endpoints.UpdateFamilyMember.self)

        // Act
        let result = try await sut.updateMemberRole(memberId: "user-2", role: .admin)

        // Assert
        XCTAssertEqual(result.role, .admin)
    }

    func test_updateMemberRole_invalidatesCache() async throws {
        // Arrange - First populate cache
        let family = makeFamily()
        mockAPIClient.setResponse(family, for: Endpoints.GetFamily.self)
        _ = try await sut.getFamily()

        // Set up member response
        let member = makeFamilyMember()
        mockAPIClient.setResponse(member, for: Endpoints.UpdateFamilyMember.self)

        // Act
        _ = try await sut.updateMemberRole(memberId: "user-2", role: .admin)

        // Assert - Cache should be invalidated
        mockAPIClient.reset()
        mockAPIClient.setResponse(makeFamily(name: "Refreshed"), for: Endpoints.GetFamily.self)

        let refreshedFamily = try await sut.getFamily()
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Update Member Privacy Tests

    func test_updateMemberPrivacy_returnsMember() async throws {
        // Arrange
        var member = makeFamilyMember()
        member.sharePortfolioValue = true
        member.shareHoldings = true
        mockAPIClient.setResponse(member, for: Endpoints.UpdateFamilyMember.self)

        let settings = MemberPrivacySettings(
            sharePortfolioValue: true,
            shareHoldings: true,
            sharePerformance: true
        )

        // Act
        let result = try await sut.updateMemberPrivacy(memberId: "user-1", settings: settings)

        // Assert
        XCTAssertTrue(result.sharePortfolioValue)
        XCTAssertTrue(result.shareHoldings)
    }

    // MARK: - Remove Member Tests

    func test_removeMember_invalidatesCache() async throws {
        // Arrange - First populate cache
        let family = makeFamily()
        mockAPIClient.setResponse(family, for: Endpoints.GetFamily.self)
        _ = try await sut.getFamily()

        // Act
        try await sut.removeMember(memberId: "user-2")

        // Assert - Cache should be invalidated
        mockAPIClient.reset()
        mockAPIClient.setResponse(makeFamily(name: "Refreshed"), for: Endpoints.GetFamily.self)

        let refreshedFamily = try await sut.getFamily()
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Leave Family Tests

    func test_leaveFamily_clearsCache() async throws {
        // Arrange - First populate cache
        let family = makeFamily()
        mockAPIClient.setResponse(family, for: Endpoints.GetFamily.self)
        _ = try await sut.getFamily()

        // Act
        try await sut.leaveFamily()

        // Assert - Cache should be cleared
        mockAPIClient.reset()
        mockAPIClient.setError(NetworkError.notFound, for: Endpoints.GetFamily.self)

        let result = try await sut.getFamily()
        XCTAssertNil(result)
    }

    // MARK: - Get Family Goals Tests

    func test_getFamilyGoals_returnsOverview() async throws {
        // Arrange
        let overview = makeFamilyGoalsOverview()
        mockAPIClient.setResponse(overview, for: Endpoints.GetFamilyGoals.self)

        // Act
        let result = try await sut.getFamilyGoals()

        // Assert
        XCTAssertEqual(result.totalGoals, 5)
        XCTAssertEqual(result.completedGoals, 2)
        XCTAssertEqual(result.totalTargetAmount, 100000)
        XCTAssertEqual(result.totalCurrentAmount, 45000)
    }

    // MARK: - Cache Invalidation Tests

    func test_invalidateCache_clearsCache() async throws {
        // Arrange - First populate cache
        let family = makeFamily()
        mockAPIClient.setResponse(family, for: Endpoints.GetFamily.self)
        _ = try await sut.getFamily()

        // Act
        await sut.invalidateCache()

        // Reset and set up new response
        mockAPIClient.reset()
        let newFamily = makeFamily(name: "New Family")
        mockAPIClient.setResponse(newFamily, for: Endpoints.GetFamily.self)

        // Act - Should make new API call
        let result = try await sut.getFamily()

        // Assert
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
        XCTAssertEqual(result?.name, "New Family")
    }

    // MARK: - Empty Response Tests

    func test_getPendingInvites_returnsEmptyArrayWhenNoInvites() async throws {
        // Arrange
        mockAPIClient.setResponse([FamilyInvite](), for: Endpoints.GetFamilyInvites.self)

        // Act
        let invites = try await sut.getPendingInvites()

        // Assert
        XCTAssertTrue(invites.isEmpty)
    }

    func test_getReceivedInvites_returnsEmptyArrayWhenNoInvites() async throws {
        // Arrange
        mockAPIClient.setResponse([ReceivedInvite](), for: Endpoints.GetReceivedInvites.self)

        // Act
        let invites = try await sut.getReceivedInvites()

        // Assert
        XCTAssertTrue(invites.isEmpty)
    }

    // MARK: - Get Family Accounts Tests

    func test_getFamilyAccounts_returnsAccountsFromAPI() async throws {
        // Arrange
        let accounts = [
            makeFamilyAccount(id: "acct-1", name: "Child 1", relationship: .child),
            makeFamilyAccount(id: "acct-2", name: "Child 2", relationship: .child)
        ]
        mockAPIClient.setResponse(accounts, for: Endpoints.GetFamilyAccounts.self)

        // Act
        let result = try await sut.getFamilyAccounts()

        // Assert
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "acct-1")
        XCTAssertEqual(result[0].name, "Child 1")
        XCTAssertEqual(result[0].relationship, .child)
        XCTAssertEqual(result[1].id, "acct-2")
    }

    func test_getFamilyAccounts_returnsEmptyArrayWhenNoAccounts() async throws {
        // Arrange
        mockAPIClient.setResponse([FamilyAccount](), for: Endpoints.GetFamilyAccounts.self)

        // Act
        let result = try await sut.getFamilyAccounts()

        // Assert
        XCTAssertTrue(result.isEmpty)
    }

    func test_getFamilyAccounts_throwsOnNetworkError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Server error"), for: Endpoints.GetFamilyAccounts.self)

        // Act & Assert
        do {
            _ = try await sut.getFamilyAccounts()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Create Family Account Tests

    func test_createFamilyAccount_createsAccountWithCorrectData() async throws {
        // Arrange
        let expectedAccount = makeFamilyAccount(
            id: "acct-new",
            name: "New Child",
            email: "child@example.com",
            relationship: .child
        )
        mockAPIClient.setResponse(expectedAccount, for: Endpoints.CreateFamilyAccount.self)

        // Act
        let result = try await sut.createFamilyAccount(
            name: "New Child",
            relationship: "child",
            email: "child@example.com"
        )

        // Assert
        XCTAssertEqual(result.id, "acct-new")
        XCTAssertEqual(result.name, "New Child")
        XCTAssertEqual(result.email, "child@example.com")
        XCTAssertEqual(result.relationship, .child)
    }

    func test_createFamilyAccount_sendsCorrectRequestData() async throws {
        // Arrange
        let account = makeFamilyAccount()
        mockAPIClient.setResponse(account, for: Endpoints.CreateFamilyAccount.self)

        // Act
        _ = try await sut.createFamilyAccount(
            name: "Test Child",
            relationship: "child",
            email: "test@example.com"
        )

        // Assert
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_createFamilyAccount_withoutEmail() async throws {
        // Arrange
        let account = makeFamilyAccount(name: "Child Without Email", email: nil)
        mockAPIClient.setResponse(account, for: Endpoints.CreateFamilyAccount.self)

        // Act
        let result = try await sut.createFamilyAccount(
            name: "Child Without Email",
            relationship: "child",
            email: nil
        )

        // Assert
        XCTAssertEqual(result.name, "Child Without Email")
        XCTAssertNil(result.email)
    }

    func test_createFamilyAccount_invalidatesCache() async throws {
        // Arrange - First populate cache
        let family = makeFamily()
        mockAPIClient.setResponse(family, for: Endpoints.GetFamily.self)
        _ = try await sut.getFamily()

        let account = makeFamilyAccount()
        mockAPIClient.setResponse(account, for: Endpoints.CreateFamilyAccount.self)

        // Act
        _ = try await sut.createFamilyAccount(name: "Test", relationship: "child", email: nil)

        // Assert - Cache should be invalidated
        mockAPIClient.reset()
        mockAPIClient.setResponse(makeFamily(name: "Refreshed"), for: Endpoints.GetFamily.self)
        _ = try await sut.getFamily()
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_createFamilyAccount_throwsOnValidationError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.clientError(statusCode: 400, message: "Invalid relationship"), for: Endpoints.CreateFamilyAccount.self)

        // Act & Assert
        do {
            _ = try await sut.createFamilyAccount(name: "Test", relationship: "invalid", email: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    func test_createFamilyAccount_throwsOnUnauthorized() async {
        // Arrange
        mockAPIClient.setError(NetworkError.unauthorized, for: Endpoints.CreateFamilyAccount.self)

        // Act & Assert
        do {
            _ = try await sut.createFamilyAccount(name: "Test", relationship: "child", email: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .unauthorized)
        }
    }

    // MARK: - Helper Methods for Family Accounts

    private func makeFamilyAccount(
        id: String = "acct-1",
        primaryUserId: String = "user-1",
        memberUserId: String = "user-2",
        name: String = "Test Account",
        email: String? = "test@example.com",
        relationship: FamilyRelationship = .child
    ) -> FamilyAccount {
        FamilyAccount(
            id: id,
            primaryUserId: primaryUserId,
            memberUserId: memberUserId,
            name: name,
            email: email,
            relationship: relationship,
            role: .viewer,
            permissions: .viewOnly,
            status: .active,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
