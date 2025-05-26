# deal.II

Installs [deal.II](https://www.dealii.org) (Differential Equations Analysis Library) - a C++ finite element library for solving partial differential equations.

## Overview

deal.II is a comprehensive C++ library that provides sophisticated algorithms and data structures for finite element programming. This feature installs deal.II with configurable support for MPI, PETSc, and Trilinos, making it ready for high-performance scientific computing in your dev container.

## Example Usage

### Basic Installation

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/deal-ii:1": {}
  }
}
```

### With MPI Support

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/deal-ii:1": {
      "version": "9.6.0",
      "enableMPI": true,
      "buildThreads": "8"
    }
  }
}
```

### With Full Linear Algebra Support (Trilinos + PETSc)

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/deal-ii:1": {
      "version": "9.6.0",
      "enableMPI": true,
      "enablePETSc": true,
      "enableTrilinos": true,
      "buildThreads": "8"
    }
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"9.6.0"` | Select the version of deal.II to install |
| `enableMPI` | boolean | `false` | Enable MPI support (installs OpenMPI) |
| `enablePETSc` | boolean | `false` | Enable PETSc support for linear algebra |
| `enableTrilinos` | boolean | `false` | Enable Trilinos support for linear algebra operations |
| `buildThreads` | string | `"4"` | Number of threads to use for building deal.II |

### Version Support

Currently supported deal.II versions:
- 9.2.0
- 9.3.0
- 9.4.0
- 9.5.0
- 9.5.1
- 9.5.2
- 9.6.0 (default)

## Dependencies

### Automatic Dependencies

When `enableTrilinos` is set to `true`, this feature automatically:
- Installs the Trilinos feature as a dependency
- Enables MPI support (required by Trilinos)
- Configures deal.II to use Trilinos for linear algebra operations

### Platform Requirements

- **Supported OS**: Ubuntu, Debian
- **Architecture**: x86_64, arm64
- **Base Images**: Debian-based images (Ubuntu, Debian)

## Environment Variables

After installation, the following environment variables are available:

| Variable | Value | Description |
|----------|-------|-------------|
| `DEAL_II_DIR` | `/usr/local/deal.II` | deal.II installation directory |
| `CMAKE_PREFIX_PATH` | Includes deal.II and Trilinos paths | CMake search paths |
| `TRILINOS_DIR` | `/usr/local/trilinos` | Trilinos installation directory (if enabled) |

## Usage Examples

### CMake Integration

```cmake
cmake_minimum_required(VERSION 3.10)
project(MyProject)

# Find deal.II (automatically uses DEAL_II_DIR)
find_package(deal.II REQUIRED)

# Create executable
add_executable(my_program main.cpp)

# Link with deal.II
target_link_libraries(my_program ${DEAL_II_LIBRARIES})
target_include_directories(my_program PRIVATE ${DEAL_II_INCLUDE_DIRS})
target_compile_definitions(my_program PRIVATE ${DEAL_II_DEFINITIONS})
```

### Basic C++ Program

```cpp
#include <deal.II/base/logstream.h>
#include <deal.II/grid/grid_generator.h>
#include <deal.II/grid/tria.h>

int main() {
    using namespace dealii;

    Triangulation<2> triangulation;
    GridGenerator::hyper_cube(triangulation);
    triangulation.refine_global(4);

    std::cout << "Number of cells: " << triangulation.n_active_cells() << std::endl;

    return 0;
}
```

## Trilinos Integration

When Trilinos support is enabled, deal.II gains access to powerful linear algebra capabilities:

### Features Available
- **Linear Solvers**: AztecOO iterative solvers
- **Preconditioners**: ML and MueLu multigrid preconditioners
- **Direct Solvers**: Amesos sparse direct solvers
- **Nonlinear Solvers**: NOX nonlinear solvers
- **Optimization**: ROL optimization library
- **Automatic Differentiation**: Sacado AD tools

### Example with Trilinos

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/deal-ii:1": {
      "enableTrilinos": true,
      "enableMPI": true
    }
  }
}
```

## Advanced Configuration

### Custom Build Options

For advanced users, deal.II is built with:
- Release configuration for optimal performance
- Documentation and examples disabled (lean installation)
- Support for 64-bit indices
- Threading support (TBB if available)

### File Locations

| Component | Location |
|-----------|----------|
| Headers | `/usr/local/deal.II/include/` |
| Libraries | `/usr/local/deal.II/lib/` |
| CMake Config | `/usr/local/deal.II/lib/cmake/deal.II/` |
| Documentation | Available online at [dealii.org](https://www.dealii.org) |

## Troubleshooting

### Common Issues

1. **Build fails with memory errors**: Reduce `buildThreads` to `"2"` or `"1"`
2. **MPI not found**: Ensure `enableMPI` is `true` when using parallel features
3. **Trilinos errors**: Verify Trilinos feature is properly installed first

### Debug Information

The feature provides detailed logging during installation. Check the container build logs for specific error messages.

## Performance Notes

- **Build Time**: deal.II compilation takes 15-45 minutes depending on options and hardware
- **Disk Space**: Installation requires ~500MB-1GB depending on enabled features
- **Memory**: Building requires at least 2GB RAM (4GB+ recommended)

## Related Features

- [Trilinos](../trilinos/README.md) - Advanced linear algebra library
- [common-utils](https://github.com/devcontainers/features/tree/main/src/common-utils) - Essential development tools

## References

- [deal.II Website](https://www.dealii.org)
- [deal.II Documentation](https://www.dealii.org/current/doxygen/deal.II/index.html)
- [deal.II Tutorial](https://www.dealii.org/current/doxygen/deal.II/Tutorial.html)
- [GitHub Repository](https://github.com/dealii/dealii)

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/mjschurig/deal-ii-devcontainer-feature/blob/main/src/deal-ii/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
