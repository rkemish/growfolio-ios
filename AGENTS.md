# Repository Guidelines

## Project Structure & Module Organization

- `Growfolio/` contains the app source, organized by Clean Architecture: `App/`, `Core/`, `Domain/`, `Data/`, `Mock/`, and `Presentation/` feature folders.
- `GrowfolioTests/` mirrors the main target structure for unit tests (Models, ViewModels, Repositories, Core).
- `Growfolio.xcodeproj/` is the Xcode project; `project.yml` is the XcodeGen source.
- `Growfolio/Resources/` holds assets and localization (`Assets.xcassets`, `Localizable.strings`).

## Build, Test, and Development Commands

- `swift build` builds the Swift Package target.
- `swift test` runs all unit tests.
- `swift test --filter DashboardViewModelTests` runs a single test class.
- `xcodebuild -project Growfolio.xcodeproj -scheme Growfolio -configuration Debug build` builds the iOS app.
- `xcodebuild -project Growfolio.xcodeproj -scheme Growfolio test -destination 'platform=iOS Simulator,name=iPhone 15'` runs iOS simulator tests.
- `xcodegen generate` regenerates the Xcode project from `project.yml` (requires XcodeGen).

## Coding Style & Naming Conventions

- Swift 5.9, iOS 17+, SwiftUI with `@Observable` and `@MainActor` for UI updates.
- Naming follows Swift conventions: PascalCase types, camelCase properties and methods.
- Use repository protocols from `Growfolio/Domain/Repositories/Protocols/` and inject via `RepositoryContainer`.
- JSON decoding uses `.convertFromSnakeCase`; encoding uses `.convertToSnakeCase`.

## Testing Guidelines

- XCTest is used throughout. Tests live in `GrowfolioTests/` and mirror the app structure.
- Test file naming follows `*Tests.swift` (for example, `DashboardViewModelTests.swift`).
- Prefer `TestFixtures` in `GrowfolioTests/Mocks/Helpers/TestFixtures.swift` for consistent model data.

## Commit & Pull Request Guidelines

- Git history is minimal (single initial commit), so no established commit message convention yet. Use clear, imperative messages (for example, "Add funding transfer history view").
- PRs should include a short summary, testing notes, and screenshots for UI changes.

## Mock Mode & Local Configuration

- Mock mode is available via `MockConfiguration.shared.isEnabled` for development without the backend.
- `MockDataStore` and `MockDataGenerator` power realistic previews and tests.
