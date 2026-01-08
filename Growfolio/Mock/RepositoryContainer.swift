//
//  RepositoryContainer.swift
//  Growfolio
//
//  Central container providing repository instances based on mock configuration.
//

import Foundation

/// Central DI container that provides repository instances based on current configuration.
/// Uses mock repositories when mock mode is enabled, otherwise returns real implementations.
/// This allows seamless switching between real API and mock data for:
/// - SwiftUI previews (instant data, no network)
/// - UI testing (reproducible, controlled state)
/// - Development without backend (work offline)
enum RepositoryContainer {

    // MARK: - User Repository

    /// Provides the appropriate UserRepository implementation
    /// Returns MockUserRepository if mock mode is enabled, otherwise real UserRepository
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

    // MARK: - Basket Repository

    /// Provides the appropriate BasketRepository implementation
    static var basketRepository: BasketRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockBasketRepository()
        }
        return BasketRepository()
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

    // MARK: - Order Repository

    /// Provides the appropriate OrderRepository implementation
    static var orderRepository: OrderRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockOrderRepository()
        }
        return OrderRepository()
    }

    // MARK: - Position Repository

    /// Provides the appropriate PositionRepository implementation
    static var positionRepository: PositionRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockPositionRepository()
        }
        return PositionRepository()
    }

    // MARK: - Bank Repository

    /// Provides the appropriate BankRepository implementation
    static var bankRepository: BankRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockBankRepository()
        }
        return BankRepository()
    }

    // MARK: - Funding Wallet Repository

    /// Provides the appropriate FundingWalletRepository implementation
    static var fundingWalletRepository: FundingWalletRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockFundingWalletRepository()
        }
        return FundingWalletRepository()
    }

    // MARK: - Document Repository

    /// Provides the appropriate DocumentRepository implementation
    static var documentRepository: DocumentRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockDocumentRepository()
        }
        return DocumentRepository()
    }

    // MARK: - Corporate Action Repository

    /// Provides the appropriate CorporateActionRepository implementation
    static var corporateActionRepository: CorporateActionRepositoryProtocol {
        if MockConfiguration.shared.isEnabled {
            return MockCorporateActionRepository()
        }
        return CorporateActionRepository()
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

    /// Creates a mock basket repository for SwiftUI previews
    static var previewBasketRepository: BasketRepositoryProtocol {
        MockBasketRepository()
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

    /// Creates a mock order repository for SwiftUI previews
    static var previewOrderRepository: OrderRepositoryProtocol {
        MockOrderRepository()
    }

    /// Creates a mock position repository for SwiftUI previews
    static var previewPositionRepository: PositionRepositoryProtocol {
        MockPositionRepository()
    }

    /// Creates a mock bank repository for SwiftUI previews
    static var previewBankRepository: BankRepositoryProtocol {
        MockBankRepository()
    }

    /// Creates a mock funding wallet repository for SwiftUI previews
    static var previewFundingWalletRepository: FundingWalletRepositoryProtocol {
        MockFundingWalletRepository()
    }

    /// Creates a mock document repository for SwiftUI previews
    static var previewDocumentRepository: DocumentRepositoryProtocol {
        MockDocumentRepository()
    }

    /// Creates a mock corporate action repository for SwiftUI previews
    static var previewCorporateActionRepository: CorporateActionRepositoryProtocol {
        MockCorporateActionRepository()
    }

    /// Initialize mock data for previews
    static func initializePreviewData() async {
        await MockDataStore.shared.initialize(for: .activeInvestor)
    }
}
