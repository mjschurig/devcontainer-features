#!/bin/bash
set -e

# Test no MPI scenario - MPI disabled, Zoltan packages disabled
echo "Testing Trilinos no MPI scenario..."

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

# Test that MPI is disabled
echo "Verifying MPI is disabled..."
if command -v mpicc >/dev/null 2>&1; then
    log_error "MPI compiler found but should be disabled in no_mpi scenario"
    exit 1
else
    log_info "MPI correctly disabled"
fi

if command -v mpirun >/dev/null 2>&1; then
    log_error "MPI runtime found but should be disabled in no_mpi scenario"
    exit 1
else
    log_info "MPI runtime correctly disabled"
fi

# Test that Zoltan packages are disabled (depend on MPI)
echo "Verifying Zoltan packages are disabled..."
INSTALL_PREFIX=${TRILINOS_DIR:-/usr/local}

# Zoltan should be disabled
if find "$INSTALL_PREFIX" -name "*zoltan*" -o -name "*Zoltan*" 2>/dev/null | grep -q .; then
    log_error "Zoltan found but should be disabled when MPI is disabled"
else
    log_info "Zoltan correctly disabled"
fi

# Zoltan2 should be disabled
if find "$INSTALL_PREFIX" -name "*zoltan2*" -o -name "*Zoltan2*" 2>/dev/null | grep -q .; then
    log_error "Zoltan2 found but should be disabled when MPI is disabled"
else
    log_info "Zoltan2 correctly disabled"
fi

# Verify base system
echo "Verifying base system..."
if [ -f /etc/os-release ]; then
    OS_NAME=$(grep "^NAME=" /etc/os-release | cut -d'"' -f2)
    log_info "Running on: $OS_NAME"
else
    log_info "OS release info not available"
fi

# Source the main test script for common tests
source "$SCRIPT_DIR/test.sh"

echo "✅ No MPI scenario test completed successfully!"
