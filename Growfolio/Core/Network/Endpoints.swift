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

    struct ExchangeTokenV2: Endpoint {
        let path = "/\(Constants.API.version)/auth/token/v2"
        let method: HTTPMethod = .post
        let body: Data?
        let requiresAuthentication = false

        init(request: UnifiedTokenRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct Logout: Endpoint {
        let path = "/\(Constants.API.version)/auth/logout"
        let method: HTTPMethod = .post

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

    struct GetBrokerageAccounts: Endpoint {
        let path = "/\(Constants.API.version)/users/me/accounts"
        let method: HTTPMethod = .get
    }

    struct GetAccountConfigurations: Endpoint {
        let path = "/\(Constants.API.version)/users/account/configurations"
        let method: HTTPMethod = .get
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

    struct PauseBasket: Endpoint {
        let path: String
        let method: HTTPMethod = .post

        init(basketId: String) {
            self.path = "/\(Constants.API.version)/baskets/\(basketId)/pause"
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct ResumeBasket: Endpoint {
        let path: String
        let method: HTTPMethod = .post

        init(basketId: String) {
            self.path = "/\(Constants.API.version)/baskets/\(basketId)/resume"
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
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

    struct GetDCAHistory: Endpoint {
        let path: String
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(scheduleId: String, page: Int = 1, limit: Int = Constants.API.defaultPageSize) {
            self.path = "/\(Constants.API.version)/dca/schedules/\(scheduleId)/history"
            self.queryItems = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        }
    }

    struct PauseDCASchedule: Endpoint {
        let path: String
        let method: HTTPMethod = .post

        init(scheduleId: String) {
            self.path = "/\(Constants.API.version)/dca/schedules/\(scheduleId)/pause"
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct ResumeDCASchedule: Endpoint {
        let path: String
        let method: HTTPMethod = .post

        init(scheduleId: String) {
            self.path = "/\(Constants.API.version)/dca/schedules/\(scheduleId)/resume"
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    // MARK: - Order Endpoints

    struct GetOrders: Endpoint {
        let path = "/\(Constants.API.version)/orders"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(status: OrderStatus? = nil, limit: Int? = nil, after: Date? = nil, until: Date? = nil) {
            var items: [URLQueryItem] = []
            if let status = status {
                items.append(URLQueryItem(name: "status", value: status.rawValue))
            }
            if let limit = limit {
                items.append(URLQueryItem(name: "limit", value: "\(limit)"))
            }
            if let after = after {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "after", value: formatter.string(from: after)))
            }
            if let until = until {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "until", value: formatter.string(from: until)))
            }
            self.queryItems = items.isEmpty ? nil : items
        }
    }

    struct GetOrder: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(orderId: String) {
            self.path = "/\(Constants.API.version)/orders/\(orderId)"
        }
    }

    struct CancelOrder: Endpoint {
        let path: String
        let method: HTTPMethod = .delete

        init(orderId: String) {
            self.path = "/\(Constants.API.version)/orders/\(orderId)"
        }
    }

    // MARK: - Position Endpoints

    struct GetPositions: Endpoint {
        let path = "/\(Constants.API.version)/positions"
        let method: HTTPMethod = .get
    }

    struct GetPosition: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(symbol: String) {
            self.path = "/\(Constants.API.version)/positions/\(symbol)"
        }
    }

    struct GetPositionHistory: Endpoint {
        let path = "/\(Constants.API.version)/positions/history"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(page: Int = 1, limit: Int = Constants.API.defaultPageSize, startDate: Date? = nil, endDate: Date? = nil) {
            var items = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            if let startDate = startDate {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "start_date", value: formatter.string(from: startDate)))
            }
            if let endDate = endDate {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "end_date", value: formatter.string(from: endDate)))
            }
            self.queryItems = items
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

    struct GetPopularStocks: Endpoint {
        let path = "/\(Constants.API.version)/stocks/popular"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(limit: Int? = nil, category: String? = nil) {
            var items: [URLQueryItem] = []
            if let limit = limit {
                items.append(URLQueryItem(name: "limit", value: "\(limit)"))
            }
            if let category = category {
                items.append(URLQueryItem(name: "category", value: category))
            }
            self.queryItems = items.isEmpty ? nil : items
        }
    }

    struct GetMarketCalendar: Endpoint {
        let path = "/\(Constants.API.version)/stocks/market/calendar"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(start: Date? = nil, end: Date? = nil) {
            var items: [URLQueryItem] = []
            if let start = start {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "start", value: formatter.string(from: start)))
            }
            if let end = end {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "end", value: formatter.string(from: end)))
            }
            self.queryItems = items.isEmpty ? nil : items
        }
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

    struct GetDividends: Endpoint {
        let path = "/\(Constants.API.version)/ledger/dividends"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(startDate: Date? = nil, endDate: Date? = nil, symbol: String? = nil) {
            var items: [URLQueryItem] = []
            if let startDate = startDate {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "start_date", value: formatter.string(from: startDate)))
            }
            if let endDate = endDate {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "end_date", value: formatter.string(from: endDate)))
            }
            if let symbol = symbol {
                items.append(URLQueryItem(name: "symbol", value: symbol))
            }
            self.queryItems = items.isEmpty ? nil : items
        }
    }

    struct GetFXHistory: Endpoint {
        let path = "/\(Constants.API.version)/ledger/fx-history"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(startDate: Date? = nil, endDate: Date? = nil) {
            var items: [URLQueryItem] = []
            if let startDate = startDate {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "start_date", value: formatter.string(from: startDate)))
            }
            if let endDate = endDate {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "end_date", value: formatter.string(from: endDate)))
            }
            self.queryItems = items.isEmpty ? nil : items
        }
    }

    struct GetLedgerSummary: Endpoint {
        let path = "/\(Constants.API.version)/ledger/summary"
        let method: HTTPMethod = .get
    }

    struct GetLedgerTransactions: Endpoint {
        let path = "/\(Constants.API.version)/ledger/transactions"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(page: Int = 1, limit: Int = Constants.API.defaultPageSize, type: String? = nil, startDate: Date? = nil, endDate: Date? = nil) {
            var items = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            if let type = type {
                items.append(URLQueryItem(name: "type", value: type))
            }
            if let startDate = startDate {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "start_date", value: formatter.string(from: startDate)))
            }
            if let endDate = endDate {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "end_date", value: formatter.string(from: endDate)))
            }
            self.queryItems = items
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

    // MARK: - Watchlist Endpoints

    struct GetWatchlists: Endpoint {
        let path = "/\(Constants.API.version)/watchlists"
        let method: HTTPMethod = .get
    }

    struct GetWatchlist: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(watchlistId: String) {
            self.path = "/\(Constants.API.version)/watchlists/\(watchlistId)"
        }
    }

    struct CreateWatchlist: Endpoint {
        let path = "/\(Constants.API.version)/watchlists"
        let method: HTTPMethod = .post
        let body: Data?

        init(watchlist: WatchlistCreate) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(watchlist)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct UpdateWatchlist: Endpoint {
        let path: String
        let method: HTTPMethod = .patch
        let body: Data?

        init(watchlistId: String, watchlist: WatchlistUpdate) throws {
            self.path = "/\(Constants.API.version)/watchlists/\(watchlistId)"
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(watchlist)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct DeleteWatchlist: Endpoint {
        let path: String
        let method: HTTPMethod = .delete

        init(watchlistId: String) {
            self.path = "/\(Constants.API.version)/watchlists/\(watchlistId)"
        }
    }

    struct AddSymbolToWatchlist: Endpoint {
        let path: String
        let method: HTTPMethod = .post
        let body: Data?

        init(watchlistId: String, symbol: String) {
            self.path = "/\(Constants.API.version)/watchlists/\(watchlistId)/symbols"
            let payload = ["symbol": symbol]
            self.body = try? JSONEncoder().encode(payload)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct RemoveSymbolFromWatchlist: Endpoint {
        let path: String
        let method: HTTPMethod = .delete

        init(watchlistId: String, symbol: String) {
            self.path = "/\(Constants.API.version)/watchlists/\(watchlistId)/symbols/\(symbol)"
        }
    }

    // MARK: - Bank Account Endpoints

    struct GetBankAccounts: Endpoint {
        let path = "/\(Constants.API.version)/banks"
        let method: HTTPMethod = .get
    }

    struct GetBankAccount: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(relationshipId: String) {
            self.path = "/\(Constants.API.version)/banks/\(relationshipId)"
        }
    }

    struct LinkBankManual: Endpoint {
        let path = "/\(Constants.API.version)/banks/link-manual"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: BankLinkManualRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct LinkBankPlaid: Endpoint {
        let path = "/\(Constants.API.version)/banks/link-plaid"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: BankLinkPlaidRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct RemoveBankAccount: Endpoint {
        let path: String
        let method: HTTPMethod = .delete

        init(relationshipId: String) {
            self.path = "/\(Constants.API.version)/banks/\(relationshipId)"
        }
    }

    // MARK: - Funding Wallet Endpoints

    struct GetFundingWallet: Endpoint {
        let path = "/\(Constants.API.version)/funding-wallet"
        let method: HTTPMethod = .get
    }

    struct GetFundingDetails: Endpoint {
        let path = "/\(Constants.API.version)/funding-wallet/funding-details"
        let method: HTTPMethod = .get
    }

    struct GetRecipientBank: Endpoint {
        let path = "/\(Constants.API.version)/funding-wallet/recipient-bank"
        let method: HTTPMethod = .get
    }

    struct SyncDeposits: Endpoint {
        let path = "/\(Constants.API.version)/funding-wallet/sync-deposits"
        let method: HTTPMethod = .post

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    struct GetWalletTransfers: Endpoint {
        let path = "/\(Constants.API.version)/funding-wallet/transfers"
        let method: HTTPMethod = .get
    }

    struct InitiateWalletWithdraw: Endpoint {
        let path = "/\(Constants.API.version)/funding-wallet/withdraw"
        let method: HTTPMethod = .post
        let body: Data?

        init(request: WalletWithdrawRequest) throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            self.body = try encoder.encode(request)
        }

        var headers: [String: String]? {
            ["Content-Type": "application/json"]
        }
    }

    // MARK: - Document Endpoints

    struct GetDocuments: Endpoint {
        let path = "/\(Constants.API.version)/documents"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(type: DocumentType? = nil, startDate: Date? = nil, endDate: Date? = nil) {
            var items: [URLQueryItem] = []
            if let type = type {
                items.append(URLQueryItem(name: "type", value: type.rawValue))
            }
            if let startDate = startDate {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "start_date", value: formatter.string(from: startDate)))
            }
            if let endDate = endDate {
                let formatter = ISO8601DateFormatter()
                items.append(URLQueryItem(name: "end_date", value: formatter.string(from: endDate)))
            }
            self.queryItems = items.isEmpty ? nil : items
        }
    }

    struct DownloadDocument: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(documentId: String) {
            self.path = "/\(Constants.API.version)/documents/\(documentId)/download"
        }
    }

    struct GetW8BENForm: Endpoint {
        let path = "/\(Constants.API.version)/documents/w8ben"
        let method: HTTPMethod = .get
    }

    // MARK: - Corporate Action Endpoints

    struct GetCorporateActions: Endpoint {
        let path = "/\(Constants.API.version)/corporate-actions"
        let method: HTTPMethod = .get
        let queryItems: [URLQueryItem]?

        init(symbol: String? = nil, type: CorporateActionType? = nil, status: CorporateActionStatus? = nil) {
            var items: [URLQueryItem] = []
            if let symbol = symbol {
                items.append(URLQueryItem(name: "symbol", value: symbol))
            }
            if let type = type {
                items.append(URLQueryItem(name: "type", value: type.rawValue))
            }
            if let status = status {
                items.append(URLQueryItem(name: "status", value: status.rawValue))
            }
            self.queryItems = items.isEmpty ? nil : items
        }
    }

    struct GetCorporateAction: Endpoint {
        let path: String
        let method: HTTPMethod = .get

        init(announcementId: String) {
            self.path = "/\(Constants.API.version)/corporate-actions/\(announcementId)"
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

// MARK: - Watchlist Requests

struct WatchlistCreate: Codable, Sendable {
    let name: String
}

struct WatchlistUpdate: Codable, Sendable {
    let name: String?
}

// MARK: - Bank Account Requests

struct BankLinkManualRequest: Codable, Sendable {
    let accountNumber: String
    let routingNumber: String
    let accountType: String
    let bankName: String
}

struct BankLinkPlaidRequest: Codable, Sendable {
    let publicToken: String
    let accountId: String
}

// MARK: - Funding Wallet Requests

struct WalletWithdrawRequest: Codable, Sendable {
    let amount: Decimal
    let currency: String
}
