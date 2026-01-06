//
//  InsightCardView.swift
//  Growfolio
//
//  Individual insight card for portfolio analysis.
//

import SwiftUI

struct InsightCardView: View {

    // MARK: - Properties

    let insight: AIInsight
    let onAction: (() -> Void)?
    let onDismiss: (() -> Void)?

    // MARK: - Initialization

    init(
        insight: AIInsight,
        onAction: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.insight = insight
        self.onAction = onAction
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                // Icon
                iconView

                // Title and Type
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(insight.type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if insight.priority >= .high {
                            priorityBadge
                        }
                    }

                    Text(insight.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                // Dismiss button
                if onDismiss != nil {
                    Button {
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(6)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Content
            Text(insight.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // Action Button
            if let action = insight.action {
                Button {
                    onAction?()
                } label: {
                    HStack {
                        Text(action.label)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color(hex: insight.type.colorHex) ?? .accentColor)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color(hex: insight.type.colorHex).opacity(0.3),
                    lineWidth: insight.priority >= .high ? 2 : 0
                )
        )
    }

    // MARK: - Icon View

    private var iconView: some View {
        ZStack {
            Circle()
                .fill((Color(hex: insight.type.colorHex) ?? .accentColor).opacity(0.15))
                .frame(width: 40, height: 40)

            Image(systemName: insight.type.iconName)
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: insight.type.colorHex) ?? .accentColor)
        }
    }

    // MARK: - Priority Badge

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: insight.priority == .critical ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                .font(.caption2)

            Text(insight.priority.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(insight.priority == .critical ? Color.negative : Color.warning)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (insight.priority == .critical ? Color.red : Color.orange).opacity(0.1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Mini Insight Card

/// Compact version of the insight card for dashboard widgets
struct MiniInsightCardView: View {

    let insight: AIInsight
    let onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill((Color(hex: insight.type.colorHex) ?? .accentColor).opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: insight.type.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: insight.type.colorHex) ?? .accentColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(insight.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Health Score Card

struct HealthScoreCardView: View {

    let score: Int
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            // Score Circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 100, height: 100)

                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                // Score text
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(color)

                    Text("/ 100")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 4) {
                Text("Portfolio Health")
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(color)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Stock Explanation Card

struct StockExplanationCardView: View {

    let explanation: StockExplanation
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(explanation.symbol)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("AI Explanation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Content
            ScrollView {
                Text(explanation.explanation)
                    .font(.body)
                    .foregroundStyle(.primary)
            }

            // Disclaimer
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.caption)

                Text("This is educational content, not financial advice.")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Preview

#Preview("Insight Card") {
    VStack(spacing: 16) {
        InsightCardView(
            insight: AIInsight(
                type: .diversification,
                title: "Consider Diversifying Your Portfolio",
                content: "Your portfolio is heavily concentrated in tech stocks. Consider adding exposure to other sectors to reduce risk.",
                priority: .high,
                action: InsightAction(type: .viewPortfolio, label: "View Portfolio", destination: nil)
            )
        )

        InsightCardView(
            insight: AIInsight(
                type: .milestone,
                title: "Congratulations!",
                content: "You've reached 50% of your retirement goal. Keep up the great work!",
                priority: .medium
            )
        )
    }
    .padding()
}

#Preview("Health Score") {
    HealthScoreCardView(score: 75, description: "Good", color: Color.growthGreen)
        .padding()
}

#Preview("Mini Insight") {
    MiniInsightCardView(
        insight: AIInsight(
            type: .tip,
            title: "Dollar Cost Averaging",
            content: "Regular investing can help reduce the impact of volatility"
        ),
        onTap: nil
    )
    .padding()
}
