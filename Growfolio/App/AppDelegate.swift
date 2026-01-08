//
//  AppDelegate.swift
//  Growfolio
//
//  UIKit App Delegate for handling app lifecycle events and push notifications.
//

import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureServices()
        registerForPushNotifications(application)
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        return configuration
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Clean up resources for discarded scenes
    }

    // MARK: - Push Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task {
            await registerDeviceToken(token)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - URL Handling

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // No custom URL handling for Apple Sign In
        return false
    }

    // MARK: - Background Tasks

    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            await performBackgroundRefresh()
            completionHandler(.newData)
        }
    }

    // MARK: - Private Methods

    private func configureServices() {
        // Process launch arguments first (for UI testing support)
        MockConfiguration.shared.processLaunchArguments()

        // Initialize core services
        configureLogging()
        configureAnalytics()
        configureCache()
    }

    private func configureLogging() {
        #if DEBUG
        // Enable verbose logging in debug mode
        print("Growfolio: Debug logging enabled")
        #endif
    }

    private func configureAnalytics() {
        // Analytics configuration - placeholder for analytics SDK
        let environment = AppEnvironment.current
        print("Growfolio: Analytics configured for \(environment.rawValue)")
    }

    private func configureCache() {
        // Configure URL cache
        let memoryCapacity = 50 * 1024 * 1024  // 50 MB
        let diskCapacity = 100 * 1024 * 1024   // 100 MB
        let cache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            diskPath: "growfolio_cache"
        )
        URLCache.shared = cache
    }

    private func registerForPushNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
            if let error = error {
                print("Push notification authorization error: \(error.localizedDescription)")
            }
        }
    }

    private func registerDeviceToken(_ token: String) async {
        guard !MockConfiguration.shared.isEnabled else { return }
        // Send device token to backend for push notifications
        do {
            try await RepositoryContainer.userRepository.registerDeviceToken(token)
        } catch {
            print("Failed to register device token: \(error)")
        }
    }

    private func performBackgroundRefresh() async {
        // Refresh portfolio data in background
        // This is called when the app has background fetch enabled
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleNotificationAction(userInfo: userInfo, actionIdentifier: response.actionIdentifier)
        completionHandler()
    }

    private func handleNotificationAction(userInfo: [AnyHashable: Any], actionIdentifier: String) {
        // Handle notification tap - navigate to appropriate screen
        if let type = userInfo["type"] as? String {
            switch type {
            case "dca_reminder":
                // Navigate to DCA screen
                NotificationCenter.default.post(name: .navigateToDCA, object: nil)
            case "goal_update":
                // Navigate to Goals screen
                NotificationCenter.default.post(name: .navigateToGoals, object: nil)
            case "portfolio_alert":
                // Navigate to Portfolio screen
                NotificationCenter.default.post(name: .navigateToPortfolio, object: nil)
            default:
                break
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToDCA = Notification.Name("navigateToDCA")
    static let navigateToGoals = Notification.Name("navigateToGoals")
    static let navigateToPortfolio = Notification.Name("navigateToPortfolio")
}
