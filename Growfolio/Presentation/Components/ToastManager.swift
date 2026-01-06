//
//  ToastManager.swift
//  Growfolio
//
//  Manages toast notifications throughout the app.
//

import Foundation
import SwiftUI

/// Manages the display and lifecycle of toast messages
@Observable
@MainActor
final class ToastManager: @unchecked Sendable {

    // MARK: - Singleton

    /// Shared instance for app-wide toast management
    static let shared = ToastManager()

    // MARK: - Properties

    /// Currently displayed toasts
    private(set) var toasts: [Toast] = []

    /// Maximum number of toasts to display simultaneously
    var maxToasts: Int = 3

    /// Queue of pending toasts waiting to be displayed
    private var queue: [Toast] = []

    /// Timers for auto-dismissing toasts
    private var dismissTimers: [UUID: Task<Void, Never>] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Show a toast message
    /// - Parameter toast: The toast to display
    func show(_ toast: Toast) {
        if toasts.count >= maxToasts {
            // Queue the toast for later
            queue.append(toast)
            return
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            toasts.append(toast)
        }

        scheduleAutoDismiss(for: toast)
    }

    /// Show an error toast
    /// - Parameters:
    ///   - message: Error message to display
    ///   - actionTitle: Optional action button title
    ///   - action: Optional action to perform when button is tapped
    ///   - duration: How long to show the toast (default: 5 seconds for errors)
    func showError(
        _ message: String,
        actionTitle: String? = nil,
        action: (@Sendable () -> Void)? = nil,
        duration: TimeInterval = 5.0
    ) {
        let toast = Toast(
            type: .error,
            message: message,
            actionTitle: actionTitle,
            action: action,
            duration: duration
        )
        show(toast)
    }

    /// Show an error toast from an Error object
    /// - Parameters:
    ///   - error: The error to display
    ///   - retryAction: Optional retry action for retryable errors
    func showError(_ error: Error, retryAction: (@Sendable () -> Void)? = nil) {
        let message = userFriendlyMessage(for: error)

        if let networkError = error as? NetworkError, networkError.isRetryable, let retry = retryAction {
            showError(message, actionTitle: "Retry", action: retry)
        } else {
            showError(message)
        }
    }

    /// Show a success toast
    /// - Parameters:
    ///   - message: Success message to display
    ///   - duration: How long to show the toast (default: 3 seconds)
    func showSuccess(_ message: String, duration: TimeInterval = 3.0) {
        let toast = Toast(
            type: .success,
            message: message,
            duration: duration
        )
        show(toast)
    }

    /// Show a warning toast
    /// - Parameters:
    ///   - message: Warning message to display
    ///   - actionTitle: Optional action button title
    ///   - action: Optional action to perform when button is tapped
    ///   - duration: How long to show the toast (default: 4 seconds)
    func showWarning(
        _ message: String,
        actionTitle: String? = nil,
        action: (@Sendable () -> Void)? = nil,
        duration: TimeInterval = 4.0
    ) {
        let toast = Toast(
            type: .warning,
            message: message,
            actionTitle: actionTitle,
            action: action,
            duration: duration
        )
        show(toast)
    }

    /// Show an info toast
    /// - Parameters:
    ///   - message: Info message to display
    ///   - duration: How long to show the toast (default: 4 seconds)
    func showInfo(_ message: String, duration: TimeInterval = 4.0) {
        let toast = Toast(
            type: .info,
            message: message,
            duration: duration
        )
        show(toast)
    }

    /// Dismiss a specific toast
    /// - Parameter toast: The toast to dismiss
    func dismiss(_ toast: Toast) {
        dismissTimers[toast.id]?.cancel()
        dismissTimers.removeValue(forKey: toast.id)

        withAnimation(.easeOut(duration: 0.2)) {
            toasts.removeAll { $0.id == toast.id }
        }

        // Show next queued toast after a brief delay
        if !queue.isEmpty {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                if let next = queue.first {
                    queue.removeFirst()
                    show(next)
                }
            }
        }
    }

    /// Dismiss all toasts
    func dismissAll() {
        for timer in dismissTimers.values {
            timer.cancel()
        }
        dismissTimers.removeAll()
        queue.removeAll()

        withAnimation(.easeOut(duration: 0.2)) {
            toasts.removeAll()
        }
    }

    // MARK: - Private Methods

    private func scheduleAutoDismiss(for toast: Toast) {
        let task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            dismiss(toast)
        }
        dismissTimers[toast.id] = task
    }

    /// Convert an error to a user-friendly message
    private func userFriendlyMessage(for error: Error) -> String {
        // Handle NetworkError specifically
        if let networkError = error as? NetworkError {
            return networkError.errorDescription ?? "An unexpected error occurred."
        }

        // Handle LocalizedError
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        // Default message
        return "An unexpected error occurred. Please try again."
    }
}

// MARK: - View Extension

extension View {
    /// Adds toast display capability to a view
    /// - Parameters:
    ///   - position: Where toasts should appear (default: top)
    ///   - toastManager: The toast manager to use (default: shared)
    /// - Returns: Modified view with toast overlay
    func toastOverlay(
        position: ToastPosition = .top,
        toastManager: ToastManager = .shared
    ) -> some View {
        self.overlay {
            ToastContainerView(position: position)
                .environment(toastManager)
        }
    }
}
