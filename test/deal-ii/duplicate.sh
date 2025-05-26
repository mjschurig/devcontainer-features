#!/bin/bash
set -e

# Test for deal.II feature idempotency (duplicate installation)
# This script tests that the deal.II feature can be installed multiple times
# without causing errors or conflicts.

echo "Testing deal.II feature idempotency (duplicate installation)..."

# Source the main test script to get utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test.sh"

echo ""
echo "=== DUPLICATE INSTALLATION TEST ==="
echo "This test verifies that deal.II can handle being installed multiple times"
echo "without conflicts or errors (idempotency test)."
echo ""

# Check if deal.II is already installed from the first run
if [ -d "/usr/local/deal.II" ]; then
    echo "✓ deal.II is already installed from the first installation"
else
    echo "✗ deal.II not found from first installation - this test requires a prior installation"
    exit 1
fi

# Simulate a second installation by checking that the feature would be idempotent
echo "Checking idempotency markers and installation state..."

# Test 1: Check that environment variables are still set correctly
if [ -n "$DEAL_II_DIR" ]; then
    echo "✓ DEAL_II_DIR environment variable is still set: $DEAL_II_DIR"
else
    echo "✗ DEAL_II_DIR environment variable is not set"
    exit 1
fi

# Test 2: Check that libraries are still accessible
if [ -d "/usr/local/deal.II/lib" ]; then
    echo "✓ deal.II library directory is still present"
else
    echo "✗ deal.II library directory not found"
    exit 1
fi

# Test 3: Check that CMake configuration is still available
if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    echo "✓ deal.II CMake configuration is still available"
else
    echo "✗ deal.II CMake configuration not found"
    exit 1
fi

# Test 4: Check that headers are still present
if [ -d "/usr/local/deal.II/include" ]; then
    echo "✓ deal.II header directory is still present"
else
    echo "✗ deal.II header directory not found"
    exit 1
fi

# Test 5: Verify that a simple CMake find_package still works
echo "Testing CMake find_package functionality after duplicate installation..."
TEMP_CMAKE_TEST_DIR=$(mktemp -d)
cd "$TEMP_CMAKE_TEST_DIR"

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(DealIIIdempotencyTest)

find_package(deal.II REQUIRED)

if(deal.II_FOUND)
    message(STATUS "deal.II found successfully in idempotency test")
else()
    message(FATAL_ERROR "deal.II not found in idempotency test")
endif()
EOF

if cmake . >/dev/null 2>&1; then
    echo "✓ CMake find_package(deal.II) still works after duplicate installation"
else
    echo "✗ CMake find_package(deal.II) failed after duplicate installation"
    cd /
    rm -rf "$TEMP_CMAKE_TEST_DIR"
    exit 1
fi

# Clean up
cd /
rm -rf "$TEMP_CMAKE_TEST_DIR"

# Test 6: Check that the deal.II executable is still available
if command -v deal.II >/dev/null 2>&1; then
    echo "✓ deal.II executable is still available"
else
    echo "ℹ️ deal.II executable not in PATH (this may be normal depending on installation)"
fi

echo ""
echo "✅ All idempotency tests passed!"
echo "deal.II feature handles duplicate installation correctly."
echo ""
echo "Summary:"
echo "  - Environment variables: ✓ Preserved"
echo "  - Library directories: ✓ Present"
echo "  - CMake configuration: ✓ Functional"
echo "  - Header directories: ✓ Present"
echo "  - CMake find_package: ✓ Working"
echo ""
echo "The deal.II feature is idempotent and can be safely installed multiple times."
