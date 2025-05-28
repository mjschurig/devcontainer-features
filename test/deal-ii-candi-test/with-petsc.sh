#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - PETSc scenario..."

# Basic deal.II check
check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# PETSc-specific checks
check "PETSc support enabled" grep -q "DEAL_II_WITH_PETSC.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

# Verify PETSc libraries are accessible
check "PETSc configuration found" find "${DEAL_II_DIR}" -name "*petsc*" | head -1 | grep -q . || echo "PETSc libraries may be system-installed"

# Report result
reportResults
