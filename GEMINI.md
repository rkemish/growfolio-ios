# Growfolio iOS Project Context

## Project Overview

Growfolio is a native iOS 17+ application built with SwiftUI, designed for portfolio tracking, dollar-cost averaging (DCA), and AI-driven investment insights. It connects to the Growfolio API backend and features real-time updates via WebSockets.

**Key Technologies:**
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **State Management:** `@Observable` (Observation framework)
- **Concurrency:** Swift Concurrency (`async`/`await`, `@MainActor`, `Sendable`)
- **Architecture:** Clean Architecture + MVVM
- **Build System:** Swift Package Manager & Xcode (via `xcodegen`)

## Architecture

The project adheres strictly to **Clean Architecture** principles, separating concerns into distinct layers:

1.  **App:** Entry point, dependency injection setup, and global configuration (`App/Configuration`).
2.  **Presentation (MVVM):**
    *   **Views:** SwiftUI views that react to state changes.
    *   **ViewModels:** `@Observable` classes managing state and business logic, interacting with Use Cases or Repositories.
3.  **Domain:**
    *   **Models:** Pure Swift structs (Value Types, `Codable`, `Sendable`).
    *   **Repositories (Protocols):** Interfaces defining data access contracts.
    *   **UseCases:** (Optional) specific business logic encapsulations.
4.  **Data:**
    *   **Repositories (Implementations):** Implement domain protocols, coordinating between API, Storage, and Mappers.
    *   **DTOs & Mappers:** Transfer objects and translation logic.
5.  **Core:** Shared infrastructure (Networking, Authentication, Extensions, Storage).
6.  **Mock:** Comprehensive mocking system for development and testing.

### Dependency Injection
The project uses a dedicated container pattern:
- **`RepositoryContainer`:** Central dependency injection container.
- **Usage:** ViewModels receive dependencies via `init`, defaulting to `RepositoryContainer.shared` (or similar static accessors).
- **Switching:** The container automatically provides Mock implementations if `MockConfiguration.shared.isEnabled` is true.

## Project Structure

```
Growfolio/
├── App/                  # App Delegate, Entry Point, Config
├── Core/                 # Infrastructure (Net, Auth, Storage)
│   ├── Authentication/   # Auth Service, TokenManager
│   ├── Network/          # APIClient, WebSocketService
│   └── Extensions/       # Swift Extensions
├── Data/                 # Repository Implementations
├── Domain/               # Models & Repository Protocols
├── Mock/                 # Mock Data & Repositories
└── Presentation/         # UI Layer (Features)
    ├── Dashboard/
    ├── Portfolio/
    └── ...
```

## Setup & Development

### Prerequisites
- Xcode 16+
- iOS 17.0+ Simulator/Device
- `xcodegen` (optional, for regenerating `.xcodeproj`)

### Build Commands

**Using Swift Package Manager (Fastest for Logic/Tests):**
```bash
# Build the package
swift build

# Run all tests
swift test

# Run specific tests
swift test --filter DashboardViewModelTests
```

**Using Xcode / xcodebuild:**
```bash
# Generate Xcode project (if project.yml changed)
xcodegen generate

# Build for Simulator
xcodebuild -project Growfolio.xcodeproj -scheme Growfolio -configuration Debug build

# Run Tests
xcodebuild -project Growfolio.xcodeproj -scheme Growfolio test -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Key Concepts

### 1. Networking & WebSockets
- **APIClient:** Actor-based HTTP client handling token refresh and request interception.
- **WebSocketService:** Manages real-time connections (`wss://api.growfolio.app/api/v1/ws`).
    - Handles heartbeats, reconnection, and event subscriptions (`quotes`, `transfers`, etc.).
    - See `IOS_WEBSOCKET_MANUAL.md` for protocol details.

### 2. Authentication
- **Sign in with Apple:** Primary auth method.
- **Token Exchange:** Swaps Apple Identity Token for Growfolio JWTs.
- **Storage:** Secure storage via Keychain (production) or potentially simulated in mocks.

### 3. Mock Mode
- **Toggle:** Controlled by `MockConfiguration.shared.isEnabled` (default in Debug).
- **Arguments:** Pass `--mock-mode` or `--no-mock-data` as launch arguments to override.
- **Implementation:** `MockDataStore` holds in-memory state for mock repositories to simulate a real backend.

### 4. Environments
Defined in `App/Configuration/Environment.swift`:
- **Development:** Localhost / Mock Data.
- **Staging:** `staging-api.growfolio.app`.
- **Production:** `api.growfolio.app`.

## Coding Conventions

- **Style:** Follow official Swift guidelines. Use `PascalCase` for types, `camelCase` for properties/functions.
- **JSON:** Use `SnakeCase` conversion strategies (`.convertFromSnakeCase`, `.convertToSnakeCase`).
- **Concurrency:** Prefer `async/await`. Always mark UI-updating functions/classes with `@MainActor`.
- **Testing:**
    - Mirror the app structure in `GrowfolioTests`.
    - Use `MockRepository` implementations for ViewModel tests.
    - Validate logic, not just coverage.
