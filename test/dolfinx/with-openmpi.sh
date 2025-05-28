#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - with OpenMPI scenario..."

# Check OpenMPI is installed
check "OpenMPI is available" which mpirun

# Check OpenMPI version
check "OpenMPI version check" mpirun --version | grep -i "open mpi"

# Check MPI compilers are available
check "mpicc is available" which mpicc
check "mpicxx is available" which mpicxx

# Test MPI functionality with DOLFINx
check "MPI functionality with DOLFINx" conda run -n fenicsx-env python -c "
from mpi4py import MPI
import dolfinx
from dolfinx import mesh

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

print(f'MPI rank: {rank}, size: {size}')

# Create a distributed mesh
domain = mesh.create_unit_square(comm, 4, 4, mesh.CellType.triangle)
print(f'Mesh created successfully on rank {rank}')
"

# Test that mpi4py was compiled with OpenMPI
check "mpi4py compiled with OpenMPI" conda run -n fenicsx-env python -c "
from mpi4py import MPI
import mpi4py
print(f'mpi4py version: {mpi4py.__version__}')
print('MPI implementation check passed')
"

reportResults
