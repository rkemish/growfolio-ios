//
//  ChatInputView.swift
//  Growfolio
//
//  Text input with send button for the AI chat.
//

import SwiftUI

struct ChatInputView: View {

    // MARK: - Properties

    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    // MARK: - Initialization

    init(
        text: Binding<String>,
        isLoading: Bool = false,
        onSend: @escaping () -> Void
    ) {
        self._text = text
        self.isLoading = isLoading
        self.onSend = onSend
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Text Field
            textField

            // Send Button
            sendButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
        )
    }

    // MARK: - Text Field

    private var textField: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask about investing...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit {
                    if canSend {
                        onSend()
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            if canSend {
                isFocused = false
                onSend()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(canSend ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(canSend ? .white : .gray)
                }
            }
        }
        .disabled(!canSend)
        .animation(.easeInOut(duration: 0.2), value: canSend)
    }

    // MARK: - Computed Properties

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

// MARK: - Preview

#Preview("Empty") {
    VStack {
        Spacer()
        ChatInputView(
            text: .constant(""),
            isLoading: false,
            onSend: {}
        )
    }
}

#Preview("With Text") {
    VStack {
        Spacer()
        ChatInputView(
            text: .constant("What's the best strategy for investing?"),
            isLoading: false,
            onSend: {}
        )
    }
}

#Preview("Loading") {
    VStack {
        Spacer()
        ChatInputView(
            text: .constant(""),
            isLoading: true,
            onSend: {}
        )
    }
}
