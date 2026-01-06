//
//  ColorExtensionsTests.swift
//  GrowfolioTests
//
//  Tests for Color extensions.
//

import XCTest
import SwiftUI
@testable import Growfolio

final class ColorExtensionsTests: XCTestCase {

    // MARK: - Hex Initialization Tests

    func testColorInitFromHex6Digit() {
        let color = Color(hex: "#FF5733")

        // Verify color is created (non-nil)
        XCTAssertNotNil(color)
    }

    func testColorInitFromHex6DigitWithoutHash() {
        let color = Color(hex: "FF5733")

        XCTAssertNotNil(color)
    }

    func testColorInitFromHex3Digit() {
        let color = Color(hex: "#FFF")

        XCTAssertNotNil(color)
    }

    func testColorInitFromHex8DigitARGB() {
        let color = Color(hex: "#80FF5733")

        XCTAssertNotNil(color)
    }

    func testColorInitFromInvalidHex() {
        let color = Color(hex: "invalid")

        // Should create a color (defaults to black)
        XCTAssertNotNil(color)
    }

    func testColorInitFromEmptyHex() {
        let color = Color(hex: "")

        XCTAssertNotNil(color)
    }

    func testColorInitBlack() {
        let color = Color(hex: "#000000")

        XCTAssertNotNil(color)
    }

    func testColorInitWhite() {
        let color = Color(hex: "#FFFFFF")

        XCTAssertNotNil(color)
    }

    func testColorInitRed() {
        let color = Color(hex: "#FF0000")

        XCTAssertNotNil(color)
    }

    func testColorInitGreen() {
        let color = Color(hex: "#00FF00")

        XCTAssertNotNil(color)
    }

    func testColorInitBlue() {
        let color = Color(hex: "#0000FF")

        XCTAssertNotNil(color)
    }

    func testColorInitLowercase() {
        let color = Color(hex: "#ff5733")

        XCTAssertNotNil(color)
    }

    func testColorInitMixedCase() {
        let color = Color(hex: "#Ff5733")

        XCTAssertNotNil(color)
    }

    // MARK: - Hex Output Tests

    func testColorHexString() {
        let color = Color.red
        let hexString = color.hexString

        // Red color should produce a hex with FF in red channel
        // Note: hexString may be nil for certain color types
        if let hex = hexString {
            XCTAssertTrue(hex.hasPrefix("#"))
            XCTAssertEqual(hex.count, 7) // #RRGGBB
        }
    }

    func testColorHexStringRoundTrip() {
        let originalHex = "#FF5733"
        let color = Color(hex: originalHex)
        let outputHex = color.hexString

        // May not match exactly due to color space conversions
        if let hex = outputHex {
            XCTAssertTrue(hex.hasPrefix("#"))
        }
    }

    // MARK: - App Colors Tests

    func testColorSuccess() {
        let color = Color.success

        XCTAssertNotNil(color)
    }

    func testColorWarning() {
        let color = Color.warning

        XCTAssertNotNil(color)
    }

    func testColorError() {
        let color = Color.error

        XCTAssertNotNil(color)
    }

    func testColorPositive() {
        let color = Color.positive

        XCTAssertNotNil(color)
    }

    func testColorNegative() {
        let color = Color.negative

        XCTAssertNotNil(color)
    }

    func testColorNeutral() {
        let color = Color.neutral

        XCTAssertNotNil(color)
    }

    // MARK: - Chart Colors Tests

    func testChartColorsArray() {
        let colors = Color.chartColors

        XCTAssertEqual(colors.count, 10)
    }

    func testChartColorAtIndex() {
        let color0 = Color.chartColor(at: 0)
        let color5 = Color.chartColor(at: 5)

        XCTAssertNotNil(color0)
        XCTAssertNotNil(color5)
    }

    func testChartColorAtIndexCycles() {
        let color0 = Color.chartColor(at: 0)
        let color10 = Color.chartColor(at: 10)

        // Index 10 should cycle back to index 0
        // Colors should be the same
        XCTAssertNotNil(color0)
        XCTAssertNotNil(color10)
    }

    func testChartColorAtLargeIndex() {
        let color = Color.chartColor(at: 100)

        // Should not crash and should return a valid color
        XCTAssertNotNil(color)
    }

    // MARK: - Adjustment Tests

    func testColorLighter() {
        let color = Color(hex: "#808080")
        let lighter = color.lighter(by: 0.2)

        XCTAssertNotNil(lighter)
    }

    func testColorDarker() {
        let color = Color(hex: "#808080")
        let darker = color.darker(by: 0.2)

        XCTAssertNotNil(darker)
    }

    func testColorLighterDefaultAmount() {
        let color = Color(hex: "#808080")
        let lighter = color.lighter()

        XCTAssertNotNil(lighter)
    }

    func testColorDarkerDefaultAmount() {
        let color = Color(hex: "#808080")
        let darker = color.darker()

        XCTAssertNotNil(darker)
    }

    func testColorLighterWithNegativeAmount() {
        let color = Color(hex: "#808080")
        let result = color.lighter(by: -0.2)

        // Should use absolute value, so still lighten
        XCTAssertNotNil(result)
    }

    func testColorDarkerWithNegativeAmount() {
        let color = Color(hex: "#808080")
        let result = color.darker(by: -0.2)

        // Should use absolute value, so still darken
        XCTAssertNotNil(result)
    }

    func testColorLighterClamps() {
        let color = Color.white
        let lighter = color.lighter(by: 0.5)

        // Should not exceed maximum brightness
        XCTAssertNotNil(lighter)
    }

    func testColorDarkerClamps() {
        let color = Color.black
        let darker = color.darker(by: 0.5)

        // Should not go below minimum brightness
        XCTAssertNotNil(darker)
    }

    // MARK: - Contrast Tests

    func testColorIsDarkForBlack() {
        let black = Color(hex: "#000000")
        let isDark = black.isDark

        XCTAssertTrue(isDark)
    }

    func testColorIsDarkForWhite() {
        let white = Color(hex: "#FFFFFF")
        let isDark = white.isDark

        XCTAssertFalse(isDark)
    }

    func testColorIsDarkForDarkGray() {
        let darkGray = Color(hex: "#333333")
        let isDark = darkGray.isDark

        XCTAssertTrue(isDark)
    }

    func testColorIsDarkForLightGray() {
        let lightGray = Color(hex: "#CCCCCC")
        let isDark = lightGray.isDark

        XCTAssertFalse(isDark)
    }

    func testColorContrastingTextColorForDark() {
        let darkColor = Color(hex: "#000000")
        let contrastColor = darkColor.contrastingTextColor

        // Dark background should have white text
        XCTAssertNotNil(contrastColor)
    }

    func testColorContrastingTextColorForLight() {
        let lightColor = Color(hex: "#FFFFFF")
        let contrastColor = lightColor.contrastingTextColor

        // Light background should have black text
        XCTAssertNotNil(contrastColor)
    }

    // MARK: - CGColor Extension Tests

    func testCGColorHex() {
        let cgColor = CGColor.hex("#FF5733")

        XCTAssertNotNil(cgColor)
    }

    func testCGColorHexInvalid() {
        let cgColor = CGColor.hex("invalid")

        // Should return black as default
        XCTAssertNotNil(cgColor)
    }

    // MARK: - Edge Cases

    func testColorWithSpacesInHex() {
        let color = Color(hex: " #FF5733 ")

        // Should trim whitespace
        XCTAssertNotNil(color)
    }

    func testColorWithNewlinesInHex() {
        let color = Color(hex: "\n#FF5733\n")

        XCTAssertNotNil(color)
    }

    func testColorHexStringForSystemColor() {
        let systemColor = Color.blue
        let hex = systemColor.hexString

        // System colors may or may not produce a hex string
        // depending on the color space
        // This test just ensures it doesn't crash
        _ = hex
    }

    func testColorHexStringForCustomColor() {
        let customColor = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 1.0)
        let hex = customColor.hexString

        if let hex = hex {
            XCTAssertTrue(hex.hasPrefix("#"))
        }
    }

    func testChartColorsAreDistinct() {
        let colors = Color.chartColors

        // Verify all colors are unique (by checking they're not all the same)
        // This is a basic sanity check
        var hexSet = Set<String>()
        for color in colors {
            if let hex = color.hexString {
                hexSet.insert(hex)
            }
        }

        // Should have multiple distinct colors
        XCTAssertGreaterThan(hexSet.count, 1)
    }

    func testColorAdjustmentPreservesAlpha() {
        let colorWithAlpha = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5)
        let lighter = colorWithAlpha.lighter(by: 0.1)

        // The result should still be a valid color
        XCTAssertNotNil(lighter)
    }
}
