#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - with Julia (no Jupyter)..."

# Check Julia is installed
check "Julia is installed" which julia

# Check Julia works
check "Julia version" julia --version

# Check FEniCS.jl is installed and works
check "FEniCS.jl basic test" julia -e "
using FEniCS
mesh = UnitSquareMesh(2, 2)
V = FunctionSpace(mesh, \"P\", 1)
println(\"Julia FEniCS test passed\")
"

# Check test script exists and runs
check "Julia test script runs" julia ~/test_fenics_jl.jl

reportResults
