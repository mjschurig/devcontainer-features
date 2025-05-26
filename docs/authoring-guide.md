# Feature Authoring Guide

This guide provides comprehensive instructions for creating new dev container features in this repository.

## Overview

A dev container feature is a self-contained unit of functionality that can be added to any dev container. Features consist of:

- **Metadata** (`devcontainer-feature.json`) - Configuration and options
- **Installation Script** (`install.sh`) - The actual installation logic
- **Documentation** (`README.md`) - Usage instructions and examples
- **Tests** (`test/feature-name/test.sh`) - Validation and testing

## Getting Started

### 1. Create Feature Structure

```bash
# Create directories
mkdir -p src/my-feature test/my-feature

# Create basic files
touch src/my-feature/devcontainer-feature.json
touch src/my-feature/install.sh
touch src/my-feature/README.md
touch test/my-feature/test.sh
```

### 2. Feature Metadata (`devcontainer-feature.json`)

This file defines the feature's metadata, options, and behavior.

```json
{
  "id": "my-feature",
  "version": "1.0.0",
  "name": "My Awesome Feature",
  "description": "A brief description of what this feature does",
  "documentationURL": "https://github.com/your-username/devcontainer-features/tree/main/src/my-feature",
  "keywords": ["example", "demo", "my-feature"],
  "options": {
    "version": {
      "type": "string",
      "proposals": ["latest", "1.0", "2.0"],
      "default": "latest",
      "description": "Version of the tool to install"
    },
    "enableFeatureX": {
      "type": "boolean",
      "default": false,
      "description": "Enable additional feature X"
    }
  },
  "containerEnv": {
    "MY_FEATURE_INSTALLED": "true"
  },
  "installsAfter": ["ghcr.io/devcontainers/features/common-utils"]
}
```

#### Required Fields

- `id`: Unique identifier (must match directory name)
- `version`: Semantic version (x.y.z)
- `name`: Human-readable name
- `description`: Brief description

#### Optional Fields

- `documentationURL`: Link to documentation
- `keywords`: Array of keywords for discovery
- `options`: User-configurable options
- `containerEnv`: Environment variables to set
- `dependsOn`: Features this depends on
- `installsAfter`: Features to install before this one

#### Option Types

- `string`: Text input with optional proposals
- `boolean`: True/false toggle

### 3. Installation Script (`install.sh`)

The installation script contains the actual logic to install and configure your feature.

#### Basic Template

```bash
#!/bin/bash
set -e

# Feature options (automatically set as environment variables)
VERSION=${VERSION:-"latest"}
ENABLE_FEATURE_X=${ENABLEFEATUREX:-"false"}

echo "Installing my-feature version $VERSION..."

# Platform detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Detected OS: $ID $VERSION_ID"
else
    echo "WARNING: Could not detect OS version"
fi

# Architecture detection
ARCHITECTURE="$(uname -m)"
echo "Detected architecture: $ARCHITECTURE"

# Validate platform support
case "$ID" in
    ubuntu|debian)
        echo "✓ Supported platform detected"
        PACKAGE_MANAGER="apt-get"
        ;;
    alpine)
        echo "✓ Alpine Linux detected"
        PACKAGE_MANAGER="apk"
        ;;
    *)
        echo "WARNING: Untested platform '$ID'"
        PACKAGE_MANAGER="apt-get"
        ;;
esac

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Script must be run as root"
    exit 1
fi

# Idempotency check
if command -v my-tool >/dev/null 2>&1; then
    echo "my-tool already installed, checking version..."
    CURRENT_VERSION=$(my-tool --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
    if [ "$CURRENT_VERSION" = "$VERSION" ]; then
        echo "✓ Correct version already installed"
        exit 0
    else
        echo "Different version detected, proceeding with installation..."
    fi
fi

# Install system dependencies
echo "Installing system dependencies..."
case "$PACKAGE_MANAGER" in
    apt-get)
        apt-get update
        apt-get install -y curl wget
        ;;
    apk)
        apk update
        apk add curl wget
        ;;
esac

# Main installation logic
echo "Installing my-tool..."
# Your installation commands here

# Verify installation
if command -v my-tool >/dev/null 2>&1; then
    echo "✓ my-tool installed successfully"
    my-tool --version
else
    echo "ERROR: Installation failed"
    exit 1
fi

# Configure for non-root user
if [ -n "$_REMOTE_USER" ] && [ "$_REMOTE_USER" != "root" ]; then
    echo "Configuring for user: $_REMOTE_USER"
    # User-specific configuration
fi

echo "Feature installation completed successfully!"
```

#### Best Practices

##### Error Handling

```bash
set -e  # Exit on any error

# Check prerequisites
if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is required but not installed"
    exit 1
fi
```

##### Idempotency

```bash
# Check if already installed
if command -v my-tool >/dev/null 2>&1; then
    echo "my-tool already installed"
    exit 0
fi

# Check if specific version is installed
CURRENT_VERSION=$(my-tool --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "")
if [ "$CURRENT_VERSION" = "$REQUESTED_VERSION" ]; then
    echo "Requested version already installed"
    exit 0
fi
```

##### Platform Detection

```bash
# OS detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu|debian)
            PACKAGE_MANAGER="apt-get"
            ;;
        alpine)
            PACKAGE_MANAGER="apk"
            ;;
        centos|rhel|fedora)
            PACKAGE_MANAGER="yum"
            ;;
        *)
            echo "Unsupported OS: $ID"
            exit 1
            ;;
    esac
fi

# Architecture detection
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)
        DOWNLOAD_ARCH="amd64"
        ;;
    aarch64|arm64)
        DOWNLOAD_ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac
```

##### User Handling

```bash
# Non-root user setup
if [ -n "$_REMOTE_USER" ] && [ "$_REMOTE_USER" != "root" ]; then
    USER_HOME=$(eval echo "~$_REMOTE_USER")

    # Create user directories
    sudo -u "$_REMOTE_USER" mkdir -p "$USER_HOME/.local/bin"

    # Set ownership
    chown -R "$_REMOTE_USER:$_REMOTE_USER" "$USER_HOME/.local"
fi
```

### 4. Documentation (`README.md`)

Provide comprehensive documentation for your feature.

#### Template

```markdown
# My Awesome Feature

Brief description of what this feature does and why it's useful.

## Usage

### Basic Usage

\`\`\`json
{
"features": {
"ghcr.io/your-username/devcontainer-features/my-feature:1": {}
}
}
\`\`\`

### With Options

\`\`\`json
{
"features": {
"ghcr.io/your-username/devcontainer-features/my-feature:1": {
"version": "2.0",
"enableFeatureX": true
}
}
}
\`\`\`

## Options

| Option           | Type    | Default    | Description        |
| ---------------- | ------- | ---------- | ------------------ |
| `version`        | string  | `"latest"` | Version to install |
| `enableFeatureX` | boolean | `false`    | Enable feature X   |

## Examples

### Example 1: Latest Version

\`\`\`json
{
"features": {
"ghcr.io/your-username/devcontainer-features/my-feature:1": {
"version": "latest"
}
}
}
\`\`\`

### Example 2: Specific Version with Features

\`\`\`json
{
"features": {
"ghcr.io/your-username/devcontainer-features/my-feature:1": {
"version": "2.0",
"enableFeatureX": true
}
}
}
\`\`\`

## Platform Support

- ✅ Ubuntu 20.04+
- ✅ Debian 11+
- ⚠️ Alpine Linux (limited support)
- ❌ CentOS/RHEL

## What's Installed

- `my-tool` command-line utility
- Configuration files in `/etc/my-tool/`
- Environment variables: `MY_FEATURE_INSTALLED=true`

## Troubleshooting

### Common Issues

**Issue**: Installation fails with permission error
**Solution**: Ensure the container is running as root during feature installation

**Issue**: Command not found after installation
**Solution**: Restart your terminal or run `source ~/.bashrc`

## Contributing

See the [main repository](https://github.com/your-username/devcontainer-features) for contribution guidelines.
```

### 5. Testing (`test/my-feature/test.sh`)

Create comprehensive tests for your feature.

#### Test Template

```bash
#!/bin/bash
set -e

# Import test utilities
source "$(dirname "$0")/../_global/test-utils.sh"

echo "Testing my-feature..."

# Test 1: Check if command is installed
echo "Test 1: Checking if my-tool command is available"
check_command "my-tool"

# Test 2: Check version output
echo "Test 2: Checking version output"
VERSION_OUTPUT=$(my-tool --version)
if echo "$VERSION_OUTPUT" | grep -q "my-tool"; then
    echo "✓ Version output is correct"
else
    echo "ERROR: Version output is incorrect: $VERSION_OUTPUT"
    exit 1
fi

# Test 3: Check basic functionality
echo "Test 3: Checking basic functionality"
if my-tool --help >/dev/null 2>&1; then
    echo "✓ Help command works"
else
    echo "ERROR: Help command failed"
    exit 1
fi

# Test 4: Check environment variables
echo "Test 4: Checking environment variables"
check_env_var "MY_FEATURE_INSTALLED" "true"

# Test 5: Check file permissions
echo "Test 5: Checking file permissions"
check_executable "/usr/local/bin/my-tool"

echo ""
echo "✅ All my-feature tests passed!"
```

#### Test Utilities

Use the shared test utilities in `test/_global/test-utils.sh`:

```bash
# Check if command exists
check_command "my-tool"

# Check if file exists
check_file "/etc/my-tool/config.conf"

# Check environment variable
check_env_var "MY_VAR" "expected_value"

# Check file permissions
check_executable "/usr/local/bin/my-tool"
check_readable "/etc/my-tool/config.conf"

# Run command and check output
run_command "my-tool --version" 0  # Expect exit code 0
```

## Validation and Testing

### 1. Validate Structure

```bash
./scripts/validate-feature.sh my-feature
```

### 2. Test Locally

```bash
# Test with default base image
./scripts/test-feature.sh my-feature

# Test with specific base image
./scripts/test-feature.sh my-feature mcr.microsoft.com/devcontainers/base:debian

# Test all features
./scripts/test-all.sh
```

### 3. Build Package

```bash
./scripts/build-feature.sh my-feature
```

## Advanced Topics

### Dependencies

If your feature depends on other features:

```json
{
  "dependsOn": {
    "ghcr.io/devcontainers/features/common-utils:2": {}
  },
  "installsAfter": ["common-utils"]
}
```

### Multiple Tools

Install multiple related tools:

```bash
# Install main tool
install_main_tool() {
    echo "Installing main tool..."
    # Installation logic
}

# Install additional tools
install_additional_tools() {
    if [ "$INSTALL_EXTRAS" = "true" ]; then
        echo "Installing additional tools..."
        # Additional installation logic
    fi
}

# Main installation
install_main_tool
install_additional_tools
```

### Configuration Files

Create configuration files:

```bash
# Create config directory
CONFIG_DIR="/etc/my-tool"
mkdir -p "$CONFIG_DIR"

# Create configuration file
cat > "$CONFIG_DIR/config.conf" << EOF
# My Tool Configuration
version=$VERSION
feature_x_enabled=$ENABLE_FEATURE_X
EOF

# Set proper permissions
chmod 644 "$CONFIG_DIR/config.conf"
```

### Version Management

Handle multiple versions:

```bash
case "$VERSION" in
    "latest"|"")
        DOWNLOAD_URL="https://releases.example.com/latest/my-tool"
        ;;
    "1.0"|"1.0.0")
        DOWNLOAD_URL="https://releases.example.com/v1.0.0/my-tool"
        ;;
    "2.0"|"2.0.0")
        DOWNLOAD_URL="https://releases.example.com/v2.0.0/my-tool"
        ;;
    *)
        echo "ERROR: Unsupported version: $VERSION"
        exit 1
        ;;
esac
```

## Common Patterns

### Download and Install Binary

```bash
# Download binary
DOWNLOAD_URL="https://example.com/releases/my-tool-${VERSION}-${ARCH}"
TEMP_FILE="/tmp/my-tool"

echo "Downloading from $DOWNLOAD_URL..."
curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_FILE"

# Verify checksum (optional but recommended)
EXPECTED_CHECKSUM="abc123..."
ACTUAL_CHECKSUM=$(sha256sum "$TEMP_FILE" | cut -d' ' -f1)
if [ "$ACTUAL_CHECKSUM" != "$EXPECTED_CHECKSUM" ]; then
    echo "ERROR: Checksum mismatch"
    exit 1
fi

# Install binary
chmod +x "$TEMP_FILE"
mv "$TEMP_FILE" "/usr/local/bin/my-tool"
```

### Package Manager Installation

```bash
case "$PACKAGE_MANAGER" in
    apt-get)
        # Add repository if needed
        curl -fsSL https://example.com/gpg | apt-key add -
        echo "deb https://example.com/apt stable main" > /etc/apt/sources.list.d/my-tool.list

        # Install package
        apt-get update
        apt-get install -y my-tool="$VERSION"
        ;;
    apk)
        apk add --no-cache my-tool="$VERSION"
        ;;
esac
```

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure script runs as root
2. **Platform Detection**: Test on multiple base images
3. **Idempotency**: Test multiple installations
4. **Environment Variables**: Check variable naming (uppercase)
5. **Path Issues**: Use absolute paths where possible

### Debugging

Add debug output:

```bash
set -x  # Enable debug mode
echo "DEBUG: Variable value is $MY_VAR"
```

Test in isolation:

```bash
# Test just the installation script
docker run --rm -it mcr.microsoft.com/devcontainers/base:ubuntu bash
# Copy and run your install.sh
```

## Publishing

Once your feature is ready:

1. **Validate**: `./scripts/validate-feature.sh my-feature`
2. **Test**: `./scripts/test-feature.sh my-feature`
3. **Commit**: Create a pull request
4. **Release**: Tag and push for automatic publishing

The CI/CD pipeline will automatically test and publish your feature when changes are detected.

## Resources

- [Dev Container Specification](https://containers.dev/implementors/features/)
- [Feature Distribution](https://containers.dev/implementors/features-distribution/)
- [Dev Container CLI](https://github.com/devcontainers/cli)
- [Example Features](https://github.com/devcontainers/features)
