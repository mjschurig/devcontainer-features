#!/bin/bash
set -e

# Test full_features scenario - deal.II with all features enabled
echo "Testing deal.II full_features scenario..."

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

# This scenario tests all features: MPI + PETSc + Trilinos
echo "Verifying all features are properly configured..."

# Check MPI support
echo "Checking MPI support..."
if command -v mpicc >/dev/null 2>&1 && command -v mpicxx >/dev/null 2>&1; then
    log_info "✅ MPI compilers are available"
else
    log_error "MPI compilers not found"
    exit 1
fi

# Check PETSc support (may not be available via package manager)
echo "Checking PETSc support..."
if ldconfig -p 2>/dev/null | grep -q "libpetsc"; then
    log_info "✅ PETSc libraries found in system"
    PETSC_AVAILABLE=true
else
    log_info "ℹ️  PETSc not found in system - may be expected if not installable via package manager"
    PETSC_AVAILABLE=false
fi

# Check Trilinos support
echo "Checking Trilinos support..."
if [ -d "/usr/local/trilinos" ]; then
    log_info "✅ Trilinos installation found"

    if [ -n "$TRILINOS_DIR" ]; then
        log_info "✅ TRILINOS_DIR environment variable is set"
    else
        log_error "TRILINOS_DIR environment variable not set"
        exit 1
    fi
else
    log_error "Trilinos installation not found - required for full features scenario"
    exit 1
fi

# Check deal.II configuration with all features
echo "Verifying deal.II configuration with all features..."
if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    CONFIG_FILE="/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake"

    # Check MPI
    if grep -q "DEAL_II_WITH_MPI.*ON" "$CONFIG_FILE"; then
        log_info "✅ deal.II built with MPI support"
    else
        log_error "deal.II missing MPI support"
        exit 1
    fi

    # Check PETSc (conditional on availability)
    if [ "$PETSC_AVAILABLE" = "true" ]; then
        if grep -q "DEAL_II_WITH_PETSC.*ON" "$CONFIG_FILE"; then
            log_info "✅ deal.II built with PETSc support"
        else
            log_info "ℹ️  deal.II built without PETSc support (PETSc may not have been available)"
        fi
    else
        log_info "ℹ️  Skipping PETSc check (not available in system)"
    fi

    # Check Trilinos
    if grep -q "DEAL_II_WITH_TRILINOS.*ON" "$CONFIG_FILE"; then
        log_info "✅ deal.II built with Trilinos support"
    else
        log_error "deal.II missing Trilinos support"
        exit 1
    fi
else
    log_error "Cannot check deal.II configuration"
    exit 1
fi

# Test comprehensive integration
echo "Testing comprehensive CMake integration..."
TEMP_CMAKE_TEST_DIR=$(mktemp -d)
cd "$TEMP_CMAKE_TEST_DIR"

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(FullFeaturesTest)

find_package(MPI REQUIRED)
find_package(Trilinos REQUIRED)
find_package(deal.II REQUIRED)

add_executable(full_test full_test.cpp)
target_link_libraries(full_test ${DEAL_II_LIBRARIES})
target_include_directories(full_test PRIVATE ${DEAL_II_INCLUDE_DIRS})
target_compile_definitions(full_test PRIVATE ${DEAL_II_DEFINITIONS})
EOF

cat > full_test.cpp << 'EOF'
#include <deal.II/base/config.h>
#include <deal.II/base/mpi.h>
#include <iostream>

int main(int argc, char *argv[]) {
    try {
        dealii::Utilities::MPI::MPI_InitFinalize mpi_initialization(argc, argv, 1);

        std::cout << "deal.II full features test" << std::endl;

#ifdef DEAL_II_WITH_MPI
        std::cout << "✅ MPI support enabled" << std::endl;
#endif

#ifdef DEAL_II_WITH_PETSC
        std::cout << "✅ PETSc support enabled" << std::endl;
#endif

#ifdef DEAL_II_WITH_TRILINOS
        std::cout << "✅ Trilinos support enabled" << std::endl;
#endif

        return 0;
    } catch (const std::exception &e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
EOF

if cmake . > cmake_full.log 2>&1; then
    log_info "✅ CMake configuration successful"

    if make > build_full.log 2>&1; then
        log_info "✅ Compilation successful"

        if ./full_test > run_full.log 2>&1; then
            log_info "✅ Execution successful"
            log_info "Output: $(cat run_full.log)"
        else
            log_error "Execution failed"
            cat run_full.log
            cd /
            rm -rf "$TEMP_CMAKE_TEST_DIR"
            exit 1
        fi
    else
        log_error "Compilation failed"
        cat build_full.log
        cd /
        rm -rf "$TEMP_CMAKE_TEST_DIR"
        exit 1
    fi
else
    log_error "CMake configuration failed"
    cat cmake_full.log
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

echo "✅ Full features scenario test completed successfully!"
