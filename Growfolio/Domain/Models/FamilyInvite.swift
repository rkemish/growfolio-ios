//
//  FamilyInvite.swift
//  Growfolio
//
//  Family invitation domain model for pending invitations.
//

import Foundation

/// Represents a pending family invitation
struct FamilyInvite: Identifiable, Codable, Sendable, Equatable, Hashable {

    // MARK: - Properties

    /// Unique identifier
    let id: String

    /// Family ID to join
    let familyId: String

    /// Family name (for display)
    let familyName: String

    /// User ID who sent the invite
    let inviterId: String

    /// Inviter's display name
    let inviterName: String

    /// Email address of the invitee
    let inviteeEmail: String

    /// User ID of the invitee (if they already have an account)
    var inviteeUserId: String?

    /// Role to assign upon acceptance
    var role: FamilyMemberRole

    /// Current status of the invite
    var status: InviteStatus

    /// Short invite code for easy sharing
    let inviteCode: String

    /// Optional message from inviter
    var message: String?

    /// When the invite was created
    let createdAt: Date

    /// When the invite expires
    let expiresAt: Date

    /// When the invitee responded (if any)
    var respondedAt: Date?

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        familyId: String,
        familyName: String,
        inviterId: String,
        inviterName: String,
        inviteeEmail: String,
        inviteeUserId: String? = nil,
        role: FamilyMemberRole = .member,
        status: InviteStatus = .pending,
        // Generate a short, user-friendly invite code from first 8 chars of UUID
        inviteCode: String = String(UUID().uuidString.prefix(8)).uppercased(),
        message: String? = nil,
        createdAt: Date = Date(),
        // Default expiration: 7 days from now (fallback to current date if date math fails)
        expiresAt: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
        respondedAt: Date? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.familyName = familyName
        self.inviterId = inviterId
        self.inviterName = inviterName
        self.inviteeEmail = inviteeEmail
        self.inviteeUserId = inviteeUserId
        self.role = role
        self.status = status
        self.inviteCode = inviteCode
        self.message = message
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.respondedAt = respondedAt
    }

    // MARK: - Computed Properties

    /// Whether the invite is still pending
    var isPending: Bool {
        status == .pending
    }

    /// Whether the invite has expired
    var isExpired: Bool {
        status == .expired || Date() > expiresAt
    }

    /// Whether the invite can still be accepted
    var canBeAccepted: Bool {
        isPending && !isExpired
    }

    /// Time remaining until expiration
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSinceNow)
    }

    /// Human-readable time remaining
    var timeRemainingString: String {
        let remaining = timeRemaining
        if remaining <= 0 {
            return "Expired"
        }

        // Calculate days and hours from seconds
        // 86400 seconds = 1 day, 3600 seconds = 1 hour
        let days = Int(remaining / 86400)
        let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)

        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") left"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") left"
        } else {
            return "Less than an hour left"
        }
    }

    /// Share link for the invite
    var shareLink: URL? {
        URL(string: "growfolio://family/invite/\(inviteCode)")
    }

    /// Share text for the invite
    var shareText: String {
        var text = "\(inviterName) invited you to join the \(familyName) family on Growfolio!"
        if let message = message, !message.isEmpty {
            text += "\n\n\"\(message)\""
        }
        text += "\n\nUse invite code: \(inviteCode)"
        return text
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case familyId
        case familyName
        case inviterId
        case inviterName
        case inviteeEmail
        case inviteeUserId
        case role
        case status
        case inviteCode
        case message
        case createdAt
        case expiresAt
        case respondedAt
    }
}

// MARK: - Invite Status

/// Status of a family invitation
enum InviteStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case accepted
    case declined
    case expired

    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        case .expired:
            return "Expired"
        }
    }

    var iconName: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .accepted:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .pending:
            return "#FF9500"
        case .accepted:
            return "#34C759"
        case .declined:
            return "#FF3B30"
        case .expired:
            return "#8E8E93"
        }
    }
}

// MARK: - Create Invite Request

/// Request model for creating a new invite
struct CreateInviteRequest: Codable, Sendable {
    let email: String
    let role: FamilyMemberRole
    let message: String?

    init(email: String, role: FamilyMemberRole = .member, message: String? = nil) {
        self.email = email
        self.role = role
        self.message = message
    }
}

// MARK: - Invite Response

/// Response for accepting or declining an invite
struct InviteResponse: Codable, Sendable {
    let inviteId: String
    let accepted: Bool
}

// MARK: - Received Invite

/// A received invite for the current user
struct ReceivedInvite: Identifiable, Codable, Sendable {
    var id: String { invite.id }
    let invite: FamilyInvite
    let familyMemberCount: Int
    let familyOwnerName: String
    let familyDescription: String?

    var summaryText: String {
        "\(familyMemberCount) member\(familyMemberCount == 1 ? "" : "s")"
    }
}
