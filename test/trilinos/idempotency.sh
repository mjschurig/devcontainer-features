#!/bin/bash
set -e

# Test idempotency scenario - installation can be run multiple times safely
echo "Testing Trilinos idempotency scenario..."

# Import test utilities first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_UTILS_PATH="$SCRIPT_DIR/../_global/test-utils.sh"

if [ -f "$TEST_UTILS_PATH" ]; then
    source "$TEST_UTILS_PATH"
else
    # Define basic log function if test-utils not available
    log_info() {
        echo "[INFO] $1"
    }
    log_error() {
        echo "[ERROR] $1"
    }
fi

# The idempotency test should validate that the installation is working correctly
# The runTwice logic is handled by the devcontainer framework or GitHub Actions workflow
echo "Running comprehensive installation validation for idempotency scenario..."

# Source the main test script for comprehensive validation
source "$SCRIPT_DIR/test.sh"

echo "✅ Idempotency scenario test completed successfully!"
echo "   Installation appears stable and ready for repeated installations."
