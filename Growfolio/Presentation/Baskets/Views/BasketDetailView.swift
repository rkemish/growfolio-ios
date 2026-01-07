//
//  BasketDetailView.swift
//  Growfolio
//
//  Detail view for a single basket.
//

import SwiftUI

struct BasketDetailView: View {
    @State private var viewModel: BasketDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(basket: Basket) {
        _viewModel = State(initialValue: BasketDetailViewModel(basket: basket))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Performance Summary
                performanceSection

                // Allocations
                allocationsSection

                // Actions
                actionsSection
            }
            .padding()
        }
        .navigationTitle(viewModel.basket.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task {
                            await viewModel.toggleStatus()
                        }
                    } label: {
                        Label(
                            viewModel.basket.status == .active ? "Pause Basket" : "Resume Basket",
                            systemImage: viewModel.basket.status == .active ? "pause.circle" : "play.circle"
                        )
                    }

                    Button(role: .destructive) {
                        // Handle delete
                        dismiss()
                    } label: {
                        Label("Delete Basket", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(spacing: 16) {
            // Icon
            if let icon = viewModel.basket.icon {
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(Color(hex: viewModel.basket.color ?? "#007AFF"))
                    .frame(width: 80, height: 80)
                    .background(Color(hex: viewModel.basket.color ?? "#007AFF").opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            VStack(alignment: .leading, spacing: 8) {
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: viewModel.basket.status.iconName)
                        .font(.caption2)
                    Text(viewModel.basket.status.displayName)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: viewModel.basket.status.colorHex).opacity(0.1))
                .foregroundStyle(Color(hex: viewModel.basket.status.colorHex))
                .clipShape(Capsule())

                if let category = viewModel.basket.category {
                    Text(category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let description = viewModel.basket.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var performanceSection: some View {
        VStack(spacing: 16) {
            Text("Performance")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                performanceRow(
                    title: "Current Value",
                    value: viewModel.basket.summary.currentValue.currencyString,
                    color: .primary
                )

                Divider()

                performanceRow(
                    title: "Total Invested",
                    value: viewModel.basket.summary.totalInvested.currencyString,
                    color: .secondary
                )

                Divider()

                performanceRow(
                    title: "Gain/Loss",
                    value: viewModel.basket.summary.totalGainLoss.currencyString,
                    color: viewModel.isGaining ? .green : .red
                )

                Divider()

                performanceRow(
                    title: "Return",
                    value: viewModel.returnPercentage.rawPercentString,
                    color: viewModel.isGaining ? .green : .red
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func performanceRow(title: String, value: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }

    private var allocationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Stock Allocations")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.basket.allocations.count) stocks")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(viewModel.basket.allocations) { allocation in
                    VStack(spacing: 0) {
                        BasketAllocationRow(allocation: allocation)

                        if allocation.id != viewModel.basket.allocations.last?.id {
                            Divider()
                                .padding(.leading, 74)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            if viewModel.basket.dcaEnabled {
                HStack(spacing: 12) {
                    Image(systemName: "repeat.circle.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DCA Enabled")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Automatic investments are active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if viewModel.basket.isShared {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.purple)
                    Text("Shared with family")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BasketDetailView(basket: Basket(
            userId: "user1",
            name: "Tech Giants",
            description: "Major technology companies for long-term growth",
            category: "Technology",
            icon: "laptopcomputer",
            color: "#007AFF",
            allocations: [
                BasketAllocation(symbol: "AAPL", name: "Apple Inc.", percentage: 40, targetShares: nil),
                BasketAllocation(symbol: "MSFT", name: "Microsoft Corporation", percentage: 30, targetShares: nil),
                BasketAllocation(symbol: "GOOGL", name: "Alphabet Inc.", percentage: 30, targetShares: nil)
            ],
            dcaEnabled: true,
            status: .active,
            summary: BasketSummary(
                currentValue: 15678.50,
                totalInvested: 12000,
                totalGainLoss: 3678.50
            ),
            isShared: true
        ))
    }
}
