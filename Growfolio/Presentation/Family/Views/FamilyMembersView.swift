//
//  FamilyMembersView.swift
//  Growfolio
//
//  View displaying all family members with their roles and status.
//

import SwiftUI

struct FamilyMembersView: View {

    // MARK: - Properties

    let members: [FamilyMember]
    let isAdmin: Bool
    let onMemberSelected: (FamilyMember) -> Void
    let onInviteTapped: () -> Void

    @State private var searchText = ""
    @State private var filterRole: FamilyMemberRole?

    // MARK: - Computed Properties

    private var filteredMembers: [FamilyMember] {
        var result = members

        // Filter by search
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by role
        if let role = filterRole {
            result = result.filter { $0.role == role }
        }

        // Sort: admins first, then by name
        return result.sorted { member1, member2 in
            if member1.role == .admin && member2.role != .admin {
                return true
            } else if member1.role != .admin && member2.role == .admin {
                return false
            }
            return member1.name.localizedCaseInsensitiveCompare(member2.name) == .orderedAscending
        }
    }

    private var activeCount: Int {
        members.filter { $0.isActive }.count
    }

    private var pendingCount: Int {
        members.filter { $0.status == .pending || $0.status == .invited }.count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Stats Section
                Section {
                    HStack(spacing: 20) {
                        statView(count: members.count, label: "Total")
                        Divider()
                        statView(count: activeCount, label: "Active", color: Color.growthGreen)
                        Divider()
                        statView(count: pendingCount, label: "Pending", color: Color.prosperityGold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // Members List
                Section {
                    ForEach(filteredMembers) { member in
                        MemberRow(
                            member: member,
                            onTap: { onMemberSelected(member) }
                        )
                    }
                } header: {
                    HStack {
                        Text("Members")
                        Spacer()
                        if let role = filterRole {
                            Button {
                                filterRole = nil
                            } label: {
                                HStack(spacing: 4) {
                                    Text(role.displayName)
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .font(.caption)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search members")
            .navigationTitle("Members")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if isAdmin {
                            Button {
                                onInviteTapped()
                            } label: {
                                Label("Invite Member", systemImage: "person.badge.plus")
                            }
                            Divider()
                        }

                        Menu("Filter by Role") {
                            Button("All Roles") {
                                filterRole = nil
                            }
                            Divider()
                            ForEach(FamilyMemberRole.allCases, id: \.self) { role in
                                Button {
                                    filterRole = role
                                } label: {
                                    HStack {
                                        Label(role.displayName, systemImage: role.iconName)
                                        if filterRole == role {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    // MARK: - Stat View

    private func statView(count: Int, label: String, color: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Member Row

struct MemberRow: View {
    let member: FamilyMember
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                MemberAvatarView(member: member, size: 48)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(member.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        if member.role == .admin {
                            Image(systemName: "shield.fill")
                                .font(.caption)
                                .foregroundStyle(Color.trustBlue)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(member.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Status & Role
                VStack(alignment: .trailing, spacing: 4) {
                    Text(member.role.displayName)
                        .font(.caption)
                        .foregroundStyle(Color(hex: member.role.colorHex))

                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: member.statusColorHex))
                            .frame(width: 6, height: 6)

                        Text(member.statusDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Member Avatar View

struct MemberAvatarView: View {
    let member: FamilyMember
    let size: CGFloat
    var showStatus: Bool = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Avatar
            if let pictureUrl = member.pictureUrl, let url = URL(string: pictureUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                initialsView
            }

            // Status indicator
            if showStatus {
                Circle()
                    .fill(Color(hex: member.statusColorHex))
                    .frame(width: size * 0.25, height: size * 0.25)
                    .overlay {
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var initialsView: some View {
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
    FamilyMembersView(
        members: [
            FamilyMember(
                userId: "1",
                name: "John Smith",
                email: "john@example.com",
                role: .admin,
                status: .active
            ),
            FamilyMember(
                userId: "2",
                name: "Jane Smith",
                email: "jane@example.com",
                role: .member,
                status: .active
            ),
            FamilyMember(
                userId: "3",
                name: "Tom Smith",
                email: "tom@example.com",
                role: .viewer,
                status: .pending
            )
        ],
        isAdmin: true,
        onMemberSelected: { _ in },
        onInviteTapped: {}
    )
}
