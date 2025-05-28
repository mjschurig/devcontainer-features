#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - without examples scenario..."

# Check that examples directory does not exist
check "Examples directory does not exist" test ! -d "$HOME/dolfinx-examples"

# Check that DOLFINx still works without examples
check "DOLFINx works without examples" conda run -n fenicsx-env python -c "import dolfinx; print(f'DOLFINx version: {dolfinx.__version__}')"

# Check basic functionality still works
check "Basic functionality works without examples" conda run -n fenicsx-env python -c "
import dolfinx
from mpi4py import MPI
from dolfinx import mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 2, 2, mesh.CellType.triangle)
print('Basic functionality test passed without examples')
"

# Verify that the test script from examples is not present
check "Test script not present" test ! -f "$HOME/dolfinx-examples/test_dolfinx.py"

reportResults
