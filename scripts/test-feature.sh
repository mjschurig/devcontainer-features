#!/bin/bash
set -e

# test-feature.sh - Test individual dev container features locally

FEATURE_NAME=$1
BASE_IMAGE=${2:-"mcr.microsoft.com/devcontainers/base:ubuntu"}
WORKSPACE_DIR=${3:-"$(pwd)"}

show_help() {
    echo "test-feature.sh - Test individual dev container features locally"
    echo ""
    echo "Usage: $0 <feature-name> [base-image] [workspace-dir]"
    echo ""
    echo "Arguments:"
    echo "  feature-name    Name of the feature to test (required)"
    echo "  base-image      Base container image to test against (optional)"
    echo "  workspace-dir   Workspace directory (optional, defaults to current directory)"
    echo ""
    echo "Examples:"
    echo "  $0 hello-world"
    echo "  $0 hello-world mcr.microsoft.com/devcontainers/base:debian"
    echo "  $0 hello-universe mcr.microsoft.com/devcontainers/base:ubuntu"
    echo ""
    echo "Available base images:"
    echo "  mcr.microsoft.com/devcontainers/base:ubuntu"
    echo "  mcr.microsoft.com/devcontainers/base:debian"
    echo "  mcr.microsoft.com/devcontainers/base:alpine"
    echo "  ubuntu:22.04"
    echo "  debian:bullseye"
}

if [ -z "$FEATURE_NAME" ] || [ "$FEATURE_NAME" = "--help" ] || [ "$FEATURE_NAME" = "-h" ]; then
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

echo "Testing feature: $FEATURE_NAME"
echo "Base image: $BASE_IMAGE"
echo "Workspace: $WORKSPACE_DIR"
echo "Feature directory: $FEATURE_DIR"
echo ""

# Check if devcontainer CLI is available
if ! command -v devcontainer >/dev/null 2>&1; then
    echo "ERROR: devcontainer CLI not found. Please install it first:"
    echo "  npm install -g @devcontainers/cli"
    exit 1
fi

# Check if test directory exists
TEST_DIR="$WORKSPACE_DIR/test/$FEATURE_NAME"
if [ -d "$TEST_DIR" ]; then
    echo "Using test directory: $TEST_DIR"
    echo "Project folder: $WORKSPACE_DIR"

    # Check for optional test files
    SCENARIOS_FILE="$TEST_DIR/scenarios.json"
    DUPLICATE_FILE="$TEST_DIR/duplicate.sh"

    if [ -f "$SCENARIOS_FILE" ]; then
        echo "Found scenarios.json - will test multiple scenarios"
    else
        echo "No scenarios.json found - will test default scenario only"
    fi

    if [ -f "$DUPLICATE_FILE" ]; then
        echo "Found duplicate.sh - will test feature idempotency"
    else
        echo "No duplicate.sh found - skipping idempotency test"
    fi
else
    echo "WARNING: No test directory found at $TEST_DIR"
    echo "Running basic feature test without custom tests"
fi

# Run the test
echo ""
echo "Running devcontainer features test..."
echo "Command: devcontainer features test --project-folder $WORKSPACE_DIR --features $FEATURE_NAME --base-image $BASE_IMAGE"
echo ""

if devcontainer features test \
    --project-folder "$WORKSPACE_DIR" \
    --features "$FEATURE_NAME" \
    --base-image "$BASE_IMAGE" \
    --skip-scenarios; then
    echo ""
    echo "✅ Feature test completed successfully!"

else
    echo ""
    echo "❌ Feature test failed!"
    exit 1
fi
