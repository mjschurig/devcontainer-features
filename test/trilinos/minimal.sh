#!/bin/bash
set -e

# Test minimal scenario - core packages only, most features disabled
echo "Testing Trilinos minimal scenario..."

# Import test utilities first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_UTILS_PATH="$SCRIPT_DIR/../_global/test-utils.sh"

if [ -f "$TEST_UTILS_PATH" ]; then
    source "$TEST_UTILS_PATH"
else
    # Define basic log function if test-utils not available
    log_info() {
        echo "[INFO] $1"
    }
    log_error() {
        echo "[ERROR] $1"
    }
fi

# Test that MPI is not installed/available when disabled
echo "Verifying MPI is disabled..."
if command -v mpicc >/dev/null 2>&1; then
    log_error "MPI compiler found but should be disabled in minimal scenario"
    exit 1
else
    log_info "MPI correctly disabled"
fi

# Test that optional packages are disabled
echo "Verifying optional packages are disabled..."
INSTALL_PREFIX=${TRILINOS_DIR:-/usr/local}

# Kokkos should be disabled
if find "$INSTALL_PREFIX" -name "*kokkos*" -type f 2>/dev/null | grep -q .; then
    log_error "Kokkos found but should be disabled in minimal scenario"
else
    log_info "Kokkos correctly disabled"
fi

# Tpetra should be disabled
if find "$INSTALL_PREFIX" -name "*tpetra*" -type f 2>/dev/null | grep -q .; then
    log_error "Tpetra found but should be disabled in minimal scenario"
else
    log_info "Tpetra correctly disabled"
fi

# Source the main test script for common tests
source "$SCRIPT_DIR/test.sh"

echo "✅ Minimal scenario test completed successfully!"
