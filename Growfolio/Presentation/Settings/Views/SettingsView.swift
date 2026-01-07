//
//  SettingsView.swift
//  Growfolio
//
//  Settings and user preferences view.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Properties

    @State private var viewModel = SettingsViewModel()
    @Environment(AppState.self) private var appState
    @AppStorage(Constants.StorageKeys.useMockData) private var useMockData = true
    @State private var showRestartAlert = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                profileSection

                // Preferences Section
                preferencesSection

                // Notifications Section
                notificationsSection

                // Security Section
                securitySection

                // About Section
                aboutSection

                #if DEBUG
                // Developer Section (only in DEBUG builds)
                developerSection
                #endif

                // Account Actions
                accountActionsSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadUserData()
            }
            .sheet(isPresented: $viewModel.showEditProfile) {
                EditProfileView(
                    displayName: viewModel.displayName,
                    onSave: { newName in
                        Task {
                            await viewModel.updateDisplayName(newName)
                            viewModel.showEditProfile = false
                        }
                    },
                    onCancel: {
                        viewModel.showEditProfile = false
                    }
                )
            }
            .sheet(isPresented: $viewModel.showCurrencyPicker) {
                CurrencyPickerView(
                    selectedCurrency: viewModel.settings.preferredCurrency,
                    onSelect: { currency in
                        Task {
                            await viewModel.updateCurrency(currency)
                            viewModel.showCurrencyPicker = false
                        }
                    },
                    onCancel: {
                        viewModel.showCurrencyPicker = false
                    }
                )
            }
            .sheet(isPresented: $viewModel.showThemePicker) {
                ThemePickerView(
                    selectedTheme: viewModel.settings.theme,
                    onSelect: { theme in
                        viewModel.updateTheme(theme)
                        viewModel.showThemePicker = false
                    },
                    onCancel: {
                        viewModel.showThemePicker = false
                    }
                )
            }
            .sheet(isPresented: $viewModel.showNotificationSettings) {
                NotificationSettingsView(
                    settings: Binding(
                        get: { viewModel.notificationSettings },
                        set: { viewModel.notificationSettings = $0 }
                    ),
                    onSave: {
                        Task {
                            await viewModel.updateNotificationSettings(viewModel.notificationSettings)
                            viewModel.showNotificationSettings = false
                        }
                    },
                    onCancel: {
                        viewModel.showNotificationSettings = false
                    }
                )
            }
            .sheet(isPresented: $viewModel.showAbout) {
                AboutView()
            }
            .alert("Sign Out", isPresented: $viewModel.showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $viewModel.showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.trustBlue.gradient)
                        .frame(width: 60, height: 60)

                    Text(viewModel.initials)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.displayName)
                        .font(.headline)

                    Text(viewModel.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isPremium ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(viewModel.isPremium ? .yellow : .secondary)

                        Text(viewModel.subscriptionTier.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Edit Button
                Button {
                    viewModel.showEditProfile = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.trustBlue)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        Section("Preferences") {
            // Currency
            Button {
                viewModel.showCurrencyPicker = true
            } label: {
                HStack {
                    Label("Currency", systemImage: "dollarsign.circle")
                    Spacer()
                    Text(viewModel.settings.preferredCurrency)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)

            // Theme
            Button {
                viewModel.showThemePicker = true
            } label: {
                HStack {
                    Label("Appearance", systemImage: "paintbrush")
                    Spacer()
                    Text(viewModel.settings.theme.displayName)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: Binding(
                get: { viewModel.settings.notificationsEnabled },
                set: { newValue in
                    Task {
                        await viewModel.toggleNotifications(newValue)
                    }
                }
            )) {
                Label("Push Notifications", systemImage: "bell")
            }

            if viewModel.settings.notificationsEnabled {
                Button {
                    viewModel.showNotificationSettings = true
                } label: {
                    HStack {
                        Label("Notification Preferences", systemImage: "bell.badge")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Security Section

    private var securitySection: some View {
        Section("Security") {
            Toggle(isOn: Binding(
                get: { viewModel.settings.biometricEnabled },
                set: { newValue in
                    Task {
                        await viewModel.toggleBiometric(newValue)
                    }
                }
            )) {
                Label("Face ID / Touch ID", systemImage: "faceid")
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            Button {
                viewModel.showAbout = true
            } label: {
                HStack {
                    Label("About Growfolio", systemImage: "info.circle")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)

            HStack {
                Label("Version", systemImage: "number")
                Spacer()
                Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Member Since", systemImage: "calendar")
                Spacer()
                Text(viewModel.memberSince)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Account Actions Section

    private var accountActionsSection: some View {
        Section {
            Button {
                viewModel.showSignOutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    Spacer()
                }
            }
            .foregroundStyle(Color.trustBlue)

            Button {
                viewModel.showDeleteAccountConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Label("Delete Account", systemImage: "trash")
                    Spacer()
                }
            }
            .foregroundStyle(Color.negative)
        }
    }

    // MARK: - Developer Section

    #if DEBUG
    private var developerSection: some View {
        Section {
            // Mock Mode Toggle
            Toggle(isOn: $useMockData) {
                Label("Mock Mode", systemImage: "hammer.fill")
            }
            .onChange(of: useMockData) { _, _ in
                showRestartAlert = true
            }

            // Reset Onboarding
            Button {
                UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                // Immediately show onboarding
                appState.currentFlow = .onboarding
            } label: {
                Label("Show Intro Again", systemImage: "arrow.counterclockwise")
            }
            .foregroundStyle(.primary)

            // Reset All Data
            Button {
                // Clear all UserDefaults
                if let bundleID = Bundle.main.bundleIdentifier {
                    UserDefaults.standard.removePersistentDomain(forName: bundleID)
                }
                showRestartAlert = true
            } label: {
                Label("Reset All App Data", systemImage: "trash.circle")
            }
            .foregroundStyle(Color.negative)
        } header: {
            Label("Developer", systemImage: "wrench.and.screwdriver")
        } footer: {
            Text("These options are only visible in debug builds. Restart the app after making changes.")
        }
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("OK") {}
        } message: {
            Text("Please restart the app for changes to take effect.")
        }
    }
    #endif
}

// MARK: - Preview

#Preview {
    SettingsView()
}
