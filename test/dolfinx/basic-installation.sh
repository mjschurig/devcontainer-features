#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - basic installation scenario..."

# Check conda environment exists
check "DOLFINx conda environment exists" conda env list | grep -q "fenicsx-env"

# Check DOLFINx can be imported
check "DOLFINx import successful" conda run -n fenicsx-env python -c "import dolfinx; print(f'DOLFINx version: {dolfinx.__version__}')"

# Check basic functionality
check "Basic mesh creation works" conda run -n fenicsx-env python -c "
import dolfinx
from mpi4py import MPI
from dolfinx import mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 2, 2, mesh.CellType.triangle)
assert domain.topology.index_map(domain.topology.dim).size_global > 0
print('Basic functionality test passed')
"

reportResults
