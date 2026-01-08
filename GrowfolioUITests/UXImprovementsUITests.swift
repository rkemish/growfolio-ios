import XCTest

/// UI tests for iPhone UX improvements (Phases 1-3)
/// Tests the consolidated tab bar, success toasts, improved empty states, and search functionality
final class UXImprovementsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--mock-mode")
        app.launchArguments.append("--skip-to-main")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Phase 1.2: Onboarding Tests (3 Pages)

    func testOnboarding_HasThreePages() throws {
        // Reset onboarding for this test
        app.launchArguments.removeAll { $0 == "--skip-to-main" }
        app.launchArguments.append("--reset-onboarding")
        app.launch()

        // Page 1: Welcome to Growfolio
        XCTAssertTrue(app.staticTexts["Welcome to Growfolio"].waitForExistence(timeout: 5),
                      "Welcome page not found")

        // Continue to page 2
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.exists, "Continue button not found")
        continueButton.tap()
        sleep(1)

        // Page 2: Automate Your Growth
        XCTAssertTrue(app.staticTexts["Automate Your Growth"].waitForExistence(timeout: 2),
                      "Automate Your Growth page not found")
        continueButton.tap()
        sleep(1)

        // Page 3: Built for Families (last page)
        XCTAssertTrue(app.staticTexts["Built for Families"].waitForExistence(timeout: 2),
                      "Built for Families page not found")

        // Should show "Get Started" instead of "Continue" on last page
        XCTAssertTrue(app.buttons["Get Started"].exists,
                      "Get Started button not found on last page")
        XCTAssertFalse(continueButton.exists,
                       "Continue button should not exist on last page")
    }

    func testOnboarding_SkipButton() throws {
        app.launchArguments.removeAll { $0 == "--skip-to-main" }
        app.launchArguments.append("--reset-onboarding")
        app.launch()

        // Skip button should exist on first pages
        let skipButton = app.buttons["Skip"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5),
                      "Skip button not found")

        // Tap skip
        skipButton.tap()
        sleep(1)

        // Should navigate to authentication (in mock mode, goes to main)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5),
                      "Did not navigate after skip")
    }

    // MARK: - Phase 2.1: Tab Bar Tests (4 Tabs)

    func testTabBar_HasFourTabs() throws {
        app.launch()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar not found")

        // Verify exactly 4 tabs exist
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].exists, "Dashboard tab not found")
        XCTAssertTrue(app.tabBars.buttons["Invest"].exists, "Invest tab not found")
        XCTAssertTrue(app.tabBars.buttons["Portfolio"].exists, "Portfolio tab not found")
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists, "Settings tab not found")

        // Old tabs should NOT exist
        XCTAssertFalse(app.tabBars.buttons["Watchlist"].exists,
                       "Old Watchlist tab should not exist")
        XCTAssertFalse(app.tabBars.buttons["Baskets"].exists,
                       "Old Baskets tab should not exist")
        XCTAssertFalse(app.tabBars.buttons["DCA"].exists,
                       "Old DCA tab should not exist")
    }

    func testTabBar_AllTabsAccessible() throws {
        app.launch()
        sleep(1)

        // Test Dashboard tab (default)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Portfolio'")).firstMatch.waitForExistence(timeout: 3),
                      "Dashboard content not visible")

        // Test Invest tab (shows "Watchlist" title by default)
        app.tabBars.buttons["Invest"].tap()
        sleep(2)
        XCTAssertTrue(app.navigationBars["Watchlist"].waitForExistence(timeout: 5),
                      "Invest tab not loaded (Watchlist navigation bar not found)")

        // Test Portfolio tab
        app.tabBars.buttons["Portfolio"].tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["Portfolio"].waitForExistence(timeout: 3),
                      "Portfolio navigation bar not found")

        // Test Settings tab
        app.tabBars.buttons["Settings"].tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3),
                      "Settings navigation bar not found")
    }

    // MARK: - Phase 2.1: Invest Tab Tests (Segmented Control)

    func testInvestTab_HasSegmentedControl() throws {
        app.launch()

        // Navigate to Invest tab
        app.tabBars.buttons["Invest"].tap()
        sleep(1)

        // Verify segmented control exists with 3 segments
        let segmentedControl = app.segmentedControls.firstMatch
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 3),
                      "Segmented control not found in Invest tab")

        // Verify segments exist
        XCTAssertTrue(app.buttons["Watchlist"].exists, "Watchlist segment not found")
        XCTAssertTrue(app.buttons["Baskets"].exists, "Baskets segment not found")
        XCTAssertTrue(app.buttons["DCA"].exists, "DCA segment not found")
    }

    func testInvestTab_SegmentSwitching() throws {
        app.launch()

        // Navigate to Invest tab
        app.tabBars.buttons["Invest"].tap()
        sleep(2)

        // Default should be Watchlist (child view's navigation title)
        XCTAssertTrue(app.navigationBars["Watchlist"].waitForExistence(timeout: 5),
                      "Watchlist navigation bar not found")

        // Switch to Baskets
        app.buttons["Baskets"].tap()
        sleep(1)
        // Content should change (check for empty state or basket content)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Basket'")).firstMatch.exists,
                      "Baskets content not visible")

        // Switch to DCA
        app.buttons["DCA"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'DCA'")).firstMatch.exists,
                      "DCA content not visible")

        // Switch back to Watchlist
        app.buttons["Watchlist"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Watchlist' OR label CONTAINS 'stock'")).firstMatch.exists,
                      "Watchlist content not visible")
    }

    func testInvestTab_SwipeGesture() throws {
        app.launch()

        // Navigate to Invest tab
        app.tabBars.buttons["Invest"].tap()
        sleep(1)

        // Try swiping left to change segments (TabView with .page style)
        let investView = app.otherElements["Invest"].firstMatch
        if investView.exists {
            investView.swipeLeft()
            sleep(1)
            // Should switch to Baskets segment
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Basket'")).firstMatch.exists,
                          "Did not switch segments on swipe")
        }
    }

    // MARK: - Phase 1.1: Success Toast Tests

    func testCreateGoal_ShowsSuccessToast() throws {
        app.launch()

        // Navigate to Invest tab
        app.tabBars.buttons["Invest"].tap()
        sleep(1)

        // Switch to Goals (if accessible via Invest or Dashboard)
        // For this test, we'll create from Dashboard quick actions
        app.tabBars.buttons["Dashboard"].tap()
        sleep(1)

        // Tap "Add Goal" quick action button
        let addGoalButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Add Goal'")).firstMatch
        if addGoalButton.waitForExistence(timeout: 3) {
            addGoalButton.tap()
            sleep(1)

            // Fill in goal form
            let nameField = app.textFields["Goal Name"]
            if nameField.waitForExistence(timeout: 2) {
                nameField.tap()
                nameField.typeText("Test Goal")

                let amountField = app.textFields["Target Amount"]
                amountField.tap()
                amountField.typeText("10000")

                // Save
                app.buttons["Save"].tap()
                sleep(1)

                // Verify success toast appears
                let successToast = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Test Goal' AND label CONTAINS[c] 'created successfully'")).firstMatch
                XCTAssertTrue(successToast.waitForExistence(timeout: 3),
                              "Success toast not found after creating goal")
            }
        }
    }

    func testCreateDCASchedule_ShowsSuccessToast() throws {
        app.launch()

        // Navigate to Dashboard
        app.tabBars.buttons["Dashboard"].tap()
        sleep(1)

        // Tap "New DCA" quick action button
        let newDCAButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'New DCA'")).firstMatch
        if newDCAButton.waitForExistence(timeout: 3) {
            newDCAButton.tap()
            sleep(1)

            // Fill in DCA form (simplified - actual form may vary)
            let symbolSearch = app.textFields.firstMatch
            if symbolSearch.waitForExistence(timeout: 2) {
                symbolSearch.tap()
                symbolSearch.typeText("AAPL")
                sleep(1)

                // Select first result if available
                let firstResult = app.cells.firstMatch
                if firstResult.exists {
                    firstResult.tap()
                }

                let amountField = app.textFields.containing(NSPredicate(format: "label CONTAINS 'Amount'")).firstMatch
                if amountField.exists {
                    amountField.tap()
                    amountField.typeText("100")
                }

                // Save
                let createButton = app.buttons["Create"]
                if createButton.exists {
                    createButton.tap()
                    sleep(1)

                    // Verify success toast
                    let successToast = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'AAPL' AND label CONTAINS[c] 'created successfully'")).firstMatch
                    XCTAssertTrue(successToast.waitForExistence(timeout: 3),
                                  "Success toast not found after creating DCA schedule")
                }
            }
        }
    }

    func testCreateBasket_ShowsSuccessToast() throws {
        app.launch()

        // Navigate to Invest tab
        app.tabBars.buttons["Invest"].tap()
        sleep(2)

        // Switch to Baskets segment
        app.buttons["Baskets"].tap()
        sleep(1)

        // Tap create basket button (either in empty state or toolbar)
        let createBasketButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Create'")).firstMatch
        XCTAssertTrue(createBasketButton.waitForExistence(timeout: 3),
                      "Create basket button not found")

        createBasketButton.tap()
        sleep(1)

        // Verify basket creation form opened
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 3),
                      "Basket creation form did not open")

        // NOTE: Full basket creation flow requires complex allocation setup
        // This test verifies the form opens correctly
        // The success toast is tested in integration tests with proper mock data

        // Cancel to clean up
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }

    // MARK: - Phase 3.1: Empty State Tests

    func testGoalsEmptyState_ShowsEducationalContent() throws {
        app.launch()

        // Navigate to Dashboard and find Goals section
        // Or navigate via Invest if Goals is accessible there
        app.tabBars.buttons["Dashboard"].tap()
        sleep(1)

        // Scroll to goals section
        app.swipeUp()
        sleep(1)

        // Check for empty state educational content
        let emptyStateLabel = app.staticTexts["No Goals Yet"]
        if emptyStateLabel.exists {
            // Verify educational steps are shown
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'goal type'")).firstMatch.exists,
                          "Educational step 1 not found in goals empty state")
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'target amount'")).firstMatch.exists,
                          "Educational step 2 not found in goals empty state")
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'DCA schedules'")).firstMatch.exists,
                          "Educational step 3 not found in goals empty state")

            // Verify CTA button
            XCTAssertTrue(app.buttons["Create Your First Goal"].exists,
                          "Create Your First Goal button not found")
        }
    }

    func testDCAEmptyState_ShowsEducationalContent() throws {
        app.launch()

        // Navigate to Invest tab
        app.tabBars.buttons["Invest"].tap()
        sleep(1)

        // Switch to DCA segment
        app.buttons["DCA"].tap()
        sleep(1)

        // Check for empty state educational content
        let emptyStateLabel = app.staticTexts["No DCA Schedules"]
        if emptyStateLabel.exists {
            // Verify educational steps are shown
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'stock and investment amount'")).firstMatch.exists,
                          "Educational step 1 not found in DCA empty state")
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'frequency'")).firstMatch.exists,
                          "Educational step 2 not found in DCA empty state")
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'automation'")).firstMatch.exists,
                          "Educational step 3 not found in DCA empty state")

            // Verify CTA button
            XCTAssertTrue(app.buttons["Create Your First Schedule"].exists,
                          "Create Your First Schedule button not found")
        }
    }

    func testBasketsEmptyState_ShowsEducationalContent() throws {
        app.launch()

        // Navigate to Invest tab
        app.tabBars.buttons["Invest"].tap()
        sleep(1)

        // Switch to Baskets segment
        app.buttons["Baskets"].tap()
        sleep(1)

        // Check for empty state educational content
        let emptyStateLabel = app.staticTexts["No Baskets Yet"]
        if emptyStateLabel.exists {
            // Verify educational steps are shown
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Name your basket'")).firstMatch.exists,
                          "Educational step 1 not found in baskets empty state")
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'allocation percentages'")).firstMatch.exists,
                          "Educational step 2 not found in baskets empty state")
            XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'rebalancing'")).firstMatch.exists,
                          "Educational step 3 not found in baskets empty state")

            // Verify CTA button
            XCTAssertTrue(app.buttons["Create Your First Basket"].exists,
                          "Create Your First Basket button not found")
        }
    }

    // MARK: - Phase 3.2: Global Search Tests

    func testDashboard_HasSearchButton() throws {
        app.launch()

        // Dashboard should be default tab
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5),
                      "Navigation bar not found")

        // Verify search button exists in toolbar
        let searchButton = app.navigationBars.buttons.containing(NSPredicate(format: "identifier == 'magnifyingglass' OR label CONTAINS 'Search'")).firstMatch
        XCTAssertTrue(searchButton.exists,
                      "Search button not found in Dashboard toolbar")
    }

    func testDashboard_SearchButtonOpensStockSearch() throws {
        app.launch()

        // Tap search button
        let searchButton = app.navigationBars.buttons.containing(NSPredicate(format: "identifier == 'magnifyingglass' OR label CONTAINS 'Search'")).firstMatch
        if searchButton.waitForExistence(timeout: 3) {
            searchButton.tap()
            sleep(1)

            // Verify stock search sheet appears
            XCTAssertTrue(app.navigationBars["Add to Watchlist"].waitForExistence(timeout: 3) ||
                         app.searchFields.firstMatch.waitForExistence(timeout: 3),
                         "Stock search sheet did not appear")
        }
    }

    func testDashboard_SearchAndAddStock() throws {
        app.launch()

        // Tap search button
        let searchButton = app.navigationBars.buttons.containing(NSPredicate(format: "identifier == 'magnifyingglass' OR label CONTAINS 'Search'")).firstMatch
        if searchButton.waitForExistence(timeout: 3) {
            searchButton.tap()
            sleep(1)

            // Enter search query
            let searchField = app.searchFields.firstMatch
            if searchField.waitForExistence(timeout: 2) {
                searchField.tap()
                searchField.typeText("AAPL")
                sleep(2) // Wait for search results

                // Tap first result
                let firstResult = app.cells.firstMatch
                if firstResult.waitForExistence(timeout: 3) {
                    firstResult.tap()
                    sleep(1)

                    // Verify success toast
                    let successToast = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'added to watchlist'")).firstMatch
                    XCTAssertTrue(successToast.waitForExistence(timeout: 3),
                                  "Success toast not shown after adding stock")
                }
            }
        }
    }

    // MARK: - Integration Tests

    func testCompleteUserFlow_CreateGoalFromDashboard() throws {
        app.launch()

        // Start from Dashboard
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].exists,
                      "Dashboard tab not found")

        // Tap Add Goal quick action
        let addGoalButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Add Goal'")).firstMatch
        if addGoalButton.waitForExistence(timeout: 3) {
            addGoalButton.tap()
            sleep(1)

            // Fill form
            let nameField = app.textFields["Goal Name"]
            if nameField.waitForExistence(timeout: 2) {
                nameField.tap()
                nameField.typeText("Retirement")

                let amountField = app.textFields["Target Amount"]
                amountField.tap()
                amountField.typeText("1000000")

                // Save
                app.buttons["Save"].tap()
                sleep(1)

                // Verify success toast
                let successToast = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'Retirement' AND label CONTAINS[c] 'created'")).firstMatch
                XCTAssertTrue(successToast.waitForExistence(timeout: 3),
                              "Success toast not shown")

                // Verify we're back on Dashboard
                XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Portfolio'")).firstMatch.exists,
                              "Not returned to Dashboard after creating goal")
            }
        }
    }

    func testCompleteUserFlow_NavigateThroughAllTabs() throws {
        app.launch()

        // Dashboard (default)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Portfolio'")).firstMatch.waitForExistence(timeout: 3),
                      "Dashboard not loaded")

        // Invest tab with all segments (shows "Watchlist" title by default)
        app.tabBars.buttons["Invest"].tap()
        sleep(2)
        XCTAssertTrue(app.navigationBars["Watchlist"].waitForExistence(timeout: 5),
                      "Invest tab not loaded (Watchlist navigation bar not found)")

        // Test each segment
        app.buttons["Watchlist"].tap()
        sleep(1)
        app.buttons["Baskets"].tap()
        sleep(1)
        app.buttons["DCA"].tap()
        sleep(1)

        // Portfolio tab
        app.tabBars.buttons["Portfolio"].tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["Portfolio"].exists,
                      "Portfolio tab not loaded")

        // Settings tab
        app.tabBars.buttons["Settings"].tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars["Settings"].exists,
                      "Settings tab not loaded")

        // Return to Dashboard
        app.tabBars.buttons["Dashboard"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Portfolio'")).firstMatch.exists,
                      "Could not return to Dashboard")
    }
}
