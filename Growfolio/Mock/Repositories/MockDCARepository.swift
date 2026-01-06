//
//  MockDCARepository.swift
//  Growfolio
//
//  Mock implementation of DCARepositoryProtocol for demo mode.
//

import Foundation

/// Mock implementation of DCARepositoryProtocol
final class MockDCARepository: DCARepositoryProtocol, @unchecked Sendable {

    // MARK: - Properties

    private let store = MockDataStore.shared
    private let config = MockConfiguration.shared

    // MARK: - Schedule Operations

    func fetchSchedules() async throws -> [DCASchedule] {
        try await simulateNetwork()
        await ensureInitialized()
        return await store.dcaSchedules
    }

    func fetchActiveSchedules() async throws -> [DCASchedule] {
        try await simulateNetwork()
        await ensureInitialized()
        return await store.dcaSchedules.filter { $0.isActive && !$0.isPaused }
    }

    func fetchSchedule(id: String) async throws -> DCASchedule {
        try await simulateNetwork()

        guard let schedule = await store.dcaSchedules.first(where: { $0.id == id }) else {
            throw DCARepositoryError.scheduleNotFound(id: id)
        }
        return schedule
    }

    func fetchSchedules(for symbol: String) async throws -> [DCASchedule] {
        try await simulateNetwork()
        return await store.dcaSchedules.filter { $0.stockSymbol == symbol.uppercased() }
    }

    func fetchSchedules(linkedToPortfolio portfolioId: String) async throws -> [DCASchedule] {
        try await simulateNetwork()
        return await store.dcaSchedules.filter { $0.portfolioId == portfolioId }
    }

    func createSchedule(_ schedule: DCASchedule) async throws -> DCASchedule {
        try await simulateNetwork()
        await ensureInitialized()

        let userId = await store.currentUser?.id ?? "mock"
        let profile = MockStockDataProvider.stockProfiles[schedule.stockSymbol]

        let newSchedule = DCASchedule(
            id: MockDataGenerator.mockId(prefix: "dca"),
            userId: userId,
            stockSymbol: schedule.stockSymbol.uppercased(),
            stockName: schedule.stockName ?? profile?.name,
            amount: schedule.amount,
            frequency: schedule.frequency,
            preferredDayOfWeek: schedule.preferredDayOfWeek,
            preferredDayOfMonth: schedule.preferredDayOfMonth,
            startDate: schedule.startDate,
            endDate: schedule.endDate,
            nextExecutionDate: MockDataGenerator.nextExecutionDate(frequency: schedule.frequency),
            portfolioId: schedule.portfolioId,
            createdAt: Date(),
            updatedAt: Date()
        )

        await store.addSchedule(newSchedule)
        return newSchedule
    }

    func createSchedule(
        stockSymbol: String,
        amount: Decimal,
        frequency: DCAFrequency,
        startDate: Date,
        endDate: Date?,
        portfolioId: String
    ) async throws -> DCASchedule {
        let schedule = DCASchedule(
            userId: await store.currentUser?.id ?? "mock",
            stockSymbol: stockSymbol.uppercased(),
            amount: amount,
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            portfolioId: portfolioId
        )
        return try await createSchedule(schedule)
    }

    func updateSchedule(_ schedule: DCASchedule) async throws -> DCASchedule {
        try await simulateNetwork()

        var updatedSchedule = schedule
        updatedSchedule.updatedAt = Date()
        await store.updateSchedule(updatedSchedule)
        return updatedSchedule
    }

    func updateScheduleAmount(id: String, amount: Decimal) async throws -> DCASchedule {
        try await simulateNetwork()

        guard var schedule = await store.dcaSchedules.first(where: { $0.id == id }) else {
            throw DCARepositoryError.scheduleNotFound(id: id)
        }

        schedule.amount = amount
        schedule.updatedAt = Date()
        await store.updateSchedule(schedule)
        return schedule
    }

    func updateScheduleFrequency(id: String, frequency: DCAFrequency) async throws -> DCASchedule {
        try await simulateNetwork()

        guard var schedule = await store.dcaSchedules.first(where: { $0.id == id }) else {
            throw DCARepositoryError.scheduleNotFound(id: id)
        }

        schedule.frequency = frequency
        schedule.nextExecutionDate = MockDataGenerator.nextExecutionDate(frequency: frequency)
        schedule.updatedAt = Date()
        await store.updateSchedule(schedule)
        return schedule
    }

    func pauseSchedule(id: String) async throws -> DCASchedule {
        try await simulateNetwork()

        guard var schedule = await store.dcaSchedules.first(where: { $0.id == id }) else {
            throw DCARepositoryError.scheduleNotFound(id: id)
        }

        if schedule.isPaused {
            throw DCARepositoryError.scheduleAlreadyPaused
        }

        schedule.isPaused = true
        schedule.updatedAt = Date()
        await store.updateSchedule(schedule)
        return schedule
    }

    func resumeSchedule(id: String) async throws -> DCASchedule {
        try await simulateNetwork()

        guard var schedule = await store.dcaSchedules.first(where: { $0.id == id }) else {
            throw DCARepositoryError.scheduleNotFound(id: id)
        }

        if !schedule.isPaused {
            throw DCARepositoryError.scheduleNotPaused
        }

        schedule.isPaused = false
        schedule.nextExecutionDate = MockDataGenerator.nextExecutionDate(frequency: schedule.frequency)
        schedule.updatedAt = Date()
        await store.updateSchedule(schedule)
        return schedule
    }

    func cancelSchedule(id: String) async throws -> DCASchedule {
        try await simulateNetwork()

        guard var schedule = await store.dcaSchedules.first(where: { $0.id == id }) else {
            throw DCARepositoryError.scheduleNotFound(id: id)
        }

        schedule.isActive = false
        schedule.updatedAt = Date()
        await store.updateSchedule(schedule)
        return schedule
    }

    func deleteSchedule(id: String) async throws {
        try await simulateNetwork()
        await store.deleteSchedule(id: id)
    }

    // MARK: - Execution Operations

    func fetchExecutions(for scheduleId: String, page: Int, limit: Int) async throws -> PaginatedResponse<DCAExecution> {
        try await simulateNetwork()

        let allExecutions = await store.getExecutions(for: scheduleId)
            .sorted { $0.executedAt > $1.executedAt }

        let startIndex = (page - 1) * limit
        let endIndex = min(startIndex + limit, allExecutions.count)

        guard startIndex < allExecutions.count else {
            let totalPages = allExecutions.isEmpty ? 1 : (allExecutions.count + limit - 1) / limit
            return PaginatedResponse(
                data: [],
                pagination: PaginatedResponse.Pagination(page: page, limit: limit, totalPages: totalPages, totalItems: allExecutions.count)
            )
        }

        let pageItems = Array(allExecutions[startIndex..<endIndex])
        let totalPages = (allExecutions.count + limit - 1) / limit
        return PaginatedResponse(
            data: pageItems,
            pagination: PaginatedResponse.Pagination(page: page, limit: limit, totalPages: totalPages, totalItems: allExecutions.count)
        )
    }

    func fetchAllExecutions(for scheduleId: String) async throws -> [DCAExecution] {
        try await simulateNetwork()
        return await store.getExecutions(for: scheduleId).sorted { $0.executedAt > $1.executedAt }
    }

    func fetchExecution(id executionId: String) async throws -> DCAExecution {
        try await simulateNetwork()

        for scheduleId in await store.dcaSchedules.map({ $0.id }) {
            let executions = await store.getExecutions(for: scheduleId)
            if let execution = executions.first(where: { $0.id == executionId }) {
                return execution
            }
        }

        throw DCARepositoryError.executionNotFound(id: executionId)
    }

    func fetchRecentExecutions(limit: Int = 10) async throws -> [DCAExecution] {
        try await simulateNetwork()
        await ensureInitialized()

        var allExecutions: [DCAExecution] = []
        for scheduleId in await store.dcaSchedules.map({ $0.id }) {
            allExecutions.append(contentsOf: await store.getExecutions(for: scheduleId))
        }

        return Array(allExecutions.sorted { $0.executedAt > $1.executedAt }.prefix(limit))
    }

    func executeNow(scheduleId: String) async throws -> DCAExecution {
        try await simulateNetwork()

        guard let schedule = await store.dcaSchedules.first(where: { $0.id == scheduleId }) else {
            throw DCARepositoryError.scheduleNotFound(id: scheduleId)
        }

        let price = MockStockDataProvider.currentPrice(for: schedule.stockSymbol)
        let shares = (schedule.amount / price).rounded(places: 4)

        let execution = DCAExecution(
            id: MockDataGenerator.mockId(prefix: "exec"),
            scheduleId: scheduleId,
            stockSymbol: schedule.stockSymbol,
            amount: schedule.amount,
            sharesAcquired: shares,
            pricePerShare: price,
            executedAt: Date()
        )

        await store.addExecution(execution, to: scheduleId)
        return execution
    }

    func retryExecution(id executionId: String) async throws -> DCAExecution {
        try await simulateNetwork()

        let execution = try await fetchExecution(id: executionId)

        guard execution.status == .failed else {
            throw DCARepositoryError.executionCannotBeRetried
        }

        // Create a new successful execution
        let price = MockStockDataProvider.currentPrice(for: execution.stockSymbol)
        let shares = (execution.amount / price).rounded(places: 4)

        let newExecution = DCAExecution(
            id: MockDataGenerator.mockId(prefix: "exec"),
            scheduleId: execution.scheduleId,
            stockSymbol: execution.stockSymbol,
            amount: execution.amount,
            sharesAcquired: shares,
            pricePerShare: price,
            executedAt: Date()
        )

        await store.addExecution(newExecution, to: execution.scheduleId)
        return newExecution
    }

    // MARK: - Simulation Operations

    func simulateDCA(
        symbol: String,
        amount: Decimal,
        frequency: DCAFrequency,
        startDate: Date,
        endDate: Date
    ) async throws -> DCASimulation {
        try await simulateNetwork()

        let profile = MockStockDataProvider.stockProfiles[symbol.uppercased()]
        let basePrice = profile?.basePrice ?? 100
        let volatility = profile?.volatility ?? 0.02

        var dataPoints: [DCASimulationDataPoint] = []
        var currentDate = startDate
        var totalInvested: Decimal = 0
        var totalShares: Decimal = 0
        var executionCount = 0

        let calendar = Calendar.current

        while currentDate <= endDate {
            // Simulate price at this date
            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: currentDate).day ?? 0
            let priceMultiplier = 1.0 + Double.random(in: -volatility...volatility) * Double(daysSinceStart % 30)
            let price = Decimal(NSDecimalNumber(decimal: basePrice).doubleValue * priceMultiplier)

            totalInvested += amount
            let sharesBought = (amount / price).rounded(places: 4)
            totalShares += sharesBought
            executionCount += 1

            let currentValue = totalShares * price

            dataPoints.append(DCASimulationDataPoint(
                date: currentDate,
                cumulativeInvested: totalInvested,
                cumulativeValue: currentValue,
                sharesOwned: totalShares,
                priceAtDate: price
            ))

            currentDate = MockDataGenerator.nextExecutionDate(frequency: frequency, from: currentDate)
        }

        let finalPrice = MockStockDataProvider.currentPrice(for: symbol.uppercased())
        let finalValue = totalShares * finalPrice
        let avgCost = totalShares > 0 ? totalInvested / totalShares : 0
        let totalReturn = finalValue - totalInvested
        let totalReturnPercent = totalInvested > 0 ? (totalReturn / totalInvested) * 100 : 0

        return DCASimulation(
            symbol: symbol.uppercased(),
            amount: amount,
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            totalInvested: totalInvested,
            finalValue: finalValue,
            totalShares: totalShares,
            averageCost: avgCost,
            totalReturn: totalReturn,
            totalReturnPercent: totalReturnPercent,
            executionCount: executionCount,
            dataPoints: dataPoints
        )
    }

    func projectReturns(
        for scheduleId: String,
        projectionMonths: Int,
        expectedAnnualReturn: Decimal
    ) async throws -> DCAProjection {
        try await simulateNetwork()

        guard let schedule = await store.dcaSchedules.first(where: { $0.id == scheduleId }) else {
            throw DCARepositoryError.scheduleNotFound(id: scheduleId)
        }

        var dataPoints: [DCAProjectionDataPoint] = []
        let monthlyReturn = expectedAnnualReturn / 12 / 100

        var currentDate = Date()
        var projectedInvestment: Decimal = schedule.totalInvested
        var projectedValue: Decimal = schedule.totalInvested

        let executionsPerMonth = Decimal(schedule.frequency.executionsPerYear) / 12
        let monthlyInvestment = schedule.amount * executionsPerMonth

        let calendar = Calendar.current

        for _ in 0..<projectionMonths {
            projectedInvestment += monthlyInvestment
            projectedValue = projectedValue * (1 + monthlyReturn) + monthlyInvestment

            // Add uncertainty bands
            let uncertainty = projectedValue * Decimal(0.1) // 10% uncertainty
            let low = projectedValue - uncertainty
            let high = projectedValue + uncertainty

            dataPoints.append(DCAProjectionDataPoint(
                date: currentDate,
                projectedInvestment: projectedInvestment,
                projectedValue: projectedValue,
                projectedValueLow: low,
                projectedValueHigh: high
            ))

            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }

        let projectedReturn = projectedValue - projectedInvestment
        let projectedReturnPercent = projectedInvestment > 0 ? (projectedReturn / projectedInvestment) * 100 : 0

        return DCAProjection(
            scheduleId: scheduleId,
            projectionMonths: projectionMonths,
            expectedAnnualReturn: expectedAnnualReturn,
            projectedInvestment: projectedInvestment,
            projectedValue: projectedValue,
            projectedReturn: projectedReturn,
            projectedReturnPercent: projectedReturnPercent,
            dataPoints: dataPoints
        )
    }

    // MARK: - Summary Operations

    func fetchDCASummary() async throws -> DCASummary {
        try await simulateNetwork()
        await ensureInitialized()
        return DCASummary(schedules: await store.dcaSchedules)
    }

    func fetchUpcomingExecutions(days: Int = 30) async throws -> [UpcomingExecution] {
        try await simulateNetwork()
        await ensureInitialized()

        let cutoffDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        var upcoming: [UpcomingExecution] = []

        for schedule in await store.dcaSchedules where schedule.isActive && !schedule.isPaused {
            if let nextDate = schedule.nextExecutionDate, nextDate <= cutoffDate {
                let portfolio = await store.portfolios.first { $0.id == schedule.portfolioId }

                upcoming.append(UpcomingExecution(
                    scheduleId: schedule.id,
                    stockSymbol: schedule.stockSymbol,
                    stockName: schedule.stockName,
                    amount: schedule.amount,
                    executionDate: nextDate,
                    portfolioId: schedule.portfolioId,
                    portfolioName: portfolio?.name
                ))
            }
        }

        return upcoming.sorted { $0.executionDate < $1.executionDate }
    }

    // MARK: - Cache Operations

    func invalidateCache() async {
        // No-op for mock
    }

    func prefetchSchedules() async throws {
        await ensureInitialized()
    }

    // MARK: - Private Methods

    private func simulateNetwork() async throws {
        try await config.simulateNetworkDelay()
        try config.maybeThrowSimulatedError()
    }

    private func ensureInitialized() async {
        if await store.dcaSchedules.isEmpty {
            await store.initialize(for: config.demoPersona)
        }
    }
}


