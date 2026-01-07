//
//  AddToDCASheet.swift
//  Growfolio
//
//  Sheet for adding a stock to a DCA schedule.
//

import SwiftUI

struct AddToDCASheet: View {

    // MARK: - Properties

    let symbol: String
    let stockName: String?
    let onDismiss: () -> Void

    @State private var viewModel: AddToDCASheetViewModel

    @FocusState private var focusedField: Field?

    private enum Field {
        case amount
        case allocation
    }

    // MARK: - Initialization

    init(
        symbol: String,
        stockName: String? = nil,
        dcaRepository: DCARepositoryProtocol = RepositoryContainer.dcaRepository,
        onDismiss: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.stockName = stockName
        self.onDismiss = onDismiss
        _viewModel = State(initialValue: AddToDCASheetViewModel(
            symbol: symbol,
            stockName: stockName,
            dcaRepository: dcaRepository
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Stock Info Section
                stockInfoSection

                // Schedule Mode Selection
                scheduleModeSection

                // Schedule Configuration
                if viewModel.scheduleMode == .existing {
                    existingScheduleSection
                } else {
                    newScheduleSection
                }

                // Allocation Section
                allocationSection

                // Estimate Section
                if viewModel.canShowEstimate {
                    estimateSection
                }
            }
            .navigationTitle("Add to DCA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.submit()
                            if viewModel.didSucceed {
                                onDismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .task {
                await viewModel.loadSchedules()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .overlay {
                if viewModel.isSubmitting {
                    submittingOverlay
                }
            }
            .overlay {
                if viewModel.didSucceed {
                    successOverlay
                }
            }
        }
    }

    // MARK: - Stock Info Section

    private var stockInfoSection: some View {
        Section {
            HStack(spacing: 12) {
                // Stock Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Text(String(symbol.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.trustBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(symbol)
                        .font(.headline)

                    if let name = stockName {
                        Text(name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title2)
                    .foregroundStyle(Color.trustBlue)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Schedule Mode Section

    private var scheduleModeSection: some View {
        Section {
            Picker("Schedule Type", selection: $viewModel.scheduleMode) {
                Text("Create New Schedule").tag(ScheduleMode.new)
                Text("Copy From Existing").tag(ScheduleMode.existing)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
    }

    // MARK: - Existing Schedule Section

    private var existingScheduleSection: some View {
        Section("Copy Settings From") {
            if viewModel.isLoadingSchedules {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading schedules...")
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.existingSchedules.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No existing schedules")
                        .foregroundStyle(.secondary)

                    Text("You don't have any DCA schedules yet. Create a new one instead.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            } else {
                ForEach(viewModel.existingSchedules) { schedule in
                    Button {
                        viewModel.selectSchedule(schedule)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(schedule.stockSymbol)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                HStack(spacing: 8) {
                                    Text(schedule.amount.currencyString)
                                        .font(.subheadline)

                                    Text(schedule.frequency.shortName)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5))
                                        .clipShape(Capsule())
                                }
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if viewModel.selectedScheduleId == schedule.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.trustBlue)
                                    .font(.title3)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - New Schedule Section

    private var newScheduleSection: some View {
        Group {
            Section("Investment Amount") {
                HStack {
                    Text("$")
                        .foregroundStyle(.secondary)

                    TextField("Amount per execution", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                }
            }

            Section("Frequency") {
                Picker("Frequency", selection: $viewModel.frequency) {
                    ForEach(DCAFrequency.allCases, id: \.self) { freq in
                        Text(freq.displayName).tag(freq)
                    }
                }
                .pickerStyle(.menu)

                // Day selection based on frequency
                if viewModel.frequency == .weekly {
                    Picker("Day of Week", selection: $viewModel.preferredDayOfWeek) {
                        ForEach(viewModel.daysOfWeek, id: \.0) { day in
                            Text(day.1).tag(day.0)
                        }
                    }
                } else if viewModel.frequency == .monthly {
                    Picker("Day of Month", selection: $viewModel.preferredDayOfMonth) {
                        ForEach(1...28, id: \.self) { day in
                            Text(ordinalDay(day)).tag(day)
                        }
                    }
                }

                DatePicker(
                    "Start Date",
                    selection: $viewModel.startDate,
                    in: Date()...,
                    displayedComponents: .date
                )

                Toggle("Set End Date", isOn: $viewModel.hasEndDate.animation())

                if viewModel.hasEndDate {
                    DatePicker(
                        "End Date",
                        selection: $viewModel.endDate,
                        in: viewModel.startDate.adding(days: 1)...,
                        displayedComponents: .date
                    )
                }
            }
        }
    }

    // MARK: - Allocation Section

    private var allocationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Allocation")
                        .font(.subheadline)

                    Spacer()

                    Text("\(Int(viewModel.allocationPercentage))%")
                        .font(.headline)
                        .foregroundColor(viewModel.isAllocationValid ? .primary : Color.negative)
                }

                Slider(
                    value: $viewModel.allocationPercentage,
                    in: 1...100,
                    step: 1
                )
                .tint(Color.trustBlue)

                if !viewModel.isAllocationValid {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.negative)

                        Text(viewModel.allocationValidationMessage)
                            .font(.caption)
                            .foregroundStyle(Color.negative)
                    }
                }

                Text("This is the percentage of the schedule's total amount that will be invested in \(symbol).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Allocation")
        } footer: {
            if viewModel.scheduleMode == .existing, let schedule = viewModel.selectedSchedule {
                Text("Current schedule total: \(schedule.amount.currencyString). This stock will receive \((schedule.amount * Decimal(viewModel.allocationPercentage) / 100).currencyString) per execution.")
            }
        }
    }

    // MARK: - Estimate Section

    private var estimateSection: some View {
        Section("Estimated Investment") {
            HStack {
                Text("Per Execution")
                Spacer()
                Text(viewModel.estimatedPerExecution.currencyString)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Monthly")
                Spacer()
                Text(viewModel.estimatedMonthly.currencyString)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Yearly")
                Spacer()
                Text(viewModel.estimatedYearly.currencyString)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Executions/Year")
                Spacer()
                Text("\(viewModel.executionsPerYear)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Overlays

    private var submittingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Creating schedule...")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.positive)

                Text("Schedule Created!")
                    .font(.headline)

                Text("\(symbol) has been added to your DCA schedule")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onDismiss()
            }
        }
    }

    // MARK: - Helpers

    private func ordinalDay(_ day: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: day)) ?? "\(day)"
    }
}

// MARK: - Schedule Mode

enum ScheduleMode: String, CaseIterable {
    case new
    case existing
}

// MARK: - View Model

@Observable
final class AddToDCASheetViewModel: @unchecked Sendable {

    // MARK: - Properties

    // Input Data
    let symbol: String
    let stockName: String?

    // Mode
    var scheduleMode: ScheduleMode = .new

    // Existing Schedule Selection
    var existingSchedules: [DCASchedule] = []
    var selectedScheduleId: String?
    var isLoadingSchedules = false

    // New Schedule Configuration
    var amount: String = ""
    var frequency: DCAFrequency = .monthly
    var preferredDayOfWeek: Int = 2 // Monday
    var preferredDayOfMonth: Int = 1
    var startDate: Date = Date()
    var hasEndDate: Bool = false
    var endDate: Date = Date().adding(years: 1) ?? Date()

    // Allocation
    var allocationPercentage: Double = 100

    // State
    var isSubmitting = false
    var didSucceed = false
    var showError = false
    var errorMessage: String?

    // Repository
    private let dcaRepository: DCARepositoryProtocol

    // MARK: - Computed Properties

    var selectedSchedule: DCASchedule? {
        existingSchedules.first { $0.id == selectedScheduleId }
    }

    var canSubmit: Bool {
        guard isAllocationValid else { return false }

        if scheduleMode == .existing {
            return selectedScheduleId != nil
        } else {
            return (Decimal(string: amount) ?? 0) > 0
        }
    }

    var canShowEstimate: Bool {
        if scheduleMode == .existing {
            return selectedScheduleId != nil
        } else {
            return (Decimal(string: amount) ?? 0) > 0
        }
    }

    var isAllocationValid: Bool {
        allocationPercentage >= 1 && allocationPercentage <= 100
    }

    var allocationValidationMessage: String {
        if allocationPercentage < 1 {
            return "Allocation must be at least 1%"
        } else if allocationPercentage > 100 {
            return "Allocation cannot exceed 100%"
        }
        return ""
    }

    var effectiveAmount: Decimal {
        if scheduleMode == .existing, let schedule = selectedSchedule {
            return schedule.amount
        } else {
            return Decimal(string: amount) ?? 0
        }
    }

    var effectiveFrequency: DCAFrequency {
        if scheduleMode == .existing, let schedule = selectedSchedule {
            return schedule.frequency
        } else {
            return frequency
        }
    }

    var estimatedPerExecution: Decimal {
        effectiveAmount * Decimal(allocationPercentage) / 100
    }

    var estimatedMonthly: Decimal {
        estimatedPerExecution * Decimal(effectiveFrequency.executionsPerYear) / 12
    }

    var estimatedYearly: Decimal {
        estimatedPerExecution * Decimal(effectiveFrequency.executionsPerYear)
    }

    var executionsPerYear: Int {
        effectiveFrequency.executionsPerYear
    }

    var daysOfWeek: [(Int, String)] {
        [
            (1, "Sunday"),
            (2, "Monday"),
            (3, "Tuesday"),
            (4, "Wednesday"),
            (5, "Thursday"),
            (6, "Friday"),
            (7, "Saturday")
        ]
    }

    // MARK: - Initialization

    init(
        symbol: String,
        stockName: String?,
        dcaRepository: DCARepositoryProtocol
    ) {
        self.symbol = symbol
        self.stockName = stockName
        self.dcaRepository = dcaRepository
    }

    // MARK: - Methods

    @MainActor
    func loadSchedules() async {
        isLoadingSchedules = true

        do {
            existingSchedules = try await dcaRepository.fetchActiveSchedules()
        } catch {
            // Silently fail - user can still create new schedule
            existingSchedules = []
        }

        isLoadingSchedules = false
    }

    func selectSchedule(_ schedule: DCASchedule) {
        if selectedScheduleId == schedule.id {
            selectedScheduleId = nil
        } else {
            selectedScheduleId = schedule.id
        }
    }

    @MainActor
    func submit() async {
        guard canSubmit else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            let scheduleAmount: Decimal
            let scheduleFrequency: DCAFrequency
            let scheduleStartDate: Date
            let scheduleEndDate: Date?
            var schedulePreferredDayOfWeek: Int? = nil
            var schedulePreferredDayOfMonth: Int? = nil

            if scheduleMode == .existing, let existingSchedule = selectedSchedule {
                // Copy settings from existing schedule
                scheduleAmount = estimatedPerExecution
                scheduleFrequency = existingSchedule.frequency
                scheduleStartDate = Date()
                scheduleEndDate = existingSchedule.endDate
                schedulePreferredDayOfWeek = existingSchedule.preferredDayOfWeek
                schedulePreferredDayOfMonth = existingSchedule.preferredDayOfMonth
            } else {
                // Use new schedule settings
                scheduleAmount = estimatedPerExecution
                scheduleFrequency = frequency
                scheduleStartDate = startDate
                scheduleEndDate = hasEndDate ? endDate : nil

                if frequency == .weekly {
                    schedulePreferredDayOfWeek = preferredDayOfWeek
                } else if frequency == .monthly {
                    schedulePreferredDayOfMonth = preferredDayOfMonth
                }
            }

            // Create the new schedule
            _ = try await dcaRepository.createSchedule(
                stockSymbol: symbol,
                amount: scheduleAmount,
                frequency: scheduleFrequency,
                startDate: scheduleStartDate,
                endDate: scheduleEndDate,
                portfolioId: "default" // Use default portfolio
            )

            didSucceed = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSubmitting = false
    }
}

// MARK: - Preview

#Preview {
    AddToDCASheet(
        symbol: "AAPL",
        stockName: "Apple Inc.",
        onDismiss: {}
    )
}
