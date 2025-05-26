#!/bin/bash
set -e

# Test with_trilinos scenario - deal.II with Trilinos support
echo "Testing deal.II with_trilinos scenario..."

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

# Check that Trilinos is available
echo "Verifying Trilinos availability..."
if [ -d "/usr/local/trilinos" ]; then
    log_info "✅ Trilinos installation found at /usr/local/trilinos"

    # Check TRILINOS_DIR environment variable
    if [ -n "$TRILINOS_DIR" ]; then
        log_info "✅ TRILINOS_DIR environment variable is set: $TRILINOS_DIR"
    else
        log_error "TRILINOS_DIR environment variable not set"
        exit 1
    fi
else
    log_error "Trilinos installation not found - required for this scenario"
    exit 1
fi

# Check that deal.II was built with Trilinos support
echo "Verifying deal.II Trilinos configuration..."
if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    if grep -q "DEAL_II_WITH_TRILINOS.*ON" "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake"; then
        log_info "✅ deal.II was built with Trilinos support"
    else
        log_error "deal.II was not built with Trilinos support"
        exit 1
    fi
else
    log_error "Cannot check deal.II Trilinos configuration"
    exit 1
fi

# Check that MPI was automatically enabled (required by Trilinos)
echo "Verifying MPI was automatically enabled..."
if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    if grep -q "DEAL_II_WITH_MPI.*ON" "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake"; then
        log_info "✅ MPI was automatically enabled (required by Trilinos)"
    else
        log_error "MPI was not enabled - required when using Trilinos"
        exit 1
    fi
fi

# Test Trilinos CMake integration
echo "Testing Trilinos CMake integration..."
TEMP_CMAKE_TEST_DIR=$(mktemp -d)
cd "$TEMP_CMAKE_TEST_DIR"

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(TrilinosIntegrationTest)

find_package(Trilinos REQUIRED)
find_package(deal.II REQUIRED)

if(Trilinos_FOUND AND deal.II_FOUND)
    message(STATUS "Both Trilinos and deal.II found successfully")
else()
    message(FATAL_ERROR "Failed to find required packages")
endif()
EOF

if cmake . >/dev/null 2>&1; then
    log_info "✅ CMake can find both Trilinos and deal.II"
else
    log_error "CMake failed to find Trilinos and deal.II integration"
    cd /
    rm -rf "$TEMP_CMAKE_TEST_DIR"
    exit 1
fi

# Clean up
cd /
rm -rf "$TEMP_CMAKE_TEST_DIR"

# Source the main test script for comprehensive validation
echo "Running comprehensive installation validation..."
source "$SCRIPT_DIR/test.sh"

echo "✅ Trilinos scenario test completed successfully!"
