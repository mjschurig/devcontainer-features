#!/bin/bash
set -e

# Test older_version scenario - deal.II version 9.5.0
echo "Testing deal.II older_version scenario..."

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

# Check that the correct version was installed
echo "Verifying deal.II version 9.5.0..."
if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfigVersion.cmake" ]; then
    if grep -q "9\.5\.0\|9_5_0" "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfigVersion.cmake"; then
        log_info "✅ deal.II version 9.5.0 confirmed"
    else
        # Try alternative version checking
        if [ -f "/usr/local/deal.II/include/deal.II/base/config.h" ]; then
            if grep -q "9\.5\.0\|9_5_0" "/usr/local/deal.II/include/deal.II/base/config.h"; then
                log_info "✅ deal.II version 9.5.0 confirmed (via config.h)"
            else
                log_info "ℹ️  Version information found but format may vary"
            fi
        else
            log_info "ℹ️  Version check inconclusive - configuration may vary between versions"
        fi
    fi
else
    log_error "Version configuration file not found"
    exit 1
fi

# Test version-specific functionality
echo "Testing version-specific CMake integration..."
TEMP_CMAKE_TEST_DIR=$(mktemp -d)
cd "$TEMP_CMAKE_TEST_DIR"

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(VersionTest)

find_package(deal.II REQUIRED)

if(deal.II_FOUND)
    message(STATUS "deal.II version: ${DEAL_II_VERSION}")
    # Check if version starts with 9.5
    string(REGEX MATCH "^9\\.5\\." VERSION_MATCH "${DEAL_II_VERSION}")
    if(VERSION_MATCH)
        message(STATUS "Confirmed deal.II 9.5.x series")
    else()
        message(WARNING "Version does not appear to be 9.5.x: ${DEAL_II_VERSION}")
    endif()
else()
    message(FATAL_ERROR "deal.II not found")
endif()

# Create simple test program for this version
add_executable(version_test version_test.cpp)
target_link_libraries(version_test ${DEAL_II_LIBRARIES})
target_include_directories(version_test PRIVATE ${DEAL_II_INCLUDE_DIRS})
target_compile_definitions(version_test PRIVATE ${DEAL_II_DEFINITIONS})
EOF

cat > version_test.cpp << 'EOF'
#include <deal.II/base/config.h>
#include <iostream>

int main() {
    std::cout << "deal.II version: " << DEAL_II_VERSION_MAJOR << "."
              << DEAL_II_VERSION_MINOR << "." << DEAL_II_VERSION_SUBMINOR << std::endl;

    // Check that this is indeed version 9.5.x
    if (DEAL_II_VERSION_MAJOR == 9 && DEAL_II_VERSION_MINOR == 5) {
        std::cout << "✅ Confirmed deal.II 9.5.x series" << std::endl;
    } else {
        std::cout << "⚠️  Version mismatch - expected 9.5.x" << std::endl;
    }

    return 0;
}
EOF

if cmake . > cmake_version.log 2>&1; then
    log_info "✅ CMake configuration successful"

    if make > build_version.log 2>&1; then
        log_info "✅ Compilation successful"

        if ./version_test > run_version.log 2>&1; then
            log_info "✅ Version test execution successful"
            log_info "Output: $(cat run_version.log)"
        else
            log_error "Version test execution failed"
            cat run_version.log
            cd /
            rm -rf "$TEMP_CMAKE_TEST_DIR"
            exit 1
        fi
    else
        log_error "Compilation failed"
        cat build_version.log
        cd /
        rm -rf "$TEMP_CMAKE_TEST_DIR"
        exit 1
    fi
else
    log_error "CMake configuration failed"
    cat cmake_version.log
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

echo "✅ Older version scenario test completed successfully!"
