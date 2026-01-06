//
//  AIChatView.swift
//  Growfolio
//
//  Full chat interface with AI assistant.
//

import SwiftUI

struct AIChatView: View {

    // MARK: - Properties

    @State private var viewModel = AIChatViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isEmpty {
                    emptyState
                } else {
                    messageList
                }

                ChatInputView(
                    text: $viewModel.inputText,
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.sendMessage()
                    }
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.clearConversation()
                        } label: {
                            Label("Clear Conversation", systemImage: "trash")
                        }

                        Toggle(isOn: $viewModel.includePortfolioContext) {
                            Label("Include Portfolio Context", systemImage: "chart.pie")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("Retry") {
                    Task {
                        await viewModel.retryLastMessage()
                    }
                }
                Button("OK", role: .cancel) {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.trustBlue, Color.growthGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 8) {
                        Text("Growfolio AI")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Your personal investment assistant. Ask me anything about your portfolio, investing strategies, or financial goals.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 40)

                // Suggested Prompts
                VStack(alignment: .leading, spacing: 16) {
                    Text("Try asking about...")
                        .font(.headline)
                        .padding(.horizontal)

                    SuggestedPromptsView(prompts: viewModel.suggestedPrompts) { prompt in
                        Task {
                            await viewModel.sendPrompt(prompt)
                        }
                    }
                    .padding(.horizontal)
                }

                // Disclaimer
                disclaimerView
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.messages) { message in
                        ChatMessageView(message: message) { action in
                            Task {
                                await viewModel.handleSuggestedAction(action)
                            }
                        }
                        .id(message.id)
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Scroll to bottom when new messages arrive
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimerView: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("AI responses are for educational purposes only and should not be considered financial advice.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Chat View Button

/// Button to open the AI chat from other views
struct AIChatButton: View {

    @State private var showChat = false

    var body: some View {
        Button {
            showChat = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Ask AI")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color.trustBlue, Color.growthGreen],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .sheet(isPresented: $showChat) {
            AIChatView()
        }
    }
}

// MARK: - Floating Chat Button

/// Floating action button for AI chat
struct FloatingAIChatButton: View {

    @State private var showChat = false

    var body: some View {
        Button {
            showChat = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.trustBlue, Color.growthGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.trustBlue.opacity(0.3), radius: 10, x: 0, y: 5)

                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showChat) {
            AIChatView()
        }
    }
}

// MARK: - Preview

#Preview("Chat View") {
    AIChatView()
}

#Preview("Chat Button") {
    AIChatButton()
}

#Preview("Floating Button") {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingAIChatButton()
                    .padding()
            }
        }
    }
}
