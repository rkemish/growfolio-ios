//
//  AddTransactionView.swift
//  Growfolio
//
//  View for recording a new transaction.
//

import SwiftUI

struct AddTransactionView: View {

    // MARK: - Properties

    let onSave: (LedgerEntryType, String?, Decimal?, Decimal?, Decimal, String?) -> Void
    let onCancel: () -> Void

    @State private var transactionType: LedgerEntryType = .buy
    @State private var stockSymbol: String = ""
    @State private var quantity: String = ""
    @State private var pricePerShare: String = ""
    @State private var totalAmount: String = ""
    @State private var notes: String = ""
    @State private var transactionDate: Date = Date()

    @State private var useManualTotal = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case symbol, quantity, price, total, notes
    }

    private var requiresStock: Bool {
        transactionType.requiresStock
    }

    private var requiresQuantity: Bool {
        transactionType.requiresQuantity
    }

    private var calculatedTotal: Decimal {
        guard let qty = Decimal(string: quantity),
              let price = Decimal(string: pricePerShare) else {
            return 0
        }
        return qty * price
    }

    private var effectiveTotal: Decimal {
        if useManualTotal {
            return Decimal(string: totalAmount) ?? 0
        }
        return requiresQuantity ? calculatedTotal : (Decimal(string: totalAmount) ?? 0)
    }

    private var canSave: Bool {
        if requiresStock && stockSymbol.isEmpty {
            return false
        }
        if requiresQuantity {
            guard let _ = Decimal(string: quantity),
                  let _ = Decimal(string: pricePerShare) else {
                return false
            }
        }
        return effectiveTotal > 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Transaction Type
                Section("Transaction Type") {
                    Picker("Type", selection: $transactionType) {
                        ForEach(LedgerEntryType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: transactionType) { _, _ in
                        // Reset fields when type changes
                        if !transactionType.requiresStock {
                            stockSymbol = ""
                        }
                        if !transactionType.requiresQuantity {
                            quantity = ""
                            pricePerShare = ""
                        }
                    }
                }

                // Stock (if required)
                if requiresStock || transactionType == .dividend {
                    Section("Stock") {
                        TextField("Symbol (e.g., AAPL)", text: $stockSymbol)
                            .textInputAutocapitalization(.characters)
                            .focused($focusedField, equals: .symbol)
                    }
                }

                // Quantity and Price (for buy/sell)
                if requiresQuantity {
                    Section("Trade Details") {
                        HStack {
                            Text("Shares")
                            Spacer()
                            TextField("0", text: $quantity)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .quantity)
                        }

                        HStack {
                            Text("Price per Share")
                            Spacer()
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $pricePerShare)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: .price)
                        }

                        if calculatedTotal > 0 {
                            HStack {
                                Text("Total")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(calculatedTotal.currencyString)
                                    .fontWeight(.semibold)
                            }
                        }

                        Toggle("Enter Total Manually", isOn: $useManualTotal)
                    }
                }

                // Amount (for non-stock transactions or manual total)
                if !requiresQuantity || useManualTotal {
                    Section("Amount") {
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $totalAmount)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .total)
                        }
                    }
                }

                // Date
                Section("Date") {
                    DatePicker(
                        "Transaction Date",
                        selection: $transactionDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                // Notes
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .focused($focusedField, equals: .notes)
                }

                // Summary
                if canSave {
                    Section("Summary") {
                        summaryView
                    }
                }
            }
            .navigationTitle("Record Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!canSave)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }

    // MARK: - Summary View

    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: transactionType.iconName)
                    .foregroundStyle(Color(hex: transactionType.colorHex))
                Text(transactionType.displayName)
                    .fontWeight(.medium)
            }

            if !stockSymbol.isEmpty {
                Text(stockSymbol.uppercased())
                    .font(.headline)
            }

            if let qty = Decimal(string: quantity), qty > 0 {
                Text("\(qty.sharesString) shares @ \(Decimal(string: pricePerShare)?.currencyString ?? "$0")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(effectiveTotal.currencyString)
                .font(.title2)
                .fontWeight(.bold)
        }
    }

    // MARK: - Actions

    private func save() {
        onSave(
            transactionType,
            stockSymbol.isEmpty ? nil : stockSymbol.uppercased(),
            Decimal(string: quantity),
            Decimal(string: pricePerShare),
            effectiveTotal,
            notes.isEmpty ? nil : notes
        )
    }
}

// MARK: - Preview

#Preview {
    AddTransactionView(
        onSave: { _, _, _, _, _, _ in },
        onCancel: {}
    )
}
