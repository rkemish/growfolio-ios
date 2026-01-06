//
//  ChatMessageView.swift
//  Growfolio
//
//  Individual message bubble view for the AI chat.
//

import SwiftUI

struct ChatMessageView: View {

    // MARK: - Properties

    let message: ChatMessage
    let onSuggestedActionTap: ((String) -> Void)?

    // MARK: - Initialization

    init(message: ChatMessage, onSuggestedActionTap: ((String) -> Void)? = nil) {
        self.message = message
        self.onSuggestedActionTap = onSuggestedActionTap
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 60)
                userMessageContent
            } else {
                assistantMessageContent
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    // MARK: - User Message

    private var userMessageContent: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(ChatBubbleShape(isUser: true))

            Text(message.formattedTime)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Assistant Message

    private var assistantMessageContent: some View {
        HStack(alignment: .top, spacing: 8) {
            // AI Avatar
            aiAvatar

            VStack(alignment: .leading, spacing: 8) {
                if message.isStreaming {
                    typingIndicator
                } else {
                    // Message content
                    Text(message.content)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(ChatBubbleShape(isUser: false))

                    // Suggested actions
                    if let actions = message.suggestedActions, !actions.isEmpty {
                        SuggestedActionsView(actions: actions, onActionTap: onSuggestedActionTap)
                    }

                    // Timestamp
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - AI Avatar

    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.trustBlue, Color.growthGreen],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)

            Image(systemName: "sparkles")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(typingScale(for: index))
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: UUID()
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(ChatBubbleShape(isUser: false))
        .onAppear {
            // Trigger animation
        }
    }

    private func typingScale(for index: Int) -> CGFloat {
        // This creates a pulsing effect
        1.0
    }
}

// MARK: - Chat Bubble Shape

struct ChatBubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6

        var path = Path()

        if isUser {
            // User bubble - tail on right
            path.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
        } else {
            // Assistant bubble - tail on left
            path.addRoundedRect(
                in: CGRect(x: tailSize, y: 0, width: rect.width - tailSize, height: rect.height),
                cornerSize: CGSize(width: radius, height: radius)
            )
        }

        return path
    }
}

// MARK: - Animated Typing Indicator

struct AnimatedTypingIndicator: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 8, height: 8)
                    .offset(y: animationPhase == index ? -4 : 0)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Preview

#Preview("User Message") {
    ChatMessageView(
        message: ChatMessage.user("What's the best strategy for dollar cost averaging?")
    )
}

#Preview("Assistant Message") {
    ChatMessageView(
        message: ChatMessage.assistant(
            "Dollar cost averaging (DCA) is an investment strategy where you invest a fixed amount of money at regular intervals, regardless of the asset's price. This approach helps reduce the impact of volatility on your overall purchase.",
            suggestedActions: ["Set up DCA schedule", "Learn more about DCA"]
        )
    )
}

#Preview("Typing") {
    ChatMessageView(message: ChatMessage.streaming())
}
