#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - without optional dependencies scenario..."

# Check that numba is NOT installed
check "numba is not installed" ! conda run -n fenicsx-env python -c "import numba" 2>/dev/null || echo "numba correctly not installed"

# Check that pyamg is NOT installed
check "pyamg is not installed" ! conda run -n fenicsx-env python -c "import pyamg" 2>/dev/null || echo "pyamg correctly not installed"

# Check that slepc4py is NOT installed
check "slepc4py is not installed" ! conda run -n fenicsx-env python -c "import slepc4py" 2>/dev/null || echo "slepc4py correctly not installed"

# Check that DOLFINx still works without optional dependencies
check "DOLFINx works without optional deps" conda run -n fenicsx-env python -c "
import dolfinx
from mpi4py import MPI
from dolfinx import mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 4, 4, mesh.CellType.triangle)
print('DOLFINx works correctly without optional dependencies')
"

# Check that core functionality is preserved
check "Core DOLFINx functionality preserved" conda run -n fenicsx-env python -c "
import dolfinx
import dolfinx.fem
import dolfinx.io
import dolfinx.mesh
import dolfinx.plot
print('All core DOLFINx modules available')
"

reportResults
