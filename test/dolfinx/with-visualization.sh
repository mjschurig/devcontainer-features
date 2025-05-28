#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - with visualization scenario..."

# Check PyVista is installed
check "PyVista is installed" conda run -n fenicsx-env python -c "import pyvista; print(f'PyVista version: {pyvista.__version__}')"

# Check DOLFINx plotting functionality
check "DOLFINx plotting functionality" conda run -n fenicsx-env python -c "
import dolfinx
import pyvista as pv
from mpi4py import MPI
from dolfinx import mesh

# Create a simple mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 4, 4, mesh.CellType.triangle)

# Test DOLFINx-PyVista integration
try:
    topology, cell_types, geometry = dolfinx.plot.create_vtk_mesh(domain, domain.topology.dim)
    grid = pv.UnstructuredGrid(topology, cell_types, geometry)
    print('DOLFINx-PyVista integration test passed')
except Exception as e:
    print(f'DOLFINx-PyVista integration test failed: {e}')
    raise
"

# Check that visualization dependencies are available
check "VTK is available" conda run -n fenicsx-env python -c "import vtk; print('VTK imported successfully')"

reportResults
