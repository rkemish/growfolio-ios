//
//  Document.swift
//  Growfolio
//
//  Domain model for account documents (statements, tax forms, etc.).
//

import Foundation

// MARK: - Document Type

enum DocumentType: String, Codable, Sendable, CaseIterable {
    case statement
    case taxForm = "tax_form"
    case confirmation
    case prospectus
    case w8ben

    var displayName: String {
        switch self {
        case .statement: return "Statement"
        case .taxForm: return "Tax Form"
        case .confirmation: return "Trade Confirmation"
        case .prospectus: return "Prospectus"
        case .w8ben: return "W-8BEN Form"
        }
    }

    var iconName: String {
        switch self {
        case .statement: return "doc.text"
        case .taxForm: return "doc.badge.gearshape"
        case .confirmation: return "checkmark.circle.fill"
        case .prospectus: return "book"
        case .w8ben: return "doc.text.fill"
        }
    }
}

// MARK: - Document Main Model

struct Document: Identifiable, Codable, Sendable, Equatable, Hashable {
    // MARK: - Properties
    let id: String
    let userId: String
    let type: DocumentType
    let title: String
    let description: String?
    let fileUrl: URL
    let fileSize: Int64
    let mimeType: String
    let createdAt: Date

    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        userId: String,
        type: DocumentType,
        title: String,
        description: String? = nil,
        fileUrl: URL,
        fileSize: Int64,
        mimeType: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.description = description
        self.fileUrl = fileUrl
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    var displayName: String {
        title
    }

    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var isPDF: Bool {
        mimeType == "application/pdf"
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case description
        case fileUrl = "file_url"
        case fileSize = "file_size"
        case mimeType = "mime_type"
        case createdAt = "created_at"
    }
}
