#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - MPI scenario..."

# Basic deal.II check
check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# MPI-specific checks
check "MPI support enabled" grep -q "DEAL_II_WITH_MPI.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

# Verify MPI compilers are available
check "mpicc available" which mpicc
check "mpicxx available" which mpicxx

# Report result
reportResults
