//
//  CurrencyPickerView.swift
//  Growfolio
//
//  View for selecting display currency preference.
//

import SwiftUI

struct CurrencyPickerView: View {

    // MARK: - Properties

    let selectedCurrency: String
    let onSelect: (String) -> Void
    let onCancel: () -> Void

    @State private var currentSelection: String
    @State private var searchText: String = ""

    // MARK: - Initialization

    init(
        selectedCurrency: String,
        onSelect: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.selectedCurrency = selectedCurrency
        self.onSelect = onSelect
        self.onCancel = onCancel
        self._currentSelection = State(initialValue: selectedCurrency)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Current Selection Header
                currentSelectionHeader

                // Currency List
                List {
                    // Primary Currencies Section
                    Section {
                        ForEach(filteredPrimaryCurrencies, id: \.code) { currency in
                            currencyRow(currency)
                        }
                    } header: {
                        Text("Primary")
                    } footer: {
                        Text("GBP is recommended for UK-based investors.")
                    }

                    // Other Currencies Section
                    if !filteredSecondaryCurrencies.isEmpty {
                        Section("Other Currencies") {
                            ForEach(filteredSecondaryCurrencies, id: \.code) { currency in
                                currencyRow(currency)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search currencies")
            }
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        UserDefaults.standard.set(currentSelection, forKey: Constants.StorageKeys.preferredCurrency)
                        onSelect(currentSelection)
                    }
                    .fontWeight(.semibold)
                    .disabled(currentSelection == selectedCurrency)
                }
            }
        }
    }

    // MARK: - Current Selection Header

    private var currentSelectionHeader: some View {
        VStack(spacing: 8) {
            if let currency = allCurrencies.first(where: { $0.code == currentSelection }) {
                HStack(spacing: 16) {
                    // Currency Symbol
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Text(currency.symbol)
                            .font(.title)
                            .fontWeight(.semibold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(currency.name)
                            .font(.headline)

                        Text(currency.code)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.positive)
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Currency Row

    private func currencyRow(_ currency: CurrencyInfo) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                currentSelection = currency.code
            }
        } label: {
            HStack(spacing: 16) {
                // Symbol Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(currency.code == currentSelection ? Color.blue.opacity(0.15) : Color(.systemGray5))
                        .frame(width: 44, height: 44)

                    Text(currency.symbol)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(currency.code == currentSelection ? Color.trustBlue : .primary)
                }

                // Currency Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.code)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(currency.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection Indicator
                if currency.code == currentSelection {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.trustBlue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private var allCurrencies: [CurrencyInfo] {
        SettingsViewModel.availableCurrencies.map { currency in
            CurrencyInfo(code: currency.code, name: currency.name, symbol: currency.symbol)
        }
    }

    private var primaryCurrencies: [CurrencyInfo] {
        // GBP and USD are primary for this app (UK investors in US equities)
        allCurrencies.filter { ["GBP", "USD", "EUR"].contains($0.code) }
    }

    private var secondaryCurrencies: [CurrencyInfo] {
        allCurrencies.filter { !["GBP", "USD", "EUR"].contains($0.code) }
    }

    private var filteredPrimaryCurrencies: [CurrencyInfo] {
        if searchText.isEmpty {
            return primaryCurrencies
        }
        return primaryCurrencies.filter { matches($0, searchText: searchText) }
    }

    private var filteredSecondaryCurrencies: [CurrencyInfo] {
        if searchText.isEmpty {
            return secondaryCurrencies
        }
        return secondaryCurrencies.filter { matches($0, searchText: searchText) }
    }

    private func matches(_ currency: CurrencyInfo, searchText: String) -> Bool {
        let search = searchText.lowercased()
        return currency.code.lowercased().contains(search) ||
               currency.name.lowercased().contains(search) ||
               currency.symbol.contains(search)
    }
}

// MARK: - Currency Info

private struct CurrencyInfo: Identifiable {
    let code: String
    let name: String
    let symbol: String

    var id: String { code }
}

// MARK: - Preview

#Preview {
    CurrencyPickerView(
        selectedCurrency: "GBP",
        onSelect: { _ in },
        onCancel: {}
    )
}
