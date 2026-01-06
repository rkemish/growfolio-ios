//
//  KYCFlowView.swift
//  Growfolio
//
//  Container view for the KYC onboarding flow with step navigation.
//

import SwiftUI

struct KYCFlowView: View {
    @State private var viewModel = KYCViewModel()
    @Environment(AppState.self) private var appState
    @Environment(AuthService.self) private var authService

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressHeader

                currentStepView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                navigationButtons
            }
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.isFirstStep {
                        Button {
                            viewModel.previousStep()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
            }
            .onAppear {
                loadUserEmail()
            }
            .alert("Submission Error", isPresented: showErrorAlert) {
                Button("OK", role: .cancel) {
                    viewModel.submissionState = .idle
                }
            } message: {
                if case .error(let message) = viewModel.submissionState {
                    Text(message)
                }
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            ProgressView(value: viewModel.progress)
                .tint(.accentColor)
                .padding(.horizontal)

            Text(viewModel.currentStep.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Current Step View

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .personalInfo:
            PersonalInfoView(viewModel: viewModel)
        case .address:
            AddressView(viewModel: viewModel)
        case .taxInfo:
            TaxInfoView(viewModel: viewModel)
        case .employment:
            EmploymentInfoView(viewModel: viewModel)
        case .disclosures:
            DisclosuresView(viewModel: viewModel)
        case .review:
            KYCReviewView(viewModel: viewModel)
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        VStack(spacing: 12) {
            Button {
                if viewModel.isLastStep {
                    Task {
                        await viewModel.submit()
                        if case .success = viewModel.submissionState {
                            appState.hasCompletedKYC = true
                            appState.currentFlow = .main
                        }
                    }
                } else {
                    viewModel.nextStep()
                }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(viewModel.isLastStep ? "Submit Application" : "Continue")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canProceed ? Color.accentColor : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadius))
            }
            .disabled(!viewModel.canProceed || viewModel.isSubmitting)

            stepIndicator
        }
        .padding(.horizontal, Constants.UI.standardPadding)
        .padding(.bottom, 24)
        .background(Color(.systemBackground))
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(KYCViewModel.Step.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(step == viewModel.currentStep ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: viewModel.currentStep)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private var showErrorAlert: Binding<Bool> {
        Binding(
            get: {
                if case .error = viewModel.submissionState {
                    return true
                }
                return false
            },
            set: { _ in }
        )
    }

    private func loadUserEmail() {
        if let user = authService.currentUser {
            viewModel.userEmail = user.email ?? ""
        }
    }
}

#Preview {
    KYCFlowView()
        .environment(AppState())
        .environment(AuthService.shared)
}
