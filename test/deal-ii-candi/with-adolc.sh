#!/bin/bash

set -e

source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - ADOL-C scenario..."

check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Check for ADOL-C support
check "ADOL-C support enabled" grep -q "DEAL_II_WITH_ADOLC.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

reportResults
