//
//  AIChatViewModelTests.swift
//  GrowfolioTests
//
//  Tests for AIChatViewModel.
//

import XCTest
@testable import Growfolio

@MainActor
final class AIChatViewModelTests: XCTestCase {

    // MARK: - Properties

    var mockRepository: MockAIRepository!
    var sut: AIChatViewModel!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockAIRepository()
        sut = AIChatViewModel(aiRepository: mockRepository)
    }

    override func tearDown() {
        mockRepository = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_hasDefaultValues() {
        XCTAssertTrue(sut.messages.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isTyping)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.showError)
        XCTAssertEqual(sut.inputText, "")
        XCTAssertTrue(sut.includePortfolioContext)
        XCTAssertFalse(sut.suggestedPrompts.isEmpty)
    }

    func test_initialState_hasSuggestedPrompts() {
        XCTAssertEqual(sut.suggestedPrompts.count, 4)

        let titles = sut.suggestedPrompts.map { $0.title }
        XCTAssertTrue(titles.contains("Portfolio Analysis"))
        XCTAssertTrue(titles.contains("DCA Strategy"))
        XCTAssertTrue(titles.contains("Goal Planning"))
        XCTAssertTrue(titles.contains("Market Trends"))
    }

    // MARK: - Computed Properties Tests

    func test_canSend_returnsTrueWhenHasInputAndNotLoading() {
        sut.inputText = "Hello"
        sut.isLoading = false

        XCTAssertTrue(sut.canSend)
    }

    func test_canSend_returnsFalseWhenEmpty() {
        sut.inputText = ""
        sut.isLoading = false

        XCTAssertFalse(sut.canSend)
    }

    func test_canSend_returnsFalseWhenOnlyWhitespace() {
        sut.inputText = "   \n\t  "
        sut.isLoading = false

        XCTAssertFalse(sut.canSend)
    }

    func test_canSend_returnsFalseWhenLoading() {
        sut.inputText = "Hello"
        sut.isLoading = true

        XCTAssertFalse(sut.canSend)
    }

    func test_isEmpty_returnsTrueWhenNoMessages() {
        XCTAssertTrue(sut.isEmpty)
    }

    func test_isEmpty_returnsFalseWhenHasMessages() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "Hello"
        await sut.sendMessage()

        XCTAssertFalse(sut.isEmpty)
    }

    func test_lastAssistantMessage_returnsLastAssistantMessage() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "First question"
        await sut.sendMessage()

        let lastMessage = sut.lastAssistantMessage

        XCTAssertNotNil(lastMessage)
        XCTAssertTrue(lastMessage?.isAssistant ?? false)
    }

    func test_lastAssistantMessage_returnsNilWhenNoAssistantMessages() {
        // Only add a user message manually without AI response
        sut.messages.append(ChatMessage.user("Test"))

        XCTAssertNil(sut.lastAssistantMessage)
    }

    // MARK: - Loading State Tests

    func test_sendMessage_setsIsLoadingDuringOperation() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "Hello"

        await sut.sendMessage()

        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isTyping)
    }

    // MARK: - Send Message Tests

    func test_sendMessage_clearsInputImmediately() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "Hello"

        await sut.sendMessage()

        XCTAssertEqual(sut.inputText, "")
    }

    func test_sendMessage_addsUserMessage() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "Hello AI"

        await sut.sendMessage()

        let userMessage = sut.messages.first { $0.isUser }
        XCTAssertNotNil(userMessage)
        XCTAssertEqual(userMessage?.content, "Hello AI")
    }

    func test_sendMessage_addsAssistantResponse() async {
        let expectedResponse = AIChatTestFixtures.sampleAssistantMessage(content: "Hello! How can I help?")
        mockRepository.chatMessageToReturn = expectedResponse
        sut.inputText = "Hello"

        await sut.sendMessage()

        let assistantMessage = sut.messages.last { $0.isAssistant }
        XCTAssertNotNil(assistantMessage)
        XCTAssertEqual(assistantMessage?.content, "Hello! How can I help?")
    }

    func test_sendMessage_passesCorrectParametersToRepository() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "Test message"
        sut.includePortfolioContext = true

        await sut.sendMessage()

        XCTAssertTrue(mockRepository.sendMessageCalled)
        XCTAssertEqual(mockRepository.lastSentMessage, "Test message")
        XCTAssertEqual(mockRepository.lastIncludePortfolioContext, true)
    }

    func test_sendMessage_doesNothingWhenInputEmpty() async {
        sut.inputText = ""

        await sut.sendMessage()

        XCTAssertFalse(mockRepository.sendMessageCalled)
        XCTAssertTrue(sut.messages.isEmpty)
    }

    func test_sendMessage_trimsWhitespace() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "  Hello  \n"

        await sut.sendMessage()

        XCTAssertEqual(mockRepository.lastSentMessage, "Hello")
    }

    func test_sendMessage_passesConversationHistory() async {
        // Send first message
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage(content: "Response 1")
        sut.inputText = "First message"
        await sut.sendMessage()

        // Send second message
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage(content: "Response 2")
        sut.inputText = "Second message"
        await sut.sendMessage()

        // Verify history was passed (should include first user message, not the current one)
        XCTAssertNotNil(mockRepository.lastConversationHistory)
        // History should contain the first exchange
        XCTAssertGreaterThan(mockRepository.lastConversationHistory?.count ?? 0, 0)
    }

    // MARK: - Error Handling Tests

    func test_sendMessage_setsErrorOnFailure() async {
        mockRepository.errorToThrow = NetworkError.noConnection
        sut.inputText = "Hello"

        await sut.sendMessage()

        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.showError)
    }

    func test_sendMessage_removesStreamingPlaceholderOnError() async {
        mockRepository.errorToThrow = NetworkError.noConnection
        sut.inputText = "Hello"

        await sut.sendMessage()

        // Should have user message but no streaming placeholder
        let streamingMessages = sut.messages.filter { $0.isStreaming }
        XCTAssertTrue(streamingMessages.isEmpty)
    }

    func test_sendMessage_preservesUserMessageOnError() async {
        mockRepository.errorToThrow = NetworkError.noConnection
        sut.inputText = "Hello"

        await sut.sendMessage()

        let userMessage = sut.messages.first { $0.isUser }
        XCTAssertNotNil(userMessage)
        XCTAssertEqual(userMessage?.content, "Hello")
    }

    func test_dismissError_clearsErrorState() async {
        mockRepository.errorToThrow = NetworkError.noConnection
        sut.inputText = "Hello"
        await sut.sendMessage()

        sut.dismissError()

        XCTAssertFalse(sut.showError)
        XCTAssertNil(sut.error)
    }

    // MARK: - Send Prompt Tests

    func test_sendPrompt_setsInputAndSendsMessage() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        let prompt = "Analyze my portfolio"

        await sut.sendPrompt(prompt)

        XCTAssertEqual(mockRepository.lastSentMessage, prompt)
    }

    func test_sendPrompt_worksWithSuggestedPrompt() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        let suggestedPrompt = sut.suggestedPrompts.first!

        await sut.sendPrompt(suggestedPrompt.prompt)

        XCTAssertEqual(mockRepository.lastSentMessage, suggestedPrompt.prompt)
    }

    // MARK: - Handle Suggested Action Tests

    func test_handleSuggestedAction_sendsFollowUpMessage() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()

        await sut.handleSuggestedAction("Learn more about DCA")

        XCTAssertTrue(mockRepository.lastSentMessage?.contains("Learn more about DCA") ?? false)
    }

    // MARK: - Clear Conversation Tests

    func test_clearConversation_removesAllMessages() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "Hello"
        await sut.sendMessage()

        sut.clearConversation()

        XCTAssertTrue(sut.messages.isEmpty)
    }

    func test_clearConversation_clearsErrorState() async {
        mockRepository.errorToThrow = NetworkError.noConnection
        sut.inputText = "Hello"
        await sut.sendMessage()

        sut.clearConversation()

        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.showError)
    }

    // MARK: - Retry Last Message Tests

    func test_retryLastMessage_resendsLastUserMessage() async {
        // First message
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage(content: "Response 1")
        sut.inputText = "Original message"
        await sut.sendMessage()

        // Reset mock to track new call
        mockRepository.sendMessageCalled = false
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage(content: "Retried response")

        await sut.retryLastMessage()

        XCTAssertTrue(mockRepository.sendMessageCalled)
        XCTAssertEqual(mockRepository.lastSentMessage, "Original message")
    }

    func test_retryLastMessage_removesOriginalMessageBeforeRetry() async {
        // First message
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "Original message"
        await sut.sendMessage()

        let messageCountBefore = sut.messages.count

        // Mock a new response for retry
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage(content: "New response")
        await sut.retryLastMessage()

        // Should have same number of messages (removed old, added new)
        XCTAssertEqual(sut.messages.count, messageCountBefore)
    }

    func test_retryLastMessage_doesNothingWhenNoUserMessages() async {
        await sut.retryLastMessage()

        XCTAssertFalse(mockRepository.sendMessageCalled)
    }

    // MARK: - Include Portfolio Context Tests

    func test_sendMessage_respectsIncludePortfolioContextSetting() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "Hello"
        sut.includePortfolioContext = false

        await sut.sendMessage()

        XCTAssertEqual(mockRepository.lastIncludePortfolioContext, false)
    }

    // MARK: - Suggested Actions Tests

    func test_sendMessage_responseCanHaveSuggestedActions() async {
        let responseWithActions = AIChatTestFixtures.sampleAssistantMessage(
            content: "Here's my analysis",
            suggestedActions: ["View portfolio", "Set up DCA", "Add goal"]
        )
        mockRepository.chatMessageToReturn = responseWithActions
        sut.inputText = "Analyze my portfolio"

        await sut.sendMessage()

        let lastAssistant = sut.messages.last { $0.isAssistant }
        XCTAssertNotNil(lastAssistant?.suggestedActions)
        XCTAssertEqual(lastAssistant?.suggestedActions?.count, 3)
    }

    // MARK: - Message Content Tests

    func test_userMessage_hasCorrectProperties() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage()
        sut.inputText = "Test message"

        await sut.sendMessage()

        let userMessage = sut.messages.first { $0.isUser }
        XCTAssertNotNil(userMessage)
        XCTAssertTrue(userMessage?.isUser ?? false)
        XCTAssertFalse(userMessage?.isAssistant ?? true)
        XCTAssertEqual(userMessage?.content, "Test message")
    }

    func test_assistantMessage_hasCorrectProperties() async {
        let response = AIChatTestFixtures.sampleAssistantMessage(content: "AI Response")
        mockRepository.chatMessageToReturn = response
        sut.inputText = "Test"

        await sut.sendMessage()

        let assistantMessage = sut.messages.last { $0.isAssistant }
        XCTAssertNotNil(assistantMessage)
        XCTAssertTrue(assistantMessage?.isAssistant ?? false)
        XCTAssertFalse(assistantMessage?.isUser ?? true)
        XCTAssertEqual(assistantMessage?.content, "AI Response")
    }

    // MARK: - Multiple Message Flow Tests

    func test_multipleMessages_maintainsCorrectOrder() async {
        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage(content: "Response 1")
        sut.inputText = "Message 1"
        await sut.sendMessage()

        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage(content: "Response 2")
        sut.inputText = "Message 2"
        await sut.sendMessage()

        mockRepository.chatMessageToReturn = AIChatTestFixtures.sampleAssistantMessage(content: "Response 3")
        sut.inputText = "Message 3"
        await sut.sendMessage()

        XCTAssertEqual(sut.messages.count, 6) // 3 user + 3 assistant

        // Check alternating pattern
        XCTAssertTrue(sut.messages[0].isUser)
        XCTAssertTrue(sut.messages[1].isAssistant)
        XCTAssertTrue(sut.messages[2].isUser)
        XCTAssertTrue(sut.messages[3].isAssistant)
        XCTAssertTrue(sut.messages[4].isUser)
        XCTAssertTrue(sut.messages[5].isAssistant)
    }
}

// MARK: - Test Fixtures

private enum AIChatTestFixtures {
    static func sampleAssistantMessage(
        content: String = "This is a mock AI response.",
        suggestedActions: [String]? = nil
    ) -> ChatMessage {
        ChatMessage.assistant(content, suggestedActions: suggestedActions)
    }

    static func sampleUserMessage(content: String = "Hello AI") -> ChatMessage {
        ChatMessage.user(content)
    }
}
