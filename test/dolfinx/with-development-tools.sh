#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - with development tools scenario..."

# Check development tools are installed
check "cmake is available" which cmake
check "gcc is available" which gcc
check "g++ is available" which g++
check "gfortran is available" which gfortran

# Check development libraries
check "Boost development headers" test -d "/usr/include/boost" || dpkg -l | grep -q "libboost.*dev"
check "HDF5 development headers" dpkg -l | grep -q "libhdf5.*dev"
check "Eigen3 development headers" dpkg -l | grep -q "libeigen3-dev"

# Test basic compilation
check "Basic C++ compilation test" bash -c "
cat > /tmp/test.cpp << 'EOF'
#include <iostream>
#include <vector>
int main() {
    std::vector<double> v = {1.0, 2.0, 3.0};
    std::cout << 'Test compilation successful' << std::endl;
    return 0;
}
EOF
g++ -o /tmp/test /tmp/test.cpp && /tmp/test && rm -f /tmp/test /tmp/test.cpp
"

# Test CMake functionality
check "CMake functionality test" bash -c "
mkdir -p /tmp/cmake_test
cd /tmp/cmake_test
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(test)
add_executable(test test.cpp)
EOF
cat > test.cpp << 'EOF'
#include <iostream>
int main() {
    std::cout << \"CMake test successful\" << std::endl;
    return 0;
}
EOF
cmake . && make && ./test
cd / && rm -rf /tmp/cmake_test
"

reportResults
