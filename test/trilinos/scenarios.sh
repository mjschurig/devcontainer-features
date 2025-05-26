#!/bin/bash
set -e

# scenarios.sh - Execute test scenarios for trilinos feature

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIOS_FILE="$SCRIPT_DIR/scenarios.json"
TEST_SCRIPT="$SCRIPT_DIR/test.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "${BLUE}[SCENARIO]${NC} $1"
}

# Check if required files exist
if [ ! -f "$SCENARIOS_FILE" ]; then
    log_error "Scenarios file not found: $SCENARIOS_FILE"
    exit 1
fi

if [ ! -f "$TEST_SCRIPT" ]; then
    log_error "Test script not found: $TEST_SCRIPT"
    exit 1
fi

# Check if jq is available for parsing JSON
if ! command -v jq >/dev/null 2>&1; then
    log_warning "jq is not available, attempting to install it..."

    # Try to install jq if we're running as root
    if [ "$(id -u)" -eq 0 ]; then
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -qq && apt-get install -y jq >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            yum install -y jq >/dev/null 2>&1
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache jq >/dev/null 2>&1
        fi
    fi

    # Check again if jq is now available
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required for parsing scenarios.json but could not be installed"
        log_error "Please install jq manually or run the basic test.sh script instead"
        exit 1
    else
        log_info "jq successfully installed"
    fi
fi

echo "🧪 Executing trilinos feature scenarios..."
echo "Scenarios file: $SCENARIOS_FILE"
echo "Test script: $TEST_SCRIPT"
echo ""

# Parse scenarios from JSON
SCENARIOS=$(jq -r '.scenarios[] | @base64' "$SCENARIOS_FILE" 2>/dev/null)

if [ -z "$SCENARIOS" ]; then
    log_error "No scenarios found in $SCENARIOS_FILE"
    exit 1
fi

TOTAL_SCENARIOS=0
PASSED_SCENARIOS=0
FAILED_SCENARIOS=0

# Function to export scenario options as environment variables
export_scenario_options() {
    local scenario_data=$1

    # Clear previous scenario environment variables
    unset VERSION ENABLEMPI ENABLEKOKKOS ENABLETPETRA ENABLEBELOS ENABLEIFPACK2
    unset ENABLEMUELU ENABLEZOLTAN ENABLEZOLTAN2 BUILDTYPE INSTALLPREFIX
    unset ENABLESHAREDLIBS ENABLETESTS ENABLEEXAMPLES PARALLELJOBS
    unset ENABLEFLOAT ENABLECOMPLEX CXXSTANDARD ENABLEFORTRAN

    # Export new options
    local options=$(echo "$scenario_data" | jq -r '.options // {}')

    # Map JSON keys to environment variable names (camelCase to UPPER_CASE)
    if [ "$options" != "{}" ] && [ "$options" != "null" ]; then
        # Version
        local version=$(echo "$options" | jq -r '.version // empty')
        if [ -n "$version" ] && [ "$version" != "null" ]; then
            export VERSION="$version"
        fi

        # Boolean options
        local enableMPI=$(echo "$options" | jq -r '.enableMPI // empty')
        if [ -n "$enableMPI" ] && [ "$enableMPI" != "null" ]; then
            export ENABLEMPI="$enableMPI"
        fi

        local enableKokkos=$(echo "$options" | jq -r '.enableKokkos // empty')
        if [ -n "$enableKokkos" ] && [ "$enableKokkos" != "null" ]; then
            export ENABLEKOKKOS="$enableKokkos"
        fi

        local enableTpetra=$(echo "$options" | jq -r '.enableTpetra // empty')
        if [ -n "$enableTpetra" ] && [ "$enableTpetra" != "null" ]; then
            export ENABLETPETRA="$enableTpetra"
        fi

        local enableBelos=$(echo "$options" | jq -r '.enableBelos // empty')
        if [ -n "$enableBelos" ] && [ "$enableBelos" != "null" ]; then
            export ENABLEBELOS="$enableBelos"
        fi

        local enableIfpack2=$(echo "$options" | jq -r '.enableIfpack2 // empty')
        if [ -n "$enableIfpack2" ] && [ "$enableIfpack2" != "null" ]; then
            export ENABLEIFPACK2="$enableIfpack2"
        fi

        local enableMueLu=$(echo "$options" | jq -r '.enableMueLu // empty')
        if [ -n "$enableMueLu" ] && [ "$enableMueLu" != "null" ]; then
            export ENABLEMUELU="$enableMueLu"
        fi

        local enableZoltan=$(echo "$options" | jq -r '.enableZoltan // empty')
        if [ -n "$enableZoltan" ] && [ "$enableZoltan" != "null" ]; then
            export ENABLEZOLTAN="$enableZoltan"
        fi

        local enableZoltan2=$(echo "$options" | jq -r '.enableZoltan2 // empty')
        if [ -n "$enableZoltan2" ] && [ "$enableZoltan2" != "null" ]; then
            export ENABLEZOLTAN2="$enableZoltan2"
        fi

        local enableFortran=$(echo "$options" | jq -r '.enableFortran // empty')
        if [ -n "$enableFortran" ] && [ "$enableFortran" != "null" ]; then
            export ENABLEFORTRAN="$enableFortran"
        fi

        local enableSharedLibs=$(echo "$options" | jq -r '.enableSharedLibs // empty')
        if [ -n "$enableSharedLibs" ] && [ "$enableSharedLibs" != "null" ]; then
            export ENABLESHAREDLIBS="$enableSharedLibs"
        fi

        local enableTests=$(echo "$options" | jq -r '.enableTests // empty')
        if [ -n "$enableTests" ] && [ "$enableTests" != "null" ]; then
            export ENABLETESTS="$enableTests"
        fi

        local enableExamples=$(echo "$options" | jq -r '.enableExamples // empty')
        if [ -n "$enableExamples" ] && [ "$enableExamples" != "null" ]; then
            export ENABLEEXAMPLES="$enableExamples"
        fi

        local enableFloat=$(echo "$options" | jq -r '.enableFloat // empty')
        if [ -n "$enableFloat" ] && [ "$enableFloat" != "null" ]; then
            export ENABLEFLOAT="$enableFloat"
        fi

        local enableComplex=$(echo "$options" | jq -r '.enableComplex // empty')
        if [ -n "$enableComplex" ] && [ "$enableComplex" != "null" ]; then
            export ENABLECOMPLEX="$enableComplex"
        fi

        # String options
        local buildType=$(echo "$options" | jq -r '.buildType // empty')
        if [ -n "$buildType" ] && [ "$buildType" != "null" ]; then
            export BUILDTYPE="$buildType"
        fi

        local installPrefix=$(echo "$options" | jq -r '.installPrefix // empty')
        if [ -n "$installPrefix" ] && [ "$installPrefix" != "null" ]; then
            export INSTALLPREFIX="$installPrefix"
        fi

        local parallelJobs=$(echo "$options" | jq -r '.parallelJobs // empty')
        if [ -n "$parallelJobs" ] && [ "$parallelJobs" != "null" ]; then
            export PARALLELJOBS="$parallelJobs"
        fi

        local cxxStandard=$(echo "$options" | jq -r '.cxxStandard // empty')
        if [ -n "$cxxStandard" ] && [ "$cxxStandard" != "null" ]; then
            export CXXSTANDARD="$cxxStandard"
        fi
    fi
}

# Function to run a single scenario
run_scenario() {
    local scenario_data=$1
    local scenario_name=$(echo "$scenario_data" | jq -r '.name')
    local scenario_description=$(echo "$scenario_data" | jq -r '.description // ""')
    local run_twice=$(echo "$scenario_data" | jq -r '.runTwice // false')

    log_section "Running scenario: $scenario_name"
    if [ -n "$scenario_description" ]; then
        echo "Description: $scenario_description"
    fi

    # Export scenario options as environment variables
    export_scenario_options "$scenario_data"

    # Show configuration for this scenario
    echo "Scenario configuration:"
    echo "  VERSION=${VERSION:-latest}"
    echo "  ENABLEMPI=${ENABLEMPI:-true}"
    echo "  ENABLEKOKKOS=${ENABLEKOKKOS:-true}"
    echo "  ENABLETPETRA=${ENABLETPETRA:-true}"
    echo "  ENABLEBELOS=${ENABLEBELOS:-true}"
    echo "  ENABLEIFPACK2=${ENABLEIFPACK2:-true}"
    echo "  ENABLEMUELU=${ENABLEMUELU:-false}"
    echo "  ENABLEZOLTAN=${ENABLEZOLTAN:-false}"
    echo "  ENABLEZOLTAN2=${ENABLEZOLTAN2:-false}"
    echo "  BUILDTYPE=${BUILDTYPE:-Release}"
    echo "  INSTALLPREFIX=${INSTALLPREFIX:-/usr/local}"
    echo "  ENABLESHAREDLIBS=${ENABLESHAREDLIBS:-true}"
    echo "  ENABLETESTS=${ENABLETESTS:-false}"
    echo "  ENABLEEXAMPLES=${ENABLEEXAMPLES:-false}"
    echo "  PARALLELJOBS=${PARALLELJOBS:-auto}"
    echo "  ENABLEFLOAT=${ENABLEFLOAT:-false}"
    echo "  ENABLECOMPLEX=${ENABLECOMPLEX:-false}"
    echo "  CXXSTANDARD=${CXXSTANDARD:-20}"
    echo "  ENABLEFORTRAN=${ENABLEFORTRAN:-true}"
    echo ""

    # Run the test script
    local test_result=0
    if bash "$TEST_SCRIPT"; then
        log_info "Scenario '$scenario_name' PASSED"

        # If runTwice is true, run the test again to check idempotency
        if [ "$run_twice" = "true" ]; then
            log_info "Running scenario '$scenario_name' again to test idempotency..."
            if bash "$TEST_SCRIPT"; then
                log_info "Scenario '$scenario_name' idempotency test PASSED"
            else
                log_error "Scenario '$scenario_name' idempotency test FAILED"
                test_result=1
            fi
        fi
    else
        log_error "Scenario '$scenario_name' FAILED"
        test_result=1
    fi

    echo ""
    return $test_result
}

# Execute all scenarios
while IFS= read -r scenario_base64; do
    if [ -n "$scenario_base64" ]; then
        TOTAL_SCENARIOS=$((TOTAL_SCENARIOS + 1))

        # Decode base64 and parse scenario
        scenario_data=$(echo "$scenario_base64" | base64 -d)

        if run_scenario "$scenario_data"; then
            PASSED_SCENARIOS=$((PASSED_SCENARIOS + 1))
        else
            FAILED_SCENARIOS=$((FAILED_SCENARIOS + 1))
        fi
    fi
done <<< "$SCENARIOS"

# Print summary
echo "========================================"
echo "🧪 Scenario Execution Summary"
echo "========================================"
echo "Total scenarios: $TOTAL_SCENARIOS"
echo "Passed: $PASSED_SCENARIOS"
echo "Failed: $FAILED_SCENARIOS"
echo ""

if [ $FAILED_SCENARIOS -eq 0 ]; then
    log_info "All scenarios passed! ✅"
    exit 0
else
    log_error "$FAILED_SCENARIOS scenario(s) failed ❌"
    exit 1
fi

