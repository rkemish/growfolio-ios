//
//  FamilyGoalsView.swift
//  Growfolio
//
//  View displaying family shared goals overview and progress.
//

import SwiftUI

struct FamilyGoalsView: View {

    // MARK: - Properties

    let goalsOverview: FamilyGoalsOverview

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Overall Progress Card
                    overallProgressCard

                    // Goals Summary
                    goalsSummaryCard

                    // Member Progress
                    memberProgressSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Family Goals")
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

    // MARK: - Overall Progress Card

    private var overallProgressCard: some View {
        VStack(spacing: 20) {
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: goalsOverview.overallProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.trustBlue, Color.growthGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(goalsOverview.overallProgress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Overall")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Amount Progress
            VStack(spacing: 8) {
                HStack {
                    Text(goalsOverview.totalCurrentAmount.currencyString)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("of")
                        .foregroundStyle(.secondary)

                    Text(goalsOverview.totalTargetAmount.currencyString)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                ProgressView(value: goalsOverview.overallProgress, total: 1.0)
                    .tint(Color.trustBlue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Goals Summary Card

    private var goalsSummaryCard: some View {
        HStack(spacing: 0) {
            summaryItem(
                value: "\(goalsOverview.totalGoals)",
                label: "Total Goals",
                color: Color.trustBlue
            )

            Divider()
                .frame(height: 40)

            summaryItem(
                value: "\(goalsOverview.completedGoals)",
                label: "Completed",
                color: Color.growthGreen
            )

            Divider()
                .frame(height: 40)

            summaryItem(
                value: "\(goalsOverview.goalsOnTrack)",
                label: "On Track",
                color: Color.prosperityGold
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func summaryItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Member Progress Section

    private var memberProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Member Progress")
                .font(.headline)

            ForEach(goalsOverview.memberGoals) { memberGoal in
                memberGoalCard(memberGoal)
            }
        }
    }

    private func memberGoalCard(_ memberGoal: MemberGoalSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Member Header
            HStack(spacing: 12) {
                // Avatar
                if let pictureUrl = memberGoal.memberPictureUrl, let url = URL(string: pictureUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        initialsAvatar(for: memberGoal.memberName)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    initialsAvatar(for: memberGoal.memberName)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(memberGoal.memberName)
                        .font(.headline)

                    Text("\(memberGoal.goals.count) goal\(memberGoal.goals.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Progress Badge
                Text("\(Int(memberGoal.totalProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(progressColor(for: memberGoal.totalProgress).opacity(0.2))
                    .foregroundStyle(progressColor(for: memberGoal.totalProgress))
                    .clipShape(Capsule())
            }

            // Goals List
            ForEach(memberGoal.goals) { goal in
                goalRow(goal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func goalRow(_ goal: GoalSummaryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name)
                    .font(.subheadline)

                Spacer()

                HStack(spacing: 4) {
                    if goal.isOnTrack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.positive)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(Color.prosperityGold)
                    }

                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            ProgressView(value: goal.progress, total: 1.0)
                .tint(goal.isOnTrack ? Color.positive : Color.warning)

            HStack {
                Text(goal.currentAmount.currencyString)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(goal.targetAmount.currencyString)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func initialsAvatar(for name: String) -> some View {
        let components = name.components(separatedBy: " ")
        let initials = (components.first?.prefix(1) ?? "") + (components.last?.prefix(1) ?? "")

        return Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay {
                Text(initials.uppercased())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.trustBlue)
            }
    }

    private func progressColor(for progress: Double) -> Color {
        switch progress {
        case 0..<0.25:
            return Color.negative
        case 0.25..<0.5:
            return Color.warning
        case 0.5..<0.75:
            return .yellow
        default:
            return Color.positive
        }
    }
}

// MARK: - Preview

#Preview {
    FamilyGoalsView(
        goalsOverview: FamilyGoalsOverview(
            familyId: "preview",
            totalGoals: 5,
            completedGoals: 2,
            totalTargetAmount: 500000,
            totalCurrentAmount: 175000,
            memberGoals: [
                MemberGoalSummary(
                    memberId: "1",
                    memberName: "John Smith",
                    memberPictureUrl: nil,
                    goals: [
                        GoalSummaryItem(
                            id: "g1",
                            name: "Retirement Fund",
                            targetAmount: 200000,
                            currentAmount: 75000,
                            progress: 0.375,
                            isOnTrack: true,
                            targetDate: nil
                        ),
                        GoalSummaryItem(
                            id: "g2",
                            name: "Emergency Fund",
                            targetAmount: 50000,
                            currentAmount: 45000,
                            progress: 0.9,
                            isOnTrack: true,
                            targetDate: nil
                        )
                    ],
                    totalProgress: 0.52
                ),
                MemberGoalSummary(
                    memberId: "2",
                    memberName: "Jane Smith",
                    memberPictureUrl: nil,
                    goals: [
                        GoalSummaryItem(
                            id: "g3",
                            name: "House Down Payment",
                            targetAmount: 100000,
                            currentAmount: 30000,
                            progress: 0.3,
                            isOnTrack: false,
                            targetDate: nil
                        )
                    ],
                    totalProgress: 0.3
                )
            ]
        )
    )
}
