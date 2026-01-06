//
//  FamilyView.swift
//  Growfolio
//
//  Main family hub view - shows family overview or create family CTA.
//

import SwiftUI

struct FamilyView: View {

    // MARK: - Properties

    @State private var viewModel = FamilyViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.family == nil {
                    loadingView
                } else if viewModel.isEmpty {
                    emptyStateView
                } else if let family = viewModel.family {
                    familyContentView(family)
                } else if viewModel.hasReceivedInvites {
                    receivedInvitesView
                }
            }
            .navigationTitle("Family")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.hasFamily {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            if viewModel.canInviteMembers {
                                Button {
                                    viewModel.showInviteMember = true
                                } label: {
                                    Label("Invite Member", systemImage: "person.badge.plus")
                                }
                            }

                            Button {
                                viewModel.showFamilyGoals = true
                            } label: {
                                Label("Family Goals", systemImage: "target")
                            }

                            if viewModel.isAdmin {
                                Divider()
                                Button {
                                    viewModel.showSettings = true
                                } label: {
                                    Label("Settings", systemImage: "gear")
                                }
                            }

                            if !viewModel.isOwner {
                                Divider()
                                Button(role: .destructive) {
                                    viewModel.showLeaveConfirmation = true
                                } label: {
                                    Label("Leave Family", systemImage: "rectangle.portrait.and.arrow.right")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshFamily()
            }
            .task {
                await viewModel.loadFamily()
            }
            .sheet(isPresented: $viewModel.showCreateFamily) {
                CreateFamilyView(
                    onSave: { name, description in
                        Task {
                            try await viewModel.createFamily(name: name, description: description)
                        }
                    },
                    onCancel: {
                        viewModel.showCreateFamily = false
                    }
                )
            }
            .sheet(isPresented: $viewModel.showInviteMember) {
                InviteMemberView(
                    onInvite: { email, role, message in
                        Task {
                            try await viewModel.inviteMember(email: email, role: role, message: message)
                        }
                    },
                    onCancel: {
                        viewModel.showInviteMember = false
                    }
                )
            }
            .sheet(isPresented: $viewModel.showMemberDetail) {
                if let member = viewModel.selectedMember {
                    MemberDetailView(
                        member: member,
                        isAdmin: viewModel.isAdmin,
                        isOwner: viewModel.isOwner,
                        onUpdateRole: { newRole in
                            Task {
                                try await viewModel.updateMemberRole(member, to: newRole)
                            }
                        },
                        onRemove: {
                            viewModel.confirmRemoveMember(member)
                        }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showFamilyGoals) {
                if let goals = viewModel.familyGoals {
                    FamilyGoalsView(goalsOverview: goals)
                }
            }
            .alert("Leave Family?", isPresented: $viewModel.showLeaveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Leave", role: .destructive) {
                    Task {
                        try? await viewModel.leaveFamily()
                    }
                }
            } message: {
                Text("You will no longer have access to shared family information.")
            }
            .alert("Remove Member?", isPresented: $viewModel.showRemoveMemberConfirmation) {
                Button("Cancel", role: .cancel) {
                    viewModel.memberToRemove = nil
                }
                Button("Remove", role: .destructive) {
                    if let member = viewModel.memberToRemove {
                        Task {
                            try? await viewModel.removeMember(member)
                        }
                    }
                }
            } message: {
                if let member = viewModel.memberToRemove {
                    Text("Remove \(member.name) from the family?")
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading family...")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 32) {
            // Illustration
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.trustBlue)
            }

            VStack(spacing: 12) {
                Text("Family Sharing")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create a family group to share goals, track progress together, and keep everyone aligned on your financial journey.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    viewModel.showCreateFamily = true
                } label: {
                    Text("Create Family")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if viewModel.hasReceivedInvites {
                    Button {
                        // Show received invites
                    } label: {
                        Text("View \(viewModel.receivedInvites.count) Pending Invite\(viewModel.receivedInvites.count == 1 ? "" : "s")")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 32)

            // Received invites
            if viewModel.hasReceivedInvites {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pending Invites")
                        .font(.headline)

                    ForEach(viewModel.receivedInvites) { received in
                        receivedInviteCard(received)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Received Invites View

    private var receivedInvitesView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.trustBlue)

                    Text("You Have Invites!")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 32)

                ForEach(viewModel.receivedInvites) { received in
                    receivedInviteCard(received)
                }
            }
            .padding()
        }
    }

    private func receivedInviteCard(_ received: ReceivedInvite) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Family avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Text(String(received.invite.familyName.prefix(1)).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.trustBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(received.invite.familyName)
                        .font(.headline)

                    Text("Invited by \(received.invite.inviterName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if let message = received.invite.message, !message.isEmpty {
                Text("\"\(message)\"")
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(received.summaryText, systemImage: "person.2")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(received.invite.timeRemainingString)
                    .font(.caption)
                    .foregroundStyle(Color.prosperityGold)
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        try? await viewModel.declineInvite(received)
                    }
                } label: {
                    Text("Decline")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    Task {
                        try? await viewModel.acceptInvite(received)
                    }
                } label: {
                    Text("Accept")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Family Content

    private func familyContentView(_ family: Family) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Family Header Card
                familyHeaderCard(family)

                // Quick Stats
                quickStatsSection

                // Members Section
                membersSection(family)

                // Pending Invites
                if !viewModel.pendingInvites.isEmpty && viewModel.isAdmin {
                    pendingInvitesSection
                }
            }
            .padding()
        }
    }

    // MARK: - Family Header Card

    private func familyHeaderCard(_ family: Family) -> some View {
        VStack(spacing: 16) {
            // Family Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.trustBlue)
            }

            VStack(spacing: 4) {
                Text(family.name)
                    .font(.title2)
                    .fontWeight(.bold)

                if let description = family.familyDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            // Member avatars
            HStack(spacing: -8) {
                ForEach(Array(family.activeMembers.prefix(5).enumerated()), id: \.element.id) { index, member in
                    memberAvatar(member, size: 36)
                        .zIndex(Double(5 - index))
                }

                if family.activeMembers.count > 5 {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text("+\(family.activeMembers.count - 5)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Members",
                value: "\(viewModel.activeMembers.count)",
                icon: "person.2.fill",
                color: Color.trustBlue
            )

            if let goals = viewModel.familyGoals {
                statCard(
                    title: "Goals",
                    value: "\(goals.totalGoals)",
                    icon: "target",
                    color: Color.growthGreen
                )

                statCard(
                    title: "Progress",
                    value: "\(Int(goals.overallProgress * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color.prosperityGold
                )
            }
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    // MARK: - Members Section

    private func membersSection(_ family: Family) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Members")
                    .font(.headline)

                Spacer()

                if viewModel.canInviteMembers {
                    Button {
                        viewModel.showInviteMember = true
                    } label: {
                        Label("Invite", systemImage: "plus")
                            .font(.subheadline)
                    }
                }
            }

            ForEach(family.members) { member in
                memberRow(member)
                    .onTapGesture {
                        viewModel.selectMember(member)
                    }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func memberRow(_ member: FamilyMember) -> some View {
        HStack(spacing: 12) {
            memberAvatar(member, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(member.name)
                        .font(.body)
                        .fontWeight(.medium)

                    if member.role == .admin {
                        Image(systemName: "shield.fill")
                            .font(.caption)
                            .foregroundStyle(Color.trustBlue)
                    }
                }

                Text(member.role.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Status indicator
            Circle()
                .fill(Color(hex: member.statusColorHex))
                .frame(width: 8, height: 8)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func memberAvatar(_ member: FamilyMember, size: CGFloat) -> some View {
        ZStack {
            if let pictureUrl = member.pictureUrl, let url = URL(string: pictureUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsAvatar(member.initials, size: size)
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                initialsAvatar(member.initials, size: size)
            }
        }
        .overlay {
            Circle()
                .stroke(Color(.systemBackground), lineWidth: 2)
        }
    }

    private func initialsAvatar(_ initials: String, size: CGFloat) -> some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.4))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.trustBlue)
            }
    }

    // MARK: - Pending Invites Section

    private var pendingInvitesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Invites")
                .font(.headline)

            ForEach(viewModel.pendingInvites) { invite in
                pendingInviteRow(invite)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func pendingInviteRow(_ invite: FamilyInvite) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.fill")
                .font(.title3)
                .foregroundStyle(Color.prosperityGold)

            VStack(alignment: .leading, spacing: 2) {
                Text(invite.inviteeEmail)
                    .font(.body)

                Text(invite.timeRemainingString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button {
                    Task {
                        try? await viewModel.resendInvite(invite)
                    }
                } label: {
                    Label("Resend", systemImage: "arrow.clockwise")
                }

                Button(role: .destructive) {
                    Task {
                        try? await viewModel.cancelInvite(invite)
                    }
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    FamilyView()
}
