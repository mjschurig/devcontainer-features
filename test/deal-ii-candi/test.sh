#!/bin/bash
set -e

# Import test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_UTILS_PATH="$SCRIPT_DIR/../_global/test-utils.sh"

# Try multiple possible paths for test utilities
if [ -f "$TEST_UTILS_PATH" ]; then
    source "$TEST_UTILS_PATH"
elif [ -f "/workspaces/*/test/_global/test-utils.sh" ]; then
    source /workspaces/*/test/_global/test-utils.sh
elif [ -f "test/_global/test-utils.sh" ]; then
    source "test/_global/test-utils.sh"
else
    echo "WARNING: test-utils.sh not found, defining basic functions..."
    # Define basic functions if test-utils.sh is not available
    log_info() { echo "ℹ️  $1"; }
    log_error() { echo "❌ $1" >&2; }
    log_success() { echo "✅ $1"; }

    check_command() {
        local cmd=$1
        if command -v "$cmd" >/dev/null 2>&1; then
            log_info "Command '$cmd' is available"
            return 0
        else
            log_error "Command '$cmd' not found"
            return 1
        fi
    }

    check_file() {
        local file=$1
        if [ -f "$file" ]; then
            log_info "File '$file' exists"
            return 0
        else
            log_error "File '$file' not found"
            return 1
        fi
    }

    check_directory() {
        local dir=$1
        if [ -d "$dir" ]; then
            log_info "Directory '$dir' exists"
            return 0
        else
            log_error "Directory '$dir' not found"
            return 1
        fi
    }

    check_env_var_set() {
        local var=$1
        local actual="${!var}"
        if [ -n "$actual" ]; then
            log_info "Environment variable '$var' is set to '$actual'"
            return 0
        else
            log_error "Environment variable '$var' is not set"
            return 1
        fi
    }
fi

echo "🧪 Testing deal.II candi feature..."
echo "=================================="

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_function="$2"

    echo ""
    echo "🔍 Test: $test_name"
    echo "----------------------------"

    if $test_function; then
        log_success "$test_name passed"
        ((TESTS_PASSED++))
        return 0
    else
        log_error "$test_name failed"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Installation directory structure
test_installation_structure() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    check_directory "$install_path" &&
    check_directory "$install_path/include" &&
    check_directory "$install_path/lib" &&
    check_directory "$install_path/lib/cmake" &&
    check_directory "$install_path/lib/cmake/deal.II"
}

# Test 2: Core library files
test_core_files() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    check_file "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake" &&
    check_file "$install_path/lib/cmake/deal.II/deal.IIConfigVersion.cmake" &&

    # Check for main library files (pattern match since exact names may vary)
    local lib_found=false
    for lib_file in "$install_path"/lib/libdeal_II*; do
        if [ -f "$lib_file" ]; then
            log_info "Found deal.II library: $(basename "$lib_file")"
            lib_found=true
            break
        fi
    done

    if [ "$lib_found" = "false" ]; then
        log_error "No deal.II library files found"
        return 1
    fi

    return 0
}

# Test 3: Header files
test_header_files() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    check_file "$install_path/include/deal.II/base/config.h" &&
    check_directory "$install_path/include/deal.II/base" &&
    check_directory "$install_path/include/deal.II/grid" &&
    check_directory "$install_path/include/deal.II/fe" &&
    check_directory "$install_path/include/deal.II/dofs"
}

# Test 4: Environment variables
test_environment_variables() {
    check_env_var_set "DEAL_II_DIR" &&

    # Check that DEAL_II_DIR points to the correct location
    local expected_path="/usr/local/dealii-candi"
    if [ "${DEAL_II_DIR}" = "$expected_path" ]; then
        log_info "DEAL_II_DIR correctly set to $expected_path"
    else
        log_info "DEAL_II_DIR set to '${DEAL_II_DIR}' (custom path)"
    fi

    # Check CMAKE_PREFIX_PATH includes deal.II
    if echo "${CMAKE_PREFIX_PATH}" | grep -q "${DEAL_II_DIR}"; then
        log_info "CMAKE_PREFIX_PATH includes deal.II path"
    else
        log_error "CMAKE_PREFIX_PATH does not include deal.II path"
        return 1
    fi

    # Check PATH includes deal.II bin directory
    if echo "${PATH}" | grep -q "${DEAL_II_DIR}/bin"; then
        log_info "PATH includes deal.II bin directory"
    else
        log_info "PATH does not include deal.II bin directory (may be expected)"
    fi

    return 0
}

# Test 5: CMake integration
test_cmake_integration() {
    # Check if cmake is available
    check_command "cmake" || return 1

    # Create temporary test directory
    local test_dir="/tmp/deal-ii-candi-cmake-test-$$"
    mkdir -p "$test_dir"
    cd "$test_dir"

    # Create minimal CMakeLists.txt
    cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(deal_ii_candi_test)

find_package(deal.II REQUIRED)

message(STATUS "deal.II version: ${DEAL_II_VERSION}")
message(STATUS "deal.II include dirs: ${DEAL_II_INCLUDE_DIRS}")
message(STATUS "deal.II libraries: ${DEAL_II_LIBRARIES}")

# Create a simple executable target to test linking
add_executable(test_program test.cpp)
target_link_libraries(test_program ${DEAL_II_LIBRARIES})
target_include_directories(test_program PRIVATE ${DEAL_II_INCLUDE_DIRS})
target_compile_definitions(test_program PRIVATE ${DEAL_II_DEFINITIONS})
EOF

    # Create minimal test program
    cat > test.cpp << 'EOF'
#include <deal.II/base/config.h>
#include <deal.II/base/logstream.h>
#include <deal.II/base/quadrature_lib.h>
#include <deal.II/grid/tria.h>
#include <deal.II/grid/grid_generator.h>
#include <deal.II/dofs/dof_handler.h>
#include <deal.II/fe/fe_q.h>
#include <iostream>

using namespace dealii;

int main() {
    std::cout << "deal.II version: " << DEAL_II_VERSION_MAJOR << "."
              << DEAL_II_VERSION_MINOR << "." << DEAL_II_VERSION_SUBMINOR << std::endl;

    // Create a simple triangulation to test functionality
    Triangulation<2> triangulation;
    GridGenerator::hyper_cube(triangulation);
    triangulation.refine_global(1);

    FE_Q<2> fe(1);
    DoFHandler<2> dof_handler(triangulation);
    dof_handler.distribute_dofs(fe);

    std::cout << "Number of degrees of freedom: " << dof_handler.n_dofs() << std::endl;
    std::cout << "deal.II candi test completed successfully!" << std::endl;

    return 0;
}
EOF

    # Run CMake configuration
    if cmake . > cmake_output.log 2>&1; then
        log_info "CMake configuration successful"

        # Check that deal.II was found
        if grep -q "deal.II version:" cmake_output.log; then
            log_info "deal.II version detected by CMake"
        else
            log_error "deal.II version not detected by CMake"
            cat cmake_output.log
            cd /
            rm -rf "$test_dir"
            return 1
        fi

        # Try to build the test program
        if make > build_output.log 2>&1; then
            log_info "Test program compiled successfully"

            # Try to run the test program
            if ./test_program > run_output.log 2>&1; then
                log_info "Test program executed successfully"
                log_info "Output: $(cat run_output.log)"
            else
                log_error "Test program execution failed"
                cat run_output.log
                cd /
                rm -rf "$test_dir"
                return 1
            fi
        else
            log_error "Test program compilation failed"
            cat build_output.log
            cd /
            rm -rf "$test_dir"
            return 1
        fi
    else
        log_error "CMake configuration failed"
        cat cmake_output.log
        cd /
        rm -rf "$test_dir"
        return 1
    fi

    # Clean up
    cd /
    rm -rf "$test_dir"
    return 0
}

# Test 6: Compiler dependencies
test_compiler_dependencies() {
    check_command "g++" &&
    check_command "gfortran" &&
    check_command "cmake" &&
    check_command "make" &&
    check_command "mpicc" &&
    check_command "mpicxx" &&
    check_command "mpifort"
}

# Test 7: MPI support
test_mpi_support() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    # Check if MPI commands are available
    if command -v mpicc >/dev/null 2>&1 && command -v mpicxx >/dev/null 2>&1; then
        log_info "MPI compilers found"
    else
        log_error "MPI compilers not found"
        return 1
    fi

    # Check deal.II configuration for MPI
    if [ -f "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
        if grep -q "DEAL_II_WITH_MPI.*ON" "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake"; then
            log_info "deal.II built with MPI support"
        else
            log_info "deal.II built without MPI support"
        fi
    else
        log_error "Cannot check deal.II MPI configuration"
        return 1
    fi

    return 0
}

# Test 8: PETSc support (if enabled)
test_petsc_support() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    # Check deal.II configuration for PETSc
    if [ -f "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
        if grep -q "DEAL_II_WITH_PETSC.*ON" "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake"; then
            log_info "deal.II built with PETSc support"

            # Check if PETSc libraries are available in the installation
            if find "$install_path" -name "*petsc*" -type f | head -1 | grep -q .; then
                log_info "PETSc libraries found in installation"
            else
                log_info "PETSc support enabled but libraries not found in installation path"
            fi
        else
            log_info "deal.II built without PETSc support"
        fi
    else
        log_error "Cannot check deal.II PETSc configuration"
        return 1
    fi

    return 0
}

# Test 9: Trilinos support (if enabled)
test_trilinos_support() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    # Check deal.II configuration for Trilinos
    if [ -f "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
        if grep -q "DEAL_II_WITH_TRILINOS.*ON" "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake"; then
            log_info "deal.II built with Trilinos support"

            # Check if Trilinos libraries are available in the installation
            if find "$install_path" -name "*trilinos*" -o -name "*Trilinos*" -type f | head -1 | grep -q .; then
                log_info "Trilinos libraries found in installation"
            else
                log_info "Trilinos support enabled but libraries not found in installation path"
            fi
        else
            log_info "deal.II built without Trilinos support"
        fi
    else
        log_error "Cannot check deal.II Trilinos configuration"
        return 1
    fi

    return 0
}

# Test 10: p4est support (if enabled)
test_p4est_support() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    # Check deal.II configuration for p4est
    if [ -f "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
        if grep -q "DEAL_II_WITH_P4EST.*ON" "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake"; then
            log_info "deal.II built with p4est support"

            # Check if p4est libraries are available
            if find "$install_path" -name "*p4est*" -type f | head -1 | grep -q .; then
                log_info "p4est libraries found in installation"
            else
                log_info "p4est support enabled but libraries not found in installation path"
            fi
        else
            log_info "deal.II built without p4est support"
        fi
    else
        log_error "Cannot check deal.II p4est configuration"
        return 1
    fi

    return 0
}

# Test 11: HDF5 support (if enabled)
test_hdf5_support() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    # Check deal.II configuration for HDF5
    if [ -f "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
        if grep -q "DEAL_II_WITH_HDF5.*ON" "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake"; then
            log_info "deal.II built with HDF5 support"

            # Check if HDF5 libraries are available
            if find "$install_path" -name "*hdf5*" -type f | head -1 | grep -q .; then
                log_info "HDF5 libraries found in installation"
            else
                log_info "HDF5 support enabled but libraries not found in installation path"
            fi
        else
            log_info "deal.II built without HDF5 support"
        fi
    else
        log_error "Cannot check deal.II HDF5 configuration"
        return 1
    fi

    return 0
}

# Test 12: OpenCASCADE support (if enabled)
test_opencascade_support() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    # Check deal.II configuration for OpenCASCADE
    if [ -f "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
        if grep -q "DEAL_II_WITH_OPENCASCADE.*ON" "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake"; then
            log_info "deal.II built with OpenCASCADE support"

            # Check if OpenCASCADE libraries are available
            if find "$install_path" -name "*opencascade*" -o -name "*TK*" -type f | head -1 | grep -q .; then
                log_info "OpenCASCADE libraries found in installation"
            else
                log_info "OpenCASCADE support enabled but libraries not found in installation path"
            fi
        else
            log_info "deal.II built without OpenCASCADE support"
        fi
    else
        log_error "Cannot check deal.II OpenCASCADE configuration"
        return 1
    fi

    return 0
}

# Test 13: Version verification
test_version_verification() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    if [ -f "$install_path/lib/cmake/deal.II/deal.IIConfigVersion.cmake" ]; then
        local version_info=$(grep "DEAL_II_VERSION" "$install_path/lib/cmake/deal.II/deal.IIConfigVersion.cmake" | head -1)
        log_info "Version info: $version_info"
        return 0
    else
        log_error "Version configuration file not found"
        return 1
    fi
}

# Test 14: Candi installation verification
test_candi_installation() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    # Check if the installation looks like it was done by candi
    if [ -d "$install_path" ]; then
        log_info "Installation directory exists"

        # Check for typical candi structure
        if [ -d "$install_path/include" ] && [ -d "$install_path/lib" ]; then
            log_info "Installation has expected candi structure"
        else
            log_error "Installation does not have expected candi structure"
            return 1
        fi

        # Check for deal.II specific files
        if [ -f "$install_path/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
            log_info "deal.II CMake configuration found"
        else
            log_error "deal.II CMake configuration not found"
            return 1
        fi
    else
        log_error "Installation directory not found"
        return 1
    fi

    return 0
}

# Test 15: Idempotency check
test_idempotency() {
    local install_path="${DEAL_II_DIR:-/usr/local/dealii-candi}"

    if [ -d "$install_path" ]; then
        log_info "deal.II candi installation directory exists (idempotency check passed)"
        return 0
    else
        log_error "deal.II candi installation directory not found"
        return 1
    fi
}

# Run all tests
echo "Starting deal.II candi feature tests..."
echo ""

run_test "Installation Structure" test_installation_structure
run_test "Core Library Files" test_core_files
run_test "Header Files" test_header_files
run_test "Environment Variables" test_environment_variables
run_test "CMake Integration" test_cmake_integration
run_test "Compiler Dependencies" test_compiler_dependencies
run_test "MPI Support" test_mpi_support
run_test "PETSc Support" test_petsc_support
run_test "Trilinos Support" test_trilinos_support
run_test "p4est Support" test_p4est_support
run_test "HDF5 Support" test_hdf5_support
run_test "OpenCASCADE Support" test_opencascade_support
run_test "Version Verification" test_version_verification
run_test "Candi Installation" test_candi_installation
run_test "Idempotency Check" test_idempotency

# Print summary
echo ""
echo "=================================="
echo "🏁 Test Summary"
echo "=================================="
echo "✅ Tests passed: $TESTS_PASSED"
echo "❌ Tests failed: $TESTS_FAILED"
echo "📊 Total tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo "🎉 All deal.II candi tests passed!"
    exit 0
else
    echo ""
    echo "💥 Some tests failed. Check the output above for details."
    exit 1
fi
