#!/bin/bash
set -e

# test-feature-scenarios.sh - Test all scenarios for a dev container feature

FEATURE_NAME=$1
WORKSPACE_DIR=${2:-"$(pwd)"}

show_help() {
    echo "test-feature-scenarios.sh - Test all scenarios for a dev container feature"
    echo ""
    echo "Usage: $0 <feature-name> [workspace-dir]"
    echo ""
    echo "Arguments:"
    echo "  feature-name    Name of the feature to test (required)"
    echo "  workspace-dir   Workspace directory (optional, defaults to current directory)"
    echo ""
    echo "This script will:"
    echo "  - Read scenarios.json for the feature"
    echo "  - Run each scenario in parallel"
    echo "  - Report results for all scenarios"
    echo ""
    echo "Examples:"
    echo "  $0 deal-ii"
    echo "  $0 trilinos /path/to/workspace"
}

if [ -z "$FEATURE_NAME" ] || [ "$FEATURE_NAME" = "--help" ] || [ "$FEATURE_NAME" = "-h" ]; then
    show_help
    exit 0
fi

# Validate feature exists
FEATURE_DIR="$WORKSPACE_DIR/src/$FEATURE_NAME"
TEST_DIR="$WORKSPACE_DIR/test/$FEATURE_NAME"
SCENARIOS_FILE="$TEST_DIR/scenarios.json"

if [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Feature '$FEATURE_NAME' not found in $FEATURE_DIR"
    echo "Available features:"
    ls -1 "$WORKSPACE_DIR/src/" 2>/dev/null || echo "  No features found"
    exit 1
fi

if [ ! -d "$TEST_DIR" ]; then
    echo "ERROR: Test directory '$TEST_DIR' not found"
    exit 1
fi

if [ ! -f "$SCENARIOS_FILE" ]; then
    echo "ERROR: Scenarios file '$SCENARIOS_FILE' not found"
    exit 1
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required but not installed"
    echo "Please install jq: sudo apt-get install jq"
    exit 1
fi

# Check if devcontainer CLI is available
if ! command -v devcontainer >/dev/null 2>&1; then
    echo "ERROR: devcontainer CLI not found. Please install it first:"
    echo "  npm install -g @devcontainers/cli"
    exit 1
fi

echo "Testing feature: $FEATURE_NAME"
echo "Test directory: $TEST_DIR"
echo "Scenarios file: $SCENARIOS_FILE"
echo ""

# Parse scenarios from JSON
SCENARIO_NAMES=$(jq -r 'keys[]' "$SCENARIOS_FILE" 2>/dev/null)

if [ -z "$SCENARIO_NAMES" ]; then
    echo "ERROR: No scenarios found in $SCENARIOS_FILE"
    exit 1
fi

echo "Found scenarios:"
for scenario in $SCENARIO_NAMES; do
    echo "  - $scenario"
done
echo ""

# Create temporary directory for results
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Function to run a single scenario
run_scenario() {
    local scenario=$1
    local result_file="$TEMP_DIR/$scenario.result"
    local log_file="$TEMP_DIR/$scenario.log"

    echo "Starting scenario: $scenario" > "$log_file"

    # Get scenario configuration
    local scenario_config=$(jq ".[\"$scenario\"]" "$SCENARIOS_FILE")
    local base_image=$(echo "$scenario_config" | jq -r '.image // "mcr.microsoft.com/devcontainers/base:ubuntu"')

    echo "Base image: $base_image" >> "$log_file"
    echo "Configuration: $scenario_config" >> "$log_file"
    echo "" >> "$log_file"

    # Check if scenario-specific test script exists
    local scenario_script="$TEST_DIR/$scenario.sh"
    if [ -f "$scenario_script" ]; then
        echo "Running scenario-specific test script: $scenario_script" >> "$log_file"

        # Create temporary devcontainer configuration
        local temp_config_dir="$TEMP_DIR/devcontainer-$scenario"
        mkdir -p "$temp_config_dir"
        echo "$scenario_config" > "$temp_config_dir/devcontainer.json"

        # Change to workspace directory for the test
        cd "$WORKSPACE_DIR"

        # Run the scenario test
        if DEVCONTAINER_CONFIG="$temp_config_dir/devcontainer.json" bash "$scenario_script" >> "$log_file" 2>&1; then
            echo "PASSED" > "$result_file"
            echo "✅ Scenario '$scenario' PASSED" >> "$log_file"
        else
            echo "FAILED" > "$result_file"
            echo "❌ Scenario '$scenario' FAILED" >> "$log_file"
        fi

        # Cleanup
        rm -rf "$temp_config_dir"
    else
        echo "No scenario-specific test script found, using general test with base image" >> "$log_file"

        # Change to workspace directory for the test
        cd "$WORKSPACE_DIR"

        # Run general feature test with the scenario's base image
        if "./scripts/test-feature.sh" "$FEATURE_NAME" "$base_image" >> "$log_file" 2>&1; then
            echo "PASSED" > "$result_file"
            echo "✅ Scenario '$scenario' PASSED (general test)" >> "$log_file"
        else
            echo "FAILED" > "$result_file"
            echo "❌ Scenario '$scenario' FAILED (general test)" >> "$log_file"
        fi
    fi
}

# Start all scenarios in parallel
echo "Running scenarios in parallel..."
for scenario in $SCENARIO_NAMES; do
    run_scenario "$scenario" &
done

# Wait for all scenarios to complete
wait

# Collect and display results
echo ""
echo "=== Scenario Test Results ==="
echo ""

TOTAL_SCENARIOS=0
PASSED_SCENARIOS=0
FAILED_SCENARIOS=0

for scenario in $SCENARIO_NAMES; do
    TOTAL_SCENARIOS=$((TOTAL_SCENARIOS + 1))
    result_file="$TEMP_DIR/$scenario.result"
    log_file="$TEMP_DIR/$scenario.log"

    if [ -f "$result_file" ]; then
        result=$(cat "$result_file")
        if [ "$result" = "PASSED" ]; then
            PASSED_SCENARIOS=$((PASSED_SCENARIOS + 1))
            echo "✅ $scenario: PASSED"
        else
            FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
            echo "❌ $scenario: FAILED"
            echo "   Error details:"
            tail -n 10 "$log_file" | sed 's/^/   /'
        fi
    else
        FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
        echo "❌ $scenario: NO RESULT"
    fi
done

echo ""
echo "=== Summary ==="
echo "Total scenarios: $TOTAL_SCENARIOS"
echo "Passed: $PASSED_SCENARIOS"
echo "Failed: $FAILED_SCENARIOS"

if [ $FAILED_SCENARIOS -eq 0 ]; then
    echo ""
    echo "🎉 All scenarios passed!"
    exit 0
else
    echo ""
    echo "💥 $FAILED_SCENARIOS scenario(s) failed"
    exit 1
fi
