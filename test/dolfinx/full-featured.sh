#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - full-featured scenario..."

# Check all major components are installed
check "DOLFINx is installed" conda run -n fenicsx-env python -c "import dolfinx; print(f'DOLFINx version: {dolfinx.__version__}')"
check "JupyterLab is installed" conda run -n fenicsx-env which jupyter-lab
check "PyVista is installed" conda run -n fenicsx-env python -c "import pyvista; print(f'PyVista version: {pyvista.__version__}')"
check "numba is installed" conda run -n fenicsx-env python -c "import numba; print(f'numba version: {numba.__version__}')"

# Check development tools
check "cmake is available" which cmake
check "gcc is available" which gcc

# Check examples are installed
check "Examples directory exists" test -d "$HOME/dolfinx-examples"
check "Test script exists" test -f "$HOME/dolfinx-examples/test_dolfinx.py"

# Check all scripts are present
check "Activation script exists" test -f "$HOME/.dolfinx_env"
check "Mode switching scripts exist" test -f "$HOME/dolfinx-real-mode" && test -f "$HOME/dolfinx-complex-mode"
check "Jupyter startup script exists" test -f "$HOME/start_jupyter.sh"

# Test comprehensive functionality using current DOLFINx API
check "Comprehensive DOLFINx test" conda run -n fenicsx-env python -c "
import dolfinx
import numpy as np
import pyvista as pv
from mpi4py import MPI
from dolfinx import mesh, fem, plot
from dolfinx.fem import functionspace
import ufl

# Create mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 8, 8, mesh.CellType.triangle)

# Define finite element function space using current API
V = functionspace(domain, ('Lagrange', 1))

# Define boundary condition function
uD = fem.Function(V)
uD.interpolate(lambda x: 1 + x[0]**2 + 2 * x[1]**2)

# Create facet to cell connectivity required to determine boundary facets
tdim = domain.topology.dim
fdim = tdim - 1
domain.topology.create_connectivity(fdim, tdim)
boundary_facets = mesh.exterior_facet_indices(domain.topology)

# Find boundary dofs
boundary_dofs = fem.locate_dofs_topological(V, fdim, boundary_facets)
bc = fem.dirichletbc(uD, boundary_dofs)

# Define variational problem
u = ufl.TrialFunction(V)
v = ufl.TestFunction(V)
f = fem.Constant(domain, -6.0)
a = ufl.dot(ufl.grad(u), ufl.grad(v)) * ufl.dx
L = f * v * ufl.dx

# Solve using current API
from dolfinx.fem.petsc import LinearProblem
problem = LinearProblem(a, L, bcs=[bc], petsc_options={'ksp_type': 'preonly', 'pc_type': 'lu'})
uh = problem.solve()

# Test visualization
topology, cell_types, geometry = plot.vtk_mesh(domain, domain.topology.dim)
grid = pv.UnstructuredGrid(topology, cell_types, geometry)

# Compute L2 error
V2 = functionspace(domain, ('Lagrange', 2))
uex = fem.Function(V2)
uex.interpolate(lambda x: 1 + x[0]**2 + 2 * x[1]**2)

L2_error = fem.form(ufl.inner(uh - uex, uh - uex) * ufl.dx)
error_local = fem.assemble_scalar(L2_error)
error_L2 = np.sqrt(domain.comm.allreduce(error_local, op=MPI.SUM))

print(f'Full-featured test passed: solved problem with {len(uh.x.array)} DOFs')
print(f'L2 error: {error_L2:.2e}')
"

reportResults
