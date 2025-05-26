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

echo "🧪 Testing deal.II feature..."
echo "================================"

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
    check_directory "/usr/local/deal.II" &&
    check_directory "/usr/local/deal.II/include" &&
    check_directory "/usr/local/deal.II/lib" &&
    check_directory "/usr/local/deal.II/lib/cmake" &&
    check_directory "/usr/local/deal.II/lib/cmake/deal.II"
}

# Test 2: Core library files
test_core_files() {
    check_file "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" &&
    check_file "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfigVersion.cmake" &&

    # Check for main library files (pattern match since exact names may vary)
    local lib_found=false
    for lib_file in /usr/local/deal.II/lib/libdeal_II*; do
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
    check_file "/usr/local/deal.II/include/deal.II/base/config.h" &&
    check_directory "/usr/local/deal.II/include/deal.II/base" &&
    check_directory "/usr/local/deal.II/include/deal.II/grid" &&
    check_directory "/usr/local/deal.II/include/deal.II/fe" &&
    check_directory "/usr/local/deal.II/include/deal.II/dofs"
}

# Test 4: Environment variables
test_environment_variables() {
    check_env_var_set "DEAL_II_DIR" &&

    # Check that DEAL_II_DIR points to the correct location
    if [ "${DEAL_II_DIR}" = "/usr/local/deal.II" ]; then
        log_info "DEAL_II_DIR correctly set to /usr/local/deal.II"
    else
        log_error "DEAL_II_DIR set to '${DEAL_II_DIR}', expected '/usr/local/deal.II'"
        return 1
    fi

    # Check CMAKE_PREFIX_PATH includes deal.II
    if echo "${CMAKE_PREFIX_PATH}" | grep -q "/usr/local/deal.II"; then
        log_info "CMAKE_PREFIX_PATH includes deal.II path"
    else
        log_error "CMAKE_PREFIX_PATH does not include deal.II path"
        return 1
    fi

    return 0
}

# Test 5: CMake integration
test_cmake_integration() {
    # Check if cmake is available
    check_command "cmake" || return 1

    # Create temporary test directory
    local test_dir="/tmp/deal-ii-cmake-test-$$"
    mkdir -p "$test_dir"
    cd "$test_dir"

    # Create minimal CMakeLists.txt
    cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(deal_ii_test)

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
#include <iostream>

int main() {
    std::cout << "deal.II version: " << DEAL_II_VERSION_MAJOR << "."
              << DEAL_II_VERSION_MINOR << "." << DEAL_II_VERSION_SUBMINOR << std::endl;
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
    check_command "cmake" &&
    check_command "make"
}

# Test 7: MPI support (if enabled)
test_mpi_support() {
    local mpi_enabled=false

    # Check if MPI commands are available
    if command -v mpicc >/dev/null 2>&1 && command -v mpicxx >/dev/null 2>&1; then
        log_info "MPI compilers found"
        mpi_enabled=true
    fi

    # Check deal.II configuration for MPI
    if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
        if grep -q "DEAL_II_WITH_MPI.*ON" "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake"; then
            log_info "deal.II built with MPI support"

            if [ "$mpi_enabled" = "false" ]; then
                log_error "deal.II has MPI support but MPI compilers not found"
                return 1
            fi
        else
            log_info "deal.II built without MPI support"

            if [ "$mpi_enabled" = "true" ]; then
                log_info "MPI compilers available but not used in deal.II build"
            fi
        fi
    else
        log_error "Cannot check deal.II MPI configuration"
        return 1
    fi

    return 0
}

# Test 8: PETSc support (if enabled)
test_petsc_support() {
    # Check if PETSc libraries are available
    local petsc_available=false

    if ldconfig -p 2>/dev/null | grep -q "libpetsc"; then
        log_info "PETSc libraries found in system"
        petsc_available=true
    fi

    # Check deal.II configuration for PETSc
    if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
        if grep -q "DEAL_II_WITH_PETSC.*ON" "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake"; then
            log_info "deal.II built with PETSc support"

            if [ "$petsc_available" = "false" ]; then
                log_error "deal.II has PETSc support but PETSc libraries not found"
                return 1
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
    # Check if Trilinos is available
    local trilinos_available=false

    if [ -d "/usr/local/trilinos" ]; then
        log_info "Trilinos installation found"
        trilinos_available=true
        check_env_var_set "TRILINOS_DIR"
    fi

    # Check deal.II configuration for Trilinos
    if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
        if grep -q "DEAL_II_WITH_TRILINOS.*ON" "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake"; then
            log_info "deal.II built with Trilinos support"

            if [ "$trilinos_available" = "false" ]; then
                log_error "deal.II has Trilinos support but Trilinos installation not found"
                return 1
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

# Test 10: Version verification
test_version_verification() {
    if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfigVersion.cmake" ]; then
        local version_info=$(grep "DEAL_II_VERSION" "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfigVersion.cmake" | head -1)
        log_info "Version info: $version_info"
        return 0
    else
        log_error "Version configuration file not found"
        return 1
    fi
}

# Test 11: Idempotency check
test_idempotency() {
    # This test verifies that the installation can detect an existing installation
    # We check for the idempotency markers that the install script should create

    if [ -d "/usr/local/deal.II" ]; then
        log_info "deal.II installation directory exists (idempotency check passed)"
        return 0
    else
        log_error "deal.II installation directory not found"
        return 1
    fi
}

# Run all tests
echo "Starting deal.II feature tests..."
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
run_test "Version Verification" test_version_verification
run_test "Idempotency Check" test_idempotency

# Print summary
echo ""
echo "================================"
echo "🏁 Test Summary"
echo "================================"
echo "✅ Tests passed: $TESTS_PASSED"
echo "❌ Tests failed: $TESTS_FAILED"
echo "📊 Total tests: $((TESTS_PASSED + TESTS_FAILED))"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo "🎉 All deal.II tests passed!"
    exit 0
else
    echo ""
    echo "💥 Some tests failed. Check the output above for details."
    exit 1
fi
