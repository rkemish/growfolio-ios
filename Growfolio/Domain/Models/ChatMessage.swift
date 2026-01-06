//
//  ChatMessage.swift
//  Growfolio
//
//  Chat message model for AI conversations.
//

import Foundation

/// Represents a message in an AI chat conversation
struct ChatMessage: Identifiable, Codable, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Message role (user or assistant)
    let role: MessageRole

    /// Message content
    let content: String

    /// Timestamp when the message was created
    let timestamp: Date

    /// Whether the message is still being generated (for streaming)
    var isStreaming: Bool

    /// Suggested actions (only for assistant messages)
    var suggestedActions: [String]?

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        suggestedActions: [String]? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.suggestedActions = suggestedActions
    }

    // MARK: - Convenience Initializers

    /// Create a user message
    static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: .user, content: content)
    }

    /// Create an assistant message
    static func assistant(_ content: String, suggestedActions: [String]? = nil) -> ChatMessage {
        ChatMessage(role: .assistant, content: content, suggestedActions: suggestedActions)
    }

    /// Create a streaming assistant message (typing indicator)
    static func streaming() -> ChatMessage {
        ChatMessage(role: .assistant, content: "", isStreaming: true)
    }

    // MARK: - Computed Properties

    /// Whether this is a user message
    var isUser: Bool {
        role == .user
    }

    /// Whether this is an assistant message
    var isAssistant: Bool {
        role == .assistant
    }

    /// Formatted timestamp
    var formattedTime: String {
        timestamp.shortTimeString
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case timestamp
        case isStreaming
        case suggestedActions
    }
}

// MARK: - Message Role

/// Role of a chat message sender
enum MessageRole: String, Codable, Sendable {
    case user
    case assistant

    var displayName: String {
        switch self {
        case .user:
            return "You"
        case .assistant:
            return "Growfolio AI"
        }
    }
}

// MARK: - Chat Conversation

/// Represents a chat conversation
struct ChatConversation: Identifiable, Codable, Sendable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Conversation title (generated from first message)
    var title: String

    /// Messages in the conversation
    var messages: [ChatMessage]

    /// Date when the conversation was created
    let createdAt: Date

    /// Date when the conversation was last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        title: String = "New Conversation",
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Last message in the conversation
    var lastMessage: ChatMessage? {
        messages.last
    }

    /// Number of messages
    var messageCount: Int {
        messages.count
    }

    /// Whether the conversation is empty
    var isEmpty: Bool {
        messages.isEmpty
    }

    /// Preview text for the conversation
    var preview: String {
        lastMessage?.content.prefix(100).description ?? "No messages"
    }

    // MARK: - Methods

    /// Add a message to the conversation
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        updatedAt = Date()

        // Update title from first user message
        if messages.count == 1 && message.isUser {
            title = String(message.content.prefix(50))
        }
    }

    /// Convert to API format for sending conversation history
    func toAPIHistory() -> [[String: String]] {
        messages.map { ["role": $0.role.rawValue, "content": $0.content] }
    }
}

// MARK: - Date Extension

private extension Date {
    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
