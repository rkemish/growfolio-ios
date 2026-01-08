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
        .task(id: scenePhase) {
            // Observe WebSocket connection state for server shutdown events
            await observeConnectionState()
        }
    }

    /// Observes WebSocket connection state changes to detect server maintenance
    @MainActor
    private func observeConnectionState() async {
        let connectionStateStream = AsyncStream<WebSocketService.ConnectionState> { continuation in
            let task = Task { @MainActor in
                while !Task.isCancelled {
                    _ = withObservationTracking {
                        _ = WebSocketService.shared.connectionState
                        _ = WebSocketService.shared.lastError
                    } onChange: {
                        Task { @MainActor in
                            continuation.yield(WebSocketService.shared.connectionState)
                        }
                    }
                    try? await Task.sleep(for: .seconds(1))
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }

        for await state in connectionStateStream {
            handleConnectionStateChange(state)
        }
    }

    /// Handles WebSocket connection state changes to show user-friendly notifications
    @MainActor
    private func handleConnectionStateChange(_ state: WebSocketService.ConnectionState) {
        // Check if disconnection was due to server shutdown
        if case .disconnected = state,
           let error = WebSocketService.shared.lastError as? WebSocketServiceError,
           case .connectionClosed(let code) = error,
           code == 4006 {  // 4006 = server_shutdown

            ToastManager.shared.showInfo(
                "Server maintenance in progress. Reconnecting...",
                duration: 5.0
            )
        }
    }
}

#Preview("iPad Split View") {
    iPadSplitView()
        .environment(NavigationState())
        .previewDevice("iPad Pro (12.9-inch)")
}
