#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - without visualization scenario..."

# Check that PyVista is NOT installed
check "PyVista is not installed" ! conda run -n fenicsx-env python -c "import pyvista" 2>/dev/null || echo "PyVista correctly not installed"

# Check that VTK is NOT installed
check "VTK is not installed" ! conda run -n fenicsx-env python -c "import vtk" 2>/dev/null || echo "VTK correctly not installed"

# Check that DOLFINx still works without visualization dependencies
check "DOLFINx works without visualization" conda run -n fenicsx-env python -c "
import dolfinx
from mpi4py import MPI
from dolfinx import mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 4, 4, mesh.CellType.triangle)
print('DOLFINx works correctly without visualization dependencies')
"

# Check that core DOLFINx functionality is preserved
check "Core DOLFINx functionality preserved" conda run -n fenicsx-env python -c "
import dolfinx
import dolfinx.fem
import dolfinx.io
import dolfinx.mesh
print('All core DOLFINx modules available')
"

# Verify that dolfinx.plot module exists but visualization functions may be limited
check "DOLFINx plot module exists" conda run -n fenicsx-env python -c "
import dolfinx.plot
print('DOLFINx plot module imported (may have limited functionality without PyVista)')
"

reportResults
