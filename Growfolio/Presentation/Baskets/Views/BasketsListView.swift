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
    @State private var selectedBasketForNavigation: Basket?
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(NavigationState.self) private var navState: NavigationState?

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
            .navigationDestination(item: $selectedBasketForNavigation) { basket in
                BasketDetailView(basket: basket)
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
                        BasketCard(basket: basket)
                            .onTapGesture {
                                if sizeClass == .compact {
                                    // iPhone: Navigate using NavigationStack
                                    selectedBasketForNavigation = basket
                                } else {
                                    // iPad: Update navigation state
                                    navState?.selectedBasket = basket
                                }
                            }
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
        ContentUnavailableView {
            Label("No Baskets Yet", systemImage: "basket.fill")
        } description: {
            VStack(spacing: 16) {
                Text("Create custom stock baskets with specific allocations for diversified investing.")
                    .multilineTextAlignment(.center)

                // Educational steps
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "1.circle.fill")
                            .foregroundStyle(Color.trustBlue)
                        Text("Name your basket and choose stocks")
                            .font(.subheadline)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "2.circle.fill")
                            .foregroundStyle(Color.trustBlue)
                        Text("Set allocation percentages (must total 100%)")
                            .font(.subheadline)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "3.circle.fill")
                            .foregroundStyle(Color.trustBlue)
                        Text("Link to DCA schedules for automatic rebalancing")
                            .font(.subheadline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        } actions: {
            Button {
                showingCreateBasket = true
            } label: {
                Text("Create Your First Basket")
            }
            .buttonStyle(.borderedProminent)
        }
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
