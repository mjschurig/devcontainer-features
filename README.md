# Dev Container Features

A collection of reusable dev container features that can be easily shared and consumed by development teams. This repository provides a complete development workflow for creating, testing, and publishing dev container features.

## 🚀 Quick Start

### Using Features

Add features to your `devcontainer.json`:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/mjschurig/devcontainer-features/hello-world:1": {
      "greeting": "Hello",
      "name": "Developer"
    },
    "ghcr.io/mjschurig/devcontainer-features/hello-universe:1": {
      "scope": "galaxy",
      "language": "spanish"
    }
  }
}
```

### Development Setup

1. **Clone the repository**:

   ```bash
   git clone https://github.com/mjschurig/devcontainer-features.git
   cd devcontainer-features
   ```

2. **Open in dev container**:

   - Open the repository in VS Code
   - When prompted, click "Reopen in Container"
   - Or use Command Palette: `Dev Containers: Reopen in Container`
   - Global commands will be automatically set up during container creation

3. **Test features locally**:

   The dev container automatically sets up global commands for easy testing:

   ```bash
   # Using global commands (recommended - work from any directory)
   test-feature hello-world
   test-all
   validate-feature hello-world
   build-feature hello-world

   # Or using scripts directly
   ./scripts/test-feature.sh hello-world
   ./scripts/test-all.sh
   ./scripts/validate-feature.sh hello-world
   ./scripts/build-feature.sh hello-world
   ```

## 📦 Available Features

### Hello World

A simple feature demonstrating basic dev container feature concepts.

- **ID**: `hello-world`
- **Description**: Installs a customizable hello-world command
- **Options**: `greeting`, `name`, `includeDate`

[📖 Documentation](src/hello-world/README.md)

### Hello Universe

An advanced feature showcasing complex installation patterns and multiple tools.

- **ID**: `hello-universe`
- **Description**: Advanced cosmic greeting with multiple tools and languages
- **Options**: `scope`, `language`, `installTools`, `enableAsciiArt`

[📖 Documentation](src/hello-universe/README.md)

## 🛠️ Development

### Repository Structure

```
.
├── .devcontainer/          # Development environment
├── .github/workflows/      # CI/CD pipelines
├── src/                    # Feature source code
│   ├── hello-world/
│   └── hello-universe/
├── test/                   # Feature tests
│   ├── _global/           # Shared test utilities
│   ├── hello-world/
│   └── hello-universe/
├── scripts/               # Development scripts
├── docs/                  # Documentation
└── README.md
```

### Creating a New Feature

1. **Create feature directory**:

   ```bash
   mkdir -p src/my-feature test/my-feature
   ```

2. **Create feature files**:

   - `src/my-feature/devcontainer-feature.json` - Feature metadata
   - `src/my-feature/install.sh` - Installation script
   - `src/my-feature/README.md` - Documentation

3. **Create tests**:

   - `test/my-feature/test.sh` - Test script

4. **Validate and test**:
   ```bash
   # Using global commands (recommended)
   validate-feature my-feature
   test-feature my-feature

   # Or using scripts directly
   ./scripts/validate-feature.sh my-feature
   ./scripts/test-feature.sh my-feature
   ```

### Development Scripts

All scripts are available as global commands in the dev container:

| Global Command    | Script                        | Description                |
| ----------------- | ----------------------------- | -------------------------- |
| `test-feature`    | `scripts/test-feature.sh`     | Test individual feature    |
| `test-all`        | `scripts/test-all.sh`         | Test all features          |
| `validate-feature`| `scripts/validate-feature.sh` | Validate feature structure |
| `build-feature`   | `scripts/build-feature.sh`    | Build feature package      |

**Note**: Global commands are automatically set up when the dev container starts via the `scripts/setup-global-commands.sh` script. You can use either the global commands (e.g., `test-feature hello-world`) or run the scripts directly (e.g., `./scripts/test-feature.sh hello-world`).

**Global Command Examples**:
```bash
# Test a feature from anywhere in the container
test-feature hello-world

# Test with custom base image
test-feature hello-world mcr.microsoft.com/devcontainers/base:debian

# Validate feature structure
validate-feature my-new-feature

# Build feature package
build-feature hello-world

# Test all features
test-all
```

### Testing

The repository includes comprehensive testing:

- **Structure Validation**: JSON schema validation, file presence checks
- **Unit Testing**: Individual feature functionality
- **Integration Testing**: Features against multiple base images
- **Idempotency Testing**: Safe re-installation
- **Security Scanning**: ShellCheck, secret detection

Run tests locally:

```bash
# Using global commands (recommended)
# Test specific feature against specific base image
test-feature hello-world mcr.microsoft.com/devcontainers/base:debian

# Test all features in parallel
BASE_IMAGES="ubuntu:22.04,debian:bullseye" test-all . true

# Test only specific features
FEATURES="hello-world" test-all

# Or using scripts directly
# Test specific feature against specific base image
./scripts/test-feature.sh hello-world mcr.microsoft.com/devcontainers/base:debian

# Test all features in parallel
BASE_IMAGES="ubuntu:22.04,debian:bullseye" ./scripts/test-all.sh . true

# Test only specific features
FEATURES="hello-world" ./scripts/test-all.sh
```

## 🚀 CI/CD

### Automated Testing

Every pull request triggers:

- Feature structure validation
- Multi-platform testing
- Security scanning
- Build verification

### Publishing

Features are automatically published when:

- Tags are pushed (`v*`)
- Manual workflow dispatch

Published to: `ghcr.io/mjschurig/devcontainer-features`

### Workflows

- **`test.yml`**: Comprehensive testing on PRs and pushes
- **`release.yml`**: Publishing and release management

## 📚 Documentation

- [Feature Authoring Guide](docs/authoring-guide.md)
- [Testing Guide](docs/testing-guide.md)
- [Contributing Guidelines](docs/contributing.md)
- [Architecture Overview](concept.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

See [Contributing Guidelines](docs/contributing.md) for detailed information.

## 📋 Feature Requirements

All features must:

- ✅ Include `devcontainer-feature.json` with proper metadata
- ✅ Include `install.sh` with idempotent installation logic
- ✅ Include `README.md` with usage documentation
- ✅ Support both root and non-root users
- ✅ Handle platform detection and compatibility
- ✅ Include comprehensive tests
- ✅ Follow semantic versioning

## 🔧 Best Practices

### Feature Development

- **Idempotency**: Features should be safe to run multiple times
- **Platform Support**: Detect and handle different base images
- **Error Handling**: Provide clear error messages
- **Documentation**: Include usage examples and option descriptions
- **Testing**: Cover all major functionality and edge cases

### Security

- **Input Validation**: Validate all user inputs
- **Privilege Management**: Minimize root operations
- **Dependency Verification**: Verify package checksums
- **Secret Management**: Never hardcode secrets

## 📊 Status

![Test Status](https://github.com/mjschurig/devcontainer-features/workflows/Test%20Features/badge.svg)
![Release Status](https://github.com/mjschurig/devcontainer-features/workflows/Release%20Features/badge.svg)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Dev Container Specification](https://containers.dev/)
- [Dev Container Features](https://containers.dev/features)
- [Dev Container CLI](https://github.com/devcontainers/cli)

---

**Happy coding! 🎉**
