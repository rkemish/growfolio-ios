//
//  DCASchedulesView.swift
//  Growfolio
//
//  Main DCA schedules list view.
//

import SwiftUI

struct DCASchedulesView: View {

    // MARK: - Properties

    @State private var viewModel = DCAViewModel()
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(NavigationState.self) private var navState: NavigationState?

    // MARK: - Body

    /// Check if we're in iPad split view mode (navState available means iPad)
    private var isIPad: Bool {
        navState != nil
    }

    var body: some View {
        Group {
            if isIPad {
                dcaMainContent
            } else {
                NavigationStack {
                    dcaMainContent
                }
            }
        }
    }

    private var dcaMainContent: some View {
        ZStack {
            if viewModel.isLoading && viewModel.schedules.isEmpty {
                loadingView
            } else if viewModel.isEmpty {
                emptyStateView
            } else {
                schedulesListView
            }
        }
        .navigationTitle("DCA Schedules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.showCreateSchedule = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    sortMenu
                    filterMenu
                    Divider()
                    Toggle("Show Inactive", isOn: $viewModel.showInactive)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .refreshable {
            await viewModel.refreshSchedules()
        }
        .task {
            await viewModel.loadSchedules()
        }
        .sheet(isPresented: $viewModel.showCreateSchedule) {
            CreateDCAScheduleView(
                scheduleToEdit: viewModel.scheduleToEdit,
                onSave: { symbol, amount, frequency, startDate, endDate, portfolioId in
                    Task {
                        do {
                            if let editSchedule = viewModel.scheduleToEdit {
                                var updated = editSchedule
                                updated.amount = amount
                                updated.frequency = frequency
                                updated.endDate = endDate
                                try await viewModel.updateSchedule(updated)
                            } else {
                                try await viewModel.createSchedule(
                                    stockSymbol: symbol,
                                    amount: amount,
                                    frequency: frequency,
                                    startDate: startDate,
                                    endDate: endDate,
                                    portfolioId: portfolioId
                                )
                            }
                            viewModel.showCreateSchedule = false
                            viewModel.scheduleToEdit = nil
                        } catch {
                            // Handle error
                        }
                    }
                },
                onCancel: {
                    viewModel.showCreateSchedule = false
                    viewModel.scheduleToEdit = nil
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { navState == nil && viewModel.showScheduleDetail },
            set: { viewModel.showScheduleDetail = $0 }
        )) {
            if let schedule = viewModel.selectedSchedule {
                DCAScheduleDetailView(
                    schedule: schedule,
                    onEdit: {
                        viewModel.showScheduleDetail = false
                        viewModel.editSchedule(schedule)
                    },
                    onPauseResume: {
                        Task {
                            if schedule.isPaused {
                                try? await viewModel.resumeSchedule(schedule)
                            } else {
                                try? await viewModel.pauseSchedule(schedule)
                            }
                            viewModel.showScheduleDetail = false
                        }
                    },
                    onDelete: {
                        Task {
                            try? await viewModel.deleteSchedule(schedule)
                            viewModel.showScheduleDetail = false
                        }
                    }
                )
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading schedules...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No DCA Schedules", systemImage: "arrow.triangle.2.circlepath")
        } description: {
            VStack(spacing: 16) {
                Text("Dollar-Cost Averaging helps you invest consistently, reducing the impact of market volatility.")
                    .multilineTextAlignment(.center)

                // Educational steps
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "1.circle.fill")
                            .foregroundStyle(Color.prosperityGold)
                        Text("Choose a stock and investment amount")
                            .font(.subheadline)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "2.circle.fill")
                            .foregroundStyle(Color.prosperityGold)
                        Text("Set your frequency (daily, weekly, monthly)")
                            .font(.subheadline)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "3.circle.fill")
                            .foregroundStyle(Color.prosperityGold)
                        Text("Sit back and let automation build your wealth")
                            .font(.subheadline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        } actions: {
            Button {
                viewModel.showCreateSchedule = true
            } label: {
                Text("Create Your First Schedule")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Schedules List

    private var schedulesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Summary Card
                summaryCard

                // Upcoming Executions
                if !viewModel.upcomingExecutions.isEmpty {
                    upcomingSection
                }

                // Schedules List
                ForEach(viewModel.filteredSchedules) { schedule in
                    DCAScheduleRow(schedule: schedule)
                        .onTapGesture {
                            if let navState = navState {
                                // iPad: Update navigation state
                                navState.selectedSchedule = schedule
                            } else {
                                // iPhone: Show sheet
                                viewModel.selectSchedule(schedule)
                            }
                        }
                        .contextMenu {
                            scheduleContextMenu(for: schedule)
                        }
                }
            }
            .padding()
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Investment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(viewModel.totalMonthlyInvestment.currencyString)
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(Color.positive)
                        Text("\(viewModel.activeSchedulesCount) Active")
                    }
                    .font(.subheadline)

                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                            .foregroundStyle(Color.trustBlue)
                        Text(viewModel.summary.totalInvested.currencyString)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .glassCard(material: .regular, cornerRadius: Constants.UI.glassCornerRadius)
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(viewModel.upcomingExecutions) { schedule in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(schedule.stockSymbol)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if let name = schedule.stockName {
                            Text(name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(schedule.amount.currencyString)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        if let nextDate = schedule.nextExecutionDate {
                            Text(nextDate.relativeString)
                                .font(.caption)
                                .foregroundStyle(Color.trustBlue)
                        }
                    }
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Menus

    private var sortMenu: some View {
        Menu("Sort By") {
            ForEach(DCASortOrder.allCases, id: \.self) { order in
                Button {
                    viewModel.sortOrder = order
                } label: {
                    HStack {
                        Text(order.displayName)
                        if viewModel.sortOrder == order {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }

    private var filterMenu: some View {
        Menu("Filter by Frequency") {
            Button("All Frequencies") {
                viewModel.filterFrequency = nil
            }
            Divider()
            ForEach(DCAFrequency.allCases, id: \.self) { frequency in
                Button {
                    viewModel.filterFrequency = frequency
                } label: {
                    HStack {
                        Text(frequency.displayName)
                        if viewModel.filterFrequency == frequency {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }

    private func scheduleContextMenu(for schedule: DCASchedule) -> some View {
        Group {
            Button {
                viewModel.editSchedule(schedule)
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            if schedule.isPaused {
                Button {
                    Task {
                        try? await viewModel.resumeSchedule(schedule)
                    }
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
            } else if schedule.isActive {
                Button {
                    Task {
                        try? await viewModel.pauseSchedule(schedule)
                    }
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
            }

            Divider()

            Button(role: .destructive) {
                Task {
                    try? await viewModel.deleteSchedule(schedule)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - DCA Schedule Row

struct DCAScheduleRow: View {
    let schedule: DCASchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Symbol and Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.stockSymbol)
                        .font(.headline)

                    if let name = schedule.stockName {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Status badge
                statusBadge
            }

            // Amount and Frequency
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(schedule.amount.currencyString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Frequency")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(schedule.frequency.shortName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Invested")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(schedule.totalInvested.currencyString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Next Execution
            if schedule.status == .active, let nextDate = schedule.nextExecutionDate {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(Color.trustBlue)

                    Text("Next: \(nextDate.displayString)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(schedule.executionCount) executions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .glassCard(material: .regular, cornerRadius: Constants.UI.glassCornerRadius)
        .opacity(schedule.isPaused || !schedule.isActive ? 0.7 : 1.0)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: schedule.status.iconName)
            Text(schedule.status.displayName)
        }
        .font(.caption2)
        .fontWeight(.medium)
        .glassBadge(tintColor: Color(hex: schedule.status.colorHex))
        .foregroundStyle(Color(hex: schedule.status.colorHex))
    }
}

// MARK: - Preview

#Preview {
    DCASchedulesView()
}
