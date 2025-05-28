#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - basic installation..."

# Basic installation check
check "DOLFINx conda environment exists" conda env list | grep -q "${CONDA_ENV_NAME:-fenicsx-env}"

# Environment variables check
check "DOLFINX_SCALAR_MODE is set" test -n "$DOLFINX_SCALAR_MODE"

# Core functionality check
check "DOLFINx can be imported" conda run -n "${CONDA_ENV_NAME:-fenicsx-env}" python -c "import dolfinx; print(f'DOLFINx version: {dolfinx.__version__}')"

# MPI functionality check
check "MPI can be imported" conda run -n "${CONDA_ENV_NAME:-fenicsx-env}" python -c "from mpi4py import MPI; print(f'MPI size: {MPI.COMM_WORLD.size}')"

# Basic mesh creation test
check "Basic DOLFINx mesh creation" conda run -n "${CONDA_ENV_NAME:-fenicsx-env}" python -c "
import dolfinx
from mpi4py import MPI
from dolfinx import mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 4, 4, mesh.CellType.triangle)
print(f'Created mesh with {domain.topology.index_map(domain.topology.dim).size_global} cells')
"

# Check activation script exists
check "DOLFINx activation script exists" test -f "$HOME/.dolfinx_env"

# Check mode switching scripts exist
check "Mode switching scripts exist" test -f "$HOME/dolfinx-real-mode" && test -f "$HOME/dolfinx-complex-mode"

# Report result
reportResults
