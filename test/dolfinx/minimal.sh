#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - minimal scenario..."

# Check basic DOLFINx installation
check "DOLFINx is installed" conda run -n fenicsx-env python -c "import dolfinx; print(f'DOLFINx version: {dolfinx.__version__}')"

# Check that optional components are NOT installed
check "JupyterLab is NOT installed" ! conda run -n fenicsx-env which jupyter-lab 2>/dev/null || echo "JupyterLab not found (expected)"
check "PyVista is NOT installed" ! conda run -n fenicsx-env python -c "import pyvista" 2>/dev/null || echo "PyVista not found (expected)"
check "numba is NOT installed" ! conda run -n fenicsx-env python -c "import numba" 2>/dev/null || echo "numba not found (expected)"

# Check that examples are NOT installed
check "Examples directory does not exist" test ! -d "$HOME/dolfinx-examples"

# Check that development tools are NOT installed
check "cmake is NOT available" ! which cmake 2>/dev/null || echo "cmake not found (expected)"

# Check that Jupyter startup script does NOT exist
check "Jupyter startup script does not exist" test ! -f "$HOME/start_jupyter.sh"

# Check basic functionality still works
check "Basic DOLFINx functionality works" conda run -n fenicsx-env python -c "
import dolfinx
from mpi4py import MPI
from dolfinx import mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 4, 4, mesh.CellType.triangle)
print(f'Minimal installation test passed: created mesh with {domain.topology.index_map(domain.topology.dim).size_global} cells')
"

# Check that essential scripts still exist
check "Activation script exists" test -f "$HOME/.dolfinx_env"
check "Mode switching scripts exist" test -f "$HOME/dolfinx-real-mode" && test -f "$HOME/dolfinx-complex-mode"

reportResults
