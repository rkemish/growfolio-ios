//
//  InviteMemberView.swift
//  Growfolio
//
//  View for inviting a new member to the family by email.
//

import SwiftUI

struct InviteMemberView: View {

    // MARK: - Properties

    let onInvite: (String, FamilyMemberRole, String?) -> Void
    let onCancel: () -> Void

    @State private var email: String = ""
    @State private var role: FamilyMemberRole = .member
    @State private var message: String = ""
    @State private var showRolePicker = false
    @State private var isInviting = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case email, message
    }

    private var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.range(of: emailRegex, options: .regularExpression) != nil
    }

    private var canInvite: Bool {
        isValidEmail
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Email Section
                Section {
                    TextField("Email Address", text: $email)
                        .focused($focusedField, equals: .email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Invite By Email")
                } footer: {
                    if !email.isEmpty && !isValidEmail {
                        Label("Please enter a valid email address", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(Color.negative)
                            .font(.caption)
                    }
                }

                // Role Section
                Section {
                    Button {
                        showRolePicker = true
                    } label: {
                        HStack {
                            Label {
                                Text("Role")
                            } icon: {
                                Image(systemName: role.iconName)
                                    .foregroundStyle(Color(hex: role.colorHex))
                            }

                            Spacer()

                            Text(role.displayName)
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Permissions")
                } footer: {
                    Text(role.description)
                }

                // Message Section
                Section {
                    TextField("Add a personal message (optional)", text: $message, axis: .vertical)
                        .focused($focusedField, equals: .message)
                        .lineLimit(3...6)
                } header: {
                    Text("Personal Message")
                } footer: {
                    Text("This message will be included in the invitation email.")
                }

                // Preview Section
                Section("Invitation Preview") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.title2)
                                .foregroundStyle(Color.trustBlue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("To: \(email.isEmpty ? "email@example.com" : email)")
                                    .font(.subheadline)
                                    .foregroundStyle(email.isEmpty ? .secondary : .primary)

                                Text("Role: \(role.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !message.isEmpty {
                            Divider()

                            Text("\"\(message)\"")
                                .font(.subheadline)
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Send Invite") {
                        sendInvite()
                    }
                    .disabled(!canInvite || isInviting)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .sheet(isPresented: $showRolePicker) {
                rolePickerSheet
            }
            .interactiveDismissDisabled(isInviting)
            .onAppear {
                focusedField = .email
            }
        }
    }

    // MARK: - Role Picker Sheet

    private var rolePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(FamilyMemberRole.allCases, id: \.self) { memberRole in
                    Button {
                        role = memberRole
                        showRolePicker = false
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: memberRole.colorHex).opacity(0.2))
                                    .frame(width: 44, height: 44)

                                Image(systemName: memberRole.iconName)
                                    .font(.title3)
                                    .foregroundStyle(Color(hex: memberRole.colorHex))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(memberRole.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)

                                Text(memberRole.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if role == memberRole {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.trustBlue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showRolePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func sendInvite() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

        isInviting = true
        onInvite(
            trimmedEmail,
            role,
            trimmedMessage.isEmpty ? nil : trimmedMessage
        )
    }
}

// MARK: - Preview

#Preview {
    InviteMemberView(
        onInvite: { _, _, _ in },
        onCancel: {}
    )
}
