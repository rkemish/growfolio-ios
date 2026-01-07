#!/bin/bash

# Growfolio iOS - Simulator Flow Capture Script
# Records video of the app running in the simulator
#
# Usage:
#   ./scripts/capture-flow.sh [flow-name] [duration]
#
# Examples:
#   ./scripts/capture-flow.sh                    # Interactive mode
#   ./scripts/capture-flow.sh full-walkthrough   # Record with name
#   ./scripts/capture-flow.sh dashboard 30       # Record for 30 seconds

set -e

# Configuration
OUTPUT_DIR="Growfolio/Docs/Screenshots/Videos"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Functions
print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Growfolio iOS - Flow Capture Tool        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
}

get_booted_simulator() {
    xcrun simctl list devices booted -j | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for device in devices:
        if device.get('state') == 'Booted':
            print(device['udid'])
            sys.exit(0)
" 2>/dev/null
}

list_available_simulators() {
    echo -e "${YELLOW}Available simulators:${NC}"
    xcrun simctl list devices available | grep -E "iPhone|iPad" | head -10
}

boot_simulator() {
    local sim_name="$1"
    echo -e "${BLUE}Booting simulator: $sim_name${NC}"
    xcrun simctl boot "$sim_name" 2>/dev/null || true
    open -a Simulator
    sleep 3
}

start_recording() {
    local udid="$1"
    local output_file="$2"

    echo -e "${GREEN}Recording started...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop recording${NC}"
    echo ""

    # Record video (H.264 codec for compatibility)
    xcrun simctl io "$udid" recordVideo --codec h264 "$output_file"
}

timed_recording() {
    local udid="$1"
    local output_file="$2"
    local duration="$3"

    echo -e "${GREEN}Recording for $duration seconds...${NC}"

    # Start recording in background
    xcrun simctl io "$udid" recordVideo --codec h264 "$output_file" &
    local record_pid=$!

    # Wait for duration
    sleep "$duration"

    # Stop recording
    kill -INT "$record_pid" 2>/dev/null || true
    wait "$record_pid" 2>/dev/null || true

    echo -e "${GREEN}Recording stopped.${NC}"
}

run_ui_test_with_recording() {
    local udid="$1"
    local output_file="$2"
    local test_name="$3"

    echo -e "${BLUE}Running UI test: $test_name${NC}"
    echo -e "${GREEN}Recording started...${NC}"

    # Start recording in background
    xcrun simctl io "$udid" recordVideo --codec h264 "$output_file" &
    local record_pid=$!

    # Run the UI test
    xcodebuild test \
        -project Growfolio.xcodeproj \
        -scheme Growfolio \
        -destination "platform=iOS Simulator,id=$udid" \
        -only-testing:"GrowfolioUITests/$test_name" \
        2>&1 | grep -E "(Test Case|passed|failed|error:)" || true

    # Give a moment for any final animations
    sleep 2

    # Stop recording
    kill -INT "$record_pid" 2>/dev/null || true
    wait "$record_pid" 2>/dev/null || true

    echo -e "${GREEN}Recording stopped.${NC}"
}

convert_to_gif() {
    local input_file="$1"
    local output_file="${input_file%.mp4}.gif"

    if command -v ffmpeg &> /dev/null; then
        echo -e "${BLUE}Converting to GIF...${NC}"
        ffmpeg -i "$input_file" \
            -vf "fps=10,scale=320:-1:flags=lanczos" \
            -c:v gif \
            -y "$output_file" 2>/dev/null
        echo -e "${GREEN}GIF created: $output_file${NC}"
    else
        echo -e "${YELLOW}ffmpeg not found - skipping GIF conversion${NC}"
        echo "Install with: brew install ffmpeg"
    fi
}

# Main script
print_header

# Get flow name
FLOW_NAME="${1:-}"
DURATION="${2:-}"

if [ -z "$FLOW_NAME" ]; then
    echo -e "${YELLOW}Available capture modes:${NC}"
    echo "  1) Manual recording (press Ctrl+C to stop)"
    echo "  2) Timed recording (specify duration)"
    echo "  3) Record UI test execution"
    echo ""
    read -p "Select mode (1-3): " MODE

    read -p "Enter flow name (e.g., 'dashboard', 'full-walkthrough'): " FLOW_NAME
    FLOW_NAME="${FLOW_NAME:-recording}"

    if [ "$MODE" = "2" ]; then
        read -p "Enter duration in seconds: " DURATION
    elif [ "$MODE" = "3" ]; then
        echo ""
        echo -e "${YELLOW}Available UI tests:${NC}"
        echo "  - FullAppWalkthroughTests/testFullAppWalkthrough"
        echo "  - MainAppFlowTests/testAllTabsSequence"
        echo "  - OnboardingFlowTests/testOnboardingFlow"
        echo "  - StockDetailFlowTests/testStockDetailAndBuyFlow"
        echo ""
        read -p "Enter test name: " TEST_NAME
    fi
else
    MODE="1"
fi

# Generate output filename with timestamp
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
OUTPUT_FILE="$OUTPUT_DIR/${FLOW_NAME}-${TIMESTAMP}.mp4"

# Check for booted simulator
SIMULATOR_UDID=$(get_booted_simulator)

if [ -z "$SIMULATOR_UDID" ]; then
    echo -e "${YELLOW}No simulator running.${NC}"
    list_available_simulators
    echo ""
    read -p "Enter simulator name to boot (or press Enter for 'iPhone 17 Pro'): " SIM_NAME
    SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"
    boot_simulator "$SIM_NAME"
    SIMULATOR_UDID=$(get_booted_simulator)

    if [ -z "$SIMULATOR_UDID" ]; then
        echo -e "${RED}Failed to boot simulator${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Using simulator: $SIMULATOR_UDID${NC}"
echo -e "${BLUE}Output file: $OUTPUT_FILE${NC}"
echo ""

# Ensure app is installed and running
echo -e "${BLUE}Building and installing app...${NC}"
xcodebuild -project Growfolio.xcodeproj \
    -scheme Growfolio \
    -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
    -configuration Debug \
    build 2>&1 | grep -E "(BUILD|error:)" || true

# Launch app with mock mode
echo -e "${BLUE}Launching app in mock mode...${NC}"
xcrun simctl terminate "$SIMULATOR_UDID" com.growfolio.app 2>/dev/null || true
xcrun simctl launch "$SIMULATOR_UDID" com.growfolio.app --args --mock-mode --skip-to-main
sleep 2

# Record based on mode
case "$MODE" in
    1)
        # Manual recording
        trap "echo ''; echo -e '${GREEN}Recording saved to: $OUTPUT_FILE${NC}'" EXIT
        start_recording "$SIMULATOR_UDID" "$OUTPUT_FILE"
        ;;
    2)
        # Timed recording
        timed_recording "$SIMULATOR_UDID" "$OUTPUT_FILE" "$DURATION"
        ;;
    3)
        # UI test recording
        run_ui_test_with_recording "$SIMULATOR_UDID" "$OUTPUT_FILE" "$TEST_NAME"
        ;;
esac

echo ""
echo -e "${GREEN}✓ Recording saved to: $OUTPUT_FILE${NC}"

# Offer GIF conversion
if [ -f "$OUTPUT_FILE" ]; then
    read -p "Convert to GIF? (y/n): " CONVERT_GIF
    if [ "$CONVERT_GIF" = "y" ] || [ "$CONVERT_GIF" = "Y" ]; then
        convert_to_gif "$OUTPUT_FILE"
    fi
fi

echo ""
echo -e "${BLUE}Done!${NC}"
