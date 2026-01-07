//
//  RepositoryContainer.swift
//  Growfolio
//
//  Central container providing repository instances based on mock configuration.
//

import Foundation

/// Provides repository instances based on current configuration.
/// Uses mock repositories when mock mode is enabled, otherwise returns real implementations.
enum RepositoryContainer {

    // MARK: - User Repository

    /// Provides the appropriate UserRepository implementation
    static var userRepository: UserRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockUserRepository()
        }
        return UserRepository()
    }

    // MARK: - Portfolio Repository

    /// Provides the appropriate PortfolioRepository implementation
    static var portfolioRepository: PortfolioRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockPortfolioRepository()
        }
        return PortfolioRepository()
    }

    // MARK: - Stocks Repository

    /// Provides the appropriate StocksRepository implementation
    static var stocksRepository: StocksRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockStocksRepository()
        }
        return StocksRepository()
    }

    // MARK: - DCA Repository

    /// Provides the appropriate DCARepository implementation
    static var dcaRepository: DCARepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockDCARepository()
        }
        return DCARepository()
    }

    // MARK: - Goal Repository

    /// Provides the appropriate GoalRepository implementation
    static var goalRepository: GoalRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockGoalRepository()
        }
        return GoalRepository()
    }

    // MARK: - Funding Repository

    /// Provides the appropriate FundingRepository implementation
    static var fundingRepository: FundingRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockFundingRepository()
        }
        return FundingRepository()
    }

    // MARK: - AI Repository

    /// Provides the appropriate AIRepository implementation
    static var aiRepository: AIRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockAIRepository()
        }
        return AIRepository()
    }

    // MARK: - Family Repository

    /// Provides the appropriate FamilyRepository implementation
    static var familyRepository: FamilyRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockFamilyRepository()
        }
        return FamilyRepository()
    }

    // MARK: - KYC Repository

    /// Provides the appropriate KYCRepository implementation
    static var kycRepository: KYCRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockKYCRepository()
        }
        return KYCRepository()
    }
}

// MARK: - SwiftUI Preview Support

extension RepositoryContainer {

    /// Creates a mock user repository for SwiftUI previews
    static var previewUserRepository: UserRepositoryProtocol {
        MockUserRepository()
    }

    /// Creates a mock portfolio repository for SwiftUI previews
    static var previewPortfolioRepository: PortfolioRepositoryProtocol {
        MockPortfolioRepository()
    }

    /// Creates a mock stocks repository for SwiftUI previews
    static var previewStocksRepository: StocksRepositoryProtocol {
        MockStocksRepository()
    }

    /// Creates a mock DCA repository for SwiftUI previews
    static var previewDCARepository: DCARepositoryProtocol {
        MockDCARepository()
    }

    /// Creates a mock goal repository for SwiftUI previews
    static var previewGoalRepository: GoalRepositoryProtocol {
        MockGoalRepository()
    }

    /// Creates a mock funding repository for SwiftUI previews
    static var previewFundingRepository: FundingRepositoryProtocol {
        MockFundingRepository()
    }

    /// Creates a mock AI repository for SwiftUI previews
    static var previewAIRepository: AIRepositoryProtocol {
        MockAIRepository()
    }

    /// Creates a mock family repository for SwiftUI previews
    static var previewFamilyRepository: FamilyRepositoryProtocol {
        MockFamilyRepository()
    }

    /// Creates a mock KYC repository for SwiftUI previews
    static var previewKYCRepository: KYCRepositoryProtocol {
        MockKYCRepository()
    }

    /// Initialize mock data for previews
    static func initializePreviewData() async {
        await MockDataStore.shared.initialize(for: .activeInvestor)
    }
}
