#!/bin/bash

set -e

source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - No cleanup scenario..."

check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Check if build artifacts might still exist (no cleanup scenario)
check "Candi directory exists" test -d "/tmp/candi" || echo "Candi build directory may have been cleaned up"

reportResults
