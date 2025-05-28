#!/bin/bash

set -e

source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Development tools scenario..."

check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Check if development tools are available
check "numdiff available" which numdiff || echo "numdiff may not be in PATH"
check "astyle available" which astyle || echo "astyle may not be in PATH"

reportResults
