//
//  PositionsView.swift
//  Growfolio
//
//  View for displaying and managing positions.
//

import SwiftUI

struct PositionsView: View {
    @State private var viewModel = PositionsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.positions.isEmpty {
                    ProgressView("Loading positions...")
                } else if viewModel.isEmpty {
                    emptyState
                } else {
                    positionsList
                }
            }
            .navigationTitle("Positions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    sortMenu
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadPositions()
            }
        }
    }

    // MARK: - Subviews

    private var positionsList: some View {
        List {
            // Summary Section
            Section {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Value")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(viewModel.totalMarketValueUsd.formatted(.currency(code: "USD")))
                                .font(.title2)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total P&L")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Text(viewModel.totalUnrealizedPnlUsd.formatted(.currency(code: "USD")))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(viewModel.isProfitable ? .green : .red)

                                Image(systemName: viewModel.isProfitable ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption)
                                    .foregroundStyle(viewModel.isProfitable ? .green : .red)
                            }
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Overall Return")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(viewModel.overallReturnPercentage.formatted(.percent.precision(.fractionLength(2))))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(viewModel.isProfitable ? .green : .red)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Positions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(viewModel.positions.count)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            // Top Gainers
            if !viewModel.topGainers.isEmpty {
                Section("Top Gainers") {
                    ForEach(viewModel.topGainers) { position in
                        PositionRow(position: position)
                    }
                }
            }

            // Top Losers
            if !viewModel.topLosers.isEmpty && viewModel.topLosers.first?.unrealizedPnlUsd ?? 0 < 0 {
                Section("Top Losers") {
                    ForEach(viewModel.topLosers.filter { $0.unrealizedPnlUsd < 0 }) { position in
                        PositionRow(position: position)
                    }
                }
            }

            // All Positions
            Section("All Positions") {
                ForEach(viewModel.filteredPositions) { position in
                    PositionRow(position: position)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Positions Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your investment positions will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $viewModel.sortOption) {
                ForEach(PositionsViewModel.SortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }

            Divider()

            Toggle("Only Profitable", isOn: $viewModel.showOnlyProfitable)
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}

// MARK: - Position Row

struct PositionRow: View {
    let position: Position

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(position.symbol)
                    .font(.headline)

                HStack(spacing: 4) {
                    Text("\(position.quantity.description)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("shares")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text("@\(position.averageEntryPrice.formatted(.currency(code: "USD")))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(position.marketValueUsd.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(position.unrealizedPnlUsd.formatted(.currency(code: "USD")))
                        .font(.caption)
                        .foregroundStyle(position.unrealizedPnlUsd >= 0 ? .green : .red)

                    Text("(\(position.changePct.formatted(.percent.precision(.fractionLength(2)))))")
                        .font(.caption)
                        .foregroundStyle(position.unrealizedPnlUsd >= 0 ? .green : .red)

                    Image(systemName: position.unrealizedPnlUsd >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                        .foregroundStyle(position.unrealizedPnlUsd >= 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    PositionsView()
}
