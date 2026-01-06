//
//  GoalsView.swift
//  Growfolio
//
//  Main goals list view.
//

import SwiftUI

struct GoalsView: View {

    // MARK: - Properties

    @State private var viewModel = GoalsViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.goals.isEmpty {
                    loadingView
                } else if viewModel.isEmpty {
                    emptyStateView
                } else {
                    goalsListView
                }
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showCreateGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        sortMenu
                        filterMenu
                        Divider()
                        Toggle("Show Archived", isOn: $viewModel.showArchived)
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshGoals()
            }
            .task {
                await viewModel.loadGoals()
            }
            .sheet(isPresented: $viewModel.showCreateGoal) {
                CreateGoalView(
                    goalToEdit: viewModel.goalToEdit,
                    onSave: { name, amount, date, category, notes in
                        Task {
                            do {
                                if let editGoal = viewModel.goalToEdit {
                                    var updated = editGoal
                                    updated.name = name
                                    updated.targetAmount = amount
                                    updated.targetDate = date
                                    updated.notes = notes
                                    try await viewModel.updateGoal(updated)
                                } else {
                                    try await viewModel.createGoal(
                                        name: name,
                                        targetAmount: amount,
                                        targetDate: date,
                                        category: category,
                                        notes: notes
                                    )
                                }
                                viewModel.showCreateGoal = false
                                viewModel.goalToEdit = nil
                            } catch {
                                // Handle error
                            }
                        }
                    },
                    onCancel: {
                        viewModel.showCreateGoal = false
                        viewModel.goalToEdit = nil
                    }
                )
            }
            .sheet(isPresented: $viewModel.showGoalDetail) {
                if let goal = viewModel.selectedGoal {
                    GoalDetailView(
                        goal: goal,
                        onEdit: {
                            viewModel.showGoalDetail = false
                            viewModel.editGoal(goal)
                        },
                        onArchive: {
                            Task {
                                try? await viewModel.archiveGoal(goal)
                                viewModel.showGoalDetail = false
                            }
                        },
                        onDelete: {
                            Task {
                                try? await viewModel.deleteGoal(goal)
                                viewModel.showGoalDetail = false
                            }
                        },
                        positionsSummary: viewModel.selectedGoalPositions
                    )
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading goals...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Goals Yet", systemImage: "target")
        } description: {
            Text("Create your first investment goal to start tracking your progress.")
        } actions: {
            Button {
                viewModel.showCreateGoal = true
            } label: {
                Text("Create Goal")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Goals List

    private var goalsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Summary Card
                summaryCard

                // Goals List
                ForEach(viewModel.filteredGoals) { goal in
                    GoalRow(goal: goal)
                        .onTapGesture {
                            viewModel.selectGoal(goal)
                        }
                        .contextMenu {
                            goalContextMenu(for: goal)
                        }
                }
            }
            .padding()
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(Int(viewModel.summary.overallProgress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.positive)
                        Text("\(viewModel.achievedGoalsCount)")
                    }
                    .font(.subheadline)

                    HStack(spacing: 4) {
                        Image(systemName: "circle.lefthalf.filled")
                            .foregroundStyle(Color.trustBlue)
                        Text("\(viewModel.activeGoalsCount)")
                    }
                    .font(.subheadline)
                }
            }

            ProgressView(value: viewModel.summary.overallProgress, total: 1.0)
                .tint(Color.trustBlue)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Menus

    private var sortMenu: some View {
        Menu("Sort By") {
            ForEach(GoalSortOrder.allCases, id: \.self) { order in
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
        Menu("Filter by Category") {
            Button("All Categories") {
                viewModel.filterCategory = nil
            }
            Divider()
            ForEach(GoalCategory.allCases, id: \.self) { category in
                Button {
                    viewModel.filterCategory = category
                } label: {
                    HStack {
                        Image(systemName: category.iconName)
                        Text(category.displayName)
                        if viewModel.filterCategory == category {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }

    private func goalContextMenu(for goal: Goal) -> some View {
        Group {
            Button {
                viewModel.editGoal(goal)
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            if goal.isArchived {
                Button {
                    Task {
                        try? await viewModel.unarchiveGoal(goal)
                    }
                } label: {
                    Label("Unarchive", systemImage: "arrow.uturn.backward")
                }
            } else {
                Button {
                    Task {
                        try? await viewModel.archiveGoal(goal)
                    }
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
            }

            Divider()

            Button(role: .destructive) {
                Task {
                    try? await viewModel.deleteGoal(goal)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Goal Row

struct GoalRow: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: goal.colorHex).opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: goal.category.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: goal.colorHex))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.headline)

                    Text(goal.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status badge
                statusBadge
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(goal.currentAmount.currencyString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(goal.targetAmount.currencyString)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                ProgressView(value: goal.clampedProgress, total: 1.0)
                    .tint(Color(hex: goal.colorHex))
            }

            // Footer info
            HStack {
                if let targetDate = goal.targetDate {
                    Label(targetDate.displayString, systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(Int(goal.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(hex: goal.colorHex))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .opacity(goal.isArchived ? 0.6 : 1.0)
    }

    private var statusBadge: some View {
        Text(goal.status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: goal.status.colorHex).opacity(0.2))
            .foregroundStyle(Color(hex: goal.status.colorHex))
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    GoalsView()
}
