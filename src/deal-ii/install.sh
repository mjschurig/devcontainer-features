#!/bin/bash
set -e

# deal.II devcontainer feature installation script
# Follows dev container feature best practices

# Feature options (from environment variables)
VERSION="${VERSION:-9.6.0}"
ENABLE_MPI="${ENABLEMPI:-false}"
ENABLE_PETSC="${ENABLEPETSC:-false}"
ENABLE_TRILINOS="${ENABLETRILINOS:-false}"
BUILD_THREADS="${BUILDTHREADS:-4}"

# Logging functions
print_error() {
    echo -e "\033[0;31m[ERROR] $1\033[0m" 1>&2
}

print_info() {
    echo -e "\033[0;34m[INFO] $1\033[0m"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS] $1\033[0m"
}

# Root user check - following best practices
if [ "$(id -u)" -ne 0 ]; then
    print_error "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
    exit 1
fi

# Platform detection
. /etc/os-release
ARCHITECTURE="$(dpkg --print-architecture 2>/dev/null || echo "unknown")"

print_info "Detected OS: ${ID} ${VERSION_ID} (${VERSION_CODENAME:-unknown})"
print_info "Architecture: ${ARCHITECTURE}"

# Validate platform support
if [[ "${ID}" != "ubuntu" ]] && [[ "${ID}" != "debian" ]]; then
    print_error "This feature requires Ubuntu or Debian base images"
    print_error "Detected: ${ID}"
    exit 1
fi

# Idempotency check
if [ -d "/usr/local/deal.II" ] && [ -f "/usr/local/deal.II/lib/cmake/deal.II/deal.IIConfig.cmake" ]; then
    print_info "deal.II installation found at /usr/local/deal.II"

    # Try to detect installed version
    if command -v cmake >/dev/null 2>&1; then
        INSTALLED_VERSION=$(cmake -DDEAL_II_DIR=/usr/local/deal.II -P /dev/stdin 2>/dev/null <<< "
            find_package(deal.II QUIET)
            if(deal.II_FOUND)
                message(\${DEAL_II_VERSION})
            endif()
        " | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")

        if [ "${INSTALLED_VERSION}" = "${VERSION}" ]; then
            print_success "deal.II ${VERSION} is already installed. Skipping installation."
            exit 0
        else
            print_info "Different version installed (${INSTALLED_VERSION}). Installing version ${VERSION}..."
        fi
    else
        print_info "Cannot detect installed version. Proceeding with installation..."
    fi
fi

# Non-root user detection
USERNAME="${_REMOTE_USER:-"vscode"}"
USER_UID="${_REMOTE_USER_UID:-1000}"
USER_GID="${_REMOTE_USER_GID:-1000}"
USER_HOME="${_REMOTE_USER_HOME:-"/home/${USERNAME}"}"

print_info "Target user: ${USERNAME} (UID: ${USER_UID}, GID: ${USER_GID})"

# Configure non-interactive package installation
export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC

# Pre-configure tzdata to prevent interactive prompts
echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections 2>/dev/null || true
echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections 2>/dev/null || true

# Update package list
print_info "Updating package lists..."
apt-get update

# Install base dependencies
print_info "Installing base dependencies..."
apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    wget \
    ca-certificates \
    libboost-all-dev \
    libblas-dev \
    liblapack-dev \
    zlib1g-dev \
    git \
    curl \
    pkg-config

# Install optional MPI support
if [ "${ENABLE_MPI}" = "true" ]; then
    print_info "Installing MPI support..."
    apt-get install -y --no-install-recommends \
        libopenmpi-dev \
        openmpi-bin \
        openmpi-common
fi

# Install optional PETSc support
if [ "${ENABLE_PETSC}" = "true" ]; then
    print_info "Installing PETSc..."
    apt-get install -y --no-install-recommends \
        petsc-dev \
        libpetsc-real-dev || {
            print_error "Failed to install PETSc from package repository"
            print_info "Continuing without PETSc support..."
            ENABLE_PETSC="false"
        }
fi

# Validate Trilinos dependency
if [ "${ENABLE_TRILINOS}" = "true" ]; then
    if [ ! -d "/usr/local/trilinos" ]; then
        print_error "Trilinos support requested but Trilinos installation not found at /usr/local/trilinos"
        print_error "Make sure the Trilinos feature is installed first"
        exit 1
    fi
    print_info "Trilinos installation found, configuring deal.II with Trilinos support"

    # Ensure MPI is enabled when Trilinos is used
    if [ "${ENABLE_MPI}" = "false" ]; then
        print_info "Enabling MPI automatically due to Trilinos dependency"
        ENABLE_MPI="true"
        apt-get install -y --no-install-recommends \
            libopenmpi-dev \
            openmpi-bin \
            openmpi-common
    fi
fi

# Create temporary build directory
BUILD_DIR="/tmp/dealii-build-$$"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Download deal.II source
print_info "Downloading deal.II ${VERSION}..."
DOWNLOAD_URL="https://github.com/dealii/dealii/releases/download/v${VERSION}/dealii-${VERSION}.tar.gz"
ARCHIVE_URL="https://github.com/dealii/dealii/archive/v${VERSION}.tar.gz"

if wget -q --spider "${DOWNLOAD_URL}"; then
    wget -q "${DOWNLOAD_URL}" -O "dealii-${VERSION}.tar.gz"
elif wget -q --spider "${ARCHIVE_URL}"; then
    print_info "Release tarball not found, using archive"
    wget -q "${ARCHIVE_URL}" -O "dealii-${VERSION}.tar.gz"
else
    print_error "Failed to download deal.II ${VERSION}"
    print_error "URLs tried:"
    print_error "  ${DOWNLOAD_URL}"
    print_error "  ${ARCHIVE_URL}"
    cd /
    rm -rf "${BUILD_DIR}"
    exit 1
fi

# Extract source
print_info "Extracting deal.II source..."
tar -xzf "dealii-${VERSION}.tar.gz"
cd "dealii-${VERSION}"

# Configure deal.II
print_info "Configuring deal.II..."
mkdir -p build && cd build

# Build CMake configuration
CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=/usr/local/deal.II"
CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_WITH_MPI=${ENABLE_MPI}"
CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_COMPONENT_DOCUMENTATION=OFF"
CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_COMPONENT_EXAMPLES=OFF"
CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_BUILD_TYPE=Release"

if [ "${ENABLE_PETSC}" = "true" ]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_WITH_PETSC=ON"
fi

if [ "${ENABLE_TRILINOS}" = "true" ]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DDEAL_II_WITH_TRILINOS=ON"
    CMAKE_ARGS="${CMAKE_ARGS} -DTrilinos_DIR=/usr/local/trilinos/lib/cmake/Trilinos"
fi

# Run CMake configuration
if ! cmake .. ${CMAKE_ARGS}; then
    print_error "CMake configuration failed"
    cd /
    rm -rf "${BUILD_DIR}"
    exit 1
fi

# Build deal.II
print_info "Building deal.II (this may take a while)..."
if ! make -j"${BUILD_THREADS}"; then
    print_error "Build failed with ${BUILD_THREADS} threads, trying single thread..."
    if ! make -j1; then
        print_error "Build failed"
        cd /
        rm -rf "${BUILD_DIR}"
        exit 1
    fi
fi

# Install deal.II
print_info "Installing deal.II..."
make install

# Configure environment for non-root user
if [ "${USERNAME}" != "root" ] && [ -d "${USER_HOME}" ]; then
    print_info "Configuring environment for user ${USERNAME}..."

    # Create user's local bin directory if it doesn't exist
    mkdir -p "${USER_HOME}/.local/bin"

    # Add deal.II to user's PATH via .bashrc if not already present
    if ! grep -q "DEAL_II_DIR" "${USER_HOME}/.bashrc" 2>/dev/null; then
        {
            echo ""
            echo "# deal.II configuration"
            echo "export DEAL_II_DIR=/usr/local/deal.II"
            echo "export PATH=\${DEAL_II_DIR}/bin:\${PATH}"
        } >> "${USER_HOME}/.bashrc"
    fi

    # Ensure proper ownership
    chown -R "${USER_UID}:${USER_GID}" "${USER_HOME}/.local" 2>/dev/null || true
    chown "${USER_UID}:${USER_GID}" "${USER_HOME}/.bashrc" 2>/dev/null || true
fi

# Clean up
cd /
rm -rf "${BUILD_DIR}"
apt-get clean
rm -rf /var/lib/apt/lists/*

print_success "deal.II ${VERSION} installation completed successfully!"
print_info "DEAL_II_DIR: /usr/local/deal.II"
print_info "CMake will find deal.II automatically with find_package(deal.II)"

# Set environment variable for current session
export DEAL_II_DIR="/usr/local/deal.II"
