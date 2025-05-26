# Dev Container Features Repository Concept

## Overview

This repository will serve as a collection of reusable dev container features that can be easily shared and consumed by development teams. The repository will be designed with development-first principles, allowing feature authors to build, test, and iterate on features locally before publishing them to a container registry.

## Architecture & Design Principles

### Self-Contained Development Environment

- The entire development workflow will run inside a dev container
- Local testing and validation of features before publishing
- Consistent development environment across all contributors
- Automated testing pipeline integrated into the development workflow

### Feature Collection Structure

Following the [dev container specification](https://containers.dev/implementors/features-distribution/), this repository will contain multiple features in a single collection, sharing the same namespace and distribution mechanism.

### Testing Strategy

- **Unit Testing**: Each feature will have individual test scenarios
- **Integration Testing**: Features will be tested against multiple base images
- **Idempotency Testing**: Features will be tested for safe re-installation
- **Cross-Platform Testing**: Features tested on different architectures (x86_64, arm64)

## Repository Structure

```
.
├── .devcontainer/
│   ├── devcontainer.json          # Development environment configuration
│   ├── Dockerfile                 # Custom dev environment setup
│   └── devcontainer.env          # Environment variables (gitignored)
├── .github/
│   └── workflows/
│       ├── test.yml              # Feature testing workflow
│       ├── release.yml           # Feature publishing workflow
│       └── ci.yml                # Continuous integration
├── src/                          # Feature source code
│   ├── hello-world/
│   │   ├── devcontainer-feature.json
│   │   ├── install.sh
│   │   └── README.md
│   ├── hello-universe/
│   │   ├── devcontainer-feature.json
│   │   ├── install.sh
│   │   └── README.md
│   └── [other-features]/
├── test/                         # Feature tests
│   ├── hello-world/
│   │   ├── test.sh
│   │   ├── scenarios.json
│   │   └── expected-output.txt
│   ├── hello-universe/
│   │   ├── test.sh
│   │   ├── scenarios.json
│   │   └── expected-output.txt
│   └── _global/
│       ├── test-utils.sh         # Shared testing utilities
│       └── base-images.json      # Base images for testing
├── scripts/
│   ├── test-feature.sh           # Local feature testing script
│   ├── test-all.sh              # Test all features locally
│   ├── build-feature.sh         # Build individual feature
│   └── validate-feature.sh      # Feature validation script
├── docs/
│   ├── authoring-guide.md        # Guide for creating new features
│   ├── testing-guide.md          # Testing best practices
│   └── contributing.md           # Contribution guidelines
├── README.md
├── LICENSE
└── devcontainer-collection.json  # Auto-generated collection metadata
```

## Development Workflow

### 1. Development Environment Setup

The repository includes a dev container configuration that provides:

- **devcontainers CLI**: For building and testing features locally
- **Docker-in-Docker**: For container operations within the dev environment
- **Testing Tools**: Bash testing framework, validation utilities
- **Development Tools**: Git, editors, debugging tools

### 2. Feature Development Process

1. **Create Feature Structure**:

   ```bash
   mkdir -p src/my-feature test/my-feature
   ```

2. **Implement Feature**:

   - `devcontainer-feature.json`: Feature metadata and options
   - `install.sh`: Installation script (idempotent)
   - `README.md`: Feature documentation

3. **Write Tests**:

   - `test.sh`: Feature validation script
   - `scenarios.json`: Test scenarios with different options
   - Expected outputs and validation criteria

4. **Local Testing**:

   ```bash
   # Test single feature
   ./scripts/test-feature.sh my-feature

   # Test against multiple base images
   devcontainer features test --base-image ubuntu:22.04 src/my-feature
   devcontainer features test --base-image debian:bullseye src/my-feature

   # Test all features
   ./scripts/test-all.sh
   ```

### 3. Feature Testing Strategy

#### Test Scenarios

Each feature will be tested with:

- **Default Options**: Basic installation with default settings
- **Custom Options**: Various option combinations
- **Multiple Base Images**: Ubuntu, Debian, Alpine, etc.
- **Idempotency**: Multiple installations with same/different options
- **Architecture Support**: x86_64 and arm64 when applicable

#### Test Implementation

```bash
# Example test structure
test/my-feature/
├── test.sh                    # Main test script
├── scenarios.json             # Test scenarios definition
├── expected-output.txt        # Expected installation output
└── validation/
    ├── default.sh            # Default scenario validation
    ├── custom-options.sh     # Custom options validation
    └── idempotency.sh        # Idempotency validation
```

#### Test Execution

```bash
# Using devcontainers CLI test command
devcontainer features test \
  --features src/my-feature \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu \
  --test-folder test/my-feature
```

## CI/CD Pipeline

### GitHub Actions Workflows

#### 1. Feature Testing (`test.yml`)

- **Trigger**: Pull requests, pushes to main
- **Matrix Strategy**: Test features against multiple base images
- **Changed Files Detection**: Only test features that have been modified
- **Parallel Execution**: Run tests for different features in parallel

```yaml
strategy:
  matrix:
    feature: [hello-world, hello-universe]
    base-image:
      - mcr.microsoft.com/devcontainers/base:ubuntu
      - mcr.microsoft.com/devcontainers/base:debian
      - mcr.microsoft.com/devcontainers/base:alpine
```

#### 2. Feature Publishing (`release.yml`)

- **Trigger**: Tags matching `v*` pattern
- **Changed Features Detection**: Only publish features with version bumps
- **OCI Registry Publishing**: Push to GitHub Container Registry (GHCR)
- **Collection Update**: Update and publish collection metadata

#### 3. Continuous Integration (`ci.yml`)

- **Trigger**: All pushes and pull requests
- **Validation**: Lint feature configurations, validate JSON schemas
- **Documentation**: Generate and update feature documentation
- **Security**: Scan for vulnerabilities in feature scripts

### Publishing Strategy

#### Version Management

- **Semantic Versioning**: Each feature follows semver independently
- **Automated Detection**: CI detects version changes in `devcontainer-feature.json`
- **Selective Publishing**: Only publish features with version increments

#### Registry Distribution

- **Primary Registry**: GitHub Container Registry (ghcr.io)
- **Namespace**: `ghcr.io/[username]/devcontainer-features`
- **Tagging Strategy**:
  - `latest`: Most recent version
  - `major.minor.patch`: Specific versions
  - `major.minor`: Latest patch for minor version
  - `major`: Latest minor for major version

#### Collection Management

- **Auto-generated Metadata**: `devcontainer-collection.json` updated automatically
- **Feature Discovery**: Published to containers.dev for community discovery
- **Documentation**: Auto-generated feature documentation

## Feature Development Guidelines

### Feature Design Principles

1. **Idempotency**: Features must be safe to run multiple times
2. **Platform Detection**: Check and support appropriate base images
3. **Non-root User Support**: Handle both root and non-root scenarios
4. **Error Handling**: Graceful failure with helpful error messages
5. **Documentation**: Clear README with usage examples

### Feature Structure Template

```json
{
  "id": "feature-name",
  "version": "1.0.0",
  "name": "Human Readable Feature Name",
  "description": "Brief description of what this feature provides",
  "documentationURL": "https://github.com/[username]/devcontainer-features/tree/main/src/feature-name",
  "options": {
    "version": {
      "type": "string",
      "proposals": ["latest", "1.0", "2.0"],
      "default": "latest",
      "description": "Version to install"
    }
  },
  "installsAfter": ["ghcr.io/devcontainers/features/common-utils"]
}
```

### Installation Script Best Practices

```bash
#!/bin/bash
set -e

# Feature options (from environment variables)
VERSION=${VERSION:-"latest"}

# Platform detection
. /etc/os-release
ARCHITECTURE="$(dpkg --print-architecture 2>/dev/null || echo "unknown")"

# Validate platform support
if [[ "${ID}" != "ubuntu" ]] && [[ "${ID}" != "debian" ]]; then
    echo "ERROR: This feature requires Ubuntu or Debian base images"
    exit 1
fi

# Non-root user detection
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Script must be run as root"
    exit 1
fi

# Idempotency check
if command -v my-tool >/dev/null 2>&1; then
    echo "Feature already installed, skipping..."
    exit 0
fi

# Installation logic
echo "Installing my-feature version ${VERSION}..."
# ... installation commands ...

echo "Feature installation completed successfully!"
```

## Testing Framework

### Local Testing Tools

#### Feature Test Runner

```bash
#!/bin/bash
# scripts/test-feature.sh

FEATURE_NAME=$1
BASE_IMAGE=${2:-"mcr.microsoft.com/devcontainers/base:ubuntu"}

if [ -z "$FEATURE_NAME" ]; then
    echo "Usage: $0 <feature-name> [base-image]"
    exit 1
fi

echo "Testing feature: $FEATURE_NAME"
echo "Base image: $BASE_IMAGE"

# Run devcontainer features test
devcontainer features test \
    --features "src/$FEATURE_NAME" \
    --base-image "$BASE_IMAGE" \
    --test-folder "test/$FEATURE_NAME"
```

#### Validation Utilities

```bash
# test/_global/test-utils.sh

# Check if command exists
check_command() {
    local cmd=$1
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Command '$cmd' not found"
        return 1
    fi
    echo "✓ Command '$cmd' is available"
    return 0
}

# Check file exists
check_file() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo "ERROR: File '$file' not found"
        return 1
    fi
    echo "✓ File '$file' exists"
    return 0
}

# Check environment variable
check_env_var() {
    local var=$1
    local expected=$2
    local actual="${!var}"

    if [ "$actual" != "$expected" ]; then
        echo "ERROR: Environment variable '$var' expected '$expected', got '$actual'"
        return 1
    fi
    echo "✓ Environment variable '$var' = '$actual'"
    return 0
}
```

### Test Scenarios Configuration

```json
{
  "scenarios": [
    {
      "name": "default",
      "description": "Test with default options",
      "options": {},
      "baseImages": [
        "mcr.microsoft.com/devcontainers/base:ubuntu",
        "mcr.microsoft.com/devcontainers/base:debian"
      ]
    },
    {
      "name": "custom-version",
      "description": "Test with specific version",
      "options": {
        "version": "2.0"
      },
      "baseImages": ["mcr.microsoft.com/devcontainers/base:ubuntu"]
    },
    {
      "name": "idempotency",
      "description": "Test multiple installations",
      "options": {},
      "runTwice": true,
      "baseImages": ["mcr.microsoft.com/devcontainers/base:ubuntu"]
    }
  ]
}
```

## Security Considerations

### Script Security

- **Input Validation**: Validate all user inputs and options
- **Privilege Escalation**: Minimize root operations, drop privileges when possible
- **Dependency Verification**: Verify checksums for downloaded packages
- **Secure Defaults**: Use secure default configurations

### Supply Chain Security

- **Dependency Scanning**: Automated vulnerability scanning in CI
- **Signed Releases**: Sign published features for integrity verification
- **Audit Trail**: Maintain logs of all feature publications
- **Access Control**: Restrict publishing permissions to authorized maintainers

## Documentation Strategy

### Feature Documentation

Each feature includes:

- **README.md**: Usage examples, options, compatibility
- **CHANGELOG.md**: Version history and breaking changes
- **Examples**: Sample devcontainer.json configurations

### Repository Documentation

- **Authoring Guide**: How to create new features
- **Testing Guide**: Testing best practices and tools
- **Contributing Guide**: Contribution workflow and standards
- **Architecture Guide**: Repository structure and design decisions

## Example Features

### 1. Hello World Feature

A simple feature that demonstrates basic concepts:

- Installs a custom "hello-world" command
- Supports version options
- Demonstrates proper error handling and validation

### 2. Hello Universe Feature

A more complex feature that shows advanced patterns:

- Multiple installation methods
- Platform-specific logic
- Integration with other features
- Custom environment configuration

## Future Enhancements

### Advanced Testing

- **Performance Testing**: Measure installation time and resource usage
- **Compatibility Matrix**: Automated testing against feature combinations
- **Regression Testing**: Automated detection of breaking changes

### Enhanced Development Experience

- **Feature Generator**: CLI tool to scaffold new features
- **Live Testing**: Hot-reload testing during development
- **Visual Testing**: UI for managing and testing features

### Community Features

- **Feature Marketplace**: Community-contributed features
- **Feature Analytics**: Usage metrics and adoption tracking
- **Feature Dependencies**: Advanced dependency management

This concept provides a solid foundation for building a professional-grade dev container features repository with proper testing, CI/CD, and development workflows.
