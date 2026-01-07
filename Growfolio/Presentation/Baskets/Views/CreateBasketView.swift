//
//  CreateBasketView.swift
//  Growfolio
//
//  View for creating a new basket with allocations.
//

import SwiftUI

struct CreateBasketView: View {
    @State private var viewModel = CreateBasketViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Basket Name", text: $viewModel.name)
                        .autocorrectionDisabled()

                    TextField("Description (Optional)", text: $viewModel.description, axis: .vertical)
                        .lineLimit(2...4)

                    TextField("Category (Optional)", text: $viewModel.category)
                }

                // Appearance Section
                Section("Appearance") {
                    Picker("Icon", selection: $viewModel.selectedIcon) {
                        ForEach(CreateBasketViewModel.iconOptions, id: \.self) { icon in
                            Label(icon, systemImage: icon)
                                .tag(icon)
                        }
                    }

                    HStack {
                        Text("Color")
                        Spacer()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(CreateBasketViewModel.colorOptions, id: \.self) { color in
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 32, height: 32)
                                        .overlay {
                                            if viewModel.selectedColor == color {
                                                Circle()
                                                    .stroke(.white, lineWidth: 3)
                                                Image(systemName: "checkmark")
                                                    .foregroundStyle(.white)
                                                    .fontWeight(.bold)
                                            }
                                        }
                                        .onTapGesture {
                                            viewModel.selectedColor = color
                                        }
                                }
                            }
                        }
                    }
                }

                // Stock Allocations Section
                Section {
                    ForEach(Array(viewModel.allocations.enumerated()), id: \.element.id) { index, allocation in
                        VStack(spacing: 12) {
                            HStack {
                                Text("Stock \(index + 1)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                if viewModel.allocations.count > 1 {
                                    Button(role: .destructive) {
                                        viewModel.removeAllocation(at: index)
                                    } label: {
                                        Image(systemName: "trash.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                }
                            }

                            TextField("Symbol (e.g., AAPL)", text: Binding(
                                get: { viewModel.allocations[index].symbol },
                                set: { viewModel.allocations[index].symbol = $0 }
                            ))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()

                            TextField("Company Name", text: Binding(
                                get: { viewModel.allocations[index].name },
                                set: { viewModel.allocations[index].name = $0 }
                            ))

                            HStack {
                                TextField("Percentage", text: Binding(
                                    get: { viewModel.allocations[index].percentage },
                                    set: { viewModel.allocations[index].percentage = $0 }
                                ))
                                .keyboardType(.decimalPad)

                                Text("%")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Button {
                        viewModel.addAllocation()
                    } label: {
                        Label("Add Stock", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Stock Allocations")
                        Spacer()
                        Text("Total: \(viewModel.totalAllocationPercentage.rawPercentString)")
                            .foregroundStyle(
                                viewModel.totalAllocationPercentage == 100 ? .green : .orange
                            )
                    }
                }

                // Settings Section
                Section("Settings") {
                    Toggle("Share with Family", isOn: $viewModel.isShared)
                }

                // Validation Info
                Section {
                    if !viewModel.isValid {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Allocations must total 100%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Create Basket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            if await viewModel.createBasket() != nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isCreating)
                }
            }
            .disabled(viewModel.isCreating)
            .overlay {
                if viewModel.isCreating {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Creating basket...")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
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
}

// MARK: - Preview

#Preview {
    CreateBasketView()
}
