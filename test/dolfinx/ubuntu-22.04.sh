#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - Ubuntu 22.04 scenario..."

# Check OS version
check "Running on Ubuntu 22.04" cat /etc/os-release | grep -q "22.04"

# Check that Python feature was installed first
check "Python is available" which python3

# Check DOLFINx installation
check "DOLFINx is installed" conda run -n fenicsx-env python -c "import dolfinx; print(f'DOLFINx version: {dolfinx.__version__}')"

# Check system compatibility
check "System libraries compatibility" conda run -n fenicsx-env python -c "
import dolfinx
from mpi4py import MPI
from dolfinx import mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 4, 4, mesh.CellType.triangle)
print('Ubuntu 22.04 compatibility test passed')
"

# Check that conda was installed properly
check "Conda environment works on Ubuntu 22.04" conda env list | grep -q "fenicsx-env"

reportResults
