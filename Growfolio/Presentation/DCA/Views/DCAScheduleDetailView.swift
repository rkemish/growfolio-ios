//
//  DCAScheduleDetailView.swift
//  Growfolio
//
//  Detailed view for a single DCA schedule.
//

import SwiftUI

struct DCAScheduleDetailView: View {

    // MARK: - Properties

    let schedule: DCASchedule
    let onEdit: () -> Void
    let onPauseResume: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard

                    // Stats Section
                    statsSection

                    // Schedule Details
                    scheduleDetailsSection

                    // Execution History Placeholder
                    executionHistorySection

                    // Actions Section
                    actionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(schedule.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button {
                            onPauseResume()
                        } label: {
                            if schedule.isPaused {
                                Label("Resume", systemImage: "play.fill")
                            } else {
                                Label("Pause", systemImage: "pause.fill")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete Schedule", systemImage: "trash")
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
            // Symbol
            Text(schedule.stockSymbol)
                .font(.largeTitle)
                .fontWeight(.bold)

            if let name = schedule.stockName {
                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Status Badge
            HStack(spacing: 4) {
                Image(systemName: schedule.status.iconName)
                Text(schedule.status.displayName)
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: schedule.status.colorHex).opacity(0.2))
            .foregroundStyle(Color(hex: schedule.status.colorHex))
            .clipShape(Capsule())

            // Amount per execution
            VStack(spacing: 4) {
                Text(schedule.amount.currencyString)
                    .font(.title)
                    .fontWeight(.bold)

                Text(schedule.frequency.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statCard(
                    title: "Total Invested",
                    value: schedule.totalInvested.currencyString,
                    icon: "dollarsign.circle.fill",
                    color: Color.growthGreen
                )

                statCard(
                    title: "Executions",
                    value: "\(schedule.executionCount)",
                    icon: "arrow.triangle.2.circlepath",
                    color: Color.trustBlue
                )

                statCard(
                    title: "Avg/Execution",
                    value: schedule.averagePerExecution.currencyString,
                    icon: "chart.bar.fill",
                    color: Color.prosperityGold
                )

                statCard(
                    title: "Est. Annual",
                    value: schedule.estimatedAnnualInvestment.currencyString,
                    icon: "calendar",
                    color: Color.trustBlue
                )
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
        color: Color
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

    // MARK: - Schedule Details

    private var scheduleDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule Details")
                .font(.headline)

            VStack(spacing: 0) {
                detailRow(label: "Frequency", value: schedule.frequency.displayName)
                Divider()

                if let nextDate = schedule.nextExecutionDate {
                    detailRow(label: "Next Execution", value: nextDate.displayString)
                    Divider()
                }

                if let lastDate = schedule.lastExecutionDate {
                    detailRow(label: "Last Execution", value: lastDate.displayString)
                    Divider()
                }

                detailRow(label: "Start Date", value: schedule.startDate.displayString)
                Divider()

                if let endDate = schedule.endDate {
                    detailRow(label: "End Date", value: endDate.displayString)
                    Divider()
                }

                detailRow(label: "Created", value: schedule.createdAt.displayString)
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

    // MARK: - Execution History

    private var executionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Execution History")
                    .font(.headline)

                Spacer()

                Button("View All") {
                    // Navigate to full history
                }
                .font(.subheadline)
            }

            if schedule.executionCount == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title)
                        .foregroundStyle(.secondary)

                    Text("No executions yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                Text("Recent executions will appear here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                onEdit()
            } label: {
                Label("Edit Schedule", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                onPauseResume()
            } label: {
                if schedule.isPaused {
                    Label("Resume Schedule", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Pause Schedule", systemImage: "pause.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    DCAScheduleDetailView(
        schedule: DCASchedule(
            id: "1",
            userId: "user1",
            stockSymbol: "VOO",
            stockName: "Vanguard S&P 500 ETF",
            amount: 500,
            frequency: .monthly,
            nextExecutionDate: Date().adding(days: 5),
            portfolioId: "portfolio1",
            totalInvested: 6000,
            executionCount: 12
        ),
        onEdit: {},
        onPauseResume: {},
        onDelete: {}
    )
}
