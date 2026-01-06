//
//  EditProfileView.swift
//  Growfolio
//
//  View for editing user profile information.
//

import SwiftUI

struct EditProfileView: View {

    // MARK: - Properties

    let displayName: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var isSaving: Bool = false

    // Optional: Additional user info for display
    var email: String?
    var alpacaAccountStatus: AlpacaAccountStatus?

    // MARK: - Initialization

    init(
        displayName: String,
        email: String? = nil,
        alpacaAccountStatus: AlpacaAccountStatus? = nil,
        onSave: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.displayName = displayName
        self.email = email
        self.alpacaAccountStatus = alpacaAccountStatus
        self.onSave = onSave
        self.onCancel = onCancel
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Profile Photo Section
                profilePhotoSection

                // Personal Information Section
                personalInfoSection

                // Account Status Section
                if alpacaAccountStatus != nil || email != nil {
                    accountInfoSection
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveProfile()
                        }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                    }
                }
            }
            .onAppear {
                name = displayName
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    // MARK: - Profile Photo Section

    private var profilePhotoSection: some View {
        Section {
            HStack {
                Spacer()

                VStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.trustBlue.gradient)
                            .frame(width: 100, height: 100)

                        Text(initials)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    // Change Photo Button (placeholder for future implementation)
                    Button {
                        // Photo picker would go here
                    } label: {
                        Text("Change Photo")
                            .font(.subheadline)
                    }
                    .disabled(true) // Disabled until photo upload is implemented
                }

                Spacer()
            }
            .listRowBackground(Color.clear)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Personal Information Section

    private var personalInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Enter your name", text: $name)
                    .textContentType(.name)
                    .autocorrectionDisabled()

                if !name.isEmpty && name.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("Name cannot be only whitespace")
                        .font(.caption)
                        .foregroundStyle(Color.negative)
                }
            }
        } header: {
            Text("Personal Information")
        } footer: {
            Text("This name will be displayed throughout the app and in your portfolio summaries.")
        }
    }

    // MARK: - Account Info Section

    private var accountInfoSection: some View {
        Section("Account Information") {
            // Email (read-only)
            if let email = email {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(email)
                                .font(.body)
                        }
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Color.trustBlue)
                    }

                    Spacer()

                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Alpaca Account Status
            if let status = alpacaAccountStatus {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Brokerage Account")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(status.displayName)
                                .font(.body)
                        }
                    } icon: {
                        Image(systemName: status.iconName)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    statusBadge(for: status)
                }
            }
        }
    }

    private func statusBadge(for status: AlpacaAccountStatus) -> some View {
        Text(status.badgeText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.15))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }

    // MARK: - Computed Properties

    private var initials: String {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            return "?"
        }

        let components = trimmedName.components(separatedBy: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }

    private var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed != displayName
    }

    // MARK: - Actions

    private func saveProfile() {
        isSaving = true

        // Simulate brief delay for better UX feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onSave(name.trimmingCharacters(in: .whitespaces))
        }
    }
}

// MARK: - Alpaca Account Status

enum AlpacaAccountStatus {
    case notLinked
    case pending
    case active
    case suspended
    case closed

    var displayName: String {
        switch self {
        case .notLinked:
            return "Not Connected"
        case .pending:
            return "Pending Approval"
        case .active:
            return "Alpaca Securities"
        case .suspended:
            return "Account Suspended"
        case .closed:
            return "Account Closed"
        }
    }

    var iconName: String {
        switch self {
        case .notLinked:
            return "link.badge.plus"
        case .pending:
            return "clock.fill"
        case .active:
            return "checkmark.shield.fill"
        case .suspended:
            return "exclamationmark.triangle.fill"
        case .closed:
            return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .notLinked:
            return .gray
        case .pending:
            return Color.warning
        case .active:
            return Color.positive
        case .suspended:
            return Color.negative
        case .closed:
            return Color.negative
        }
    }

    var badgeText: String {
        switch self {
        case .notLinked:
            return "CONNECT"
        case .pending:
            return "PENDING"
        case .active:
            return "ACTIVE"
        case .suspended:
            return "SUSPENDED"
        case .closed:
            return "CLOSED"
        }
    }
}

// MARK: - Preview

#Preview("With Alpaca Account") {
    EditProfileView(
        displayName: "John Doe",
        email: "john.doe@example.com",
        alpacaAccountStatus: .active,
        onSave: { _ in },
        onCancel: {}
    )
}

#Preview("Basic") {
    EditProfileView(
        displayName: "John Doe",
        onSave: { _ in },
        onCancel: {}
    )
}
