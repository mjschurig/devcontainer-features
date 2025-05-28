#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - with optional dependencies scenario..."

# Check numba is installed
check "numba is installed" conda run -n fenicsx-env python -c "import numba; print(f'numba version: {numba.__version__}')"

# Check pyamg is installed
check "pyamg is installed" conda run -n fenicsx-env python -c "import pyamg; print(f'pyamg version: {pyamg.__version__}')"

# Check slepc4py is installed
check "slepc4py is installed" conda run -n fenicsx-env python -c "import slepc4py; print('slepc4py imported successfully')"

# Test numba functionality with DOLFINx
check "numba functionality test" conda run -n fenicsx-env python -c "
import numba
import numpy as np

@numba.jit
def test_function(x):
    return x * 2

result = test_function(5.0)
assert result == 10.0
print('numba functionality test passed')
"

# Test SLEPc functionality
check "SLEPc functionality test" conda run -n fenicsx-env python -c "
import slepc4py
slepc4py.init()
from slepc4py import SLEPc
print('SLEPc initialized successfully')
"

reportResults
