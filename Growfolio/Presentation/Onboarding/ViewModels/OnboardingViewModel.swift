//
//  OnboardingViewModel.swift
//  Growfolio
//
//  View model for the onboarding flow.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class OnboardingViewModel: @unchecked Sendable {

    // MARK: - Properties

    /// Current page index
    var currentPage: Int = 0

    /// All onboarding pages
    let pages: [OnboardingPage] = OnboardingPage.pages

    /// Whether the user is on the last page
    var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    /// Whether the user is on the first page
    var isFirstPage: Bool {
        currentPage == 0
    }

    /// Progress through onboarding (0.0 to 1.0)
    var progress: Double {
        guard pages.count > 1 else { return 1.0 }
        return Double(currentPage) / Double(pages.count - 1)
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Navigation

    /// Move to the next page
    func nextPage() {
        guard !isLastPage else { return }
        currentPage += 1
    }

    /// Move to the previous page
    func previousPage() {
        guard !isFirstPage else { return }
        currentPage -= 1
    }

    /// Jump to a specific page
    /// - Parameter index: Page index to navigate to
    func goToPage(_ index: Int) {
        guard index >= 0 && index < pages.count else { return }
        currentPage = index
    }

    // MARK: - Completion

    /// Complete the onboarding flow
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Constants.StorageKeys.hasCompletedOnboarding)
        trackOnboardingCompletion()
    }

    /// Skip the onboarding flow
    func skipOnboarding() {
        UserDefaults.standard.set(true, forKey: Constants.StorageKeys.hasCompletedOnboarding)
        trackOnboardingSkip()
    }

    // MARK: - Analytics

    private func trackOnboardingCompletion() {
        // Track analytics event for onboarding completion
        #if DEBUG
        print("Onboarding completed at page \(currentPage + 1) of \(pages.count)")
        #endif
    }

    private func trackOnboardingSkip() {
        // Track analytics event for onboarding skip
        #if DEBUG
        print("Onboarding skipped at page \(currentPage + 1) of \(pages.count)")
        #endif
    }
}

// MARK: - Onboarding State Manager

/// Manages persistent onboarding state
actor OnboardingStateManager {

    // MARK: - Singleton

    static let shared = OnboardingStateManager()

    // MARK: - Properties

    private let defaults = UserDefaults.standard

    // MARK: - State

    /// Whether onboarding has been completed
    var hasCompletedOnboarding: Bool {
        defaults.bool(forKey: Constants.StorageKeys.hasCompletedOnboarding)
    }

    /// Set onboarding completion state
    func setOnboardingCompleted(_ completed: Bool) {
        defaults.set(completed, forKey: Constants.StorageKeys.hasCompletedOnboarding)
    }

    /// Reset onboarding state (for testing or re-onboarding)
    func resetOnboarding() {
        defaults.removeObject(forKey: Constants.StorageKeys.hasCompletedOnboarding)
    }

    /// Get the page where user left off (if applicable)
    var lastViewedPage: Int {
        defaults.integer(forKey: "onboarding_last_page")
    }

    /// Save the current page
    func saveCurrentPage(_ page: Int) {
        defaults.set(page, forKey: "onboarding_last_page")
    }
}

// MARK: - Onboarding Feature Highlights

/// Feature highlights shown during onboarding
struct OnboardingFeature: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let category: FeatureCategory

    enum FeatureCategory: String, Sendable {
        case goals
        case dca
        case portfolio
        case family
        case insights
    }

    static let allFeatures: [OnboardingFeature] = [
        // Goals Features
        OnboardingFeature(
            title: "Smart Goal Setting",
            description: "Set financial goals with target amounts and dates",
            iconName: "target",
            category: .goals
        ),
        OnboardingFeature(
            title: "Goal Tracking",
            description: "Monitor progress with visual indicators",
            iconName: "chart.bar.fill",
            category: .goals
        ),
        OnboardingFeature(
            title: "Portfolio Linking",
            description: "Link goals to specific portfolios for automatic tracking",
            iconName: "link.circle.fill",
            category: .goals
        ),

        // DCA Features
        OnboardingFeature(
            title: "Automated Investing",
            description: "Schedule recurring investments at your preferred frequency",
            iconName: "arrow.triangle.2.circlepath",
            category: .dca
        ),
        OnboardingFeature(
            title: "Flexible Scheduling",
            description: "Daily, weekly, bi-weekly, monthly, or quarterly options",
            iconName: "calendar",
            category: .dca
        ),
        OnboardingFeature(
            title: "DCA Simulations",
            description: "See how DCA would have performed historically",
            iconName: "waveform.path.ecg",
            category: .dca
        ),

        // Portfolio Features
        OnboardingFeature(
            title: "Multi-Portfolio Support",
            description: "Manage multiple investment accounts in one place",
            iconName: "briefcase.fill",
            category: .portfolio
        ),
        OnboardingFeature(
            title: "Performance Analytics",
            description: "Track returns and compare to benchmarks",
            iconName: "chart.line.uptrend.xyaxis",
            category: .portfolio
        ),
        OnboardingFeature(
            title: "Transaction History",
            description: "Full ledger of all your investment activities",
            iconName: "list.bullet.rectangle",
            category: .portfolio
        ),

        // Family Features
        OnboardingFeature(
            title: "Family Accounts",
            description: "Manage investments for your whole family",
            iconName: "person.3.fill",
            category: .family
        ),
        OnboardingFeature(
            title: "Custodial Accounts",
            description: "Set up accounts for minors with appropriate controls",
            iconName: "figure.and.child.holdinghands",
            category: .family
        ),
        OnboardingFeature(
            title: "Permission Controls",
            description: "Control who can view or manage family portfolios",
            iconName: "lock.shield.fill",
            category: .family
        ),

        // AI Insights Features
        OnboardingFeature(
            title: "AI-Powered Insights",
            description: "Get personalized investment recommendations",
            iconName: "brain.head.profile",
            category: .insights
        ),
        OnboardingFeature(
            title: "Goal Analysis",
            description: "AI evaluates your goal feasibility and suggests optimizations",
            iconName: "sparkles",
            category: .insights
        ),
        OnboardingFeature(
            title: "Portfolio Health",
            description: "Receive alerts about portfolio diversification and risk",
            iconName: "heart.text.square.fill",
            category: .insights
        )
    ]

    static func features(for category: FeatureCategory) -> [OnboardingFeature] {
        allFeatures.filter { $0.category == category }
    }
}
