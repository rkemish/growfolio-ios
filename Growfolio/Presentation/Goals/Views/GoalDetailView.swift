//
//  GoalDetailView.swift
//  Growfolio
//
//  Detailed view for a single goal.
//

import SwiftUI

struct GoalDetailView: View {

    // MARK: - Properties

    let goal: Goal
    let onEdit: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    var positionsSummary: GoalPositionsSummary?

    @Environment(\.dismiss) private var dismiss
    @State private var showAllPositions = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard

                    // Progress Section
                    progressSection

                    // Positions Section (if goal has linked DCA schedules)
                    if goal.hasLinkedDCASchedules, let summary = positionsSummary {
                        positionsSection(summary: summary)
                    }

                    // Details Section
                    detailsSection

                    // Actions Section
                    actionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(goal.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        if goal.isArchived {
                            Button {
                                // Unarchive would be handled here
                            } label: {
                                Label("Unarchive", systemImage: "arrow.uturn.backward")
                            }
                        } else {
                            Button {
                                onArchive()
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Goal", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: goal.colorHex).opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: goal.category.iconName)
                    .font(.system(size: 36))
                    .foregroundStyle(Color(hex: goal.colorHex))
            }

            // Category & Status
            HStack(spacing: 12) {
                Text(goal.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())

                Text(goal.status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: goal.status.colorHex).opacity(0.2))
                    .foregroundStyle(Color(hex: goal.status.colorHex))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.headline)

            // Progress Bar
            VStack(spacing: 8) {
                ProgressView(value: goal.clampedProgress, total: 1.0)
                    .tint(Color(hex: goal.colorHex))
                    .scaleEffect(y: 2)

                HStack {
                    Text(goal.currentAmount.currencyString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(goal.progress * 100))%")
                        .font(.headline)
                        .foregroundStyle(Color(hex: goal.colorHex))

                    Spacer()

                    Text(goal.targetAmount.currencyString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }

            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statCard(
                    title: "Remaining",
                    value: goal.remainingAmount.currencyString,
                    icon: "arrow.up.circle"
                )

                if let monthly = goal.estimatedMonthlyContribution {
                    statCard(
                        title: "Monthly Needed",
                        value: monthly.currencyString,
                        icon: "calendar.badge.clock"
                    )
                }

                if let days = goal.daysRemaining {
                    statCard(
                        title: "Days Left",
                        value: "\(days)",
                        icon: "clock"
                    )
                }

                if goal.isAchieved {
                    statCard(
                        title: "Status",
                        value: "Achieved!",
                        icon: "checkmark.circle.fill",
                        color: Color.growthGreen
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCard(
        title: String,
        value: String,
        icon: String,
        color: Color = Color.trustBlue
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Positions Section

    private func positionsSection(summary: GoalPositionsSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Positions")
                    .font(.headline)

                Spacer()

                Button {
                    showAllPositions = true
                } label: {
                    Text("See All")
                        .font(.subheadline)
                }
            }

            // Summary stats
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Market Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(summary.totalCurrentValue.currencyString)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Return")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: summary.isProfitable ? "arrow.up.right" : "arrow.down.right")
                        Text("\(summary.totalGain.currencyString) (\(summary.totalGainPercent.formatted(.number.precision(.fractionLength(2))))%)")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(summary.isProfitable ? Color.positive : Color.negative)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Position cards
            ForEach(summary.positions.prefix(3)) { position in
                positionCard(position: position)
            }

            if summary.positions.count > 3 {
                Button {
                    showAllPositions = true
                } label: {
                    Text("View all \(summary.positions.count) positions")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showAllPositions) {
            GoalPositionsView(goal: goal, positionsSummary: summary)
        }
    }

    private func positionCard(position: GoalPosition) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(position.stockSymbol)
                        .font(.headline)
                    Text(position.stockName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(position.currentValue.currencyString)
                        .font(.headline)
                    HStack(spacing: 2) {
                        Image(systemName: position.isProfitable ? "arrow.up.right" : "arrow.down.right")
                        Text("\(position.totalGainPercent.formatted(.number.precision(.fractionLength(2))))%")
                    }
                    .font(.caption)
                    .foregroundStyle(position.isProfitable ? Color.positive : Color.negative)
                }
            }

            HStack {
                Label("\(position.totalShares.formatted(.number.precision(.fractionLength(4)))) shares", systemImage: "chart.pie")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(position.purchases.count) purchases")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)

            VStack(spacing: 0) {
                detailRow(label: "Category", value: goal.category.displayName)

                Divider()

                if let targetDate = goal.targetDate {
                    detailRow(label: "Target Date", value: targetDate.displayString)
                    Divider()
                }

                detailRow(label: "Created", value: goal.createdAt.displayString)

                Divider()

                detailRow(label: "Last Updated", value: goal.updatedAt.displayString)

                if let notes = goal.notes, !notes.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(notes)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                onEdit()
            } label: {
                Label("Edit Goal", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if !goal.isArchived {
                Button {
                    onArchive()
                } label: {
                    Label("Archive Goal", systemImage: "archivebox")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    GoalDetailView(
        goal: Goal(
            id: "1",
            userId: "user1",
            name: "Retirement Fund",
            targetAmount: 1_000_000,
            currentAmount: 125_432.87,
            targetDate: Date().adding(years: 25),
            category: .retirement,
            colorHex: "#FF9500"
        ),
        onEdit: {},
        onArchive: {},
        onDelete: {}
    )
}
