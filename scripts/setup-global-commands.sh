#!/bin/bash
set -e

# setup-global-commands.sh - Create global command wrappers

WORKSPACE_DIR=${1:-"$(pwd)"}
SCRIPTS_DIR="$WORKSPACE_DIR/scripts"

echo "Setting up global commands..."
echo "Workspace: $WORKSPACE_DIR"
echo "Scripts directory: $SCRIPTS_DIR"

# Ensure /usr/local/bin exists
echo "Ensuring /usr/local/bin directory exists..."
sudo mkdir -p /usr/local/bin

# Create wrapper scripts
create_wrapper() {
    local script_name=$1
    local command_name=$2
    local wrapper_path="/usr/local/bin/$command_name"
    local temp_file="/tmp/$command_name"

    echo "Creating wrapper: $command_name -> $script_name"

    # Create the wrapper script content in temp location
    cat > "$temp_file" << EOF
#!/bin/bash
# Auto-generated wrapper for $script_name
exec "$SCRIPTS_DIR/$script_name" "\$@"
EOF

    # Move it to the final location with sudo
    sudo mv "$temp_file" "$wrapper_path"
    sudo chmod +x "$wrapper_path"
    echo "  ✓ Created: $wrapper_path"
}

# Create wrappers for all scripts
create_wrapper "test-feature.sh" "test-feature"
create_wrapper "build-feature.sh" "build-feature"
create_wrapper "validate-feature.sh" "validate-feature"
create_wrapper "test-all.sh" "test-all"

echo ""
echo "✅ Global commands setup complete!"
echo ""
echo "Available commands:"
echo "  test-feature <feature-name> [base-image] [workspace-dir]"
echo "  build-feature <feature-name> [workspace-dir] [output-dir]"
echo "  validate-feature <feature-name> [workspace-dir]"
echo "  test-all [workspace-dir]"
echo ""
echo "Example usage:"
echo "  test-feature hello-world"
echo "  build-feature my-feature"
echo ""
echo "Verifying commands are available:"
which test-feature build-feature validate-feature test-all 2>/dev/null || echo "Commands will be available in new shell sessions"
