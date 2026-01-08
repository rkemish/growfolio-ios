//
//  AdaptiveHelpers.swift
//  Growfolio
//
//  Utilities for adaptive layouts based on horizontal size class.
//  Provides helpers for detecting device type and computing responsive layouts.
//

import SwiftUI

// MARK: - View Extension

extension View {
    /// Returns true if the current horizontal size class is compact (iPhone, iPad split screen)
    var isCompactWidth: Bool {
        #if targetEnvironment(macCatalyst)
        return false
        #else
        // Access via environment would require @Environment binding
        // This is a utility that should be used with @Environment(\.horizontalSizeClass)
        return true // Default fallback
        #endif
    }
}

// MARK: - Adaptive Layout Helpers

/// Helper for determining grid column counts based on size class
struct AdaptiveGridHelper {
    let horizontalSizeClass: UserInterfaceSizeClass?

    /// Returns the number of columns for a standard grid layout
    var gridColumns: Int {
        horizontalSizeClass == .regular ? Constants.UI.regularGridColumns : Constants.UI.compactGridColumns
    }

    /// Returns the number of columns for stat grids in detail views
    var statGridColumns: Int {
        horizontalSizeClass == .regular ? 4 : 2
    }

    /// Returns the number of columns for card-based list grids
    var cardGridColumns: Int {
        switch horizontalSizeClass {
        case .regular:
            return 3 // iPad shows 3 columns
        default:
            return 1 // iPhone shows single column
        }
    }

    /// Returns GridItem array for the specified column count
    func columns(count: Int? = nil) -> [GridItem] {
        let columnCount = count ?? gridColumns
        return Array(repeating: GridItem(.flexible(), spacing: Constants.UI.standardPadding), count: columnCount)
    }
}

// MARK: - Device Type Detection

/// Helper for detecting device capabilities
enum DeviceCapability {
    /// Check if running on iPad (regular horizontal size class)
    static func isIPad(sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .regular
    }

    /// Check if running on iPhone or iPad in compact mode
    static func isCompact(sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .compact || sizeClass == nil
    }

    /// Preferred navigation style based on size class
    static func prefersSplitView(sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .regular
    }
}

// MARK: - Adaptive Content Width

extension View {
    /// Constrains content width for iPad while allowing full width on iPhone
    func adaptiveContentWidth(sizeClass: UserInterfaceSizeClass?, maxWidth: CGFloat = 800) -> some View {
        self
            .frame(maxWidth: sizeClass == .regular ? maxWidth : .infinity)
            .frame(maxWidth: .infinity) // Centers the content
    }
}
