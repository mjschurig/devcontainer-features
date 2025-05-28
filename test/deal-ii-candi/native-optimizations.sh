#!/bin/bash

set -e

source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Native optimizations scenario..."

check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Check for optimized build
check "deal.II config file exists" test -f "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

reportResults
