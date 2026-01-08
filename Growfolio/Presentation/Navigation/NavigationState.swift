//
//  NavigationState.swift
//  Growfolio
//
//  Centralized navigation state for iPad split view navigation.
//  Manages the selected section and detail items across the app.
//

import Foundation
import SwiftUI

/// App sections for iPad sidebar navigation
enum AppSection: String, CaseIterable, Hashable {
    case dashboard
    case portfolio
    case watchlist
    case baskets
    case dca
    case goals
    case settings

    var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .portfolio: return "Portfolio"
        case .watchlist: return "Watchlist"
        case .baskets: return "Baskets"
        case .dca: return "DCA"
        case .goals: return "Goals"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .portfolio: return "briefcase.fill"
        case .watchlist: return "star.fill"
        case .baskets: return "basket.fill"
        case .dca: return "arrow.triangle.2.circlepath"
        case .goals: return "target"
        case .settings: return "gearshape.fill"
        }
    }
}

/// Observable class managing navigation state for iPad split view
@Observable
final class NavigationState {
    /// Currently selected section in the sidebar
    var selectedSection: AppSection = .dashboard

    // MARK: - Detail Selections

    /// Selected holding in portfolio section
    var selectedHolding: Holding?

    /// Selected goal in goals section
    var selectedGoal: Goal?

    /// Selected DCA schedule in DCA section
    var selectedSchedule: DCASchedule?

    /// Selected basket in baskets section
    var selectedBasket: Basket?

    /// Selected stock symbol in watchlist section
    var selectedStock: String?

    // MARK: - Sheet Presentation State

    /// Controls create goal sheet visibility
    var showCreateGoal = false

    /// Controls create DCA schedule sheet visibility
    var showCreateDCASchedule = false

    /// Controls create basket sheet visibility
    var showCreateBasket = false

    /// Controls add transaction sheet visibility
    var showAddTransaction = false

    // MARK: - Selection Management

    /// Clears the detail selection for the current section
    func clearDetailSelection() {
        switch selectedSection {
        case .portfolio:
            selectedHolding = nil
        case .goals:
            selectedGoal = nil
        case .dca:
            selectedSchedule = nil
        case .baskets:
            selectedBasket = nil
        case .watchlist:
            selectedStock = nil
        case .dashboard, .settings:
            break
        }
    }

    /// Selects a section and optionally clears its detail selection
    func selectSection(_ section: AppSection, clearDetail: Bool = true) {
        selectedSection = section
        if clearDetail {
            clearDetailSelection()
        }
    }
}
