# Hello World Feature

A simple dev container feature that demonstrates basic concepts and best practices for feature development. This feature installs a customizable `hello-world` command that can be used to verify the feature installation and showcase option handling.

## Purpose

This feature serves as:

- A learning example for dev container feature development
- A template for creating new features
- A demonstration of feature best practices including idempotency, platform detection, and proper error handling

## Usage

### Basic Usage

```json
{
  "features": {
    "ghcr.io/your-username/devcontainer-features/hello-world:1": {}
  }
}
```

### With Custom Options

```json
{
  "features": {
    "ghcr.io/your-username/devcontainer-features/hello-world:1": {
      "greeting": "Hi",
      "name": "Developer",
      "includeDate": true
    }
  }
}
```

## Options

| Option        | Type    | Default   | Description                                                                                         |
| ------------- | ------- | --------- | --------------------------------------------------------------------------------------------------- |
| `greeting`    | string  | `"Hello"` | The greeting to use in the hello-world command. Supported values: "Hello", "Hi", "Hey", "Greetings" |
| `name`        | string  | `"World"` | The name to greet in the hello-world command                                                        |
| `includeDate` | boolean | `false`   | Whether to include the current date in the greeting                                                 |

## Installed Command

After installation, the `hello-world` command will be available with the following options:

```bash
# Basic usage with configured defaults
hello-world

# Show help
hello-world --help

# Show version
hello-world --version

# Override greeting and name
hello-world --greeting "Hi" --name "Developer"

# Include current date
hello-world --date
```

## Examples

### Example 1: Default Configuration

```json
{
  "features": {
    "ghcr.io/your-username/devcontainer-features/hello-world:1": {}
  }
}
```

Output: `Hello, World!`

### Example 2: Custom Greeting

```json
{
  "features": {
    "ghcr.io/your-username/devcontainer-features/hello-world:1": {
      "greeting": "Greetings",
      "name": "Developer"
    }
  }
}
```

Output: `Greetings, Developer!`

### Example 3: With Date

```json
{
  "features": {
    "ghcr.io/your-username/devcontainer-features/hello-world:1": {
      "includeDate": true
    }
  }
}
```

Output: `Hello, World! (at 2024-01-15 10:30:45)`

## Platform Support

- **Primary**: Ubuntu, Debian
- **Secondary**: Other Linux distributions (with warnings)
- **Architecture**: x86_64, arm64

## Feature Behavior

### Idempotency

The feature can be safely run multiple times. If the same version is already installed, the installation will be skipped.

### Platform Detection

The feature detects the operating system and architecture, providing appropriate warnings for unsupported platforms.

### Non-root User Support

The feature properly handles both root and non-root user scenarios, setting up the environment appropriately for the configured remote user.

### Environment Variables

The feature sets the following environment variable:

- `HELLO_WORLD_INSTALLED=true`

## Development Notes

This feature demonstrates several best practices:

1. **Proper option handling** - Environment variables are correctly mapped from feature options
2. **Idempotency** - Safe to run multiple times without side effects
3. **Platform detection** - Checks OS and architecture compatibility
4. **Error handling** - Graceful failure with helpful error messages
5. **User environment setup** - Properly configures both root and non-root user environments
6. **Comprehensive testing** - Includes validation of installation and functionality

## Testing

The feature includes comprehensive tests that verify:

- Default installation works correctly
- Custom options are properly applied
- Idempotency behavior is correct
- The installed command functions as expected
- Platform compatibility warnings are shown appropriately

## Contributing

When modifying this feature:

1. Update the version in `devcontainer-feature.json`
2. Test with multiple base images
3. Verify idempotency behavior
4. Update documentation as needed
5. Add appropriate test cases

## License

This feature is part of the devcontainer-features collection and is licensed under the same terms as the repository.
