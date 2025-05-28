#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - custom environment name scenario..."

# Check custom conda environment exists
check "Custom conda environment exists" conda env list | grep -q "custom-dolfinx"

# Check DOLFINx works in custom environment
check "DOLFINx works in custom environment" conda run -n custom-dolfinx python -c "import dolfinx; print(f'DOLFINx version: {dolfinx.__version__}')"

# Check activation script references custom environment
check "Activation script uses custom environment" grep -q "custom-dolfinx" "$HOME/.dolfinx_env"

# Check mode switching scripts use custom environment
check "Mode switching scripts use custom environment" grep -q "custom-dolfinx" "$HOME/dolfinx-real-mode"

# Test basic functionality in custom environment
check "Basic functionality in custom environment" conda run -n custom-dolfinx python -c "
import dolfinx
from mpi4py import MPI
from dolfinx import mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 2, 2, mesh.CellType.triangle)
print('Custom environment functionality test passed')
"

reportResults
