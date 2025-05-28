#!/bin/bash

# DOLFINx (FEniCSx) Installation Script
# This script installs DOLFINx using conda-forge packages

set -e

# Import feature options
VERSION=${VERSION:-"latest"}
SCALAR_MODE=${SCALARMODE:-"real"}
INSTALL_JUPYTER_LAB=${INSTALLJUPYTERLAB:-"false"}
START_JUPYTER_LAB=${STARTJUPYTERLAB:-"false"}
JUPYTER_PORT=${JUPYTERPORT:-"8888"}
JUPYTER_WORKSPACE_DIR=${JUPYTERWORKSPACEDIR:-"/workspace"}
INSTALL_VISUALIZATION=${INSTALLVISUALIZATION:-"true"}
INSTALL_OPTIONAL_DEPS=${INSTALLOPTIONALDEPS:-"true"}
MPI_IMPLEMENTATION=${MPIIMPLEMENTATION:-"mpich"}
PYTHON_VERSION=${PYTHONVERSION:-"3.11"}
CONDA_ENV_NAME=${CONDAENVIRONMENTNAME:-"fenicsx-env"}
INSTALL_EXAMPLES=${INSTALLEXAMPLES:-"true"}
ENABLE_DEVELOPMENT_TOOLS=${ENABLEDEVELOPMENTTOOLS:-"false"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to run commands as user (handles both sudo and non-sudo environments)
run_as_user() {
    if command -v sudo >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        sudo -u "$USERNAME" "$@"
    else
        # If no sudo or already running as target user, run directly
        "$@"
    fi
}

# Function to set file ownership (handles both sudo and non-sudo environments)
set_ownership() {
    local file_path="$1"
    if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        chown "$USERNAME:$USERNAME" "$file_path"
    fi
    # If not root or username is root, ownership is already correct
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root"
    exit 1
fi

# Get the username of the user who will use the environment
USERNAME="${_REMOTE_USER:-"${_REMOTE_USER_HOME##*/}"}"
if [ -z "$USERNAME" ]; then
    USERNAME="$(ls /home | head -n 1)"
fi
if [ -z "$USERNAME" ]; then
    USERNAME="vscode"
fi

USER_HOME="/home/$USERNAME"
if [ "$USERNAME" = "root" ]; then
    USER_HOME="/root"
fi

# Ensure user home directory exists
if [ ! -d "$USER_HOME" ]; then
    mkdir -p "$USER_HOME"
    if [ "$USERNAME" != "root" ]; then
        set_ownership "$USER_HOME"
    fi
fi

# Ensure .bashrc exists
if [ ! -f "$USER_HOME/.bashrc" ]; then
    touch "$USER_HOME/.bashrc"
    set_ownership "$USER_HOME/.bashrc"
fi

log_info "Installing DOLFINx for user: $USERNAME"
log_info "User home directory: $USER_HOME"

# Update package lists
log_info "Updating package lists..."
export DEBIAN_FRONTEND=noninteractive
apt-get update

# Install system dependencies
log_info "Installing system dependencies..."
apt-get install -y \
    wget \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    git \
    pkg-config

# Install development tools if requested
if [ "$ENABLE_DEVELOPMENT_TOOLS" = "true" ]; then
    log_info "Installing development tools..."
    apt-get install -y \
        cmake \
        gcc \
        g++ \
        gfortran \
        libboost-all-dev \
        libhdf5-dev \
        libhdf5-mpi-dev \
        libpugixml-dev \
        libspdlog-dev \
        libeigen3-dev
fi

# Function to check if conda/mamba is available
check_conda() {
    if command -v mamba >/dev/null 2>&1; then
        echo "mamba"
    elif command -v conda >/dev/null 2>&1; then
        echo "conda"
    else
        echo ""
    fi
}

# Install conda/mamba if not available
install_conda() {
    log_info "Installing Miniconda..."

    # Determine architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        CONDA_ARCH="x86_64"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        CONDA_ARCH="aarch64"
    else
        log_error "Unsupported architecture: $ARCH"
        exit 1
    fi

    # Download and install Miniconda
    CONDA_INSTALLER="Miniconda3-latest-Linux-${CONDA_ARCH}.sh"
    wget -q "https://repo.anaconda.com/miniconda/${CONDA_INSTALLER}" -O /tmp/miniconda.sh

    # Install for the user
    run_as_user bash /tmp/miniconda.sh -b -p "$USER_HOME/miniconda3"
    rm /tmp/miniconda.sh

    # Initialize conda for the user
    run_as_user "$USER_HOME/miniconda3/bin/conda" init bash

    # Install mamba for faster package resolution
    run_as_user "$USER_HOME/miniconda3/bin/conda" install -y -n base -c conda-forge mamba

    log_success "Miniconda and mamba installed successfully"
}

# Setup conda environment
setup_conda_env() {
    local conda_cmd="$1"
    local conda_path

    if [ "$conda_cmd" = "mamba" ]; then
        conda_path="$USER_HOME/miniconda3/bin/mamba"
    else
        conda_path="$USER_HOME/miniconda3/bin/conda"
    fi

    log_info "Setting up conda environment: $CONDA_ENV_NAME"

    # Create environment with specific Python version
    run_as_user "$conda_path" create -y -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION"

    log_success "Conda environment '$CONDA_ENV_NAME' created"
}

# Install DOLFINx and dependencies
install_dolfinx() {
    local conda_cmd="$1"
    local conda_path

    if [ "$conda_cmd" = "mamba" ]; then
        conda_path="$USER_HOME/miniconda3/bin/mamba"
    else
        conda_path="$USER_HOME/miniconda3/bin/conda"
    fi

    log_info "Installing DOLFINx with scalar mode: $SCALAR_MODE"

    # Prepare package list
    local packages="fenics-dolfinx"

    # Add version specification if not latest
    if [ "$VERSION" != "latest" ]; then
        packages="fenics-dolfinx=$VERSION"
    fi

    # Add MPI implementation
    packages="$packages $MPI_IMPLEMENTATION"

    # Add scalar mode specific packages
    if [ "$SCALAR_MODE" = "complex" ]; then
        log_info "Installing complex scalar mode packages..."
        packages="$packages petsc=*=complex* slepc=*=complex*"
    else
        log_info "Installing real scalar mode packages..."
        packages="$packages petsc slepc"
    fi

    # Add visualization if requested
    if [ "$INSTALL_VISUALIZATION" = "true" ]; then
        packages="$packages pyvista"
    fi

    # Add optional dependencies if requested
    if [ "$INSTALL_OPTIONAL_DEPS" = "true" ]; then
        packages="$packages numba pyamg slepc4py"
    fi

    # Add JupyterLab if requested
    if [ "$INSTALL_JUPYTER_LAB" = "true" ]; then
        packages="$packages jupyterlab ipywidgets"
    fi

    # Install packages
    log_info "Installing packages: $packages"
    run_as_user "$conda_path" install -y -n "$CONDA_ENV_NAME" -c conda-forge $packages

    log_success "DOLFINx installation completed"
}

# Install examples and demos
install_examples() {
    if [ "$INSTALL_EXAMPLES" = "true" ]; then
        log_info "Setting up DOLFINx examples..."

        # Create examples directory
        local examples_dir="$USER_HOME/dolfinx-examples"
        run_as_user mkdir -p "$examples_dir"

        # Clone DOLFINx repository for examples
        run_as_user git clone --depth 1 https://github.com/FEniCS/dolfinx.git "$examples_dir/dolfinx-repo"

        # Copy Python demos
        run_as_user cp -r "$examples_dir/dolfinx-repo/python/demo" "$examples_dir/"

        # Create a simple test script
        cat > "$examples_dir/test_dolfinx.py" << 'EOF'
#!/usr/bin/env python3
"""
Simple DOLFINx test script to verify installation
"""
import dolfinx
import numpy as np
from mpi4py import MPI

def test_dolfinx():
    print(f"DOLFINx version: {dolfinx.__version__}")
    print(f"MPI size: {MPI.COMM_WORLD.size}")
    print(f"MPI rank: {MPI.COMM_WORLD.rank}")

    # Create a simple mesh
    from dolfinx import mesh
    domain = mesh.create_unit_square(MPI.COMM_WORLD, 8, 8, mesh.CellType.triangle)
    print(f"Mesh created with {domain.topology.index_map(domain.topology.dim).size_global} cells")

    print("DOLFINx installation test: SUCCESS")

if __name__ == "__main__":
    test_dolfinx()
EOF

        set_ownership "$examples_dir/test_dolfinx.py"
        chmod +x "$examples_dir/test_dolfinx.py"

        log_success "Examples installed in $examples_dir"
    fi
}

# Setup environment activation
setup_environment() {
    log_info "Setting up environment activation..."

    # Create activation script
    cat > "$USER_HOME/.dolfinx_env" << EOF
#!/bin/bash
# DOLFINx Environment Setup

# Activate conda environment
source $USER_HOME/miniconda3/etc/profile.d/conda.sh
conda activate $CONDA_ENV_NAME

# Set scalar mode
export DOLFINX_SCALAR_MODE="$SCALAR_MODE"

# Add environment info
echo "DOLFINx Environment Active"
echo "Scalar Mode: $SCALAR_MODE"
echo "Conda Environment: $CONDA_ENV_NAME"
echo "Python: \$(which python)"

# Test DOLFINx import
python -c "import dolfinx; print(f'DOLFINx version: {dolfinx.__version__}')" 2>/dev/null || echo "Warning: DOLFINx import failed"
EOF

    set_ownership "$USER_HOME/.dolfinx_env"
    chmod +x "$USER_HOME/.dolfinx_env"

    # Add to bashrc
    if ! grep -q "source.*\.dolfinx_env" "$USER_HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$USER_HOME/.bashrc"
        echo "# DOLFINx Environment" >> "$USER_HOME/.bashrc"
        echo "source ~/.dolfinx_env" >> "$USER_HOME/.bashrc"
    fi

    log_success "Environment activation setup completed"
}

# Setup JupyterLab startup
setup_jupyter() {
    if [ "$INSTALL_JUPYTER_LAB" = "true" ] && [ "$START_JUPYTER_LAB" = "true" ]; then
        log_info "Setting up JupyterLab auto-start..."

        # Create JupyterLab startup script
        cat > "$USER_HOME/start_jupyter.sh" << EOF
#!/bin/bash
# JupyterLab Startup Script

source $USER_HOME/miniconda3/etc/profile.d/conda.sh
conda activate $CONDA_ENV_NAME

# Set working directory to workspace if it exists, otherwise use home
JUPYTER_WORKDIR="$JUPYTER_WORKSPACE_DIR"
if [ ! -d "\$JUPYTER_WORKDIR" ]; then
    JUPYTER_WORKDIR="$USER_HOME"
fi

# Create Jupyter config directory if it doesn't exist
mkdir -p "\$JUPYTER_WORKDIR/.jupyter"

# Configure Jupyter to use the workspace as root directory
cat > "\$JUPYTER_WORKDIR/.jupyter/jupyter_lab_config.py" << JUPYTER_CONFIG
# JupyterLab configuration for workspace alignment
c.ServerApp.root_dir = '\$JUPYTER_WORKDIR'
c.ServerApp.preferred_dir = '\$JUPYTER_WORKDIR'
c.FileContentsManager.root_dir = '\$JUPYTER_WORKDIR'
JUPYTER_CONFIG

# Set JUPYTER_CONFIG_DIR to use workspace config
export JUPYTER_CONFIG_DIR="\$JUPYTER_WORKDIR/.jupyter"

# Start JupyterLab from the workspace directory
cd "\$JUPYTER_WORKDIR"
jupyter lab --ip=0.0.0.0 --port=$JUPYTER_PORT --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password='' --config="\$JUPYTER_WORKDIR/.jupyter/jupyter_lab_config.py"
EOF

        set_ownership "$USER_HOME/start_jupyter.sh"
        chmod +x "$USER_HOME/start_jupyter.sh"

        # Create systemd service for JupyterLab (optional)
        cat > "/etc/systemd/system/jupyter-$USERNAME.service" << EOF
[Unit]
Description=JupyterLab for $USERNAME
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$JUPYTER_WORKSPACE_DIR
ExecStart=$USER_HOME/start_jupyter.sh
Restart=always
RestartSec=10
Environment=JUPYTER_CONFIG_DIR=$JUPYTER_WORKSPACE_DIR/.jupyter

[Install]
WantedBy=multi-user.target
EOF

        # Enable but don't start the service (user can start manually)
        systemctl daemon-reload
        systemctl enable "jupyter-$USERNAME.service"

        log_success "JupyterLab startup configured"
        log_info "To start JupyterLab manually: $USER_HOME/start_jupyter.sh"
        log_info "To start JupyterLab service: systemctl start jupyter-$USERNAME"
        log_info "JupyterLab will be available at: http://localhost:$JUPYTER_PORT"
        log_info "JupyterLab workspace: $JUPYTER_WORKSPACE_DIR (or $USER_HOME if $JUPYTER_WORKSPACE_DIR doesn't exist)"
    fi
}

# Create mode switching scripts
create_mode_scripts() {
    log_info "Creating scalar mode switching scripts..."

    # Real mode script
    cat > "$USER_HOME/dolfinx-real-mode" << EOF
#!/bin/bash
# Switch to real scalar mode

source $USER_HOME/miniconda3/etc/profile.d/conda.sh
conda activate $CONDA_ENV_NAME

# Install real mode packages
mamba install -y -c conda-forge petsc slepc fenics-dolfinx

export DOLFINX_SCALAR_MODE="real"
echo "Switched to DOLFINx real scalar mode"
EOF

    # Complex mode script
    cat > "$USER_HOME/dolfinx-complex-mode" << EOF
#!/bin/bash
# Switch to complex scalar mode

source $USER_HOME/miniconda3/etc/profile.d/conda.sh
conda activate $CONDA_ENV_NAME

# Install complex mode packages
mamba install -y -c conda-forge petsc=*=complex* slepc=*=complex* fenics-dolfinx

export DOLFINX_SCALAR_MODE="complex"
echo "Switched to DOLFINx complex scalar mode"
EOF

    set_ownership "$USER_HOME/dolfinx-real-mode" "$USER_HOME/dolfinx-complex-mode"
    chmod +x "$USER_HOME/dolfinx-real-mode" "$USER_HOME/dolfinx-complex-mode"

    log_success "Mode switching scripts created"
}

# Main installation process
main() {
    log_info "Starting DOLFINx installation..."
    log_info "Configuration:"
    log_info "  Version: $VERSION"
    log_info "  Scalar Mode: $SCALAR_MODE"
    log_info "  MPI Implementation: $MPI_IMPLEMENTATION"
    log_info "  Python Version: $PYTHON_VERSION"
    log_info "  Conda Environment: $CONDA_ENV_NAME"
    log_info "  Install JupyterLab: $INSTALL_JUPYTER_LAB"
    log_info "  Start JupyterLab: $START_JUPYTER_LAB"
    log_info "  JupyterLab Port: $JUPYTER_PORT"
    log_info "  JupyterLab Workspace: $JUPYTER_WORKSPACE_DIR"
    log_info "  Install Visualization: $INSTALL_VISUALIZATION"
    log_info "  Install Optional Dependencies: $INSTALL_OPTIONAL_DEPS"
    log_info "  Install Examples: $INSTALL_EXAMPLES"
    log_info "  Enable Development Tools: $ENABLE_DEVELOPMENT_TOOLS"

    # Check for existing conda installation
    CONDA_CMD=$(check_conda)
    if [ -z "$CONDA_CMD" ]; then
        install_conda
        CONDA_CMD="mamba"
    else
        log_info "Found existing conda/mamba installation: $CONDA_CMD"
    fi

    # Setup conda environment
    setup_conda_env "$CONDA_CMD"

    # Install DOLFINx
    install_dolfinx "$CONDA_CMD"

    # Install examples
    install_examples

    # Setup environment
    setup_environment

    # Setup JupyterLab if requested
    setup_jupyter

    # Create mode switching scripts
    create_mode_scripts

    # Final verification
    log_info "Verifying installation..."
    run_as_user bash -c "source $USER_HOME/.dolfinx_env && python -c 'import dolfinx; print(f\"DOLFINx {dolfinx.__version__} installed successfully\")'"

    log_success "DOLFINx installation completed successfully!"
    log_info ""
    log_info "Usage:"
    log_info "  - Activate environment: source ~/.dolfinx_env"
    log_info "  - Switch to real mode: ~/dolfinx-real-mode"
    log_info "  - Switch to complex mode: ~/dolfinx-complex-mode"
    log_info "  - Test installation: python ~/dolfinx-examples/test_dolfinx.py"

    if [ "$INSTALL_JUPYTER_LAB" = "true" ]; then
        log_info "  - Start JupyterLab: ~/start_jupyter.sh"
        log_info "  - JupyterLab URL: http://localhost:$JUPYTER_PORT"
    fi

    log_info ""
    log_info "Examples available in: ~/dolfinx-examples/"
}

# Run main installation
main "$@"
