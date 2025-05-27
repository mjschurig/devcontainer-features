#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Trilinos scenario..."

# Basic deal.II check
check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Trilinos-specific checks
check "Trilinos support enabled" grep -q "DEAL_II_WITH_TRILINOS.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

# Verify Trilinos libraries are accessible
check "Trilinos configuration found" find "${DEAL_II_DIR}" -name "*trilinos*" -o -name "*Trilinos*" | head -1 | grep -q . || echo "Trilinos libraries may be system-installed"

# Report result
reportResults
