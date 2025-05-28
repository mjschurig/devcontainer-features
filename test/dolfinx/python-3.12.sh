#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - Python 3.12 scenario..."

# Check Python version in conda environment
check "Python 3.12 is used" conda run -n fenicsx-env python --version | grep -q "3.12"

# Check DOLFINx works with Python 3.12
check "DOLFINx works with Python 3.12" conda run -n fenicsx-env python -c "
import sys
import dolfinx
print(f'Python version: {sys.version}')
print(f'DOLFINx version: {dolfinx.__version__}')
assert sys.version_info.major == 3
assert sys.version_info.minor == 12
print('Python 3.12 compatibility test passed')
"

# Test basic functionality with Python 3.12
check "Basic functionality with Python 3.12" conda run -n fenicsx-env python -c "
import dolfinx
from mpi4py import MPI
from dolfinx import mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 4, 4, mesh.CellType.triangle)
print('Python 3.12 functionality test passed')
"

reportResults
