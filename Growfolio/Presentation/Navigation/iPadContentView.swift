//
//  iPadContentView.swift
//  Growfolio
//
//  Content column router for iPad split view.
//  Routes to the appropriate list view based on selected section.
//

import SwiftUI

/// Content column view that displays the appropriate list/content based on selected section
struct iPadContentView: View {
    @Environment(NavigationState.self) private var navState

    var body: some View {
        Group {
            switch navState.selectedSection {
            case .dashboard:
                DashboardView()

            case .portfolio:
                PortfolioView()

            case .watchlist:
                WatchlistView()

            case .baskets:
                BasketsListView()

            case .dca:
                DCASchedulesView()

            case .goals:
                GoalsView()

            case .settings:
                SettingsView()
            }
        }
    }
}

#Preview("iPad Content") {
    NavigationSplitView {
        Text("Sidebar")
    } content: {
        iPadContentView()
            .environment(NavigationState())
    } detail: {
        Text("Detail")
    }
}
