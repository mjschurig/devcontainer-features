# Contributing to Dev Container Features

Thank you for your interest in contributing to this dev container features repository! This guide will help you get started with contributing new features, improvements, and bug fixes.

## 🚀 Quick Start

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Open in dev container** for consistent development environment
4. **Create a feature branch** for your changes
5. **Make your changes** following our guidelines
6. **Test thoroughly** using our testing tools
7. **Submit a pull request**

## 📋 Types of Contributions

### New Features

- Add new dev container features to the `src/` directory
- Include comprehensive tests and documentation
- Follow our feature authoring guidelines

### Bug Fixes

- Fix issues in existing features
- Update tests to prevent regression
- Document the fix in commit messages

### Documentation

- Improve README files
- Update feature documentation
- Add examples and use cases

### Testing

- Add test cases for existing features
- Improve test coverage
- Enhance testing utilities

## 🛠️ Development Setup

### Prerequisites

- Git
- Docker
- VS Code with Dev Containers extension

### Setup Steps

1. **Fork and clone**:

   ```bash
   git clone https://github.com/mjschurig/devcontainer-features.git
   cd devcontainer-features
   ```

2. **Open in dev container**:

   - Open VS Code in the repository directory
   - When prompted, click "Reopen in Container"
   - Wait for the container to build and start

3. **Verify setup**:

   ```bash
   # Check if devcontainer CLI is available
   devcontainer --version

   # Test existing features
   ./scripts/test-all.sh
   ```

## 📝 Feature Development Guidelines

### Creating a New Feature

1. **Plan your feature**:

   - Define what problem it solves
   - Identify target platforms
   - Plan configuration options

2. **Create feature structure**:

   ```bash
   mkdir -p src/my-feature test/my-feature
   ```

3. **Implement the feature**:

   - `src/my-feature/devcontainer-feature.json` - Metadata
   - `src/my-feature/install.sh` - Installation script
   - `src/my-feature/README.md` - Documentation
   - `test/my-feature/test.sh` - Tests

4. **Follow best practices**:
   - Implement idempotency
   - Support multiple platforms
   - Handle errors gracefully
   - Use semantic versioning

### Feature Requirements

All features must:

- ✅ **Be idempotent** - Safe to run multiple times
- ✅ **Support root and non-root users**
- ✅ **Include comprehensive tests**
- ✅ **Have clear documentation**
- ✅ **Follow naming conventions**
- ✅ **Handle platform differences**
- ✅ **Use semantic versioning**

### Code Standards

#### Shell Scripts

- Use `#!/bin/bash` shebang
- Include `set -e` for error handling
- Use meaningful variable names
- Add comments for complex logic
- Quote variables to prevent word splitting

#### JSON Files

- Use 2-space indentation
- Validate JSON syntax
- Include all required fields
- Use descriptive option names

#### Documentation

- Use clear, concise language
- Include usage examples
- Document all options
- Provide troubleshooting tips

## 🧪 Testing

### Local Testing

Before submitting a pull request:

1. **Validate feature structure**:

   ```bash
   ./scripts/validate-feature.sh my-feature
   ```

2. **Test feature functionality**:

   ```bash
   ./scripts/test-feature.sh my-feature
   ```

3. **Test against multiple base images**:

   ```bash
   ./scripts/test-feature.sh my-feature mcr.microsoft.com/devcontainers/base:debian
   ./scripts/test-feature.sh my-feature ubuntu:22.04
   ```

4. **Test all features**:
   ```bash
   ./scripts/test-all.sh
   ```

### Test Requirements

Each feature must include:

- **Unit tests** - Test basic functionality
- **Integration tests** - Test with different base images
- **Idempotency tests** - Test multiple installations
- **Option tests** - Test all configuration options
- **Error handling tests** - Test failure scenarios

### Writing Tests

Use the shared test utilities:

```bash
#!/bin/bash
set -e

# Import test utilities
source "$(dirname "$0")/../_global/test-utils.sh"

echo "Testing my-feature..."

# Test command availability
check_command "my-tool"

# Test environment variables
check_env_var "MY_FEATURE_INSTALLED" "true"

# Test file permissions
check_executable "/usr/local/bin/my-tool"

echo "✅ All tests passed!"
```

## 📖 Documentation Standards

### Feature README Template

Each feature must include a comprehensive README:

```markdown
# Feature Name

Brief description of the feature.

## Usage

Basic usage example with devcontainer.json.

## Options

Table of all available options.

## Examples

Multiple usage examples.

## Platform Support

List of supported platforms.

## What's Installed

List of installed tools and files.

## Troubleshooting

Common issues and solutions.
```

### Commit Messages

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test changes
- `refactor`: Code refactoring
- `chore`: Maintenance tasks

Examples:

```
feat(hello-world): add date option support
fix(hello-universe): resolve platform detection issue
docs(readme): update installation instructions
test(hello-world): add idempotency tests
```

## 🔄 Pull Request Process

### Before Submitting

1. **Test thoroughly**:

   - Run all validation scripts
   - Test on multiple platforms
   - Verify documentation is accurate

2. **Update documentation**:

   - Update feature README
   - Update main README if needed
   - Add changelog entries

3. **Check code quality**:
   - Run linting tools
   - Follow coding standards
   - Remove debug code

### Pull Request Template

When creating a pull request, include:

```markdown
## Description

Brief description of changes.

## Type of Change

- [ ] New feature
- [ ] Bug fix
- [ ] Documentation update
- [ ] Test improvement

## Testing

- [ ] Validated feature structure
- [ ] Tested on multiple base images
- [ ] Added/updated tests
- [ ] Updated documentation

## Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Tests pass locally
- [ ] Documentation updated
```

### Review Process

1. **Automated checks** run on all PRs
2. **Manual review** by maintainers
3. **Testing** on multiple platforms
4. **Approval** required before merge

## 🏷️ Release Process

### Versioning

We use semantic versioning (semver):

- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features, backward compatible
- **Patch** (0.0.1): Bug fixes, backward compatible

### Release Steps

1. **Update version** in `devcontainer-feature.json`
2. **Update documentation** with changes
3. **Create pull request** with version bump
4. **Tag release** after merge
5. **Automated publishing** to registry

## 🤝 Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Provide constructive feedback
- Focus on what's best for the community

### Getting Help

- **Issues**: Report bugs and request features
- **Discussions**: Ask questions and share ideas
- **Documentation**: Check existing docs first
- **Examples**: Look at existing features

### Communication

- Use clear, descriptive titles
- Provide context and examples
- Be patient with responses
- Help others when possible

## 🔧 Advanced Topics

### Feature Dependencies

If your feature depends on others:

```json
{
  "dependsOn": {
    "ghcr.io/devcontainers/features/common-utils:2": {}
  },
  "installsAfter": ["common-utils"]
}
```

### Multi-Platform Support

Handle different architectures:

```bash
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

### Security Considerations

- Validate all inputs
- Use HTTPS for downloads
- Verify checksums when possible
- Minimize privilege escalation
- Don't hardcode secrets

## 📊 Metrics and Analytics

We track:

- Feature usage statistics
- Platform compatibility
- Test success rates
- Community engagement

This helps us:

- Prioritize improvements
- Identify popular features
- Fix common issues
- Plan future development

## 🙏 Recognition

Contributors are recognized through:

- GitHub contributor graphs
- Release notes mentions
- Community highlights
- Maintainer nominations

## 📚 Resources

### Documentation

- [Feature Authoring Guide](authoring-guide.md)
- [Testing Guide](testing-guide.md)
- [Architecture Overview](../concept.md)

### External Resources

- [Dev Container Specification](https://containers.dev/)
- [Dev Container Features](https://containers.dev/features)
- [Dev Container CLI](https://github.com/devcontainers/cli)

### Tools

- [VS Code Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Docker](https://www.docker.com/)
- [ShellCheck](https://www.shellcheck.net/)

## 📞 Contact

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Email**: [maintainer email]
- **Chat**: [community chat link]

---

Thank you for contributing to dev container features! Your contributions help make development environments better for everyone. 🎉
