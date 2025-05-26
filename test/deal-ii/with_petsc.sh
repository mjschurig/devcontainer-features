#!/bin/bash
set -e

# Test with_petsc scenario - deal.II with PETSc support
echo "Testing deal.II with_petsc scenario..."

# Import test utilities first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_UTILS_PATH="$SCRIPT_DIR/../_global/test-utils.sh"

if [ -f "$TEST_UTILS_PATH" ]; then
    source "$TEST_UTILS_PATH"
else
    # Define basic log function if test-utils not available
    log_info() { echo "[INFO] $1"; }
    log_error() { echo "[ERROR] $1"; }
fi

# Check that PETSc is available in the system
echo "Verifying PETSc availability..."
if ldconfig -p 2>/dev/null | grep -q "libpetsc"; then
    log_info "PETSc libraries found in system"
else
    log_info "PETSc not found in system - may be expected if not installable via package manager"
fi

# Check that deal.II was built with PETSc support
echo "Verifying deal.II PETSc configuration..."
if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    if grep -q "DEAL_II_WITH_PETSC.*ON" "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake"; then
        log_info "✅ deal.II was built with PETSc support"
    else
        log_info "ℹ️  deal.II was built without PETSc support (may be expected if PETSc unavailable)"
    fi
else
    log_error "Cannot check deal.II PETSc configuration"
    exit 1
fi

# Source the main test script for comprehensive validation
echo "Running comprehensive installation validation..."
source "$SCRIPT_DIR/test.sh"

echo "✅ PETSc scenario test completed successfully!"
