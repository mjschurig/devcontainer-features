# deal.II with candi

Installs [deal.II](https://www.dealii.org/) using [candi](https://github.com/dealii/candi) (Compile & Install) with comprehensive package support including Trilinos, PETSc, p4est, HDF5, and more.

## Recent Changes - Compatibility Fixes

⚠️ **Important Update**: The OpenCASCADE, ParMETIS, SUNDIALS, Trilinos, PETSc, and SLEPc options have been updated to address compatibility issues with modern systems.

### What Changed

1. **Default disabled**: `enableOpencascade`, `enableParmetis`, `enableSundials`, `enableTrilinos`, `enablePetsc`, and `enableSlepc` are now `false` by default due to known build failures with candi's outdated versions
2. **System packages**: The feature now automatically installs modern system packages as a fallback for OpenCASCADE, ParMETIS/METIS, SUNDIALS, Trilinos, PETSc/SCALAPACK, and SLEPc
3. **Automatic detection**: deal.II will automatically use system packages when available

### OpenCASCADE Options

- **Recommended**: Keep `enableOpencascade: false` (default) and rely on system packages
- **Advanced users**: Set `enableOpencascade: true` only if you specifically need candi's version and can troubleshoot build issues

### ParMETIS/METIS Options

- **Recommended**: Keep `enableParmetis: false` (default) and rely on system packages
- **Advanced users**: Set `enableParmetis: true` only if you specifically need candi's version and can troubleshoot build issues

### SUNDIALS Options

- **Recommended**: Keep `enableSundials: false` (default) and rely on system packages
- **Advanced users**: Set `enableSundials: true` only if you specifically need candi's version and can troubleshoot build issues

### Trilinos Options

- **Recommended**: Keep `enableTrilinos: false` (default) and rely on system packages
- **Advanced users**: Set `enableTrilinos: true` only if you specifically need candi's version and can troubleshoot build issues

### SLEPc Options

- **Recommended**: Keep `enableSlepc: false` (default) and rely on system packages
- **Advanced users**: Set `enableSlepc: true` only if you specifically need candi's version and can troubleshoot build issues

## Quick Start

### Basic Installation
```json
{
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/deal-ii-candi:1": {
      "dealiiVersion": "v9.6.1"
    }
  }
}
```

### Full-featured Installation
```json
{
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/deal-ii-candi:1": {
      "dealiiVersion": "v9.6.1",
      "enableTrilinos": true,
      "enablePetsc": true,
      "enableP4est": true,
      "enableHdf5": true,
      "buildJobs": "8"
    }
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dealiiVersion` | string | "v9.6.1" | deal.II version to install |
| `installPath` | string | "/usr/local/dealii-candi" | Installation directory |
| `buildJobs` | string | "4" | Number of parallel build jobs |
| `enableTrilinos` | boolean | **false** | Install Trilinos via candi (not recommended) |
| `enablePetsc` | boolean | **false** | Install PETSc via candi (not recommended) |
| `enableSlepc` | boolean | **false** | Install SLEPc via candi (not recommended) |
| `enableP4est` | boolean | true | Install p4est |
| `enableHdf5` | boolean | true | Install HDF5 |
| `enableOpencascade` | boolean | **false** | Install OpenCASCADE via candi (not recommended) |
| `enableParmetis` | boolean | **false** | Install ParMETIS via candi (not recommended) |
| `enableSundials` | boolean | **false** | Install SUNDIALS via candi (not recommended) |
| `enableSymengine` | boolean | true | Install SymEngine |

## Environment Variables

After installation, these environment variables are automatically set:

- `DEAL_II_DIR`: `/usr/local/dealii-candi`
- `CMAKE_PREFIX_PATH`: Updated to include deal.II installation
- `PATH`: Updated to include deal.II binaries
- `LD_LIBRARY_PATH`: Updated to include deal.II libraries
- `PKG_CONFIG_PATH`: Updated for pkg-config

## System Requirements

- **Time**: 2-6 hours (depending on enabled packages)
- **RAM**: At least 4GB recommended for compilation
- **Disk**: ~5GB for full installation with all packages
- **Base image**: Debian/Ubuntu-based container

## Troubleshooting

### OpenCASCADE Issues
If you encounter OpenCASCADE-related build failures:
1. Ensure `enableOpencascade` is `false` (default)
2. The feature will automatically install system OpenCASCADE packages
3. deal.II will detect and use system packages automatically

### ParMETIS/METIS Issues
If you encounter ParMETIS-related build failures:
1. Ensure `enableParmetis` is `false` (default)
2. The feature will automatically install system ParMETIS/METIS packages
3. deal.II will detect and use system packages automatically

### SUNDIALS Issues
If you encounter SUNDIALS-related build failures:
1. Ensure `enableSundials` is `false` (default)
2. The feature will automatically install system SUNDIALS packages
3. deal.II will detect and use system packages automatically

### PETSc Issues
If you encounter PETSc-related build failures (especially SCALAPACK/CMake errors):
1. Ensure `enablePetsc` is `false` (default)
2. The feature will automatically install system PETSc and SCALAPACK packages
3. deal.II will detect and use system packages automatically

### Trilinos Issues
If you encounter Trilinos-related build failures:
1. Ensure `enableTrilinos` is `false` (default)
2. The feature will automatically install system Trilinos packages
3. deal.II will detect and use system packages automatically

### SLEPc Issues
If you encounter SLEPc-related build failures (especially "PETSC_DIR not found" errors):
1. Ensure `enableSlepc` is `false` (default)
2. The feature will automatically install system SLEPc packages
3. deal.II will detect and use system packages automatically

### Memory Issues
If builds fail due to memory constraints:
- Reduce `buildJobs` to "2" or "1"
- Disable optional packages you don't need
- Use a container with more RAM

### Long Build Times
- Use more parallel jobs if you have sufficient RAM: `"buildJobs": "8"`
- Consider disabling packages you don't need
- Use a faster container host

## Package Details

### Core Packages (always installed)
- **deal.II**: Main finite element library
- **MPI**: Parallel computing support

### Default Packages
- **Trilinos**: Advanced linear algebra
- **PETSc**: Parallel linear algebra
- **SLEPc**: Eigenvalue problems
- **p4est**: Adaptive mesh refinement
- **HDF5**: Data I/O
- **SUNDIALS**: ODE/DAE solving
- **SymEngine**: Symbolic computation

### System Packages (automatically installed)
- **OpenCASCADE**: CAD file support (modern system version)
- **ParMETIS/METIS**: Mesh partitioning (modern system version)
- **SUNDIALS**: ODE/DAE solving (modern system version)
- **Trilinos**: Advanced linear algebra (modern system version)
- **PETSc/SCALAPACK**: Parallel linear algebra and distributed computing (modern system version)
- **SLEPc**: Eigenvalue problems (modern system version)

### Optional Packages
Set the corresponding `enable*` option to `true`:
- ADOL-C, ARPACK-NG, Assimp, Ginkgo, Gmsh, GSL, MUMPS, NetCDF, OpenBLAS, ScaLAPACK, SuperLU_DIST, zlib, bzip2, Boost

## License

This feature follows the same license as deal.II and candi. See the [deal.II license](https://github.com/dealii/dealii/blob/master/LICENSE.md) and [candi license](https://github.com/dealii/candi/blob/master/LICENSE) for details.

