#!/bin/bash

set -e

source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Gmsh scenario..."

check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Check for Gmsh support
check "Gmsh support enabled" grep -q "DEAL_II_WITH_GMSH.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

# Verify Gmsh executable is available
check "Gmsh executable available" which gmsh || echo "Gmsh may be library-only installation"

reportResults
