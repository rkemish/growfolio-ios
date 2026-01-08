# UX Improvements UI Test Plan

## Overview

This document outlines the comprehensive UI test suite for the iPhone UX improvements implemented across Phases 1-3. The test suite validates all new features including the 4-tab navigation, success toasts, enhanced empty states, and global search functionality.

---

## Test Files

### 1. `UXImprovementsUITests.swift` (NEW)
Comprehensive test suite specifically for the UX improvements. Contains 20+ test cases covering all three phases.

### 2. `GrowfolioUITests.swift` (UPDATED)
Updated existing tests to reflect the new 4-tab structure and 3-page onboarding.

---

## Running the Tests

### Run All UI Tests
```bash
# From command line
xcodebuild -project Growfolio.xcodeproj -scheme Growfolio test -destination 'platform=iOS Simulator,name=iPhone 15'

# Using Xcode
# Cmd+U or Product > Test
```

### Run Specific Test Class
```bash
# UX Improvements tests only
xcodebuild -project Growfolio.xcodeproj -scheme Growfolio test -only-testing:GrowfolioUITests/UXImprovementsUITests -destination 'platform=iOS Simulator,name=iPhone 15'

# Onboarding tests only
xcodebuild -project Growfolio.xcodeproj -scheme Growfolio test -only-testing:GrowfolioUITests/OnboardingFlowTests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run Specific Test Method
```bash
xcodebuild -project Growfolio.xcodeproj -scheme Growfolio test -only-testing:GrowfolioUITests/UXImprovementsUITests/testTabBar_HasFourTabs -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## Test Coverage by Phase

## Phase 1: Quick Wins

### 1.1 Success Toasts (3 tests)

| Test | Description | Validates |
|------|-------------|-----------|
| `testCreateGoal_ShowsSuccessToast` | Create a goal and verify toast appears | Success message contains goal name and "created successfully" |
| `testCreateDCASchedule_ShowsSuccessToast` | Create a DCA schedule and verify toast | Success message contains stock symbol and "created successfully" |
| `testCreateBasket_ShowsSuccessToast` | Create a basket and verify toast | Success message contains basket name and "created successfully" |

**Expected Results:**
- Toast appears within 3 seconds of creation
- Toast contains entity name and success message
- Toast auto-dismisses after ~3 seconds

---

### 1.2 Onboarding Reduction (2 tests)

| Test | Description | Validates |
|------|-------------|-----------|
| `testOnboarding_HasThreePages` | Walk through entire onboarding flow | Exactly 3 pages: Welcome, Automate, Families |
| `testOnboarding_SkipButton` | Test skip functionality | Skip button navigates to authentication |

**Expected Results:**
- Onboarding has exactly 3 pages (not 5)
- Page 1: Welcome to Growfolio
- Page 2: Automate Your Growth
- Page 3: Built for Families
- Last page shows "Get Started" (not "Continue")
- Skip button works on pages 1-2

**Updated Existing Test:**
- `OnboardingFlowTests.testOnboardingFlow` - Updated to expect 3 pages

---

## Phase 2: Navigation Simplification

### 2.1 Tab Bar Consolidation (4 tests)

| Test | Description | Validates |
|------|-------------|-----------|
| `testTabBar_HasFourTabs` | Count tabs and verify names | 4 tabs: Dashboard, Invest, Portfolio, Settings |
| `testTabBar_AllTabsAccessible` | Navigate to each tab | All tabs load correctly |
| `testInvestTab_HasSegmentedControl` | Verify segmented control exists | 3 segments: Watchlist, Baskets, DCA |
| `testInvestTab_SegmentSwitching` | Switch between segments | Content changes when segments switch |
| `testInvestTab_SwipeGesture` | Test swipe navigation | Swiping left/right changes segments |

**Expected Results:**
- Tab bar has exactly 4 tabs (not 6)
- Old tabs (Watchlist, Baskets, DCA) do NOT exist in tab bar
- Invest tab contains segmented control
- Segments switch content correctly
- Swipe gestures work for segment navigation

**Updated Existing Tests:**
- `MainAppFlowTests.testInvestTab` - Replaced `testWatchlistTab` and `testDCATab`
- `MainAppFlowTests.testAllTabsSequence` - Updated to iterate 3 tabs (not 4)
- `StockDetailFlowTests.testStockDetailAndBuyFlow` - Navigate via Invest tab
- `StockDetailFlowTests.testStockDetailChartPeriods` - Navigate via Invest tab
- `FullAppWalkthroughTests.testFullAppWalkthrough` - Updated navigation flow

---

## Phase 3: Enhanced Discoverability

### 3.1 Empty State Improvements (3 tests)

| Test | Description | Validates |
|------|-------------|-----------|
| `testGoalsEmptyState_ShowsEducationalContent` | Verify goals empty state content | Educational steps 1-3 present, CTA button exists |
| `testDCAEmptyState_ShowsEducationalContent` | Verify DCA empty state content | Educational steps 1-3 present, CTA button exists |
| `testBasketsEmptyState_ShowsEducationalContent` | Verify baskets empty state content | Educational steps 1-3 present, CTA button exists |

**Expected Results:**
- Empty state shows title and description
- 3 numbered educational steps visible with icons
- Step content explains feature value and usage
- CTA button present ("Create Your First X")
- Educational box has background and padding

---

### 3.2 Global Search (3 tests)

| Test | Description | Validates |
|------|-------------|-----------|
| `testDashboard_HasSearchButton` | Verify search button in toolbar | Magnifying glass icon exists |
| `testDashboard_SearchButtonOpensStockSearch` | Tap search button | Stock search sheet appears |
| `testDashboard_SearchAndAddStock` | Complete search flow | Search → Select → Toast confirmation |

**Expected Results:**
- Search button visible in Dashboard toolbar
- Tapping search opens stock search sheet
- Searching for "AAPL" shows results
- Adding stock shows success toast

---

## Integration Tests (2 tests)

| Test | Description | Validates |
|------|-------------|-----------|
| `testCompleteUserFlow_CreateGoalFromDashboard` | End-to-end goal creation | Dashboard → Quick Action → Form → Toast → Return to Dashboard |
| `testCompleteUserFlow_NavigateThroughAllTabs` | Full tab navigation | Dashboard → Invest (all segments) → Portfolio → Settings → Dashboard |

**Expected Results:**
- Complete flows work without errors
- User returns to expected screens after actions
- Toasts appear at appropriate times
- All tabs and segments accessible

---

## Test Execution Report

### Quick Test Run (5 minutes)
```bash
# Essential tests only
xcodebuild test -only-testing:GrowfolioUITests/UXImprovementsUITests/testTabBar_HasFourTabs
xcodebuild test -only-testing:GrowfolioUITests/UXImprovementsUITests/testOnboarding_HasThreePages
xcodebuild test -only-testing:GrowfolioUITests/UXImprovementsUITests/testInvestTab_HasSegmentedControl
xcodebuild test -only-testing:GrowfolioUITests/UXImprovementsUITests/testDashboard_HasSearchButton
```

### Comprehensive Test Run (15-20 minutes)
```bash
# All UX improvement tests
xcodebuild test -only-testing:GrowfolioUITests/UXImprovementsUITests
```

### Full Regression Test (30+ minutes)
```bash
# All UI tests (updated existing + new)
xcodebuild test -scheme Growfolio -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## Manual Test Checklist

Use this checklist for manual verification after running automated tests:

### Phase 1: Quick Wins
- [ ] Create a goal → See toast with goal name
- [ ] Edit a goal → See "updated successfully" toast
- [ ] Create DCA schedule → See toast with stock symbol
- [ ] Edit DCA schedule → See "updated successfully" toast
- [ ] Create basket → See toast with basket name
- [ ] Onboarding shows 3 pages (not 5)
- [ ] Skip button works on onboarding

### Phase 2: Navigation
- [ ] Tab bar shows 4 tabs (Dashboard, Invest, Portfolio, Settings)
- [ ] Invest tab has segmented control at top
- [ ] Segmented control shows: Watchlist | Baskets | DCA
- [ ] Tapping segments changes content
- [ ] Swiping left/right changes segments
- [ ] All content loads correctly in each segment
- [ ] iPad still shows 7 sections in sidebar (not affected)

### Phase 3: Discoverability
- [ ] Goals empty state shows 3 educational steps
- [ ] DCA empty state shows 3 educational steps
- [ ] Baskets empty state shows 3 educational steps
- [ ] Each empty state has "Create Your First X" button
- [ ] Dashboard has search button (magnifying glass)
- [ ] Tapping search opens stock search
- [ ] Searching and adding stock shows success toast

---

## Known Issues & Edge Cases

### Test Environment Requirements
- **iOS Simulator:** iPhone 15 or later (iOS 17+)
- **Launch Arguments:** `--uitesting`, `--mock-mode`, `--skip-to-main`
- **Mock Data:** Tests depend on mock data being available

### Potential Flaky Tests
1. **Toast visibility tests** - Toasts auto-dismiss, may need timing adjustments
2. **Swipe gesture tests** - Simulator gestures can be unreliable
3. **Search tests** - Network-dependent (but should use mock in UI tests)

### Debugging Tips
```swift
// Add breakpoints in test methods
// Enable "Pause on Test Failure" in Test navigator
// Check test attachment screenshots in test results
// Increase timeout values if tests fail due to slow simulator
```

---

## Test Maintenance

### When to Update Tests

**Add new tests when:**
- Adding new features to the UX improvements
- Changing navigation flows
- Modifying empty states or success messages

**Update existing tests when:**
- Changing tab count or tab names
- Modifying onboarding page count
- Changing segment names in Invest tab
- Updating toast message formats

### Test Naming Convention
```
test[Feature]_[Scenario]()

Examples:
- testTabBar_HasFourTabs()
- testInvestTab_SegmentSwitching()
- testCreateGoal_ShowsSuccessToast()
- testDashboard_SearchButtonOpensStockSearch()
```

---

## Success Metrics

### Test Pass Criteria
- **100% of Phase 1 tests pass** (critical: toasts, onboarding)
- **100% of Phase 2 tests pass** (critical: navigation)
- **90%+ of Phase 3 tests pass** (enhanced features)
- **No regressions in existing tests**

### Expected Results Summary
| Phase | Test Count | Pass Threshold | Impact |
|-------|-----------|----------------|--------|
| Phase 1.1 (Toasts) | 3 | 100% | HIGH |
| Phase 1.2 (Onboarding) | 2 | 100% | HIGH |
| Phase 2.1 (Tabs) | 5 | 100% | HIGH |
| Phase 3.1 (Empty States) | 3 | 90% | MEDIUM |
| Phase 3.2 (Search) | 3 | 90% | MEDIUM |
| Integration | 2 | 100% | HIGH |
| **TOTAL** | **18 new tests** | **95%+** | |

---

## Continuous Integration

### GitHub Actions / CI Configuration
```yaml
# Example CI configuration
- name: Run UI Tests
  run: |
    xcodebuild test \
      -project Growfolio.xcodeproj \
      -scheme Growfolio \
      -destination 'platform=iOS Simulator,name=iPhone 15' \
      -only-testing:GrowfolioUITests/UXImprovementsUITests
```

### Pre-merge Requirements
- [ ] All Phase 1 & 2 tests pass
- [ ] No regressions in existing tests
- [ ] Manual testing completed for critical paths
- [ ] Test coverage report reviewed

---

## Contact & Support

**Test Maintainer:** Development Team
**Last Updated:** 2026-01-08
**Test Framework:** XCTest (iOS 17+)
**Coverage:** 18 new tests + 8 updated tests = 26 total tests for UX improvements
