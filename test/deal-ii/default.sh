#!/bin/bash
set -e

# Test deal.II with default configuration
echo "🧪 Testing deal.II with default configuration..."

# Source the main test script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test.sh"

# Additional tests specific to default configuration
echo ""
echo "🔍 Default Configuration Specific Tests"
echo "========================================="

# Test that MPI is NOT enabled by default
if ! command -v mpicc >/dev/null 2>&1; then
    echo "✅ MPI not installed (expected for default configuration)"
else
    echo "ℹ️  MPI is available but deal.II should not be using it by default"
fi

# Test that PETSc is NOT enabled by default
if ! ldconfig -p 2>/dev/null | grep -q "libpetsc"; then
    echo "✅ PETSc not installed (expected for default configuration)"
else
    echo "ℹ️  PETSc is available but deal.II should not be using it by default"
fi

# Test that Trilinos is NOT enabled by default
if [ ! -d "/usr/local/trilinos" ]; then
    echo "✅ Trilinos not installed (expected for default configuration)"
else
    echo "ℹ️  Trilinos is available but deal.II should not be using it by default"
fi

echo ""
echo "🎉 Default configuration tests completed!"
