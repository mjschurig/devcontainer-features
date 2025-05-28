#!/bin/bash

set -e

source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Compression libraries scenario..."

check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Check for compression library support
check "ZLIB support enabled" grep -q "DEAL_II_WITH_ZLIB.*ON" "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

reportResults
