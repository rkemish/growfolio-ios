//
//  iPadSidebarView.swift
//  Growfolio
//
//  iPad sidebar navigation view for split view interface.
//  Displays app sections organized by category.
//

import SwiftUI

/// Sidebar navigation view for iPad showing all app sections
struct iPadSidebarView: View {
    @Environment(NavigationState.self) private var navState

    var body: some View {
        List {
            Section("Overview") {
                Button {
                    navState.selectSection(.dashboard)
                } label: {
                    Label(AppSection.dashboard.displayName, systemImage: AppSection.dashboard.iconName)
                }
            }

            Section("Investing") {
                Button {
                    navState.selectSection(.portfolio)
                } label: {
                    Label(AppSection.portfolio.displayName, systemImage: AppSection.portfolio.iconName)
                }

                Button {
                    navState.selectSection(.watchlist)
                } label: {
                    Label(AppSection.watchlist.displayName, systemImage: AppSection.watchlist.iconName)
                }

                Button {
                    navState.selectSection(.baskets)
                } label: {
                    Label(AppSection.baskets.displayName, systemImage: AppSection.baskets.iconName)
                }
            }

            Section("Automation") {
                Button {
                    navState.selectSection(.dca)
                } label: {
                    Label(AppSection.dca.displayName, systemImage: AppSection.dca.iconName)
                }

                Button {
                    navState.selectSection(.goals)
                } label: {
                    Label(AppSection.goals.displayName, systemImage: AppSection.goals.iconName)
                }
            }

            Section("Account") {
                Button {
                    navState.selectSection(.settings)
                } label: {
                    Label(AppSection.settings.displayName, systemImage: AppSection.settings.iconName)
                }
            }
        }
        .navigationTitle("Growfolio")
        .navigationSplitViewColumnWidth(min: 250, ideal: Constants.UI.sidebarWidth, max: 400)
    }
}

#Preview("iPad Sidebar") {
    NavigationSplitView {
        iPadSidebarView()
            .environment(NavigationState())
    } detail: {
        Text("Select a section")
            .font(.title)
            .foregroundStyle(.secondary)
    }
}
