//
//  SettingsViewModelTests.swift
//  GrowfolioTests
//
//  Tests for SettingsViewModel - user preferences, theme, notifications, and account actions.
//

import XCTest
@testable import Growfolio

@MainActor
final class SettingsViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockUserRepository: MockUserRepository!
    var sut: SettingsViewModel!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockUserRepository = MockUserRepository()
        // Note: AuthService.shared is used by default - we test without logout functionality
        sut = SettingsViewModel(userRepository: mockUserRepository)
    }

    override func tearDown() {
        mockUserRepository = nil
        sut = nil
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.preferredCurrency)
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.selectedTheme)
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.biometricEnabled)
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isSaving)
        XCTAssertNil(sut.error)
        XCTAssertNil(sut.user)
    }

    func test_initialState_sheetPresentationStates() {
        XCTAssertFalse(sut.showEditProfile)
        XCTAssertFalse(sut.showCurrencyPicker)
        XCTAssertFalse(sut.showThemePicker)
        XCTAssertFalse(sut.showNotificationSettings)
        XCTAssertFalse(sut.showAbout)
        XCTAssertFalse(sut.showDeleteAccountConfirmation)
        XCTAssertFalse(sut.showSignOutConfirmation)
    }

    func test_initialState_appInfo() {
        XCTAssertEqual(sut.appVersion, Constants.App.version)
        XCTAssertEqual(sut.buildNumber, Constants.App.buildNumber)
    }

    // MARK: - Computed Properties Tests - Without User

    func test_displayName_returnsUserWhenNoUser() {
        XCTAssertEqual(sut.displayName, "User")
    }

    func test_email_returnsEmptyWhenNoUser() {
        XCTAssertEqual(sut.email, "")
    }

    func test_initials_returnsQuestionMarkWhenNoUser() {
        XCTAssertEqual(sut.initials, "?")
    }

    func test_subscriptionTier_returnsFreeWhenNoUser() {
        XCTAssertEqual(sut.subscriptionTier, .free)
    }

    func test_isPremium_returnsFalseWhenNoUser() {
        XCTAssertFalse(sut.isPremium)
    }

    func test_memberSince_returnsUnknownWhenNoUser() {
        XCTAssertEqual(sut.memberSince, "Unknown")
    }

    // MARK: - Computed Properties Tests - With User

    func test_displayName_returnsUserDisplayName() async {
        let user = SettingsViewModelTests.sampleUser(displayName: "John Doe")
        mockUserRepository.userToReturn = user

        await sut.loadUserData()

        XCTAssertEqual(sut.displayName, "John Doe")
    }

    func test_displayName_returnsEmailWhenNoDisplayName() async {
        let user = SettingsViewModelTests.sampleUser(displayName: nil)
        mockUserRepository.userToReturn = user

        await sut.loadUserData()

        XCTAssertEqual(sut.displayName, "test@example.com")
    }

    func test_email_returnsUserEmail() async {
        let user = SettingsViewModelTests.sampleUser(email: "john@example.com")
        mockUserRepository.userToReturn = user

        await sut.loadUserData()

        XCTAssertEqual(sut.email, "john@example.com")
    }

    func test_initials_calculatesFromDisplayName() async {
        let user = SettingsViewModelTests.sampleUser(displayName: "John Doe")
        mockUserRepository.userToReturn = user

        await sut.loadUserData()

        XCTAssertEqual(sut.initials, "JD")
    }

    func test_subscriptionTier_returnsUserSubscription() async {
        let user = SettingsViewModelTests.sampleUser(subscriptionTier: .premium)
        mockUserRepository.userToReturn = user

        await sut.loadUserData()

        XCTAssertEqual(sut.subscriptionTier, .premium)
    }

    func test_isPremium_returnsTrueForPremiumUser() async {
        let user = SettingsViewModelTests.sampleUser(subscriptionTier: .premium)
        mockUserRepository.userToReturn = user

        await sut.loadUserData()

        XCTAssertTrue(sut.isPremium)
    }

    func test_isPremium_returnsFalseForFreeUser() async {
        let user = SettingsViewModelTests.sampleUser(subscriptionTier: .free)
        mockUserRepository.userToReturn = user

        await sut.loadUserData()

        XCTAssertFalse(sut.isPremium)
    }

    // MARK: - Load User Data Tests

    func test_loadUserData_setsIsLoading() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()

        await sut.loadUserData()

        // isLoading should be false after completion
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadUserData_fetchesCurrentUser() async {
        let user = SettingsViewModelTests.sampleUser()
        mockUserRepository.userToReturn = user

        await sut.loadUserData()

        XCTAssertTrue(mockUserRepository.fetchCurrentUserCalled)
        XCTAssertEqual(sut.user?.id, user.id)
    }

    func test_loadUserData_doesNotFetchIfAlreadyLoading() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        sut.isLoading = true

        await sut.loadUserData()

        XCTAssertFalse(mockUserRepository.fetchCurrentUserCalled)
    }

    func test_loadUserData_setsErrorOnFailure() async {
        mockUserRepository.errorToThrow = NetworkError.noConnection

        await sut.loadUserData()

        XCTAssertNotNil(sut.error)
    }

    func test_loadUserData_loadsLocalSettingsOnError() async {
        mockUserRepository.errorToThrow = NetworkError.noConnection

        await sut.loadUserData()

        // Settings should still be loaded from local storage
        XCTAssertNotNil(sut.settings)
    }

    func test_loadUserData_clearsErrorBeforeLoading() async {
        sut.error = NetworkError.noConnection
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()

        await sut.loadUserData()

        XCTAssertNil(sut.error)
    }

    // MARK: - Settings Update Tests

    func test_updateCurrency_updatesLocalSettings() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.updateCurrency("EUR")

        XCTAssertEqual(sut.settings.preferredCurrency, "EUR")
    }

    func test_updateCurrency_savesToUserDefaults() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.updateCurrency("GBP")

        let savedCurrency = UserDefaults.standard.string(forKey: Constants.StorageKeys.preferredCurrency)
        XCTAssertEqual(savedCurrency, "GBP")
    }

    func test_updateCurrency_callsRepository() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.updateCurrency("CAD")

        XCTAssertTrue(mockUserRepository.updatePreferencesCalled)
        XCTAssertEqual(mockUserRepository.lastUpdatedPreferences?.defaultCurrency, "CAD")
    }

    func test_updateTheme_updatesLocalSettings() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.updateTheme(.dark)

        XCTAssertEqual(sut.settings.theme, .dark)
    }

    func test_updateTheme_savesToUserDefaults() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.updateTheme(.light)

        let savedTheme = UserDefaults.standard.string(forKey: Constants.StorageKeys.selectedTheme)
        XCTAssertEqual(savedTheme, "light")
    }

    func test_toggleNotifications_updatesSettings() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.toggleNotifications(false)

        XCTAssertFalse(sut.settings.notificationsEnabled)
    }

    func test_toggleNotifications_callsRepository() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.toggleNotifications(true)

        XCTAssertTrue(mockUserRepository.updatePreferencesCalled)
        XCTAssertEqual(mockUserRepository.lastUpdatedPreferences?.notificationsEnabled, true)
    }

    func test_toggleBiometric_updatesSettings() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.toggleBiometric(true)

        XCTAssertTrue(sut.settings.biometricEnabled)
    }

    func test_toggleBiometric_savesToUserDefaults() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.toggleBiometric(true)

        let savedBiometric = UserDefaults.standard.bool(forKey: Constants.StorageKeys.biometricEnabled)
        XCTAssertTrue(savedBiometric)
    }

    func test_toggleBiometric_callsRepository() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.toggleBiometric(true)

        XCTAssertTrue(mockUserRepository.updatePreferencesCalled)
        XCTAssertEqual(mockUserRepository.lastUpdatedPreferences?.biometricEnabled, true)
    }

    func test_updateNotificationSettings_updatesLocalSettings() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        let newSettings = NotificationSettings(
            dcaReminders: false,
            goalProgress: true,
            portfolioAlerts: false,
            marketNews: true,
            aiInsights: false,
            weeklyDigest: true
        )

        await sut.updateNotificationSettings(newSettings)

        XCTAssertFalse(sut.notificationSettings.dcaReminders)
        XCTAssertTrue(sut.notificationSettings.goalProgress)
        XCTAssertFalse(sut.notificationSettings.portfolioAlerts)
        XCTAssertTrue(sut.notificationSettings.marketNews)
    }

    // MARK: - Profile Update Tests

    func test_updateDisplayName_callsRepository() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.updateDisplayName("New Name")

        XCTAssertTrue(mockUserRepository.updateProfileCalled)
        XCTAssertEqual(mockUserRepository.lastUpdatedDisplayName, "New Name")
    }

    func test_updateDisplayName_setsIsSaving() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.updateDisplayName("Updated Name")

        // isSaving should be false after completion
        XCTAssertFalse(sut.isSaving)
    }

    func test_updateDisplayName_updatesUser() async {
        let originalUser = SettingsViewModelTests.sampleUser(displayName: "Original Name")
        mockUserRepository.userToReturn = originalUser
        await sut.loadUserData()

        let updatedUser = SettingsViewModelTests.sampleUser(displayName: "Updated Name")
        mockUserRepository.userToReturn = updatedUser

        await sut.updateDisplayName("Updated Name")

        XCTAssertEqual(sut.user?.displayName, "Updated Name")
    }

    func test_updateDisplayName_setsErrorOnFailure() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        mockUserRepository.errorToThrow = NetworkError.serverError(statusCode: 500, message: nil)

        await sut.updateDisplayName("New Name")

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Delete Account Tests

    func test_deleteAccount_callsRepository() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.deleteAccount()

        XCTAssertTrue(mockUserRepository.deleteAccountCalled)
    }

    func test_deleteAccount_setsErrorOnFailure() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        mockUserRepository.errorToThrow = NetworkError.serverError(statusCode: 500, message: nil)

        await sut.deleteAccount()

        XCTAssertNotNil(sut.error)
    }

    // MARK: - Available Currencies Tests

    func test_availableCurrencies_containsExpectedCurrencies() {
        let currencies = SettingsViewModel.availableCurrencies

        XCTAssertFalse(currencies.isEmpty)

        let codes = currencies.map { $0.code }
        XCTAssertTrue(codes.contains("USD"))
        XCTAssertTrue(codes.contains("EUR"))
        XCTAssertTrue(codes.contains("GBP"))
        XCTAssertTrue(codes.contains("CAD"))
        XCTAssertTrue(codes.contains("AUD"))
    }

    func test_availableCurrencies_haveSymbols() {
        let currencies = SettingsViewModel.availableCurrencies

        for currency in currencies {
            XCTAssertFalse(currency.symbol.isEmpty, "Currency \(currency.code) should have a symbol")
            XCTAssertFalse(currency.name.isEmpty, "Currency \(currency.code) should have a name")
        }
    }

    // MARK: - Settings Persistence Tests

    func test_settingsArePersisted_acrossViewModelInstances() async {
        // First ViewModel instance
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()
        await sut.updateCurrency("CHF")
        await sut.updateTheme(.dark)

        // Create a new ViewModel instance
        let newSut = SettingsViewModel(userRepository: mockUserRepository)
        await newSut.loadUserData()

        // Verify settings are loaded from UserDefaults
        XCTAssertEqual(newSut.settings.preferredCurrency, "CHF")
        XCTAssertEqual(newSut.settings.theme, .dark)
    }

    // MARK: - Error Handling Tests

    func test_saveSettings_setsErrorOnFailure() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        mockUserRepository.errorToThrow = NetworkError.noConnection

        await sut.toggleNotifications(false)

        XCTAssertNotNil(sut.error)
    }

    func test_saveSettings_setsIsSaving() async {
        mockUserRepository.userToReturn = SettingsViewModelTests.sampleUser()
        await sut.loadUserData()

        await sut.toggleNotifications(true)

        // isSaving should be false after completion
        XCTAssertFalse(sut.isSaving)
    }

    // MARK: - Helpers

    static func sampleUser(
        id: String = "user-1",
        email: String = "test@example.com",
        displayName: String? = "Test User",
        subscriptionTier: SubscriptionTier = .free
    ) -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            preferredCurrency: "USD",
            notificationsEnabled: true,
            biometricEnabled: false,
            createdAt: Date(),
            updatedAt: Date(),
            subscriptionTier: subscriptionTier,
            timezoneIdentifier: "America/New_York"
        )
    }
}
