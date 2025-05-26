# deal.II Feature Tests

This directory contains comprehensive tests for the deal.II devcontainer feature.

## Test Structure

### Test Scripts

- **`test.sh`** - Main test suite with 11 comprehensive tests
- **`default.sh`** - Tests for default configuration scenario
- **`default_debian.sh`** - Tests for default configuration on Debian
- **`with_mpi.sh`** - Tests for MPI-enabled configuration with advanced functionality testing
- **`with_petsc.sh`** - Tests for PETSc-enabled configuration
- **`with_trilinos.sh`** - Tests for Trilinos integration scenario
- **`full_features.sh`** - Tests for all features enabled scenario
- **`older_version.sh`** - Tests for specific version (9.5.0) scenario
- **`single_thread.sh`** - Tests for single-threaded build scenario
- **`idempotency.sh`** - Tests for installation idempotency scenario

### Test Scenarios

The `scenarios.json` file defines different test scenarios that cover:

| Scenario | Description | Features Tested | Test Script |
|----------|-------------|-----------------|-------------|
| `default` | Basic installation on Ubuntu | Default deal.II installation | `default.sh` |
| `default_debian` | Basic installation on Debian | Platform compatibility | `default_debian.sh` |
| `with_mpi` | MPI support enabled | OpenMPI integration | `with_mpi.sh` |
| `with_petsc` | PETSc support enabled | Linear algebra libraries | `with_petsc.sh` |
| `with_trilinos` | Trilinos support enabled | Advanced linear algebra with dependencies | `with_trilinos.sh` |
| `full_features` | All features enabled | Complete integration | `full_features.sh` |
| `older_version` | Specific version (9.5.0) | Version compatibility | `older_version.sh` |
| `single_thread` | Single-threaded build | Resource-constrained builds | `single_thread.sh` |
| `idempotency` | Multiple installations | Re-installation safety | `idempotency.sh` |

## Test Coverage

### Core Functionality Tests
1. **Installation Structure** - Verify directory layout
2. **Core Library Files** - Check CMake configs and libraries
3. **Header Files** - Validate include directories
4. **Environment Variables** - Test DEAL_II_DIR and CMAKE_PREFIX_PATH
5. **CMake Integration** - End-to-end build test
6. **Compiler Dependencies** - Check required tools

### Feature-Specific Tests
7. **MPI Support** - Validate MPI integration when enabled
8. **PETSc Support** - Check PETSc library integration
9. **Trilinos Support** - Test Trilinos dependency management
10. **Version Verification** - Confirm installed version
11. **Idempotency Check** - Ensure safe re-installation

### Advanced Integration Tests

#### MPI Testing (`with_mpi.sh`)
- Verifies MPI compilers are available
- Tests deal.II MPI configuration
- Compiles and runs MPI-enabled deal.II program
- Validates MPI initialization and process management

#### Trilinos Integration (`with_trilinos.sh`)
- Checks Trilinos installation is available
- Verifies deal.II was built with Trilinos support
- Tests CMake integration between deal.II and Trilinos
- Validates automatic MPI enablement

#### Full Features Testing (`full_features.sh`)
- Tests all features working together (MPI + PETSc + Trilinos)
- Comprehensive CMake integration test
- Compiles and executes program using all features

#### CMake Integration Testing
- Creates minimal CMake project
- Tests `find_package(deal.II)`
- Compiles and links against deal.II
- Executes test program to verify functionality

## Running Tests

### Using DevContainer CLI

```bash
# Test all scenarios
devcontainer features test --features src/deal-ii test/deal-ii

# Test specific scenario
devcontainer features test --features src/deal-ii test/deal-ii --scenario with_mpi
```

### Using Repository Scripts

```bash
# Test deal.II feature
test-feature deal-ii

# Test with specific base image
test-feature deal-ii mcr.microsoft.com/devcontainers/base:debian
```

## Test Philosophy

The tests follow the repository's testing guidelines:

1. **Comprehensive Coverage** - Test all major functionality and edge cases
2. **Multiple Platforms** - Ubuntu and Debian support
3. **Feature Combinations** - Test different option combinations
4. **Idempotency** - Ensure safe re-installation
5. **Integration** - End-to-end CMake and compilation testing
6. **Dependency Management** - Test feature dependencies (Trilinos)

## Expected Outcomes

All tests should pass for a properly functioning deal.II installation. The tests verify:

- ✅ deal.II installs correctly
- ✅ All required files are present
- ✅ Environment variables are set
- ✅ CMake can find and use deal.II
- ✅ Optional features (MPI, PETSc, Trilinos) work when enabled
- ✅ Feature is idempotent (safe to re-install)
- ✅ Works across supported platforms

## Troubleshooting

If tests fail, check:

1. **Build Resources** - deal.II requires significant memory (2GB+)
2. **Trilinos Dependency** - Ensure Trilinos feature is installed first when testing Trilinos scenarios
3. **Platform Support** - Only Ubuntu and Debian are supported
4. **Network Access** - Feature downloads source code from GitHub

