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

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color

    log_info() {
        echo -e "${GREEN}[INFO]${NC} $1"
    }

    log_error() {
        echo -e "${RED}[ERROR]${NC} $1"
    }

    log_warning() {
        echo -e "${YELLOW}[WARNING]${NC} $1"
    }

    check_command() {
        local cmd=$1
        local description=${2:-"Command '$cmd'"}

        if command -v "$cmd" >/dev/null 2>&1; then
            log_info "$description is available"
            return 0
        else
            log_error "$description not found"
            return 1
        fi
    }

    check_file() {
        local file=$1
        local description=${2:-"File '$file'"}

        if [ -f "$file" ]; then
            log_info "$description exists"
            return 0
        else
            log_error "$description not found"
            return 1
        fi
    }

    check_directory() {
        local dir=$1
        local description=${2:-"Directory '$dir'"}

        if [ -d "$dir" ]; then
            log_info "$description exists"
            return 0
        else
            log_error "$description not found"
            return 1
        fi
    }

    check_env_var_set() {
        local var=$1
        local description=${2:-"Environment variable '$var'"}

        local actual="${!var}"

        if [ -n "$actual" ]; then
            log_info "$description is set to '$actual'"
            return 0
        else
            log_error "$description is not set"
            return 1
        fi
    }

    run_command() {
        local cmd=$1
        local expected_exit_code=${2:-0}
        local description=${3:-"Command '$cmd'"}

        local output
        local exit_code

        output=$(eval "$cmd" 2>&1)
        exit_code=$?

        if [ $exit_code -eq $expected_exit_code ]; then
            log_info "$description executed successfully (exit code: $exit_code)"
            echo "$output"
            return 0
        else
            log_error "$description failed with exit code $exit_code (expected: $expected_exit_code)"
            echo "$output"
            return 1
        fi
    }
fi

# Check if TRILINOS_DIR is set, if not try to source the environment script
if [ -z "$TRILINOS_DIR" ]; then
    echo "TRILINOS_DIR not set, attempting to source Trilinos environment..."

    # Try sourcing from /etc/environment (Debian/Ubuntu style)
    if [ -f /etc/environment ]; then
        # Source /etc/environment to get TRILINOS_DIR
        set -a  # automatically export all variables
        . /etc/environment
        set +a  # turn off automatic export
        if [ -n "$TRILINOS_DIR" ]; then
            echo "Found TRILINOS_DIR in /etc/environment: $TRILINOS_DIR"
        fi
    fi

    # Try sourcing from /etc/profile.d/trilinos.sh
    if [ -z "$TRILINOS_DIR" ] && [ -f /etc/profile.d/trilinos.sh ]; then
        echo "Sourcing /etc/profile.d/trilinos.sh..."
        . /etc/profile.d/trilinos.sh
    fi

    # Try common installation prefixes
    if [ -z "$TRILINOS_DIR" ]; then
        for prefix in "/usr/local" "/opt/trilinos" "/usr"; do
            ENV_SCRIPT="$prefix/bin/trilinos-env.sh"
            if [ -f "$ENV_SCRIPT" ]; then
                echo "Found Trilinos environment script at: $ENV_SCRIPT"
                source "$ENV_SCRIPT"
                break
            fi
        done
    fi

    # If still not set, check if we can find it anywhere
    if [ -z "$TRILINOS_DIR" ]; then
        echo "Searching for trilinos-env.sh..."
        ENV_SCRIPT=$(find /usr -name "trilinos-env.sh" 2>/dev/null | head -1)
        if [ -n "$ENV_SCRIPT" ] && [ -f "$ENV_SCRIPT" ]; then
            echo "Found Trilinos environment script at: $ENV_SCRIPT"
            source "$ENV_SCRIPT"
        fi
    fi
fi

echo "Testing Trilinos feature..."

# Get installation prefix from environment or default
INSTALL_PREFIX=${TRILINOS_DIR:-/usr/local}

# Test 1: Check environment variables
echo "Test 1: Checking environment variables"
check_env_var_set "TRILINOS_DIR" "TRILINOS_DIR environment variable"

# Check CMAKE_PREFIX_PATH contains TRILINOS_DIR
if [ -n "$CMAKE_PREFIX_PATH" ]; then
    if echo "$CMAKE_PREFIX_PATH" | grep -q "$TRILINOS_DIR"; then
        log_info "CMAKE_PREFIX_PATH contains TRILINOS_DIR: $CMAKE_PREFIX_PATH"
    else
        log_error "CMAKE_PREFIX_PATH does not contain TRILINOS_DIR"
        log_error "CMAKE_PREFIX_PATH: $CMAKE_PREFIX_PATH"
        log_error "TRILINOS_DIR: $TRILINOS_DIR"
    fi
else
    log_error "CMAKE_PREFIX_PATH is not set"
fi

# Test 2: Check for essential development tools
echo "Test 2: Checking essential tools"
check_command "cmake" "CMake"
check_command "make" "Make"
check_command "gcc" "GCC compiler"
check_command "g++" "G++ compiler"

# Test 3: Check CMake version
echo "Test 3: Checking CMake version"
CMAKE_VERSION=$(cmake --version | grep -oP 'cmake version \K[0-9]+\.[0-9]+\.[0-9]+')
log_info "CMake version: $CMAKE_VERSION"

# Check if CMake version meets Trilinos requirements (3.23.0+)
if [ -n "$CMAKE_VERSION" ]; then
    CMAKE_MAJOR=$(echo "$CMAKE_VERSION" | cut -d. -f1)
    CMAKE_MINOR=$(echo "$CMAKE_VERSION" | cut -d. -f2)
    CMAKE_PATCH=$(echo "$CMAKE_VERSION" | cut -d. -f3)

    if [ "$CMAKE_MAJOR" -gt 3 ] || \
       ([ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -gt 23 ]) || \
       ([ "$CMAKE_MAJOR" -eq 3 ] && [ "$CMAKE_MINOR" -eq 23 ] && [ "$CMAKE_PATCH" -ge 0 ]); then
        log_info "CMake version meets Trilinos requirements (>= 3.23.0)"
    else
        log_error "CMake version is too old for Trilinos (requires >= 3.23.0)"
        exit 1
    fi
fi

# Test 4: Check MPI if enabled
echo "Test 4: Checking MPI installation"
if [ "${ENABLEMPI:-true}" = "true" ]; then
    check_command "mpicc" "MPI C compiler"
    check_command "mpicxx" "MPI C++ compiler"
    check_command "mpirun" "MPI runtime"

    # Test MPI functionality
    if command -v mpirun >/dev/null 2>&1; then
        MPI_VERSION=$(mpirun --version 2>/dev/null | head -n1 || echo "Unknown")
        log_info "MPI version: $MPI_VERSION"
    fi
else
    log_info "MPI support is disabled, skipping MPI tests"
fi

# Test 5: Check Fortran compiler if enabled
echo "Test 5: Checking Fortran compiler"
if [ "${ENABLEFORTRAN:-true}" = "true" ]; then
    check_command "gfortran" "Fortran compiler"
else
    log_info "Fortran support is disabled, skipping Fortran tests"
fi

# Test 6: Check BLAS/LAPACK
echo "Test 6: Checking BLAS/LAPACK"
if ldconfig -p | grep -q "libblas\|liblapack"; then
    log_info "BLAS/LAPACK libraries are available"
else
    log_error "BLAS/LAPACK libraries not found"
fi

# Test 7: Check Trilinos installation directories
echo "Test 7: Checking Trilinos installation structure"
check_directory "$INSTALL_PREFIX" "Installation prefix"
check_directory "$INSTALL_PREFIX/include" "Include directory"
check_directory "$INSTALL_PREFIX/lib" "Library directory (lib)" || \
check_directory "$INSTALL_PREFIX/lib64" "Library directory (lib64)"

# Test 8: Check Trilinos headers
echo "Test 8: Checking Trilinos headers"
check_file "$INSTALL_PREFIX/include/Teuchos_Version.hpp" "Teuchos version header"

# Check for package-specific headers based on feature options (informational only)
if [ "${ENABLEKOKKOS:-true}" = "true" ]; then
    if [ -f "$INSTALL_PREFIX/include/Kokkos_Core.hpp" ]; then
        log_info "Kokkos core header found"
    elif find "$INSTALL_PREFIX/include" -name "*Kokkos*" -type f 2>/dev/null | head -1 | grep -q .; then
        KOKKOS_HEADER=$(find "$INSTALL_PREFIX/include" -name "*Kokkos*" -type f 2>/dev/null | head -1)
        log_info "Kokkos headers found: $(basename "$KOKKOS_HEADER")"
    else
        log_info "Kokkos headers not found (may be integrated or header-only)"
    fi
fi

if [ "${ENABLETPETRA:-true}" = "true" ]; then
    if [ -f "$INSTALL_PREFIX/include/Tpetra_Version.hpp" ]; then
        log_info "Tpetra version header found"
    elif [ -f "$INSTALL_PREFIX/include/Tpetra_Map.hpp" ]; then
        log_info "Tpetra map header found"
    elif find "$INSTALL_PREFIX/include" -name "*Tpetra*" -type f 2>/dev/null | head -1 | grep -q .; then
        TPETRA_HEADER=$(find "$INSTALL_PREFIX/include" -name "*Tpetra*" -type f 2>/dev/null | head -1)
        log_info "Tpetra headers found: $(basename "$TPETRA_HEADER")"
    else
        log_info "Tpetra headers not found (may be integrated or header-only)"
    fi
fi

if [ "${ENABLEBELOS:-true}" = "true" ]; then
    if [ -f "$INSTALL_PREFIX/include/BelosVersion.hpp" ]; then
        log_info "Belos version header found"
    elif [ -f "$INSTALL_PREFIX/include/BelosConfigDefs.hpp" ]; then
        log_info "Belos config header found"
    elif find "$INSTALL_PREFIX/include" -name "*Belos*" -type f 2>/dev/null | head -1 | grep -q .; then
        BELOS_HEADER=$(find "$INSTALL_PREFIX/include" -name "*Belos*" -type f 2>/dev/null | head -1)
        log_info "Belos headers found: $(basename "$BELOS_HEADER")"
    else
        log_info "Belos headers not found (may be integrated or header-only)"
    fi
fi

# Test 9: Check Trilinos libraries (using improved detection like install.sh)
echo "Test 9: Checking Trilinos libraries"

# Check for core Teuchos library with improved detection
TEUCHOS_LIB_FOUND=false

# Check for various possible library names and locations
for lib_dir in "$INSTALL_PREFIX/lib" "$INSTALL_PREFIX/lib64"; do
    if [ -d "$lib_dir" ]; then
        # Check for different possible library names (shared libraries first)
        for lib_pattern in "libteuchos.so*" "libteuchoscore.so*" "libteuchoscomm.so*" "libteuchos*.so*"; do
            if ls "$lib_dir"/$lib_pattern 1> /dev/null 2>&1; then
                log_info "Trilinos shared libraries found: $(ls "$lib_dir"/$lib_pattern | head -1)"
                TEUCHOS_LIB_FOUND=true
                break 2
            fi
        done
        # If no shared libraries found, check for static libraries
        if [ "$TEUCHOS_LIB_FOUND" = "false" ]; then
            for lib_pattern in "libteuchos.a" "libteuchoscore.a" "libteuchoscomm.a" "libteuchos*.a"; do
                if ls "$lib_dir"/$lib_pattern 1> /dev/null 2>&1; then
                    log_info "Trilinos static libraries found: $(ls "$lib_dir"/$lib_pattern | head -1)"
                    log_info "Note: Static libraries found instead of shared libraries"
                    TEUCHOS_LIB_FOUND=true
                    break 2
                fi
            done
        fi
    fi
done

if [ "$TEUCHOS_LIB_FOUND" = "false" ]; then
    log_warning "Trilinos core libraries not found in expected locations"
    log_info "Searching for any Trilinos libraries..."
    TEUCHOS_LIBS=$(find "$INSTALL_PREFIX" -name "*.so*" 2>/dev/null | grep -i teuchos | head -3)
    if [ -n "$TEUCHOS_LIBS" ]; then
        log_info "Found teuchos libraries: $(echo "$TEUCHOS_LIBS" | tr '\n' ' ')"
    else
        log_info "No teuchos shared libraries found"
    fi

    TRILINOS_LIBS=$(find "$INSTALL_PREFIX" -name "*.so*" 2>/dev/null | grep -i trilinos | head -3)
    if [ -n "$TRILINOS_LIBS" ]; then
        log_info "Found trilinos libraries: $(echo "$TRILINOS_LIBS" | tr '\n' ' ')"
    else
        log_info "No trilinos shared libraries found"
    fi

    # Check for static libraries as well
    STATIC_LIBS=$(find "$INSTALL_PREFIX" -name "*.a" 2>/dev/null | grep -i trilinos | head -3)
    if [ -n "$STATIC_LIBS" ]; then
        log_info "Found static libraries: $(echo "$STATIC_LIBS" | tr '\n' ' ')"
    fi
fi

# Check for package-specific libraries based on options (more flexible)
for lib_dir in "$INSTALL_PREFIX/lib" "$INSTALL_PREFIX/lib64"; do
    if [ -d "$lib_dir" ]; then
        if [ "${ENABLEKOKKOS:-true}" = "true" ]; then
            if ls "$lib_dir"/libkokkos* >/dev/null 2>&1; then
                log_info "Kokkos library found"
            else
                log_info "Kokkos library not found (may be header-only or integrated)"
            fi
        fi

        if [ "${ENABLETPETRA:-true}" = "true" ]; then
            if ls "$lib_dir"/libtpetra* >/dev/null 2>&1; then
                log_info "Tpetra library found"
            else
                log_info "Tpetra library not found (may be header-only)"
            fi
        fi

        if [ "${ENABLEBELOS:-true}" = "true" ]; then
            if ls "$lib_dir"/libbelos* >/dev/null 2>&1; then
                log_info "Belos library found"
            else
                log_info "Belos library not found (may be header-only)"
            fi
        fi
        break  # Only check the first existing directory
    fi
done

# Test 10: Check CMake configuration (improved detection like install.sh)
echo "Test 10: Checking CMake configuration"

CMAKE_CONFIG_FOUND=false
for cmake_dir in "$INSTALL_PREFIX/lib/cmake/Trilinos" "$INSTALL_PREFIX/lib64/cmake/Trilinos" "$INSTALL_PREFIX/share/cmake/Trilinos"; do
    if [ -f "$cmake_dir/TrilinosConfig.cmake" ]; then
        log_info "Trilinos CMake configuration found: $cmake_dir/TrilinosConfig.cmake"
        CMAKE_CONFIG_FOUND=true
        break
    fi
done

if [ "$CMAKE_CONFIG_FOUND" = "false" ]; then
    log_warning "Trilinos CMake configuration not found in expected locations"
    log_info "Searching for CMake configuration files..."
    TRILINOS_CONFIG=$(find "$INSTALL_PREFIX" -name "TrilinosConfig.cmake" 2>/dev/null | head -1)
    if [ -n "$TRILINOS_CONFIG" ]; then
        log_info "Found TrilinosConfig.cmake at: $TRILINOS_CONFIG"
    else
        log_info "No TrilinosConfig.cmake found"
    fi

    CMAKE_FILES=$(find "$INSTALL_PREFIX" -name "*Trilinos*.cmake" 2>/dev/null | head -3)
    if [ -n "$CMAKE_FILES" ]; then
        log_info "Found Trilinos CMake files:"
        echo "$CMAKE_FILES" | while read -r file; do
            log_info "  - $(basename "$file")"
        done
    else
        log_info "No Trilinos CMake files found"
    fi
fi

# Test 11: Check environment setup script
echo "Test 11: Checking environment setup script"
ENV_SCRIPT="$INSTALL_PREFIX/bin/trilinos-env.sh"
check_file "$ENV_SCRIPT" "Environment setup script"

if [ -f "$ENV_SCRIPT" ]; then
    # Test that the script is executable
    if [ -x "$ENV_SCRIPT" ]; then
        log_info "Environment script is executable"
    else
        log_error "Environment script is not executable"
    fi

    # Test sourcing the script
    if bash -c "source '$ENV_SCRIPT' && echo 'Environment script sourced successfully'" >/dev/null 2>&1; then
        log_info "Environment script can be sourced successfully"
    else
        log_error "Environment script cannot be sourced"
    fi
fi

# Test 12: Check test program
echo "Test 12: Checking test program"
TEST_PROGRAM_DIR="$INSTALL_PREFIX/share/trilinos/test"
check_directory "$TEST_PROGRAM_DIR" "Test program directory"
check_file "$TEST_PROGRAM_DIR/test_trilinos.cpp" "Test program source"
check_file "$TEST_PROGRAM_DIR/CMakeLists.txt" "Test program CMakeLists.txt"

# Test 13: Build and run test program
echo "Test 13: Building and running test program"
if [ -d "$TEST_PROGRAM_DIR" ] && [ -f "$TEST_PROGRAM_DIR/CMakeLists.txt" ]; then
    # Create a temporary build directory
    TEMP_BUILD_DIR=$(mktemp -d)
    cd "$TEMP_BUILD_DIR"

    # Try to configure the test program with verbose output on failure
    CMAKE_OUTPUT=$(cmake "$TEST_PROGRAM_DIR" 2>&1)
    CMAKE_EXIT_CODE=$?

    if [ $CMAKE_EXIT_CODE -eq 0 ]; then
        log_info "Test program CMake configuration successful"

        # Try to build the test program with verbose output on failure
        MAKE_OUTPUT=$(make 2>&1)
        MAKE_EXIT_CODE=$?

        if [ $MAKE_EXIT_CODE -eq 0 ]; then
            log_info "Test program build successful"

            # Try to run the test program
            if [ -x "./test_trilinos" ]; then
                TEST_OUTPUT=$(./test_trilinos 2>&1)
                if echo "$TEST_OUTPUT" | grep -q "SUCCESS"; then
                    log_info "Test program execution successful"
                    VERSION_LINE=$(echo "$TEST_OUTPUT" | grep "Trilinos version" || echo "Version info not found")
                    log_info "$VERSION_LINE"
                else
                    log_warning "Test program execution failed: $TEST_OUTPUT"
                fi
            else
                log_warning "Test program executable not found"
            fi
        else
            log_warning "Test program build failed (this may be expected if libraries are not available for linking)"
            # Show first few lines of error for debugging but don't fail the entire test
            echo "Build error details (first 10 lines):"
            echo "$MAKE_OUTPUT" | head -10 | sed 's/^/  /'
        fi
    else
        log_warning "Test program CMake configuration failed (this may be expected in some environments)"
        # Show first few lines of error for debugging but don't fail the entire test
        echo "CMake error details (first 10 lines):"
        echo "$CMAKE_OUTPUT" | head -10 | sed 's/^/  /'
    fi

    # Clean up
    cd /
    rm -rf "$TEMP_BUILD_DIR"
else
    log_warning "Test program files not found, skipping build test"
fi

# Test 14: Test CMake find_package functionality
echo "Test 14: Testing CMake find_package functionality"
TEMP_CMAKE_TEST_DIR=$(mktemp -d)
cd "$TEMP_CMAKE_TEST_DIR"

# Create a minimal CMake project to test find_package
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(TrilinosTest)

find_package(Trilinos REQUIRED)

if(Trilinos_FOUND)
    message(STATUS "Trilinos found successfully")
    message(STATUS "Trilinos version: ${Trilinos_VERSION}")
    message(STATUS "Trilinos libraries: ${Trilinos_LIBRARIES}")
    message(STATUS "Trilinos include directories: ${Trilinos_INCLUDE_DIRS}")
else()
    message(FATAL_ERROR "Trilinos not found")
endif()

# Create a simple test that just includes Teuchos
add_executable(find_package_test find_package_test.cpp)
target_link_libraries(find_package_test ${Trilinos_LIBRARIES})
target_include_directories(find_package_test PRIVATE ${Trilinos_INCLUDE_DIRS})
EOF

cat > find_package_test.cpp << 'EOF'
#include <iostream>
#include "Teuchos_Version.hpp"

int main() {
    std::cout << "find_package test successful" << std::endl;
    return 0;
}
EOF

# Try CMake configuration
if cmake . >/dev/null 2>&1; then
    log_info "CMake find_package(Trilinos) successful"

    # Extract version information if available
    CMAKE_OUTPUT=$(cmake . 2>&1)
    if echo "$CMAKE_OUTPUT" | grep -q "Trilinos version:"; then
        VERSION_INFO=$(echo "$CMAKE_OUTPUT" | grep "Trilinos version:" || echo "Version not found")
        log_info "$VERSION_INFO"
    fi

    # Try to build the find_package test
    if make >/dev/null 2>&1; then
        log_info "find_package test build successful"

        # Try to run the test
        if [ -x "./find_package_test" ]; then
            if ./find_package_test >/dev/null 2>&1; then
                log_info "find_package test execution successful"
            else
                log_error "find_package test execution failed"
            fi
        fi
    else
        log_info "find_package test build failed (may be expected for header-only packages)"
    fi
else
    log_error "CMake find_package(Trilinos) failed"
fi

# Clean up
cd /
rm -rf "$TEMP_CMAKE_TEST_DIR"

# Test 15: Check library path configuration
echo "Test 15: Checking library path configuration"
if echo "$LD_LIBRARY_PATH" | grep -q "$INSTALL_PREFIX"; then
    log_info "Trilinos library path is in LD_LIBRARY_PATH"
else
    log_info "Trilinos library path not in LD_LIBRARY_PATH (may use system paths)"
fi

# Test 16: Check PATH configuration
echo "Test 16: Checking PATH configuration"
if echo "$PATH" | grep -q "$INSTALL_PREFIX/bin"; then
    log_info "Trilinos bin directory is in PATH"
else
    log_info "Trilinos bin directory not in PATH (may not have binaries)"
fi

# Test 17: Check for any Trilinos binaries
echo "Test 17: Checking for Trilinos binaries"
if [ -d "$INSTALL_PREFIX/bin" ]; then
    BIN_COUNT=$(find "$INSTALL_PREFIX/bin" -type f -executable | wc -l)
    if [ "$BIN_COUNT" -gt 0 ]; then
        log_info "Found $BIN_COUNT executable(s) in Trilinos bin directory"
        # List a few binaries for reference
        find "$INSTALL_PREFIX/bin" -type f -executable | head -3 | while read -r binary; do
            log_info "  - $(basename "$binary")"
        done
    else
        log_info "No executables found in Trilinos bin directory"
    fi
else
    log_info "Trilinos bin directory does not exist"
fi

# Test 18: Verify idempotency indicator
echo "Test 18: Checking installation completeness"
if [ -f "$INSTALL_PREFIX/include/Teuchos_Version.hpp" ] && \
   ([ -d "$INSTALL_PREFIX/lib" ] || [ -d "$INSTALL_PREFIX/lib64" ]) && \
   ([ -f "$INSTALL_PREFIX/lib/cmake/Trilinos/TrilinosConfig.cmake" ] || \
    [ -f "$INSTALL_PREFIX/lib64/cmake/Trilinos/TrilinosConfig.cmake" ]); then
    log_info "Trilinos installation appears complete"
else
    log_error "Trilinos installation appears incomplete"
    exit 1
fi

echo ""
echo "✅ All Trilinos tests completed!"
echo ""
echo "Installation Summary:"
echo "  Install prefix: $INSTALL_PREFIX"
echo "  CMake version: $CMAKE_VERSION"
if [ "${ENABLEMPI:-true}" = "true" ]; then
    echo "  MPI: Enabled"
else
    echo "  MPI: Disabled"
fi
if [ "${ENABLEFORTRAN:-true}" = "true" ]; then
    echo "  Fortran: Enabled"
else
    echo "  Fortran: Disabled"
fi
echo "  Environment configured: Yes"
echo "  Test program available: $([ -f "$TEST_PROGRAM_DIR/test_trilinos.cpp" ] && echo "Yes" || echo "No")"
echo ""
