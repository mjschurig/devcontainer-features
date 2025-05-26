#!/bin/bash
set -e

# test-all.sh - Test all dev container features against multiple base images

WORKSPACE_DIR=${1:-"$(pwd)"}
PARALLEL=${2:-"false"}

# Default base images to test against
DEFAULT_BASE_IMAGES=(
    "mcr.microsoft.com/devcontainers/base:ubuntu"
    "mcr.microsoft.com/devcontainers/base:debian"
    "ubuntu:22.04"
    "debian:bullseye"
)

show_help() {
    echo "test-all.sh - Test all dev container features against multiple base images"
    echo ""
    echo "Usage: $0 [workspace-dir] [parallel]"
    echo ""
    echo "Arguments:"
    echo "  workspace-dir   Workspace directory (optional, defaults to current directory)"
    echo "  parallel        Run tests in parallel (true/false, defaults to false)"
    echo ""
    echo "Environment Variables:"
    echo "  BASE_IMAGES     Comma-separated list of base images to test against"
    echo "  FEATURES        Comma-separated list of specific features to test"
    echo "  SKIP_FEATURES   Comma-separated list of features to skip"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 /path/to/workspace true"
    echo "  BASE_IMAGES='ubuntu:22.04,debian:bullseye' $0"
    echo "  FEATURES='hello-world,hello-universe' $0"
    echo "  SKIP_FEATURES='hello-universe' $0"
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

echo "Testing all dev container features..."
echo "Workspace: $WORKSPACE_DIR"
echo "Parallel execution: $PARALLEL"
echo ""

# Check if devcontainer CLI is available
if ! command -v devcontainer >/dev/null 2>&1; then
    echo "ERROR: devcontainer CLI not found. Please install it first:"
    echo "  npm install -g @devcontainers/cli"
    exit 1
fi

# Parse base images
if [ -n "$BASE_IMAGES" ]; then
    IFS=',' read -ra IMAGES <<< "$BASE_IMAGES"
else
    IMAGES=("${DEFAULT_BASE_IMAGES[@]}")
fi

echo "Base images to test:"
for image in "${IMAGES[@]}"; do
    echo "  - $image"
done
echo ""

# Discover features
SRC_DIR="$WORKSPACE_DIR/src"
if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: Source directory not found: $SRC_DIR"
    exit 1
fi

# Get list of features
if [ -n "$FEATURES" ]; then
    IFS=',' read -ra FEATURE_LIST <<< "$FEATURES"
else
    FEATURE_LIST=()
    for feature_dir in "$SRC_DIR"/*; do
        if [ -d "$feature_dir" ]; then
            feature_name=$(basename "$feature_dir")
            FEATURE_LIST+=("$feature_name")
        fi
    done
fi

# Filter out skipped features
if [ -n "$SKIP_FEATURES" ]; then
    IFS=',' read -ra SKIP_LIST <<< "$SKIP_FEATURES"
    FILTERED_FEATURES=()
    for feature in "${FEATURE_LIST[@]}"; do
        skip=false
        for skip_feature in "${SKIP_LIST[@]}"; do
            if [ "$feature" = "$skip_feature" ]; then
                skip=true
                break
            fi
        done
        if [ "$skip" = false ]; then
            FILTERED_FEATURES+=("$feature")
        fi
    done
    FEATURE_LIST=("${FILTERED_FEATURES[@]}")
fi

echo "Features to test:"
for feature in "${FEATURE_LIST[@]}"; do
    echo "  - $feature"
done
echo ""

# Validate features exist
for feature in "${FEATURE_LIST[@]}"; do
    feature_dir="$SRC_DIR/$feature"
    if [ ! -d "$feature_dir" ]; then
        echo "ERROR: Feature directory not found: $feature_dir"
        exit 1
    fi
    if [ ! -f "$feature_dir/devcontainer-feature.json" ]; then
        echo "ERROR: Feature '$feature' missing devcontainer-feature.json"
        exit 1
    fi
    if [ ! -f "$feature_dir/install.sh" ]; then
        echo "ERROR: Feature '$feature' missing install.sh"
        exit 1
    fi
done

# Test execution functions
run_test() {
    local feature=$1
    local image=$2
    local test_name="$feature-$image"
    
    echo "Testing $feature against $image..."
    
    if "$WORKSPACE_DIR/scripts/test-feature.sh" "$feature" "$image" "$WORKSPACE_DIR"; then
        echo "✅ $test_name: PASSED"
        return 0
    else
        echo "❌ $test_name: FAILED"
        return 1
    fi
}

# Results tracking
declare -a RESULTS
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Run tests
if [ "$PARALLEL" = "true" ]; then
    echo "Running tests in parallel..."
    echo ""
    
    # Create temporary directory for results
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT
    
    # Start all tests in background
    for feature in "${FEATURE_LIST[@]}"; do
        for image in "${IMAGES[@]}"; do
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
            test_name="$feature-$(echo "$image" | tr '/' '-' | tr ':' '-')"
            result_file="$TEMP_DIR/$test_name.result"
            
            (
                if run_test "$feature" "$image" > "$result_file.log" 2>&1; then
                    echo "PASSED" > "$result_file"
                else
                    echo "FAILED" > "$result_file"
                fi
            ) &
        done
    done
    
    # Wait for all tests to complete
    wait
    
    # Collect results
    for feature in "${FEATURE_LIST[@]}"; do
        for image in "${IMAGES[@]}"; do
            test_name="$feature-$(echo "$image" | tr '/' '-' | tr ':' '-')"
            result_file="$TEMP_DIR/$test_name.result"
            log_file="$TEMP_DIR/$test_name.result.log"
            
            if [ -f "$result_file" ]; then
                result=$(cat "$result_file")
                if [ "$result" = "PASSED" ]; then
                    PASSED_TESTS=$((PASSED_TESTS + 1))
                    echo "✅ $feature against $image: PASSED"
                else
                    FAILED_TESTS=$((FAILED_TESTS + 1))
                    echo "❌ $feature against $image: FAILED"
                    if [ -f "$log_file" ]; then
                        echo "   Log output:"
                        sed 's/^/   /' "$log_file"
                    fi
                fi
                RESULTS+=("$feature|$image|$result")
            else
                FAILED_TESTS=$((FAILED_TESTS + 1))
                echo "❌ $feature against $image: NO RESULT"
                RESULTS+=("$feature|$image|NO_RESULT")
            fi
        done
    done
else
    echo "Running tests sequentially..."
    echo ""
    
    for feature in "${FEATURE_LIST[@]}"; do
        for image in "${IMAGES[@]}"; do
            TOTAL_TESTS=$((TOTAL_TESTS + 1))
            
            echo "=== Test $TOTAL_TESTS: $feature against $image ==="
            
            if run_test "$feature" "$image"; then
                PASSED_TESTS=$((PASSED_TESTS + 1))
                RESULTS+=("$feature|$image|PASSED")
            else
                FAILED_TESTS=$((FAILED_TESTS + 1))
                RESULTS+=("$feature|$image|FAILED")
            fi
            
            echo ""
        done
    done
fi

# Print summary
echo ""
echo "=== Test Summary ==="
echo "Total tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "❌ $FAILED_TESTS test(s) failed"
    echo ""
    echo "Failed tests:"
    for result in "${RESULTS[@]}"; do
        IFS='|' read -r feature image status <<< "$result"
        if [ "$status" != "PASSED" ]; then
            echo "  - $feature against $image: $status"
        fi
    done
    exit 1
fi 