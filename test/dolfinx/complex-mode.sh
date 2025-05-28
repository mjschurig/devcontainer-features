#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - complex scalar mode scenario..."

# Check environment variable is set correctly
check "DOLFINX_SCALAR_MODE is complex" test "$DOLFINX_SCALAR_MODE" = "complex"

# Check DOLFINx works with complex numbers
check "DOLFINx complex mode functionality" conda run -n fenicsx-env python -c "
import dolfinx
import numpy as np
from mpi4py import MPI
from dolfinx import mesh, fem
import ufl

# Create mesh and function space
domain = mesh.create_unit_square(MPI.COMM_WORLD, 4, 4, mesh.CellType.triangle)
V = fem.FunctionSpace(domain, ('Lagrange', 1))

# Test with complex numbers
u = fem.Function(V)
u.x.array[:] = 1.0 + 2.0j  # Complex number assignment

# Verify it's working with complex scalars
assert np.iscomplexobj(u.x.array)
print('Complex scalar mode test passed')
"

# Check PETSc scalar type (should be complex)
check "PETSc complex scalar type" conda run -n fenicsx-env python -c "
import petsc4py
petsc4py.init()
from petsc4py import PETSc
scalar_type = PETSc.ScalarType
print(f'PETSc scalar type: {scalar_type}')
assert 'complex' in str(scalar_type).lower()
"

reportResults
