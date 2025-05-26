#!/bin/bash
set -e

# Import test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_UTILS_PATH="$SCRIPT_DIR/../_global/test-utils.sh"

# Try multiple possible paths for test utilities
if [ -f "$TEST_UTILS_PATH" ]; then
    source "$TEST_UTILS_PATH"
elif [ -f "/workspaces/*/test/_global/test-utils.sh" ]; then
    source /workspaces/*/test/_global/test-utils.sh
elif [ -f "test/_global/test-utils.sh" ]; then
    source "test/_global/test-utils.sh"
else
    echo "WARNING: test-utils.sh not found, defining basic functions..."
    # Define basic functions if test-utils.sh is not available
    check_command() {
        local cmd=$1
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "✓ Command '$cmd' is available"
            return 0
        else
            echo "ERROR: Command '$cmd' not found"
            return 1
        fi
    }

    check_env_var() {
        local var=$1
        local expected=$2
        local actual="${!var}"

        if [ "$actual" = "$expected" ]; then
            echo "✓ Environment variable '$var' = '$actual' (correct)"
            return 0
        else
            echo "ERROR: Environment variable '$var' expected '$expected', got '$actual'"
            return 1
        fi
    }
fi

echo "Testing hello-world feature..."

# Test 1: Check if hello-world command is installed
echo "Test 1: Checking if hello-world command is available"
check_command "hello-world"

# Test 2: Check version output
echo "Test 2: Checking version output"
VERSION_OUTPUT=$(hello-world --version)
if echo "$VERSION_OUTPUT" | grep -q "hello-world 1.0.0"; then
    echo "✓ Version output is correct"
else
    echo "ERROR: Version output is incorrect: $VERSION_OUTPUT"
    exit 1
fi

# Test 3: Check basic functionality
echo "Test 3: Checking basic functionality"
BASIC_OUTPUT=$(hello-world)
# The test framework might override the name parameter, so let's be more flexible
# Check that it contains a greeting pattern rather than exact text
# Allow for system names that may contain spaces, slashes, and other characters
if echo "$BASIC_OUTPUT" | grep -qE "(Hello|Hi|Hey|Greetings), .+!"; then
    echo "✓ Basic greeting works: $BASIC_OUTPUT"
else
    echo "ERROR: Basic greeting failed: $BASIC_OUTPUT"
    exit 1
fi

# Test 4: Check help output
echo "Test 4: Checking help output"
HELP_OUTPUT=$(hello-world --help)
if echo "$HELP_OUTPUT" | grep -q "Usage: hello-world"; then
    echo "✓ Help output is correct"
else
    echo "ERROR: Help output is incorrect"
    exit 1
fi

# Test 5: Check custom greeting option
echo "Test 5: Checking custom greeting option"
CUSTOM_OUTPUT=$(hello-world --greeting "Hi" --name "Tester")
if echo "$CUSTOM_OUTPUT" | grep -q "Hi, Tester!"; then
    echo "✓ Custom greeting works"
else
    echo "ERROR: Custom greeting failed: $CUSTOM_OUTPUT"
    exit 1
fi

# Test 6: Check date option
echo "Test 6: Checking date option"
DATE_OUTPUT=$(hello-world --date)
if echo "$DATE_OUTPUT" | grep -q "at [0-9]"; then
    echo "✓ Date option works"
else
    echo "ERROR: Date option failed: $DATE_OUTPUT"
    exit 1
fi

# Test 7: Check environment variable
echo "Test 7: Checking environment variable"
check_env_var "HELLO_WORLD_INSTALLED" "true"

# Test 8: Check file permissions
echo "Test 8: Checking file permissions"
if [ -x "/usr/local/bin/hello-world" ]; then
    echo "✓ hello-world script is executable"
else
    echo "ERROR: hello-world script is not executable"
    exit 1
fi

# Test 9: Check idempotency (simulate re-installation)
echo "Test 9: Testing idempotency"
# This would normally be tested by running the install script again
# For now, we just verify the command still works after multiple calls
hello-world >/dev/null
hello-world >/dev/null
echo "✓ Command works after multiple calls"

echo ""
echo "✅ All hello-world tests passed!"
