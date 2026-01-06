//
//  StockExplanationTests.swift
//  GrowfolioTests
//
//  Tests for StockExplanation domain model.
//

import XCTest
@testable import Growfolio

final class StockExplanationTests: XCTestCase {

    // MARK: - Identifiable Tests

    func testId_ReturnsSymbol() {
        let explanation = TestFixtures.stockExplanation(symbol: "AAPL")
        XCTAssertEqual(explanation.id, "AAPL")
    }

    // MARK: - Basic Properties Tests

    func testSymbol_ReturnsValue() {
        let explanation = TestFixtures.stockExplanation(symbol: "MSFT")
        XCTAssertEqual(explanation.symbol, "MSFT")
    }

    func testExplanation_ReturnsValue() {
        let explanationText = "Apple Inc. is a technology company that designs and manufactures consumer electronics."
        let explanation = TestFixtures.stockExplanation(symbol: "AAPL", explanation: explanationText)
        XCTAssertEqual(explanation.explanation, explanationText)
    }

    func testGeneratedAt_ReturnsDate() {
        let customDate = TestFixtures.pastDate
        let explanation = TestFixtures.stockExplanation(symbol: "AAPL", generatedAt: customDate)
        XCTAssertEqual(explanation.generatedAt, customDate)
    }

    // MARK: - Initialization Tests

    func testInit_WithDefaultDate() {
        let beforeCreation = Date()
        let explanation = StockExplanation(
            symbol: "AAPL",
            explanation: "Test explanation"
        )
        let afterCreation = Date()

        XCTAssertGreaterThanOrEqual(explanation.generatedAt, beforeCreation)
        XCTAssertLessThanOrEqual(explanation.generatedAt, afterCreation)
    }

    func testInit_WithCustomDate() {
        let customDate = TestFixtures.referenceDate
        let explanation = StockExplanation(
            symbol: "AAPL",
            explanation: "Test explanation",
            generatedAt: customDate
        )
        XCTAssertEqual(explanation.generatedAt, customDate)
    }

    // MARK: - Codable Tests

    func testStockExplanation_EncodeDecode_RoundTrip() throws {
        let original = TestFixtures.stockExplanation(
            symbol: "GOOGL",
            explanation: "Alphabet Inc. is a multinational technology company.",
            generatedAt: TestFixtures.referenceDate
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(StockExplanation.self, from: data)

        XCTAssertEqual(decoded.symbol, original.symbol)
        XCTAssertEqual(decoded.explanation, original.explanation)
    }

    func testStockExplanation_DecodeWithMissingGeneratedAt() throws {
        // Test that decoder handles missing generatedAt by defaulting to Date()
        let json = """
        {
            "symbol": "AAPL",
            "explanation": "Test explanation"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(StockExplanation.self, from: json)

        XCTAssertEqual(decoded.symbol, "AAPL")
        XCTAssertEqual(decoded.explanation, "Test explanation")
        // generatedAt should default to now (approximately)
        XCTAssertNotNil(decoded.generatedAt)
    }

    // MARK: - Equatable Tests

    func testStockExplanation_Equatable_Same() {
        let explanation1 = TestFixtures.stockExplanation(symbol: "AAPL", explanation: "Test")
        let explanation2 = TestFixtures.stockExplanation(symbol: "AAPL", explanation: "Test")
        XCTAssertEqual(explanation1, explanation2)
    }

    func testStockExplanation_Equatable_DifferentSymbol() {
        let explanation1 = TestFixtures.stockExplanation(symbol: "AAPL")
        let explanation2 = TestFixtures.stockExplanation(symbol: "MSFT")
        XCTAssertNotEqual(explanation1, explanation2)
    }

    func testStockExplanation_Equatable_DifferentExplanation() {
        let explanation1 = TestFixtures.stockExplanation(symbol: "AAPL", explanation: "Text 1")
        let explanation2 = TestFixtures.stockExplanation(symbol: "AAPL", explanation: "Text 2")
        XCTAssertNotEqual(explanation1, explanation2)
    }

    // MARK: - AllocationSuggestion Tests

    func testAllocationSuggestion_Init() {
        let suggestion = AllocationSuggestion(
            suggestion: "Consider investing 60% in stocks and 40% in bonds.",
            investmentAmount: 10000,
            riskTolerance: .medium,
            timeHorizon: .long
        )

        XCTAssertFalse(suggestion.id.isEmpty)
        XCTAssertEqual(suggestion.investmentAmount, 10000)
        XCTAssertEqual(suggestion.riskTolerance, .medium)
        XCTAssertEqual(suggestion.timeHorizon, .long)
        XCTAssertFalse(suggestion.disclaimer.isEmpty)
    }

    func testAllocationSuggestion_CustomDisclaimer() {
        let customDisclaimer = "This is a custom disclaimer for testing."
        let suggestion = AllocationSuggestion(
            suggestion: "Test suggestion",
            investmentAmount: 5000,
            riskTolerance: .high,
            timeHorizon: .short,
            disclaimer: customDisclaimer
        )

        XCTAssertEqual(suggestion.disclaimer, customDisclaimer)
    }

    // MARK: - RiskTolerance Tests

    func testRiskTolerance_DisplayName() {
        XCTAssertEqual(RiskTolerance.low.displayName, "Conservative")
        XCTAssertEqual(RiskTolerance.medium.displayName, "Moderate")
        XCTAssertEqual(RiskTolerance.high.displayName, "Aggressive")
    }

    func testRiskTolerance_Description() {
        XCTAssertFalse(RiskTolerance.low.description.isEmpty)
        XCTAssertFalse(RiskTolerance.medium.description.isEmpty)
        XCTAssertFalse(RiskTolerance.high.description.isEmpty)
    }

    func testRiskTolerance_IconName() {
        XCTAssertEqual(RiskTolerance.low.iconName, "shield.fill")
        XCTAssertEqual(RiskTolerance.medium.iconName, "scale.3d")
        XCTAssertEqual(RiskTolerance.high.iconName, "bolt.fill")
    }

    func testRiskTolerance_ColorHex() {
        XCTAssertEqual(RiskTolerance.low.colorHex, "#34C759")
        XCTAssertEqual(RiskTolerance.medium.colorHex, "#FF9500")
        XCTAssertEqual(RiskTolerance.high.colorHex, "#FF3B30")
    }

    func testRiskTolerance_AllCases() {
        XCTAssertEqual(RiskTolerance.allCases.count, 3)
    }

    // MARK: - TimeHorizon Tests

    func testTimeHorizon_DisplayName() {
        XCTAssertEqual(TimeHorizon.short.displayName, "Short-term")
        XCTAssertEqual(TimeHorizon.medium.displayName, "Medium-term")
        XCTAssertEqual(TimeHorizon.long.displayName, "Long-term")
    }

    func testTimeHorizon_Description() {
        XCTAssertEqual(TimeHorizon.short.description, "Less than 3 years")
        XCTAssertEqual(TimeHorizon.medium.description, "3-10 years")
        XCTAssertEqual(TimeHorizon.long.description, "More than 10 years")
    }

    func testTimeHorizon_IconName() {
        XCTAssertEqual(TimeHorizon.short.iconName, "clock")
        XCTAssertEqual(TimeHorizon.medium.iconName, "calendar")
        XCTAssertEqual(TimeHorizon.long.iconName, "calendar.badge.clock")
    }

    func testTimeHorizon_AllCases() {
        XCTAssertEqual(TimeHorizon.allCases.count, 3)
    }

    // MARK: - Codable Tests for Supporting Types

    func testRiskTolerance_Codable() throws {
        for tolerance in RiskTolerance.allCases {
            let data = try JSONEncoder().encode(tolerance)
            let decoded = try JSONDecoder().decode(RiskTolerance.self, from: data)
            XCTAssertEqual(decoded, tolerance)
        }
    }

    func testTimeHorizon_Codable() throws {
        for horizon in TimeHorizon.allCases {
            let data = try JSONEncoder().encode(horizon)
            let decoded = try JSONDecoder().decode(TimeHorizon.self, from: data)
            XCTAssertEqual(decoded, horizon)
        }
    }

    func testAllocationSuggestion_Codable() throws {
        let original = AllocationSuggestion(
            id: "suggestion-123",
            suggestion: "Diversify your portfolio",
            investmentAmount: 50000,
            riskTolerance: .medium,
            timeHorizon: .long,
            disclaimer: "Test disclaimer",
            generatedAt: TestFixtures.referenceDate
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(AllocationSuggestion.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.suggestion, original.suggestion)
        XCTAssertEqual(decoded.investmentAmount, original.investmentAmount)
        XCTAssertEqual(decoded.riskTolerance, original.riskTolerance)
        XCTAssertEqual(decoded.timeHorizon, original.timeHorizon)
        XCTAssertEqual(decoded.disclaimer, original.disclaimer)
    }

    func testAllocationSuggestion_DecodeWithDefaults() throws {
        // Test that decoder handles missing optional fields
        let json = """
        {
            "suggestion": "Test suggestion"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AllocationSuggestion.self, from: json)

        XCTAssertFalse(decoded.id.isEmpty) // Should have generated UUID
        XCTAssertEqual(decoded.suggestion, "Test suggestion")
        XCTAssertEqual(decoded.investmentAmount, 0) // Default
        XCTAssertEqual(decoded.riskTolerance, .medium) // Default
        XCTAssertEqual(decoded.timeHorizon, .medium) // Default
    }

    // MARK: - AllocationSuggestionResponse Tests

    func testAllocationSuggestionResponse_Init() {
        let response = AllocationSuggestionResponse(
            suggestion: "Invest in index funds",
            disclaimer: "Not financial advice"
        )

        XCTAssertEqual(response.suggestion, "Invest in index funds")
        XCTAssertEqual(response.disclaimer, "Not financial advice")
    }

    func testAllocationSuggestionResponse_Codable() throws {
        let original = AllocationSuggestionResponse(
            suggestion: "Test suggestion",
            disclaimer: "Test disclaimer"
        )

        let data = try TestFixtures.jsonData(for: original)
        let decoded = try TestFixtures.decode(AllocationSuggestionResponse.self, from: data)

        XCTAssertEqual(decoded.suggestion, original.suggestion)
        XCTAssertEqual(decoded.disclaimer, original.disclaimer)
    }

    // MARK: - Edge Cases

    func testStockExplanation_EmptyExplanation() {
        let explanation = StockExplanation(
            symbol: "AAPL",
            explanation: ""
        )
        XCTAssertEqual(explanation.explanation, "")
    }

    func testStockExplanation_LongExplanation() {
        let longExplanation = String(repeating: "This is a detailed explanation about the company. ", count: 100)
        let explanation = TestFixtures.stockExplanation(
            symbol: "AAPL",
            explanation: longExplanation
        )
        XCTAssertEqual(explanation.explanation, longExplanation)
    }

    func testStockExplanation_SpecialCharactersInSymbol() {
        let explanation = StockExplanation(
            symbol: "BRK.A",
            explanation: "Berkshire Hathaway Class A shares"
        )
        XCTAssertEqual(explanation.symbol, "BRK.A")
        XCTAssertEqual(explanation.id, "BRK.A")
    }

    func testAllocationSuggestion_ZeroInvestmentAmount() {
        let suggestion = AllocationSuggestion(
            suggestion: "Save more before investing",
            investmentAmount: 0,
            riskTolerance: .low,
            timeHorizon: .short
        )
        XCTAssertEqual(suggestion.investmentAmount, 0)
    }

    func testAllocationSuggestion_LargeInvestmentAmount() {
        let suggestion = AllocationSuggestion(
            suggestion: "High net worth portfolio strategy",
            investmentAmount: 10_000_000,
            riskTolerance: .high,
            timeHorizon: .long
        )
        XCTAssertEqual(suggestion.investmentAmount, 10_000_000)
    }

    // MARK: - Equatable Tests for AllocationSuggestion

    func testAllocationSuggestion_Equatable_Same() {
        let suggestion1 = AllocationSuggestion(
            id: "s1",
            suggestion: "Test",
            investmentAmount: 1000,
            riskTolerance: .medium,
            timeHorizon: .medium,
            generatedAt: TestFixtures.referenceDate
        )
        let suggestion2 = AllocationSuggestion(
            id: "s1",
            suggestion: "Test",
            investmentAmount: 1000,
            riskTolerance: .medium,
            timeHorizon: .medium,
            generatedAt: TestFixtures.referenceDate
        )
        XCTAssertEqual(suggestion1, suggestion2)
    }

    func testAllocationSuggestion_Equatable_DifferentId() {
        let suggestion1 = AllocationSuggestion(
            id: "s1",
            suggestion: "Test",
            investmentAmount: 1000,
            riskTolerance: .medium,
            timeHorizon: .medium
        )
        let suggestion2 = AllocationSuggestion(
            id: "s2",
            suggestion: "Test",
            investmentAmount: 1000,
            riskTolerance: .medium,
            timeHorizon: .medium
        )
        XCTAssertNotEqual(suggestion1, suggestion2)
    }
}
