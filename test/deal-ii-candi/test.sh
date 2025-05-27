#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - basic installation..."

# Basic installation check
check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Environment variables check
check "DEAL_II_DIR is set" test -n "$DEAL_II_DIR"

# Core files check
check "deal.II CMake config exists" test -f "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"
check "deal.II headers exist" test -f "${DEAL_II_DIR}/include/deal.II/base/config.h"

# Library files check
check "deal.II library files exist" find "${DEAL_II_DIR}/lib" -name "libdeal_II*" | head -1 | grep -q .

# Report result
reportResults
