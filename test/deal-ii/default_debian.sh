#!/bin/bash
set -e

# Test default_debian scenario - basic installation on Debian
echo "Testing deal.II default_debian scenario..."

# Source the main test script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test.sh"

echo "✅ Default Debian scenario test completed successfully!"
