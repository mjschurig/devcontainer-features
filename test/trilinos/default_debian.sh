#!/bin/bash
set -e

# Test default scenario on Debian base image
echo "Testing Trilinos default scenario on Debian..."

# Source the main test script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test.sh"

echo "✅ Default Debian scenario test completed successfully!"
