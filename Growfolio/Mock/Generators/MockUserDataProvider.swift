//
//  MockUserDataProvider.swift
//  Growfolio
//
//  Provides realistic user-related mock data.
//

import Foundation

/// Provides realistic user-related mock data
enum MockUserDataProvider {

    // MARK: - Names

    static let firstNames = [
        "Alex", "Sam", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Quinn",
        "James", "Emma", "Michael", "Sarah", "David", "Emily", "Daniel", "Jessica",
        "Christopher", "Ashley", "Matthew", "Amanda", "Andrew", "Stephanie"
    ]

    static let lastNames = [
        "Thompson", "Anderson", "Williams", "Johnson", "Brown", "Davis", "Miller",
        "Wilson", "Moore", "Taylor", "Jackson", "White", "Harris", "Martin", "Garcia"
    ]

    /// Generate a random full name
    static func fullName() -> String {
        "\(firstNames.randomElement()!) \(lastNames.randomElement()!)"
    }

    /// Generate a random first name
    static func firstName() -> String {
        firstNames.randomElement()!
    }

    /// Generate a random last name
    static func lastName() -> String {
        lastNames.randomElement()!
    }

    // MARK: - Email

    static let emailDomains = ["gmail.com", "outlook.com", "icloud.com", "yahoo.com"]

    /// Generate an email address
    static func email(for name: String? = nil) -> String {
        let baseName = name?.lowercased().replacingOccurrences(of: " ", with: ".") ?? "\(firstName().lowercased()).\(lastName().lowercased())"
        return "\(baseName)@\(emailDomains.randomElement()!)"
    }

    // MARK: - Portfolio Names

    static let portfolioNames = [
        "Main Portfolio", "Growth Portfolio", "Retirement", "Roth IRA",
        "Trading Account", "Long-term Investments", "Tech Stocks",
        "Dividend Portfolio", "Education Fund", "Emergency Fund"
    ]

    /// Generate a portfolio name
    static func portfolioName() -> String {
        portfolioNames.randomElement()!
    }

    /// Generate a unique portfolio name
    static func uniquePortfolioName(existing: [String]) -> String {
        let available = portfolioNames.filter { !existing.contains($0) }
        if available.isEmpty {
            return "Portfolio \(existing.count + 1)"
        }
        return available.randomElement()!
    }

    // MARK: - Goal Names

    /// Generate a goal name for a category
    static func goalName(for category: GoalCategory) -> String {
        switch category {
        case .retirement:
            return ["Retirement Fund", "Golden Years", "Freedom Fund", "Nest Egg"].randomElement()!
        case .education:
            return ["College Fund", "Education Savings", "University Fund", "Learning Fund"].randomElement()!
        case .house:
            return ["House Deposit", "Dream Home", "Down Payment", "First Home"].randomElement()!
        case .car:
            return ["New Car Fund", "Vehicle Upgrade", "Car Savings", "Auto Fund"].randomElement()!
        case .vacation:
            return ["Dream Vacation", "Travel Fund", "Holiday Savings", "Adventure Fund"].randomElement()!
        case .emergency:
            return ["Emergency Fund", "Rainy Day Fund", "Safety Net", "Emergency Savings"].randomElement()!
        case .wedding:
            return ["Wedding Fund", "Big Day Savings", "Marriage Fund", "Celebration Fund"].randomElement()!
        case .investment:
            return ["Investment Goal", "Wealth Building", "Growth Target", "Capital Goal"].randomElement()!
        case .other:
            return ["Savings Goal", "Financial Target", "Money Goal", "Custom Goal"].randomElement()!
        }
    }

    // MARK: - DCA Schedule Names

    /// Generate a DCA schedule name
    static func dcaScheduleName(for symbol: String, stockName: String?) -> String {
        if let name = stockName {
            return "\(name) DCA"
        }
        return "\(symbol) Auto-Invest"
    }

    // MARK: - Family Names

    static let familyNames = [
        "The Thompsons", "Anderson Family", "Williams Household",
        "Johnson Family", "The Smiths", "Our Family"
    ]

    /// Generate a family name
    static func familyName(ownerLastName: String? = nil) -> String {
        if let lastName = ownerLastName {
            return "The \(lastName)s"
        }
        return familyNames.randomElement()!
    }

    // MARK: - AI Responses

    /// Pre-defined AI chat responses by topic
    static let aiResponses: [String: [String]] = [
        "portfolio": [
            "Your portfolio is well-diversified across technology and consumer sectors. Consider adding some international exposure for better diversification.",
            "Based on your current holdings, you have a growth-oriented portfolio. The tech allocation looks solid, but you might want to consider adding some dividend-paying stocks for income.",
            "Your portfolio shows a healthy mix of growth and value stocks. The allocation to ETFs provides good diversification."
        ],
        "dca": [
            "Dollar-cost averaging is an excellent strategy for long-term investing. Your current DCA schedule of investing monthly helps smooth out market volatility.",
            "Your DCA approach is working well. Consider increasing your contribution amount if your budget allows, as consistent investing tends to yield good results over time.",
            "I see you're using DCA for several positions. This is a great way to build wealth over time without worrying about market timing."
        ],
        "goals": [
            "You're making great progress on your financial goals! The College Fund is on track to meet its target.",
            "I notice some of your goals could benefit from increased contributions. Would you like me to suggest adjustments?",
            "Your goal progress looks healthy. Keep up the consistent investing!"
        ],
        "market": [
            "Markets have been volatile recently, but remember that long-term investors historically benefit from staying the course.",
            "The market is showing mixed signals. This is a good time to focus on quality companies with strong fundamentals.",
            "Market conditions favor a balanced approach. Consider maintaining your current allocation strategy."
        ],
        "default": [
            "I can help you with portfolio analysis, investment strategies, and understanding your financial goals. What would you like to know?",
            "Happy to assist with your investment questions! I can provide insights on your holdings, DCA schedules, and goal progress.",
            "I'm here to help you make informed investment decisions. Feel free to ask about your portfolio, market trends, or investment strategies."
        ]
    ]

    /// Get AI response for a message
    static func aiResponse(for message: String) -> String {
        let lowercased = message.lowercased()

        if lowercased.contains("portfolio") || lowercased.contains("holding") || lowercased.contains("stock") {
            return aiResponses["portfolio"]!.randomElement()!
        } else if lowercased.contains("dca") || lowercased.contains("auto") || lowercased.contains("schedule") {
            return aiResponses["dca"]!.randomElement()!
        } else if lowercased.contains("goal") || lowercased.contains("target") || lowercased.contains("saving") {
            return aiResponses["goals"]!.randomElement()!
        } else if lowercased.contains("market") || lowercased.contains("trend") || lowercased.contains("economy") {
            return aiResponses["market"]!.randomElement()!
        } else {
            return aiResponses["default"]!.randomElement()!
        }
    }

    /// AI insights templates
    static let aiInsights = [
        "Your portfolio is up 12.5% this year, outperforming the S&P 500 by 2.3%.",
        "You have strong exposure to technology stocks (45% of portfolio). Consider diversifying into other sectors.",
        "Your DCA strategy has helped you accumulate shares at an average cost below current market price.",
        "The College Fund goal is 25% complete and on track to meet your target date.",
        "Consider rebalancing your portfolio - technology allocation has drifted 5% above target."
    ]

    /// AI tips
    static let investingTips = [
        (title: "Dollar-Cost Averaging", content: "Regular investing helps smooth out market volatility and removes the stress of timing the market."),
        (title: "Diversification", content: "Spreading investments across different sectors and asset classes helps reduce risk."),
        (title: "Long-term Thinking", content: "Historically, patient investors who stay invested through market cycles tend to see better returns."),
        (title: "Keep Costs Low", content: "Low-cost index funds and ETFs can help maximize your returns over time."),
        (title: "Automate Your Investing", content: "Setting up automatic investments ensures you stay consistent with your financial goals.")
    ]
}
