#!/bin/bash
set -e

# Test default scenario - all features enabled with default options
echo "Testing Trilinos default scenario..."

# Source the main test script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test.sh"

echo "✅ Default scenario test completed successfully!"
