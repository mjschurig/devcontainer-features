# DOLFINx (FEniCSx) Dev Container Feature

This feature installs [DOLFINx](https://fenicsproject.org/), the computational environment of FEniCSx, for solving partial differential equations using finite element methods.

## Features

- 🚀 **Easy Installation**: Automated installation using conda-forge packages
- 🔢 **Scalar Mode Support**: Switch between real and complex number modes
- 📊 **Visualization**: Optional PyVista integration for plotting
- 📓 **Jupyter Lab**: Optional JupyterLab installation with auto-start
- 🔧 **Development Tools**: Optional C++ development environment
- 📚 **Examples**: Includes DOLFINx examples and demos
- 🐍 **Python Versions**: Support for Python 3.9-3.12
- 🌐 **MPI Support**: Choice between MPICH and OpenMPI

## Usage

Add this feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/dolfinx:1": {}
  }
}
```

### Basic Configuration

```json
{
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/dolfinx:1": {
      "version": "latest",
      "scalarMode": "real",
      "installJupyterLab": true,
      "installVisualization": true
    }
  }
}
```

### Advanced Configuration

```json
{
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/dolfinx:1": {
      "version": "0.9.0",
      "scalarMode": "complex",
      "installJupyterLab": true,
      "startJupyterLab": true,
      "jupyterPort": "8888",
      "installVisualization": true,
      "installOptionalDeps": true,
      "mpiImplementation": "mpich",
      "pythonVersion": "3.11",
      "condaEnvironmentName": "fenicsx-env",
      "installExamples": true,
      "enableDevelopmentTools": true
    }
  },
  "forwardPorts": [8888]
}
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"latest"` | DOLFINx version to install (`latest`, `0.9.0`, `0.8.0`, `0.7.3`) |
| `scalarMode` | string | `"real"` | Scalar mode for DOLFINx/PETSc (`real` or `complex`) |
| `installJupyterLab` | boolean | `false` | Install JupyterLab for interactive development |
| `startJupyterLab` | boolean | `false` | Automatically start JupyterLab server |
| `jupyterPort` | string | `"8888"` | Port for JupyterLab server |
| `jupyterWorkspaceDir` | string | `"/workspace"` | Working directory for JupyterLab (should align with dev container workspace) |
| `installVisualization` | boolean | `true` | Install PyVista for visualization |
| `installOptionalDeps` | boolean | `true` | Install optional dependencies (numba, pyamg, slepc4py) |
| `mpiImplementation` | string | `"mpich"` | MPI implementation (`mpich` or `openmpi`) |
| `pythonVersion` | string | `"3.11"` | Python version (`3.12`, `3.11`, `3.10`, `3.9`) |
| `condaEnvironmentName` | string | `"fenicsx-env"` | Name for the conda environment |
| `installExamples` | boolean | `true` | Install DOLFINx examples and demos |
| `enableDevelopmentTools` | boolean | `false` | Install C++ development tools |

## Getting Started

After the container is built, the DOLFINx environment is automatically activated. You can start using DOLFINx immediately:

### Test Installation

```bash
# Test DOLFINx installation
python ~/dolfinx-examples/test_dolfinx.py
```

### Basic Example

```python
import dolfinx
import numpy as np
from mpi4py import MPI
from dolfinx import mesh, fem, plot
import ufl

# Create a unit square mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 8, 8, mesh.CellType.triangle)

# Define function space
V = fem.FunctionSpace(domain, ("Lagrange", 1))

# Define boundary condition
def boundary(x):
    return np.logical_or(np.isclose(x[0], 0), np.isclose(x[0], 1))

dofs = fem.locate_dofs_geometrical(V, boundary)
bc = fem.dirichletbc(0.0, dofs, V)

# Define variational problem
u = ufl.TrialFunction(V)
v = ufl.TestFunction(V)
f = fem.Constant(domain, 1.0)
a = ufl.dot(ufl.grad(u), ufl.grad(v)) * ufl.dx
L = f * v * ufl.dx

# Solve
problem = fem.petsc.LinearProblem(a, L, bcs=[bc])
uh = problem.solve()

print(f"Solution computed with {len(uh.x.array)} degrees of freedom")
```

## Scalar Mode Switching

The feature provides scripts to switch between real and complex scalar modes:

### Switch to Real Mode
```bash
~/dolfinx-real-mode
```

### Switch to Complex Mode
```bash
~/dolfinx-complex-mode
```

## JupyterLab Integration

If JupyterLab is installed, you can start it manually:

```bash
# Start JupyterLab
~/start_jupyter.sh
```

Or use the systemd service:

```bash
# Start JupyterLab service
sudo systemctl start jupyter-$(whoami)

# Stop JupyterLab service
sudo systemctl stop jupyter-$(whoami)
```

Access JupyterLab at `http://localhost:8888` (or your configured port).

## Workspace Configuration

This feature supports aligning the dev container workspace with JupyterLab's working directory, following [Jupyter's directory configuration guidelines](https://docs.jupyter.org/en/stable/use/jupyter-directories.html).

### Complete Dev Container Configuration

For optimal workspace alignment, configure your `devcontainer.json` as follows:

```json
{
  "name": "DOLFINx Development Environment",
  "image": "mcr.microsoft.com/devcontainers/python:3.11",

  // Set the workspace folder to align with JupyterLab
  "workspaceFolder": "/workspace",

  // Mount the workspace to ensure persistence
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
  ],

  "features": {
    "ghcr.io/mjschurig/devcontainer-features/dolfinx:1": {
      "installJupyterLab": true,
      "jupyterWorkspaceDir": "/workspace"
    }
  },

  "forwardPorts": [8888],

  "customizations": {
    "vscode": {
      "settings": {
        "jupyter.notebookFileRoot": "${workspaceFolder}"
      }
    }
  }
}
```

### Workspace Directory Options

- **Default**: `/workspace` - Aligns with dev container best practices
- **Custom**: Set `jupyterWorkspaceDir` to any directory path
- **Fallback**: If the specified directory doesn't exist, JupyterLab will use the user's home directory

### Benefits of Workspace Alignment

1. **Consistent File Access**: Both VS Code and JupyterLab work from the same directory
2. **Persistent Storage**: Files are preserved between container rebuilds
3. **Jupyter Configuration**: Jupyter config files are stored in the workspace
4. **Environment Variables**: `JUPYTER_CONFIG_DIR` is automatically set to the workspace

## Examples and Demos

The feature installs DOLFINx examples in `~/dolfinx-examples/`:

```bash
# List available demos
ls ~/dolfinx-examples/demo/

# Run a demo (example)
cd ~/dolfinx-examples/demo/
python demo_poisson.py
```

## Environment Management

### Manual Environment Activation

```bash
# Activate DOLFINx environment
source ~/.dolfinx_env
```

### Check Environment Status

```bash
# Check DOLFINx version
python -c "import dolfinx; print(f'DOLFINx version: {dolfinx.__version__}')"

# Check scalar mode
echo $DOLFINX_SCALAR_MODE

# Check MPI
python -c "from mpi4py import MPI; print(f'MPI size: {MPI.COMM_WORLD.size}')"
```

## Visualization with PyVista

If visualization is enabled, you can use PyVista for plotting:

```python
import dolfinx
import pyvista as pv
from dolfinx import mesh
from mpi4py import MPI

# Create mesh
domain = mesh.create_unit_square(MPI.COMM_WORLD, 10, 10)

# Convert to PyVista format
topology, cell_types, geometry = dolfinx.plot.create_vtk_mesh(domain, domain.topology.dim)
grid = pv.UnstructuredGrid(topology, cell_types, geometry)

# Plot
plotter = pv.Plotter()
plotter.add_mesh(grid, show_edges=True)
plotter.show()
```

## Development Tools

If development tools are enabled, you can build DOLFINx from source:

```bash
# Clone DOLFINx source
git clone https://github.com/FEniCS/dolfinx.git
cd dolfinx

# Build C++ core
mkdir cpp/build
cd cpp/build
cmake ..
make -j4

# Install Python interface
cd ../../python
pip install -e .
```

## Troubleshooting

### Common Issues

1. **Import Error**: If DOLFINx import fails, ensure the environment is activated:
   ```bash
   source ~/.dolfinx_env
   ```

2. **MPI Issues**: For MPI-related problems, check your MPI installation:
   ```bash
   mpirun --version
   python -c "from mpi4py import MPI; print('MPI working')"
   ```

3. **Complex Mode Issues**: When switching to complex mode, ensure all packages are compatible:
   ```bash
   ~/dolfinx-complex-mode
   python -c "import dolfinx; import petsc4py; print('Complex mode working')"
   ```

4. **JupyterLab Not Starting**: Check the startup script and port availability:
   ```bash
   # Check if port is in use
   netstat -tlnp | grep 8888

   # Start manually with different port
   jupyter lab --port=8889 --ip=0.0.0.0 --no-browser
   ```

### Performance Tips

1. **Use Mamba**: The feature automatically installs mamba for faster package resolution
2. **Parallel Builds**: Use multiple cores for compilation when building from source
3. **Memory Usage**: Complex mode requires more memory; consider increasing container resources

### Getting Help

- [DOLFINx Documentation](https://docs.fenicsproject.org/dolfinx/)
- [FEniCS Discourse](https://fenicsproject.discourse.group/)
- [DOLFINx GitHub Issues](https://github.com/FEniCS/dolfinx/issues)

## Dependencies

This feature installs the following main packages:

- **Core**: `fenics-dolfinx`, `petsc`, `slepc`
- **MPI**: `mpich` or `openmpi`
- **Python**: `python`, `numpy`, `mpi4py`
- **Optional**: `pyvista`, `numba`, `pyamg`, `slepc4py`
- **Development**: `jupyterlab`, `ipywidgets`

## License

This feature is provided under the same license terms as DOLFINx (LGPL-3.0-or-later).

## Contributing

Contributions are welcome! Please see the [main repository](https://github.com/mjschurig/devcontainer-features) for contribution guidelines.
