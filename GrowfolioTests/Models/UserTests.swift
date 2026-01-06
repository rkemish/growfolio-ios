//
//  UserTests.swift
//  GrowfolioTests
//
//  Tests for User domain model.
//

import XCTest
@testable import Growfolio

final class UserTests: XCTestCase {

    // MARK: - DisplayNameOrEmail Tests

    func testDisplayNameOrEmail_WithDisplayName_ReturnsDisplayName() {
        let user = TestFixtures.user(email: "john@example.com", displayName: "John Doe")
        XCTAssertEqual(user.displayNameOrEmail, "John Doe")
    }

    func testDisplayNameOrEmail_NilDisplayName_ReturnsEmail() {
        let user = TestFixtures.user(email: "john@example.com", displayName: nil)
        XCTAssertEqual(user.displayNameOrEmail, "john@example.com")
    }

    // MARK: - Initials Tests

    func testInitials_TwoNames_ReturnsTwoLetters() {
        let user = TestFixtures.user(displayName: "John Doe")
        XCTAssertEqual(user.initials, "JD")
    }

    func testInitials_SingleName_ReturnsSingleLetter() {
        let user = TestFixtures.user(displayName: "Madonna")
        XCTAssertEqual(user.initials, "M")
    }

    func testInitials_ThreeNames_ReturnsFirstAndLast() {
        let user = TestFixtures.user(displayName: "John Paul Jones")
        XCTAssertEqual(user.initials, "JJ")
    }

    func testInitials_LowercaseName_ReturnsUppercased() {
        let user = TestFixtures.user(displayName: "john doe")
        XCTAssertEqual(user.initials, "JD")
    }

    func testInitials_EmptyDisplayName_ReturnsEmailPrefix() {
        let user = TestFixtures.user(email: "john@example.com", displayName: "")
        XCTAssertEqual(user.initials, "JO")
    }

    func testInitials_NilDisplayName_ReturnsEmailPrefix() {
        let user = TestFixtures.user(email: "ab@example.com", displayName: nil)
        XCTAssertEqual(user.initials, "AB")
    }

    // MARK: - Timezone Tests

    func testTimezone_ValidIdentifier_ReturnsTimezone() {
        let user = TestFixtures.user(timezoneIdentifier: "America/New_York")
        XCTAssertEqual(user.timezone.identifier, "America/New_York")
    }

    func testTimezone_InvalidIdentifier_ReturnsCurrent() {
        let user = TestFixtures.user(timezoneIdentifier: "Invalid/Timezone")
        XCTAssertEqual(user.timezone, TimeZone.current)
    }

    // MARK: - HasActiveSubscription Tests

    func testHasActiveSubscription_FreeTier_ReturnsFalse() {
        let user = TestFixtures.user(subscriptionTier: .free)
        XCTAssertFalse(user.hasActiveSubscription)
    }

    func testHasActiveSubscription_PremiumWithNoExpiry_ReturnsTrue() {
        let user = TestFixtures.user(subscriptionTier: .premium, subscriptionExpiresAt: nil)
        XCTAssertTrue(user.hasActiveSubscription)
    }

    func testHasActiveSubscription_PremiumWithFutureExpiry_ReturnsTrue() {
        let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let user = TestFixtures.user(subscriptionTier: .premium, subscriptionExpiresAt: futureDate)
        XCTAssertTrue(user.hasActiveSubscription)
    }

    func testHasActiveSubscription_PremiumWithPastExpiry_ReturnsFalse() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let user = TestFixtures.user(subscriptionTier: .premium, subscriptionExpiresAt: pastDate)
        XCTAssertFalse(user.hasActiveSubscription)
    }

    func testHasActiveSubscription_FamilyWithFutureExpiry_ReturnsTrue() {
        let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let user = TestFixtures.user(subscriptionTier: .family, subscriptionExpiresAt: futureDate)
        XCTAssertTrue(user.hasActiveSubscription)
    }

    // MARK: - CanAccessPremiumFeatures Tests

    func testCanAccessPremiumFeatures_FreeTier_ReturnsFalse() {
        let user = TestFixtures.user(subscriptionTier: .free)
        XCTAssertFalse(user.canAccessPremiumFeatures)
    }

    func testCanAccessPremiumFeatures_PremiumActive_ReturnsTrue() {
        let futureDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let user = TestFixtures.user(subscriptionTier: .premium, subscriptionExpiresAt: futureDate)
        XCTAssertTrue(user.canAccessPremiumFeatures)
    }

    func testCanAccessPremiumFeatures_PremiumExpired_ReturnsFalse() {
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let user = TestFixtures.user(subscriptionTier: .premium, subscriptionExpiresAt: pastDate)
        XCTAssertFalse(user.canAccessPremiumFeatures)
    }

    func testCanAccessPremiumFeatures_FamilyActive_ReturnsTrue() {
        let user = TestFixtures.user(subscriptionTier: .family, subscriptionExpiresAt: nil)
        XCTAssertTrue(user.canAccessPremiumFeatures)
    }

    // MARK: - SubscriptionTier Tests

    func testSubscriptionTier_DisplayName() {
        XCTAssertEqual(SubscriptionTier.free.displayName, "Free")
        XCTAssertEqual(SubscriptionTier.premium.displayName, "Premium")
        XCTAssertEqual(SubscriptionTier.family.displayName, "Family")
    }

    func testSubscriptionTier_Description() {
        XCTAssertFalse(SubscriptionTier.free.description.isEmpty)
        XCTAssertFalse(SubscriptionTier.premium.description.isEmpty)
        XCTAssertFalse(SubscriptionTier.family.description.isEmpty)
    }

    func testSubscriptionTier_MaxPortfolios() {
        XCTAssertEqual(SubscriptionTier.free.maxPortfolios, 1)
        XCTAssertEqual(SubscriptionTier.premium.maxPortfolios, 10)
        XCTAssertEqual(SubscriptionTier.family.maxPortfolios, 25)
    }

    func testSubscriptionTier_MaxGoals() {
        XCTAssertEqual(SubscriptionTier.free.maxGoals, 3)
        XCTAssertEqual(SubscriptionTier.premium.maxGoals, 50)
        XCTAssertEqual(SubscriptionTier.family.maxGoals, 100)
    }

    func testSubscriptionTier_DcaAutomationEnabled() {
        XCTAssertFalse(SubscriptionTier.free.dcaAutomationEnabled)
        XCTAssertTrue(SubscriptionTier.premium.dcaAutomationEnabled)
        XCTAssertTrue(SubscriptionTier.family.dcaAutomationEnabled)
    }

    func testSubscriptionTier_AiInsightsEnabled() {
        XCTAssertFalse(SubscriptionTier.free.aiInsightsEnabled)
        XCTAssertTrue(SubscriptionTier.premium.aiInsightsEnabled)
        XCTAssertTrue(SubscriptionTier.family.aiInsightsEnabled)
    }

    func testSubscriptionTier_FamilyAccountsEnabled() {
        XCTAssertFalse(SubscriptionTier.free.familyAccountsEnabled)
        XCTAssertFalse(SubscriptionTier.premium.familyAccountsEnabled)
        XCTAssertTrue(SubscriptionTier.family.familyAccountsEnabled)
    }

    func testSubscriptionTier_MaxFamilyMembers() {
        XCTAssertEqual(SubscriptionTier.free.maxFamilyMembers, 0)
        XCTAssertEqual(SubscriptionTier.premium.maxFamilyMembers, 0)
        XCTAssertEqual(SubscriptionTier.family.maxFamilyMembers, 5)
    }

    func testSubscriptionTier_AllCases() {
        XCTAssertEqual(SubscriptionTier.allCases.count, 3)
    }

    // MARK: - UserSettings Tests

    func testUserSettings_DefaultValues() {
        let settings = UserSettings()
        XCTAssertEqual(settings.preferredCurrency, "USD")
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertFalse(settings.biometricEnabled)
        XCTAssertEqual(settings.theme, .system)
        XCTAssertTrue(settings.hapticFeedbackEnabled)
        XCTAssertTrue(settings.showBalances)
    }

    func testUserSettings_CustomValues() {
        let settings = UserSettings(
            preferredCurrency: "GBP",
            notificationsEnabled: false,
            biometricEnabled: true,
            timezoneIdentifier: "Europe/London",
            theme: .dark,
            hapticFeedbackEnabled: false,
            showBalances: false
        )
        XCTAssertEqual(settings.preferredCurrency, "GBP")
        XCTAssertFalse(settings.notificationsEnabled)
        XCTAssertTrue(settings.biometricEnabled)
        XCTAssertEqual(settings.theme, .dark)
        XCTAssertFalse(settings.hapticFeedbackEnabled)
        XCTAssertFalse(settings.showBalances)
    }

    // MARK: - AppTheme Tests

    func testAppTheme_DisplayName() {
        XCTAssertEqual(AppTheme.light.displayName, "Light")
        XCTAssertEqual(AppTheme.dark.displayName, "Dark")
        XCTAssertEqual(AppTheme.system.displayName, "System")
    }

    func testAppTheme_Description() {
        XCTAssertFalse(AppTheme.light.description.isEmpty)
        XCTAssertFalse(AppTheme.dark.description.isEmpty)
        XCTAssertFalse(AppTheme.system.description.isEmpty)
    }

    func testAppTheme_IconName() {
        XCTAssertEqual(AppTheme.light.iconName, "sun.max.fill")
        XCTAssertEqual(AppTheme.dark.iconName, "moon.fill")
        XCTAssertEqual(AppTheme.system.iconName, "circle.lefthalf.filled")
    }

    func testAppTheme_AllCases() {
        XCTAssertEqual(AppTheme.allCases.count, 3)
    }

    // MARK: - NotificationSettings Tests

    func testNotificationSettings_Default() {
        let settings = NotificationSettings.default
        XCTAssertTrue(settings.dcaReminders)
        XCTAssertTrue(settings.goalProgress)
        XCTAssertTrue(settings.portfolioAlerts)
        XCTAssertFalse(settings.marketNews)
        XCTAssertTrue(settings.aiInsights)
        XCTAssertTrue(settings.weeklyDigest)
    }

    func testNotificationSettings_AllEnabled() {
        let settings = NotificationSettings.allEnabled
        XCTAssertTrue(settings.dcaReminders)
        XCTAssertTrue(settings.goalProgress)
        XCTAssertTrue(settings.portfolioAlerts)
        XCTAssertTrue(settings.marketNews)
        XCTAssertTrue(settings.aiInsights)
        XCTAssertTrue(settings.weeklyDigest)
    }

    func testNotificationSettings_AllDisabled() {
        let settings = NotificationSettings.allDisabled
        XCTAssertFalse(settings.dcaReminders)
        XCTAssertFalse(settings.goalProgress)
        XCTAssertFalse(settings.portfolioAlerts)
        XCTAssertFalse(settings.marketNews)
        XCTAssertFalse(settings.aiInsights)
        XCTAssertFalse(settings.weeklyDigest)
    }

    // MARK: - Codable Tests

    func testUser_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.user(
            id: "user-123",
            email: "john@example.com",
            displayName: "John Doe",
            preferredCurrency: "GBP",
            notificationsEnabled: true,
            biometricEnabled: true,
            subscriptionTier: .premium,
            timezoneIdentifier: "Europe/London"
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(User.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.email, original.email)
        XCTAssertEqual(decoded.displayName, original.displayName)
        XCTAssertEqual(decoded.preferredCurrency, original.preferredCurrency)
        XCTAssertEqual(decoded.notificationsEnabled, original.notificationsEnabled)
        XCTAssertEqual(decoded.biometricEnabled, original.biometricEnabled)
        XCTAssertEqual(decoded.subscriptionTier, original.subscriptionTier)
        XCTAssertEqual(decoded.timezoneIdentifier, original.timezoneIdentifier)
    }

    func testUser_EncodeDecode_NilOptionals() throws {
        let original = TestFixtures.user(
            displayName: nil,
            profilePictureURL: nil,
            subscriptionExpiresAt: nil
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(User.self, from: data)

        XCTAssertNil(decoded.displayName)
        XCTAssertNil(decoded.profilePictureURL)
        XCTAssertNil(decoded.subscriptionExpiresAt)
    }

    func testSubscriptionTier_Codable() throws {
        for tier in SubscriptionTier.allCases {
            let data = try JSONEncoder().encode(tier)
            let decoded = try JSONDecoder().decode(SubscriptionTier.self, from: data)
            XCTAssertEqual(decoded, tier)
        }
    }

    func testAppTheme_Codable() throws {
        for theme in AppTheme.allCases {
            let data = try JSONEncoder().encode(theme)
            let decoded = try JSONDecoder().decode(AppTheme.self, from: data)
            XCTAssertEqual(decoded, theme)
        }
    }

    func testUserSettings_Codable() throws {
        let original = UserSettings(
            preferredCurrency: "EUR",
            notificationsEnabled: false,
            biometricEnabled: true,
            theme: .dark
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(UserSettings.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testNotificationSettings_Codable() throws {
        let original = NotificationSettings(
            dcaReminders: true,
            goalProgress: false,
            portfolioAlerts: true,
            marketNews: true,
            aiInsights: false,
            weeklyDigest: true
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(NotificationSettings.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    // MARK: - Equatable Tests

    func testUser_Equatable_SameId() {
        let user1 = TestFixtures.user(id: "u1", displayName: "John")
        let user2 = TestFixtures.user(id: "u1", displayName: "John")
        XCTAssertEqual(user1, user2)
    }

    func testUser_Equatable_DifferentId() {
        let user1 = TestFixtures.user(id: "u1")
        let user2 = TestFixtures.user(id: "u2")
        XCTAssertNotEqual(user1, user2)
    }

    // MARK: - Hashable Tests

    func testUser_Hashable() {
        let user1 = TestFixtures.user(id: "u1")
        let user2 = TestFixtures.user(id: "u2")

        var set = Set<User>()
        set.insert(user1)
        set.insert(user2)

        XCTAssertEqual(set.count, 2)
    }

    func testUser_Hashable_SameIdNotDuplicated() {
        // Note: User uses synthesized Equatable/Hashable which compares ALL properties.
        // Two users with the same ID but different names are NOT considered equal/duplicate.
        // This test verifies that users with identical properties are deduplicated.
        let user1 = TestFixtures.user(id: "u1", displayName: "Name 1")
        let user2 = TestFixtures.user(id: "u1", displayName: "Name 1")

        var set = Set<User>()
        set.insert(user1)
        set.insert(user2)

        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Edge Cases

    func testUser_EmptyEmail() {
        let user = TestFixtures.user(email: "")
        XCTAssertEqual(user.email, "")
    }

    func testUser_SpecialCharactersInDisplayName() {
        let user = TestFixtures.user(displayName: "O'Brien-Smith Jr.")
        XCTAssertEqual(user.displayName, "O'Brien-Smith Jr.")
        XCTAssertEqual(user.initials, "OJ")
    }

    func testUser_ProfilePictureURL() {
        let url = URL(string: "https://example.com/profile.jpg")!
        let user = TestFixtures.user(profilePictureURL: url)
        XCTAssertEqual(user.profilePictureURL, url)
    }
}
