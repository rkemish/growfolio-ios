//
//  DashboardView.swift
//  Growfolio
//
//  Main dashboard view showing portfolio overview and key metrics.
//

import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @Environment(AuthService.self) private var authService
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader

                    // Market Status
                    marketStatusSection

                    // Portfolio Summary Card
                    portfolioSummaryCard

                    // Quick Actions
                    quickActionsSection

                    // Goals Progress
                    goalsProgressSection

                    // DCA Schedules
                    dcaSchedulesSection

                    // Recent Activity
                    recentActivitySection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refreshDataAsync()
            }
            .task {
                await viewModel.loadDashboardData()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(.title2)
                    .fontWeight(.bold)

                if let userName = authService.currentUser?.name {
                    Text(userName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Theme Toggle
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isDarkMode.toggle()
                }
            } label: {
                Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.title3)
                    .foregroundStyle(isDarkMode ? .yellow : Color.trustBlue)
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Profile Avatar
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    if let user = authService.currentUser {
                        Text(user.name?.prefix(1).uppercased() ?? "U")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.subheadline)
                            .foregroundStyle(Color.accentColor)
                    }
                }
        }
        .padding(.top, 8)
    }

    // MARK: - Market Status Section

    private var marketStatusSection: some View {
        MarketStatusCard(marketHours: viewModel.marketHours)
    }

    // MARK: - Portfolio Summary Card

    private var portfolioSummaryCard: some View {
        VStack(spacing: 16) {
            // Total Value
            VStack(spacing: 4) {
                Text("Total Portfolio Value")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text(viewModel.totalPortfolioValue.currencyString)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
            }

            // Performance
            HStack(spacing: 24) {
                performanceMetric(
                    title: "Today",
                    value: viewModel.todaysChange,
                    percentage: viewModel.todaysChangePercent
                )

                Divider()
                    .frame(height: 40)

                performanceMetric(
                    title: "Total Return",
                    value: viewModel.totalReturn,
                    percentage: viewModel.totalReturnPercent
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.largeCornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private func performanceMetric(title: String, value: Decimal, percentage: Decimal) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 4) {
                Image(systemName: percentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)

                Text(value.currencyString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(percentage >= 0 ? Color.positive : Color.negative)

            Text(percentage >= 0 ? "+\(percentage.rounded(places: 2))%" : "\(percentage.rounded(places: 2))%")
                .font(.caption)
                .foregroundStyle(percentage >= 0 ? Color.positive : Color.negative)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    quickActionButton(
                        title: "Add Goal",
                        icon: "plus.circle.fill",
                        color: Color.trustBlue
                    ) {
                        viewModel.showAddGoal = true
                    }

                    quickActionButton(
                        title: "New DCA",
                        icon: "arrow.triangle.2.circlepath.circle.fill",
                        color: Color.trustBlue
                    ) {
                        viewModel.showAddDCA = true
                    }

                    quickActionButton(
                        title: "Record Trade",
                        icon: "arrow.left.arrow.right.circle.fill",
                        color: Color.growthGreen
                    ) {
                        viewModel.showRecordTrade = true
                    }

                    quickActionButton(
                        title: "Deposit",
                        icon: "plus.square.fill",
                        color: Color.prosperityGold
                    ) {
                        viewModel.showDeposit = true
                    }
                }
            }
        }
    }

    private func quickActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(width: 80, height: 80)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Goals Progress

    private var goalsProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goals Progress")
                    .font(.headline)

                Spacer()

                NavigationLink {
                    GoalsView()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }

            if viewModel.topGoals.isEmpty {
                emptyStateCard(
                    icon: "target",
                    title: "No Goals Yet",
                    message: "Create your first investment goal to get started"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.topGoals) { goal in
                        GoalProgressRow(goal: goal)
                    }
                }
            }
        }
    }

    // MARK: - DCA Schedules

    private var dcaSchedulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active DCA Schedules")
                    .font(.headline)

                Spacer()

                NavigationLink {
                    DCASchedulesView()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }

            if viewModel.activeDCASchedules.isEmpty {
                emptyStateCard(
                    icon: "arrow.triangle.2.circlepath",
                    title: "No Active Schedules",
                    message: "Set up dollar-cost averaging to invest automatically"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.activeDCASchedules) { schedule in
                        DashboardDCAScheduleRow(schedule: schedule)
                    }
                }
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)

                Spacer()

                NavigationLink {
                    AllActivityView()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }

            if viewModel.recentActivity.isEmpty {
                emptyStateCard(
                    icon: "clock",
                    title: "No Recent Activity",
                    message: "Your investment activities will appear here"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentActivity) { entry in
                        ActivityRow(entry: entry)
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private func emptyStateCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
}

// MARK: - Supporting Row Views

struct GoalProgressRow: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goal.category.iconName)
                    .foregroundStyle(Color(hex: goal.colorHex) ?? .accentColor)

                Text(goal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text("\(Int(goal.progressPercentage.doubleValue))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: goal.clampedProgress)
                .tint(Color(hex: goal.colorHex) ?? .accentColor)

            HStack {
                Text(goal.currentAmount.currencyString)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(goal.targetAmount.currencyString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
}

private struct DashboardDCAScheduleRow: View {
    let schedule: DCASchedule

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(schedule.stockSymbol.prefix(2))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.prosperityGold)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(schedule.amount.currencyString) \(schedule.frequency.shortName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let nextDate = schedule.nextExecutionDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Next")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(nextDate.shortDateString)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
    }
}

struct ActivityRow: View {
    let entry: LedgerEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.type.iconName)
                .foregroundStyle(Color(hex: entry.type.colorHex) ?? .accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayDescription)
                    .font(.subheadline)

                Text(entry.transactionDate.relativeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.signPrefix)\(entry.totalAmount.currencyString)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(entry.type == .sell || entry.type == .deposit || entry.type == .dividend ? Color.positive : .primary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environment(AuthService.shared)
}
