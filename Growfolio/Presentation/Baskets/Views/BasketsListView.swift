//
//  BasketsListView.swift
//  Growfolio
//
//  Main view for the Baskets tab showing list of user baskets.
//

import SwiftUI

struct BasketsListView: View {
    @State private var viewModel = BasketsViewModel()
    @State private var showingCreateBasket = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.baskets.isEmpty {
                    loadingView
                } else if viewModel.baskets.isEmpty {
                    emptyStateView
                } else {
                    basketsList
                }
            }
            .navigationTitle("Baskets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateBasket = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreateBasket) {
                CreateBasketView()
                    .onDisappear {
                        Task {
                            await viewModel.refreshBaskets()
                        }
                    }
            }
            .task {
                await viewModel.loadBaskets()
            }
            .refreshable {
                await viewModel.refreshBaskets()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Subviews

    private var basketsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary header
                summaryHeader

                // Baskets list
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.baskets) { basket in
                        NavigationLink {
                            BasketDetailView(basket: basket)
                        } label: {
                            BasketCard(basket: basket)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteBasket(basket)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Portfolio Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalValue.currencyString)
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Gain/Loss")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalGainLoss.currencyString)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.totalGainLoss >= 0 ? .green : .red)
                }
            }

            Divider()

            HStack {
                Label("\(viewModel.activeBaskets.count) Active", systemImage: "play.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)

                Spacer()

                Label("\(viewModel.pausedBaskets.count) Paused", systemImage: "pause.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "basket.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            Text("No Baskets Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first basket to group stocks\nwith custom allocations and DCA schedules")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingCreateBasket = true
            } label: {
                Label("Create Basket", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding()
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Loading baskets...")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }
}

// MARK: - Preview

#Preview {
    BasketsListView()
}
