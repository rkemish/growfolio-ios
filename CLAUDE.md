# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Growfolio iOS is a Dollar Cost Averaging (DCA) investment app for international users investing in US equities. This is the iOS client application built with SwiftUI that connects to the Growfolio API backend.

## Common Commands

### Build and Run

```bash
# Build the project using Swift Package Manager
swift build

# Run tests
swift test

# Build with Xcode (if .xcodeproj exists)
xcodebuild -project Growfolio.xcodeproj -scheme Growfolio -configuration Debug build

# Run tests with Xcode
xcodebuild -project Growfolio.xcodeproj -scheme Growfolio -configuration Debug test -destination 'platform=iOS Simulator,name=iPhone 15'

# Open in Xcode
open Growfolio.xcodeproj

# Generate Xcode project from project.yml (requires xcodegen)
xcodegen generate
```

### Code Quality

```bash
# Run SwiftLint (if configured)
swiftlint lint

# Auto-fix SwiftLint issues
swiftlint lint --fix
```

## Architecture

The app follows Clean Architecture with MVVM presentation pattern:

### Directory Structure

- **App/**: Entry point (`AppDelegate.swift`) and app configuration
  - `Configuration/`: Environment constants and settings

- **Core/**: Shared infrastructure and utilities
  - `Network/`: `APIClient` (async/await HTTP client), `AuthInterceptor` (token refresh), `NetworkError`
  - `Authentication/`: Auth0 integration, `TokenManager`, `BiometricAuth`
  - `Extensions/`: Swift type extensions

- **Domain/**: Business layer (pure Swift, no external dependencies)
  - `Models/`: Domain entities (`User`, `Portfolio`, `Holding`, `DCASchedule`, `LedgerEntry`)
  - `Repositories/Protocols/`: Repository interfaces
  - `UseCases/`: Business logic use cases

- **Data/**: Data layer implementation
  - `Repositories/`: Concrete repository implementations
  - `DTOs/`: Data transfer objects for API communication
  - `Mappers/`: DTO to Domain model mappers

- **Presentation/**: UI layer (SwiftUI + ViewModels)
  - `Dashboard/`: Main dashboard view
  - `Goals/`: Investment goals management
  - `DCA/`: Dollar cost averaging schedule management
  - `Portfolio/`: Holdings and positions view
  - `Family/`: Family account management
  - `StockDetails/`: Individual stock information
  - `AIInsights/`: AI-powered investment insights
  - `Settings/`: App settings and preferences

- **Resources/**: Assets, localization strings, and other resources

### Key Patterns

1. **Repository Pattern**: ViewModels depend on repository protocols, enabling easy testing with mocks

2. **Dependency Injection**: Repositories are injected into ViewModels, with mock implementations in tests

3. **Async/Await**: All network operations use Swift concurrency

4. **Observable Macro**: ViewModels use `@Observable` for reactive UI updates

## Code Style

- **Swift Version**: Swift 6
- **Minimum iOS**: iOS 17+
- **UI Framework**: SwiftUI with `@Observable` macro
- **JSON Decoding**: Uses `.convertFromSnakeCase` key decoding strategy
- **Naming**: Swift standard conventions (camelCase for properties/methods, PascalCase for types)
- **Error Handling**: Use `Result` types and structured error enums

## API Connection

The app connects to the Growfolio API backend:
- Authentication via Auth0 JWT tokens
- Token refresh handled automatically by `AuthInterceptor`
- API base URL configured in `Constants.swift`

## Testing

Tests are located in `GrowfolioTests/`:
- Unit tests for ViewModels with mock repositories
- Mock implementations in `Mocks/` directory
- Run with `swift test` or Xcode Test Navigator
