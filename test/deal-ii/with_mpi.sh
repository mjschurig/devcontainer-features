#!/bin/bash
set -e

# Test deal.II with MPI enabled
echo "🧪 Testing deal.II with MPI configuration..."

# Source the main test script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test.sh"

# Additional tests specific to MPI configuration
echo ""
echo "🔍 MPI Configuration Specific Tests"
echo "===================================="

# Test that MPI commands are available
if command -v mpicc >/dev/null 2>&1 && command -v mpicxx >/dev/null 2>&1; then
    echo "✅ MPI compilers are available"

    # Test MPI version
    MPI_VERSION=$(mpicc --version | head -1)
    echo "ℹ️  MPI Version: $MPI_VERSION"
else
    echo "❌ MPI compilers not found (required for MPI configuration)"
    exit 1
fi

# Test that deal.II was built with MPI support
if [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    if grep -q "DEAL_II_WITH_MPI.*ON" "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake"; then
        echo "✅ deal.II built with MPI support"
    else
        echo "❌ deal.II was not built with MPI support"
        exit 1
    fi
else
    echo "❌ Cannot check deal.II MPI configuration"
    exit 1
fi

# Test MPI-specific functionality with a small program
TEST_DIR="/tmp/deal-ii-mpi-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(deal_ii_mpi_test)

find_package(deal.II REQUIRED)
find_package(MPI REQUIRED)

add_executable(mpi_test mpi_test.cpp)
target_link_libraries(mpi_test ${DEAL_II_LIBRARIES})
target_include_directories(mpi_test PRIVATE ${DEAL_II_INCLUDE_DIRS})
target_compile_definitions(mpi_test PRIVATE ${DEAL_II_DEFINITIONS})
EOF

cat > mpi_test.cpp << 'EOF'
#include <deal.II/base/config.h>
#include <deal.II/base/mpi.h>
#include <iostream>

int main(int argc, char *argv[]) {
    try {
        dealii::Utilities::MPI::MPI_InitFinalize mpi_initialization(argc, argv, 1);

        const int rank = dealii::Utilities::MPI::this_mpi_process(MPI_COMM_WORLD);
        const int size = dealii::Utilities::MPI::n_mpi_processes(MPI_COMM_WORLD);

        std::cout << "Hello from MPI rank " << rank << " of " << size << std::endl;

#ifdef DEAL_II_WITH_MPI
        std::cout << "deal.II built with MPI support" << std::endl;
#else
        std::cout << "deal.II built without MPI support" << std::endl;
#endif

        return 0;
    } catch (const std::exception &e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
EOF

if cmake . > cmake_mpi.log 2>&1; then
    echo "✅ MPI test CMake configuration successful"

    if make > build_mpi.log 2>&1; then
        echo "✅ MPI test program compiled successfully"

        # Test serial execution
        if ./mpi_test > run_mpi.log 2>&1; then
            echo "✅ MPI test program executed successfully"
            echo "ℹ️  Output: $(cat run_mpi.log)"
        else
            echo "❌ MPI test program execution failed"
            cat run_mpi.log
            cd /
            rm -rf "$TEST_DIR"
            exit 1
        fi
    else
        echo "❌ MPI test program compilation failed"
        cat build_mpi.log
        cd /
        rm -rf "$TEST_DIR"
        exit 1
    fi
else
    echo "❌ MPI test CMake configuration failed"
    cat cmake_mpi.log
    cd /
    rm -rf "$TEST_DIR"
    exit 1
fi

# Clean up
cd /
rm -rf "$TEST_DIR"

echo ""
echo "🎉 MPI configuration tests completed successfully!"
