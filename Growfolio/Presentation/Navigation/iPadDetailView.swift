//
//  iPadDetailView.swift
//  Growfolio
//
//  Detail column router for iPad split view.
//  Routes to the appropriate detail view based on selected section and item.
//

import SwiftUI

/// Detail column view that displays the appropriate detail view based on navigation state
struct iPadDetailView: View {
    @Environment(NavigationState.self) private var navState

    var body: some View {
        Group {
            switch navState.selectedSection {
            case .portfolio:
                if let holding = navState.selectedHolding {
                    HoldingDetailView(holding: holding)
                } else {
                    emptyDetailView(
                        title: "Select a Holding",
                        systemImage: "briefcase",
                        description: "Choose a holding from your portfolio to view details"
                    )
                }

            case .goals:
                if let goal = navState.selectedGoal {
                    GoalDetailView(
                        goal: goal,
                        onEdit: {},
                        onArchive: {},
                        onDelete: {},
                        positionsSummary: nil
                    )
                } else {
                    emptyDetailView(
                        title: "Select a Goal",
                        systemImage: "target",
                        description: "Choose a goal to view its details and progress"
                    )
                }

            case .dca:
                if let schedule = navState.selectedSchedule {
                    DCAScheduleDetailView(
                        schedule: schedule,
                        onEdit: {},
                        onPauseResume: {},
                        onDelete: {}
                    )
                } else{
                    emptyDetailView(
                        title: "Select a DCA Schedule",
                        systemImage: "arrow.triangle.2.circlepath",
                        description: "Choose a schedule to view its details and history"
                    )
                }

            case .baskets:
                if let basket = navState.selectedBasket {
                    BasketDetailView(basket: basket)
                } else {
                    emptyDetailView(
                        title: "Select a Basket",
                        systemImage: "basket",
                        description: "Choose a basket to view its allocation and holdings"
                    )
                }

            case .watchlist:
                if let symbol = navState.selectedStock {
                    StockDetailView(symbol: symbol)
                } else {
                    emptyDetailView(
                        title: "Select a Stock",
                        systemImage: "star",
                        description: "Choose a stock from your watchlist to view details"
                    )
                }

            case .dashboard:
                emptyDetailView(
                    title: "Dashboard",
                    systemImage: "chart.pie",
                    description: "Your investment overview and quick actions"
                )

            case .settings:
                emptyDetailView(
                    title: "Settings",
                    systemImage: "gearshape",
                    description: "Select a settings option from the list"
                )
            }
        }
    }

    /// Helper for displaying empty state when no detail is selected
    private func emptyDetailView(title: String, systemImage: String, description: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        }
    }
}

#Preview("iPad Detail - Empty") {
    NavigationSplitView {
        Text("Sidebar")
    } detail: {
        iPadDetailView()
            .environment(NavigationState())
    }
}

#Preview("iPad Detail - Portfolio Selected") {
    let navState = NavigationState()
    navState.selectedSection = .portfolio

    return NavigationSplitView {
        Text("Sidebar")
    } detail: {
        iPadDetailView()
            .environment(navState)
    }
}
