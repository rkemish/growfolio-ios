//
//  UserRepositoryTests.swift
//  GrowfolioTests
//
//  Tests for UserRepository.
//

import XCTest
@testable import Growfolio

final class UserRepositoryTests: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var sut: UserRepository!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        sut = UserRepository(apiClient: mockAPIClient)
    }

    override func tearDown() {
        mockAPIClient.reset()
        sut = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeUserDTO(
        id: String = "user-123",
        email: String = "test@example.com",
        name: String = "Test User",
        isVerified: Bool = true,
        alpacaAccountId: String? = "alpaca-123"
    ) -> UserDTO {
        UserDTO(
            id: id,
            email: email,
            name: name,
            firstName: "Test",
            lastName: "User",
            pictureUrl: "https://example.com/picture.jpg",
            isVerified: isVerified,
            alpacaAccountId: alpacaAccountId,
            alpacaAccountStatus: "ACTIVE",
            familyId: nil,
            preferences: makeUserPreferencesDTO(),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    private func makeUserPreferencesDTO(
        defaultCurrency: String = "USD",
        notificationsEnabled: Bool = true,
        theme: String = "system",
        biometricEnabled: Bool = false
    ) -> UserPreferencesDTO {
        UserPreferencesDTO(
            defaultCurrency: defaultCurrency,
            notificationsEnabled: notificationsEnabled,
            emailNotifications: true,
            dcaNotifications: true,
            weeklySummary: true,
            theme: theme,
            biometricEnabled: biometricEnabled
        )
    }

    private func makeUser(
        id: String = "user-123",
        email: String = "test@example.com",
        displayName: String? = "Test User"
    ) -> User {
        User(
            id: id,
            email: email,
            displayName: displayName
        )
    }

    private func makeUserSettings(
        preferredCurrency: String = "USD",
        notificationsEnabled: Bool = true,
        theme: AppTheme = .system
    ) -> UserSettings {
        UserSettings(
            preferredCurrency: preferredCurrency,
            notificationsEnabled: notificationsEnabled,
            biometricEnabled: false,
            timezoneIdentifier: TimeZone.current.identifier,
            theme: theme,
            hapticFeedbackEnabled: true,
            showBalances: true
        )
    }

    // MARK: - Fetch Current User Tests

    func test_fetchCurrentUser_returnsUserFromAPI() async throws {
        // Arrange
        let userDTO = makeUserDTO(email: "john@example.com", name: "John Doe")
        mockAPIClient.setResponse(userDTO, for: Endpoints.GetCurrentUser.self)

        // Act
        let user = try await sut.fetchCurrentUser()

        // Assert
        XCTAssertEqual(user.id, "user-123")
        XCTAssertEqual(user.email, "john@example.com")
        XCTAssertEqual(user.displayName, "John Doe")
    }

    func test_fetchCurrentUser_usesCache() async throws {
        // Arrange
        let userDTO = makeUserDTO()
        mockAPIClient.setResponse(userDTO, for: Endpoints.GetCurrentUser.self)

        // Act - First call populates cache
        _ = try await sut.fetchCurrentUser()

        // Act - Second call should use cache (within 5 minutes)
        let result = try await sut.fetchCurrentUser()

        // Assert
        XCTAssertEqual(result.id, "user-123")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_fetchCurrentUser_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.unauthorized, for: Endpoints.GetCurrentUser.self)

        // Act & Assert
        do {
            _ = try await sut.fetchCurrentUser()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .unauthorized)
        }
    }

    func test_fetchCurrentUser_setsPremiumTierForAlpacaAccount() async throws {
        // Arrange
        let userDTO = makeUserDTO(alpacaAccountId: "alpaca-123")
        mockAPIClient.setResponse(userDTO, for: Endpoints.GetCurrentUser.self)

        // Act
        let user = try await sut.fetchCurrentUser()

        // Assert
        XCTAssertEqual(user.subscriptionTier, .premium)
    }

    func test_fetchCurrentUser_setsFreeTierWithoutAlpacaAccount() async throws {
        // Arrange
        let userDTO = makeUserDTO(alpacaAccountId: nil)
        mockAPIClient.setResponse(userDTO, for: Endpoints.GetCurrentUser.self)

        // Act
        let user = try await sut.fetchCurrentUser()

        // Assert
        XCTAssertEqual(user.subscriptionTier, .free)
    }

    // MARK: - Update Profile Tests

    func test_updateProfile_returnsUpdatedUser() async throws {
        // Arrange
        let updatedDTO = makeUserDTO(name: "Updated Name")
        mockAPIClient.setResponse(updatedDTO, for: Endpoints.UpdateUser.self)

        // Act
        let user = try await sut.updateProfile(displayName: "Updated Name")

        // Assert
        XCTAssertEqual(user.displayName, "Updated Name")
    }

    func test_updateProfile_updatesCache() async throws {
        // Arrange
        let updatedDTO = makeUserDTO(name: "New Name")
        mockAPIClient.setResponse(updatedDTO, for: Endpoints.UpdateUser.self)

        // Act
        _ = try await sut.updateProfile(displayName: "New Name")

        // Assert - Subsequent fetch should use cache
        mockAPIClient.reset()
        let cachedUser = try await sut.fetchCurrentUser()
        XCTAssertEqual(cachedUser.displayName, "New Name")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 0)
    }

    func test_updateProfile_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Error"), for: Endpoints.UpdateUser.self)

        // Act & Assert
        do {
            _ = try await sut.updateProfile(displayName: "Test")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Fetch Preferences Tests

    func test_fetchPreferences_returnsSettings() async throws {
        // Arrange
        let preferencesDTO = makeUserPreferencesDTO(
            defaultCurrency: "GBP",
            theme: "dark"
        )
        mockAPIClient.setResponse(preferencesDTO, for: Endpoints.GetPreferences.self)

        // Act
        let settings = try await sut.fetchPreferences()

        // Assert
        XCTAssertEqual(settings.preferredCurrency, "GBP")
        XCTAssertEqual(settings.theme, .dark)
    }

    func test_fetchPreferences_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Error"), for: Endpoints.GetPreferences.self)

        // Act & Assert
        do {
            _ = try await sut.fetchPreferences()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Update Preferences Tests

    func test_updatePreferences_returnsUpdatedSettings() async throws {
        // Arrange
        let updatedPreferencesDTO = makeUserPreferencesDTO(
            defaultCurrency: "EUR",
            notificationsEnabled: false
        )
        mockAPIClient.setResponse(updatedPreferencesDTO, for: Endpoints.UpdatePreferences.self)

        let update = UserPreferencesUpdate(
            defaultCurrency: "EUR",
            notificationsEnabled: false
        )

        // Act
        let settings = try await sut.updatePreferences(update)

        // Assert
        XCTAssertEqual(settings.preferredCurrency, "EUR")
        XCTAssertFalse(settings.notificationsEnabled)
    }

    func test_updatePreferences_invalidatesUserCache() async throws {
        // Arrange - First populate cache
        let userDTO = makeUserDTO()
        mockAPIClient.setResponse(userDTO, for: Endpoints.GetCurrentUser.self)
        _ = try await sut.fetchCurrentUser()

        // Set up preferences update
        let preferencesDTO = makeUserPreferencesDTO()
        mockAPIClient.setResponse(preferencesDTO, for: Endpoints.UpdatePreferences.self)

        // Act
        _ = try await sut.updatePreferences(UserPreferencesUpdate())

        // Assert - Cache should be invalidated
        mockAPIClient.reset()
        let newUserDTO = makeUserDTO(name: "Refreshed User")
        mockAPIClient.setResponse(newUserDTO, for: Endpoints.GetCurrentUser.self)

        let refreshedUser = try await sut.fetchCurrentUser()
        XCTAssertEqual(refreshedUser.displayName, "Refreshed User")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    // MARK: - Register Device Token Tests

    func test_registerDeviceToken_succeeds() async throws {
        // Act & Assert - Should not throw
        try await sut.registerDeviceToken("device-token-123")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_registerDeviceToken_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.serverError(statusCode: 500, message: "Error"), for: Endpoints.RegisterDevice.self)

        // Act & Assert
        do {
            try await sut.registerDeviceToken("token")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Delete Account Tests

    func test_deleteAccount_invalidatesCache() async throws {
        // Arrange - First populate cache
        let userDTO = makeUserDTO()
        mockAPIClient.setResponse(userDTO, for: Endpoints.GetCurrentUser.self)
        _ = try await sut.fetchCurrentUser()

        // Act
        try await sut.deleteAccount()

        // Assert - Cache should be invalidated
        mockAPIClient.reset()
        let newUserDTO = makeUserDTO(id: "new-user")
        mockAPIClient.setResponse(newUserDTO, for: Endpoints.GetCurrentUser.self)

        let newUser = try await sut.fetchCurrentUser()
        XCTAssertEqual(newUser.id, "new-user")
        XCTAssertEqual(mockAPIClient.requestsMade.count, 1)
    }

    func test_deleteAccount_throwsOnError() async {
        // Arrange
        mockAPIClient.setError(NetworkError.forbidden, for: Endpoints.DeleteUser.self)

        // Act & Assert
        do {
            try await sut.deleteAccount()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NetworkError, .forbidden)
        }
    }

    // MARK: - UserDTO Conversion Tests

    func test_userDTO_toDomain_convertsCorrectly() {
        // Arrange
        let dto = makeUserDTO(
            id: "test-id",
            email: "test@example.com",
            name: "Test User"
        )

        // Act
        let user = dto.toDomain()

        // Assert
        XCTAssertEqual(user.id, "test-id")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.displayName, "Test User")
    }

    func test_userDTO_toDomain_handlesEmptyName() {
        // Arrange
        let dto = UserDTO(
            id: "user-1",
            email: "test@example.com",
            name: "",
            firstName: nil,
            lastName: nil,
            pictureUrl: nil,
            isVerified: true,
            alpacaAccountId: nil,
            alpacaAccountStatus: nil,
            familyId: nil,
            preferences: makeUserPreferencesDTO(),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )

        // Act
        let user = dto.toDomain()

        // Assert
        XCTAssertNil(user.displayName)
    }

    func test_userPreferencesDTO_toSettings_convertsCorrectly() {
        // Arrange
        let dto = makeUserPreferencesDTO(
            defaultCurrency: "GBP",
            notificationsEnabled: true,
            theme: "dark",
            biometricEnabled: true
        )

        // Act
        let settings = dto.toSettings()

        // Assert
        XCTAssertEqual(settings.preferredCurrency, "GBP")
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertEqual(settings.theme, .dark)
        XCTAssertTrue(settings.biometricEnabled)
    }

    func test_userPreferencesDTO_toSettings_defaultsUnknownThemeToSystem() {
        // Arrange
        let dto = UserPreferencesDTO(
            defaultCurrency: "USD",
            notificationsEnabled: true,
            emailNotifications: true,
            dcaNotifications: true,
            weeklySummary: true,
            theme: "unknown",
            biometricEnabled: false
        )

        // Act
        let settings = dto.toSettings()

        // Assert
        XCTAssertEqual(settings.theme, .system)
    }

    func test_userPreferencesDTO_toNotificationSettings_convertsCorrectly() {
        // Arrange
        let dto = makeUserPreferencesDTO()

        // Act
        let notificationSettings = dto.toNotificationSettings()

        // Assert
        XCTAssertTrue(notificationSettings.dcaReminders)
        XCTAssertTrue(notificationSettings.weeklyDigest)
    }

    // MARK: - UserPreferencesUpdate Tests

    func test_userPreferencesUpdate_fromSettings_convertsCorrectly() {
        // Arrange
        let settings = makeUserSettings(
            preferredCurrency: "EUR",
            notificationsEnabled: false,
            theme: .dark
        )
        let notifications = NotificationSettings(
            dcaReminders: true,
            goalProgress: true,
            portfolioAlerts: true,
            marketNews: false,
            aiInsights: true,
            weeklyDigest: false
        )

        // Act
        let update = UserPreferencesUpdate.from(settings: settings, notifications: notifications)

        // Assert
        XCTAssertEqual(update.defaultCurrency, "EUR")
        XCTAssertEqual(update.notificationsEnabled, false)
        XCTAssertEqual(update.theme, "dark")
        XCTAssertEqual(update.dcaNotifications, true)
        XCTAssertEqual(update.weeklySummary, false)
    }

    // MARK: - Concurrent Access Tests

    func test_fetchCurrentUser_handlesConcurrentAccess() async throws {
        // Arrange
        let userDTO = makeUserDTO()
        mockAPIClient.setResponse(userDTO, for: Endpoints.GetCurrentUser.self)

        // Capture repository locally to avoid data races in concurrent closures
        let repository = self.sut!

        // Act - Make multiple concurrent requests
        async let user1 = repository.fetchCurrentUser()
        async let user2 = repository.fetchCurrentUser()
        async let user3 = repository.fetchCurrentUser()

        let results = try await [user1, user2, user3]

        // Assert - All should return the same user
        XCTAssertEqual(results[0].id, results[1].id)
        XCTAssertEqual(results[1].id, results[2].id)
    }
}
