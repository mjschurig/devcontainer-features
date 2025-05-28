#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Minimal build scenario..."

# Basic deal.II check
check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Verify basic configuration
check "deal.II config file exists" test -f "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

# Verify headers are installed
check "deal.II headers exist" test -d "${DEAL_II_DIR}/include/deal.II"

# Report result
reportResults
