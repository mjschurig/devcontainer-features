#!/bin/bash

set -e

source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Full build scenario..."

check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Check key features from the full build
check "deal.II config file exists" test -f "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"
check "64-bit indices enabled" grep -q "DEAL_II_WITH_64BIT_INDICES.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"
check "Trilinos support enabled" grep -q "DEAL_II_WITH_TRILINOS.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"
check "PETSc support enabled" grep -q "DEAL_II_WITH_PETSC.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"
check "p4est support enabled" grep -q "DEAL_II_WITH_P4EST.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"
check "HDF5 support enabled" grep -q "DEAL_II_WITH_HDF5.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

# Check development tools
check "Git available" which git
check "CMake available" which cmake

reportResults
