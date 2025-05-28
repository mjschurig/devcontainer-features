#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - specific version scenario..."

# Check that DOLFINx version 0.9.0 is installed
check "DOLFINx version 0.9.0 is installed" conda run -n fenicsx-env python -c "
import dolfinx
version = dolfinx.__version__
print(f'DOLFINx version: {version}')
assert version.startswith('0.9.0'), f'Expected version 0.9.0, got {version}'
print('Specific version test passed')
"

# Check basic functionality with specific version
check "Basic functionality with version 0.9.0" conda run -n fenicsx-env python -c "
import dolfinx
from mpi4py import MPI
from dolfinx import mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 4, 4, mesh.CellType.triangle)
print('Version 0.9.0 functionality test passed')
"

reportResults
