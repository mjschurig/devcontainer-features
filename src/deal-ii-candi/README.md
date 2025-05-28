# deal.II with candi

![Version](https://img.shields.io/badge/version-1.6.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

A comprehensive devcontainer feature for installing [deal.II](https://www.dealii.org/) using the [candi (Compile & Install)](https://github.com/dealii/candi) system with extensive package support including Trilinos, PETSc, p4est, HDF5, and many more scientific computing libraries.

## Overview

This feature provides a complete deal.II installation environment with:
- **Modern deal.II versions** (v9.3.0 to master)
- **30+ optional packages** for extended functionality
- **Flexible configuration** for development and production use
- **Optimized builds** with native CPU optimizations
- **System package fallbacks** for compatibility

## Quick Start

Add this feature to your `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/deal-ii-candi:1": {
      "dealiiVersion": "v9.6.1",
      "enableTrilinos": true,
      "enablePetsc": true,
      "enableP4est": true
    }
  }
}
```

## Configuration Options

### Core Configuration

#### `dealiiVersion` (string)
**Default:** `"v9.6.1"`
**Options:** `"master"`, `"v9.6.1"`, `"v9.6.0"`, `"v9.5.2"`, `"v9.5.1"`, `"v9.5.0"`, `"v9.4.0"`, `"v9.3.0"`

Select the version of deal.II to install. Use `"master"` for the latest development version.

```json
"dealiiVersion": "v9.6.1"
```

#### `installPath` (string)
**Default:** `"/usr/local/dealii-candi"`

Installation path for deal.II and all dependencies. All libraries will be installed under this prefix.

```json
"installPath": "/opt/dealii"
```

#### `buildJobs` (string)
**Default:** `"4"`

Number of parallel build jobs. Increase for faster builds on machines with more CPU cores, but be aware of memory requirements.

```json
"buildJobs": "8"
```

### Build Configuration

#### `cleanBuild` (boolean)
**Default:** `true`

Use fresh build directory by removing existing ones. Ensures clean builds but increases compilation time.

#### `nativeOptimizations` (boolean)
**Default:** `false`

Enable machine-specific optimizations (e.g., `-march=native`). Improves performance but reduces portability.

#### `use64BitIndices` (boolean)
**Default:** `false`

Enable 64-bit indices for large computations. Required for problems with more than ~2 billion degrees of freedom.

#### `buildExamples` (boolean)
**Default:** `true`

Enable building of deal.II examples. Useful for learning and testing but increases build time.

#### `runTests` (boolean)
**Default:** `false`

Run comprehensive tests after installation. Significantly increases build time but ensures correctness.

### Linear Algebra Libraries

#### `enableTrilinos` (boolean)
**Default:** `true`

Install Trilinos for advanced linear algebra operations. **Note:** Known compatibility issues with modern systems - system packages used by default.

Features:
- Advanced iterative solvers
- Preconditioners
- Parallel linear algebra
- ML/MueLu algebraic multigrid

#### `trilinosMajorVersion` (string)
**Default:** `"AUTO"`
**Options:** `"AUTO"`, `"16"`, `"15"`, `"14"`, `"13"`, `"12"`

Trilinos major version to use. `"AUTO"` selects the best compatible version.

#### `trilinosWithComplex` (boolean)
**Default:** `false`

Configure Trilinos with complex number support. **Warning:** Requires significantly more RAM and compilation time.

#### `enablePetsc` (boolean)
**Default:** `true`

Install PETSc for parallel linear algebra. **Note:** Known SCALAPACK/CMake compatibility issues - system packages used by default.

Features:
- Parallel sparse matrices and vectors
- Iterative solvers (GMRES, CG, BiCGStab, etc.)
- Preconditioners (ILU, algebraic multigrid, etc.)
- Nonlinear solvers (Newton methods)

#### `enableSlepc` (boolean)
**Default:** `true`

Install SLEPc for eigenvalue problems. **Note:** Requires candi PETSc - system packages used by default.

Features:
- Large-scale eigenvalue problems
- Singular value decomposition
- Matrix functions

### Mesh and Geometry Libraries

#### `enableP4est` (boolean)
**Default:** `true`

Install p4est for adaptive mesh refinement in parallel.

Features:
- Parallel adaptive mesh refinement
- Forest-of-octrees data structure
- Load balancing

#### `enableParmetis` (boolean)
**Default:** `true`

Install ParMETIS for mesh partitioning. **Note:** Known compatibility issues - system packages used by default.

Features:
- Graph partitioning
- Mesh partitioning for parallel computing

#### `enableOpencascade` (boolean)
**Default:** `true`

Install OpenCASCADE for CAD file support. **Note:** Known compatibility issues with modern systems - use system packages instead.

Features:
- STEP/IGES file import
- CAD geometry manipulation
- Mesh generation from CAD

#### `enableGmsh` (boolean)
**Default:** `false`

Install Gmsh for mesh generation.

Features:
- Automatic mesh generation
- Geometry modeling
- Post-processing

### Data I/O Libraries

#### `enableHdf5` (boolean)
**Default:** `true`

Install HDF5 for data I/O.

Features:
- Parallel data I/O
- Self-describing data format
- Compression support

#### `enableNetcdf` (boolean)
**Default:** `false`

Install NetCDF for scientific data I/O.

Features:
- Array-oriented scientific data
- Metadata support
- Cross-platform compatibility

### Mathematical Libraries

#### `enableSundials` (boolean)
**Default:** `true`

Install SUNDIALS for ODE/DAE solving. **Note:** Known compatibility issues - system packages used by default.

Features:
- CVODE for ODE solving
- IDA for DAE solving
- KINSOL for nonlinear systems

#### `enableSymengine` (boolean)
**Default:** `true`

Install SymEngine for symbolic computation.

Features:
- Symbolic differentiation
- Expression manipulation
- Computer algebra system

#### `enableGsl` (boolean)
**Default:** `false`

Install GSL (GNU Scientific Library).

Features:
- Special functions
- Random number generators
- Numerical integration
- Optimization algorithms

### Specialized Solvers

#### `enableSuperluDist` (boolean)
**Default:** `false`

Install SuperLU_DIST for distributed sparse direct solvers.

Features:
- Parallel sparse LU factorization
- Memory-efficient storage
- High performance on clusters

#### `enableMumps` (boolean)
**Default:** `false`

Install MUMPS for sparse direct solvers.

Features:
- Multifrontal sparse LU factorization
- Out-of-core capability
- Symmetric and unsymmetric matrices

#### `enableArpackNg` (boolean)
**Default:** `false`

Install ARPACK-NG for eigenvalue problems.

Features:
- Large sparse eigenvalue problems
- Implicitly restarted Arnoldi method
- Real and complex arithmetic

### Automatic Differentiation

#### `enableAdolc` (boolean)
**Default:** `false`

Install ADOL-C for automatic differentiation.

Features:
- Forward and reverse mode AD
- Higher-order derivatives
- Sparse Jacobians and Hessians

### Graphics and Visualization

#### `enableAssimp` (boolean)
**Default:** `false`

Install Assimp for 3D model loading.

Features:
- 40+ 3D file format support
- Mesh processing
- Animation support

### GPU Computing

#### `enableGinkgo` (boolean)
**Default:** `false`

Install Ginkgo for GPU-accelerated linear algebra.

Features:
- CUDA/HIP/OpenMP backends
- Sparse matrix operations
- Iterative solvers on GPU

### BLAS/LAPACK Libraries

#### `enableOpenblas` (boolean)
**Default:** `false`

Install OpenBLAS for optimized linear algebra.

Features:
- Optimized BLAS/LAPACK implementation
- Multi-threaded operations
- Architecture-specific optimizations

#### `enableScalapack` (boolean)
**Default:** `false`

Install ScaLAPACK for distributed linear algebra.

Features:
- Parallel dense linear algebra
- PBLAS parallel BLAS
- Distributed memory algorithms

#### `enableMkl` (boolean)
**Default:** `false`

Use Intel MKL for BLAS/LAPACK.

#### `mklDir` (string)
**Default:** `""`

Path to Intel MKL installation (if `enableMkl` is true).

#### `blasDir` (string)
**Default:** `""`

Path to custom BLAS installation.

#### `lapackDir` (string)
**Default:** `""`

Path to custom LAPACK installation.

### Compression Libraries

#### `enableZlib` (boolean)
**Default:** `false`

Install zlib compression library.

#### `enableBzip2` (boolean)
**Default:** `false`

Install bzip2 compression library.

### C++ Libraries

#### `enableBoost` (boolean)
**Default:** `false`

Install Boost C++ libraries.

Features:
- Extensive C++ utilities
- Smart pointers
- Containers and algorithms

### Development Tools

#### `enableGit` (boolean)
**Default:** `false`

Install Git version control system via candi.

#### `enableCmake` (boolean)
**Default:** `true`

Install CMake build system via candi.

#### `enableNumdiff` (boolean)
**Default:** `false`

Install numdiff numerical comparison tool.

Features:
- Compare numerical output files
- Tolerance-based comparison

#### `enableAstyle` (boolean)
**Default:** `false`

Install Astyle code formatter for development.

Features:
- C++ code formatting
- Multiple style options
- Integration with editors

### Advanced Options

#### `developerMode` (boolean)
**Default:** `false`

Enable developer mode to avoid package fetch and unpack. Requires a previous successful run.

#### `instantCleanBuild` (boolean)
**Default:** `true`

Remove build directory after successful installation to save space.

#### `instantCleanSrc` (boolean)
**Default:** `true`

Remove downloaded source files after successful installation.

#### `instantCleanUnpack` (boolean)
**Default:** `true`

Remove unpacked source files after successful installation.

## Example Configurations

### Minimal Setup
```json
{
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/deal-ii-candi:1": {
      "dealiiVersion": "v9.6.1"
    }
  }
}
```

### Research Configuration
```json
{
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/deal-ii-candi:1": {
      "dealiiVersion": "v9.6.1",
      "enableTrilinos": true,
      "enablePetsc": true,
      "enableSlepc": true,
      "enableP4est": true,
      "enableHdf5": true,
      "enableSundials": true,
      "enableSymengine": true,
      "use64BitIndices": true,
      "nativeOptimizations": true
    }
  }
}
```

### Full Development Setup
```json
{
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/deal-ii-candi:1": {
      "dealiiVersion": "master",
      "enableTrilinos": true,
      "enablePetsc": true,
      "enableSlepc": true,
      "enableP4est": true,
      "enableHdf5": true,
      "enableSundials": true,
      "enableSymengine": true,
      "enableGmsh": true,
      "enableAdolc": true,
      "enableGinkgo": true,
      "enableNumdiff": true,
      "enableAstyle": true,
      "buildExamples": true,
      "runTests": true,
      "nativeOptimizations": true
    }
  }
}
```

## Environment Variables

After installation, the following environment variables are automatically configured:

- `DEAL_II_DIR`: Path to deal.II installation
- `CMAKE_PREFIX_PATH`: Updated to include deal.II path
- `PATH`: Updated to include deal.II binaries
- `LD_LIBRARY_PATH`: Updated to include deal.II libraries
- `PKG_CONFIG_PATH`: Updated to include deal.II pkg-config files

## Usage in CMake Projects

```cmake
cmake_minimum_required(VERSION 3.16)
project(MyProject)

find_package(deal.II 9.6 REQUIRED
  HINTS ${DEAL_II_DIR} ${CMAKE_PREFIX_PATH}
)

# Create executable
add_executable(main main.cpp)

# Link with deal.II
target_link_libraries(main ${DEAL_II_LIBRARIES})
target_include_directories(main PRIVATE ${DEAL_II_INCLUDE_DIRS})
target_compile_definitions(main PRIVATE ${DEAL_II_DEFINITIONS})
target_compile_options(main PRIVATE ${DEAL_II_CXX_FLAGS})
```

## Known Issues and Workarounds

### Ubuntu 20.04 Specific Issues

**Based on community reports and GitHub issues, Ubuntu 20.04 has several known compatibility problems with candi builds:**

#### Trilinos Build Failures
- **Issue**: CMake installation errors with "Cannot open file for write" and "Permission denied" messages
- **Cause**: Known Trilinos CMake bug ([Trilinos #7419](https://github.com/trilinos/Trilinos/issues/7419)) affecting parallel builds
- **Workaround**: Feature automatically falls back to system packages (`libtrilinos-dev`)
- **Memory Requirements**: Trilinos builds require 4GB+ RAM, often exceeding container limits

#### GCC Version Requirements
- **Issue**: Trilinos/Kokkos requires GCC 8.2.0 or higher, but older Ubuntu versions (18.04, 16.04) ship with GCC 7.x
- **Cause**: Kokkos compiler compatibility requirements for modern C++ features
- **Solution**: Feature automatically detects older GCC versions and installs GCC 9 from Ubuntu toolchain PPA
- **Verification**: Check active GCC version with `gcc --version` after installation

#### System Package Conflicts
- **Issue**: Incomplete system Trilinos packages cause configuration errors ([deal.II #17916](https://github.com/dealii/dealii/issues/17916))
- **Cause**: Ubuntu packages missing CMake configuration files for some Trilinos components
- **Workaround**: Feature includes comprehensive system package installation as fallback

#### SCALAPACK Dependencies
- **Issue**: Missing SCALAPACK libraries cause Trilinos configuration failures
- **Solution**: Feature automatically installs `libscalapack-openmpi-dev` and related packages

#### Community Recommendations
Multiple users in the [deal.II community forums](https://community.geodynamics.org/t/i-cant-use-candi-to-compile-deal-ii-9-3-here-are-the-error-messages/1961) recommend:
1. Using system packages instead of candi for Ubuntu 20.04
2. Installing additional dependencies: `libmumps-ptscotch-dev`, `libptscotch-dev`
3. Avoiding complex package combinations that exceed memory limits

### Memory and Build Time Considerations

### Troubleshooting Guide

#### If Trilinos Build Fails
1. **Check available memory**: Ensure at least 4GB RAM available
2. **Reduce parallel jobs**: Set `buildJobs` to "1" or "2"
3. **Use system packages**: Set `enableTrilinos=false` and rely on system installation
4. **Check logs**: Look for "Permission denied" or "Cannot open file for write" errors

#### If System Package Installation Fails
```bash
# Manually install missing dependencies
sudo apt-get update
sudo apt-get install -y \
    libtrilinos-dev \
    libscalapack-openmpi-dev \
    libmumps-ptscotch-dev \
    libptscotch-dev \
    libsuitesparse-dev
```

#### Container Memory Issues
- **Symptoms**: Build processes killed, "make: *** [target] Error 137"
- **Solution**: Increase Docker memory limit to 8GB+ or use fewer parallel jobs

### References and Further Reading

- [Trilinos CMake Permission Issues](https://github.com/trilinos/Trilinos/issues/7419)
- [deal.II System Package Problems](https://github.com/dealii/dealii/issues/17916)
- [Community Discussion on Ubuntu 20.04 Issues](https://community.geodynamics.org/t/i-cant-use-candi-to-compile-deal-ii-9-3-here-are-the-error-messages/1961)
- [Xyce Build Issues on Ubuntu 20.04](https://github.com/Xyce/Xyce/issues/100)
- [Official deal.II Trilinos Documentation](https://dealii.org/developer/external-libs/trilinos.html)

## Contributing

Issues and pull requests are welcome at the [devcontainer-features repository](https://github.com/mjschurig/devcontainer-features).

## License

This devcontainer feature is licensed under the MIT License. deal.II and candi have their own respective licenses.

## References

- [deal.II Website](https://www.dealii.org/)
- [deal.II Documentation](https://www.dealii.org/current/doxygen/deal.II/)
- [candi Repository](https://github.com/dealii/candi)
- [Devcontainer Features Specification](https://containers.dev/implementors/features/)
