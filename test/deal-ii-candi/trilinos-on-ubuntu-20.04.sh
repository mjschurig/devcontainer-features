#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Minimal build on Ubuntu 20.04..."

# Basic deal.II check
check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Verify basic configuration
check "deal.II config file exists" test -f "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

# Verify headers are installed
check "deal.II headers exist" test -d "${DEAL_II_DIR}/include/deal.II"

# Ubuntu 20.04 specific checks
echo "🔍 Running Ubuntu 20.04 specific compatibility checks..."

# Check if system packages were used as fallbacks (expected on Ubuntu 20.04)
check "System CMake available" which cmake

# Verify deal.II can find basic dependencies
check "deal.II can find CMake" grep -q "CMAKE_COMMAND" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

# Check for known Ubuntu 20.04 compatibility workarounds
echo "📋 Checking for Ubuntu 20.04 compatibility workarounds..."

# Verify environment variables are set correctly
check "DEAL_II_DIR environment variable" test -n "${DEAL_II_DIR}"
check "CMAKE_PREFIX_PATH includes deal.II" echo "${CMAKE_PREFIX_PATH}" | grep -q "${DEAL_II_DIR}"

# Test basic compilation capability
echo "🔨 Testing basic compilation capability..."
cat > /tmp/test_dealii.cpp << 'EOF'
#include <deal.II/base/config.h>
#include <iostream>

int main() {
    std::cout << "deal.II version: " << DEAL_II_PACKAGE_VERSION << std::endl;
    return 0;
}
EOF

# Try to compile a simple deal.II program
if command -v g++ >/dev/null 2>&1; then
    check "Basic deal.II compilation test" g++ -I"${DEAL_II_DIR}/include" /tmp/test_dealii.cpp -o /tmp/test_dealii
    check "Basic deal.II execution test" /tmp/test_dealii
    rm -f /tmp/test_dealii /tmp/test_dealii.cpp
else
    echo "⚠️ g++ not available, skipping compilation test"
fi

# Check for Ubuntu 20.04 specific issues mentioned in documentation
echo "🔍 Checking for known Ubuntu 20.04 issues..."

# Check if Trilinos was installed via system packages (expected fallback)
if dpkg -l | grep -q trilinos; then
    echo "✅ Trilinos system packages detected (expected fallback on Ubuntu 20.04)"
else
    echo "ℹ️ No Trilinos system packages found (may be using candi build)"
fi

# Check if PETSc was installed via system packages (expected fallback)
if dpkg -l | grep -q petsc; then
    echo "✅ PETSc system packages detected (expected fallback on Ubuntu 20.04)"
else
    echo "ℹ️ No PETSc system packages found (may be using candi build)"
fi

# Verify no obvious build artifacts remain (cleanup check)
check "Build directory cleaned up" test ! -d "${DEAL_II_DIR}/tmp"

echo "✅ Ubuntu 20.04 minimal build test completed successfully!"

# Report result
reportResults
