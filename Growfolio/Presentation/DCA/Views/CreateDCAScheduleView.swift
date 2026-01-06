//
//  CreateDCAScheduleView.swift
//  Growfolio
//
//  View for creating or editing a DCA schedule.
//

import SwiftUI

struct CreateDCAScheduleView: View {

    // MARK: - Properties

    let scheduleToEdit: DCASchedule?
    let onSave: (String, Decimal, DCAFrequency, Date, Date?, String) -> Void
    let onCancel: () -> Void

    @State private var stockSymbol: String = ""
    @State private var stockSearchQuery: String = ""
    @State private var amount: String = ""
    @State private var frequency: DCAFrequency = .monthly
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date().adding(years: 1) ?? Date()
    @State private var portfolioId: String = "default"

    @State private var showStockSearch = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case symbol, amount
    }

    private var isEditing: Bool {
        scheduleToEdit != nil
    }

    private var canSave: Bool {
        !stockSymbol.isEmpty && (Decimal(string: amount) ?? 0) > 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Stock Selection
                Section("Investment") {
                    if isEditing {
                        HStack {
                            Text("Stock")
                            Spacer()
                            Text(stockSymbol)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button {
                            showStockSearch = true
                        } label: {
                            HStack {
                                Text(stockSymbol.isEmpty ? "Select Stock" : stockSymbol)
                                    .foregroundStyle(stockSymbol.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Amount per execution", text: $amount)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                    }
                }

                // Frequency
                Section("Schedule") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(DCAFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    if !isEditing {
                        DatePicker(
                            "Start Date",
                            selection: $startDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }

                    Toggle("Set End Date", isOn: $hasEndDate.animation())

                    if hasEndDate {
                        DatePicker(
                            "End Date",
                            selection: $endDate,
                            in: startDate.adding(days: 1)...,
                            displayedComponents: .date
                        )
                    }
                }

                // Estimate Section
                if let amountDecimal = Decimal(string: amount), amountDecimal > 0 {
                    Section("Estimated Investment") {
                        HStack {
                            Text("Monthly")
                            Spacer()
                            Text(monthlyEstimate(amountDecimal).currencyString)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Yearly")
                            Spacer()
                            Text(yearlyEstimate(amountDecimal).currencyString)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Executions/Year")
                            Spacer()
                            Text("\(frequency.executionsPerYear)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Popular Stocks
                if !isEditing && stockSymbol.isEmpty {
                    Section("Popular Stocks") {
                        ForEach([
                            ("VOO", "Vanguard S&P 500 ETF"),
                            ("AAPL", "Apple Inc."),
                            ("QQQ", "Invesco QQQ Trust"),
                            ("VTI", "Vanguard Total Stock Market"),
                            ("MSFT", "Microsoft Corporation")
                        ], id: \.0) { stock in
                            Button {
                                stockSymbol = stock.0
                            } label: {
                                HStack {
                                    Text(stock.0)
                                        .fontWeight(.medium)
                                    Text(stock.1)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if stockSymbol == stock.0 {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.trustBlue)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Schedule" : "New DCA Schedule")
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
            .sheet(isPresented: $showStockSearch) {
                stockSearchSheet
            }
            .onAppear {
                if let schedule = scheduleToEdit {
                    stockSymbol = schedule.stockSymbol
                    amount = "\(schedule.amount)"
                    frequency = schedule.frequency
                    if let end = schedule.endDate {
                        hasEndDate = true
                        endDate = end
                    }
                }
            }
        }
    }

    // MARK: - Stock Search Sheet

    private var stockSearchSheet: some View {
        NavigationStack {
            VStack {
                TextField("Search stocks...", text: $stockSearchQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                List {
                    // In a real app, this would call the StocksRepository to search
                    ForEach([
                        ("VOO", "Vanguard S&P 500 ETF"),
                        ("AAPL", "Apple Inc."),
                        ("GOOGL", "Alphabet Inc."),
                        ("MSFT", "Microsoft Corporation"),
                        ("AMZN", "Amazon.com Inc."),
                        ("TSLA", "Tesla Inc."),
                        ("QQQ", "Invesco QQQ Trust"),
                        ("VTI", "Vanguard Total Stock Market"),
                        ("SPY", "SPDR S&P 500 ETF Trust"),
                        ("NVDA", "NVIDIA Corporation")
                    ].filter { stockSearchQuery.isEmpty || $0.0.contains(stockSearchQuery.uppercased()) || $0.1.lowercased().contains(stockSearchQuery.lowercased()) }, id: \.0) { stock in
                        Button {
                            stockSymbol = stock.0
                            showStockSearch = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(stock.0)
                                        .font(.headline)
                                    Text(stock.1)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Select Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showStockSearch = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Calculations

    private func monthlyEstimate(_ amount: Decimal) -> Decimal {
        amount * Decimal(frequency.executionsPerYear) / 12
    }

    private func yearlyEstimate(_ amount: Decimal) -> Decimal {
        amount * Decimal(frequency.executionsPerYear)
    }

    // MARK: - Actions

    private func save() {
        guard let amountDecimal = Decimal(string: amount) else { return }

        onSave(
            stockSymbol,
            amountDecimal,
            frequency,
            startDate,
            hasEndDate ? endDate : nil,
            portfolioId
        )
    }
}

// MARK: - Preview

#Preview {
    CreateDCAScheduleView(
        scheduleToEdit: nil,
        onSave: { _, _, _, _, _, _ in },
        onCancel: {}
    )
}
