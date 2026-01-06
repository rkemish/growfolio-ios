//
//  AIChatViewModel.swift
//  Growfolio
//
//  View model for the AI chat feature.
//

import Foundation
import SwiftUI

@Observable
final class AIChatViewModel: @unchecked Sendable {

    // MARK: - Dependencies

    private let aiRepository: AIRepositoryProtocol

    // MARK: - Properties

    // State
    var messages: [ChatMessage] = []
    var isLoading = false
    var isTyping = false
    var error: Error?
    var showError = false

    // Input
    var inputText = ""

    // Settings
    var includePortfolioContext = true

    // Suggested prompts for empty state
    let suggestedPrompts: [SuggestedPrompt] = [
        SuggestedPrompt(
            icon: "chart.pie.fill",
            title: "Portfolio Analysis",
            prompt: "Can you analyze my portfolio and give me feedback?"
        ),
        SuggestedPrompt(
            icon: "arrow.triangle.2.circlepath",
            title: "DCA Strategy",
            prompt: "What is dollar cost averaging and how should I use it?"
        ),
        SuggestedPrompt(
            icon: "target",
            title: "Goal Planning",
            prompt: "Help me set up investment goals for retirement"
        ),
        SuggestedPrompt(
            icon: "chart.line.uptrend.xyaxis",
            title: "Market Trends",
            prompt: "What are some general principles for long-term investing?"
        )
    ]

    // MARK: - Computed Properties

    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var isEmpty: Bool {
        messages.isEmpty
    }

    var lastAssistantMessage: ChatMessage? {
        messages.last { $0.isAssistant }
    }

    // MARK: - Initialization

    init(aiRepository: AIRepositoryProtocol = RepositoryContainer.aiRepository) {
        self.aiRepository = aiRepository
    }

    // MARK: - Public Methods

    /// Send a message to the AI
    @MainActor
    func sendMessage() async {
        let messageText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }

        // Clear input immediately
        inputText = ""

        // Add user message
        let userMessage = ChatMessage.user(messageText)
        messages.append(userMessage)

        // Show typing indicator
        isLoading = true
        isTyping = true

        // Add streaming placeholder
        let streamingMessage = ChatMessage.streaming()
        messages.append(streamingMessage)

        do {
            // Get conversation history (exclude the streaming placeholder)
            let history = messages.filter { !$0.isStreaming }

            // Send message to AI
            let response = try await aiRepository.sendMessage(
                messageText,
                conversationHistory: Array(history.dropLast()), // Exclude the user message we just added
                includePortfolioContext: includePortfolioContext
            )

            // Replace streaming placeholder with actual response
            if let index = messages.lastIndex(where: { $0.isStreaming }) {
                messages[index] = response
            }

        } catch {
            // Remove streaming placeholder
            messages.removeAll { $0.isStreaming }

            // Show error
            self.error = error
            self.showError = true
        }

        isLoading = false
        isTyping = false
    }

    /// Send a suggested prompt
    @MainActor
    func sendPrompt(_ prompt: String) async {
        inputText = prompt
        await sendMessage()
    }

    /// Handle suggested action tap
    @MainActor
    func handleSuggestedAction(_ action: String) async {
        // Convert action to a follow-up message
        inputText = "Tell me more about: \(action)"
        await sendMessage()
    }

    /// Clear conversation
    @MainActor
    func clearConversation() {
        messages.removeAll()
        error = nil
        showError = false
    }

    /// Retry last message
    @MainActor
    func retryLastMessage() async {
        // Find the last user message
        guard let lastUserMessage = messages.last(where: { $0.isUser }) else { return }

        // Remove the last user message and any following messages
        if let index = messages.lastIndex(where: { $0.id == lastUserMessage.id }) {
            messages.removeSubrange(index...)
        }

        // Resend
        inputText = lastUserMessage.content
        await sendMessage()
    }

    /// Dismiss error
    func dismissError() {
        showError = false
        error = nil
    }
}

// MARK: - Suggested Prompt

struct SuggestedPrompt: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let prompt: String
}
