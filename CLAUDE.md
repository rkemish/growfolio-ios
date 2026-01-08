# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Growfolio iOS is a Dollar Cost Averaging (DCA) investment app for international users investing in US equities. This is the iOS client application built with SwiftUI that connects to the Growfolio API backend.

## Common Commands

```bash
# Build
swift build

# Run all tests
swift test

# Run a single test file
swift test --filter DashboardViewModelTests

# Run a specific test method
swift test --filter DashboardViewModelTests.test_loadDashboardData_loadsPortfolioSummary

# Build with Xcode
xcodebuild -project Growfolio.xcodeproj -scheme Growfolio -configuration Debug build

# Run tests with Xcode (for iOS-specific tests)
xcodebuild -project Growfolio.xcodeproj -scheme Growfolio test -destination 'platform=iOS Simulator,name=iPhone 15'

# Regenerate Xcode project from project.yml (requires xcodegen)
xcodegen generate

# Open in Xcode
open Growfolio.xcodeproj
```

## Architecture

Clean Architecture with MVVM. The codebase is organized into layers:

```
Growfolio/
├── App/                    # Entry point and configuration
│   └── Configuration/      # Environment, Constants
├── Core/                   # Shared infrastructure
│   ├── Network/            # APIClient (actor), AuthInterceptor, Endpoints
│   ├── Authentication/     # Apple Sign In integration, TokenManager
│   └── Extensions/         # Swift type extensions
├── Domain/                 # Pure Swift business layer
│   ├── Models/             # Domain entities (Codable, Sendable)
│   └── Repositories/Protocols/  # Repository interfaces
├── Data/                   # API layer
│   └── Repositories/       # Protocol implementations using APIClient
├── Mock/                   # Mock mode for development/previews
│   ├── Repositories/       # Mock repository implementations
│   ├── Generators/         # MockDataGenerator, MockDataStore
│   └── RepositoryContainer.swift  # DI container switching real/mock
└── Presentation/           # SwiftUI views and ViewModels
    └── {Feature}/
        ├── Views/          # SwiftUI views
        └── ViewModels/     # @Observable ViewModels
```

### Key Patterns

**RepositoryContainer**: Central DI container that provides repository instances. Switches between real and mock implementations based on `MockConfiguration.shared.isEnabled`:
```swift
// In ViewModel init (default parameters enable DI)
init(portfolioRepository: PortfolioRepositoryProtocol = RepositoryContainer.portfolioRepository) { ... }
```

**ViewModel Pattern**: All ViewModels use `@Observable` macro with `@MainActor` for async methods:
```swift
@Observable
final class DashboardViewModel: @unchecked Sendable {
    @MainActor
    func loadData() async { ... }
}
```

**APIClient**: An `actor` that handles all network requests with automatic token refresh and retry logic. Uses `Endpoint` structs for request configuration.

**TestFixtures**: Factory enum in `GrowfolioTests/Mocks/Helpers/TestFixtures.swift` provides consistent test data for all domain models.

## Code Style

- **iOS 17+**, Swift 5.9 (Package.swift), Xcode 16 (project.yml)
- **SwiftUI** with `@Observable` macro (not ObservableObject)
- **JSON**: `.convertFromSnakeCase` for decoding, `.convertToSnakeCase` for encoding
- **Concurrency**: async/await with `@MainActor` for UI updates, `Sendable` conformance on models
- **Naming**: Swift conventions (camelCase properties, PascalCase types)

## Testing

Tests in `GrowfolioTests/` mirror the main target structure:

- `ViewModels/`: ViewModel tests with injected mock repositories
- `Models/`: Domain model tests (encoding/decoding, computed properties)
- `Repositories/`: Repository tests with MockAPIClient
- `Mocks/`: Mock implementations and TestFixtures

Test pattern for ViewModels:
```swift
@MainActor
final class DashboardViewModelTests: XCTestCase {
    var mockPortfolioRepository: MockPortfolioRepository!
    var sut: DashboardViewModel!

    override func setUp() {
        mockPortfolioRepository = MockPortfolioRepository()
        sut = DashboardViewModel(portfolioRepository: mockPortfolioRepository)
    }
}
```

## Mock Mode

The app supports a mock mode for development without backend:
- Toggle via `MockConfiguration.shared.isEnabled`
- `MockDataStore` manages shared state across mock repositories
- `MockDataGenerator` creates realistic test data scenarios
- SwiftUI previews use `RepositoryContainer.preview*` properties

## WebSocket (Real-Time Updates)

The app uses WebSocket for real-time data including quotes, order updates, and transfer notifications.

Key files:
- `Growfolio/Core/Network/WebSocketService.swift` - Main service managing connection lifecycle
- `Growfolio/Core/Network/WebSocketModels.swift` - Message types and event definitions
- `Growfolio/Core/Network/WebSocketClient.swift` - Low-level URLSessionWebSocketTask wrapper

Available channels: `quotes`, `orders`, `positions`, `account`, `dca`, `transfers`, `fx`, `baskets`

See `IOS_WEBSOCKET_MANUAL.md` for the complete WebSocket protocol specification.

## Launch Arguments

The app supports launch arguments for testing and development:

| Argument | Description |
|----------|-------------|
| `--uitesting` | Enable UI testing mode (faster animations) |
| `--mock-mode` | Use mock data instead of real API |
| `--skip-to-main` | Skip directly to main app (tab bar) |
| `--skip-onboarding` | Skip to authentication screen |
| `--reset-onboarding` | Reset onboarding state |

Example usage in tests:
```swift
app.launchArguments.append("--mock-mode")
app.launchArguments.append("--skip-to-main")
```

## Environment Configuration

Three environments configured in `Growfolio/App/Configuration/Environment.swift`:
- **development**: localhost, mock data enabled by default, verbose logging
- **staging**: staging-api.growfolio.app, SSL pinning enabled
- **production**: api.growfolio.app, SSL pinning, analytics, crash reporting

Feature flags are managed in `FeatureFlags` struct in the same file.
