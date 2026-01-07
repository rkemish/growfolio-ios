//
//  GrowfolioApp.swift
//  Growfolio
//
//  Main entry point for the Growfolio iOS application.
//  This file defines the app's structure, global configuration, and root scene.
//

import SwiftUI

/// Main application struct conforming to the App protocol.
/// Serves as the entry point for the Growfolio iOS application and manages
/// global app state, services, and appearance configuration.
@main
struct GrowfolioApp: App {
    /// Connect the UIKit app delegate for lifecycle and push notification handling
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Shared authentication service for managing user login/logout state
    @State private var authService = AuthService.shared

    /// Global app state manager for tracking current flow and user progress
    @State private var appState = AppState()

    /// Shared toast notification manager for displaying user feedback
    @State private var toastManager = ToastManager.shared

    /// Initializes the app and configures global appearance settings
    init() {
        configureAppearance()
    }

    /// Defines the main scene structure for the application
    var body: some Scene {
        WindowGroup {
            RootView()
                // Inject shared services into the SwiftUI environment
                .environment(authService)
                .environment(appState)
                .environment(toastManager)
                // Add toast overlay at the top of the screen
                .toastOverlay(position: .top, toastManager: toastManager)
        }
    }

    /// Configures global UI appearance settings for the application.
    /// Sets up navigation bar appearance to maintain consistency across views.
    private func configureAppearance() {
        // Create opaque navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Apply appearance to both standard and scroll edge states
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Root View

/// Root view that manages the app's main navigation flow.
/// Determines which view to display based on the current app state and user authentication status.
/// Handles the transitions between onboarding, authentication, KYC, and main app flows.
struct RootView: View {
    /// Injected authentication service from the environment
    @Environment(AuthService.self) private var authService
    
    /// Injected app state manager from the environment
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            // Navigate to appropriate view based on current flow state
            switch appState.currentFlow {
            case .onboarding:
                OnboardingView()
            case .authentication:
                AuthenticationView()
            case .kyc:
                KYCFlowView()
            case .main:
                MainTabView()
            }
        }
        .task {
            // Check authentication state when view appears
            await checkAuthenticationState()
        }
    }

    /// Determines the appropriate app flow based on user's onboarding, authentication, and KYC status.
    /// Priority order: Onboarding → Authentication → KYC → Main App
    /// Includes support for mock mode and UI testing launch arguments.
    private func checkAuthenticationState() async {
        let mockConfig = MockConfiguration.shared

        // Handle UI testing launch arguments
        if mockConfig.shouldResetOnboarding {
            appState.hasCompletedOnboarding = false
            appState.hasCompletedKYC = false
        }

        if mockConfig.shouldSkipToMain {
            appState.hasCompletedOnboarding = true
            appState.hasCompletedKYC = true
            appState.currentFlow = .main
            return
        }

        if mockConfig.shouldSkipOnboarding {
            appState.hasCompletedOnboarding = true
            appState.currentFlow = .authentication
            return
        }

        // First priority: Check if user has completed onboarding
        if !appState.hasCompletedOnboarding {
            appState.currentFlow = .onboarding
            return
        }

        // Development feature: Skip authentication in mock mode
        if mockConfig.isEnabled {
            appState.currentFlow = .main
            return
        }

        // Check authentication and KYC status to determine next flow
        if await authService.isAuthenticated() {
            if appState.hasCompletedKYC {
                appState.currentFlow = .main
            } else {
                // User is authenticated but needs to complete KYC
                appState.currentFlow = .kyc
            }
        } else {
            // User is not authenticated, show login screen
            appState.currentFlow = .authentication
        }
    }
}

// MARK: - Main Tab View

/// Main tab-based interface for the authenticated user experience.
/// Manages the primary navigation between core app features and handles
/// WebSocket connections for real-time data updates.
struct MainTabView: View {
    /// Currently selected tab index (0-4)
    @State private var selectedTab = 0
    
    /// Monitor app lifecycle to manage WebSocket connections
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard - Main overview and analytics
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)

            // Watchlist - Tracked securities and favorites
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }
                .tag(1)

            // Dollar-Cost Averaging - Investment automation
            DCASchedulesView()
                .tabItem {
                    Label("DCA", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(2)

            // Portfolio - Holdings and performance tracking
            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "briefcase.fill")
                }
                .tag(3)

            // Settings - App configuration and account management
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .task {
            // Establish WebSocket connection when tab view appears
            await WebSocketService.shared.connect()
        }
        .onDisappear {
            // Clean up WebSocket connection when view disappears
            Task {
                await WebSocketService.shared.disconnect()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Manage WebSocket connections based on app lifecycle
            switch phase {
            case .active:
                // Reconnect when app becomes active
                Task {
                    await WebSocketService.shared.connect()
                }
            case .background:
                // Disconnect when app goes to background to save resources
                Task {
                    await WebSocketService.shared.disconnect()
                }
            default:
                break
            }
        }
    }
}

// MARK: - Authentication View

/// Authentication screen that handles user sign-in flow.
/// Provides a welcoming interface with Sign in with Apple functionality
/// and appropriate error handling with toast notifications.
struct AuthenticationView: View {
    /// Injected authentication service from the environment
    @Environment(AuthService.self) private var authService
    
    /// Injected app state manager from the environment
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            // App branding and visual identity
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            // App title
            Text("Growfolio")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Subtitle explaining the purpose
            Text("Sign in to access your portfolio")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Primary authentication button
            Button {
                Task {
                    await signIn()
                }
            } label: {
                Text("Sign In with Apple")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
    }

    /// Handles the sign-in process with proper error handling and flow navigation.
    /// On success, navigates to either KYC flow or main app based on completion status.
    /// On failure, shows error toast with retry option.
    private func signIn() async {
        do {
            // Attempt authentication through the auth service
            try await authService.login()
            
            // Navigate to appropriate flow based on KYC completion status
            if appState.hasCompletedKYC {
                appState.currentFlow = .main
            } else {
                appState.currentFlow = .kyc
            }
        } catch {
            // Handle authentication failure with user-friendly error message
            Task { @MainActor in
                ToastManager.shared.showError(
                    "Sign in failed. Please try again.",
                    actionTitle: "Retry"
                ) {
                    // Provide retry action in the toast
                    Task { await signIn() }
                }
            }
        }
    }
}

// MARK: - Placeholder Views

/// These placeholder views serve as temporary implementations for features
/// that are planned but not yet fully developed. They provide a consistent
/// "coming soon" experience while maintaining proper navigation structure.

/// Placeholder view for the Goals feature.
/// Will eventually allow users to set and track investment goals.
struct GoalsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Goals Coming Soon",
                systemImage: "target",
                description: Text("Track your investment goals here")
            )
            .navigationTitle("Goals")
        }
    }
}

/// Placeholder view for the Dollar-Cost Averaging (DCA) feature.
/// Will eventually provide automated investment scheduling and management.
struct DCAPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "DCA Coming Soon",
                systemImage: "arrow.triangle.2.circlepath",
                description: Text("Manage your dollar-cost averaging schedules")
            )
            .navigationTitle("DCA")
        }
    }
}

/// Placeholder view for the Portfolio feature.
/// Will eventually show complete portfolio holdings, performance, and analytics.
struct PortfolioPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Portfolio Coming Soon",
                systemImage: "briefcase.fill",
                description: Text("View your complete portfolio")
            )
            .navigationTitle("Portfolio")
        }
    }
}

/// Placeholder view for the Settings feature.
/// Will eventually provide app configuration, account management, and preferences.
struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Settings Coming Soon",
                systemImage: "gearshape.fill",
                description: Text("Configure your app preferences")
            )
            .navigationTitle("Settings")
        }
    }
}

// MARK: - App State Management

/// Observable class that manages the global state of the application.
/// Tracks user progress through different app flows and persists important
/// completion flags using UserDefaults for persistence across app launches.
@Observable
final class AppState {
    /// Enumeration defining the different flows/screens in the app.
    /// The app progresses through these flows in a specific order based on user status.
    enum Flow {
        case onboarding    // First-time user introduction and setup
        case authentication // User login and account verification
        case kyc           // Know Your Customer compliance process
        case main          // Main authenticated app experience
    }

    /// Current flow state of the application.
    /// This determines which root view is displayed to the user.
    var currentFlow: Flow = .onboarding
    
    /// Tracks whether the user has completed the onboarding process.
    /// Stored persistently in UserDefaults to remember across app launches.
    /// Once true, the user will skip onboarding on future app starts.
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    
    /// Tracks whether the user has completed the KYC (Know Your Customer) process.
    /// This is typically required for financial applications to comply with regulations.
    /// Stored persistently in UserDefaults to remember across app launches.
    var hasCompletedKYC: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedKYC") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedKYC") }
    }
}
