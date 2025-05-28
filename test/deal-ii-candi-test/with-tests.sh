#!/bin/bash

set -e

source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Tests scenario..."

check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Check if tests were run (look for test results or logs)
check "Test infrastructure available" test -d "${DEAL_II_DIR}/examples" || echo "Tests may have been run during build"

reportResults
