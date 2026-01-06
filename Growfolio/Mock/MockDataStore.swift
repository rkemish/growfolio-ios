//
//  MockDataStore.swift
//  Growfolio
//
//  Actor-based singleton for stateful mock data storage.
//

import Foundation

/// Actor-based singleton that stores all mock data with thread-safe access
actor MockDataStore {

    // MARK: - Singleton

    static let shared = MockDataStore()

    // MARK: - User Data

    private(set) var currentUser: User?
    private(set) var userSettings: UserSettings?

    // MARK: - Portfolio Data

    private(set) var portfolios: [Portfolio] = []
    private(set) var holdings: [String: [Holding]] = [:] // portfolioId -> holdings
    private(set) var ledgerEntries: [String: [LedgerEntry]] = [:] // portfolioId -> entries

    // MARK: - DCA Data

    private(set) var dcaSchedules: [DCASchedule] = []
    private(set) var dcaExecutions: [String: [DCAExecution]] = [:] // scheduleId -> executions

    // MARK: - Goals Data

    private(set) var goals: [Goal] = []
    private(set) var milestones: [String: [GoalMilestone]] = [:] // goalId -> milestones

    // MARK: - Stocks Data

    private(set) var watchlist: [String] = []

    // MARK: - Funding Data

    private(set) var fundingBalance: FundingBalance?
    private(set) var transfers: [Transfer] = []
    private(set) var currentFXRate: FXRate?

    // MARK: - Family Data

    private(set) var family: Family?
    private(set) var familyInvites: [FamilyInvite] = []

    // MARK: - Chat Data

    private(set) var chatHistory: [ChatMessage] = []

    // MARK: - Initialization

    private init() {}

    // MARK: - Initialization Methods

    /// Initialize the store with data for the specified persona
    func initialize(for persona: DemoPersona) async {
        await reset()

        switch persona {
        case .newUser:
            await seedNewUserData()
        case .activeInvestor:
            await seedActiveInvestorData()
        case .familyAccount:
            await seedFamilyAccountData()
        }
    }

    /// Reset all data
    func reset() async {
        currentUser = nil
        userSettings = nil
        portfolios = []
        holdings = [:]
        ledgerEntries = [:]
        dcaSchedules = []
        dcaExecutions = [:]
        goals = []
        milestones = [:]
        watchlist = []
        fundingBalance = nil
        transfers = []
        currentFXRate = nil
        family = nil
        familyInvites = []
        chatHistory = []
    }

    // MARK: - User CRUD

    func setUser(_ user: User) {
        currentUser = user
    }

    func updateUser(_ user: User) {
        currentUser = user
    }

    func setUserSettings(_ settings: UserSettings) {
        userSettings = settings
    }

    // MARK: - Portfolio CRUD

    func addPortfolio(_ portfolio: Portfolio) {
        portfolios.append(portfolio)
        holdings[portfolio.id] = []
        ledgerEntries[portfolio.id] = []
    }

    func updatePortfolio(_ portfolio: Portfolio) {
        if let index = portfolios.firstIndex(where: { $0.id == portfolio.id }) {
            portfolios[index] = portfolio
        }
    }

    func deletePortfolio(id: String) {
        portfolios.removeAll { $0.id == id }
        holdings.removeValue(forKey: id)
        ledgerEntries.removeValue(forKey: id)
    }

    func setDefaultPortfolio(id: String) {
        for i in portfolios.indices {
            portfolios[i].isDefault = portfolios[i].id == id
        }
    }

    // MARK: - Holdings CRUD

    func addHolding(_ holding: Holding, to portfolioId: String) {
        if holdings[portfolioId] == nil {
            holdings[portfolioId] = []
        }
        holdings[portfolioId]?.append(holding)
        recalculatePortfolioValue(id: portfolioId)
    }

    func updateHolding(_ holding: Holding) {
        if var portfolioHoldings = holdings[holding.portfolioId] {
            if let index = portfolioHoldings.firstIndex(where: { $0.id == holding.id }) {
                portfolioHoldings[index] = holding
                holdings[holding.portfolioId] = portfolioHoldings
                recalculatePortfolioValue(id: holding.portfolioId)
            }
        }
    }

    func deleteHolding(id: String, from portfolioId: String) {
        holdings[portfolioId]?.removeAll { $0.id == id }
        recalculatePortfolioValue(id: portfolioId)
    }

    func getHoldings(for portfolioId: String) -> [Holding] {
        holdings[portfolioId] ?? []
    }

    // MARK: - Ledger CRUD

    func addLedgerEntry(_ entry: LedgerEntry, to portfolioId: String) {
        if ledgerEntries[portfolioId] == nil {
            ledgerEntries[portfolioId] = []
        }
        ledgerEntries[portfolioId]?.append(entry)
    }

    func getLedgerEntries(for portfolioId: String) -> [LedgerEntry] {
        ledgerEntries[portfolioId] ?? []
    }

    // MARK: - DCA CRUD

    func addSchedule(_ schedule: DCASchedule) {
        dcaSchedules.append(schedule)
        dcaExecutions[schedule.id] = []
    }

    func updateSchedule(_ schedule: DCASchedule) {
        if let index = dcaSchedules.firstIndex(where: { $0.id == schedule.id }) {
            dcaSchedules[index] = schedule
        }
    }

    func deleteSchedule(id: String) {
        dcaSchedules.removeAll { $0.id == id }
        dcaExecutions.removeValue(forKey: id)
    }

    func addExecution(_ execution: DCAExecution, to scheduleId: String) {
        if dcaExecutions[scheduleId] == nil {
            dcaExecutions[scheduleId] = []
        }
        dcaExecutions[scheduleId]?.append(execution)

        // Update schedule totals
        if let index = dcaSchedules.firstIndex(where: { $0.id == scheduleId }) {
            dcaSchedules[index].totalInvested += execution.amount
            dcaSchedules[index].executionCount += 1
            dcaSchedules[index].lastExecutionDate = execution.executedAt
        }
    }

    func getExecutions(for scheduleId: String) -> [DCAExecution] {
        dcaExecutions[scheduleId] ?? []
    }

    // MARK: - Goals CRUD

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        milestones[goal.id] = []
    }

    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        }
    }

    func deleteGoal(id: String) {
        goals.removeAll { $0.id == id }
        milestones.removeValue(forKey: id)
    }

    func addMilestone(_ milestone: GoalMilestone, to goalId: String) {
        if milestones[goalId] == nil {
            milestones[goalId] = []
        }
        milestones[goalId]?.append(milestone)
    }

    func getMilestones(for goalId: String) -> [GoalMilestone] {
        milestones[goalId] ?? []
    }

    /// Get positions summary for a goal based on linked DCA schedules
    func getGoalPositions(for goalId: String) -> GoalPositionsSummary? {
        guard let goal = goals.first(where: { $0.id == goalId }),
              !goal.linkedDCAScheduleIds.isEmpty else {
            return nil
        }

        var positions: [GoalPosition] = []

        for scheduleId in goal.linkedDCAScheduleIds {
            guard let schedule = dcaSchedules.first(where: { $0.id == scheduleId }),
                  let executions = dcaExecutions[scheduleId],
                  !executions.isEmpty else {
                continue
            }

            let symbol = schedule.stockSymbol
            let profile = MockStockDataProvider.stockProfiles[symbol]
            let currentPrice = MockStockDataProvider.currentPrice(for: symbol)

            // Aggregate executions into purchases
            let purchases: [GoalPurchase] = executions.map { exec in
                GoalPurchase(
                    id: exec.id,
                    date: exec.executedAt,
                    shares: exec.sharesAcquired,
                    pricePerShare: exec.pricePerShare,
                    totalAmount: exec.amount,
                    dcaScheduleId: scheduleId
                )
            }

            let totalShares = executions.reduce(Decimal.zero) { $0 + $1.sharesAcquired }
            let totalCost = executions.reduce(Decimal.zero) { $0 + $1.amount }

            let position = GoalPosition(
                id: scheduleId,
                stockSymbol: symbol,
                stockName: profile?.name ?? symbol,
                totalShares: totalShares,
                totalCostBasis: totalCost,
                currentPrice: currentPrice,
                purchases: purchases
            )
            positions.append(position)
        }

        return GoalPositionsSummary(goalId: goalId, positions: positions)
    }

    // MARK: - Watchlist CRUD

    func addToWatchlist(_ symbol: String) {
        if !watchlist.contains(symbol) {
            watchlist.append(symbol)
        }
    }

    func removeFromWatchlist(_ symbol: String) {
        watchlist.removeAll { $0 == symbol }
    }

    // MARK: - Funding CRUD

    func setFundingBalance(_ balance: FundingBalance) {
        fundingBalance = balance
    }

    func updateFundingBalance(_ balance: FundingBalance) {
        fundingBalance = balance
    }

    func setFXRate(_ rate: FXRate) {
        currentFXRate = rate
    }

    func addTransfer(_ transfer: Transfer) {
        transfers.append(transfer)
    }

    func updateTransfer(_ transfer: Transfer) {
        if let index = transfers.firstIndex(where: { $0.id == transfer.id }) {
            transfers[index] = transfer
        }
    }

    // MARK: - Family CRUD

    func setFamily(_ family: Family?) {
        self.family = family
    }

    func addFamilyInvite(_ invite: FamilyInvite) {
        familyInvites.append(invite)
    }

    func updateFamilyInvite(_ invite: FamilyInvite) {
        if let index = familyInvites.firstIndex(where: { $0.id == invite.id }) {
            familyInvites[index] = invite
        }
    }

    // MARK: - Chat CRUD

    func addChatMessage(_ message: ChatMessage) {
        chatHistory.append(message)
    }

    func clearChatHistory() {
        chatHistory = []
    }

    // MARK: - Helper Methods

    private func recalculatePortfolioValue(id: String) {
        guard let index = portfolios.firstIndex(where: { $0.id == id }),
              let portfolioHoldings = holdings[id] else { return }

        let totalValue = portfolioHoldings.reduce(Decimal.zero) { $0 + $1.marketValue }
        let totalCostBasis = portfolioHoldings.reduce(Decimal.zero) { $0 + $1.costBasis }

        portfolios[index].totalValue = totalValue
        portfolios[index].totalCostBasis = totalCostBasis
        portfolios[index].lastValuationDate = Date()
        portfolios[index].updatedAt = Date()
    }

    // MARK: - Seed Data Methods

    private func seedNewUserData() async {
        let userId = MockDataGenerator.mockId(prefix: "user")

        // Create new user
        currentUser = User(
            id: userId,
            email: "newuser@example.com",
            displayName: "New User",
            preferredCurrency: "GBP",
            createdAt: Date(),
            subscriptionTier: .free
        )

        userSettings = UserSettings()

        // Create empty default portfolio
        let portfolio = Portfolio(
            id: MockDataGenerator.mockId(prefix: "portfolio"),
            userId: userId,
            name: "Main Portfolio",
            type: .personal,
            currencyCode: "USD",
            isDefault: true
        )
        addPortfolio(portfolio)

        // Set up funding balance
        fundingBalance = FundingBalance(
            userId: userId,
            portfolioId: portfolio.id,
            availableUSD: 0,
            availableGBP: 0
        )

        // Set FX rate
        currentFXRate = FXRate(rate: 1.27)

        // Empty watchlist
        watchlist = []
    }

    private func seedActiveInvestorData() async {
        let userId = MockDataGenerator.mockId(prefix: "user")

        // Create user
        currentUser = User(
            id: userId,
            email: "alex.thompson@example.com",
            displayName: "Alex Thompson",
            preferredCurrency: "GBP",
            createdAt: MockDataGenerator.pastDate(daysAgo: 180),
            subscriptionTier: .premium,
            subscriptionExpiresAt: MockDataGenerator.futureDate(daysFromNow: 365)
        )

        userSettings = UserSettings(notificationsEnabled: true, biometricEnabled: true)

        // Create main portfolio
        let mainPortfolioId = MockDataGenerator.mockId(prefix: "portfolio")
        var mainPortfolio = Portfolio(
            id: mainPortfolioId,
            userId: userId,
            name: "Main Portfolio",
            type: .personal,
            currencyCode: "USD",
            cashBalance: 2500,
            isDefault: true,
            createdAt: MockDataGenerator.pastDate(daysAgo: 180)
        )
        portfolios.append(mainPortfolio)
        holdings[mainPortfolioId] = []
        ledgerEntries[mainPortfolioId] = []

        // Add holdings to main portfolio
        let mainHoldings: [(String, Decimal, Decimal)] = [
            ("AAPL", 25.5, 165),
            ("MSFT", 12.3, 350),
            ("GOOGL", 8.2, 135),
            ("VOO", 15.0, 410),
            ("VTI", 20.0, 228),
            ("NVDA", 5.5, 420),
            ("AMZN", 10.0, 155)
        ]

        for (symbol, qty, avgCost) in mainHoldings {
            let profile = MockStockDataProvider.stockProfiles[symbol]
            let holding = Holding(
                id: MockDataGenerator.mockId(prefix: "holding"),
                portfolioId: mainPortfolioId,
                stockSymbol: symbol,
                stockName: profile?.name,
                quantity: qty,
                averageCostPerShare: avgCost,
                currentPricePerShare: MockStockDataProvider.currentPrice(for: symbol),
                firstPurchaseDate: MockDataGenerator.pastDate(daysAgo: Int.random(in: 30...180)),
                sector: profile?.sector,
                industry: profile?.industry,
                assetType: profile?.assetType ?? .stock
            )
            holdings[mainPortfolioId]?.append(holding)
        }

        // Recalculate portfolio value
        let totalValue = holdings[mainPortfolioId]!.reduce(Decimal.zero) { $0 + $1.marketValue }
        let totalCostBasis = holdings[mainPortfolioId]!.reduce(Decimal.zero) { $0 + $1.costBasis }
        mainPortfolio.totalValue = totalValue
        mainPortfolio.totalCostBasis = totalCostBasis
        mainPortfolio.lastValuationDate = Date()
        portfolios[0] = mainPortfolio

        // Create retirement portfolio
        let retirementPortfolioId = MockDataGenerator.mockId(prefix: "portfolio")
        var retirementPortfolio = Portfolio(
            id: retirementPortfolioId,
            userId: userId,
            name: "Retirement",
            type: .retirement,
            currencyCode: "USD",
            cashBalance: 500,
            colorHex: "#FF9500",
            iconName: "sun.horizon.fill",
            createdAt: MockDataGenerator.pastDate(daysAgo: 150)
        )
        portfolios.append(retirementPortfolio)
        holdings[retirementPortfolioId] = []
        ledgerEntries[retirementPortfolioId] = []

        // Add holdings to retirement portfolio
        let retirementHoldings: [(String, Decimal, Decimal)] = [
            ("VTI", 50.0, 225),
            ("VXUS", 100.0, 55),
            ("BND", 150.0, 70)
        ]

        for (symbol, qty, avgCost) in retirementHoldings {
            let profile = MockStockDataProvider.stockProfiles[symbol]
            let holding = Holding(
                id: MockDataGenerator.mockId(prefix: "holding"),
                portfolioId: retirementPortfolioId,
                stockSymbol: symbol,
                stockName: profile?.name,
                quantity: qty,
                averageCostPerShare: avgCost,
                currentPricePerShare: MockStockDataProvider.currentPrice(for: symbol),
                firstPurchaseDate: MockDataGenerator.pastDate(daysAgo: Int.random(in: 30...150)),
                sector: profile?.sector,
                assetType: profile?.assetType ?? .etf
            )
            holdings[retirementPortfolioId]?.append(holding)
        }

        // Recalculate retirement portfolio value
        let retValue = holdings[retirementPortfolioId]!.reduce(Decimal.zero) { $0 + $1.marketValue }
        let retCostBasis = holdings[retirementPortfolioId]!.reduce(Decimal.zero) { $0 + $1.costBasis }
        retirementPortfolio.totalValue = retValue
        retirementPortfolio.totalCostBasis = retCostBasis
        retirementPortfolio.lastValuationDate = Date()
        portfolios[1] = retirementPortfolio

        // ===========================================
        // THEMED STOCK BASKETS FOR GOALS
        // ===========================================

        // Helper to create DCA schedule with executions
        func createDCASchedule(
            symbol: String,
            amount: Decimal,
            frequency: DCAFrequency,
            executionCount: Int
        ) -> String {
            let scheduleId = MockDataGenerator.mockId(prefix: "dca")
            let profile = MockStockDataProvider.stockProfiles[symbol]
            var totalInvested: Decimal = 0
            var executions: [DCAExecution] = []

            for i in 0..<executionCount {
                let execDate = MockDataGenerator.pastDate(daysAgo: i * frequency.averageDaysBetweenExecutions)
                let priceVariation = Decimal(1.0 + Double.random(in: -0.15...0.10))
                let basePrice = profile?.basePrice ?? 100
                let price = basePrice * priceVariation
                let shares = (amount / price).rounded(places: 4)

                let execution = DCAExecution(
                    id: MockDataGenerator.mockId(prefix: "exec"),
                    scheduleId: scheduleId,
                    stockSymbol: symbol,
                    amount: amount,
                    sharesAcquired: shares,
                    pricePerShare: price,
                    executedAt: execDate
                )
                executions.append(execution)
                totalInvested += amount
            }

            let schedule = DCASchedule(
                id: scheduleId,
                userId: userId,
                stockSymbol: symbol,
                stockName: profile?.name,
                amount: amount,
                frequency: frequency,
                startDate: MockDataGenerator.pastDate(daysAgo: executionCount * frequency.averageDaysBetweenExecutions),
                nextExecutionDate: MockDataGenerator.nextExecutionDate(frequency: frequency),
                portfolioId: mainPortfolioId,
                totalInvested: totalInvested,
                executionCount: executionCount,
                createdAt: MockDataGenerator.pastDate(daysAgo: executionCount * frequency.averageDaysBetweenExecutions)
            )
            dcaSchedules.append(schedule)
            dcaExecutions[scheduleId] = executions
            return scheduleId
        }

        // Helper to calculate current value from DCA executions
        func calculatePositionValue(scheduleIds: [String]) -> Decimal {
            var totalValue: Decimal = 0
            for scheduleId in scheduleIds {
                guard let executions = dcaExecutions[scheduleId],
                      let firstExec = executions.first else { continue }
                let totalShares = executions.reduce(Decimal.zero) { $0 + $1.sharesAcquired }
                let currentPrice = MockStockDataProvider.currentPrice(for: firstExec.stockSymbol)
                totalValue += totalShares * currentPrice
            }
            return totalValue
        }

        // -------------------------------------------
        // AI BASKET - College Fund
        // Tech giants leading in artificial intelligence
        // -------------------------------------------
        let aiBasketSchedules = [
            createDCASchedule(symbol: "NVDA", amount: 100, frequency: .monthly, executionCount: 8),  // NVIDIA - AI chips
            createDCASchedule(symbol: "MSFT", amount: 75, frequency: .monthly, executionCount: 8),   // Microsoft - Azure AI, Copilot
            createDCASchedule(symbol: "GOOGL", amount: 75, frequency: .monthly, executionCount: 8),  // Google - Gemini, DeepMind
            createDCASchedule(symbol: "AMD", amount: 50, frequency: .monthly, executionCount: 8),    // AMD - AI accelerators
            createDCASchedule(symbol: "META", amount: 50, frequency: .monthly, executionCount: 8)    // Meta - Llama, AI research
        ]
        let aiBasketValue = calculatePositionValue(scheduleIds: aiBasketSchedules)
        goals.append(Goal(
            id: MockDataGenerator.mockId(prefix: "goal"),
            userId: userId,
            name: "AI Growth Fund",
            targetAmount: 25000,
            currentAmount: aiBasketValue,
            targetDate: MockDataGenerator.futureDate(daysFromNow: 365 * 5),
            linkedPortfolioId: mainPortfolioId,
            linkedDCAScheduleIds: aiBasketSchedules,
            category: .education,
            iconName: "brain.head.profile",
            colorHex: "#5856D6",
            notes: "AI-focused companies: NVDA, MSFT, GOOGL, AMD, META",
            createdAt: MockDataGenerator.pastDate(daysAgo: 240)
        ))

        // -------------------------------------------
        // ROBOTICS BASKET - House Deposit
        // Industrial automation and robotics leaders
        // -------------------------------------------
        let roboticsBasketSchedules = [
            createDCASchedule(symbol: "ISRG", amount: 80, frequency: .monthly, executionCount: 10),  // Intuitive Surgical - surgical robots
            createDCASchedule(symbol: "HON", amount: 60, frequency: .monthly, executionCount: 10),   // Honeywell - industrial automation
            createDCASchedule(symbol: "ROK", amount: 60, frequency: .monthly, executionCount: 10),   // Rockwell - factory automation
            createDCASchedule(symbol: "TER", amount: 50, frequency: .monthly, executionCount: 10)    // Teradyne - robotics testing
        ]
        let roboticsBasketValue = calculatePositionValue(scheduleIds: roboticsBasketSchedules)
        goals.append(Goal(
            id: MockDataGenerator.mockId(prefix: "goal"),
            userId: userId,
            name: "Robotics Revolution",
            targetAmount: 40000,
            currentAmount: roboticsBasketValue,
            targetDate: MockDataGenerator.futureDate(daysFromNow: 365 * 4),
            linkedPortfolioId: mainPortfolioId,
            linkedDCAScheduleIds: roboticsBasketSchedules,
            category: .house,
            iconName: "gearshape.2.fill",
            colorHex: "#34C759",
            notes: "Robotics & automation: ISRG, HON, ROK, TER",
            createdAt: MockDataGenerator.pastDate(daysAgo: 300)
        ))

        // -------------------------------------------
        // FINTECH/TRADING BASKET - Emergency Fund
        // Financial technology and payment processors
        // -------------------------------------------
        let tradingBasketSchedules = [
            createDCASchedule(symbol: "V", amount: 60, frequency: .biweekly, executionCount: 16),    // Visa
            createDCASchedule(symbol: "MA", amount: 60, frequency: .biweekly, executionCount: 16),   // Mastercard
            createDCASchedule(symbol: "SQ", amount: 40, frequency: .biweekly, executionCount: 16),   // Block (Square)
            createDCASchedule(symbol: "PYPL", amount: 40, frequency: .biweekly, executionCount: 16)  // PayPal
        ]
        let tradingBasketValue = calculatePositionValue(scheduleIds: tradingBasketSchedules)
        goals.append(Goal(
            id: MockDataGenerator.mockId(prefix: "goal"),
            userId: userId,
            name: "FinTech Leaders",
            targetAmount: 15000,
            currentAmount: tradingBasketValue,
            linkedPortfolioId: mainPortfolioId,
            linkedDCAScheduleIds: tradingBasketSchedules,
            category: .emergency,
            iconName: "creditcard.fill",
            colorHex: "#FF3B30",
            notes: "Payments & fintech: V, MA, SQ, PYPL",
            createdAt: MockDataGenerator.pastDate(daysAgo: 200)
        ))

        // Initialize milestones for each goal
        for goal in goals {
            milestones[goal.id] = []
        }

        // Set up funding
        fundingBalance = FundingBalance(
            userId: userId,
            portfolioId: mainPortfolioId,
            availableUSD: 3000,
            availableGBP: 500
        )

        currentFXRate = FXRate(rate: 1.27)

        // Add transfer history
        for i in 0..<5 {
            let transfer = Transfer(
                id: MockDataGenerator.mockId(prefix: "transfer"),
                userId: userId,
                portfolioId: mainPortfolioId,
                type: i % 2 == 0 ? .deposit : .withdrawal,
                status: .completed,
                amount: MockDataGenerator.decimal(min: 500, max: 2000),
                amountUSD: MockDataGenerator.decimal(min: 600, max: 2500),
                fxRate: 1.27,
                referenceNumber: MockDataGenerator.referenceNumber(),
                initiatedAt: MockDataGenerator.pastDate(daysAgo: i * 15 + 5),
                completedAt: MockDataGenerator.pastDate(daysAgo: i * 15 + 3),
                createdAt: MockDataGenerator.pastDate(daysAgo: i * 15 + 5)
            )
            transfers.append(transfer)
        }

        // Set watchlist
        watchlist = MockStockDataProvider.watchlistSymbols
    }

    private func seedFamilyAccountData() async {
        // First seed as active investor
        await seedActiveInvestorData()

        // Then add family data
        guard let user = currentUser else { return }

        let familyId = MockDataGenerator.mockId(prefix: "family")
        let member1Id = MockDataGenerator.mockId(prefix: "user")
        let member2Id = MockDataGenerator.mockId(prefix: "user")

        family = Family(
            id: familyId,
            name: "The Thompsons",
            ownerId: user.id,
            members: [
                FamilyMember(
                    uniqueId: user.id,
                    userId: user.id,
                    name: user.displayName ?? "Owner",
                    email: user.email,
                    role: .admin,
                    joinedAt: MockDataGenerator.pastDate(daysAgo: 90),
                    status: .active
                ),
                FamilyMember(
                    uniqueId: member1Id,
                    userId: member1Id,
                    name: "Sarah Thompson",
                    email: "sarah.thompson@example.com",
                    role: .member,
                    joinedAt: MockDataGenerator.pastDate(daysAgo: 60),
                    status: .active
                ),
                FamilyMember(
                    uniqueId: member2Id,
                    userId: member2Id,
                    name: "Jamie Thompson",
                    email: "jamie.thompson@example.com",
                    role: .viewer,
                    joinedAt: MockDataGenerator.pastDate(daysAgo: 30),
                    status: .active
                )
            ],
            createdAt: MockDataGenerator.pastDate(daysAgo: 90)
        )

        // Add a pending invite
        let invite = FamilyInvite(
            id: MockDataGenerator.mockId(prefix: "invite"),
            familyId: familyId,
            familyName: "The Thompsons",
            inviterId: user.id,
            inviterName: user.displayName ?? "Owner",
            inviteeEmail: "pending@example.com",
            role: .member,
            status: .pending,
            inviteCode: "INV\(Int.random(in: 100000...999999))",
            createdAt: MockDataGenerator.pastDate(daysAgo: 2),
            expiresAt: MockDataGenerator.futureDate(daysFromNow: 7)
        )
        familyInvites.append(invite)

        // Update user subscription to family
        currentUser?.subscriptionTier = .family
    }
}


