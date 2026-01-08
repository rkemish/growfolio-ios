//
//  OnboardingView.swift
//  Growfolio
//
//  Onboarding flow for new users.
//

import SwiftUI

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView(selection: $viewModel.currentPage) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                OnboardingPageView(page: page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: viewModel.currentPage)
        .overlay(alignment: .bottom) {
            bottomControls
        }
        .ignoresSafeArea()
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 24) {
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<viewModel.pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == viewModel.currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: viewModel.currentPage)
                }
            }

            // Buttons
            VStack(spacing: 12) {
                if viewModel.isLastPage {
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                    }
                } else {
                    Button {
                        viewModel.nextPage()
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
                    }
                }

                Button {
                    completeOnboarding()
                } label: {
                    Text(viewModel.isLastPage ? "" : "Skip")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(viewModel.isLastPage ? 0 : 1)
            }
            .padding(.horizontal, Constants.UI.standardPadding)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        viewModel.completeOnboarding()
        appState.hasCompletedOnboarding = true
        // In mock mode, go directly to main; otherwise go to authentication
        if MockConfiguration.shared.isEnabled {
            appState.currentFlow = .main
        } else {
            appState.currentFlow = .authentication
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon
            Image(systemName: page.iconName)
                .font(.system(size: 100))
                .foregroundStyle(page.iconColor)
                .symbolRenderingMode(.hierarchical)

            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color

    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Growfolio",
            description: "Your personal investment companion for smarter investing through Dollar-Cost Averaging. Set goals, automate investments, and grow your portfolio consistently.",
            iconName: "chart.line.uptrend.xyaxis.circle.fill",
            iconColor: Color.growthGreen
        ),
        OnboardingPage(
            title: "Automate Your Growth",
            description: "Set up recurring investments with Dollar-Cost Averaging. Define your financial goals and we'll help you reach them systematically, reducing market volatility impact.",
            iconName: "arrow.triangle.2.circlepath.circle.fill",
            iconColor: Color.prosperityGold
        ),
        OnboardingPage(
            title: "Built for Families",
            description: "Manage investments for your whole family. Create custodial accounts, teach children about investing, and grow wealth together.",
            iconName: "person.3.fill",
            iconColor: .pink
        )
    ]
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(AppState())
}
