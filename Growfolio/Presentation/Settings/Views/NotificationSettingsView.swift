//
//  NotificationSettingsView.swift
//  Growfolio
//
//  View for configuring notification preferences.
//

import SwiftUI

struct NotificationSettingsView: View {

    // MARK: - Properties

    @Binding var settings: NotificationSettings
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var localSettings: NotificationSettings

    // MARK: - Initialization

    init(
        settings: Binding<NotificationSettings>,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._settings = settings
        self.onSave = onSave
        self.onCancel = onCancel
        self._localSettings = State(initialValue: settings.wrappedValue)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Investment Alerts
                investmentAlertsSection

                // Goal Notifications
                goalNotificationsSection

                // Portfolio Updates
                portfolioUpdatesSection

                // Summary & Insights
                summarySection
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        settings = localSettings
                        onSave()
                    }
                }
            }
        }
    }

    // MARK: - Investment Alerts Section

    private var investmentAlertsSection: some View {
        Section {
            Toggle(isOn: $localSettings.dcaReminders) {
                notificationRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: Color.prosperityGold,
                    title: "DCA Reminders",
                    description: "Get notified before scheduled investments"
                )
            }
        } header: {
            Text("Investment Alerts")
        } footer: {
            Text("Receive reminders before your DCA schedules execute.")
        }
    }

    // MARK: - Goal Notifications Section

    private var goalNotificationsSection: some View {
        Section {
            Toggle(isOn: $localSettings.goalProgress) {
                notificationRow(
                    icon: "target",
                    iconColor: Color.growthGreen,
                    title: "Goal Progress",
                    description: "Milestone achievements and progress updates"
                )
            }
        } header: {
            Text("Goals")
        } footer: {
            Text("Get notified when you reach goal milestones.")
        }
    }

    // MARK: - Portfolio Updates Section

    private var portfolioUpdatesSection: some View {
        Section {
            Toggle(isOn: $localSettings.portfolioAlerts) {
                notificationRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: Color.trustBlue,
                    title: "Portfolio Alerts",
                    description: "Significant portfolio value changes"
                )
            }

            Toggle(isOn: $localSettings.marketNews) {
                notificationRow(
                    icon: "newspaper",
                    iconColor: Color.trustBlue,
                    title: "Market News",
                    description: "News about stocks in your portfolio"
                )
            }
        } header: {
            Text("Portfolio")
        } footer: {
            Text("Stay informed about your portfolio performance.")
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        Section {
            Toggle(isOn: $localSettings.aiInsights) {
                notificationRow(
                    icon: "sparkles",
                    iconColor: .pink,
                    title: "AI Insights",
                    description: "Personalized investment insights"
                )
            }

            Toggle(isOn: $localSettings.weeklyDigest) {
                notificationRow(
                    icon: "envelope.open",
                    iconColor: .teal,
                    title: "Weekly Digest",
                    description: "Weekly summary of your investments"
                )
            }
        } header: {
            Text("Summary & Insights")
        } footer: {
            Text("Get periodic summaries and AI-powered insights.")
        }
    }

    // MARK: - Helper Views

    private func notificationRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NotificationSettingsView(
        settings: .constant(.default),
        onSave: {},
        onCancel: {}
    )
}
