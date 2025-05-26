#!/bin/bash
set -e

# Import test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_UTILS_PATH="$SCRIPT_DIR/../_global/test-utils.sh"

# Try multiple possible paths for test utilities
if [ -f "$TEST_UTILS_PATH" ]; then
    source "$TEST_UTILS_PATH"
elif [ -f "/workspaces/*/test/_global/test-utils.sh" ]; then
    source /workspaces/*/test/_global/test-utils.sh
elif [ -f "test/_global/test-utils.sh" ]; then
    source "test/_global/test-utils.sh"
else
    echo "WARNING: test-utils.sh not found, defining basic functions..."
    # Define basic functions if test-utils.sh is not available
    check_command() {
        local cmd=$1
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "✓ Command '$cmd' is available"
            return 0
        else
            echo "ERROR: Command '$cmd' not found"
            return 1
        fi
    }
    
    check_env_var() {
        local var=$1
        local expected=$2
        local actual="${!var}"
        
        if [ "$actual" = "$expected" ]; then
            echo "✓ Environment variable '$var' = '$actual' (correct)"
            return 0
        else
            echo "ERROR: Environment variable '$var' expected '$expected', got '$actual'"
            return 1
        fi
    }
    
    check_file() {
        local file=$1
        if [ -f "$file" ]; then
            echo "✓ File '$file' exists"
            return 0
        else
            echo "ERROR: File '$file' not found"
            return 1
        fi
    }
fi

echo "Testing hello-universe feature..."

# Test 1: Check if hello-universe command is installed
echo "Test 1: Checking if hello-universe command is available"
check_command "hello-universe"

# Test 2: Check version output
echo "Test 2: Checking version output"
VERSION_OUTPUT=$(hello-universe --version)
if echo "$VERSION_OUTPUT" | grep -q "hello-universe 1.0.0"; then
    echo "✓ Version output is correct"
else
    echo "ERROR: Version output is incorrect: $VERSION_OUTPUT"
    exit 1
fi

# Test 3: Check basic functionality
echo "Test 3: Checking basic functionality"
BASIC_OUTPUT=$(hello-universe)
if echo "$BASIC_OUTPUT" | grep -q "Hello, Universe!"; then
    echo "✓ Basic greeting works"
else
    echo "ERROR: Basic greeting failed: $BASIC_OUTPUT"
    exit 1
fi

# Test 4: Check help output
echo "Test 4: Checking help output"
HELP_OUTPUT=$(hello-universe --help)
if echo "$HELP_OUTPUT" | grep -q "Usage: hello-universe"; then
    echo "✓ Help output is correct"
else
    echo "ERROR: Help output is incorrect"
    exit 1
fi

# Test 5: Check scope options
echo "Test 5: Checking scope options"
GALAXY_OUTPUT=$(hello-universe --scope galaxy)
if echo "$GALAXY_OUTPUT" | grep -q "Hello, Galaxy!"; then
    echo "✓ Galaxy scope works"
else
    echo "ERROR: Galaxy scope failed: $GALAXY_OUTPUT"
    exit 1
fi

# Test 6: Check language options
echo "Test 6: Checking language options"
SPANISH_OUTPUT=$(hello-universe --language spanish)
if echo "$SPANISH_OUTPUT" | grep -q "¡Hola, Universo!"; then
    echo "✓ Spanish language works"
else
    echo "ERROR: Spanish language failed: $SPANISH_OUTPUT"
    exit 1
fi

# Test 7: Check ASCII art option
echo "Test 7: Checking ASCII art option"
ASCII_OUTPUT=$(hello-universe --ascii)
if echo "$ASCII_OUTPUT" | grep -q "🌌"; then
    echo "✓ ASCII art works"
else
    echo "ERROR: ASCII art failed: $ASCII_OUTPUT"
    exit 1
fi

# Test 8: Check configuration file
echo "Test 8: Checking configuration file"
CONFIG_FILE="/usr/local/etc/hello-universe.conf"
check_file "$CONFIG_FILE"

if grep -q "scope=universe" "$CONFIG_FILE"; then
    echo "✓ Configuration file contains correct scope"
else
    echo "ERROR: Configuration file missing scope setting"
    exit 1
fi

# Test 9: Check configuration display
echo "Test 9: Checking configuration display"
CONFIG_OUTPUT=$(hello-universe --config)
if echo "$CONFIG_OUTPUT" | grep -q "scope=universe"; then
    echo "✓ Configuration display works"
else
    echo "ERROR: Configuration display failed"
    exit 1
fi

# Test 10: Check tools listing
echo "Test 10: Checking tools listing"
TOOLS_OUTPUT=$(hello-universe --tools)
if echo "$TOOLS_OUTPUT" | grep -q "Available Cosmic Tools"; then
    echo "✓ Tools listing works"
else
    echo "ERROR: Tools listing failed"
    exit 1
fi

# Test 11: Check cosmic-calc tool (if installed)
echo "Test 11: Checking cosmic-calc tool"
if command -v cosmic-calc >/dev/null 2>&1; then
    echo "✓ cosmic-calc command is available"
    
    # Test basic calculation
    CALC_OUTPUT=$(cosmic-calc "2 + 2")
    if echo "$CALC_OUTPUT" | grep -q "4"; then
        echo "✓ cosmic-calc basic calculation works"
    else
        echo "ERROR: cosmic-calc calculation failed: $CALC_OUTPUT"
        exit 1
    fi
    
    # Test constants
    CONSTANTS_OUTPUT=$(cosmic-calc --constants)
    if echo "$CONSTANTS_OUTPUT" | grep -q "speed_of_light"; then
        echo "✓ cosmic-calc constants work"
    else
        echo "ERROR: cosmic-calc constants failed"
        exit 1
    fi
else
    echo "WARNING: cosmic-calc not installed (may be disabled in options)"
fi

# Test 12: Check star-map tool (if installed)
echo "Test 12: Checking star-map tool"
if command -v star-map >/dev/null 2>&1; then
    echo "✓ star-map command is available"
    
    # Test constellations
    CONSTELLATIONS_OUTPUT=$(star-map --constellations)
    if echo "$CONSTELLATIONS_OUTPUT" | grep -q "Ursa Major"; then
        echo "✓ star-map constellations work"
    else
        echo "ERROR: star-map constellations failed"
        exit 1
    fi
    
    # Test planets
    PLANETS_OUTPUT=$(star-map --planets)
    if echo "$PLANETS_OUTPUT" | grep -q "Earth"; then
        echo "✓ star-map planets work"
    else
        echo "ERROR: star-map planets failed"
        exit 1
    fi
else
    echo "WARNING: star-map not installed (may be disabled in options)"
fi

# Test 13: Check environment variables
echo "Test 13: Checking environment variables"
check_env_var "HELLO_UNIVERSE_INSTALLED" "true"

if [ -n "$COSMIC_TOOLS_PATH" ]; then
    echo "✓ COSMIC_TOOLS_PATH environment variable is set"
else
    echo "WARNING: COSMIC_TOOLS_PATH environment variable not set"
fi

# Test 14: Check file permissions
echo "Test 14: Checking file permissions"
if [ -x "/usr/local/bin/hello-universe" ]; then
    echo "✓ hello-universe script is executable"
else
    echo "ERROR: hello-universe script is not executable"
    exit 1
fi

if [ -r "$CONFIG_FILE" ]; then
    echo "✓ Configuration file is readable"
else
    echo "ERROR: Configuration file is not readable"
    exit 1
fi

# Test 15: Check dependency integration
echo "Test 15: Checking dependency integration"
if command -v hello-world >/dev/null 2>&1; then
    echo "✓ hello-world dependency is available"
    
    # Verify it appears in tools list
    if hello-universe --tools | grep -q "hello-world"; then
        echo "✓ hello-world appears in tools list"
    else
        echo "WARNING: hello-world not listed in tools (may be expected)"
    fi
else
    echo "WARNING: hello-world dependency not found"
fi

# Test 16: Test complex option combinations
echo "Test 16: Testing complex option combinations"
COMPLEX_OUTPUT=$(hello-universe --scope multiverse --language french --ascii)
if echo "$COMPLEX_OUTPUT" | grep -q "Bonjour, Multivers!" && echo "$COMPLEX_OUTPUT" | grep -q "🌌"; then
    echo "✓ Complex option combination works"
else
    echo "ERROR: Complex option combination failed: $COMPLEX_OUTPUT"
    exit 1
fi

echo ""
echo "✅ All hello-universe tests passed!" 