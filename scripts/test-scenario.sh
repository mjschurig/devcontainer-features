#!/bin/bash
set -e

# test-scenario.sh - Test individual scenarios from dev container feature scenarios.json locally

FEATURE_NAME=$1
SCENARIO_NAME=$2
WORKSPACE_DIR=${3:-"$(pwd)"}

show_help() {
    echo "test-scenario.sh - Test individual scenarios from dev container feature scenarios.json locally"
    echo ""
    echo "Usage: $0 <feature-name> <scenario-name> [workspace-dir]"
    echo ""
    echo "Arguments:"
    echo "  feature-name    Name of the feature to test (required)"
    echo "  scenario-name   Name of the scenario from scenarios.json (required)"
    echo "  workspace-dir   Workspace directory (optional, defaults to current directory)"
    echo ""
    echo "Examples:"
    echo "  $0 deal-ii-candi with-trilinos"
    echo "  $0 deal-ii-candi with-petsc"
    echo "  $0 deal-ii-candi with-mpi"
    echo ""
    echo "This script will:"
    echo "  1. Look for test/<feature-name>/scenarios.json"
    echo "  2. Validate the specified scenario exists"
    echo "  3. Run devcontainer features test with scenario filter"
    echo "  4. Run the corresponding test script if it exists"
}

if [ -z "$FEATURE_NAME" ] || [ -z "$SCENARIO_NAME" ] || [ "$FEATURE_NAME" = "--help" ] || [ "$FEATURE_NAME" = "-h" ]; then
    show_help
    exit 0
fi

# Handle help flag in any position
for arg in "$@"; do
    if [ "$arg" = "--help" ] || [ "$arg" = "-h" ]; then
        show_help
        exit 0
    fi
done

# Validate feature exists
FEATURE_DIR="$WORKSPACE_DIR/src/$FEATURE_NAME"
if [ ! -d "$FEATURE_DIR" ]; then
    echo "ERROR: Feature '$FEATURE_NAME' not found in $FEATURE_DIR"
    echo "Available features:"
    ls -1 "$WORKSPACE_DIR/src/" 2>/dev/null || echo "  No features found"
    exit 1
fi

# Validate feature has required files
if [ ! -f "$FEATURE_DIR/devcontainer-feature.json" ]; then
    echo "ERROR: Feature '$FEATURE_NAME' missing devcontainer-feature.json"
    exit 1
fi

if [ ! -f "$FEATURE_DIR/install.sh" ]; then
    echo "ERROR: Feature '$FEATURE_NAME' missing install.sh"
    exit 1
fi

# Check test directory and scenarios.json
TEST_DIR="$WORKSPACE_DIR/test/$FEATURE_NAME"
SCENARIOS_FILE="$TEST_DIR/scenarios.json"

if [ ! -d "$TEST_DIR" ]; then
    echo "ERROR: Test directory not found at $TEST_DIR"
    exit 1
fi

if [ ! -f "$SCENARIOS_FILE" ]; then
    echo "ERROR: scenarios.json not found at $SCENARIOS_FILE"
    echo "This script requires scenarios.json to run specific scenarios"
    exit 1
fi

# Check if jq is available for JSON parsing
if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq not found. Please install jq for JSON parsing:"
    echo "  sudo apt-get install jq  # on Ubuntu/Debian"
    echo "  brew install jq          # on macOS"
    exit 1
fi

# Validate scenario exists in scenarios.json
if ! jq -e ".[\"$SCENARIO_NAME\"]" "$SCENARIOS_FILE" >/dev/null 2>&1; then
    echo "ERROR: Scenario '$SCENARIO_NAME' not found in scenarios.json"
    echo "Available scenarios:"
    jq -r 'keys[]' "$SCENARIOS_FILE" 2>/dev/null || echo "  Could not parse scenarios.json"
    exit 1
fi

# Extract scenario configuration
SCENARIO_IMAGE=$(jq -r ".[\"$SCENARIO_NAME\"].image" "$SCENARIOS_FILE")
SCENARIO_CONFIG=$(jq -c ".[\"$SCENARIO_NAME\"]" "$SCENARIOS_FILE")

echo "Testing feature: $FEATURE_NAME"
echo "Scenario: $SCENARIO_NAME"
echo "Base image: $SCENARIO_IMAGE"
echo "Workspace: $WORKSPACE_DIR"
echo "Feature directory: $FEATURE_DIR"
echo "Test directory: $TEST_DIR"
echo ""

# Check if devcontainer CLI is available
if ! command -v devcontainer >/dev/null 2>&1; then
    echo "ERROR: devcontainer CLI not found. Please install it first:"
    echo "  npm install -g @devcontainers/cli"
    exit 1
fi

echo "Scenario configuration:"
echo "$SCENARIO_CONFIG" | jq .
echo ""

# Check if there's a specific test script for this scenario
SCENARIO_TEST_SCRIPT="$TEST_DIR/$SCENARIO_NAME.sh"
if [ -f "$SCENARIO_TEST_SCRIPT" ]; then
    echo "Found scenario-specific test script: $SCENARIO_TEST_SCRIPT"
else
    echo "No scenario-specific test script found (optional)"
fi

# Run the test using filter to target specific scenario
echo ""
echo "Running devcontainer features test for scenario '$SCENARIO_NAME'..."
echo "Command: devcontainer features test --project-folder $WORKSPACE_DIR --features $FEATURE_NAME --filter $SCENARIO_NAME"
echo ""

if devcontainer features test \
    --project-folder "$WORKSPACE_DIR" \
    --features "$FEATURE_NAME" \
    --filter "$SCENARIO_NAME"; then
    echo ""
    echo "✅ Scenario '$SCENARIO_NAME' test completed successfully!"

    # Run scenario-specific test if it exists
    if [ -f "$SCENARIO_TEST_SCRIPT" ] && [ -x "$SCENARIO_TEST_SCRIPT" ]; then
        echo ""
        echo "Running scenario-specific test script..."
        if "$SCENARIO_TEST_SCRIPT"; then
            echo "✅ Scenario-specific test passed!"
        else
            echo "❌ Scenario-specific test failed!"
            exit 1
        fi
    fi

    echo "✅ All tests for scenario '$SCENARIO_NAME' completed successfully!"
else
    echo ""
    echo "❌ Scenario '$SCENARIO_NAME' test failed!"
    exit 1
fi

