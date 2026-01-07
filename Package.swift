// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Growfolio",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Growfolio",
            targets: ["Growfolio"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Growfolio",
            dependencies: [],
            path: "Growfolio",
            exclude: [
                "App/GrowfolioApp.swift",
                "App/AppDelegate.swift",
                "Resources",
                "Docs",
                // Exclude iOS-only Views (they use iOS-specific APIs)
                "Presentation/Dashboard/Views",
                "Presentation/Goals/Views",
                "Presentation/DCA/Views",
                "Presentation/Portfolio/Views",
                "Presentation/Settings/Views",
                "Presentation/Onboarding",
                "Presentation/Stocks/Views",
                "Presentation/AI/Views",
                "Presentation/Family/Views",
                "Presentation/Funding/Views",
                "Presentation/KYC/Views",
                // Exclude iOS-only Authentication (uses UIApplication)
                "Core/Authentication/AuthService.swift",
                // Exclude SettingsViewModel (depends on AuthService)
                "Presentation/Settings/ViewModels/SettingsViewModel.swift"
            ],
            sources: [
                "App/Configuration",
                "Core",
                "Data",
                "Domain",
                "Mock",
                "Presentation/Dashboard/ViewModels",
                "Presentation/Goals/ViewModels",
                "Presentation/DCA/ViewModels",
                "Presentation/Portfolio/ViewModels",
                "Presentation/Settings/ViewModels",
                "Presentation/Stocks/ViewModels",
                "Presentation/AI/ViewModels",
                "Presentation/Family/ViewModels",
                "Presentation/Funding/ViewModels",
                "Presentation/KYC/ViewModels",
                "Presentation/Components"
            ]
        ),
        .testTarget(
            name: "GrowfolioTests",
            dependencies: ["Growfolio"],
            path: "GrowfolioTests",
            exclude: [
                // Exclude tests for ViewModels not included in the package
                "ViewModels/SettingsViewModelTests.swift",
                "ViewModels/OnboardingViewModelTests.swift",
                // Exclude tests for Auth types excluded from package (iOS-only)
                "Core/Authentication/AuthServiceTests.swift"
            ]
        ),
    ]
)
