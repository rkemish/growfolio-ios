//
//  SuggestedActionsView.swift
//  Growfolio
//
//  Tappable action chips for AI suggested actions.
//

import SwiftUI

struct SuggestedActionsView: View {

    // MARK: - Properties

    let actions: [String]
    let onActionTap: ((String) -> Void)?

    // MARK: - Initialization

    init(actions: [String], onActionTap: ((String) -> Void)? = nil) {
        self.actions = actions
        self.onActionTap = onActionTap
    }

    // MARK: - Body

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(actions, id: \.self) { action in
                actionChip(action)
            }
        }
    }

    // MARK: - Action Chip

    private func actionChip(_ action: String) -> some View {
        Button {
            onActionTap?(action)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: iconForAction(action))
                    .font(.caption)

                Text(action)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Icon Mapping

    private func iconForAction(_ action: String) -> String {
        let lowercased = action.lowercased()

        if lowercased.contains("dca") || lowercased.contains("schedule") {
            return "arrow.triangle.2.circlepath"
        } else if lowercased.contains("goal") {
            return "target"
        } else if lowercased.contains("portfolio") || lowercased.contains("diversif") {
            return "chart.pie"
        } else if lowercased.contains("learn") || lowercased.contains("more") {
            return "book"
        } else if lowercased.contains("stock") || lowercased.contains("invest") {
            return "chart.line.uptrend.xyaxis"
        } else if lowercased.contains("risk") || lowercased.contains("alert") {
            return "exclamationmark.shield"
        } else {
            return "sparkles"
        }
    }
}

// MARK: - Flow Layout

/// A layout that arranges views in a flowing manner, wrapping to new lines as needed
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = calculateLayout(subviews: subviews, proposal: proposal)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = calculateLayout(subviews: subviews, proposal: proposal)

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func calculateLayout(subviews: Subviews, proposal: ProposedViewSize) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        totalHeight = currentY + lineHeight

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

// MARK: - Suggested Prompts View

struct SuggestedPromptsView: View {

    // MARK: - Properties

    let prompts: [SuggestedPrompt]
    let onPromptTap: (String) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            ForEach(prompts) { prompt in
                promptButton(prompt)
            }
        }
    }

    private func promptButton(_ prompt: SuggestedPrompt) -> some View {
        Button {
            onPromptTap(prompt.prompt)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: prompt.icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(prompt.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(prompt.prompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
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

// MARK: - Preview

#Preview("Suggested Actions") {
    SuggestedActionsView(
        actions: [
            "Set up a DCA schedule",
            "Review portfolio diversification",
            "Create your first investment goal"
        ]
    )
    .padding()
}

#Preview("Suggested Prompts") {
    SuggestedPromptsView(
        prompts: [
            SuggestedPrompt(icon: "chart.pie.fill", title: "Portfolio Analysis", prompt: "Can you analyze my portfolio?"),
            SuggestedPrompt(icon: "arrow.triangle.2.circlepath", title: "DCA Strategy", prompt: "What is dollar cost averaging?"),
            SuggestedPrompt(icon: "target", title: "Goal Planning", prompt: "Help me set up investment goals")
        ],
        onPromptTap: { _ in }
    )
    .padding()
}
