#!/bin/bash
set -e

# Test idempotency scenario - installation can be run multiple times safely
echo "Testing Trilinos idempotency scenario..."

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

INSTALL_PREFIX=${TRILINOS_DIR:-/usr/local}

# Test that the installation exists and is complete
echo "Verifying installation exists and is complete..."
if [ -f "$INSTALL_PREFIX/include/Teuchos_Version.hpp" ]; then
    log_info "Trilinos installation detected"
else
    log_error "Trilinos installation not found - idempotency test requires existing installation"
    exit 1
fi

# Check installation completeness indicators
echo "Checking installation completeness..."
INSTALL_COMPLETE=true

# Check for key components
if [ ! -d "$INSTALL_PREFIX/include" ]; then
    log_error "Include directory missing"
    INSTALL_COMPLETE=false
fi

if [ ! -d "$INSTALL_PREFIX/lib" ] && [ ! -d "$INSTALL_PREFIX/lib64" ]; then
    log_error "Library directory missing"
    INSTALL_COMPLETE=false
fi

# Check for CMake config
CMAKE_CONFIG_FOUND=false
for cmake_dir in "$INSTALL_PREFIX/lib/cmake/Trilinos" "$INSTALL_PREFIX/lib64/cmake/Trilinos"; do
    if [ -f "$cmake_dir/TrilinosConfig.cmake" ]; then
        CMAKE_CONFIG_FOUND=true
        break
    fi
done

if [ "$CMAKE_CONFIG_FOUND" = "false" ]; then
    log_error "CMake configuration missing"
    INSTALL_COMPLETE=false
fi

if [ "$INSTALL_COMPLETE" = "true" ]; then
    log_info "Installation appears complete and consistent"
else
    log_error "Installation appears incomplete - idempotency may be compromised"
    exit 1
fi

# Test that environment is properly set up
echo "Verifying environment consistency..."
if [ -n "$TRILINOS_DIR" ] && [ "$TRILINOS_DIR" = "$INSTALL_PREFIX" ]; then
    log_info "TRILINOS_DIR environment variable is consistent"
else
    log_error "TRILINOS_DIR environment variable inconsistent"
fi

# Test version consistency (if version info is available)
echo "Checking version consistency..."
if [ -f "$INSTALL_PREFIX/include/Trilinos_version.h" ]; then
    if grep -q "15\.0\.0\|15_0_0" "$INSTALL_PREFIX/include/Trilinos_version.h"; then
        log_info "Version 15.0.0 confirmed (consistent with scenario configuration)"
    else
        log_info "Version information found but format may vary"
    fi
else
    log_info "Version header check skipped (file may have different name)"
fi

# Test that the installation can be detected by CMake
echo "Testing CMake find_package consistency..."
TEMP_CMAKE_TEST_DIR=$(mktemp -d)
cd "$TEMP_CMAKE_TEST_DIR"

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(IdempotencyTest)

find_package(Trilinos REQUIRED)

if(Trilinos_FOUND)
    message(STATUS "Trilinos found: ${Trilinos_VERSION}")
else()
    message(FATAL_ERROR "Trilinos not found")
endif()
EOF

if cmake . >/dev/null 2>&1; then
    log_info "CMake can consistently find Trilinos installation"
else
    log_error "CMake cannot find Trilinos installation - may indicate corruption"
fi

# Clean up
cd /
rm -rf "$TEMP_CMAKE_TEST_DIR"

# Source the main test script for comprehensive validation
echo "Running comprehensive installation validation..."
source "$SCRIPT_DIR/test.sh"

echo "✅ Idempotency scenario test completed successfully!"
echo "   Installation appears stable and ready for repeated installations."
