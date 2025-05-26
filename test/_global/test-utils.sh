#!/bin/bash

# test-utils.sh - Shared testing utilities for dev container features

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
check_command() {
    local cmd=$1
    local description=${2:-"Command '$cmd'"}
    
    if command -v "$cmd" >/dev/null 2>&1; then
        log_info "$description is available"
        return 0
    else
        log_error "$description not found"
        return 1
    fi
}

# Check if file exists
check_file() {
    local file=$1
    local description=${2:-"File '$file'"}
    
    if [ -f "$file" ]; then
        log_info "$description exists"
        return 0
    else
        log_error "$description not found"
        return 1
    fi
}

# Check if directory exists
check_directory() {
    local dir=$1
    local description=${2:-"Directory '$dir'"}
    
    if [ -d "$dir" ]; then
        log_info "$description exists"
        return 0
    else
        log_error "$description not found"
        return 1
    fi
}

# Check environment variable
check_env_var() {
    local var=$1
    local expected=$2
    local description=${3:-"Environment variable '$var'"}
    
    local actual="${!var}"
    
    if [ -z "$actual" ]; then
        log_error "$description is not set"
        return 1
    fi
    
    if [ "$actual" = "$expected" ]; then
        log_info "$description = '$actual' (correct)"
        return 0
    else
        log_error "$description expected '$expected', got '$actual'"
        return 1
    fi
}

# Check if environment variable is set (any value)
check_env_var_set() {
    local var=$1
    local description=${2:-"Environment variable '$var'"}
    
    local actual="${!var}"
    
    if [ -n "$actual" ]; then
        log_info "$description is set to '$actual'"
        return 0
    else
        log_error "$description is not set"
        return 1
    fi
}

# Check file permissions
check_file_permissions() {
    local file=$1
    local expected_perms=$2
    local description=${3:-"File '$file'"}
    
    if [ ! -f "$file" ]; then
        log_error "$description does not exist"
        return 1
    fi
    
    local actual_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
    
    if [ "$actual_perms" = "$expected_perms" ]; then
        log_info "$description has correct permissions ($actual_perms)"
        return 0
    else
        log_error "$description has incorrect permissions: expected $expected_perms, got $actual_perms"
        return 1
    fi
}

# Check if file is executable
check_executable() {
    local file=$1
    local description=${2:-"File '$file'"}
    
    if [ -x "$file" ]; then
        log_info "$description is executable"
        return 0
    else
        log_error "$description is not executable"
        return 1
    fi
}

# Check if file is readable
check_readable() {
    local file=$1
    local description=${2:-"File '$file'"}
    
    if [ -r "$file" ]; then
        log_info "$description is readable"
        return 0
    else
        log_error "$description is not readable"
        return 1
    fi
}

# Check if string contains substring
check_string_contains() {
    local string=$1
    local substring=$2
    local description=${3:-"String"}
    
    if echo "$string" | grep -q "$substring"; then
        log_info "$description contains '$substring'"
        return 0
    else
        log_error "$description does not contain '$substring'"
        log_error "Actual string: $string"
        return 1
    fi
}

# Check if string matches pattern
check_string_matches() {
    local string=$1
    local pattern=$2
    local description=${3:-"String"}
    
    if echo "$string" | grep -qE "$pattern"; then
        log_info "$description matches pattern '$pattern'"
        return 0
    else
        log_error "$description does not match pattern '$pattern'"
        log_error "Actual string: $string"
        return 1
    fi
}

# Run command and check exit code
run_command() {
    local cmd=$1
    local expected_exit_code=${2:-0}
    local description=${3:-"Command '$cmd'"}
    
    local output
    local exit_code
    
    output=$(eval "$cmd" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq $expected_exit_code ]; then
        log_info "$description executed successfully (exit code: $exit_code)"
        echo "$output"
        return 0
    else
        log_error "$description failed with exit code $exit_code (expected $expected_exit_code)"
        log_error "Output: $output"
        return 1
    fi
}

# Run command and capture output
capture_command_output() {
    local cmd=$1
    local output_var=$2
    local description=${3:-"Command '$cmd'"}
    
    local output
    local exit_code
    
    output=$(eval "$cmd" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_info "$description executed successfully"
        eval "$output_var=\"\$output\""
        return 0
    else
        log_error "$description failed with exit code $exit_code"
        log_error "Output: $output"
        return 1
    fi
}

# Check if port is listening
check_port_listening() {
    local port=$1
    local description=${2:-"Port $port"}
    
    if command -v netstat >/dev/null 2>&1; then
        if netstat -ln | grep -q ":$port "; then
            log_info "$description is listening"
            return 0
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -ln | grep -q ":$port "; then
            log_info "$description is listening"
            return 0
        fi
    fi
    
    log_error "$description is not listening"
    return 1
}

# Check if service is running
check_service_running() {
    local service=$1
    local description=${2:-"Service '$service'"}
    
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet "$service"; then
            log_info "$description is running"
            return 0
        fi
    elif command -v service >/dev/null 2>&1; then
        if service "$service" status >/dev/null 2>&1; then
            log_info "$description is running"
            return 0
        fi
    fi
    
    log_error "$description is not running"
    return 1
}

# Wait for condition with timeout
wait_for_condition() {
    local condition_cmd=$1
    local timeout=${2:-30}
    local description=${3:-"Condition"}
    
    local elapsed=0
    local interval=1
    
    log_info "Waiting for $description (timeout: ${timeout}s)..."
    
    while [ $elapsed -lt $timeout ]; do
        if eval "$condition_cmd" >/dev/null 2>&1; then
            log_info "$description met after ${elapsed}s"
            return 0
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    log_error "$description not met within ${timeout}s"
    return 1
}

# Test summary functions
declare -g TEST_COUNT=0
declare -g TEST_PASSED=0
declare -g TEST_FAILED=0

start_test() {
    local test_name=$1
    TEST_COUNT=$((TEST_COUNT + 1))
    echo ""
    echo "=== Test $TEST_COUNT: $test_name ==="
}

pass_test() {
    TEST_PASSED=$((TEST_PASSED + 1))
    log_info "Test passed"
}

fail_test() {
    local reason=${1:-"Test failed"}
    TEST_FAILED=$((TEST_FAILED + 1))
    log_error "$reason"
}

print_test_summary() {
    echo ""
    echo "=== Test Summary ==="
    echo "Total tests: $TEST_COUNT"
    echo "Passed: $TEST_PASSED"
    echo "Failed: $TEST_FAILED"
    
    if [ $TEST_FAILED -eq 0 ]; then
        log_info "All tests passed! 🎉"
        return 0
    else
        log_error "$TEST_FAILED test(s) failed"
        return 1
    fi
}

# Platform detection utilities
get_os_id() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

get_os_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$VERSION_ID"
    else
        echo "unknown"
    fi
}

get_architecture() {
    uname -m
}

is_ubuntu() {
    [ "$(get_os_id)" = "ubuntu" ]
}

is_debian() {
    [ "$(get_os_id)" = "debian" ]
}

is_alpine() {
    [ "$(get_os_id)" = "alpine" ]
}

is_centos() {
    [ "$(get_os_id)" = "centos" ]
}

is_x86_64() {
    local arch=$(get_architecture)
    [ "$arch" = "x86_64" ] || [ "$arch" = "amd64" ]
}

is_arm64() {
    local arch=$(get_architecture)
    [ "$arch" = "aarch64" ] || [ "$arch" = "arm64" ]
}

# Cleanup utilities
cleanup_temp_files() {
    local temp_dir=${1:-"/tmp"}
    local pattern=${2:-"test_*"}
    
    find "$temp_dir" -name "$pattern" -type f -delete 2>/dev/null || true
    log_info "Cleaned up temporary files matching '$pattern' in '$temp_dir'"
}

cleanup_test_commands() {
    local commands=("$@")
    
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            local cmd_path=$(which "$cmd")
            if [[ "$cmd_path" == /tmp/* ]] || [[ "$cmd_path" == *test* ]]; then
                rm -f "$cmd_path" 2>/dev/null || true
                log_info "Cleaned up test command: $cmd"
            fi
        fi
    done
}

# Export all functions
export -f log_info log_warning log_error
export -f check_command check_file check_directory
export -f check_env_var check_env_var_set
export -f check_file_permissions check_executable check_readable
export -f check_string_contains check_string_matches
export -f run_command capture_command_output
export -f check_port_listening check_service_running
export -f wait_for_condition
export -f start_test pass_test fail_test print_test_summary
export -f get_os_id get_os_version get_architecture
export -f is_ubuntu is_debian is_alpine is_centos is_x86_64 is_arm64
export -f cleanup_temp_files cleanup_test_commands 