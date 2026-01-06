//
//  StockActionsView.swift
//  Growfolio
//
//  Buy/Add to DCA action buttons for stock detail view.
//

import SwiftUI

struct StockActionsView: View {

    // MARK: - Properties

    let onBuy: () -> Void
    let onAddToDCA: () -> Void
    var showWatchlist: Bool = true
    var isInWatchlist: Bool = false
    var onToggleWatchlist: (() -> Void)? = nil

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Primary Actions
            HStack(spacing: 12) {
                // Buy Button
                Button(action: onBuy) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("Buy")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.positive)

                // Add to DCA Button
                Button(action: onAddToDCA) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Add to DCA")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.trustBlue)
            }

            // Secondary Action - Watchlist
            if showWatchlist, let toggleWatchlist = onToggleWatchlist {
                Button(action: toggleWatchlist) {
                    HStack(spacing: 8) {
                        Image(systemName: isInWatchlist ? "star.fill" : "star")
                        Text(isInWatchlist ? "Remove from Watchlist" : "Add to Watchlist")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(isInWatchlist ? .yellow : .primary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Compact Actions View

struct CompactStockActionsView: View {
    let onBuy: () -> Void
    let onAddToDCA: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBuy) {
                Image(systemName: "cart.fill")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.positive)

            Button(action: onAddToDCA) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.trustBlue)
        }
    }
}

// MARK: - Full Width Action Button

struct StockActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)

                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Quick Actions Row

struct StockQuickActionsRow: View {
    let symbol: String
    let onBuy: () -> Void
    let onSell: () -> Void
    let onAddToDCA: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            quickActionButton(
                icon: "cart.fill",
                label: "Buy",
                color: Color.growthGreen,
                action: onBuy
            )

            Divider()
                .frame(height: 30)

            quickActionButton(
                icon: "cart.badge.minus",
                label: "Sell",
                color: Color.negative,
                action: onSell
            )

            Divider()
                .frame(height: 30)

            quickActionButton(
                icon: "arrow.triangle.2.circlepath",
                label: "DCA",
                color: Color.trustBlue,
                action: onAddToDCA
            )

            Divider()
                .frame(height: 30)

            quickActionButton(
                icon: "square.and.arrow.up",
                label: "Share",
                color: Color.trustBlue,
                action: onShare
            )
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
    }

    private func quickActionButton(
        icon: String,
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Floating Action Button

struct StockFloatingActionButton: View {
    let onBuy: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if isExpanded {
                VStack(spacing: 8) {
                    miniActionButton(icon: "star", label: "Watch") {}
                    miniActionButton(icon: "arrow.triangle.2.circlepath", label: "DCA") {}
                    miniActionButton(icon: "cart.fill", label: "Buy", color: Color.growthGreen, action: onBuy)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.blue))
                    .shadow(color: Color.trustBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }

    private func miniActionButton(
        icon: String,
        label: String,
        color: Color = Color.trustBlue,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Image(systemName: icon)
                    .font(.body)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(color))
            .foregroundStyle(.white)
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        StockActionsView(
            onBuy: {},
            onAddToDCA: {},
            showWatchlist: true,
            isInWatchlist: false,
            onToggleWatchlist: {}
        )

        StockQuickActionsRow(
            symbol: "AAPL",
            onBuy: {},
            onSell: {},
            onAddToDCA: {},
            onShare: {}
        )
        .padding(.horizontal)

        CompactStockActionsView(
            onBuy: {},
            onAddToDCA: {}
        )

        StockActionButton(
            title: "Buy Apple Stock",
            icon: "cart.fill",
            color: Color.growthGreen,
            action: {}
        )
        .padding(.horizontal)

        Spacer()

        HStack {
            Spacer()
            StockFloatingActionButton(onBuy: {})
        }
        .padding()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
