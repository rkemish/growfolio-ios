//
//  TestFixtures.swift
//  GrowfolioTests
//
//  Factory methods for creating test instances of all domain models.
//

import Foundation
@testable import Growfolio

// MARK: - TestFixtures

/// Factory methods for creating test instances of domain models
enum TestFixtures {

    // MARK: - Date Helpers

    /// Reference date for consistent testing (2024-06-15 12:00:00 UTC)
    static let referenceDate: Date = {
        var components = DateComponents()
        components.year = 2024
        components.month = 6
        components.day = 15
        components.hour = 12
        components.minute = 0
        components.second = 0
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: components)!
    }()

    /// Date in the past (30 days ago from reference)
    static let pastDate: Date = {
        Calendar.current.date(byAdding: .day, value: -30, to: referenceDate)!
    }()

    /// Date in the future (30 days from reference)
    static let futureDate: Date = {
        Calendar.current.date(byAdding: .day, value: 30, to: referenceDate)!
    }()

    /// Date over 1 year ago (400 days)
    static let longTermDate: Date = {
        Calendar.current.date(byAdding: .day, value: -400, to: referenceDate)!
    }()

    // MARK: - User

    static func user(
        id: String = "user-123",
        email: String = "test@example.com",
        displayName: String? = "Test User",
        profilePictureURL: URL? = nil,
        preferredCurrency: String = "USD",
        notificationsEnabled: Bool = true,
        biometricEnabled: Bool = false,
        createdAt: Date = referenceDate,
        updatedAt: Date = referenceDate,
        subscriptionTier: SubscriptionTier = .free,
        subscriptionExpiresAt: Date? = nil,
        timezoneIdentifier: String = "America/New_York"
    ) -> User {
        User(
            id: id,
            email: email,
            displayName: displayName,
            profilePictureURL: profilePictureURL,
            preferredCurrency: preferredCurrency,
            notificationsEnabled: notificationsEnabled,
            biometricEnabled: biometricEnabled,
            createdAt: createdAt,
            updatedAt: updatedAt,
            subscriptionTier: subscriptionTier,
            subscriptionExpiresAt: subscriptionExpiresAt,
            timezoneIdentifier: timezoneIdentifier
        )
    }

    static var sampleUsers: [User] {
        [
            user(id: "user-1", email: "alice@example.com", displayName: "Alice Smith", subscriptionTier: .premium),
            user(id: "user-2", email: "bob@example.com", displayName: "Bob Jones", subscriptionTier: .free),
            user(id: "user-3", email: "charlie@example.com", displayName: "Charlie Brown", subscriptionTier: .family)
        ]
    }

    // MARK: - Goal

    static func goal(
        id: String = "goal-123",
        userId: String = "user-123",
        name: String = "Test Goal",
        targetAmount: Decimal = 10000,
        currentAmount: Decimal = 2500,
        targetDate: Date? = nil,
        linkedPortfolioId: String? = nil,
        category: GoalCategory = .investment,
        iconName: String = "target",
        colorHex: String = "#007AFF",
        notes: String? = nil,
        isArchived: Bool = false,
        createdAt: Date = referenceDate,
        updatedAt: Date = referenceDate
    ) -> Goal {
        Goal(
            id: id,
            userId: userId,
            name: name,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: targetDate,
            linkedPortfolioId: linkedPortfolioId,
            category: category,
            iconName: iconName,
            colorHex: colorHex,
            notes: notes,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static var sampleGoals: [Goal] {
        [
            goal(id: "goal-1", name: "Retirement Fund", targetAmount: 500000, currentAmount: 125000, category: .retirement),
            goal(id: "goal-2", name: "House Down Payment", targetAmount: 50000, currentAmount: 50000, category: .house),
            goal(id: "goal-3", name: "Emergency Fund", targetAmount: 20000, currentAmount: 5000, category: .emergency),
            goal(id: "goal-4", name: "Vacation", targetAmount: 5000, currentAmount: 0, category: .vacation)
        ]
    }

    // MARK: - DCASchedule

    static func dcaSchedule(
        id: String = "dca-123",
        userId: String = "user-123",
        stockSymbol: String = "AAPL",
        stockName: String? = "Apple Inc.",
        amount: Decimal = 100,
        frequency: DCAFrequency = .monthly,
        preferredDayOfWeek: Int? = nil,
        preferredDayOfMonth: Int? = 15,
        startDate: Date = referenceDate,
        endDate: Date? = nil,
        nextExecutionDate: Date? = nil,
        lastExecutionDate: Date? = nil,
        portfolioId: String = "portfolio-123",
        isActive: Bool = true,
        isPaused: Bool = false,
        totalInvested: Decimal = 1200,
        executionCount: Int = 12,
        createdAt: Date = referenceDate,
        updatedAt: Date = referenceDate
    ) -> DCASchedule {
        DCASchedule(
            id: id,
            userId: userId,
            stockSymbol: stockSymbol,
            stockName: stockName,
            amount: amount,
            frequency: frequency,
            preferredDayOfWeek: preferredDayOfWeek,
            preferredDayOfMonth: preferredDayOfMonth,
            startDate: startDate,
            endDate: endDate,
            nextExecutionDate: nextExecutionDate,
            lastExecutionDate: lastExecutionDate,
            portfolioId: portfolioId,
            isActive: isActive,
            isPaused: isPaused,
            totalInvested: totalInvested,
            executionCount: executionCount,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static var sampleDCASchedules: [DCASchedule] {
        [
            dcaSchedule(id: "dca-1", stockSymbol: "AAPL", amount: 100, frequency: .monthly),
            dcaSchedule(id: "dca-2", stockSymbol: "MSFT", amount: 50, frequency: .weekly, isPaused: true),
            dcaSchedule(id: "dca-3", stockSymbol: "VOO", amount: 500, frequency: .biweekly)
        ]
    }

    // MARK: - Portfolio

    static func portfolio(
        id: String = "portfolio-123",
        userId: String = "user-123",
        name: String = "Test Portfolio",
        description: String? = "My test portfolio",
        type: PortfolioType = .personal,
        currencyCode: String = "USD",
        totalValue: Decimal = 25000,
        totalCostBasis: Decimal = 20000,
        cashBalance: Decimal = 1000,
        lastValuationDate: Date? = nil,
        isDefault: Bool = true,
        colorHex: String = "#007AFF",
        iconName: String = "briefcase.fill",
        createdAt: Date = referenceDate,
        updatedAt: Date = referenceDate
    ) -> Portfolio {
        Portfolio(
            id: id,
            userId: userId,
            name: name,
            description: description,
            type: type,
            currencyCode: currencyCode,
            totalValue: totalValue,
            totalCostBasis: totalCostBasis,
            cashBalance: cashBalance,
            lastValuationDate: lastValuationDate,
            isDefault: isDefault,
            colorHex: colorHex,
            iconName: iconName,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static var samplePortfolios: [Portfolio] {
        [
            portfolio(id: "portfolio-1", name: "Personal Investments", totalValue: 50000, totalCostBasis: 40000),
            portfolio(id: "portfolio-2", name: "Retirement", type: .retirement, totalValue: 150000, totalCostBasis: 100000),
            portfolio(id: "portfolio-3", name: "Emergency Fund", totalValue: 10000, totalCostBasis: 10000, cashBalance: 5000)
        ]
    }

    // MARK: - Holding

    static func holding(
        id: String = "holding-123",
        portfolioId: String = "portfolio-123",
        stockSymbol: String = "AAPL",
        stockName: String? = "Apple Inc.",
        quantity: Decimal = 10,
        averageCostPerShare: Decimal = 150,
        currentPricePerShare: Decimal = 175,
        firstPurchaseDate: Date? = nil,
        lastPurchaseDate: Date? = nil,
        priceUpdatedAt: Date? = nil,
        sector: String? = "Technology",
        industry: String? = "Consumer Electronics",
        assetType: AssetType = .stock,
        createdAt: Date = referenceDate,
        updatedAt: Date = referenceDate
    ) -> Holding {
        Holding(
            id: id,
            portfolioId: portfolioId,
            stockSymbol: stockSymbol,
            stockName: stockName,
            quantity: quantity,
            averageCostPerShare: averageCostPerShare,
            currentPricePerShare: currentPricePerShare,
            firstPurchaseDate: firstPurchaseDate,
            lastPurchaseDate: lastPurchaseDate,
            priceUpdatedAt: priceUpdatedAt,
            sector: sector,
            industry: industry,
            assetType: assetType,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static var sampleHoldings: [Holding] {
        [
            holding(id: "holding-1", stockSymbol: "AAPL", quantity: 10, averageCostPerShare: 150, currentPricePerShare: 175),
            holding(id: "holding-2", stockSymbol: "MSFT", quantity: 5, averageCostPerShare: 300, currentPricePerShare: 350),
            holding(id: "holding-3", stockSymbol: "GOOGL", quantity: 2, averageCostPerShare: 140, currentPricePerShare: 130)
        ]
    }

    // MARK: - Transfer

    static func transfer(
        id: String = "transfer-123",
        userId: String = "user-123",
        portfolioId: String = "portfolio-123",
        type: TransferType = .deposit,
        status: TransferStatus = .completed,
        amount: Decimal = 1000,
        currency: String = "GBP",
        amountUSD: Decimal? = 1250,
        fxRate: Decimal? = 1.25,
        fees: Decimal = 0,
        bankAccountId: String? = "bank-***1234",
        referenceNumber: String? = "TXN123456",
        notes: String? = nil,
        initiatedAt: Date = referenceDate,
        completedAt: Date? = nil,
        expectedCompletionDate: Date? = nil,
        failureReason: String? = nil,
        createdAt: Date = referenceDate,
        updatedAt: Date = referenceDate
    ) -> Transfer {
        Transfer(
            id: id,
            userId: userId,
            portfolioId: portfolioId,
            type: type,
            status: status,
            amount: amount,
            currency: currency,
            amountUSD: amountUSD,
            fxRate: fxRate,
            fees: fees,
            bankAccountId: bankAccountId,
            referenceNumber: referenceNumber,
            notes: notes,
            initiatedAt: initiatedAt,
            completedAt: completedAt,
            expectedCompletionDate: expectedCompletionDate,
            failureReason: failureReason,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static var sampleTransfers: [Transfer] {
        [
            transfer(id: "transfer-1", type: .deposit, status: .completed, amount: 1000),
            transfer(id: "transfer-2", type: .withdrawal, status: .pending, amount: 500),
            transfer(id: "transfer-3", type: .deposit, status: .failed, amount: 2000, failureReason: "Insufficient funds")
        ]
    }

    // MARK: - Family

    static func family(
        id: String = "family-123",
        name: String = "Test Family",
        familyDescription: String? = "A test family group",
        ownerId: String = "user-123",
        adminIds: [String] = ["user-123"],
        members: [FamilyMember] = [],
        maxMembers: Int = 10,
        allowSharedGoals: Bool = true,
        createdAt: Date = referenceDate,
        updatedAt: Date = referenceDate
    ) -> Family {
        Family(
            id: id,
            name: name,
            familyDescription: familyDescription,
            ownerId: ownerId,
            adminIds: adminIds,
            members: members,
            maxMembers: maxMembers,
            allowSharedGoals: allowSharedGoals,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - FamilyMember

    static func familyMember(
        uniqueId: String = "member-123",
        userId: String = "user-456",
        name: String = "Family Member",
        email: String = "member@example.com",
        role: FamilyMemberRole = .member,
        pictureUrl: String? = nil,
        joinedAt: Date = referenceDate,
        status: FamilyMemberStatus = .active,
        sharePortfolioValue: Bool = true,
        shareHoldings: Bool = false,
        sharePerformance: Bool = true
    ) -> FamilyMember {
        FamilyMember(
            uniqueId: uniqueId,
            userId: userId,
            name: name,
            email: email,
            role: role,
            pictureUrl: pictureUrl,
            joinedAt: joinedAt,
            status: status,
            sharePortfolioValue: sharePortfolioValue,
            shareHoldings: shareHoldings,
            sharePerformance: sharePerformance
        )
    }

    static var sampleFamilyMembers: [FamilyMember] {
        [
            familyMember(uniqueId: "member-1", userId: "user-1", name: "Alice Smith", role: .admin, status: .active),
            familyMember(uniqueId: "member-2", userId: "user-2", name: "Bob Smith", role: .member, status: .active),
            familyMember(uniqueId: "member-3", userId: "user-3", name: "Charlie Smith", role: .viewer, status: .pending)
        ]
    }

    // MARK: - FamilyInvite

    static func familyInvite(
        id: String = "invite-123",
        familyId: String = "family-123",
        familyName: String = "Test Family",
        inviterId: String = "user-123",
        inviterName: String = "Test User",
        inviteeEmail: String = "invitee@example.com",
        inviteeUserId: String? = nil,
        role: FamilyMemberRole = .member,
        status: InviteStatus = .pending,
        inviteCode: String = "ABC12345",
        message: String? = "Join our family!",
        createdAt: Date = referenceDate,
        expiresAt: Date? = nil,
        respondedAt: Date? = nil
    ) -> FamilyInvite {
        FamilyInvite(
            id: id,
            familyId: familyId,
            familyName: familyName,
            inviterId: inviterId,
            inviterName: inviterName,
            inviteeEmail: inviteeEmail,
            inviteeUserId: inviteeUserId,
            role: role,
            status: status,
            inviteCode: inviteCode,
            message: message,
            createdAt: createdAt,
            expiresAt: expiresAt ?? Calendar.current.date(byAdding: .day, value: 7, to: createdAt)!,
            respondedAt: respondedAt
        )
    }

    static func receivedInvite(
        invite: FamilyInvite? = nil,
        familyMemberCount: Int = 3,
        familyOwnerName: String = "Family Owner",
        familyDescription: String? = "Test Family Description"
    ) -> ReceivedInvite {
        ReceivedInvite(
            invite: invite ?? familyInvite(),
            familyMemberCount: familyMemberCount,
            familyOwnerName: familyOwnerName,
            familyDescription: familyDescription
        )
    }

    // MARK: - Stock

    static func stock(
        symbol: String = "AAPL",
        name: String = "Apple Inc.",
        exchange: String? = "NASDAQ",
        assetType: AssetType = .stock,
        currentPrice: Decimal? = 175.50,
        priceChange: Decimal? = 2.50,
        priceChangePercent: Decimal? = 1.45,
        previousClose: Decimal? = 173.00,
        openPrice: Decimal? = 174.00,
        dayHigh: Decimal? = 176.00,
        dayLow: Decimal? = 173.50,
        weekHigh52: Decimal? = 199.62,
        weekLow52: Decimal? = 124.17,
        volume: Int? = 45_000_000,
        averageVolume: Int? = 50_000_000,
        marketCap: Decimal? = 2_750_000_000_000,
        peRatio: Decimal? = 28.5,
        dividendYield: Decimal? = 0.52,
        eps: Decimal? = 6.14,
        beta: Decimal? = 1.28,
        sector: String? = "Technology",
        industry: String? = "Consumer Electronics",
        companyDescription: String? = nil,
        websiteURL: URL? = nil,
        logoURL: URL? = nil,
        currencyCode: String = "USD",
        lastUpdated: Date? = nil
    ) -> Stock {
        Stock(
            symbol: symbol,
            name: name,
            exchange: exchange,
            assetType: assetType,
            currentPrice: currentPrice,
            priceChange: priceChange,
            priceChangePercent: priceChangePercent,
            previousClose: previousClose,
            openPrice: openPrice,
            dayHigh: dayHigh,
            dayLow: dayLow,
            weekHigh52: weekHigh52,
            weekLow52: weekLow52,
            volume: volume,
            averageVolume: averageVolume,
            marketCap: marketCap,
            peRatio: peRatio,
            dividendYield: dividendYield,
            eps: eps,
            beta: beta,
            sector: sector,
            industry: industry,
            companyDescription: companyDescription,
            websiteURL: websiteURL,
            logoURL: logoURL,
            currencyCode: currencyCode,
            lastUpdated: lastUpdated
        )
    }

    static var sampleStocks: [Stock] {
        [
            stock(symbol: "AAPL", name: "Apple Inc.", currentPrice: 175.50, priceChange: 2.50),
            stock(symbol: "MSFT", name: "Microsoft Corporation", currentPrice: 350.00, priceChange: -3.25),
            stock(symbol: "GOOGL", name: "Alphabet Inc.", currentPrice: 140.00, priceChange: 0.50)
        ]
    }

    // MARK: - StockQuote

    static func stockQuote(
        symbol: String = "AAPL",
        price: Decimal = 175.50,
        change: Decimal = 2.50,
        changePercent: Decimal = 1.45,
        volume: Int = 45_000_000,
        timestamp: Date = referenceDate
    ) -> StockQuote {
        StockQuote(
            symbol: symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            volume: volume,
            timestamp: timestamp
        )
    }

    // MARK: - MarketHours

    static func marketHours(
        exchange: String = "NYSE",
        isOpen: Bool = true,
        session: MarketSession = .regular,
        nextOpen: Date? = nil,
        nextClose: Date? = nil,
        timestamp: Date? = nil
    ) -> MarketHours {
        MarketHours(
            exchange: exchange,
            isOpen: isOpen,
            session: session,
            nextOpen: nextOpen,
            nextClose: nextClose,
            timestamp: timestamp
        )
    }

    // MARK: - WatchlistItem

    static func watchlistItem(
        symbol: String = "AAPL",
        dateAdded: Date = referenceDate,
        notes: String? = nil
    ) -> WatchlistItem {
        WatchlistItem(
            symbol: symbol,
            dateAdded: dateAdded,
            notes: notes
        )
    }

    static var sampleWatchlistItems: [WatchlistItem] {
        [
            watchlistItem(symbol: "AAPL", notes: "Strong fundamentals"),
            watchlistItem(symbol: "MSFT"),
            watchlistItem(symbol: "NVDA", notes: "AI play")
        ]
    }

    // MARK: - LedgerEntry

    static func ledgerEntry(
        id: String = "ledger-123",
        portfolioId: String = "portfolio-123",
        userId: String = "user-123",
        type: LedgerEntryType = .buy,
        stockSymbol: String? = "AAPL",
        stockName: String? = "Apple Inc.",
        quantity: Decimal? = 10,
        pricePerShare: Decimal? = 150,
        totalAmount: Decimal = 1500,
        fees: Decimal = 0,
        currencyCode: String = "USD",
        transactionDate: Date = referenceDate,
        notes: String? = nil,
        source: LedgerEntrySource = .manual,
        referenceId: String? = nil,
        isReconciled: Bool = false,
        createdAt: Date = referenceDate,
        updatedAt: Date = referenceDate
    ) -> LedgerEntry {
        LedgerEntry(
            id: id,
            portfolioId: portfolioId,
            userId: userId,
            type: type,
            stockSymbol: stockSymbol,
            stockName: stockName,
            quantity: quantity,
            pricePerShare: pricePerShare,
            totalAmount: totalAmount,
            fees: fees,
            currencyCode: currencyCode,
            transactionDate: transactionDate,
            notes: notes,
            source: source,
            referenceId: referenceId,
            isReconciled: isReconciled,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static var sampleLedgerEntries: [LedgerEntry] {
        [
            ledgerEntry(id: "ledger-1", type: .buy, stockSymbol: "AAPL", quantity: 10, pricePerShare: 150, totalAmount: 1500),
            ledgerEntry(id: "ledger-2", type: .sell, stockSymbol: "MSFT", quantity: 5, pricePerShare: 350, totalAmount: 1750),
            ledgerEntry(id: "ledger-3", type: .deposit, stockSymbol: nil, quantity: nil, pricePerShare: nil, totalAmount: 5000),
            ledgerEntry(id: "ledger-4", type: .dividend, stockSymbol: "AAPL", quantity: nil, pricePerShare: nil, totalAmount: 50)
        ]
    }

    // MARK: - CostBasisLot

    static func costBasisLot(
        date: Date = referenceDate,
        shares: Decimal = 10,
        priceUsd: Decimal = 150,
        totalUsd: Decimal = 1500,
        totalGbp: Decimal = 1200,
        fxRate: Decimal = 1.25
    ) -> CostBasisLot {
        CostBasisLot(
            date: date,
            shares: shares,
            priceUsd: priceUsd,
            totalUsd: totalUsd,
            totalGbp: totalGbp,
            fxRate: fxRate
        )
    }

    static var sampleCostBasisLots: [CostBasisLot] {
        [
            costBasisLot(date: longTermDate, shares: 5, priceUsd: 100, totalUsd: 500, totalGbp: 400, fxRate: 1.25),
            costBasisLot(date: pastDate, shares: 10, priceUsd: 150, totalUsd: 1500, totalGbp: 1200, fxRate: 1.25),
            costBasisLot(date: referenceDate, shares: 3, priceUsd: 175, totalUsd: 525, totalGbp: 420, fxRate: 1.25)
        ]
    }

    // MARK: - CostBasisSummary

    static func costBasisSummary(
        symbol: String = "AAPL",
        totalShares: Decimal = 18,
        totalCostUsd: Decimal = 2525,
        totalCostGbp: Decimal = 2020,
        averageCostUsd: Decimal = 140.28,
        averageCostGbp: Decimal = 112.22,
        lots: [CostBasisLot] = sampleCostBasisLots,
        currentPriceUsd: Decimal? = 175,
        currentFxRate: Decimal? = 1.25
    ) -> CostBasisSummary {
        CostBasisSummary(
            symbol: symbol,
            totalShares: totalShares,
            totalCostUsd: totalCostUsd,
            totalCostGbp: totalCostGbp,
            averageCostUsd: averageCostUsd,
            averageCostGbp: averageCostGbp,
            lots: lots,
            currentPriceUsd: currentPriceUsd,
            currentFxRate: currentFxRate
        )
    }

    // MARK: - ChatMessage

    static func chatMessage(
        id: String = "msg-123",
        role: MessageRole = .user,
        content: String = "Hello, how can I help?",
        timestamp: Date = referenceDate,
        isStreaming: Bool = false,
        suggestedActions: [String]? = nil
    ) -> ChatMessage {
        ChatMessage(
            id: id,
            role: role,
            content: content,
            timestamp: timestamp,
            isStreaming: isStreaming,
            suggestedActions: suggestedActions
        )
    }

    static var sampleChatMessages: [ChatMessage] {
        [
            chatMessage(id: "msg-1", role: .user, content: "What should I invest in?"),
            chatMessage(id: "msg-2", role: .assistant, content: "Based on your portfolio, I recommend diversifying into ETFs.", suggestedActions: ["Learn more", "View ETFs"])
        ]
    }

    // MARK: - AIInsight

    static func aiInsight(
        id: String = "insight-123",
        type: InsightType = .portfolioHealth,
        title: String = "Portfolio Health Check",
        content: String = "Your portfolio is well-diversified across sectors.",
        priority: InsightPriority = .medium,
        action: InsightAction? = nil,
        generatedAt: Date = referenceDate,
        isDismissed: Bool = false
    ) -> AIInsight {
        AIInsight(
            id: id,
            type: type,
            title: title,
            content: content,
            priority: priority,
            action: action,
            generatedAt: generatedAt,
            isDismissed: isDismissed
        )
    }

    static var sampleInsights: [AIInsight] {
        [
            aiInsight(id: "insight-1", type: .portfolioHealth, title: "Good Diversification", priority: .low),
            aiInsight(id: "insight-2", type: .riskAlert, title: "High Concentration", content: "50% of portfolio is in one stock", priority: .high),
            aiInsight(id: "insight-3", type: .dcaSuggestion, title: "Consider DCA", content: "Start a monthly investment plan", priority: .medium)
        ]
    }

    // MARK: - StockExplanation

    static func stockExplanation(
        symbol: String = "AAPL",
        explanation: String = "Apple Inc. is a technology company that designs and manufactures consumer electronics.",
        generatedAt: Date = referenceDate
    ) -> StockExplanation {
        StockExplanation(
            symbol: symbol,
            explanation: explanation,
            generatedAt: generatedAt
        )
    }

    // MARK: - KYCData

    static func kycData(
        firstName: String = "John",
        lastName: String = "Doe",
        dateOfBirth: Date? = nil,
        phoneNumber: String = "+1234567890",
        streetAddress: String = "123 Main St",
        apartmentUnit: String = "",
        city: String = "New York",
        state: String = "NY",
        postalCode: String = "10001",
        country: String = "USA",
        taxIdType: TaxIdType = .ssn,
        taxId: String = "123-45-6789",
        citizenship: String = "USA",
        taxCountry: String = "USA",
        employmentStatus: EmploymentStatus = .employed,
        employer: String = "Acme Corp",
        occupation: String = "Software Engineer",
        fundingSource: FundingSource = .employmentIncome,
        annualIncome: AnnualIncomeRange = .range100kTo200k,
        liquidNetWorth: LiquidNetWorthRange = .range100kTo200k,
        totalNetWorth: TotalNetWorthRange = .range200kTo500k,
        disclosuresAccepted: Bool = true,
        customerAgreementAccepted: Bool = true,
        accountAgreementAccepted: Bool = true,
        marketDataAgreementAccepted: Bool = true
    ) -> KYCData {
        var data = KYCData()
        data.firstName = firstName
        data.lastName = lastName
        data.dateOfBirth = dateOfBirth
        data.phoneNumber = phoneNumber
        data.streetAddress = streetAddress
        data.apartmentUnit = apartmentUnit
        data.city = city
        data.state = state
        data.postalCode = postalCode
        data.country = country
        data.taxIdType = taxIdType
        data.taxId = taxId
        data.citizenship = citizenship
        data.taxCountry = taxCountry
        data.employmentStatus = employmentStatus
        data.employer = employer
        data.occupation = occupation
        data.fundingSource = fundingSource
        data.annualIncome = annualIncome
        data.liquidNetWorth = liquidNetWorth
        data.totalNetWorth = totalNetWorth
        data.disclosuresAccepted = disclosuresAccepted
        data.customerAgreementAccepted = customerAgreementAccepted
        data.accountAgreementAccepted = accountAgreementAccepted
        data.marketDataAgreementAccepted = marketDataAgreementAccepted
        return data
    }

    // MARK: - FundingBalance

    static func fundingBalance(
        id: String = "balance-123",
        userId: String = "user-123",
        portfolioId: String = "portfolio-123",
        availableUSD: Decimal = 5000,
        availableGBP: Decimal = 4000,
        pendingDepositsUSD: Decimal = 0,
        pendingDepositsGBP: Decimal = 500,
        pendingWithdrawalsUSD: Decimal = 0,
        pendingWithdrawalsGBP: Decimal = 0,
        updatedAt: Date = referenceDate
    ) -> FundingBalance {
        FundingBalance(
            id: id,
            userId: userId,
            portfolioId: portfolioId,
            availableUSD: availableUSD,
            availableGBP: availableGBP,
            pendingDepositsUSD: pendingDepositsUSD,
            pendingDepositsGBP: pendingDepositsGBP,
            pendingWithdrawalsUSD: pendingWithdrawalsUSD,
            pendingWithdrawalsGBP: pendingWithdrawalsGBP,
            updatedAt: updatedAt
        )
    }

    // MARK: - FXRate

    static func fxRate(
        fromCurrency: String = "GBP",
        toCurrency: String = "USD",
        rate: Decimal = 1.25,
        spread: Decimal = 0.01,
        timestamp: Date = referenceDate,
        expiresAt: Date? = nil
    ) -> FXRate {
        FXRate(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            rate: rate,
            spread: spread,
            timestamp: timestamp,
            expiresAt: expiresAt
        )
    }
}

// MARK: - JSON Encoding Helpers

extension TestFixtures {

    // MARK: - Basket

    static func basket(
        id: String = "basket-123",
        userId: String = "user-123",
        familyId: String? = nil,
        name: String = "Test Basket",
        description: String? = "Test basket description",
        category: String? = "Technology",
        icon: String? = "chart.bar.fill",
        color: String? = "#007AFF",
        allocations: [BasketAllocation] = [],
        dcaEnabled: Bool = false,
        dcaScheduleId: String? = nil,
        status: BasketStatus = .active,
        currentValue: Decimal = 1000,
        totalInvested: Decimal = 900,
        totalGainLoss: Decimal = 100,
        isShared: Bool = false,
        createdAt: Date = referenceDate,
        updatedAt: Date = referenceDate
    ) -> Basket {
        let summary = BasketSummary(
            currentValue: currentValue,
            totalInvested: totalInvested,
            totalGainLoss: totalGainLoss
        )

        let defaultAllocations = allocations.isEmpty ? [
            BasketAllocation(symbol: "AAPL", name: "Apple Inc.", percentage: 50, targetShares: nil),
            BasketAllocation(symbol: "MSFT", name: "Microsoft Corp.", percentage: 50, targetShares: nil)
        ] : allocations

        return Basket(
            id: id,
            userId: userId,
            familyId: familyId,
            name: name,
            description: description,
            category: category,
            icon: icon,
            color: color,
            allocations: defaultAllocations,
            dcaEnabled: dcaEnabled,
            dcaScheduleId: dcaScheduleId,
            status: status,
            summary: summary,
            isShared: isShared,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static var sampleBaskets: [Basket] {
        [
            basket(
                id: "basket-1",
                name: "Tech Growth",
                category: "Technology",
                icon: "laptopcomputer",
                status: .active,
                currentValue: 5000,
                totalInvested: 4500,
                totalGainLoss: 500
            ),
            basket(
                id: "basket-2",
                name: "Dividend Kings",
                category: "Income",
                icon: "dollarsign.circle",
                status: .active,
                currentValue: 3000,
                totalInvested: 2800,
                totalGainLoss: 200
            ),
            basket(
                id: "basket-3",
                name: "ESG Portfolio",
                category: "Sustainable",
                icon: "leaf",
                status: .paused,
                currentValue: 1500,
                totalInvested: 1600,
                totalGainLoss: -100
            )
        ]
    }

    // MARK: - Order

    static func order(
        id: String = "order-123",
        clientOrderId: String? = "client-order-123",
        symbol: String = "AAPL",
        side: OrderSide = .buy,
        type: OrderType = .market,
        status: OrderStatus = .filled,
        timeInForce: TimeInForce = .day,
        quantity: Decimal? = 10,
        notional: Decimal? = nil,
        filledQuantity: Decimal? = 10,
        filledAvgPrice: Decimal? = 150.25,
        limitPrice: Decimal? = nil,
        stopPrice: Decimal? = nil,
        submittedAt: Date = referenceDate,
        filledAt: Date? = nil,
        canceledAt: Date? = nil,
        expiredAt: Date? = nil
    ) -> Order {
        Order(
            id: id,
            clientOrderId: clientOrderId,
            symbol: symbol,
            side: side,
            type: type,
            status: status,
            timeInForce: timeInForce,
            quantity: quantity,
            notional: notional,
            filledQuantity: filledQuantity,
            filledAvgPrice: filledAvgPrice,
            limitPrice: limitPrice,
            stopPrice: stopPrice,
            submittedAt: submittedAt,
            filledAt: filledAt ?? referenceDate,
            canceledAt: canceledAt,
            expiredAt: expiredAt
        )
    }

    static var sampleOrders: [Order] {
        [
            order(id: "order-1", symbol: "AAPL", side: .buy, status: .filled, quantity: 10),
            order(id: "order-2", symbol: "MSFT", side: .buy, status: .partiallyFilled, quantity: 5),
            order(id: "order-3", symbol: "GOOGL", side: .sell, status: .pendingNew, quantity: 3)
        ]
    }

    // MARK: - Position

    static func position(
        symbol: String = "AAPL",
        quantity: Decimal = 100,
        marketValueUsd: Decimal = 15000,
        marketValueGbp: Decimal = 11811.02,
        costBasis: Decimal = 13000,
        unrealizedPnlUsd: Decimal = 2000,
        unrealizedPnlGbp: Decimal = 1574.80,
        averageEntryPrice: Decimal = 130,
        currentPrice: Decimal = 150,
        changePct: Decimal = 15.38,
        side: PositionSide = .long,
        lastUpdated: Date = referenceDate
    ) -> Position {
        Position(
            symbol: symbol,
            quantity: quantity,
            marketValueUsd: marketValueUsd,
            marketValueGbp: marketValueGbp,
            costBasis: costBasis,
            unrealizedPnlUsd: unrealizedPnlUsd,
            unrealizedPnlGbp: unrealizedPnlGbp,
            averageEntryPrice: averageEntryPrice,
            currentPrice: currentPrice,
            changePct: changePct,
            side: side,
            lastUpdated: lastUpdated
        )
    }

    static var samplePositions: [Position] {
        [
            position(symbol: "AAPL", quantity: 100, marketValueUsd: 15000),
            position(symbol: "MSFT", quantity: 50, marketValueUsd: 17500),
            position(symbol: "GOOGL", quantity: 25, marketValueUsd: 3375)
        ]
    }

    // MARK: - BankAccount

    static func bankAccount(
        id: String = "bank-123",
        relationshipId: String = "rel-123",
        userId: String = "user-123",
        bankName: String = "Chase Bank",
        accountType: BankAccountType = .checking,
        accountNumberLast4: String = "1234",
        status: BankAccountStatus = .active,
        capabilities: [String] = ["ach_debit", "ach_credit"],
        linkedAt: Date = referenceDate
    ) -> BankAccount {
        BankAccount(
            id: id,
            relationshipId: relationshipId,
            userId: userId,
            bankName: bankName,
            accountType: accountType,
            accountNumberLast4: accountNumberLast4,
            status: status,
            capabilities: capabilities,
            linkedAt: linkedAt
        )
    }

    static var sampleBankAccounts: [BankAccount] {
        [
            bankAccount(id: "bank-1", bankName: "Chase Bank", accountNumberLast4: "1234"),
            bankAccount(id: "bank-2", bankName: "Bank of America", accountNumberLast4: "5678"),
            bankAccount(id: "bank-3", bankName: "Wells Fargo", accountNumberLast4: "9012", status: .pending)
        ]
    }

    // MARK: - FundingWallet

    static func fundingWallet(
        balance: Decimal = 1000,
        currency: String = "USD",
        pendingTransfers: [PendingTransfer] = [],
        fundingDetails: FundingDetails? = nil
    ) -> FundingWallet {
        FundingWallet(
            balance: balance,
            currency: currency,
            pendingTransfers: pendingTransfers,
            fundingDetails: fundingDetails ?? TestFixtures.fundingDetails()
        )
    }

    static func fundingDetails(
        accountNumber: String = "123456789",
        routingNumber: String = "021000021",
        swiftCode: String? = nil,
        iban: String? = nil
    ) -> FundingDetails {
        FundingDetails(
            accountNumber: accountNumber,
            routingNumber: routingNumber,
            swiftCode: swiftCode,
            iban: iban
        )
    }

    static func recipientBankInfo(
        bankName: String = "Alpaca Securities LLC",
        accountNumber: String = "987654321",
        routingNumber: String = "021000021",
        accountType: String = "checking",
        wireInstructions: String? = "Reference: USER123456"
    ) -> RecipientBankInfo {
        RecipientBankInfo(
            bankName: bankName,
            accountNumber: accountNumber,
            routingNumber: routingNumber,
            accountType: accountType,
            wireInstructions: wireInstructions
        )
    }

    static func pendingTransfer(
        id: String = "transfer-123",
        amount: Decimal = 500,
        direction: TransferDirection = .incoming,
        status: String = "pending",
        createdAt: Date = referenceDate
    ) -> PendingTransfer {
        PendingTransfer(
            id: id,
            amount: amount,
            direction: direction,
            status: status,
            createdAt: createdAt
        )
    }

    // MARK: - Document

    static func document(
        id: String = "doc-123",
        userId: String = "user-123",
        type: DocumentType = .statement,
        title: String = "Monthly Statement - June 2024",
        description: String? = "Portfolio statement for June 2024",
        fileUrl: URL = URL(string: "https://example.com/doc.pdf")!,
        fileSize: Int64 = 524288,
        mimeType: String = "application/pdf",
        createdAt: Date = referenceDate
    ) -> Document {
        Document(
            id: id,
            userId: userId,
            type: type,
            title: title,
            description: description,
            fileUrl: fileUrl,
            fileSize: fileSize,
            mimeType: mimeType,
            createdAt: createdAt
        )
    }

    static var sampleDocuments: [Document] {
        [
            document(id: "doc-1", type: .statement, title: "Statement - June 2024"),
            document(id: "doc-2", type: .taxForm, title: "1099-DIV Tax Form"),
            document(id: "doc-3", type: .confirmation, title: "Trade Confirmation - AAPL")
        ]
    }

    // MARK: - CorporateAction

    static func corporateAction(
        id: String = "ca-123",
        symbol: String = "AAPL",
        type: CorporateActionType = .dividend,
        announcedDate: Date = pastDate,
        exDate: Date? = nil,
        recordDate: Date? = nil,
        payableDate: Date? = nil,
        amount: Decimal? = 0.25,
        oldRate: Decimal? = nil,
        newRate: Decimal? = nil,
        description: String = "Quarterly dividend payment",
        status: CorporateActionStatus = .executed
    ) -> CorporateAction {
        CorporateAction(
            id: id,
            symbol: symbol,
            type: type,
            announcedDate: announcedDate,
            exDate: exDate ?? referenceDate,
            recordDate: recordDate,
            payableDate: payableDate ?? futureDate,
            amount: amount,
            oldRate: oldRate,
            newRate: newRate,
            description: description,
            status: status
        )
    }

    static var sampleCorporateActions: [CorporateAction] {
        [
            corporateAction(id: "ca-1", symbol: "AAPL", type: .dividend, amount: 0.25),
            corporateAction(id: "ca-2", symbol: "GOOGL", type: .split, oldRate: 1, newRate: 20),
            corporateAction(id: "ca-3", symbol: "MSFT", type: .dividend, amount: 0.75, status: .pending)
        ]
    }

    // MARK: - Helper Methods

    /// Helper to encode a model to JSON Data
    static func jsonData<T: Encodable>(for model: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(model)
    }

    /// Helper to decode JSON Data to a model
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: data)
    }
}
