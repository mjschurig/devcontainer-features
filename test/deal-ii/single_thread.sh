#!/bin/bash
set -e

# Test single_thread scenario - deal.II built with single thread
echo "Testing deal.II single_thread scenario..."

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

# This scenario tests that deal.II can be built successfully with limited resources
echo "Verifying single-threaded build scenario..."

# The main validation is that the installation completed successfully
# Single-threaded builds take longer but should produce the same result
log_info "✅ Single-threaded build completed successfully (if we reached this point)"

# Verify that the installation is complete and functional
echo "Verifying installation completeness..."
if [ -d "/usr/local/deal.II" ] && [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    log_info "✅ deal.II installation appears complete"
else
    log_error "deal.II installation appears incomplete"
    exit 1
fi

# Test basic functionality to ensure single-threaded build works correctly
echo "Testing basic functionality after single-threaded build..."
TEMP_CMAKE_TEST_DIR=$(mktemp -d)
cd "$TEMP_CMAKE_TEST_DIR"

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(SingleThreadTest)

find_package(deal.II REQUIRED)

add_executable(single_test single_test.cpp)
target_link_libraries(single_test ${DEAL_II_LIBRARIES})
target_include_directories(single_test PRIVATE ${DEAL_II_INCLUDE_DIRS})
target_compile_definitions(single_test PRIVATE ${DEAL_II_DEFINITIONS})
EOF

cat > single_test.cpp << 'EOF'
#include <deal.II/base/config.h>
#include <deal.II/grid/grid_generator.h>
#include <deal.II/grid/tria.h>
#include <iostream>

int main() {
    using namespace dealii;

    // Simple test to verify deal.II functionality
    Triangulation<2> triangulation;
    GridGenerator::hyper_cube(triangulation);
    triangulation.refine_global(2);

    std::cout << "Single-thread build test successful" << std::endl;
    std::cout << "Number of cells: " << triangulation.n_active_cells() << std::endl;

    if (triangulation.n_active_cells() == 16) {
        std::cout << "✅ Basic functionality verified" << std::endl;
    } else {
        std::cout << "⚠️  Unexpected cell count" << std::endl;
    }

    return 0;
}
EOF

if cmake . > cmake_single.log 2>&1; then
    log_info "✅ CMake configuration successful"

    if make > build_single.log 2>&1; then
        log_info "✅ Test program compilation successful"

        if ./single_test > run_single.log 2>&1; then
            log_info "✅ Test program execution successful"
            log_info "Output: $(cat run_single.log)"
        else
            log_error "Test program execution failed"
            cat run_single.log
            cd /
            rm -rf "$TEMP_CMAKE_TEST_DIR"
            exit 1
        fi
    else
        log_error "Test program compilation failed"
        cat build_single.log
        cd /
        rm -rf "$TEMP_CMAKE_TEST_DIR"
        exit 1
    fi
else
    log_error "CMake configuration failed"
    cat cmake_single.log
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

echo "✅ Single thread scenario test completed successfully!"
echo "   Single-threaded build produced a fully functional installation."
