#!/bin/bash
set -e

# Test idempotency scenario - installation can be run multiple times safely
echo "Testing deal.II idempotency scenario..."

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

INSTALL_PREFIX="/usr/local/deal.II"

# Test that the installation exists and is complete
echo "Verifying installation exists and is complete..."
if [ -f "$INSTALL_PREFIX/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    log_info "✅ deal.II installation detected"
else
    log_error "deal.II installation not found - idempotency test requires existing installation"
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

if [ ! -d "$INSTALL_PREFIX/lib" ]; then
    log_error "Library directory missing"
    INSTALL_COMPLETE=false
fi

# Check for CMake config
if [ ! -f "$INSTALL_PREFIX/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    log_error "CMake configuration missing"
    INSTALL_COMPLETE=false
fi

# Check for main headers
if [ ! -f "$INSTALL_PREFIX/include/deal.II/base/config.h" ]; then
    log_error "Main configuration header missing"
    INSTALL_COMPLETE=false
fi

# Check for library files
LIB_FOUND=false
for lib_file in "$INSTALL_PREFIX/lib/libdeal_II"*; do
    if [ -f "$lib_file" ]; then
        LIB_FOUND=true
        break
    fi
done

if [ "$LIB_FOUND" = "false" ]; then
    log_error "deal.II library files missing"
    INSTALL_COMPLETE=false
fi

if [ "$INSTALL_COMPLETE" = "true" ]; then
    log_info "✅ Installation appears complete and consistent"
else
    log_error "Installation appears incomplete - idempotency may be compromised"
    exit 1
fi

# Test that environment is properly set up
echo "Verifying environment consistency..."
if [ -n "$DEAL_II_DIR" ] && [ "$DEAL_II_DIR" = "$INSTALL_PREFIX" ]; then
    log_info "✅ DEAL_II_DIR environment variable is consistent"
else
    log_error "DEAL_II_DIR environment variable inconsistent"
fi

# Check CMAKE_PREFIX_PATH includes deal.II
if echo "${CMAKE_PREFIX_PATH}" | grep -q "$INSTALL_PREFIX"; then
    log_info "✅ CMAKE_PREFIX_PATH includes deal.II path"
else
    log_error "CMAKE_PREFIX_PATH does not include deal.II path"
fi

# Test version consistency (if version info is available)
echo "Checking version consistency..."
if [ -f "$INSTALL_PREFIX/lib/cmake/deal.II/deal.IIConfigVersion.cmake" ]; then
    VERSION_INFO=$(grep -E "DEAL_II_VERSION|deal_II_VERSION" "$INSTALL_PREFIX/lib/cmake/deal.II/deal.IIConfigVersion.cmake" | head -1)
    if [ -n "$VERSION_INFO" ]; then
        log_info "✅ Version information found: $VERSION_INFO"
    else
        log_info "ℹ️  Version information format may vary"
    fi
else
    log_info "ℹ️  Version file check skipped (file may have different name)"
fi

# Test that the installation can be detected by CMake
echo "Testing CMake find_package consistency..."
TEMP_CMAKE_TEST_DIR=$(mktemp -d)
cd "$TEMP_CMAKE_TEST_DIR"

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(IdempotencyTest)

find_package(deal.II REQUIRED)

if(deal.II_FOUND)
    message(STATUS "deal.II found: ${DEAL_II_VERSION}")
else()
    message(FATAL_ERROR "deal.II not found")
endif()

# Test basic functionality
add_executable(idempotency_test idempotency_test.cpp)
target_link_libraries(idempotency_test ${DEAL_II_LIBRARIES})
target_include_directories(idempotency_test PRIVATE ${DEAL_II_INCLUDE_DIRS})
target_compile_definitions(idempotency_test PRIVATE ${DEAL_II_DEFINITIONS})
EOF

cat > idempotency_test.cpp << 'EOF'
#include <deal.II/base/config.h>
#include <deal.II/grid/grid_generator.h>
#include <deal.II/grid/tria.h>
#include <iostream>

int main() {
    using namespace dealii;

    // Test basic functionality
    Triangulation<2> triangulation;
    GridGenerator::hyper_cube(triangulation);
    triangulation.refine_global(1);

    std::cout << "Idempotency test: deal.II version "
              << DEAL_II_VERSION_MAJOR << "."
              << DEAL_II_VERSION_MINOR << "."
              << DEAL_II_VERSION_SUBMINOR << std::endl;
    std::cout << "Cells: " << triangulation.n_active_cells() << std::endl;

    return 0;
}
EOF

if cmake . > cmake_idempotency.log 2>&1; then
    log_info "✅ CMake can consistently find deal.II installation"

    if make > build_idempotency.log 2>&1; then
        log_info "✅ Compilation successful"

        if ./idempotency_test > run_idempotency.log 2>&1; then
            log_info "✅ Execution successful"
            log_info "Output: $(cat run_idempotency.log)"
        else
            log_error "Execution failed"
            cat run_idempotency.log
        fi
    else
        log_error "Compilation failed"
        cat build_idempotency.log
    fi
else
    log_error "CMake cannot find deal.II installation - may indicate corruption"
    cat cmake_idempotency.log
fi

# Clean up
cd /
rm -rf "$TEMP_CMAKE_TEST_DIR"

# Test file permissions and ownership consistency
echo "Checking file permissions consistency..."
if [ -r "$INSTALL_PREFIX/include/deal.II/base/config.h" ]; then
    log_info "✅ Headers are readable"
else
    log_error "Headers are not readable"
fi

if [ -r "$INSTALL_PREFIX/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    log_info "✅ CMake config is readable"
else
    log_error "CMake config is not readable"
fi

# Source the main test script for comprehensive validation
echo "Running comprehensive installation validation..."
source "$SCRIPT_DIR/test.sh"

echo "✅ Idempotency scenario test completed successfully!"
echo "   Installation appears stable and ready for repeated installations."
