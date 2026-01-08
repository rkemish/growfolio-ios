//
//  CorporateAction.swift
//  Growfolio
//
//  Domain model for corporate actions (dividends, splits, mergers, etc.).
//

import Foundation

// MARK: - Corporate Action Type

enum CorporateActionType: String, Codable, Sendable, CaseIterable {
    case dividend
    case split
    case merger
    case spinoff

    var displayName: String {
        switch self {
        case .dividend: return "Dividend"
        case .split: return "Stock Split"
        case .merger: return "Merger"
        case .spinoff: return "Spinoff"
        }
    }

    var iconName: String {
        switch self {
        case .dividend: return "dollarsign.circle.fill"
        case .split: return "arrow.triangle.branch"
        case .merger: return "arrow.triangle.merge"
        case .spinoff: return "arrow.triangle.turn.up.right.circle"
        }
    }

    var colorHex: String {
        switch self {
        case .dividend: return "#10B981"  // Green
        case .split: return "#3B82F6"  // Blue
        case .merger: return "#8B5CF6"  // Purple
        case .spinoff: return "#F59E0B"  // Amber
        }
    }
}

// MARK: - Corporate Action Status

enum CorporateActionStatus: String, Codable, Sendable, CaseIterable {
    case announced
    case pending
    case executed
    case cancelled

    var displayName: String {
        switch self {
        case .announced: return "Announced"
        case .pending: return "Pending"
        case .executed: return "Executed"
        case .cancelled: return "Cancelled"
        }
    }

    var iconName: String {
        switch self {
        case .announced: return "megaphone"
        case .pending: return "clock"
        case .executed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .announced: return "#3B82F6"  // Blue
        case .pending: return "#F59E0B"  // Amber
        case .executed: return "#10B981"  // Green
        case .cancelled: return "#6B7280"  // Gray
        }
    }
}

// MARK: - Corporate Action Main Model

struct CorporateAction: Identifiable, Codable, Sendable, Equatable, Hashable {
    // MARK: - Properties
    let id: String
    let symbol: String
    let type: CorporateActionType
    let announcedDate: Date
    let exDate: Date?
    let recordDate: Date?
    let payableDate: Date?
    let amount: Decimal?
    let oldRate: Decimal?
    let newRate: Decimal?
    let description: String
    let status: CorporateActionStatus

    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        symbol: String,
        type: CorporateActionType,
        announcedDate: Date,
        exDate: Date? = nil,
        recordDate: Date? = nil,
        payableDate: Date? = nil,
        amount: Decimal? = nil,
        oldRate: Decimal? = nil,
        newRate: Decimal? = nil,
        description: String,
        status: CorporateActionStatus
    ) {
        self.id = id
        self.symbol = symbol
        self.type = type
        self.announcedDate = announcedDate
        self.exDate = exDate
        self.recordDate = recordDate
        self.payableDate = payableDate
        self.amount = amount
        self.oldRate = oldRate
        self.newRate = newRate
        self.description = description
        self.status = status
    }

    // MARK: - Computed Properties

    var displayName: String {
        "\(symbol) - \(type.displayName)"
    }

    var isDividend: Bool {
        type == .dividend
    }

    var isSplit: Bool {
        type == .split
    }

    var splitRatio: String? {
        guard isSplit, let oldRate = oldRate, let newRate = newRate else { return nil }
        return "\(newRate):\(oldRate)"
    }

    var isExecuted: Bool {
        status == .executed
    }

    var isPending: Bool {
        status == .pending
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case type
        case announcedDate = "announced_date"
        case exDate = "ex_date"
        case recordDate = "record_date"
        case payableDate = "payable_date"
        case amount
        case oldRate = "old_rate"
        case newRate = "new_rate"
        case description
        case status
    }
}
