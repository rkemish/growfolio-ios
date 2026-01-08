//
//  ErrorAlertModifier.swift
//  Growfolio
//
//  View modifiers for displaying error alerts and handling errors consistently.
//

import SwiftUI

// MARK: - Error Alert Modifier

/// A view modifier that displays an alert when an error is present
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    let title: String
    let retryAction: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(
                title,
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { presentedError in
                // Dismiss button
                Button("OK", role: .cancel) {
                    error = nil
                }

                // Retry button for retryable errors
                if isRetryable(presentedError), let retry = retryAction {
                    Button("Retry") {
                        error = nil
                        retry()
                    }
                }
            } message: { presentedError in
                Text(userFriendlyMessage(for: presentedError))
            }
    }

    private func isRetryable(_ error: Error) -> Bool {
        if let networkError = error as? NetworkError {
            return networkError.isRetryable
        }
        return false
    }

    private func userFriendlyMessage(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.errorDescription ?? "An unexpected error occurred."
        }

        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        return "An unexpected error occurred. Please try again."
    }
}

// MARK: - Error Toast Modifier

/// A view modifier that shows a toast when an error occurs
struct ErrorToastModifier: ViewModifier {
    @Binding var error: Error?
    let retryAction: (@Sendable () -> Void)?
    @Environment(ToastManager.self) private var toastManager: ToastManager?

    func body(content: Content) -> some View {
        content
            .onChange(of: error != nil) { _, hasError in
                if hasError, let error = error {
                    showErrorToast(error)
                    self.error = nil  // Clear error after showing toast
                }
            }
    }

    @MainActor
    private func showErrorToast(_ error: Error) {
        let manager = toastManager ?? ToastManager.shared

        if let retry = retryAction {
            manager.showError(error, retryAction: retry)
        } else {
            manager.showError(error)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Shows an alert when the error binding has a value
    /// - Parameters:
    ///   - error: Binding to an optional Error
    ///   - title: Alert title (default: "Error")
    ///   - retryAction: Optional retry action for retryable errors
    /// - Returns: Modified view with error alert
    func errorAlert(
        error: Binding<Error?>,
        title: String = "Error",
        retryAction: (() -> Void)? = nil
    ) -> some View {
        modifier(ErrorAlertModifier(
            error: error,
            title: title,
            retryAction: retryAction
        ))
    }

    /// Shows a toast when the error binding has a value
    /// - Parameters:
    ///   - error: Binding to an optional Error
    ///   - retryAction: Optional retry action for retryable errors
    /// - Returns: Modified view with error toast handling
    func errorToast(
        error: Binding<Error?>,
        retryAction: (@Sendable () -> Void)? = nil
    ) -> some View {
        modifier(ErrorToastModifier(
            error: error,
            retryAction: retryAction
        ))
    }
}

// MARK: - Network Error User Messages

extension NetworkError {
    /// Returns a concise user-friendly message for toast display
    var toastMessage: String {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error. Please try again later."
        case .rateLimited:
            return "Too many requests. Please wait."
        case .cancelled:
            return "Request cancelled"
        default:
            return errorDescription ?? "An error occurred"
        }
    }
}

// MARK: - Previews

#Preview("Error Alert") {
    struct PreviewWrapper: View {
        @State private var error: Error? = NetworkError.noConnection

        var body: some View {
            VStack {
                Text("Content")
                Button("Show Error") {
                    error = NetworkError.serverError(statusCode: 500, message: nil)
                }
            }
            .errorAlert(error: $error) {
                print("Retrying...")
            }
        }
    }

    return PreviewWrapper()
}
