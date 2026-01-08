import XCTest

/// Base class for UI tests with screenshot capture helpers
class GrowfolioUITests: XCTestCase {

    var app: XCUIApplication!
    var screenshotCounter = 0
    var currentFlowName = "flow"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Enable mock mode for consistent test data
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--mock-mode")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Screenshot Helpers

    /// Capture a screenshot and attach it to the test results
    func captureScreenshot(named name: String) {
        screenshotCounter += 1
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(currentFlowName)-\(String(format: "%02d", screenshotCounter))-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Wait for an element to appear
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    /// Tap and capture screenshot
    func tapAndCapture(_ element: XCUIElement, screenshotName: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Element not found: \(element)")
        element.tap()
        sleep(1) // Allow UI to settle
        captureScreenshot(named: screenshotName)
    }
}

// MARK: - Onboarding Flow Tests

final class OnboardingFlowTests: GrowfolioUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        currentFlowName = "onboarding"

        // Reset onboarding state
        app.launchArguments.append("--reset-onboarding")
    }

    func testOnboardingFlow() throws {
        app.launch()

        // Page 1: Welcome
        captureScreenshot(named: "welcome")

        // Tap Continue through all pages (now only 3 pages)
        if app.buttons["Continue"].exists {
            tapAndCapture(app.buttons["Continue"], screenshotName: "automate")
        }

        if app.buttons["Continue"].exists {
            tapAndCapture(app.buttons["Continue"], screenshotName: "family")
        }

        // Page 3: Get Started (last page)
        if app.buttons["Get Started"].exists {
            tapAndCapture(app.buttons["Get Started"], screenshotName: "auth")
        }
    }

    func testOnboardingSkip() throws {
        app.launch()

        captureScreenshot(named: "welcome-before-skip")

        if app.buttons["Skip"].exists {
            tapAndCapture(app.buttons["Skip"], screenshotName: "skipped-to-auth")
        }
    }
}

// MARK: - Authentication Flow Tests

final class AuthenticationFlowTests: GrowfolioUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        currentFlowName = "authentication"

        // Skip onboarding, go directly to auth
        app.launchArguments.append("--skip-onboarding")
    }

    func testAuthenticationScreen() throws {
        app.launch()

        captureScreenshot(named: "auth-screen")

        // Sign in with Apple button should be visible
        let signInButton = app.buttons["Sign in with Apple"]
        XCTAssertTrue(waitForElement(signInButton), "Sign in with Apple button not found")

        captureScreenshot(named: "auth-ready")
    }
}

// MARK: - Main App Flow Tests

final class MainAppFlowTests: GrowfolioUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        currentFlowName = "main-app"

        // Skip to main app (authenticated + KYC complete)
        app.launchArguments.append("--skip-to-main")
    }

    func testDashboardTab() throws {
        app.launch()

        // Dashboard should be the default tab
        captureScreenshot(named: "dashboard")

        // Scroll to see all content
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            captureScreenshot(named: "dashboard-scrolled")
        }
    }

    func testInvestTab() throws {
        app.launch()

        // Tap Invest tab (consolidates Watchlist, Baskets, DCA)
        let investTab = app.tabBars.buttons["Invest"]
        if investTab.exists {
            tapAndCapture(investTab, screenshotName: "invest-watchlist")
        }

        // Switch to Baskets segment
        if app.buttons["Baskets"].exists {
            tapAndCapture(app.buttons["Baskets"], screenshotName: "invest-baskets")
        }

        // Switch to DCA segment
        if app.buttons["DCA"].exists {
            tapAndCapture(app.buttons["DCA"], screenshotName: "invest-dca")
        }

        // Tap on a stock row if exists (switch back to Watchlist first)
        if app.buttons["Watchlist"].exists {
            app.buttons["Watchlist"].tap()
            sleep(1)

            let stockCell = app.cells.firstMatch
            if stockCell.exists {
                tapAndCapture(stockCell, screenshotName: "stock-detail")
            }
        }
    }

    func testPortfolioTab() throws {
        app.launch()

        // Tap Portfolio tab
        let portfolioTab = app.tabBars.buttons["Portfolio"]
        if portfolioTab.exists {
            tapAndCapture(portfolioTab, screenshotName: "portfolio")
        }

        // Tap on a holding if exists
        let holdingCell = app.cells.firstMatch
        if holdingCell.exists {
            tapAndCapture(holdingCell, screenshotName: "holding-detail")
        }
    }

    func testSettingsTab() throws {
        app.launch()

        // Tap Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            tapAndCapture(settingsTab, screenshotName: "settings")
        }
    }

    func testAllTabsSequence() throws {
        app.launch()

        // Capture all tabs in sequence (now 4 tabs)
        captureScreenshot(named: "tab-0-dashboard")

        let tabs = ["Invest", "Portfolio", "Settings"]
        for (index, tabName) in tabs.enumerated() {
            let tab = app.tabBars.buttons[tabName]
            if tab.exists {
                tab.tap()
                sleep(1)
                captureScreenshot(named: "tab-\(index + 1)-\(tabName.lowercased())")
            }
        }
    }
}

// MARK: - Stock Detail Flow Tests

final class StockDetailFlowTests: GrowfolioUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        currentFlowName = "stock-detail"
        app.launchArguments.append("--skip-to-main")
    }

    func testStockDetailAndBuyFlow() throws {
        app.launch()

        // Go to Invest tab and select Watchlist
        let investTab = app.tabBars.buttons["Invest"]
        if investTab.exists {
            investTab.tap()
            sleep(1)

            // Ensure Watchlist segment is selected
            if app.buttons["Watchlist"].exists {
                app.buttons["Watchlist"].tap()
                sleep(1)
            }

            captureScreenshot(named: "watchlist")
        }

        // Tap first stock
        let stockCell = app.cells.firstMatch
        if stockCell.exists {
            stockCell.tap()
            sleep(1)
            captureScreenshot(named: "stock-detail")
        }

        // Tap Buy button
        let buyButton = app.buttons["Buy"]
        if buyButton.exists {
            buyButton.tap()
            sleep(1)
            captureScreenshot(named: "buy-sheet")
        }

        // Enter amount if text field exists
        let amountField = app.textFields.firstMatch
        if amountField.exists {
            amountField.tap()
            amountField.typeText("100")
            captureScreenshot(named: "buy-amount-entered")
        }
    }

    func testStockDetailChartPeriods() throws {
        app.launch()

        // Navigate to a stock detail
        let investTab = app.tabBars.buttons["Invest"]
        if investTab.exists {
            investTab.tap()
            sleep(1)

            // Ensure Watchlist segment is selected
            if app.buttons["Watchlist"].exists {
                app.buttons["Watchlist"].tap()
                sleep(1)
            }
        }

        let stockCell = app.cells.firstMatch
        if stockCell.exists {
            stockCell.tap()
            sleep(1)
        }

        // Capture different chart periods
        let periods = ["1W", "1M", "3M", "6M", "1Y", "5Y"]
        for period in periods {
            let periodButton = app.buttons[period]
            if periodButton.exists {
                periodButton.tap()
                sleep(1)
                captureScreenshot(named: "chart-\(period)")
            }
        }
    }
}

// MARK: - Goals Flow Tests

final class GoalsFlowTests: GrowfolioUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        currentFlowName = "goals"
        app.launchArguments.append("--skip-to-main")
    }

    func testGoalsFlow() throws {
        app.launch()

        // Find and tap Goals section on dashboard
        let goalsSection = app.staticTexts["Goals"]
        if goalsSection.exists {
            goalsSection.tap()
            sleep(1)
            captureScreenshot(named: "goals-list")
        }

        // Tap on a goal if exists
        let goalCell = app.cells.firstMatch
        if goalCell.exists {
            goalCell.tap()
            sleep(1)
            captureScreenshot(named: "goal-detail")
        }
    }
}

// MARK: - Full App Walkthrough

final class FullAppWalkthroughTests: GrowfolioUITests {

    override func setUpWithError() throws {
        try super.setUpWithError()
        currentFlowName = "full-walkthrough"
        app.launchArguments.append("--skip-to-main")
    }

    /// Captures screenshots of the entire app for documentation
    func testFullAppWalkthrough() throws {
        app.launch()
        sleep(2) // Wait for app to fully load

        // 1. Dashboard
        captureScreenshot(named: "01-dashboard")

        // Check if we're on the main tab view
        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 5) else {
            // Not on main app - capture what we see and fail gracefully
            captureScreenshot(named: "unexpected-screen")
            XCTFail("Tab bar not found - app may not be on main screen")
            return
        }

        // Scroll dashboard
        app.swipeUp()
        sleep(1)
        captureScreenshot(named: "02-dashboard-scrolled")
        app.swipeDown()
        sleep(1)

        // 2. Invest tab - consolidated Watchlist, Baskets, DCA
        let investTab = app.tabBars.buttons["Invest"]
        XCTAssertTrue(investTab.waitForExistence(timeout: 5), "Invest tab not found")
        investTab.tap()
        sleep(1)
        captureScreenshot(named: "03-invest-watchlist")

        // Open stock detail
        let stockCell = app.cells.firstMatch
        if stockCell.waitForExistence(timeout: 3) {
            stockCell.tap()
            sleep(1)
            captureScreenshot(named: "04-stock-detail")

            // Scroll stock detail
            app.swipeUp()
            sleep(1)
            captureScreenshot(named: "05-stock-detail-scrolled")

            // Dismiss (try various close buttons)
            let closeButton = app.navigationBars.buttons.element(boundBy: 0)
            if closeButton.exists {
                closeButton.tap()
                sleep(1)
            }
        }

        // Capture Baskets and DCA segments within Invest tab
        if app.buttons["Baskets"].exists {
            app.buttons["Baskets"].tap()
            sleep(1)
            captureScreenshot(named: "04-invest-baskets")
        }

        if app.buttons["DCA"].exists {
            app.buttons["DCA"].tap()
            sleep(1)
            captureScreenshot(named: "05-invest-dca")
        }

        // 3. Portfolio
        let portfolioTab = app.tabBars.buttons["Portfolio"]
        XCTAssertTrue(portfolioTab.waitForExistence(timeout: 5), "Portfolio tab not found")
        portfolioTab.tap()
        sleep(1)
        captureScreenshot(named: "06-portfolio")

        app.swipeUp()
        sleep(1)
        captureScreenshot(named: "07-portfolio-scrolled")

        // 4. Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab not found")
        settingsTab.tap()
        sleep(1)
        captureScreenshot(named: "08-settings")

        app.swipeUp()
        sleep(1)
        captureScreenshot(named: "09-settings-scrolled")
    }
}
