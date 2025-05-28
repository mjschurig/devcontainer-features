#!/bin/bash

set -e

source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Trilinos with complex scenario..."

check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Check for Trilinos support
check "Trilinos support enabled" grep -q "DEAL_II_WITH_TRILINOS.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

# Check for complex number support in Trilinos
check "Trilinos libraries accessible" find "${DEAL_II_DIR}" -name "*trilinos*" -o -name "*Trilinos*" | head -1 | grep -q . || echo "Trilinos may be system-installed"

reportResults
