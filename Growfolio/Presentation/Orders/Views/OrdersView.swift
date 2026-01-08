//
//  OrdersView.swift
//  Growfolio
//
//  View for displaying and managing orders.
//

import SwiftUI

struct OrdersView: View {
    @State private var viewModel = OrdersViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.orders.isEmpty {
                    ProgressView("Loading orders...")
                } else if viewModel.isEmpty {
                    emptyState
                } else {
                    ordersList
                }
            }
            .navigationTitle("Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    filterMenu
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadOrders()
            }
            .alert("Cancel Order", isPresented: $viewModel.showCancelConfirmation) {
                Button("Cancel", role: .destructive) {
                    if let order = viewModel.orderToCancel {
                        Task {
                            await viewModel.cancelOrder(order)
                        }
                    }
                }
                Button("Keep Order", role: .cancel) {
                    viewModel.orderToCancel = nil
                }
            } message: {
                if let order = viewModel.orderToCancel {
                    Text("Are you sure you want to cancel this \(order.side == .buy ? "buy" : "sell") order for \(order.symbol)?")
                }
            }
        }
    }

    // MARK: - Subviews

    private var ordersList: some View {
        List {
            // Summary Section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Orders")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.activeOrders.count)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.completedOrders.count)")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.vertical, 8)
            }

            // Active Orders
            if !viewModel.activeOrders.isEmpty {
                Section("Active") {
                    ForEach(viewModel.activeOrders) { order in
                        OrderRow(order: order) {
                            viewModel.confirmCancelOrder(order)
                        }
                    }
                }
            }

            // Completed Orders
            if !viewModel.completedOrders.isEmpty {
                Section("Completed") {
                    ForEach(viewModel.completedOrders) { order in
                        OrderRow(order: order, showCancelButton: false)
                    }
                }
            }

            // Cancelled Orders
            if !viewModel.cancelledOrders.isEmpty {
                Section("Cancelled") {
                    ForEach(viewModel.cancelledOrders) { order in
                        OrderRow(order: order, showCancelButton: false)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Orders Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your order history will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var filterMenu: some View {
        Menu {
            Picker("Status", selection: $viewModel.selectedStatus) {
                Text("All").tag(nil as OrderStatus?)
                ForEach([OrderStatus.filled, .partiallyFilled, .cancelled], id: \.self) { status in
                    Text(status.displayName).tag(status as OrderStatus?)
                }
            }

            Divider()

            Picker("Date Range", selection: $viewModel.dateFilter) {
                ForEach(OrdersViewModel.DateFilterOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

// MARK: - Order Row

struct OrderRow: View {
    let order: Order
    var showCancelButton: Bool = true
    var onCancel: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Order Side Indicator
            Circle()
                .fill(order.side == .buy ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(order.symbol)
                        .font(.headline)

                    Text(order.side == .buy ? "BUY" : "SELL")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(order.side == .buy ? .green : .red)
                }

                HStack(spacing: 4) {
                    Text(order.type.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(order.status.displayName)
                        .font(.caption)
                        .foregroundStyle(statusColor(for: order.status))
                }

                if let quantity = order.quantity {
                    Text("\(quantity.description) shares")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let price = order.filledAvgPrice ?? order.limitPrice {
                    Text("$\(price.description)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text(order.submittedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if showCancelButton && (order.status == .new || order.status == .accepted || order.status == .pendingNew) {
                    Button("Cancel") {
                        onCancel?()
                    }
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .filled:
            return .green
        case .partiallyFilled:
            return .orange
        case .cancelled:
            return .gray
        case .expired:
            return .red
        default:
            return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    OrdersView()
}
