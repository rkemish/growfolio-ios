//
//  MarketStatusBadge.swift
//  Growfolio
//
//  Displays the current market status (open/closed) with next event time.
//

import SwiftUI

/// Badge displaying market open/closed status
struct MarketStatusBadge: View {

    // MARK: - Properties

    let marketHours: MarketHours?
    var style: BadgeStyle = .default

    enum BadgeStyle {
        case `default`
        case compact
        case detailed
    }

    // MARK: - Computed Properties

    private var isOpen: Bool {
        marketHours?.isOpen ?? false
    }

    private var statusColor: Color {
        guard let hours = marketHours else { return .gray }

        if hours.isOpen {
            return Color.positive
        } else if hours.isExtendedHours {
            return Color.warning
        } else {
            return Color.negative
        }
    }

    private var statusText: String {
        guard let hours = marketHours else { return "Loading..." }
        return hours.isOpen ? "Market Open" : "Market Closed"
    }

    private var sessionText: String? {
        guard let hours = marketHours else { return nil }

        switch hours.session {
        case .pre:
            return "Pre-Market"
        case .after:
            return "After Hours"
        case .regular, .closed:
            return nil
        }
    }

    private var nextEventText: String? {
        marketHours?.nextEventLabel
    }

    // MARK: - Body

    var body: some View {
        switch style {
        case .default:
            defaultBadge
        case .compact:
            compactBadge
        case .detailed:
            detailedBadge
        }
    }

    // MARK: - Default Badge

    private var defaultBadge: some View {
        HStack(spacing: 6) {
            // Pulsing indicator dot
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .modifier(PulsingModifier(isAnimating: isOpen))

            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(statusColor)

            // Show extended hours indicator if applicable
            if let session = sessionText {
                Text("(\(session))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .glassBadge(tintColor: statusColor)
    }

    // MARK: - Compact Badge

    private var compactBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .modifier(PulsingModifier(isAnimating: isOpen))

            Text(marketHours?.shortStatusText ?? "...")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Detailed Badge

    private var detailedBadge: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main status
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .modifier(PulsingModifier(isAnimating: isOpen))

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor)

                    if let session = sessionText {
                        Text(session)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Exchange badge
                if let exchange = marketHours?.exchange {
                    Text(exchange)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 4))
                }
            }

            // Next event time
            if let nextEvent = nextEventText, !nextEvent.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)

                    Text(nextEvent)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .glassCard(material: .regular, cornerRadius: 12)
    }
}

// MARK: - Inline Market Status

/// Inline version for embedding in other views (e.g., StockPriceView)
struct InlineMarketStatus: View {

    let marketHours: MarketHours?

    private var statusColor: Color {
        guard let hours = marketHours else { return .gray }
        return hours.isOpen ? Color.positive : Color.negative
    }

    private var statusText: String {
        guard let hours = marketHours else { return "Loading..." }

        if hours.isOpen {
            return "Market Open"
        } else if hours.session == .pre {
            return "Pre-Market"
        } else if hours.session == .after {
            return "After Hours"
        } else {
            return "Market Closed"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .modifier(PulsingModifier(isAnimating: marketHours?.isOpen ?? false))

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Pulsing Animation Modifier

private struct PulsingModifier: ViewModifier {
    let isAnimating: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.5 : 1.0)
            .animation(
                isAnimating ?
                    Animation
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true) :
                    .default,
                value: isPulsing
            )
            .onAppear {
                if isAnimating {
                    isPulsing = true
                }
            }
            .onChange(of: isAnimating) { _, newValue in
                isPulsing = newValue
            }
    }
}

// MARK: - Dashboard Market Status Card

/// Full card version for dashboard
struct MarketStatusCard: View {

    let marketHours: MarketHours?
    var onTap: (() -> Void)?

    private var isOpen: Bool {
        marketHours?.isOpen ?? false
    }

    private var statusColor: Color {
        guard let hours = marketHours else { return .gray }

        if hours.isOpen {
            return Color.positive
        } else if hours.isExtendedHours {
            return Color.warning
        } else {
            return Color.negative
        }
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: isOpen ? "checkmark.circle.fill" : "moon.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(statusColor)
                }

                // Status text
                VStack(alignment: .leading, spacing: 4) {
                    Text(marketHours?.statusText ?? "Loading...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let nextEvent = marketHours?.nextEventLabel, !nextEvent.isEmpty {
                        Text(nextEvent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let session = marketHours?.session.displayName {
                        Text(session)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Exchange
                if let exchange = marketHours?.exchange {
                    Text(exchange)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .glassCard(material: .regular, cornerRadius: Constants.UI.glassCornerRadius)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Default Badge") {
    VStack(spacing: 20) {
        MarketStatusBadge(
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: true,
                session: .regular,
                nextClose: Date().addingTimeInterval(3600 * 4)
            )
        )

        MarketStatusBadge(
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: false,
                session: .closed,
                nextOpen: Date().addingTimeInterval(3600 * 12)
            )
        )

        MarketStatusBadge(
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: false,
                session: .pre
            )
        )

        MarketStatusBadge(
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: false,
                session: .after
            )
        )
    }
    .padding()
}

#Preview("Compact Badge") {
    VStack(spacing: 20) {
        MarketStatusBadge(
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: true,
                session: .regular
            ),
            style: .compact
        )

        MarketStatusBadge(
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: false,
                session: .closed
            ),
            style: .compact
        )
    }
    .padding()
}

#Preview("Detailed Badge") {
    VStack(spacing: 20) {
        MarketStatusBadge(
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: true,
                session: .regular,
                nextClose: Date().addingTimeInterval(3600 * 4)
            ),
            style: .detailed
        )

        MarketStatusBadge(
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: false,
                session: .closed,
                nextOpen: Date().addingTimeInterval(3600 * 12)
            ),
            style: .detailed
        )
    }
    .padding()
}

#Preview("Market Status Card") {
    VStack(spacing: 20) {
        MarketStatusCard(
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: true,
                session: .regular,
                nextClose: Date().addingTimeInterval(3600 * 4)
            )
        )

        MarketStatusCard(
            marketHours: MarketHours(
                exchange: "NYSE",
                isOpen: false,
                session: .closed,
                nextOpen: Date().addingTimeInterval(3600 * 12)
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
