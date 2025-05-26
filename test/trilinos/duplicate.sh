#!/bin/bash
set -e

# Test for trilinos feature idempotency (duplicate installation)
# This script tests that the trilinos feature can be installed multiple times
# without causing errors or conflicts.

echo "Testing Trilinos feature idempotency (duplicate installation)..."

# Source the main test script to get utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test.sh"

echo ""
echo "=== DUPLICATE INSTALLATION TEST ==="
echo "This test verifies that Trilinos can handle being installed multiple times"
echo "without conflicts or errors (idempotency test)."
echo ""

# Check if Trilinos is already installed from the first run
if [ -f "$INSTALLPREFIX/include/Teuchos_Version.hpp" ]; then
    echo "✓ Trilinos is already installed from the first installation"
else
    echo "✗ Trilinos not found from first installation - this test requires a prior installation"
    exit 1
fi

# Simulate a second installation by checking that the feature would be idempotent
echo "Checking idempotency markers and installation state..."

# Test 1: Check that environment variables are still set correctly
if [ -n "$TRILINOS_DIR" ]; then
    echo "✓ TRILINOS_DIR environment variable is still set: $TRILINOS_DIR"
else
    echo "✗ TRILINOS_DIR environment variable is not set"
    exit 1
fi

# Test 2: Check that libraries are still accessible
if [ -d "$INSTALLPREFIX/lib" ] || [ -d "$INSTALLPREFIX/lib64" ]; then
    echo "✓ Trilinos library directories are still present"
else
    echo "✗ Trilinos library directories not found"
    exit 1
fi

# Test 3: Check that CMake configuration is still available
CMAKE_CONFIG_FOUND=false
for cmake_dir in "$INSTALLPREFIX/lib/cmake/Trilinos" "$INSTALLPREFIX/lib64/cmake/Trilinos" "$INSTALLPREFIX/share/cmake/Trilinos"; do
    if [ -f "$cmake_dir/TrilinosConfig.cmake" ]; then
        echo "✓ Trilinos CMake configuration is still available: $cmake_dir/TrilinosConfig.cmake"
        CMAKE_CONFIG_FOUND=true
        break
    fi
done

if [ "$CMAKE_CONFIG_FOUND" = "false" ]; then
    echo "✗ Trilinos CMake configuration not found"
    exit 1
fi

# Test 4: Check that the environment script is still functional
ENV_SCRIPT="$INSTALLPREFIX/bin/trilinos-env.sh"
if [ -f "$ENV_SCRIPT" ] && [ -x "$ENV_SCRIPT" ]; then
    if bash -c "source '$ENV_SCRIPT' && echo 'Environment script still works'" >/dev/null 2>&1; then
        echo "✓ Trilinos environment script is still functional"
    else
        echo "✗ Trilinos environment script is not functional"
        exit 1
    fi
else
    echo "✗ Trilinos environment script not found or not executable"
    exit 1
fi

# Test 5: Verify that a simple CMake find_package still works
echo "Testing CMake find_package functionality after duplicate installation..."
TEMP_CMAKE_TEST_DIR=$(mktemp -d)
cd "$TEMP_CMAKE_TEST_DIR"

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(TrilinosIdempotencyTest)

find_package(Trilinos REQUIRED)

if(Trilinos_FOUND)
    message(STATUS "Trilinos found successfully in idempotency test")
else()
    message(FATAL_ERROR "Trilinos not found in idempotency test")
endif()
EOF

if cmake . >/dev/null 2>&1; then
    echo "✓ CMake find_package(Trilinos) still works after duplicate installation"
else
    echo "✗ CMake find_package(Trilinos) failed after duplicate installation"
    cd /
    rm -rf "$TEMP_CMAKE_TEST_DIR"
    exit 1
fi

# Clean up
cd /
rm -rf "$TEMP_CMAKE_TEST_DIR"

echo ""
echo "✅ All idempotency tests passed!"
echo "Trilinos feature handles duplicate installation correctly."
echo ""
echo "Summary:"
echo "  - Environment variables: ✓ Preserved"
echo "  - Library directories: ✓ Present"
echo "  - CMake configuration: ✓ Functional"
echo "  - Environment script: ✓ Functional"
echo "  - CMake find_package: ✓ Working"
echo ""
echo "The Trilinos feature is idempotent and can be safely installed multiple times."
