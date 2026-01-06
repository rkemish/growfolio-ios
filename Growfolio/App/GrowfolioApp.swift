//
//  GrowfolioApp.swift
//  Growfolio
//
//  Main entry point for the Growfolio iOS application.
//

import SwiftUI

@main
struct GrowfolioApp: App {
    @State private var authService = AuthService.shared
    @State private var appState = AppState()
    @State private var toastManager = ToastManager.shared

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authService)
                .environment(appState)
                .environment(toastManager)
                .toastOverlay(position: .top, toastManager: toastManager)
        }
    }

    private func configureAppearance() {
        // Configure global appearance settings
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Root View

struct RootView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
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
            await checkAuthenticationState()
        }
    }

    private func checkAuthenticationState() async {
        // Always check onboarding first
        if !appState.hasCompletedOnboarding {
            appState.currentFlow = .onboarding
            return
        }

        // In mock mode, skip authentication and go directly to main
        if MockConfiguration.shared.isEnabled {
            appState.currentFlow = .main
            return
        }

        if await authService.isAuthenticated() {
            if appState.hasCompletedKYC {
                appState.currentFlow = .main
            } else {
                appState.currentFlow = .kyc
            }
        } else {
            appState.currentFlow = .authentication
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }
                .tag(0)

            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }
                .tag(1)

            DCASchedulesView()
                .tabItem {
                    Label("DCA", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(2)

            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "briefcase.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
    }
}

// MARK: - Authentication View Placeholder

struct AuthenticationView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Growfolio")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sign in to access your portfolio")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await signIn()
                }
            } label: {
                Text("Sign In with Auth0")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
    }

    private func signIn() async {
        do {
            try await authService.login()
            if appState.hasCompletedKYC {
                appState.currentFlow = .main
            } else {
                appState.currentFlow = .kyc
            }
        } catch {
            // Show authentication error toast
            Task { @MainActor in
                ToastManager.shared.showError(
                    "Sign in failed. Please try again.",
                    actionTitle: "Retry"
                ) {
                    Task { await signIn() }
                }
            }
        }
    }
}

// MARK: - Placeholder Views

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

// MARK: - App State

@Observable
final class AppState {
    enum Flow {
        case onboarding
        case authentication
        case kyc
        case main
    }

    var currentFlow: Flow = .onboarding
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }
    var hasCompletedKYC: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedKYC") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedKYC") }
    }
}
