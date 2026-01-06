//
//  AboutView.swift
//  Growfolio
//
//  View displaying app information, links, and credits.
//

import SwiftUI

struct AboutView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var showOpenSourceLicenses = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // App Logo and Branding
                    brandingSection

                    // App Description
                    descriptionSection

                    // Features Highlight
                    featuresSection

                    // Legal Links
                    legalLinksSection

                    // Support Section
                    supportSection

                    // Credits
                    creditsSection

                    // Version Info
                    versionSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showOpenSourceLicenses) {
                OpenSourceLicensesView()
            }
        }
    }

    // MARK: - Branding Section

    private var brandingSection: some View {
        VStack(spacing: 16) {
            // App Icon
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.trustBlue, Color.trustBlue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.trustBlue.opacity(0.3), radius: 10, y: 5)

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("Growfolio")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Smart Dollar Cost Averaging")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Growfolio")
                .font(.headline)

            Text("Growfolio helps UK investors build wealth through automated dollar cost averaging into US equities. Set your investment goals, create DCA schedules, and track your portfolio performance with real-time GBP/USD conversion - all in one place.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Features")
                .font(.headline)

            VStack(spacing: 12) {
                featureRow(
                    icon: "target",
                    iconColor: Color.growthGreen,
                    title: "Goal Tracking",
                    description: "Set and track investment goals with progress milestones"
                )

                featureRow(
                    icon: "calendar.badge.clock",
                    iconColor: Color.prosperityGold,
                    title: "DCA Scheduling",
                    description: "Automated recurring investments during market hours"
                )

                featureRow(
                    icon: "chart.pie.fill",
                    iconColor: Color.trustBlue,
                    title: "Portfolio Analytics",
                    description: "Real-time performance tracking in GBP and USD"
                )

                featureRow(
                    icon: "sparkles",
                    iconColor: Color.trustBlue,
                    title: "AI Insights",
                    description: "Personalized investment insights powered by Claude"
                )

                featureRow(
                    icon: "bell.badge.fill",
                    iconColor: Color.negative,
                    title: "Smart Alerts",
                    description: "Stay informed about your investments and goals"
                )

                featureRow(
                    icon: "person.2.fill",
                    iconColor: .teal,
                    title: "Family Accounts",
                    description: "Manage investments for the whole family"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func featureRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Legal Links Section

    private var legalLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Legal")
                .font(.headline)

            VStack(spacing: 0) {
                linkRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    url: Constants.App.termsOfServiceURL
                )

                Divider()
                    .padding(.leading, 52)

                linkRow(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    url: Constants.App.privacyPolicyURL
                )

                Divider()
                    .padding(.leading, 52)

                Button {
                    showOpenSourceLicenses = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.body)
                            .foregroundStyle(Color.trustBlue)
                            .frame(width: 28)

                        Text("Open Source Licenses")
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func linkRow(icon: String, title: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color.trustBlue)
                    .frame(width: 28)

                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support")
                .font(.headline)

            VStack(spacing: 0) {
                linkRow(
                    icon: "questionmark.circle.fill",
                    title: "Help Center",
                    url: Constants.App.helpCenterURL
                )

                Divider()
                    .padding(.leading, 52)

                linkRow(
                    icon: "envelope.fill",
                    title: "Contact Support",
                    url: URL(string: "mailto:\(Constants.App.supportEmail)")!
                )

                Divider()
                    .padding(.leading, 52)

                linkRow(
                    icon: "star.fill",
                    title: "Rate on App Store",
                    url: Constants.App.appStoreURL
                )
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Credits Section

    private var creditsSection: some View {
        VStack(spacing: 8) {
            Text("Made with love in London")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Text("Powered by")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Link("Alpaca", destination: URL(string: "https://alpaca.markets")!)
                    .font(.caption)
                    .foregroundStyle(Color.trustBlue)

                Text("&")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Link("Claude AI", destination: URL(string: "https://anthropic.com")!)
                    .font(.caption)
                    .foregroundStyle(Color.trustBlue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Version Section

    private var versionSection: some View {
        VStack(spacing: 4) {
            Text("Version \(Constants.App.version)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Build \(Constants.App.buildNumber)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text("\u{00A9} 2024 Growfolio. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Open Source Licenses View

private struct OpenSourceLicensesView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Growfolio uses the following open source libraries. We're grateful to the developers and communities behind these projects.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }

                Section("Dependencies") {
                    licenseRow(
                        name: "Auth0.swift",
                        license: "MIT License",
                        url: "https://github.com/auth0/Auth0.swift"
                    )

                    licenseRow(
                        name: "Kingfisher",
                        license: "MIT License",
                        url: "https://github.com/onevcat/Kingfisher"
                    )

                    licenseRow(
                        name: "Swift Algorithms",
                        license: "Apache License 2.0",
                        url: "https://github.com/apple/swift-algorithms"
                    )
                }
            }
            .navigationTitle("Open Source Licenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func licenseRow(name: String, license: String, url: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)

            Text(license)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let licenseURL = URL(string: url) {
                Link(url, destination: licenseURL)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    AboutView()
}
