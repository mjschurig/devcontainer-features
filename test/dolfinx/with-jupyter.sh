#!/bin/bash
set -e

source dev-container-features-test-lib

echo "🧪 Testing DOLFINx feature - with Jupyter Lab scenario..."

# Check JupyterLab is installed
check "JupyterLab is installed" conda run -n fenicsx-env which jupyter-lab

# Check JupyterLab can be imported
check "JupyterLab import successful" conda run -n fenicsx-env python -c "import jupyterlab; print('JupyterLab imported successfully')"

# Check ipywidgets is available
check "ipywidgets is available" conda run -n fenicsx-env python -c "import ipywidgets; print('ipywidgets imported successfully')"

# Check startup script exists
check "JupyterLab startup script exists" test -f "$HOME/start_jupyter.sh"

# Check startup script is executable
check "JupyterLab startup script is executable" test -x "$HOME/start_jupyter.sh"

# Check systemd service file exists
check "JupyterLab systemd service exists" test -f "/etc/systemd/system/jupyter-$(whoami).service"

# Test that DOLFINx works in the same environment as Jupyter
check "DOLFINx works with Jupyter environment" conda run -n fenicsx-env python -c "
import dolfinx
import jupyterlab
print('DOLFINx and JupyterLab coexist successfully')
"

reportResults
