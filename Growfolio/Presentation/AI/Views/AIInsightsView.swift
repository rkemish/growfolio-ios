//
//  AIInsightsView.swift
//  Growfolio
//
//  Main view for AI-generated portfolio insights.
//

import SwiftUI

struct AIInsightsView: View {

    // MARK: - Properties

    @State private var viewModel = AIInsightsViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Health Score
                    if let score = viewModel.healthScore {
                        HealthScoreCardView(
                            score: score,
                            description: viewModel.healthScoreDescription,
                            color: viewModel.healthScoreColor
                        )
                    }

                    // Summary
                    if let summary = viewModel.summary {
                        summarySection(summary)
                    }

                    // High Priority Insights
                    if !viewModel.highPriorityInsights.isEmpty {
                        insightsSection(
                            title: "Action Required",
                            insights: viewModel.highPriorityInsights,
                            showPriority: true
                        )
                    }

                    // All Insights
                    if viewModel.hasInsights {
                        insightsSection(
                            title: "Insights",
                            insights: viewModel.activeInsights.filter { $0.priority < .high },
                            showPriority: false
                        )
                    }

                    // Tips
                    if viewModel.hasTips {
                        InvestingTipsView(tips: viewModel.tips)
                    }

                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadAll()
            }
            .overlay {
                if viewModel.isLoading && !viewModel.hasInsights {
                    loadingView
                }
            }
            .sheet(isPresented: $viewModel.showStockExplanation) {
                if let explanation = viewModel.stockExplanation {
                    StockExplanationCardView(explanation: explanation) {
                        viewModel.dismissStockExplanation()
                    }
                    .presentationDetents([.medium, .large])
                } else if viewModel.isLoadingExplanation {
                    loadingExplanationView
                        .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $viewModel.showAllocationSuggestion) {
                AllocationSuggestionView(
                    investmentAmount: $viewModel.investmentAmount,
                    riskTolerance: $viewModel.selectedRiskTolerance,
                    timeHorizon: $viewModel.selectedTimeHorizon,
                    suggestion: viewModel.allocationSuggestion,
                    isLoading: viewModel.isLoadingAllocation,
                    onGetSuggestion: {
                        Task {
                            await viewModel.loadAllocationSuggestion()
                        }
                    },
                    onDismiss: {
                        viewModel.dismissAllocationSuggestion()
                    }
                )
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
    }

    // MARK: - Summary Section

    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundStyle(.secondary)

                Text("Summary")
                    .font(.headline)
            }

            Text(summary)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Insights Section

    private func insightsSection(title: String, insights: [AIInsight], showPriority: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(insights) { insight in
                    InsightCardView(
                        insight: insight,
                        onAction: {
                            viewModel.handleInsightAction(insight)
                        },
                        onDismiss: {
                            viewModel.dismissInsight(insight)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Tools")
                .font(.headline)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                actionButton(
                    icon: "sparkles",
                    title: "Chat",
                    color: Color.trustBlue
                ) {
                    // Open chat - handled by presenting sheet
                }

                actionButton(
                    icon: "chart.pie",
                    title: "Allocation",
                    color: Color.trustBlue
                ) {
                    viewModel.showAllocationSuggestion = true
                }
            }
        }
    }

    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Analyzing your portfolio...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }

    private var loadingExplanationView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Getting AI explanation...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Dashboard Widget

/// Compact insights widget for the dashboard
struct AIInsightsWidgetView: View {

    @State private var viewModel = AIInsightsViewModel()
    @State private var showFullInsights = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.trustBlue)

                    Text("AI Insights")
                        .font(.headline)
                }

                Spacer()

                Button {
                    showFullInsights = true
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }

            // Content
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if viewModel.hasInsights {
                // Show top 2 insights
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.activeInsights.prefix(2))) { insight in
                        MiniInsightCardView(insight: insight) {
                            showFullInsights = true
                        }
                    }
                }
            } else {
                // Empty state
                emptyState
            }

            // Tip of the day
            if let tip = viewModel.tips.first {
                TipOfTheDayCard(tip: tip)
            }
        }
        .task {
            await viewModel.loadAll()
        }
        .sheet(isPresented: $showFullInsights) {
            AIInsightsView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No insights yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Check back after adding some investments")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Preview

#Preview("AI Insights View") {
    AIInsightsView()
}

#Preview("Widget") {
    AIInsightsWidgetView()
        .padding()
}
