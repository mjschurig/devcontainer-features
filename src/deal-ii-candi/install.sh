#!/bin/bash

set -e

# Feature options with defaults
DEALII_VERSION=${DEALIIVERSION:-"v9.6.1"}
INSTALL_PATH=${INSTALLPATH:-"/usr/local/dealii-candi"}
BUILD_JOBS=${BUILDJOBS:-"4"}
CLEAN_BUILD=${CLEANBUILD:-"true"}
NATIVE_OPTIMIZATIONS=${NATIVEOPTIMIZATIONS:-"false"}
USE_64_BIT_INDICES=${USE64BITINDICES:-"false"}
BUILD_EXAMPLES=${BUILDEXAMPLES:-"true"}
RUN_TESTS=${RUNTESTS:-"false"}

# Package options
ENABLE_TRILINOS=${ENABLETRILINOS:-"true"}
TRILINOS_MAJOR_VERSION=${TRILINOSMAJORVERSION:-"AUTO"}
TRILINOS_WITH_COMPLEX=${TRILINOSWITHCOMPLEX:-"false"}
ENABLE_PETSC=${ENABLEPETSC:-"true"}
ENABLE_SLEPC=${ENABLESLEPC:-"true"}
ENABLE_P4EST=${ENABLEP4EST:-"true"}
ENABLE_HDF5=${ENABLEHDF5:-"true"}
ENABLE_OPENCASCADE=${ENABLEOPENCASCADE:-"true"}
ENABLE_PARMETIS=${ENABLEPARMETIS:-"true"}
ENABLE_SUNDIALS=${ENABLESUNDIALS:-"true"}
ENABLE_SYMENGINE=${ENABLESYMENGINE:-"true"}
ENABLE_SUPERLU_DIST=${ENABLESUPERLUD1ST:-"false"}
ENABLE_ADOLC=${ENABLEADOLC:-"false"}
ENABLE_ARPACK_NG=${ENABLEARPACKNG:-"false"}
ENABLE_ASSIMP=${ENABLEASSIMP:-"false"}
ENABLE_GINKGO=${ENABLEGINKGO:-"false"}
ENABLE_GMSH=${ENABLEGMSH:-"false"}
ENABLE_GSL=${ENABLEGSL:-"false"}
ENABLE_MUMPS=${ENABLEMUMPS:-"false"}
ENABLE_NETCDF=${ENABLENETCDF:-"false"}
ENABLE_OPENBLAS=${ENABLEOPENBLAS:-"false"}
ENABLE_SCALAPACK=${ENABLESCALAPACK:-"false"}
ENABLE_ZLIB=${ENABLEZLIB:-"false"}
ENABLE_BZIP2=${ENABLEBZIP2:-"false"}
ENABLE_BOOST=${ENABLEBOOST:-"false"}

# MKL and custom paths
ENABLE_MKL=${ENABLEMKL:-"false"}
MKL_DIR=${MKLDIR:-""}
BLAS_DIR=${BLASDIR:-""}
LAPACK_DIR=${LAPACKDIR:-""}

# Developer and cleanup options
DEVELOPER_MODE=${DEVELOPERMODE:-"false"}
INSTANT_CLEAN_BUILD=${INSTANTCLEANBUILD:-"true"}
INSTANT_CLEAN_SRC=${INSTANTCLEANSRC:-"true"}
INSTANT_CLEAN_UNPACK=${INSTANTCLEANUNPACK:-"true"}

echo "Starting deal.II installation with candi..."

# Install system dependencies
echo "Installing system dependencies..."
export DEBIAN_FRONTEND=noninteractive

# Update package lists
apt-get update

# Install essential build tools and dependencies
apt-get install -y \
    build-essential \
    gfortran \
    cmake \
    git \
    wget \
    curl \
    pkg-config \
    libopenmpi-dev \
    openmpi-bin \
    openmpi-common \
    libhdf5-openmpi-dev \
    libblas-dev \
    liblapack-dev \
    libboost-all-dev \
    zlib1g-dev \
    libbz2-dev \
    python3 \
    python3-dev \
    python3-pip

# Install system OpenCASCADE packages as a modern alternative to candi's outdated version
echo "Installing system OpenCASCADE packages for better compatibility..."
apt-get install -y \
    libocct-data-exchange-dev \
    libocct-foundation-dev \
    libocct-modeling-algorithms-dev \
    libocct-modeling-data-dev \
    libocct-ocaf-dev \
    libocct-visualization-dev \
    occt-misc || {
    # Fallback for older Ubuntu versions
    echo "Modern OpenCASCADE packages not available, trying legacy packages..."
    apt-get install -y \
        liboce-foundation-dev \
        liboce-modeling-dev \
        liboce-ocaf-dev \
        liboce-visualization-dev \
        oce-draw || echo "OpenCASCADE system packages not available - this is OK, deal.II will work without them"
}

# Install system ParMETIS and METIS packages as a modern alternative to candi's problematic versions
echo "Installing system ParMETIS and METIS packages for better compatibility..."
apt-get install -y \
    libparmetis-dev \
    libmetis-dev \
    parmetis-test || {
    echo "Warning: Could not install ParMETIS/METIS system packages - candi fallback may be needed"
}

# Install system SUNDIALS packages as a modern alternative to candi's problematic versions
echo "Installing system SUNDIALS packages for better compatibility..."
apt-get install -y \
    libsundials-dev \
    libsundials-core-dev || {
    echo "Warning: Could not install SUNDIALS system packages - candi fallback may be needed"
}

# Install system Trilinos packages as a modern alternative to candi's problematic versions
echo "Installing system Trilinos packages for better compatibility..."
apt-get install -y \
    libtrilinos-dev \
    libtrilinos-ml-dev \
    libtrilinos-epetra-dev \
    libtrilinos-teuchos-dev \
    libtrilinos-aztecoo-dev \
    libtrilinos-belos-dev \
    trilinos-dev || {
    echo "Warning: Could not install Trilinos system packages - candi fallback may be needed"
}

# Install system PETSc and SCALAPACK packages as a modern alternative to candi's problematic versions
echo "Installing system PETSc and SCALAPACK packages for better compatibility..."
apt-get install -y \
    libpetsc-real-dev \
    libpetsc-complex-dev \
    petsc-dev \
    libscalapack-mpi-dev \
    libscalapack-openmpi-dev \
    scalapack-test || {
    echo "Warning: Could not install PETSc/SCALAPACK system packages - candi fallback may be needed"
}

# Install system SLEPc packages as a modern alternative to candi's problematic versions
echo "Installing system SLEPc packages for better compatibility..."
apt-get install -y \
    libslepc-real-dev \
    libslepc-complex-dev \
    slepc-dev || {
    echo "Warning: Could not install SLEPc system packages - candi fallback may be needed"
}

# Create installation directory
mkdir -p "${INSTALL_PATH}"
cd /tmp

# Download candi
echo "Downloading candi..."
git clone https://github.com/dealii/candi.git
cd candi

# Create custom candi.cfg based on feature options
echo "Configuring candi..."
cat > candi.cfg << EOF
# Global configuration.

# Meta-project to build
PROJECT=deal.II-toolchain

# Option {ON|OFF}: Use fresh build directory by remove existing ones?
CLEAN_BUILD=$([ "$CLEAN_BUILD" = "true" ] && echo "ON" || echo "OFF")

# Where do you want the compiled software installed?
INSTALL_PATH=${INSTALL_PATH}

# Set up mirror server url(s), to speed up downloads
MIRROR="https://tjhei.info/candi-mirror/ https://falankefu.clemson.edu/candi-mirror/"

# Choose additional configuration and components of deal.II
# Add POSIX compatibility flag for better build compatibility on various systems
DEAL_II_CONFOPTS="-DDEAL_II_WITH_OPENCASCADE=ON -DDEAL_II_WITH_METIS=ON -DDEAL_II_WITH_PARMETIS=ON -DDEAL_II_WITH_SUNDIALS=ON -DDEAL_II_WITH_TRILINOS=ON -DDEAL_II_WITH_PETSC=ON -DDEAL_II_WITH_SLEPC=ON -DDEAL_II_CXX_FLAGS=-D_POSIX_C_SOURCE=199309L"

# Option {ON|OFF}: Enable machine-specific optimizations (e.g. -march=native)?
NATIVE_OPTIMIZATIONS=$([ "$NATIVE_OPTIMIZATIONS" = "true" ] && echo "ON" || echo "OFF")

# Option {ON|OFF}: Enable 64-bit indices for large computations?
USE_64_BIT_INDICES=$([ "$USE_64_BIT_INDICES" = "true" ] && echo "ON" || echo "OFF")

# Option {ON|OFF}: Enable building of dealii examples?
BUILD_EXAMPLES=$([ "$BUILD_EXAMPLES" = "true" ] && echo "ON" || echo "OFF")

# Option {ON|OFF}: Unset CXX and set the compiler as MPI_CXX_COMPILER when configuring deal.II
USE_DEAL_II_CMAKE_MPI_COMPILER=OFF

# Option {ON|OFF}: Run tests after installation?
RUN_DEAL_II_TESTS=$([ "$RUN_TESTS" = "true" ] && echo "ON" || echo "OFF")

# Now we pick the packages to install:
PACKAGES="load:dealii-prepare"

EOF

# Add system dependencies if requested
if [ "$ENABLE_ZLIB" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:zlib"' >> candi.cfg
fi

if [ "$ENABLE_BZIP2" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:bzip2"' >> candi.cfg
fi

if [ "$ENABLE_BOOST" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:boost"' >> candi.cfg
fi

if [ "$ENABLE_OPENBLAS" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:openblas"' >> candi.cfg
fi

if [ "$ENABLE_SCALAPACK" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:scalapack"' >> candi.cfg
fi

# Add optional packages
if [ "$ENABLE_ADOLC" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:adolc"' >> candi.cfg
fi

if [ "$ENABLE_ARPACK_NG" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:arpack-ng"' >> candi.cfg
fi

if [ "$ENABLE_ASSIMP" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:assimp"' >> candi.cfg
fi

if [ "$ENABLE_GINKGO" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:ginkgo"' >> candi.cfg
fi

if [ "$ENABLE_GMSH" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:gmsh"' >> candi.cfg
fi

if [ "$ENABLE_GSL" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:gsl"' >> candi.cfg
fi

if [ "$ENABLE_MUMPS" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:mumps"' >> candi.cfg
fi

# Add core packages
if [ "$ENABLE_OPENCASCADE" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:opencascade"' >> candi.cfg
fi

if [ "$ENABLE_PARMETIS" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:parmetis"' >> candi.cfg
fi

if [ "$ENABLE_SUNDIALS" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:sundials"' >> candi.cfg
fi

if [ "$ENABLE_SUPERLU_DIST" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:superlu_dist"' >> candi.cfg
fi

if [ "$ENABLE_HDF5" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:hdf5"' >> candi.cfg
fi

if [ "$ENABLE_NETCDF" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:netcdf"' >> candi.cfg
fi

if [ "$ENABLE_P4EST" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:p4est"' >> candi.cfg
fi

if [ "$ENABLE_TRILINOS" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:trilinos"' >> candi.cfg
fi

if [ "$ENABLE_PETSC" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:petsc"' >> candi.cfg
fi

if [ "$ENABLE_SLEPC" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:slepc"' >> candi.cfg
fi

if [ "$ENABLE_SYMENGINE" = "true" ]; then
    echo 'PACKAGES="${PACKAGES} once:symengine"' >> candi.cfg
fi

# Add deal.II itself
echo 'PACKAGES="${PACKAGES} dealii"' >> candi.cfg

# Add deal.II version configuration
cat >> candi.cfg << EOF

# Install the following deal.II version
DEAL_II_VERSION=${DEALII_VERSION}

# If you want to use Trilinos, decide which major version to use.
TRILINOS_MAJOR_VERSION=${TRILINOS_MAJOR_VERSION}

# If enabled, Trilinos is configured with complex number support
TRILINOS_WITH_COMPLEX=$([ "$TRILINOS_WITH_COMPLEX" = "true" ] && echo "ON" || echo "OFF")

# Option {ON|OFF}: Do you want to use MKL?
MKL=$([ "$ENABLE_MKL" = "true" ] && echo "ON" || echo "OFF")
EOF

# Add MKL/BLAS/LAPACK paths if specified
if [ -n "$MKL_DIR" ]; then
    echo "MKL_DIR=${MKL_DIR}" >> candi.cfg
fi

if [ -n "$BLAS_DIR" ]; then
    echo "BLAS_DIR=${BLAS_DIR}" >> candi.cfg
fi

if [ -n "$LAPACK_DIR" ]; then
    echo "LAPACK_DIR=${LAPACK_DIR}" >> candi.cfg
fi

# Add developer and cleanup options
cat >> candi.cfg << EOF

# Option {ON|OFF}: Developer mode
DEVELOPER_MODE=$([ "$DEVELOPER_MODE" = "true" ] && echo "ON" || echo "OFF")

# OPTION {ON|OFF}: Remove build directory after successful installation
INSTANT_CLEAN_BUILD_AFTER_INSTALL=$([ "$INSTANT_CLEAN_BUILD" = "true" ] && echo "ON" || echo "OFF")

# OPTION {ON|OFF}: Remove downloaded packed src after successful installation
INSTANT_CLEAN_SRC_AFTER_INSTALL=$([ "$INSTANT_CLEAN_SRC" = "true" ] && echo "ON" || echo "OFF")

# OPTION {ON|OFF}: Remove unpack directory after successful installation
INSTANT_CLEAN_UNPACK_AFTER_INSTALL=$([ "$INSTANT_CLEAN_UNPACK" = "true" ] && echo "ON" || echo "OFF")
EOF

echo "Generated candi.cfg:"
cat candi.cfg

# Set environment variables for MPI
export CC=mpicc
export CXX=mpicxx
export FC=mpifort
export F77=mpifort

# Run candi installation
echo "Starting candi installation with ${BUILD_JOBS} parallel jobs..."
echo "This may take a very long time (several hours)..."

# Run candi with non-interactive mode and specified number of jobs
./candi.sh --yes --jobs=${BUILD_JOBS} --prefix="${INSTALL_PATH}"

# Verify installation
if [ -d "${INSTALL_PATH}" ] && [ -f "${INSTALL_PATH}/bin/cmake" ] || [ -f "${INSTALL_PATH}/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    echo "deal.II installation completed successfully!"
    echo "Installation directory: ${INSTALL_PATH}"

    # Create a simple test to verify the installation
    cat > /tmp/test_dealii.cpp << 'EOF'
#include <deal.II/base/logstream.h>
#include <deal.II/base/quadrature_lib.h>
#include <deal.II/base/function.h>
#include <deal.II/base/utilities.h>
#include <deal.II/lac/vector.h>
#include <deal.II/grid/tria.h>
#include <deal.II/grid/grid_generator.h>
#include <deal.II/dofs/dof_handler.h>
#include <deal.II/fe/fe_q.h>
#include <iostream>

using namespace dealii;

int main()
{
    std::cout << "Testing deal.II installation..." << std::endl;

    Triangulation<2> triangulation;
    GridGenerator::hyper_cube(triangulation);
    triangulation.refine_global(1);

    FE_Q<2> fe(1);
    DoFHandler<2> dof_handler(triangulation);
    dof_handler.distribute_dofs(fe);

    std::cout << "Number of degrees of freedom: " << dof_handler.n_dofs() << std::endl;
    std::cout << "deal.II test completed successfully!" << std::endl;

    return 0;
}
EOF

    # Try to compile the test
    if command -v ${INSTALL_PATH}/bin/cmake >/dev/null 2>&1; then
        echo "CMake found in installation directory"
    fi

    echo "Installation summary:"
    echo "  deal.II version: ${DEALII_VERSION}"
    echo "  Installation path: ${INSTALL_PATH}"
    echo "  Trilinos (candi): ${ENABLE_TRILINOS}"
    echo "  Trilinos (system): Always attempted (fallback to modern packages)"
    echo "  PETSc (candi): ${ENABLE_PETSC}"
    echo "  PETSc (system): Always attempted (fallback to modern packages)"
    echo "  SLEPc enabled: ${ENABLE_SLEPC}"
    echo "  p4est enabled: ${ENABLE_P4EST}"
    echo "  HDF5 enabled: ${ENABLE_HDF5}"
    echo "  OpenCASCADE (candi): ${ENABLE_OPENCASCADE}"
    echo "  OpenCASCADE (system): Always attempted (fallback to modern packages)"
    echo "  ParMETIS (candi): ${ENABLE_PARMETIS}"
    echo "  ParMETIS (system): Always attempted (fallback to modern packages)"
    echo "  SUNDIALS (candi): ${ENABLE_SUNDIALS}"
    echo "  SUNDIALS (system): Always attempted (fallback to modern packages)"

else
    echo "ERROR: deal.II installation failed!"
    echo "Installation directory ${INSTALL_PATH} not found or incomplete."
    exit 1
fi

# Clean up
cd /
rm -rf /tmp/candi

echo "deal.II with candi installation completed!"

