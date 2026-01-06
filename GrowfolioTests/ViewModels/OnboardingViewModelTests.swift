//
//  OnboardingViewModelTests.swift
//  GrowfolioTests
//
//  Tests for OnboardingViewModel - navigation flow and step completion.
//

import XCTest
@testable import Growfolio

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: OnboardingViewModel!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        sut = OnboardingViewModel()
        // Clear onboarding state before each test
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.hasCompletedOnboarding)
    }

    override func tearDown() {
        sut = nil
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func test_initialState_startsAtFirstPage() {
        XCTAssertEqual(sut.currentPage, 0)
    }

    func test_initialState_hasPages() {
        XCTAssertFalse(sut.pages.isEmpty)
    }

    func test_initialState_isFirstPage() {
        XCTAssertTrue(sut.isFirstPage)
    }

    func test_initialState_isNotLastPage() {
        // Only true if there's more than one page
        if sut.pages.count > 1 {
            XCTAssertFalse(sut.isLastPage)
        }
    }

    func test_initialState_progressIsZero() {
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.001)
    }

    // MARK: - Pages Tests

    func test_pages_hasExpectedContent() {
        XCTAssertGreaterThan(sut.pages.count, 0)

        // Verify all pages have required properties
        for page in sut.pages {
            XCTAssertFalse(page.title.isEmpty, "Page should have a title")
            XCTAssertFalse(page.description.isEmpty, "Page should have a description")
            XCTAssertFalse(page.iconName.isEmpty, "Page should have an icon name")
        }
    }

    func test_pages_firstPageIsWelcome() {
        let firstPage = sut.pages.first
        XCTAssertNotNil(firstPage)
        XCTAssertTrue(firstPage?.title.lowercased().contains("welcome") ?? false)
    }

    // MARK: - Navigation Tests - Next Page

    func test_nextPage_advancesToNextPage() {
        let initialPage = sut.currentPage

        sut.nextPage()

        XCTAssertEqual(sut.currentPage, initialPage + 1)
    }

    func test_nextPage_doesNotAdvancePastLastPage() {
        // Go to last page
        for _ in 0..<sut.pages.count {
            sut.nextPage()
        }

        let lastPage = sut.currentPage

        // Try to go past last page
        sut.nextPage()

        XCTAssertEqual(sut.currentPage, lastPage)
    }

    func test_nextPage_updatesIsFirstPage() {
        XCTAssertTrue(sut.isFirstPage)

        sut.nextPage()

        XCTAssertFalse(sut.isFirstPage)
    }

    func test_nextPage_updatesProgress() {
        let initialProgress = sut.progress

        sut.nextPage()

        XCTAssertGreaterThan(sut.progress, initialProgress)
    }

    // MARK: - Navigation Tests - Previous Page

    func test_previousPage_goesBackToPreviousPage() {
        sut.nextPage() // Go to page 1
        let pageBeforeBack = sut.currentPage

        sut.previousPage()

        XCTAssertEqual(sut.currentPage, pageBeforeBack - 1)
    }

    func test_previousPage_doesNotGoBelowFirstPage() {
        XCTAssertEqual(sut.currentPage, 0)

        sut.previousPage()

        XCTAssertEqual(sut.currentPage, 0)
    }

    func test_previousPage_updatesIsFirstPage() {
        sut.nextPage() // Go to page 1
        XCTAssertFalse(sut.isFirstPage)

        sut.previousPage()

        XCTAssertTrue(sut.isFirstPage)
    }

    func test_previousPage_updatesProgress() {
        sut.nextPage()
        let progressAfterNext = sut.progress

        sut.previousPage()

        XCTAssertLessThan(sut.progress, progressAfterNext)
    }

    // MARK: - Navigation Tests - Go To Page

    func test_goToPage_navigatesToSpecificPage() {
        let targetPage = min(2, sut.pages.count - 1)

        sut.goToPage(targetPage)

        XCTAssertEqual(sut.currentPage, targetPage)
    }

    func test_goToPage_doesNotNavigateToInvalidNegativeIndex() {
        sut.goToPage(-1)

        XCTAssertEqual(sut.currentPage, 0)
    }

    func test_goToPage_doesNotNavigatePastLastPage() {
        let invalidIndex = sut.pages.count + 5

        sut.goToPage(invalidIndex)

        XCTAssertEqual(sut.currentPage, 0) // Should remain at initial page
    }

    func test_goToPage_canJumpToFirstPage() {
        sut.nextPage()
        sut.nextPage()

        sut.goToPage(0)

        XCTAssertEqual(sut.currentPage, 0)
    }

    func test_goToPage_canJumpToLastPage() {
        let lastPageIndex = sut.pages.count - 1

        sut.goToPage(lastPageIndex)

        XCTAssertEqual(sut.currentPage, lastPageIndex)
        XCTAssertTrue(sut.isLastPage)
    }

    // MARK: - Computed Properties Tests

    func test_isFirstPage_isTrueOnlyOnFirstPage() {
        XCTAssertTrue(sut.isFirstPage)

        sut.nextPage()

        XCTAssertFalse(sut.isFirstPage)

        sut.previousPage()

        XCTAssertTrue(sut.isFirstPage)
    }

    func test_isLastPage_isTrueOnlyOnLastPage() {
        XCTAssertFalse(sut.isLastPage)

        // Navigate to last page
        let lastPageIndex = sut.pages.count - 1
        sut.goToPage(lastPageIndex)

        XCTAssertTrue(sut.isLastPage)
    }

    func test_progress_calculatesCorrectlyAtStart() {
        // At first page, progress should be 0
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.001)
    }

    func test_progress_calculatesCorrectlyAtEnd() {
        // Navigate to last page
        let lastPageIndex = sut.pages.count - 1
        sut.goToPage(lastPageIndex)

        // At last page, progress should be 1.0
        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.001)
    }

    func test_progress_calculatesCorrectlyInMiddle() {
        guard sut.pages.count >= 3 else { return }

        // Navigate to second page (index 1)
        sut.goToPage(1)

        // Progress should be between 0 and 1
        XCTAssertGreaterThan(sut.progress, 0.0)
        XCTAssertLessThan(sut.progress, 1.0)
    }

    func test_progress_incrementsProportionally() {
        guard sut.pages.count >= 2 else { return }

        let progressPerPage = 1.0 / Double(sut.pages.count - 1)

        sut.nextPage()

        XCTAssertEqual(sut.progress, progressPerPage, accuracy: 0.001)
    }

    // MARK: - Completion Tests

    func test_completeOnboarding_savesToUserDefaults() {
        sut.completeOnboarding()

        let hasCompleted = UserDefaults.standard.bool(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        XCTAssertTrue(hasCompleted)
    }

    func test_completeOnboarding_canBeCalledFromAnyPage() {
        sut.nextPage() // Not on last page

        sut.completeOnboarding()

        let hasCompleted = UserDefaults.standard.bool(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        XCTAssertTrue(hasCompleted)
    }

    // MARK: - Skip Tests

    func test_skipOnboarding_savesToUserDefaults() {
        sut.skipOnboarding()

        let hasCompleted = UserDefaults.standard.bool(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        XCTAssertTrue(hasCompleted)
    }

    func test_skipOnboarding_canBeCalledFromFirstPage() {
        XCTAssertEqual(sut.currentPage, 0)

        sut.skipOnboarding()

        let hasCompleted = UserDefaults.standard.bool(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        XCTAssertTrue(hasCompleted)
    }

    func test_skipOnboarding_canBeCalledFromMiddlePage() {
        sut.nextPage()

        sut.skipOnboarding()

        let hasCompleted = UserDefaults.standard.bool(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        XCTAssertTrue(hasCompleted)
    }

    // MARK: - Full Flow Tests

    func test_fullNavigationFlow_completesSuccessfully() {
        // Start at first page
        XCTAssertTrue(sut.isFirstPage)
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.001)

        // Navigate through all pages
        for i in 0..<sut.pages.count - 1 {
            XCTAssertEqual(sut.currentPage, i)
            sut.nextPage()
        }

        // Should be at last page
        XCTAssertTrue(sut.isLastPage)
        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.001)

        // Complete onboarding
        sut.completeOnboarding()

        let hasCompleted = UserDefaults.standard.bool(forKey: Constants.StorageKeys.hasCompletedOnboarding)
        XCTAssertTrue(hasCompleted)
    }

    func test_backAndForthNavigation_maintainsCorrectState() {
        // Go forward
        sut.nextPage()
        sut.nextPage()
        let middlePage = sut.currentPage

        // Go back
        sut.previousPage()
        XCTAssertEqual(sut.currentPage, middlePage - 1)

        // Go forward again
        sut.nextPage()
        XCTAssertEqual(sut.currentPage, middlePage)
    }

    // MARK: - Edge Cases

    func test_rapidNavigation_maintainsConsistentState() {
        // Rapid forward navigation
        for _ in 0..<10 {
            sut.nextPage()
        }

        // Should be at most at last page
        XCTAssertLessThanOrEqual(sut.currentPage, sut.pages.count - 1)

        // Rapid backward navigation
        for _ in 0..<10 {
            sut.previousPage()
        }

        // Should be at first page
        XCTAssertEqual(sut.currentPage, 0)
    }

    func test_goToSamePage_doesNotChangeState() {
        sut.nextPage()
        let currentPage = sut.currentPage
        let currentProgress = sut.progress

        sut.goToPage(currentPage)

        XCTAssertEqual(sut.currentPage, currentPage)
        XCTAssertEqual(sut.progress, currentProgress, accuracy: 0.001)
    }

    // MARK: - OnboardingPage Static Data Tests

    func test_onboardingPages_hasCorrectCount() {
        // The app should have at least 4 onboarding pages based on the implementation
        XCTAssertGreaterThanOrEqual(OnboardingPage.pages.count, 4)
    }

    func test_onboardingPages_allHaveUniqueIds() {
        let ids = OnboardingPage.pages.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All pages should have unique IDs")
    }

    func test_onboardingPages_coverKeyFeatures() {
        let allTitles = OnboardingPage.pages.map { $0.title.lowercased() }
        let allDescriptions = OnboardingPage.pages.map { $0.description.lowercased() }
        let combinedText = (allTitles + allDescriptions).joined(separator: " ")

        // Check that key features are mentioned
        XCTAssertTrue(
            combinedText.contains("goal") || combinedText.contains("invest") || combinedText.contains("portfolio"),
            "Onboarding should mention key features"
        )
    }

    // MARK: - OnboardingStateManager Tests

    func test_onboardingStateManager_initialState() async {
        let manager = OnboardingStateManager.shared
        await manager.resetOnboarding()

        let hasCompleted = await manager.hasCompletedOnboarding
        XCTAssertFalse(hasCompleted)
    }

    func test_onboardingStateManager_setCompletion() async {
        let manager = OnboardingStateManager.shared

        await manager.setOnboardingCompleted(true)

        let hasCompleted = await manager.hasCompletedOnboarding
        XCTAssertTrue(hasCompleted)

        // Clean up
        await manager.resetOnboarding()
    }

    func test_onboardingStateManager_resetOnboarding() async {
        let manager = OnboardingStateManager.shared

        await manager.setOnboardingCompleted(true)
        await manager.resetOnboarding()

        let hasCompleted = await manager.hasCompletedOnboarding
        XCTAssertFalse(hasCompleted)
    }

    func test_onboardingStateManager_saveAndRetrieveCurrentPage() async {
        let manager = OnboardingStateManager.shared

        await manager.saveCurrentPage(3)

        let lastPage = await manager.lastViewedPage
        XCTAssertEqual(lastPage, 3)

        // Clean up
        UserDefaults.standard.removeObject(forKey: "onboarding_last_page")
    }

    // MARK: - OnboardingFeature Tests

    func test_onboardingFeatures_hasAllCategories() {
        let categories = Set(OnboardingFeature.allFeatures.map { $0.category })

        XCTAssertTrue(categories.contains(.goals))
        XCTAssertTrue(categories.contains(.dca))
        XCTAssertTrue(categories.contains(.portfolio))
        XCTAssertTrue(categories.contains(.family))
        XCTAssertTrue(categories.contains(.insights))
    }

    func test_onboardingFeatures_filteredByCategory() {
        let goalFeatures = OnboardingFeature.features(for: .goals)
        let dcaFeatures = OnboardingFeature.features(for: .dca)
        let portfolioFeatures = OnboardingFeature.features(for: .portfolio)

        XCTAssertFalse(goalFeatures.isEmpty)
        XCTAssertFalse(dcaFeatures.isEmpty)
        XCTAssertFalse(portfolioFeatures.isEmpty)

        // Verify all returned features are of the correct category
        for feature in goalFeatures {
            XCTAssertEqual(feature.category, .goals)
        }
    }

    func test_onboardingFeatures_allHaveRequiredProperties() {
        for feature in OnboardingFeature.allFeatures {
            XCTAssertFalse(feature.title.isEmpty, "Feature should have a title")
            XCTAssertFalse(feature.description.isEmpty, "Feature should have a description")
            XCTAssertFalse(feature.iconName.isEmpty, "Feature should have an icon name")
        }
    }
}
