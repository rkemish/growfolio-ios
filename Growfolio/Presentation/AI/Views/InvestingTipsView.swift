//
//  InvestingTipsView.swift
//  Growfolio
//
//  Tips carousel or list for investing education.
//

import SwiftUI

struct InvestingTipsView: View {

    // MARK: - Properties

    let tips: [InvestingTip]
    @State private var currentIndex = 0

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)

                Text("Investing Tips")
                    .font(.headline)

                Spacer()

                // Page indicator
                if tips.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<tips.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.accentColor : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }

            // Tips Carousel
            if !tips.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                        tipCard(tip)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 140)
            } else {
                emptyState
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Tip Card

    private func tipCard(_ tip: InvestingTip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let category = tip.category {
                    Image(systemName: category.iconName)
                        .font(.caption)
                        .foregroundStyle(Color(hex: category.colorHex) ?? .accentColor)
                }

                Text(tip.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(tip.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("No tips available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}

// MARK: - Tips List View

/// Full list view of investing tips
struct InvestingTipsListView: View {

    let tips: [InvestingTip]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(tips) { tip in
                    tipRow(tip)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Investing Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func tipRow(_ tip: InvestingTip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let category = tip.category {
                    Image(systemName: category.iconName)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: category.colorHex) ?? .accentColor)
                        .frame(width: 24)
                }

                Text(tip.title)
                    .font(.headline)
            }

            Text(tip.content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tip of the Day Card

/// Compact tip card for dashboard
struct TipOfTheDayCard: View {

    let tip: InvestingTip
    @State private var showAllTips = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)

                Text("Tip of the Day")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(tip.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color.prosperityGold.opacity(0.1), .orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Allocation Suggestion View

struct AllocationSuggestionView: View {

    // MARK: - Properties

    @Binding var investmentAmount: Decimal
    @Binding var riskTolerance: RiskTolerance
    @Binding var timeHorizon: TimeHorizon

    let suggestion: AllocationSuggestion?
    let isLoading: Bool
    let onGetSuggestion: () -> Void
    let onDismiss: () -> Void

    @State private var amountText: String = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Input Section
                    inputSection

                    // Get Suggestion Button
                    Button {
                        onGetSuggestion()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                                Text("Get AI Suggestion")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLoading)

                    // Suggestion Result
                    if let suggestion = suggestion {
                        suggestionResult(suggestion)
                    }
                }
                .padding()
            }
            .navigationTitle("Allocation Suggestion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .onAppear {
                amountText = NSDecimalNumber(decimal: investmentAmount).stringValue
            }
        }
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 20) {
            // Amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Investment Amount")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    Text("\u{00A3}")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    TextField("1,000", text: $amountText)
                        .font(.title2)
                        .keyboardType(.decimalPad)
                        .onChange(of: amountText) { _, newValue in
                            if let value = Decimal(string: newValue) {
                                investmentAmount = value
                            }
                        }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Risk Tolerance
            VStack(alignment: .leading, spacing: 12) {
                Text("Risk Tolerance")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    ForEach(RiskTolerance.allCases, id: \.self) { risk in
                        riskButton(risk)
                    }
                }
            }

            // Time Horizon
            VStack(alignment: .leading, spacing: 12) {
                Text("Time Horizon")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    ForEach(TimeHorizon.allCases, id: \.self) { horizon in
                        horizonButton(horizon)
                    }
                }
            }
        }
    }

    private func riskButton(_ risk: RiskTolerance) -> some View {
        Button {
            riskTolerance = risk
        } label: {
            VStack(spacing: 8) {
                Image(systemName: risk.iconName)
                    .font(.title2)

                Text(risk.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                riskTolerance == risk
                    ? Color(hex: risk.colorHex).opacity(0.2)
                    : Color(.secondarySystemBackground)
            )
            .foregroundColor(
                riskTolerance == risk
                    ? Color(hex: risk.colorHex)
                    : .secondary
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        riskTolerance == risk
                            ? Color(hex: risk.colorHex)
                            : .clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func horizonButton(_ horizon: TimeHorizon) -> some View {
        Button {
            timeHorizon = horizon
        } label: {
            VStack(spacing: 8) {
                Image(systemName: horizon.iconName)
                    .font(.title2)

                Text(horizon.displayName)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                timeHorizon == horizon
                    ? Color.accentColor.opacity(0.2)
                    : Color(.secondarySystemBackground)
            )
            .foregroundColor(
                timeHorizon == horizon ? .accentColor : .secondary
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        timeHorizon == horizon ? Color.accentColor : .clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Suggestion Result

    private func suggestionResult(_ suggestion: AllocationSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.trustBlue)

                Text("AI Suggestion")
                    .font(.headline)
            }

            Divider()

            // Content
            Text(suggestion.suggestion)
                .font(.body)

            // Disclaimer
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(Color.prosperityGold)

                Text(suggestion.disclaimer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview("Tips Carousel") {
    InvestingTipsView(tips: [
        InvestingTip(title: "Start with consistent investing", content: "Dollar cost averaging helps reduce the impact of market volatility by investing regularly.", category: .dca),
        InvestingTip(title: "Diversification matters", content: "Spreading investments across different sectors and asset types can help manage risk.", category: .diversification),
        InvestingTip(title: "Think long-term", content: "Historically, staying invested through market ups and downs has been more effective than timing.", category: .longTerm)
    ])
    .padding()
}

#Preview("Tip of the Day") {
    TipOfTheDayCard(
        tip: InvestingTip(
            title: "Automate your investing",
            content: "Setting up automatic investments removes emotion from the equation and builds discipline.",
            category: .automation
        )
    )
    .padding()
}
