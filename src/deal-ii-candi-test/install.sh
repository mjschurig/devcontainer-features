#!/bin/bash

# deal.II with candi devcontainer feature installation script
# This script installs deal.II using the candi (Compile & Install) system
# with comprehensive package support and configuration options.

set -e

# Prevent interactive prompts during package installation
export DEBIAN_FRONTEND=noninteractive
export TZ=UTC

# Feature option defaults (these will be overridden by environment variables)
DEALII_VERSION=${DEALIIVERSION:-"v9.6.1"}
INSTALL_PATH=${INSTALLPATH:-"/usr/local/dealii-candi"}
BUILD_JOBS=${BUILDJOBS:-"4"}
CLEAN_BUILD=${CLEANBUILD:-"true"}
NATIVE_OPTIMIZATIONS=${NATIVEOPTIMIZATIONS:-"false"}
USE_64BIT_INDICES=${USE64BITINDICES:-"false"}
BUILD_EXAMPLES=${BUILDEXAMPLES:-"true"}
RUN_TESTS=${RUNTESTS:-"false"}

# Package options
ENABLE_TRILINOS=${ENABLETRILINOS:-"false"}
TRILINOS_MAJOR_VERSION=${TRILINOSMAJORVERSION:-"AUTO"}
TRILINOS_WITH_COMPLEX=${TRILINOSWITHCOMPLEX:-"false"}
ENABLE_PETSC=${ENABLEPETSC:-"false"}
ENABLE_SLEPC=${ENABLESLEPC:-"false"}
ENABLE_P4EST=${ENABLEP4EST:-"true"}
ENABLE_HDF5=${ENABLEHDF5:-"true"}
ENABLE_OPENCASCADE=${ENABLEOPENCASCADE:-"false"}
ENABLE_PARMETIS=${ENABLEPARMETIS:-"false"}
ENABLE_SUNDIALS=${ENABLESUNDIALS:-"false"}
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
ENABLE_GIT=${ENABLEGIT:-"false"}
ENABLE_CMAKE=${ENABLECMAKE:-"false"}
ENABLE_NUMDIFF=${ENABLENUMDIFF:-"false"}
ENABLE_ASTYLE=${ENABLEASTYLE:-"false"}

# Advanced options
ENABLE_MKL=${ENABLEMKL:-"false"}
MKL_DIR=${MKLDIR:-""}
BLAS_DIR=${BLASDIR:-""}
LAPACK_DIR=${LAPACKDIR:-""}
DEVELOPER_MODE=${DEVELOPERMODE:-"false"}
INSTANT_CLEAN_BUILD=${INSTANTCLEANBUILD:-"true"}
INSTANT_CLEAN_SRC=${INSTANTCLEANSRC:-"true"}
INSTANT_CLEAN_UNPACK=${INSTANTCLEANUNPACK:-"true"}

# Logging functions
log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1"
    exit 1
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "This script must be run as root"
    fi
}

# Auto-detect username for non-root operations
get_username() {
    # Use environment variables passed by devcontainer system
    if [ -n "${_REMOTE_USER:-}" ]; then
        echo "${_REMOTE_USER}"
    elif [ -n "${_CONTAINER_USER:-}" ]; then
        echo "${_CONTAINER_USER}"
    elif [ -n "${USERNAME:-}" ]; then
        echo "${USERNAME}"
    else
        echo "vscode"  # default fallback
    fi
}

# Detect operating system and package manager
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
        OS_VERSION=$(cat /etc/redhat-release | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    elif [ -f /etc/debian_version ]; then
        OS="debian"
        OS_VERSION=$(cat /etc/debian_version)
    else
        OS="unknown"
        OS_VERSION="unknown"
    fi

    log_info "Detected OS: $OS $OS_VERSION"
}

install_system_dependencies() {
    log_info "Installing system dependencies..."

    # Detect operating system
    detect_os

    case "$OS" in
        "ubuntu"|"debian")
            install_debian_dependencies
            ;;
        "centos"|"rhel"|"fedora")
            install_redhat_dependencies
            ;;
        *)
            log_warn "Unsupported operating system: $OS"
            log_warn "Attempting to install with generic approach..."
            install_generic_dependencies
            ;;
    esac

    log_info "System dependencies installed successfully"
}

install_debian_dependencies() {
    log_info "Installing dependencies for Debian/Ubuntu..."

    # Pre-configure tzdata to avoid interactive prompts
    if command -v debconf-set-selections >/dev/null 2>&1; then
        echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections
        echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections
        echo 'libc6 libraries/restart-without-asking boolean true' | debconf-set-selections
        echo 'libssl1.1:amd64 libraries/restart-without-asking boolean true' | debconf-set-selections

        # Reconfigure tzdata non-interactively
        dpkg-reconfigure -f noninteractive tzdata 2>/dev/null || true
    fi

    # Update package lists
    apt-get update

    # Install essential build tools and dependencies
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        gfortran \
        git \
        wget \
        curl \
        ca-certificates \
        pkg-config \
        libtool \
        autotools-dev \
        autoconf \
        automake \
        libopenmpi-dev \
        openmpi-bin \
        liblapack-dev \
        libblas-dev \
        libboost-all-dev \
        zlib1g-dev \
        libbz2-dev \
        python3 \
        python3-dev \
        python3-pip \
        doxygen \
        graphviz \
        texlive-latex-base \
        texlive-latex-extra \
        texlive-fonts-recommended \
        texlive-fonts-extra
}

install_redhat_dependencies() {
    log_info "Installing dependencies for CentOS/RHEL/Fedora..."

    # Set timezone non-interactively
    if [ -f /usr/share/zoneinfo/UTC ]; then
        ln -sf /usr/share/zoneinfo/UTC /etc/localtime
        echo "UTC" > /etc/timezone 2>/dev/null || true
    fi

    # Determine package manager
    if command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MGR="yum"
    else
        log_error "No package manager found (yum/dnf)"
        exit 1
    fi

    # Enable EPEL repository for CentOS/RHEL
    if [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        $PKG_MGR install -y epel-release || true
    fi

    # Update package lists
    $PKG_MGR update -y

    # Install development tools group
    $PKG_MGR groupinstall -y "Development Tools" || $PKG_MGR install -y gcc gcc-c++ make

    # Install essential build tools and dependencies
    $PKG_MGR install -y \
        gcc-gfortran \
        git \
        wget \
        curl \
        ca-certificates \
        pkgconfig \
        libtool \
        autoconf \
        automake \
        openmpi-devel \
        lapack-devel \
        blas-devel \
        boost-devel \
        zlib-devel \
        bzip2-devel \
        python3 \
        python3-devel \
        python3-pip \
        doxygen \
        graphviz \
        texlive-latex \
        texlive-collection-latexextra || true

    # Some packages might not be available, continue anyway
    log_info "Note: Some optional packages may not be available on $OS $OS_VERSION"
}

install_generic_dependencies() {
    log_info "Attempting generic dependency installation..."

    # Try to install basic build tools
    if command -v apt-get >/dev/null 2>&1; then
        install_debian_dependencies
    elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        install_redhat_dependencies
    else
        log_warn "No supported package manager found"
        log_warn "Please ensure the following are installed manually:"
        log_warn "- C/C++ compiler (gcc/g++)"
        log_warn "- Fortran compiler (gfortran)"
        log_warn "- Git, wget, curl"
        log_warn "- Build tools (make, autotools)"
        log_warn "- MPI development libraries"
        log_warn "- BLAS/LAPACK libraries"
        log_warn "- Python 3 with development headers"
    fi
}

# Clone and setup candi
setup_candi() {
    log_info "Setting up candi..."

    local candi_dir="/tmp/candi"

    # Remove existing candi directory if it exists
    if [ -d "$candi_dir" ]; then
        rm -rf "$candi_dir"
    fi

    # Clone candi repository
    git clone https://github.com/dealii/candi.git "$candi_dir"
    cd "$candi_dir"

    log_info "Candi cloned successfully"
}

# Generate candi configuration
generate_candi_config() {
    log_info "Generating candi configuration..."

    local config_file="/tmp/candi/devcontainer.cfg"

    cat > "$config_file" << EOF
# Generated candi configuration for devcontainer feature
# Global configuration
PROJECT=deal.II-toolchain

# Build configuration
CLEAN_BUILD=$([ "$CLEAN_BUILD" = "true" ] && echo "ON" || echo "OFF")
INSTALL_PATH=$INSTALL_PATH

# Mirror servers for faster downloads
MIRROR="https://tjhei.info/candi-mirror/ https://falankefu.clemson.edu/candi-mirror/"

# deal.II configuration
DEAL_II_CONFOPTS=""
NATIVE_OPTIMIZATIONS=$([ "$NATIVE_OPTIMIZATIONS" = "true" ] && echo "ON" || echo "OFF")
USE_64_BIT_INDICES=$([ "$USE_64BIT_INDICES" = "true" ] && echo "ON" || echo "OFF")
BUILD_EXAMPLES=$([ "$BUILD_EXAMPLES" = "true" ] && echo "ON" || echo "OFF")
USE_DEAL_II_CMAKE_MPI_COMPILER=OFF
RUN_DEAL_II_TESTS=$([ "$RUN_TESTS" = "true" ] && echo "ON" || echo "OFF")

# deal.II version
DEAL_II_VERSION=$DEALII_VERSION

# Trilinos configuration
TRILINOS_MAJOR_VERSION=$TRILINOS_MAJOR_VERSION
TRILINOS_WITH_COMPLEX=$([ "$TRILINOS_WITH_COMPLEX" = "true" ] && echo "ON" || echo "OFF")

# MKL configuration
MKL=$([ "$ENABLE_MKL" = "true" ] && echo "ON" || echo "OFF")
EOF

    # Add MKL directories if specified
    if [ -n "$MKL_DIR" ]; then
        echo "MKL_DIR=$MKL_DIR" >> "$config_file"
    fi
    if [ -n "$BLAS_DIR" ]; then
        echo "BLAS_DIR=$BLAS_DIR" >> "$config_file"
    fi
    if [ -n "$LAPACK_DIR" ]; then
        echo "LAPACK_DIR=$LAPACK_DIR" >> "$config_file"
    fi

    cat >> "$config_file" << EOF

# Developer mode
DEVELOPER_MODE=$([ "$DEVELOPER_MODE" = "true" ] && echo "ON" || echo "OFF")

# Cleanup options
INSTANT_CLEAN_BUILD_AFTER_INSTALL=$([ "$INSTANT_CLEAN_BUILD" = "true" ] && echo "ON" || echo "OFF")
INSTANT_CLEAN_SRC_AFTER_INSTALL=$([ "$INSTANT_CLEAN_SRC" = "true" ] && echo "ON" || echo "OFF")
INSTANT_CLEAN_UNPACK_AFTER_INSTALL=$([ "$INSTANT_CLEAN_UNPACK" = "true" ] && echo "ON" || echo "OFF")

# Package selection
PACKAGES="load:dealii-prepare"
EOF

    # Add system dependencies if enabled
    if [ "$ENABLE_ZLIB" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:zlib"' >> "$config_file"
    fi
    if [ "$ENABLE_BZIP2" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:bzip2"' >> "$config_file"
    fi
    if [ "$ENABLE_GIT" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:git"' >> "$config_file"
    fi
    if [ "$ENABLE_CMAKE" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:cmake"' >> "$config_file"
    fi
    if [ "$ENABLE_BOOST" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:boost"' >> "$config_file"
    fi
    if [ "$ENABLE_NUMDIFF" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:numdiff"' >> "$config_file"
    fi
    if [ "$ENABLE_OPENBLAS" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:openblas"' >> "$config_file"
    fi
    if [ "$ENABLE_SCALAPACK" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:scalapack"' >> "$config_file"
    fi

    # Add development tools if enabled
    if [ "$ENABLE_ASTYLE" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:astyle"' >> "$config_file"
    fi

    # Add scientific libraries if enabled
    if [ "$ENABLE_ADOLC" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:adolc"' >> "$config_file"
    fi
    if [ "$ENABLE_ARPACK_NG" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:arpack-ng"' >> "$config_file"
    fi
    if [ "$ENABLE_ASSIMP" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:assimp"' >> "$config_file"
    fi
    if [ "$ENABLE_GINKGO" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:ginkgo"' >> "$config_file"
    fi
    if [ "$ENABLE_GMSH" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:gmsh"' >> "$config_file"
    fi
    if [ "$ENABLE_GSL" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:gsl"' >> "$config_file"
    fi
    if [ "$ENABLE_MUMPS" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:mumps"' >> "$config_file"
    fi
    if [ "$ENABLE_OPENCASCADE" = "true" ]; then
        log_warn "OpenCASCADE has known compatibility issues with modern systems"
        echo 'PACKAGES="${PACKAGES} once:opencascade"' >> "$config_file"
    fi
    if [ "$ENABLE_PARMETIS" = "true" ]; then
        log_warn "ParMETIS has known compatibility issues - consider using system packages"
        echo 'PACKAGES="${PACKAGES} once:parmetis"' >> "$config_file"
    fi
    if [ "$ENABLE_SUNDIALS" = "true" ]; then
        log_warn "SUNDIALS has known compatibility issues - consider using system packages"
        echo 'PACKAGES="${PACKAGES} once:sundials"' >> "$config_file"
    fi
    if [ "$ENABLE_SUPERLU_DIST" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:superlu_dist"' >> "$config_file"
    fi
    if [ "$ENABLE_HDF5" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:hdf5"' >> "$config_file"
    fi
    if [ "$ENABLE_NETCDF" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:netcdf"' >> "$config_file"
    fi
    if [ "$ENABLE_P4EST" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:p4est"' >> "$config_file"
    fi
    if [ "$ENABLE_TRILINOS" = "true" ]; then
        log_warn "Trilinos has known compatibility issues - consider using system packages"
        echo 'PACKAGES="${PACKAGES} once:trilinos"' >> "$config_file"
    fi
    if [ "$ENABLE_PETSC" = "true" ]; then
        log_warn "PETSc has known SCALAPACK/CMake compatibility issues - consider using system packages"
        echo 'PACKAGES="${PACKAGES} once:petsc"' >> "$config_file"
    fi
    if [ "$ENABLE_SLEPC" = "true" ]; then
        log_warn "SLEPc requires candi PETSc - consider using system packages"
        echo 'PACKAGES="${PACKAGES} once:slepc"' >> "$config_file"
    fi
    if [ "$ENABLE_SYMENGINE" = "true" ]; then
        echo 'PACKAGES="${PACKAGES} once:symengine"' >> "$config_file"
    fi

    # Always add deal.II itself
    echo 'PACKAGES="${PACKAGES} dealii"' >> "$config_file"

    log_info "Candi configuration generated at $config_file"
}

# Install system packages for problematic candi packages
install_system_fallbacks() {
    log_info "Installing system packages for better compatibility..."

    case "$OS" in
        "ubuntu"|"debian")
            install_debian_fallbacks
            ;;
        "centos"|"rhel"|"fedora")
            install_redhat_fallbacks
            ;;
        *)
            log_warn "System package fallbacks not available for $OS"
            log_warn "Relying on candi for all packages"
            ;;
    esac
}

install_debian_fallbacks() {
    local packages_to_install=""

    # Install system packages for packages with known issues
    if [ "$ENABLE_TRILINOS" = "true" ]; then
        packages_to_install="$packages_to_install libtrilinos-dev"
    fi

    if [ "$ENABLE_PETSC" = "true" ]; then
        packages_to_install="$packages_to_install petsc-dev libpetsc-real-dev"
    fi

    if [ "$ENABLE_SLEPC" = "true" ]; then
        packages_to_install="$packages_to_install slepc-dev libslepc-real-dev"
    fi

    if [ "$ENABLE_PARMETIS" = "true" ]; then
        packages_to_install="$packages_to_install libparmetis-dev"
    fi

    if [ "$ENABLE_SUNDIALS" = "true" ]; then
        packages_to_install="$packages_to_install libsundials-dev"
    fi

    if [ "$ENABLE_OPENCASCADE" = "true" ]; then
        packages_to_install="$packages_to_install libocct-dev"
    fi

    if [ -n "$packages_to_install" ]; then
        log_info "Installing Debian/Ubuntu system fallback packages: $packages_to_install"
        DEBIAN_FRONTEND=noninteractive apt-get install -y $packages_to_install || log_warn "Some system packages could not be installed"
    fi
}

install_redhat_fallbacks() {
    local packages_to_install=""

    # Determine package manager
    if command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MGR="yum"
    else
        log_warn "No package manager found for Red Hat-based system"
        return
    fi

    # Install system packages for packages with known issues
    # Note: Many scientific packages may not be available on CentOS/RHEL
    if [ "$ENABLE_TRILINOS" = "true" ]; then
        packages_to_install="$packages_to_install trilinos-devel"
    fi

    if [ "$ENABLE_PETSC" = "true" ]; then
        packages_to_install="$packages_to_install petsc-devel"
    fi

    if [ "$ENABLE_SLEPC" = "true" ]; then
        packages_to_install="$packages_to_install slepc-devel"
    fi

    if [ "$ENABLE_PARMETIS" = "true" ]; then
        packages_to_install="$packages_to_install parmetis-devel"
    fi

    if [ "$ENABLE_SUNDIALS" = "true" ]; then
        packages_to_install="$packages_to_install sundials-devel"
    fi

    if [ "$ENABLE_OPENCASCADE" = "true" ]; then
        packages_to_install="$packages_to_install opencascade-devel"
    fi

    if [ -n "$packages_to_install" ]; then
        log_info "Installing Red Hat system fallback packages: $packages_to_install"
        $PKG_MGR install -y $packages_to_install || log_warn "Some system packages could not be installed (this is common on CentOS/RHEL)"
    else
        log_info "No system fallback packages needed for current configuration"
    fi
}

# Run candi installation
run_candi_installation() {
    log_info "Starting candi installation..."

    cd /tmp/candi

    # Make candi.sh executable
    chmod +x candi.sh

    # Run candi with our configuration
    local candi_args="-p $INSTALL_PATH -j $BUILD_JOBS --yes"

    log_info "Running: ./candi.sh $candi_args"
    log_info "Using configuration: devcontainer.cfg"
    log_info "This may take a very long time (1-3 hours depending on packages)..."

    # Copy our config over the default one
    cp devcontainer.cfg candi.cfg

    # Run the installation
    if ! ./candi.sh $candi_args; then
        log_error "Candi installation failed. Check the logs above for details."
    fi

    log_info "Candi installation completed successfully"
}

# Setup environment variables
setup_environment() {
    log_info "Setting up environment variables..."

    # Create environment setup script
    local env_script="/etc/profile.d/dealii-candi.sh"

    cat > "$env_script" << EOF
# deal.II candi environment setup
export DEAL_II_DIR="$INSTALL_PATH"
export CMAKE_PREFIX_PATH="$INSTALL_PATH:\${CMAKE_PREFIX_PATH}"
export PATH="$INSTALL_PATH/bin:\${PATH}"
export LD_LIBRARY_PATH="$INSTALL_PATH/lib:\${LD_LIBRARY_PATH}"
export PKG_CONFIG_PATH="$INSTALL_PATH/lib/pkgconfig:\${PKG_CONFIG_PATH}"
EOF

    chmod +x "$env_script"

    # Source the environment for current session
    source "$env_script"

    log_info "Environment variables configured"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."

    # Check if deal.II directory exists
    if [ ! -d "$INSTALL_PATH" ]; then
        log_error "Installation directory $INSTALL_PATH does not exist"
    fi

    # Check for deal.II configuration file
    local config_file="$INSTALL_PATH/lib/cmake/deal.II/deal.IIConfig.cmake"
    if [ ! -f "$config_file" ]; then
        log_error "deal.II configuration file not found at $config_file"
    fi

    # Check for deal.II headers
    local header_dir="$INSTALL_PATH/include/deal.II"
    if [ ! -d "$header_dir" ]; then
        log_error "deal.II headers not found at $header_dir"
    fi

    log_info "Installation verification completed successfully"
    log_info "deal.II has been installed to: $INSTALL_PATH"
    log_info "To use deal.II, source: /etc/profile.d/dealii-candi.sh"
}

# Cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."

    # Remove candi source directory
    if [ -d "/tmp/candi" ]; then
        rm -rf "/tmp/candi"
    fi

    # Clean package cache based on OS
    case "$OS" in
        "ubuntu"|"debian")
            if command -v apt-get >/dev/null 2>&1; then
                apt-get clean
                rm -rf /var/lib/apt/lists/*
            fi
            ;;
        "centos"|"rhel"|"fedora")
            if command -v dnf >/dev/null 2>&1; then
                dnf clean all
            elif command -v yum >/dev/null 2>&1; then
                yum clean all
            fi
            ;;
        *)
            log_info "No package cache cleanup for $OS"
            ;;
    esac

    # Reset environment variables
    unset DEBIAN_FRONTEND

    log_info "Cleanup completed"
}

# Main installation function
main() {
    log_info "Starting deal.II candi installation..."
    log_info "deal.II version: $DEALII_VERSION"
    log_info "Installation path: $INSTALL_PATH"
    log_info "Build jobs: $BUILD_JOBS"

    check_root
    install_system_dependencies
    install_system_fallbacks
    setup_candi
    generate_candi_config
    run_candi_installation
    setup_environment
    verify_installation
    cleanup

    log_info "deal.II candi installation completed successfully!"
    log_info ""
    log_info "To use deal.II in your projects:"
    log_info "1. Source the environment: source /etc/profile.d/dealii-candi.sh"
    log_info "2. Use CMAKE_PREFIX_PATH=$INSTALL_PATH in your CMake projects"
    log_info "3. Set DEAL_II_DIR=$INSTALL_PATH if needed"
    log_info ""
    log_info "For examples and documentation, visit: https://www.dealii.org/"
}

# Run main function
main "$@"
