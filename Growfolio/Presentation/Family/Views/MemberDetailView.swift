//
//  MemberDetailView.swift
//  Growfolio
//
//  Detailed view for an individual family member with permissions management.
//

import SwiftUI

struct MemberDetailView: View {

    // MARK: - Properties

    let member: FamilyMember
    let isAdmin: Bool
    let isOwner: Bool
    let onUpdateRole: (FamilyMemberRole) -> Void
    let onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showRoleSheet = false
    @State private var showRemoveConfirmation = false

    private var canModify: Bool {
        isAdmin && member.role != .admin
    }

    private var canRemove: Bool {
        isOwner || (isAdmin && member.role != .admin)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader

                    // Role & Status Card
                    roleStatusCard

                    // Privacy Settings Card
                    privacySettingsCard

                    // Member Info Card
                    memberInfoCard

                    // Actions
                    if canRemove {
                        actionsSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Member Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRoleSheet) {
                rolePickerSheet
            }
            .alert("Remove Member?", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    onRemove()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to remove \(member.name) from the family? They will lose access to all shared information.")
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Large Avatar
            ZStack {
                if let pictureUrl = member.pictureUrl, let url = URL(string: pictureUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        initialsView(size: 100)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    initialsView(size: 100)
                }

                // Status indicator
                Circle()
                    .fill(Color(hex: member.statusColorHex))
                    .frame(width: 24, height: 24)
                    .overlay {
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 3)
                    }
                    .offset(x: 35, y: 35)
            }

            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(member.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    if member.role == .admin {
                        Image(systemName: "shield.fill")
                            .foregroundStyle(Color.trustBlue)
                    }
                }

                Text(member.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Role & Status Card

    private var roleStatusCard: some View {
        VStack(spacing: 0) {
            // Role
            Button {
                if canModify {
                    showRoleSheet = true
                }
            } label: {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Role")
                                .foregroundStyle(.primary)
                            Text(member.role.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: member.role.iconName)
                            .foregroundStyle(Color(hex: member.role.colorHex))
                    }

                    Spacer()

                    Text(member.role.displayName)
                        .foregroundStyle(Color(hex: member.role.colorHex))
                        .fontWeight(.medium)

                    if canModify {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .disabled(!canModify)

            Divider()
                .padding(.leading, 56)

            // Status
            HStack {
                Label {
                    Text("Status")
                } icon: {
                    Image(systemName: member.status.iconName)
                        .foregroundStyle(Color(hex: member.statusColorHex))
                }

                Spacer()

                Text(member.statusDescription)
                    .foregroundStyle(Color(hex: member.statusColorHex))
                    .fontWeight(.medium)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Privacy Settings Card

    private var privacySettingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sharing Preferences")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            VStack(spacing: 0) {
                privacyRow(
                    title: "Portfolio Value",
                    icon: "dollarsign.circle",
                    isEnabled: member.sharePortfolioValue
                )

                Divider()
                    .padding(.leading, 56)

                privacyRow(
                    title: "Holdings",
                    icon: "chart.pie",
                    isEnabled: member.shareHoldings
                )

                Divider()
                    .padding(.leading, 56)

                privacyRow(
                    title: "Performance",
                    icon: "chart.line.uptrend.xyaxis",
                    isEnabled: member.sharePerformance
                )
            }
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func privacyRow(title: String, icon: String, isEnabled: Bool) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isEnabled ? Color.positive : .secondary)

                Text(isEnabled ? "Shared" : "Private")
                    .font(.subheadline)
                    .foregroundStyle(isEnabled ? Color.positive : .secondary)
            }
        }
        .padding()
    }

    // MARK: - Member Info Card

    private var memberInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Member Since")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            VStack(spacing: 0) {
                infoRow(title: "Joined", value: member.joinedAt.displayString)
            }
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .padding()
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(role: .destructive) {
                showRemoveConfirmation = true
            } label: {
                Label("Remove from Family", systemImage: "person.badge.minus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    // MARK: - Role Picker Sheet

    private var rolePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(FamilyMemberRole.allCases, id: \.self) { role in
                    Button {
                        onUpdateRole(role)
                        showRoleSheet = false
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: role.colorHex).opacity(0.2))
                                    .frame(width: 44, height: 44)

                                Image(systemName: role.iconName)
                                    .font(.title3)
                                    .foregroundStyle(Color(hex: role.colorHex))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(role.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)

                                Text(role.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if member.role == role {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.trustBlue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Change Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showRoleSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    private func initialsView(size: CGFloat) -> some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: size, height: size)
            .overlay {
                Text(member.initials)
                    .font(.system(size: size * 0.38))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.trustBlue)
            }
    }
}

// MARK: - Preview

#Preview {
    MemberDetailView(
        member: FamilyMember(
            userId: "user-1",
            name: "Jane Smith",
            email: "jane@example.com",
            role: .member,
            pictureUrl: nil,
            joinedAt: Date().addingTimeInterval(-86400 * 30),
            status: .active,
            sharePortfolioValue: true,
            shareHoldings: false,
            sharePerformance: true
        ),
        isAdmin: true,
        isOwner: true,
        onUpdateRole: { _ in },
        onRemove: {}
    )
}
