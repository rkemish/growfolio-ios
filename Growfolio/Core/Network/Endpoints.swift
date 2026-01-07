//
//  Endpoints.swift
//  Growfolio
//
//  API endpoint definitions for the Growfolio backend.
//

import Foundation

/// HTTP methods supported by the API
enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Protocol defining an API endpoint
protocol Endpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    var requiresAuthentication: Bool { get }
    var timeout: TimeInterval { get }
}

/// Default implementations for Endpoint
extension Endpoint {
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    var requiresAuthentication: Bool { true }
    var timeout: TimeInterval { Constants.API.requestTimeout }
}

// MARK: - API Endpoints

/// All available API endpoints
enum Endpoints {

    // MARK: - Auth Endpoints

    struct ExchangeAppleToken: Endpoint {
        let path = "/\(Constants.API.version)/auth/token"
        let method: HTTPMethod = .post
        let body: Data?
        let requiresAuthentication = false

        init(request: AppleTokenExchangeRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    // MARK: - User Endpoints

    struct GetCurrentUser: Endpoint {
        let path = "/\(Constants.API.version)/users/me"
        let method: HTTPMethod = .get
    }

    struct UpdateUser: Endpoint {
        let path = "/\(Constants.API.version)/users/me"
        let method: HTTPMethod = .patch
        let body: Data?

        init(update: UserUpdateRequest) throws {
            self.body = try JSONEncoder().encode(update)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct DeleteUser: Endpoint {
        let path = "/\(Constants.API.version)/users/me"
        let method: HTTPMethod = .delete
    }

    struct GetPreferences: Endpoint {
        let path = "/\(Constants.API.version)/users/me/preferences"
        let method: HTTPMethod = .get
    }

    struct UpdatePreferences: Endpoint {
        let path = "/\(Constants.API.version)/users/me/preferences"
        let method: HTTPMethod = .put
        let body: Data?

        init(preferences: UserPreferencesUpdateRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(preferences)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    // MARK: - Device Registration

    struct RegisterDevice: Endpoint {
        let path = "/\(Constants.API.version)/devices"
        let method: HTTPMethod = .post
        let body: Data?

        init(token: String) {
            let payload = ["device_token": token, "platform": "ios"]
            self.body = try? JSONEncoder().encode(payload)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    static func registerDevice(token: String) -> RegisterDevice {
        RegisterDevice(token: token)
    }

    // MARK: - Goals Endpoints

    struct GetGoals: Endpoint {
        let path = "/\(Constants.API.version)/goals"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(page: Int = 1, limit: Int = Constants.API.defaultPageSize) {
            self.queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        }
    }

    struct GetGoal: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(id: String) {
            self.path = "/\(Constants.API.version)/goals/\(id)"
        }
    }

    struct CreateGoal: Endpoint {
        let path = "/\(Constants.API.version)/goals"
        let method: HTTPMethod = .post
        let body: Data?

        init(goal: GoalCreateRequest) throws {
            self.body = try JSONEncoder().encode(goal)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct UpdateGoal: Endpoint {
        let path: String
        let method: HTTPMethod = .patch
        let body: Data?

        init(id: String, update: GoalUpdateRequest) throws {
            self.path = "/\(Constants.API.version)/goals/\(id)"
            self.body = try JSONEncoder().encode(update)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct DeleteGoal: Endpoint {
        let path: String
        let method: HTTPMethod = .delete

        init(id: String) {
            self.path = "/\(Constants.API.version)/goals/\(id)"
        }
    }

    // MARK: - Portfolio Endpoints

    struct GetPortfolios: Endpoint {
        let path = "/\(Constants.API.version)/portfolios"
        let method: HTTPMethod = .get
    }

    struct GetPortfolio: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(id: String) {
            self.path = "/\(Constants.API.version)/portfolios/\(id)"
        }
    }

    struct GetPortfolioHoldings: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(portfolioId: String) {
            self.path = "/\(Constants.API.version)/portfolios/\(portfolioId)/holdings"
        }
    }

    struct GetPortfolioPerformance: Endpoint {
        let path: String
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(portfolioId: String, period: PerformancePeriod = .oneMonth) {
            self.path = "/\(Constants.API.version)/portfolios/\(portfolioId)/performance"
            self.queryItems = [URLQueryItem(name: "period", value: period.rawValue)]
        }
    }

    // MARK: - Basket Endpoints

    struct GetBaskets: Endpoint {
        let path = "/\(Constants.API.version)/baskets"
        let method: HTTPMethod = .get
    }

    struct GetBasket: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(id: String) {
            self.path = "/\(Constants.API.version)/baskets/\(id)"
        }
    }

    struct CreateBasket: Endpoint {
        let path = "/\(Constants.API.version)/baskets"
        let method: HTTPMethod = .post
        let body: Data?

        init(basket: BasketCreate) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(basket)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct UpdateBasket: Endpoint {
        let path: String
        let method: HTTPMethod = .patch
        let body: Data?

        init(id: String, basket: BasketCreate) throws {
            self.path = "/\(Constants.API.version)/baskets/\(id)"
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(basket)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct DeleteBasket: Endpoint {
        let path: String
        let method: HTTPMethod = .delete

        init(id: String) {
            self.path = "/\(Constants.API.version)/baskets/\(id)"
        }
    }

    // MARK: - DCA Endpoints

    struct GetDCASchedules: Endpoint {
        let path = "/\(Constants.API.version)/dca/schedules"
        let method: HTTPMethod = .get
    }

    struct GetDCASchedule: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(id: String) {
            self.path = "/\(Constants.API.version)/dca/schedules/\(id)"
        }
    }

    struct CreateDCASchedule: Endpoint {
        let path = "/\(Constants.API.version)/dca/schedules"
        let method: HTTPMethod = .post
        let body: Data?

        init(schedule: DCAScheduleCreateRequest) throws {
            self.body = try JSONEncoder().encode(schedule)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct UpdateDCASchedule: Endpoint {
        let path: String
        let method: HTTPMethod = .patch
        let body: Data?

        init(id: String, update: DCAScheduleUpdateRequest) throws {
            self.path = "/\(Constants.API.version)/dca/schedules/\(id)"
            self.body = try JSONEncoder().encode(update)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct DeleteDCASchedule: Endpoint {
        let path: String
        let method: HTTPMethod = .delete

        init(id: String) {
            self.path = "/\(Constants.API.version)/dca/schedules/\(id)"
        }
    }

    // MARK: - Stock Endpoints

    struct SearchStocks: Endpoint {
        let path = "/\(Constants.API.version)/stocks/search"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(query: String, limit: Int = 10) {
            self.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        }
    }

    struct GetStock: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(symbol: String) {
            self.path = "/\(Constants.API.version)/stocks/\(symbol)"
        }
    }

    struct GetStockQuote: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(symbol: String) {
            self.path = "/\(Constants.API.version)/stocks/\(symbol)/quote"
        }
    }

    struct GetStockHistory: Endpoint {
        let path: String
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(symbol: String, period: HistoryPeriod = .oneYear) {
            self.path = "/\(Constants.API.version)/stocks/\(symbol)/history"
            self.queryItems = [URLQueryItem(name: "period", value: period.rawValue)]
        }
    }

    struct GetMarketStatus: Endpoint {
        let path = "/\(Constants.API.version)/stocks/market/status"
        let method: HTTPMethod = .get
    }

    struct SubmitBuyOrder: Endpoint {
        let path = "/\(Constants.API.version)/orders"
        let method: HTTPMethod = .post
        let body: Data?

        init(symbol: String, notionalUSD: Decimal) throws {
            let request = BuyOrderRequest(
                symbol: symbol.uppercased(),
                side: "buy",
                type: "market",
                timeInForce: "day",
                notional: notionalUSD
            )
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    // MARK: - Family Endpoints

    struct GetFamilyAccounts: Endpoint {
        let path = "/\(Constants.API.version)/family/accounts"
        let method: HTTPMethod = .get
    }

    struct CreateFamilyAccount: Endpoint {
        let path = "/\(Constants.API.version)/family/accounts"
        let method: HTTPMethod = .post
        let body: Data?

        init(account: FamilyAccountCreateRequest) throws {
            self.body = try JSONEncoder().encode(account)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    // MARK: - Family Group Endpoints

    struct GetFamily: Endpoint {
        let path = "/\(Constants.API.version)/family"
        let method: HTTPMethod = .get
    }

    struct CreateFamily: Endpoint {
        let path = "/\(Constants.API.version)/family"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: FamilyCreateRequest) throws {
            self.body = try JSONEncoder().encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct UpdateFamily: Endpoint {
        let path: String
        let method: HTTPMethod = .patch
        let body: Data?

        init(id: String, request: FamilyUpdateRequest) throws {
            self.path = "/\(Constants.API.version)/family/\(id)"
            self.body = try JSONEncoder().encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct DeleteFamily: Endpoint {
        let path: String
        let method: HTTPMethod = .delete

        init(id: String) {
            self.path = "/\(Constants.API.version)/family/\(id)"
        }
    }

    struct InviteFamilyMember: Endpoint {
        let path = "/\(Constants.API.version)/family/invite"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: FamilyInviteRequest) throws {
            self.body = try JSONEncoder().encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct GetFamilyInvites: Endpoint {
        let path = "/\(Constants.API.version)/family/invites"
        let method: HTTPMethod = .get
    }

    struct GetReceivedInvites: Endpoint {
        let path = "/\(Constants.API.version)/family/invites/received"
        let method: HTTPMethod = .get
    }

    struct ResendFamilyInvite: Endpoint {
        let path: String
        let method: HTTPMethod = .post

        init(inviteId: String) {
            self.path = "/\(Constants.API.version)/family/invites/\(inviteId)/resend"
        }
    }

    struct CancelFamilyInvite: Endpoint {
        let path: String
        let method: HTTPMethod = .delete

        init(inviteId: String) {
            self.path = "/\(Constants.API.version)/family/invites/\(inviteId)"
        }
    }

    struct AcceptFamilyInvite: Endpoint {
        let path: String
        let method: HTTPMethod = .post

        init(inviteId: String) {
            self.path = "/\(Constants.API.version)/family/invites/\(inviteId)/accept"
        }
    }

    struct DeclineFamilyInvite: Endpoint {
        let path: String
        let method: HTTPMethod = .post

        init(inviteId: String) {
            self.path = "/\(Constants.API.version)/family/invites/\(inviteId)/decline"
        }
    }

    struct UpdateFamilyMember: Endpoint {
        let path: String
        let method: HTTPMethod = .patch
        let body: Data?

        init(memberId: String, request: FamilyMemberUpdateRequest) throws {
            self.path = "/\(Constants.API.version)/family/members/\(memberId)"
            self.body = try JSONEncoder().encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct RemoveFamilyMember: Endpoint {
        let path: String
        let method: HTTPMethod = .delete

        init(memberId: String) {
            self.path = "/\(Constants.API.version)/family/members/\(memberId)"
        }
    }

    struct LeaveFamily: Endpoint {
        let path = "/\(Constants.API.version)/family/leave"
        let method: HTTPMethod = .post
    }

    struct GetFamilyGoals: Endpoint {
        let path = "/\(Constants.API.version)/family/goals"
        let method: HTTPMethod = .get
    }

    // MARK: - Stock Price Endpoint

    struct GetStockPrice: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(symbol: String) {
            self.path = "/\(Constants.API.version)/stocks/\(symbol.uppercased())/price"
        }
    }

    // MARK: - Ledger Endpoints

    struct GetLedgerEntries: Endpoint {
        let path: String
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(portfolioId: String, page: Int = 1, limit: Int = Constants.API.defaultPageSize) {
            self.path = "/\(Constants.API.version)/portfolios/\(portfolioId)/ledger"
            self.queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        }
    }

    struct CreateLedgerEntry: Endpoint {
        let path: String
        let method: HTTPMethod = .post
        let body: Data?

        init(portfolioId: String, entry: LedgerEntryCreateRequest) throws {
            self.path = "/\(Constants.API.version)/portfolios/\(portfolioId)/ledger"
            self.body = try JSONEncoder().encode(entry)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct GetCostBasis: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(symbol: String) {
            self.path = "/\(Constants.API.version)/ledger/cost-basis/\(symbol.uppercased())"
        }
    }

    // MARK: - AI Insights Endpoints

    struct GetAIInsights: Endpoint {
        let path = "/\(Constants.API.version)/insights"
        let method: HTTPMethod = .get
    }

    struct GetGoalInsights: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(goalId: String) {
            self.path = "/\(Constants.API.version)/goals/\(goalId)/insights"
        }
    }

    // MARK: - KYC Endpoints

    struct SubmitKYC: Endpoint {
        let path = "/\(Constants.API.version)/auth/create-account"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: KYCSubmissionRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct GetKYCStatus: Endpoint {
        let path = "/\(Constants.API.version)/auth/kyc-status"
        let method: HTTPMethod = .get
    }

    // MARK: - AI Chat Endpoints

    struct AIChat: Endpoint {
        let path = "/\(Constants.API.version)/ai/chat"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: AIChatRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct GetPortfolioInsights: Endpoint {
        let path = "/\(Constants.API.version)/ai/insights"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(includeGoals: Bool = true) {
            self.queryItems = [
                URLQueryItem(name: "include_goals", value: "\(includeGoals)")
            ]
        }
    }

    struct GetStockExplanation: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(symbol: String) {
            self.path = "/\(Constants.API.version)/ai/explain/\(symbol.uppercased())"
        }
    }

    struct SuggestAllocation: Endpoint {
        let path = "/\(Constants.API.version)/ai/suggest-allocation"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: AllocationRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct GetInvestingTips: Endpoint {
        let path = "/\(Constants.API.version)/ai/tips"
        let method: HTTPMethod = .get
    }

    // MARK: - Funding Endpoints

    struct GetFundingBalance: Endpoint {
        let path = "/\(Constants.API.version)/funding/balance"
        let method: HTTPMethod = .get
    }

    struct GetFXRate: Endpoint {
        let path = "/\(Constants.API.version)/funding/fx-rate"
        let method: HTTPMethod = .get
    }

    struct InitiateDeposit: Endpoint {
        let path = "/\(Constants.API.version)/funding/deposit"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: FundingTransferRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct ConfirmDeposit: Endpoint {
        let path = "/\(Constants.API.version)/funding/deposit/confirm"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: FundingConfirmRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct InitiateWithdrawal: Endpoint {
        let path = "/\(Constants.API.version)/funding/withdraw"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: FundingTransferRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct ConfirmWithdrawal: Endpoint {
        let path = "/\(Constants.API.version)/funding/withdraw/confirm"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: FundingConfirmRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct GetTransfer: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(id: String) {
            self.path = "/\(Constants.API.version)/funding/transfers/\(id)"
        }
    }

    struct CancelTransfer: Endpoint {
        let path: String
        let method: HTTPMethod = .post

        init(id: String) {
            self.path = "/\(Constants.API.version)/funding/transfers/\(id)/cancel"
        }
    }

    struct GetTransferHistory: Endpoint {
        let path: String
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(page: Int = 1, limit: Int = Constants.API.defaultPageSize) {
            self.path = "/\(Constants.API.version)/funding/history"
            self.queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        }

        init(portfolioId: String, page: Int = 1, limit: Int = Constants.API.defaultPageSize) {
            self.path = "/\(Constants.API.version)/funding/history"
            self.queryItems = [
                URLQueryItem(name: "portfolio_id", value: portfolioId),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        }
    }
}

// MARK: - Supporting Types

enum PerformancePeriod: String, Codable, Sendable, CaseIterable {
    case oneDay = "1d"
    case oneWeek = "1w"
    case oneMonth = "1m"
    case threeMonths = "3m"
    case sixMonths = "6m"
    case oneYear = "1y"
    case yearToDate = "ytd"
    case all = "all"

    var displayName: String {
        switch self {
        case .oneDay: return "1D"
        case .oneWeek: return "1W"
        case .oneMonth: return "1M"
        case .threeMonths: return "3M"
        case .sixMonths: return "6M"
        case .oneYear: return "1Y"
        case .yearToDate: return "YTD"
        case .all: return "All"
        }
    }
}

enum HistoryPeriod: String, Codable, Sendable {
    case oneWeek = "1w"
    case oneMonth = "1m"
    case threeMonths = "3m"
    case sixMonths = "6m"
    case oneYear = "1y"
    case fiveYears = "5y"
    case all = "all"
}

// MARK: - Request DTOs

struct UserUpdateRequest: Codable, Sendable {
    var displayName: String?
    var preferredCurrency: String?
    var notificationsEnabled: Bool?
}

struct UserPreferencesUpdateRequest: Codable, Sendable {
    var defaultCurrency: String?
    var notificationsEnabled: Bool?
    var emailNotifications: Bool?
    var dcaNotifications: Bool?
    var weeklySummary: Bool?
    var theme: String?
    var biometricEnabled: Bool?
}

struct GoalCreateRequest: Codable, Sendable {
    let name: String
    let targetAmount: Decimal
    let targetDate: Date?
    let linkedPortfolioId: String?
    let notes: String?
}

struct GoalUpdateRequest: Codable, Sendable {
    var name: String?
    var targetAmount: Decimal?
    var targetDate: Date?
    var notes: String?
    var isArchived: Bool?
}

struct DCAScheduleCreateRequest: Codable, Sendable {
    let stockSymbol: String
    let amount: Decimal
    let frequency: String
    let startDate: Date
    let endDate: Date?
    let portfolioId: String
}

struct DCAScheduleUpdateRequest: Codable, Sendable {
    var amount: Decimal?
    var frequency: String?
    var endDate: Date?
    var isActive: Bool?
}

struct FamilyAccountCreateRequest: Codable, Sendable {
    let name: String
    let relationship: String
    let email: String?
}

struct LedgerEntryCreateRequest: Codable, Sendable {
    let type: String
    let stockSymbol: String?
    let quantity: Decimal?
    let pricePerShare: Decimal?
    let totalAmount: Decimal
    let date: Date
    let notes: String?
}

// MARK: - AI Request DTOs

struct AIChatRequest: Codable, Sendable {
    let message: String
    let conversationHistory: [AIChatMessageDTO]?
    let includePortfolioContext: Bool

    init(
        message: String,
        conversationHistory: [AIChatMessageDTO]? = nil,
        includePortfolioContext: Bool = true
    ) {
        self.message = message
        self.conversationHistory = conversationHistory
        self.includePortfolioContext = includePortfolioContext
    }
}

struct AIChatMessageDTO: Codable, Sendable {
    let role: String
    let content: String
}

struct AIChatResponse: Codable, Sendable {
    let message: String
    let suggestedActions: [String]?
}

struct AllocationRequest: Codable, Sendable {
    let investmentAmount: Double
    let riskTolerance: String
    let timeHorizon: String

    init(
        investmentAmount: Decimal,
        riskTolerance: RiskTolerance,
        timeHorizon: TimeHorizon
    ) {
        self.investmentAmount = NSDecimalNumber(decimal: investmentAmount).doubleValue
        self.riskTolerance = riskTolerance.rawValue
        self.timeHorizon = timeHorizon.rawValue
    }
}

// MARK: - Buy Order Request

struct BuyOrderRequest: Codable, Sendable {
    let symbol: String
    let side: String
    let type: String
    let timeInForce: String
    let notional: Decimal
}
