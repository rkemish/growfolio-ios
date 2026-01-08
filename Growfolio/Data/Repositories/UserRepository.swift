//
//  UserRepository.swift
//  Growfolio
//
//  Repository for user profile and preferences management.
//

import Foundation

// MARK: - Protocol

protocol UserRepositoryProtocol: Sendable {
    /// Fetch current user profile
    func fetchCurrentUser() async throws -> User

    /// Update user profile
    func updateProfile(displayName: String) async throws -> User

    /// Fetch user preferences
    func fetchPreferences() async throws -> UserSettings

    /// Update user preferences
    func updatePreferences(_ preferences: UserPreferencesUpdate) async throws -> UserSettings

    /// Register device token for push notifications
    func registerDeviceToken(_ token: String) async throws

    /// Delete user account
    func deleteAccount() async throws
}

// MARK: - DTOs

struct UserDTO: Codable, Sendable {
    let id: String
    let email: String
    let name: String
    let firstName: String?
    let lastName: String?
    let pictureUrl: String?
    let isVerified: Bool
    let alpacaAccountId: String?
    let alpacaAccountStatus: String?
    let familyId: String?
    let preferences: UserPreferencesDTO
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case firstName = "first_name"
        case lastName = "last_name"
        case pictureUrl = "picture_url"
        case isVerified = "is_verified"
        case alpacaAccountId = "alpaca_account_id"
        case alpacaAccountStatus = "alpaca_account_status"
        case familyId = "family_id"
        case preferences
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func toDomain() -> User {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return User(
            id: id,
            email: email,
            // Convert empty names to nil for cleaner UI display
            displayName: name.isEmpty ? nil : name,
            // Safely parse URL string, returns nil if invalid
            profilePictureURL: pictureUrl.flatMap { URL(string: $0) },
            preferredCurrency: preferences.defaultCurrency,
            notificationsEnabled: preferences.notificationsEnabled,
            biometricEnabled: preferences.biometricEnabled,
            // Fallback to current date if parsing fails
            createdAt: dateFormatter.date(from: createdAt) ?? Date(),
            updatedAt: dateFormatter.date(from: updatedAt) ?? Date(),
            // Infer subscription tier: having Alpaca account = premium, otherwise free
            subscriptionTier: alpacaAccountId != nil ? .premium : .free,
            subscriptionExpiresAt: nil,
            timezoneIdentifier: TimeZone.current.identifier
        )
    }
}

struct UserPreferencesDTO: Codable, Sendable {
    let defaultCurrency: String
    let notificationsEnabled: Bool
    let emailNotifications: Bool
    let dcaNotifications: Bool
    let weeklySummary: Bool
    let theme: String
    let biometricEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case defaultCurrency = "default_currency"
        case notificationsEnabled = "notifications_enabled"
        case emailNotifications = "email_notifications"
        case dcaNotifications = "dca_notifications"
        case weeklySummary = "weekly_summary"
        case theme
        case biometricEnabled = "biometric_enabled"
    }

    func toSettings() -> UserSettings {
        UserSettings(
            preferredCurrency: defaultCurrency,
            notificationsEnabled: notificationsEnabled,
            biometricEnabled: biometricEnabled,
            timezoneIdentifier: TimeZone.current.identifier,
            theme: AppTheme(rawValue: theme) ?? .system,
            hapticFeedbackEnabled: true,
            showBalances: true
        )
    }

    func toNotificationSettings() -> NotificationSettings {
        NotificationSettings(
            dcaReminders: dcaNotifications,
            goalProgress: true,
            portfolioAlerts: true,
            marketNews: false,
            aiInsights: true,
            weeklyDigest: weeklySummary
        )
    }
}

struct UserPreferencesUpdate: Codable, Sendable {
    let defaultCurrency: String?
    let notificationsEnabled: Bool?
    let emailNotifications: Bool?
    let dcaNotifications: Bool?
    let weeklySummary: Bool?
    let theme: String?
    let biometricEnabled: Bool?

    init(
        defaultCurrency: String? = nil,
        notificationsEnabled: Bool? = nil,
        emailNotifications: Bool? = nil,
        dcaNotifications: Bool? = nil,
        weeklySummary: Bool? = nil,
        theme: String? = nil,
        biometricEnabled: Bool? = nil
    ) {
        self.defaultCurrency = defaultCurrency
        self.notificationsEnabled = notificationsEnabled
        self.emailNotifications = emailNotifications
        self.dcaNotifications = dcaNotifications
        self.weeklySummary = weeklySummary
        self.theme = theme
        self.biometricEnabled = biometricEnabled
    }

    static func from(settings: UserSettings, notifications: NotificationSettings) -> UserPreferencesUpdate {
        UserPreferencesUpdate(
            defaultCurrency: settings.preferredCurrency,
            notificationsEnabled: settings.notificationsEnabled,
            emailNotifications: notifications.weeklyDigest,
            dcaNotifications: notifications.dcaReminders,
            weeklySummary: notifications.weeklyDigest,
            theme: settings.theme.rawValue,
            biometricEnabled: settings.biometricEnabled
        )
    }

    func toRequest() -> UserPreferencesUpdateRequest {
        UserPreferencesUpdateRequest(
            defaultCurrency: defaultCurrency,
            notificationsEnabled: notificationsEnabled,
            emailNotifications: emailNotifications,
            dcaNotifications: dcaNotifications,
            weeklySummary: weeklySummary,
            theme: theme,
            biometricEnabled: biometricEnabled
        )
    }
}

// MARK: - Repository Implementation

final class UserRepository: UserRepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let apiClient: APIClientProtocol
    private let cache: UserCache

    // MARK: - Initialization

    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
        self.cache = UserCache()
    }

    // MARK: - UserRepositoryProtocol

    func fetchCurrentUser() async throws -> User {
        // Check cache first
        if let cached = cache.getUser() {
            return cached
        }

        let dto: UserDTO = try await apiClient.request(Endpoints.GetCurrentUser())

        let user = dto.toDomain()
        cache.setUser(user)
        return user
    }

    func updateProfile(displayName: String) async throws -> User {
        let update = UserUpdateRequest(
            displayName: displayName,
            preferredCurrency: nil,
            notificationsEnabled: nil
        )

        let dto: UserDTO = try await apiClient.request(try Endpoints.UpdateUser(update: update))

        let user = dto.toDomain()
        cache.setUser(user)
        return user
    }

    func fetchPreferences() async throws -> UserSettings {
        let dto: UserPreferencesDTO = try await apiClient.request(Endpoints.GetPreferences())
        return dto.toSettings()
    }

    func updatePreferences(_ preferences: UserPreferencesUpdate) async throws -> UserSettings {
        let dto: UserPreferencesDTO = try await apiClient.request(
            try Endpoints.UpdatePreferences(preferences: preferences.toRequest())
        )

        cache.invalidate()
        return dto.toSettings()
    }

    func registerDeviceToken(_ token: String) async throws {
        try await apiClient.request(Endpoints.RegisterDevice(token: token))
    }

    func deleteAccount() async throws {
        try await apiClient.request(Endpoints.DeleteUser())
        cache.invalidate()
    }
}

// MARK: - Cache

private final class UserCache: @unchecked Sendable {
    private var user: User?
    private var cacheDate: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes

    private let lock = NSLock()

    func getUser() -> User? {
        lock.lock()
        defer { lock.unlock() }

        guard let user = user,
              let cacheDate = cacheDate,
              Date().timeIntervalSince(cacheDate) < cacheDuration else {
            return nil
        }

        return user
    }

    func setUser(_ user: User) {
        lock.lock()
        defer { lock.unlock() }

        self.user = user
        self.cacheDate = Date()
    }

    func invalidate() {
        lock.lock()
        defer { lock.unlock() }

        self.user = nil
        self.cacheDate = nil
    }
}
