//
//  iPadSplitView.swift
//  Growfolio
//
//  Main split view container for iPad interface.
//  Coordinates sidebar, content, and detail columns.
//

import SwiftUI

/// Root iPad split view with sidebar, content, and detail columns
struct iPadSplitView: View {
    @Environment(NavigationState.self) private var navState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationSplitView {
            // Sidebar column - section selection
            iPadSidebarView()
        } content: {
            // Content column - list/main content for selected section
            iPadContentView()
        } detail: {
            // Detail column - detail view for selected item
            iPadDetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .task {
            // Establish WebSocket connection when split view appears
            await WebSocketService.shared.connect()
        }
        .onDisappear {
            // Clean up WebSocket connection when view disappears
            Task {
                await WebSocketService.shared.disconnect()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Manage WebSocket connections based on app lifecycle
            switch phase {
            case .active:
                Task {
                    await WebSocketService.shared.connect()
                }
            case .background:
                Task {
                    await WebSocketService.shared.disconnect()
                }
            default:
                break
            }
        }
    }
}

#Preview("iPad Split View") {
    iPadSplitView()
        .environment(NavigationState())
        .previewDevice("iPad Pro (12.9-inch)")
}
