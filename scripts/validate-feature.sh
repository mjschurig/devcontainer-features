#!/bin/bash
set -e

# validate-feature.sh - Validate dev container feature structure and configuration

FEATURE_NAME=$1
WORKSPACE_DIR=${2:-"$(pwd)"}

show_help() {
    echo "validate-feature.sh - Validate dev container feature structure and configuration"
    echo ""
    echo "Usage: $0 <feature-name> [workspace-dir]"
    echo ""
    echo "Arguments:"
    echo "  feature-name    Name of the feature to validate (required)"
    echo "  workspace-dir   Workspace directory (optional, defaults to current directory)"
    echo ""
    echo "This script validates:"
    echo "  - Feature directory structure"
    echo "  - devcontainer-feature.json syntax and schema"
    echo "  - install.sh script syntax"
    echo "  - README.md presence and basic structure"
    echo "  - Test files if present"
    echo ""
    echo "Examples:"
    echo "  $0 hello-world"
    echo "  $0 hello-universe /path/to/workspace"
}

if [ -z "$FEATURE_NAME" ] || [ "$FEATURE_NAME" = "--help" ] || [ "$FEATURE_NAME" = "-h" ]; then
    show_help
    exit 0
fi

FEATURE_DIR="$WORKSPACE_DIR/src/$FEATURE_NAME"
TEST_DIR="$WORKSPACE_DIR/test/$FEATURE_NAME"

echo "Validating feature: $FEATURE_NAME"
echo "Feature directory: $FEATURE_DIR"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# 1. Check if feature directory exists
echo "1. Checking feature directory structure..."
if [ ! -d "$FEATURE_DIR" ]; then
    log_error "Feature directory does not exist: $FEATURE_DIR"
    exit 1
fi
log_success "Feature directory exists"

# 2. Check required files
echo ""
echo "2. Checking required files..."

# devcontainer-feature.json
if [ ! -f "$FEATURE_DIR/devcontainer-feature.json" ]; then
    log_error "Missing required file: devcontainer-feature.json"
else
    log_success "devcontainer-feature.json exists"
fi

# install.sh
if [ ! -f "$FEATURE_DIR/install.sh" ]; then
    log_error "Missing required file: install.sh"
else
    log_success "install.sh exists"
    
    # Check if install.sh is executable
    if [ -x "$FEATURE_DIR/install.sh" ]; then
        log_success "install.sh is executable"
    else
        log_warning "install.sh is not executable (will be made executable during installation)"
    fi
fi

# README.md
if [ ! -f "$FEATURE_DIR/README.md" ]; then
    log_warning "Missing recommended file: README.md"
else
    log_success "README.md exists"
fi

# 3. Validate devcontainer-feature.json
echo ""
echo "3. Validating devcontainer-feature.json..."

if [ -f "$FEATURE_DIR/devcontainer-feature.json" ]; then
    # Check JSON syntax
    if jq empty "$FEATURE_DIR/devcontainer-feature.json" >/dev/null 2>&1; then
        log_success "JSON syntax is valid"
        
        # Check required fields
        FEATURE_JSON="$FEATURE_DIR/devcontainer-feature.json"
        
        # id field
        ID=$(jq -r '.id // empty' "$FEATURE_JSON")
        if [ -z "$ID" ]; then
            log_error "Missing required field: id"
        elif [ "$ID" != "$FEATURE_NAME" ]; then
            log_error "Feature id '$ID' does not match directory name '$FEATURE_NAME'"
        else
            log_success "Feature id matches directory name"
        fi
        
        # version field
        VERSION=$(jq -r '.version // empty' "$FEATURE_JSON")
        if [ -z "$VERSION" ]; then
            log_error "Missing required field: version"
        elif echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'; then
            log_success "Version follows semantic versioning: $VERSION"
        else
            log_warning "Version '$VERSION' does not follow semantic versioning (x.y.z)"
        fi
        
        # name field
        NAME=$(jq -r '.name // empty' "$FEATURE_JSON")
        if [ -z "$NAME" ]; then
            log_error "Missing required field: name"
        else
            log_success "Feature name is set: $NAME"
        fi
        
        # description field
        DESCRIPTION=$(jq -r '.description // empty' "$FEATURE_JSON")
        if [ -z "$DESCRIPTION" ]; then
            log_warning "Missing recommended field: description"
        else
            log_success "Feature description is set"
        fi
        
        # Check options structure
        if jq -e '.options' "$FEATURE_JSON" >/dev/null 2>&1; then
            log_success "Options are defined"
            
            # Validate each option
            jq -r '.options | keys[]' "$FEATURE_JSON" 2>/dev/null | while read -r option; do
                OPTION_TYPE=$(jq -r ".options.\"$option\".type // empty" "$FEATURE_JSON")
                if [ -z "$OPTION_TYPE" ]; then
                    log_warning "Option '$option' missing type field"
                elif [ "$OPTION_TYPE" != "string" ] && [ "$OPTION_TYPE" != "boolean" ]; then
                    log_warning "Option '$option' has unsupported type: $OPTION_TYPE"
                fi
                
                OPTION_DESC=$(jq -r ".options.\"$option\".description // empty" "$FEATURE_JSON")
                if [ -z "$OPTION_DESC" ]; then
                    log_warning "Option '$option' missing description"
                fi
            done
        else
            log_warning "No options defined (this is optional but recommended)"
        fi
        
    else
        log_error "Invalid JSON syntax in devcontainer-feature.json"
    fi
fi

# 4. Validate install.sh
echo ""
echo "4. Validating install.sh..."

if [ -f "$FEATURE_DIR/install.sh" ]; then
    # Check bash syntax
    if bash -n "$FEATURE_DIR/install.sh" 2>/dev/null; then
        log_success "Bash syntax is valid"
    else
        log_error "Bash syntax errors found in install.sh"
    fi
    
    # Check for common best practices
    if grep -q "set -e" "$FEATURE_DIR/install.sh"; then
        log_success "Script uses 'set -e' for error handling"
    else
        log_warning "Script should use 'set -e' for proper error handling"
    fi
    
    if grep -q "#!/bin/bash" "$FEATURE_DIR/install.sh"; then
        log_success "Script has proper shebang"
    else
        log_warning "Script should start with '#!/bin/bash'"
    fi
    
    # Check for root user validation
    if grep -q "id -u" "$FEATURE_DIR/install.sh"; then
        log_success "Script checks for root user"
    else
        log_warning "Script should validate it's running as root"
    fi
    
    # Check for idempotency patterns
    if grep -q "command -v\|which" "$FEATURE_DIR/install.sh"; then
        log_success "Script appears to check for existing installations"
    else
        log_warning "Script should implement idempotency checks"
    fi
fi

# 5. Validate README.md
echo ""
echo "5. Validating README.md..."

if [ -f "$FEATURE_DIR/README.md" ]; then
    # Check for basic sections
    if grep -q "# " "$FEATURE_DIR/README.md"; then
        log_success "README has main heading"
    else
        log_warning "README should have a main heading"
    fi
    
    if grep -qi "usage\|example" "$FEATURE_DIR/README.md"; then
        log_success "README contains usage information"
    else
        log_warning "README should contain usage examples"
    fi
    
    if grep -qi "option" "$FEATURE_DIR/README.md"; then
        log_success "README documents options"
    else
        log_warning "README should document available options"
    fi
fi

# 6. Check test files
echo ""
echo "6. Checking test files..."

if [ -d "$TEST_DIR" ]; then
    log_success "Test directory exists: $TEST_DIR"
    
    if [ -f "$TEST_DIR/test.sh" ]; then
        log_success "Test script exists"
        
        # Check test script syntax
        if bash -n "$TEST_DIR/test.sh" 2>/dev/null; then
            log_success "Test script syntax is valid"
        else
            log_error "Test script has syntax errors"
        fi
    else
        log_warning "No test.sh script found in test directory"
    fi
    
    if [ -f "$TEST_DIR/scenarios.json" ]; then
        log_success "Test scenarios file exists"
        
        # Check JSON syntax
        if jq empty "$TEST_DIR/scenarios.json" >/dev/null 2>&1; then
            log_success "Test scenarios JSON syntax is valid"
        else
            log_error "Test scenarios JSON has syntax errors"
        fi
    else
        log_warning "No scenarios.json file found (optional)"
    fi
else
    log_warning "No test directory found: $TEST_DIR"
fi

# 7. Check for common issues
echo ""
echo "7. Checking for common issues..."

# Check for hardcoded paths
if [ -f "$FEATURE_DIR/install.sh" ]; then
    if grep -q "/home/\|/Users/" "$FEATURE_DIR/install.sh"; then
        log_warning "Script may contain hardcoded user paths"
    fi
    
    # Check for proper environment variable usage
    if [ -f "$FEATURE_DIR/devcontainer-feature.json" ] && jq -e '.options' "$FEATURE_DIR/devcontainer-feature.json" >/dev/null 2>&1; then
        jq -r '.options | keys[]' "$FEATURE_DIR/devcontainer-feature.json" 2>/dev/null | while read -r option; do
            OPTION_UPPER=$(echo "$option" | tr '[:lower:]' '[:upper:]')
            if ! grep -q "\$${OPTION_UPPER}\|{\$${OPTION_UPPER}" "$FEATURE_DIR/install.sh"; then
                log_warning "Option '$option' may not be used in install.sh (expected variable: \$${OPTION_UPPER})"
            fi
        done
    fi
fi

# Summary
echo ""
echo "=== Validation Summary ==="
echo "Feature: $FEATURE_NAME"
echo "Errors: $VALIDATION_ERRORS"
echo "Warnings: $VALIDATION_WARNINGS"

if [ $VALIDATION_ERRORS -eq 0 ]; then
    if [ $VALIDATION_WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✅ Feature validation passed with no issues!${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Feature validation passed with $VALIDATION_WARNINGS warning(s)${NC}"
        exit 0
    fi
else
    echo -e "${RED}❌ Feature validation failed with $VALIDATION_ERRORS error(s)${NC}"
    exit 1
fi 