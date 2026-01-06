//
//  ChatMessageTests.swift
//  GrowfolioTests
//
//  Tests for ChatMessage domain model.
//

import XCTest
@testable import Growfolio

final class ChatMessageTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_WithDefaults() {
        let message = ChatMessage(role: .user, content: "Hello")

        XCTAssertFalse(message.id.isEmpty)
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hello")
        XCTAssertFalse(message.isStreaming)
        XCTAssertNil(message.suggestedActions)
    }

    func testInit_WithAllParameters() {
        let message = TestFixtures.chatMessage(
            id: "msg-456",
            role: .assistant,
            content: "How can I help?",
            isStreaming: false,
            suggestedActions: ["View Portfolio", "Set Up DCA"]
        )

        XCTAssertEqual(message.id, "msg-456")
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "How can I help?")
        XCTAssertFalse(message.isStreaming)
        XCTAssertEqual(message.suggestedActions?.count, 2)
        XCTAssertEqual(message.suggestedActions?[0], "View Portfolio")
        XCTAssertEqual(message.suggestedActions?[1], "Set Up DCA")
    }

    // MARK: - Convenience Initializer Tests

    func testUser_ConvenienceInitializer() {
        let message = ChatMessage.user("What should I invest in?")

        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "What should I invest in?")
        XCTAssertFalse(message.isStreaming)
        XCTAssertNil(message.suggestedActions)
    }

    func testAssistant_ConvenienceInitializer_WithoutActions() {
        let message = ChatMessage.assistant("Here are some suggestions...")

        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Here are some suggestions...")
        XCTAssertFalse(message.isStreaming)
        XCTAssertNil(message.suggestedActions)
    }

    func testAssistant_ConvenienceInitializer_WithActions() {
        let actions = ["Learn More", "View ETFs"]
        let message = ChatMessage.assistant("Consider ETFs for diversification", suggestedActions: actions)

        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Consider ETFs for diversification")
        XCTAssertEqual(message.suggestedActions, actions)
    }

    func testStreaming_ConvenienceInitializer() {
        let message = ChatMessage.streaming()

        XCTAssertEqual(message.role, .assistant)
        XCTAssertTrue(message.content.isEmpty)
        XCTAssertTrue(message.isStreaming)
    }

    // MARK: - Computed Properties Tests

    func testIsUser_UserRole_ReturnsTrue() {
        let message = TestFixtures.chatMessage(role: .user)

        XCTAssertTrue(message.isUser)
        XCTAssertFalse(message.isAssistant)
    }

    func testIsUser_AssistantRole_ReturnsFalse() {
        let message = TestFixtures.chatMessage(role: .assistant)

        XCTAssertFalse(message.isUser)
        XCTAssertTrue(message.isAssistant)
    }

    func testFormattedTime_ReturnsNonEmpty() {
        let message = TestFixtures.chatMessage()

        XCTAssertFalse(message.formattedTime.isEmpty)
    }

    // MARK: - MessageRole Tests

    func testMessageRole_DisplayName() {
        XCTAssertEqual(MessageRole.user.displayName, "You")
        XCTAssertEqual(MessageRole.assistant.displayName, "Growfolio AI")
    }

    func testMessageRole_RawValues() {
        XCTAssertEqual(MessageRole.user.rawValue, "user")
        XCTAssertEqual(MessageRole.assistant.rawValue, "assistant")
    }

    // MARK: - Mutable Properties Tests

    func testIsStreaming_Mutable() {
        var message = TestFixtures.chatMessage(isStreaming: true)

        XCTAssertTrue(message.isStreaming)

        message.isStreaming = false

        XCTAssertFalse(message.isStreaming)
    }

    func testSuggestedActions_Mutable() {
        var message = TestFixtures.chatMessage(suggestedActions: nil)

        XCTAssertNil(message.suggestedActions)

        message.suggestedActions = ["Action 1", "Action 2"]

        XCTAssertEqual(message.suggestedActions?.count, 2)
    }

    // MARK: - Codable Tests

    func testChatMessage_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.chatMessage(
            id: "msg-test",
            role: .assistant,
            content: "Test response",
            isStreaming: false,
            suggestedActions: ["Action 1", "Action 2"]
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(ChatMessage.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.role, original.role)
        XCTAssertEqual(decoded.content, original.content)
        XCTAssertEqual(decoded.isStreaming, original.isStreaming)
        XCTAssertEqual(decoded.suggestedActions, original.suggestedActions)
    }

    func testChatMessage_EncodeDecode_WithNilSuggestedActions() throws {
        let original = TestFixtures.chatMessage(suggestedActions: nil)

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(ChatMessage.self, from: data)

        XCTAssertNil(decoded.suggestedActions)
    }

    func testMessageRole_Codable() throws {
        let roles: [MessageRole] = [.user, .assistant]
        for role in roles {
            let data = try JSONEncoder().encode(role)
            let decoded = try JSONDecoder().decode(MessageRole.self, from: data)
            XCTAssertEqual(decoded, role)
        }
    }

    // MARK: - Equatable Tests

    func testChatMessage_Equatable() {
        let message1 = TestFixtures.chatMessage(id: "msg-1", content: "Hello")
        let message2 = TestFixtures.chatMessage(id: "msg-1", content: "Hello")
        let message3 = TestFixtures.chatMessage(id: "msg-2", content: "Different")

        XCTAssertEqual(message1, message2)
        XCTAssertNotEqual(message1, message3)
    }

    // MARK: - ChatConversation Tests

    func testChatConversation_Initialization() {
        let conversation = ChatConversation(
            id: "conv-1",
            title: "My Conversation",
            messages: []
        )

        XCTAssertEqual(conversation.id, "conv-1")
        XCTAssertEqual(conversation.title, "My Conversation")
        XCTAssertTrue(conversation.messages.isEmpty)
    }

    func testChatConversation_LastMessage() {
        let messages = [
            ChatMessage.user("First"),
            ChatMessage.assistant("Second")
        ]
        let conversation = ChatConversation(messages: messages)

        XCTAssertEqual(conversation.lastMessage?.content, "Second")
    }

    func testChatConversation_LastMessage_Empty() {
        let conversation = ChatConversation(messages: [])

        XCTAssertNil(conversation.lastMessage)
    }

    func testChatConversation_MessageCount() {
        let messages = [
            ChatMessage.user("One"),
            ChatMessage.assistant("Two"),
            ChatMessage.user("Three")
        ]
        let conversation = ChatConversation(messages: messages)

        XCTAssertEqual(conversation.messageCount, 3)
    }

    func testChatConversation_IsEmpty_True() {
        let conversation = ChatConversation(messages: [])

        XCTAssertTrue(conversation.isEmpty)
    }

    func testChatConversation_IsEmpty_False() {
        let conversation = ChatConversation(messages: [ChatMessage.user("Hello")])

        XCTAssertFalse(conversation.isEmpty)
    }

    func testChatConversation_Preview() {
        let message = ChatMessage.assistant("This is a preview of the conversation that might be quite long")
        let conversation = ChatConversation(messages: [message])

        XCTAssertFalse(conversation.preview.isEmpty)
        XCTAssertEqual(conversation.preview, message.content)
    }

    func testChatConversation_Preview_Empty() {
        let conversation = ChatConversation(messages: [])

        XCTAssertEqual(conversation.preview, "No messages")
    }

    func testChatConversation_Preview_LongMessage() {
        let longContent = String(repeating: "A", count: 200)
        let message = ChatMessage.assistant(longContent)
        let conversation = ChatConversation(messages: [message])

        XCTAssertTrue(conversation.preview.count <= 100)
    }

    func testChatConversation_AddMessage() {
        var conversation = ChatConversation()
        let message = ChatMessage.user("Hello")

        conversation.addMessage(message)

        XCTAssertEqual(conversation.messageCount, 1)
        XCTAssertEqual(conversation.messages.first?.content, "Hello")
    }

    func testChatConversation_AddMessage_UpdatesTitle() {
        var conversation = ChatConversation(title: "New Conversation")
        let message = ChatMessage.user("What is dollar cost averaging?")

        conversation.addMessage(message)

        XCTAssertEqual(conversation.title, "What is dollar cost averaging?")
    }

    func testChatConversation_AddMessage_TitleTruncation() {
        var conversation = ChatConversation()
        let longContent = String(repeating: "A", count: 100)
        let message = ChatMessage.user(longContent)

        conversation.addMessage(message)

        XCTAssertEqual(conversation.title.count, 50)
    }

    func testChatConversation_AddMessage_DoesNotUpdateTitleForAssistant() {
        var conversation = ChatConversation(title: "Original Title")
        conversation.addMessage(ChatMessage.assistant("First response"))

        XCTAssertEqual(conversation.title, "Original Title")
    }

    func testChatConversation_ToAPIHistory() {
        let messages = [
            ChatMessage.user("Question"),
            ChatMessage.assistant("Answer")
        ]
        let conversation = ChatConversation(messages: messages)

        let history = conversation.toAPIHistory()

        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0]["role"], "user")
        XCTAssertEqual(history[0]["content"], "Question")
        XCTAssertEqual(history[1]["role"], "assistant")
        XCTAssertEqual(history[1]["content"], "Answer")
    }

    // MARK: - Edge Cases

    func testChatMessage_EmptyContent() {
        let message = TestFixtures.chatMessage(content: "")

        XCTAssertTrue(message.content.isEmpty)
    }

    func testChatMessage_LongContent() {
        let longContent = String(repeating: "A", count: 10000)
        let message = TestFixtures.chatMessage(content: longContent)

        XCTAssertEqual(message.content.count, 10000)
    }

    func testChatMessage_SpecialCharactersInContent() {
        let specialContent = "Test with special chars: <>&\"' and unicode: ..."
        let message = TestFixtures.chatMessage(content: specialContent)

        XCTAssertEqual(message.content, specialContent)
    }

    func testChatMessage_EmptySuggestedActions() {
        let message = TestFixtures.chatMessage(suggestedActions: [])

        XCTAssertNotNil(message.suggestedActions)
        XCTAssertTrue(message.suggestedActions?.isEmpty ?? false)
    }

    func testChatMessage_ManySuggestedActions() {
        let manyActions = (1...20).map { "Action \($0)" }
        let message = TestFixtures.chatMessage(suggestedActions: manyActions)

        XCTAssertEqual(message.suggestedActions?.count, 20)
    }
}
