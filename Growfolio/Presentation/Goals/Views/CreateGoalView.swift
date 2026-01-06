//
//  CreateGoalView.swift
//  Growfolio
//
//  View for creating or editing a goal.
//

import SwiftUI

struct CreateGoalView: View {

    // MARK: - Properties

    let goalToEdit: Goal?
    let onSave: (String, Decimal, Date?, GoalCategory, String?) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = Date().adding(years: 1) ?? Date()
    @State private var category: GoalCategory = .investment
    @State private var notes: String = ""

    @State private var showCategoryPicker = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case name, amount, notes
    }

    private var isEditing: Bool {
        goalToEdit != nil
    }

    private var canSave: Bool {
        !name.isEmpty && (Decimal(string: targetAmount) ?? 0) > 0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Goal Details
                Section("Goal Details") {
                    TextField("Goal Name", text: $name)
                        .focused($focusedField, equals: .name)

                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Target Amount", text: $targetAmount)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                    }

                    Button {
                        showCategoryPicker = true
                    } label: {
                        HStack {
                            Label(category.displayName, systemImage: category.iconName)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                // Target Date
                Section {
                    Toggle("Set Target Date", isOn: $hasTargetDate.animation())

                    if hasTargetDate {
                        DatePicker(
                            "Target Date",
                            selection: $targetDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Timeline")
                } footer: {
                    if hasTargetDate {
                        Text("We'll calculate the monthly contribution needed to reach your goal.")
                    }
                }

                // Notes
                Section("Notes") {
                    TextField("Optional notes about this goal", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .notes)
                }

                // Quick Templates
                if !isEditing {
                    Section("Quick Start Templates") {
                        ForEach([
                            ("Emergency Fund", Decimal(50000), GoalCategory.emergency),
                            ("Retirement", Decimal(1000000), GoalCategory.retirement),
                            ("Vacation", Decimal(10000), GoalCategory.vacation),
                            ("Education", Decimal(100000), GoalCategory.education)
                        ], id: \.0) { template in
                            Button {
                                name = template.0
                                targetAmount = "\(template.1)"
                                category = template.2
                            } label: {
                                HStack {
                                    Image(systemName: template.2.iconName)
                                        .foregroundStyle(Color(hex: template.2.defaultColorHex))
                                    Text(template.0)
                                    Spacer()
                                    Text(template.1.currencyString)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
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
            .sheet(isPresented: $showCategoryPicker) {
                categoryPickerSheet
            }
            .onAppear {
                if let goal = goalToEdit {
                    name = goal.name
                    targetAmount = "\(goal.targetAmount)"
                    category = goal.category
                    notes = goal.notes ?? ""
                    if let date = goal.targetDate {
                        hasTargetDate = true
                        targetDate = date
                    }
                }
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(GoalCategory.allCases, id: \.self) { cat in
                    Button {
                        category = cat
                        showCategoryPicker = false
                    } label: {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: cat.defaultColorHex).opacity(0.2))
                                    .frame(width: 40, height: 40)

                                Image(systemName: cat.iconName)
                                    .foregroundStyle(Color(hex: cat.defaultColorHex))
                            }

                            Text(cat.displayName)
                                .foregroundStyle(.primary)

                            Spacer()

                            if category == cat {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.trustBlue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCategoryPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func save() {
        guard let amount = Decimal(string: targetAmount) else { return }

        onSave(
            name,
            amount,
            hasTargetDate ? targetDate : nil,
            category,
            notes.isEmpty ? nil : notes
        )
    }
}

// MARK: - Preview

#Preview {
    CreateGoalView(
        goalToEdit: nil,
        onSave: { _, _, _, _, _ in },
        onCancel: {}
    )
}
