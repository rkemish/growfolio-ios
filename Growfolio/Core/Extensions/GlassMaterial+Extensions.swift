//
//  GlassMaterial+Extensions.swift
//  Growfolio
//
//  Glass material utilities for iOS 26 Liquid Glass design.
//

import SwiftUI

/// Glass material styles for Liquid Glass design
enum GlassMaterial: Sendable {
    /// Ultra-thin material - subtle transparency for overlays
    case thin
    /// Light material - light content backgrounds
    case light
    /// Regular material - standard cards and containers
    case regular
    /// Thick material - prominent surfaces, input areas
    case thick
    /// Ultra-thick material - modal and sheet backgrounds
    case ultraThick

    var material: Material {
        switch self {
        case .thin: return .ultraThinMaterial
        case .light: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        case .ultraThick: return .ultraThickMaterial
        }
    }
}

// MARK: - Glass View Modifiers

extension View {
    /// Apply glass card styling with Liquid Glass effect
    /// - Parameters:
    ///   - material: The glass material intensity
    ///   - cornerRadius: Corner radius for the card
    /// - Returns: View with glass card styling
    func glassCard(
        material: GlassMaterial = .regular,
        cornerRadius: CGFloat = Constants.UI.glassCornerRadius
    ) -> some View {
        self
            .background(material.material, in: RoundedRectangle(cornerRadius: cornerRadius))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Apply glass card with subtle shadow for depth
    /// - Parameters:
    ///   - material: The glass material intensity
    ///   - cornerRadius: Corner radius for the card
    /// - Returns: View with glass card and shadow
    func glassCardWithShadow(
        material: GlassMaterial = .regular,
        cornerRadius: CGFloat = Constants.UI.glassCornerRadius
    ) -> some View {
        self
            .glassCard(material: material, cornerRadius: cornerRadius)
            .shadow(
                color: .black.opacity(Constants.UI.glassShadowOpacity),
                radius: Constants.UI.glassShadowRadius,
                x: 0,
                y: 4
            )
    }

    /// Apply glass badge styling for status indicators
    /// - Parameter tintColor: Optional tint color for the badge
    /// - Returns: View with glass badge styling
    func glassBadge(tintColor: Color? = nil) -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                if let tintColor {
                    Capsule()
                        .fill(tintColor.opacity(0.15))
                        .background(.thinMaterial, in: Capsule())
                } else {
                    Capsule()
                        .fill(.thinMaterial)
                }
            }
    }

    /// Apply glass floating button styling
    /// - Parameter color: The accent color for the button
    /// - Returns: View with glass floating button styling
    func glassFloatingButton(color: Color = .trustBlue) -> some View {
        self
            .background(color, in: Circle())
            .background(.regularMaterial, in: Circle())
            .shadow(
                color: color.opacity(0.25),
                radius: 10,
                x: 0,
                y: 4
            )
    }

    /// Apply glass section header styling
    /// - Returns: View with glass section header styling
    func glassSectionHeader() -> some View {
        self
            .padding(.horizontal, Constants.UI.standardPadding)
            .padding(.vertical, Constants.UI.compactPadding)
            .background(.ultraThinMaterial)
    }

    /// Apply glass input field styling
    /// - Parameter cornerRadius: Corner radius for the input field
    /// - Returns: View with glass input field styling
    func glassInputField(cornerRadius: CGFloat = 20) -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Container Views

/// A container view that applies glass styling
struct GlassContainer<Content: View>: View {
    let material: GlassMaterial
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        material: GlassMaterial = .regular,
        cornerRadius: CGFloat = Constants.UI.glassCornerRadius,
        padding: CGFloat = Constants.UI.glassPadding,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .glassCard(material: material, cornerRadius: cornerRadius)
    }
}

/// A glass card with optional header
struct GlassCard<Content: View, Header: View>: View {
    let material: GlassMaterial
    let cornerRadius: CGFloat
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    init(
        material: GlassMaterial = .regular,
        cornerRadius: CGFloat = Constants.UI.glassCornerRadius,
        @ViewBuilder header: @escaping () -> Header = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.material = material
        self.cornerRadius = cornerRadius
        self.header = header
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header()
            content()
        }
        .padding(Constants.UI.glassPadding)
        .glassCard(material: material, cornerRadius: cornerRadius)
    }
}
