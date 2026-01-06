//
//  ToastView.swift
//  Growfolio
//
//  A toast/banner component for displaying messages to users.
//

import SwiftUI

// MARK: - Toast Type

/// Defines the visual style and semantics of a toast message
enum ToastType: Equatable, Sendable {
    case error
    case success
    case warning
    case info

    var backgroundColor: Color {
        switch self {
        case .error:
            return Color.error
        case .success:
            return Color.success
        case .warning:
            return Color.warning
        case .info:
            return Color(hex: "#007AFF") // iOS blue
        }
    }

    var iconName: String {
        switch self {
        case .error:
            return "xmark.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .error:
            return "Error"
        case .success:
            return "Success"
        case .warning:
            return "Warning"
        case .info:
            return "Information"
        }
    }
}

// MARK: - Toast Position

/// Where the toast appears on screen
enum ToastPosition: Sendable {
    case top
    case bottom
}

// MARK: - Toast Model

/// Represents a single toast message
struct Toast: Identifiable, Equatable, Sendable {
    let id: UUID
    let type: ToastType
    let message: String
    let actionTitle: String?
    let action: (@Sendable () -> Void)?
    let duration: TimeInterval

    init(
        id: UUID = UUID(),
        type: ToastType,
        message: String,
        actionTitle: String? = nil,
        action: (@Sendable () -> Void)? = nil,
        duration: TimeInterval = 4.0
    ) {
        self.id = id
        self.type = type
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.duration = duration
    }

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast View

/// A single toast banner view
struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void

    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: toast.type.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            // Message
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(3)

            Spacer(minLength: 4)

            // Action button (if provided)
            if let actionTitle = toast.actionTitle {
                Button {
                    toast.action?()
                    onDismiss()
                } label: {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Dismiss button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(toast.type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                offset = 0
                opacity = 1
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(toast.type.accessibilityLabel): \(toast.message)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to dismiss")
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            offset = -100
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Toast Container View

/// Container view that displays toasts from the ToastManager
struct ToastContainerView: View {
    @Environment(ToastManager.self) private var toastManager
    let position: ToastPosition

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear

                VStack(spacing: 8) {
                    if position == .bottom {
                        Spacer()
                    }

                    ForEach(toastManager.toasts) { toast in
                        ToastView(toast: toast) {
                            toastManager.dismiss(toast)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: position == .top ? .top : .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }

                    if position == .top {
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, position == .top ? geometry.safeAreaInsets.top + 8 : geometry.safeAreaInsets.bottom + 8)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(!toastManager.toasts.isEmpty)
    }
}

// MARK: - Preview

#Preview("Toast Types") {
    VStack(spacing: 16) {
        ToastView(
            toast: Toast(type: .error, message: "Failed to load portfolio data. Please try again."),
            onDismiss: {}
        )

        ToastView(
            toast: Toast(type: .success, message: "Investment goal created successfully!"),
            onDismiss: {}
        )

        ToastView(
            toast: Toast(type: .warning, message: "Your session will expire in 5 minutes."),
            onDismiss: {}
        )

        ToastView(
            toast: Toast(type: .info, message: "Market is currently closed. Prices shown are from last close."),
            onDismiss: {}
        )

        ToastView(
            toast: Toast(
                type: .error,
                message: "Connection lost",
                actionTitle: "Retry",
                action: {}
            ),
            onDismiss: {}
        )
    }
    .padding()
    #if os(iOS)
    .background(Color(.systemGroupedBackground))
    #else
    .background(Color.gray.opacity(0.1))
    #endif
}
