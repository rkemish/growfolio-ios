//
//  ThemePickerView.swift
//  Growfolio
//
//  View for selecting app appearance theme.
//

import SwiftUI

struct ThemePickerView: View {

    // MARK: - Properties

    let selectedTheme: AppTheme
    let onSelect: (AppTheme) -> Void
    let onCancel: () -> Void

    @State private var currentSelection: AppTheme
    @AppStorage(Constants.StorageKeys.selectedTheme) private var storedTheme: String = AppTheme.system.rawValue

    // MARK: - Initialization

    init(
        selectedTheme: AppTheme,
        onSelect: @escaping (AppTheme) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.selectedTheme = selectedTheme
        self.onSelect = onSelect
        self.onCancel = onCancel
        self._currentSelection = State(initialValue: selectedTheme)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview Section
                    previewSection

                    // Theme Options
                    themeOptionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyTheme()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(previewColorScheme)
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Mock Dashboard Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Portfolio")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("$12,456.78")
                            .font(.title)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.trustBlue.gradient)
                            .frame(width: 44, height: 44)

                        Text("JD")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }
                .padding()

                Divider()

                // Mock Stock Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AAPL")
                            .font(.headline)

                        Text("Apple Inc.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$189.84")
                            .font(.headline)

                        Text("+2.34%")
                            .font(.caption)
                            .foregroundStyle(Color.positive)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    // MARK: - Theme Options Section

    private var themeOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    themeRow(for: theme)

                    if theme != AppTheme.allCases.last {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func themeRow(for theme: AppTheme) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentSelection = theme
            }
        } label: {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: theme.iconName)
                        .font(.title3)
                        .foregroundStyle(theme.iconColor)
                }

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(theme.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Selection indicator
                if theme == currentSelection {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.trustBlue)
                } else {
                    Circle()
                        .strokeBorder(Color(.systemGray3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed Properties

    private var previewColorScheme: ColorScheme? {
        switch currentSelection {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }

    // MARK: - Actions

    private func applyTheme() {
        // Persist to UserDefaults via @AppStorage
        storedTheme = currentSelection.rawValue

        // Notify parent
        onSelect(currentSelection)
    }
}

// MARK: - Preview

#Preview {
    ThemePickerView(
        selectedTheme: .system,
        onSelect: { _ in },
        onCancel: {}
    )
}
