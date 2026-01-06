//
//  CreateFamilyView.swift
//  Growfolio
//
//  View for creating a new family group.
//

import SwiftUI

struct CreateFamilyView: View {

    // MARK: - Properties

    let onSave: (String, String?) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var familyDescription: String = ""
    @State private var isCreating = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case name, description
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Family Details
                Section {
                    TextField("Family Name", text: $name)
                        .focused($focusedField, equals: .name)
                        .textContentType(.organizationName)

                    TextField("Description (optional)", text: $familyDescription, axis: .vertical)
                        .focused($focusedField, equals: .description)
                        .lineLimit(3...6)
                } header: {
                    Text("Family Details")
                } footer: {
                    Text("Give your family group a name that everyone will recognize.")
                }

                // Preview
                Section("Preview") {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: "person.3.fill")
                                .font(.title2)
                                .foregroundStyle(Color.trustBlue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "Family Name" : name)
                                .font(.headline)
                                .foregroundStyle(name.isEmpty ? .secondary : .primary)

                            Text(familyDescription.isEmpty ? "No description" : familyDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Info
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        infoRow(
                            icon: "person.badge.plus",
                            title: "Invite Members",
                            description: "Add family members after creating the group"
                        )

                        infoRow(
                            icon: "target",
                            title: "Shared Goals",
                            description: "Track financial goals together"
                        )

                        infoRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Progress Tracking",
                            description: "See how everyone is doing"
                        )

                        infoRow(
                            icon: "lock.shield",
                            title: "Privacy Controls",
                            description: "Members control what they share"
                        )
                    }
                } header: {
                    Text("What's Included")
                }
            }
            .navigationTitle("Create Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        save()
                    }
                    .disabled(!canSave || isCreating)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .interactiveDismissDisabled(isCreating)
            .onAppear {
                focusedField = .name
            }
        }
    }

    // MARK: - Info Row

    private func infoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.trustBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = familyDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        isCreating = true
        onSave(
            trimmedName,
            trimmedDescription.isEmpty ? nil : trimmedDescription
        )
    }
}

// MARK: - Preview

#Preview {
    CreateFamilyView(
        onSave: { _, _ in },
        onCancel: {}
    )
}
