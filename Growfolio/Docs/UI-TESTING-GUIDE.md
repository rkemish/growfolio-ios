# Growfolio iOS - UI Testing & Flow Capture Guide

This guide covers automated UI testing, screenshot capture, and video recording for the Growfolio iOS app.

## Table of Contents

- [Quick Start](#quick-start)
- [UI Test Suite](#ui-test-suite)
- [Screenshot Capture](#screenshot-capture)
- [Video Recording](#video-recording)
- [Launch Arguments](#launch-arguments)
- [Exporting Assets](#exporting-assets)

---

## Quick Start

### Run All UI Tests
```bash
xcodebuild test \
  -project Growfolio.xcodeproj \
  -scheme Growfolio \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GrowfolioUITests
```

### Capture Full App Walkthrough
```bash
xcodebuild test \
  -project Growfolio.xcodeproj \
  -scheme Growfolio \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GrowfolioUITests/FullAppWalkthroughTests/testFullAppWalkthrough
```

### Record Video Flow
```bash
./scripts/capture-flow.sh
```

---

## UI Test Suite

### Test Classes

| Test Class | Description |
|------------|-------------|
| `OnboardingFlowTests` | Tests onboarding pages and skip functionality |
| `AuthenticationFlowTests` | Tests authentication screen |
| `MainAppFlowTests` | Tests all 5 main tabs |
| `StockDetailFlowTests` | Tests stock detail sheet and buy flow |
| `GoalsFlowTests` | Tests goals navigation |
| `FullAppWalkthroughTests` | Captures screenshots of entire app |

### Running Specific Tests

```bash
# Single test class
xcodebuild test \
  -project Growfolio.xcodeproj \
  -scheme Growfolio \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GrowfolioUITests/MainAppFlowTests

# Single test method
xcodebuild test \
  -project Growfolio.xcodeproj \
  -scheme Growfolio \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GrowfolioUITests/MainAppFlowTests/testAllTabsSequence
```

### Available Simulators

Check available simulators:
```bash
xcrun simctl list devices available | grep -E "iPhone|iPad"
```

Common simulators:
- `iPhone 17 Pro`
- `iPhone 17 Pro Max`
- `iPhone 16e`
- `iPad Pro 13-inch (M4)`

---

## Screenshot Capture

### How Screenshots Work

UI tests use `XCTAttachment` to capture screenshots:

```swift
func captureScreenshot(named name: String) {
    let screenshot = app.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "\(flowName)-\(name)"
    attachment.lifetime = .keepAlways
    add(attachment)
}
```

### Screenshot Locations

Screenshots are stored in the xcresult bundle:
```
~/Library/Developer/Xcode/DerivedData/Growfolio-*/Logs/Test/*.xcresult
```

### Exporting Screenshots

**Method 1: Open in Xcode**
```bash
open ~/Library/Developer/Xcode/DerivedData/Growfolio-*/Logs/Test/*.xcresult
```
Then expand test → Attachments to view/export screenshots.

**Method 2: Command Line Export**
```bash
# Find PNG files in xcresult
XCRESULT=$(ls -td ~/Library/Developer/Xcode/DerivedData/Growfolio-*/Logs/Test/*.xcresult | head -1)

# Copy all PNGs to output folder
mkdir -p Growfolio/Docs/Screenshots
for file in "$XCRESULT/Data/"*; do
    if file "$file" | grep -q "PNG image"; then
        cp "$file" "Growfolio/Docs/Screenshots/screenshot-$(basename $file).png"
    fi
done
```

### Current Screenshots

Located in `Growfolio/Docs/Screenshots/`:

| File | Screen |
|------|--------|
| `01-dashboard.png` | Main dashboard view |
| `02-dashboard-scrolled.png` | Dashboard scrolled down |
| `03-watchlist.png` | Watchlist tab |
| `04-stock-detail.png` | Stock detail sheet |
| `05-stock-detail-scrolled.png` | Stock detail scrolled |
| `06-dca-schedules.png` | DCA schedules tab |
| `07-portfolio.png` | Portfolio tab |
| `08-portfolio-scrolled.png` | Portfolio scrolled |
| `09-settings.png` | Settings tab |
| `10-settings-scrolled.png` | Settings scrolled |

---

## Video Recording

### Interactive Recording Script

```bash
./scripts/capture-flow.sh
```

**Modes:**
1. **Manual recording** - Press Ctrl+C to stop
2. **Timed recording** - Specify duration in seconds
3. **UI test recording** - Record while running automated tests

### Direct simctl Commands

**Start recording (Ctrl+C to stop):**
```bash
xcrun simctl io booted recordVideo my-flow.mp4
```

**Record for specific duration:**
```bash
# Record for 30 seconds
xcrun simctl io booted recordVideo my-flow.mp4 &
PID=$!
sleep 30
kill -INT $PID
```

**Record with app launch:**
```bash
# Get simulator UDID
UDID=$(xcrun simctl list devices booted -j | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for device in devices:
        if device.get('state') == 'Booted':
            print(device['udid'])
            break
")

# Launch app in mock mode
xcrun simctl launch "$UDID" com.growfolio.app --args --mock-mode --skip-to-main

# Start recording
xcrun simctl io "$UDID" recordVideo --codec h264 flow.mp4
```

### Simulator Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Start/Stop Recording | `Cmd + R` |
| Take Screenshot | `Cmd + S` |
| Rotate Left | `Cmd + ←` |
| Rotate Right | `Cmd + →` |
| Home Button | `Cmd + Shift + H` |
| Shake Gesture | `Cmd + Ctrl + Z` |

### Convert to GIF

```bash
# Requires: brew install ffmpeg
ffmpeg -i flow.mp4 \
  -vf "fps=10,scale=320:-1:flags=lanczos" \
  -c:v gif \
  flow.gif
```

### Output Location

Videos saved to: `Growfolio/Docs/Screenshots/Videos/`

---

## Launch Arguments

The app supports launch arguments for UI testing:

| Argument | Description |
|----------|-------------|
| `--uitesting` | Enable UI testing mode (faster animations) |
| `--mock-mode` | Use mock data instead of real API |
| `--reset-onboarding` | Reset onboarding state |
| `--skip-onboarding` | Skip to authentication screen |
| `--skip-to-main` | Skip directly to main app (tab bar) |

### Using in Tests

```swift
override func setUpWithError() throws {
    app = XCUIApplication()
    app.launchArguments.append("--uitesting")
    app.launchArguments.append("--mock-mode")
    app.launchArguments.append("--skip-to-main")
}
```

### Using with simctl

```bash
xcrun simctl launch booted com.growfolio.app --args --mock-mode --skip-to-main
```

---

## Exporting Assets

### Generate App Flow PDF

A PDF combining all screenshots with descriptions:

```bash
# Located at:
Growfolio/Docs/Screenshots/Growfolio-App-Flow.pdf
```

To regenerate, run the full walkthrough test and export screenshots.

### Batch Export All Assets

```bash
# 1. Run full test suite
xcodebuild test \
  -project Growfolio.xcodeproj \
  -scheme Growfolio \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:GrowfolioUITests/FullAppWalkthroughTests

# 2. Find latest xcresult
XCRESULT=$(ls -td ~/Library/Developer/Xcode/DerivedData/Growfolio-*/Logs/Test/*.xcresult | head -1)

# 3. Export screenshots
OUTPUT_DIR="Growfolio/Docs/Screenshots"
mkdir -p "$OUTPUT_DIR"

counter=1
for file in "$XCRESULT/Data/"*; do
    if file "$file" | grep -q "PNG image"; then
        cp "$file" "$OUTPUT_DIR/screenshot-$(printf '%02d' $counter).png"
        counter=$((counter + 1))
    fi
done

echo "Exported $((counter - 1)) screenshots to $OUTPUT_DIR"
```

---

## Troubleshooting

### No Simulator Running

```bash
# Boot a simulator
xcrun simctl boot "iPhone 17 Pro"
open -a Simulator
```

### Test Fails - Element Not Found

1. Check launch arguments are being processed
2. Add `sleep()` calls for UI to settle
3. Use `waitForExistence(timeout:)` before interacting

```swift
let button = app.buttons["MyButton"]
XCTAssertTrue(button.waitForExistence(timeout: 5))
button.tap()
```

### Recording Shows Black Screen

Ensure the app is in the foreground:
```bash
xcrun simctl launch booted com.growfolio.app
sleep 2
xcrun simctl io booted recordVideo output.mp4
```

### Build Errors

Regenerate the Xcode project:
```bash
xcodegen generate
```

---

## File Locations

```
Growfolio/
├── Docs/
│   ├── Screenshots/
│   │   ├── 01-dashboard.png
│   │   ├── ...
│   │   ├── Growfolio-App-Flow.pdf
│   │   └── Videos/
│   │       └── app-flow-demo.mp4
│   └── UI-TESTING-GUIDE.md  ← This file
├── GrowfolioUITests/
│   └── GrowfolioUITests.swift
└── scripts/
    └── capture-flow.sh
```
