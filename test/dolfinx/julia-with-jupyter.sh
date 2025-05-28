#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - Julia with Jupyter..."

# Check Julia is installed
check "Julia is installed" which julia

# Check JupyterLab is installed
check "JupyterLab is installed" conda run -n fenicsx-env which jupyter-lab

# Check IJulia is installed
check "IJulia package installed" julia -e "using IJulia; println(\"IJulia loaded\")"

# Check Julia kernel is available
check "Julia kernel available" jupyter kernelspec list | grep -i julia

# Check FEniCS.jl works in Julia
check "FEniCS.jl test" julia -e "
using FEniCS
mesh = UnitSquareMesh(2, 2)
V = FunctionSpace(mesh, \"P\", 1)
println(\"Julia FEniCS test passed\")
"

# Check Jupyter startup script exists
check "Jupyter startup script exists" test -f ~/start_jupyter.sh

reportResults
