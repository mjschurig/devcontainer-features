#!/bin/bash
set -e

# build-feature.sh - Build and package dev container features for distribution

FEATURE_NAME=$1
WORKSPACE_DIR=${2:-"$(pwd)"}
OUTPUT_DIR=${3:-"$WORKSPACE_DIR/dist"}

show_help() {
    echo "build-feature.sh - Build and package dev container features for distribution"
    echo ""
    echo "Usage: $0 <feature-name> [workspace-dir] [output-dir]"
    echo ""
    echo "Arguments:"
    echo "  feature-name    Name of the feature to build (required)"
    echo "  workspace-dir   Workspace directory (optional, defaults to current directory)"
    echo "  output-dir      Output directory for built artifacts (optional, defaults to ./dist)"
    echo ""
    echo "This script:"
    echo "  - Validates the feature structure"
    echo "  - Creates a tarball package"
    echo "  - Generates metadata"
    echo "  - Optionally pushes to OCI registry"
    echo ""
    echo "Environment Variables:"
    echo "  REGISTRY        OCI registry to push to (e.g., ghcr.io/username/features)"
    echo "  PUSH            Set to 'true' to push to registry after building"
    echo "  DRY_RUN         Set to 'true' to simulate without actual building"
    echo ""
    echo "Examples:"
    echo "  $0 hello-world"
    echo "  $0 hello-universe /path/to/workspace /path/to/output"
    echo "  REGISTRY=ghcr.io/myuser/features PUSH=true $0 hello-world"
}

if [ -z "$FEATURE_NAME" ] || [ "$FEATURE_NAME" = "--help" ] || [ "$FEATURE_NAME" = "-h" ]; then
    show_help
    exit 0
fi

FEATURE_DIR="$WORKSPACE_DIR/src/$FEATURE_NAME"
DRY_RUN=${DRY_RUN:-"false"}
PUSH=${PUSH:-"false"}

echo "Building feature: $FEATURE_NAME"
echo "Feature directory: $FEATURE_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "Dry run: $DRY_RUN"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 1. Validate feature exists and structure
log_info "Validating feature structure..."

if [ ! -d "$FEATURE_DIR" ]; then
    log_error "Feature directory does not exist: $FEATURE_DIR"
    exit 1
fi

if [ ! -f "$FEATURE_DIR/devcontainer-feature.json" ]; then
    log_error "Missing required file: devcontainer-feature.json"
    exit 1
fi

if [ ! -f "$FEATURE_DIR/install.sh" ]; then
    log_error "Missing required file: install.sh"
    exit 1
fi

log_success "Feature structure is valid"

# 2. Parse feature metadata
log_info "Parsing feature metadata..."

FEATURE_JSON="$FEATURE_DIR/devcontainer-feature.json"

if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is required for JSON parsing. Please install jq."
    exit 1
fi

if ! jq empty "$FEATURE_JSON" >/dev/null 2>&1; then
    log_error "Invalid JSON syntax in devcontainer-feature.json"
    exit 1
fi

FEATURE_ID=$(jq -r '.id // empty' "$FEATURE_JSON")
FEATURE_VERSION=$(jq -r '.version // empty' "$FEATURE_JSON")
FEATURE_NAME_DISPLAY=$(jq -r '.name // empty' "$FEATURE_JSON")

if [ -z "$FEATURE_ID" ]; then
    log_error "Feature id is not set in devcontainer-feature.json"
    exit 1
fi

if [ -z "$FEATURE_VERSION" ]; then
    log_error "Feature version is not set in devcontainer-feature.json"
    exit 1
fi

if [ "$FEATURE_ID" != "$FEATURE_NAME" ]; then
    log_error "Feature id '$FEATURE_ID' does not match directory name '$FEATURE_NAME'"
    exit 1
fi

log_success "Feature metadata parsed successfully"
log_info "  ID: $FEATURE_ID"
log_info "  Version: $FEATURE_VERSION"
log_info "  Name: $FEATURE_NAME_DISPLAY"

# 3. Create output directory
if [ "$DRY_RUN" != "true" ]; then
    log_info "Creating output directory..."
    mkdir -p "$OUTPUT_DIR"
    log_success "Output directory created: $OUTPUT_DIR"
else
    log_info "DRY RUN: Would create output directory: $OUTPUT_DIR"
fi

# 4. Create tarball
TARBALL_NAME="devcontainer-feature-${FEATURE_ID}.tgz"
TARBALL_PATH="$OUTPUT_DIR/$TARBALL_NAME"

log_info "Creating feature tarball..."

if [ "$DRY_RUN" != "true" ]; then
    # Create tarball with all files in the feature directory
    cd "$FEATURE_DIR"
    tar -czf "$TARBALL_PATH" .
    cd - >/dev/null
    
    # Verify tarball was created
    if [ -f "$TARBALL_PATH" ]; then
        TARBALL_SIZE=$(du -h "$TARBALL_PATH" | cut -f1)
        log_success "Tarball created: $TARBALL_PATH ($TARBALL_SIZE)"
    else
        log_error "Failed to create tarball"
        exit 1
    fi
else
    log_info "DRY RUN: Would create tarball: $TARBALL_PATH"
fi

# 5. Generate metadata
METADATA_FILE="$OUTPUT_DIR/${FEATURE_ID}-metadata.json"

log_info "Generating feature metadata..."

if [ "$DRY_RUN" != "true" ]; then
    # Create enhanced metadata
    jq --arg tarball "$TARBALL_NAME" \
       --arg build_date "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --arg build_host "$(hostname)" \
       '. + {
         "build": {
           "tarball": $tarball,
           "date": $build_date,
           "host": $build_host
         }
       }' "$FEATURE_JSON" > "$METADATA_FILE"
    
    log_success "Metadata generated: $METADATA_FILE"
else
    log_info "DRY RUN: Would generate metadata: $METADATA_FILE"
fi

# 6. Validate tarball contents
if [ "$DRY_RUN" != "true" ] && [ -f "$TARBALL_PATH" ]; then
    log_info "Validating tarball contents..."
    
    # List contents
    TARBALL_CONTENTS=$(tar -tzf "$TARBALL_PATH")
    
    # Check required files are present
    if echo "$TARBALL_CONTENTS" | grep -q "devcontainer-feature.json"; then
        log_success "✓ devcontainer-feature.json found in tarball"
    else
        log_error "✗ devcontainer-feature.json missing from tarball"
        exit 1
    fi
    
    if echo "$TARBALL_CONTENTS" | grep -q "install.sh"; then
        log_success "✓ install.sh found in tarball"
    else
        log_error "✗ install.sh missing from tarball"
        exit 1
    fi
    
    # Check for README
    if echo "$TARBALL_CONTENTS" | grep -q "README.md"; then
        log_success "✓ README.md found in tarball"
    else
        log_warning "README.md not found in tarball (recommended)"
    fi
    
    log_info "Tarball contents:"
    echo "$TARBALL_CONTENTS" | sed 's/^/  /'
fi

# 7. Push to registry (if requested)
if [ "$PUSH" = "true" ] && [ -n "$REGISTRY" ]; then
    log_info "Pushing to OCI registry..."
    
    if ! command -v devcontainer >/dev/null 2>&1; then
        log_error "devcontainer CLI is required for pushing to registry"
        exit 1
    fi
    
    if [ "$DRY_RUN" != "true" ]; then
        # Use devcontainer CLI to publish
        REGISTRY_URL="${REGISTRY}/${FEATURE_ID}:${FEATURE_VERSION}"
        
        log_info "Publishing to: $REGISTRY_URL"
        
        # Note: This would typically use the devcontainer features publish command
        # For now, we'll show what would be done
        log_info "Command would be: devcontainer features publish --namespace $REGISTRY $FEATURE_DIR"
        log_warning "Actual registry publishing requires proper authentication and devcontainer CLI setup"
    else
        log_info "DRY RUN: Would push to registry: ${REGISTRY}/${FEATURE_ID}:${FEATURE_VERSION}"
    fi
elif [ "$PUSH" = "true" ]; then
    log_warning "PUSH=true but REGISTRY not set. Skipping registry push."
fi

# 8. Generate build summary
log_info "Generating build summary..."

BUILD_SUMMARY="$OUTPUT_DIR/build-summary.json"

if [ "$DRY_RUN" != "true" ]; then
    cat > "$BUILD_SUMMARY" << EOF
{
  "feature": {
    "id": "$FEATURE_ID",
    "version": "$FEATURE_VERSION",
    "name": "$FEATURE_NAME_DISPLAY"
  },
  "build": {
    "date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "workspace": "$WORKSPACE_DIR",
    "output": "$OUTPUT_DIR",
    "tarball": "$TARBALL_NAME",
    "metadata": "${FEATURE_ID}-metadata.json"
  },
  "registry": {
    "push_requested": $PUSH,
    "registry": "${REGISTRY:-null}"
  }
}
EOF
    
    log_success "Build summary generated: $BUILD_SUMMARY"
else
    log_info "DRY RUN: Would generate build summary: $BUILD_SUMMARY"
fi

# 9. Final summary
echo ""
echo "=== Build Summary ==="
echo "Feature: $FEATURE_ID v$FEATURE_VERSION"
echo "Output directory: $OUTPUT_DIR"

if [ "$DRY_RUN" != "true" ]; then
    echo "Generated files:"
    echo "  - $TARBALL_NAME"
    echo "  - ${FEATURE_ID}-metadata.json"
    echo "  - build-summary.json"
    
    if [ -f "$TARBALL_PATH" ]; then
        echo "Tarball size: $(du -h "$TARBALL_PATH" | cut -f1)"
    fi
else
    echo "DRY RUN: No files were actually created"
fi

if [ "$PUSH" = "true" ] && [ -n "$REGISTRY" ]; then
    echo "Registry: ${REGISTRY}/${FEATURE_ID}:${FEATURE_VERSION}"
fi

echo ""
log_success "Feature build completed successfully!"

if [ "$DRY_RUN" = "true" ]; then
    echo ""
    log_info "This was a dry run. To actually build the feature, run without DRY_RUN=true"
fi 