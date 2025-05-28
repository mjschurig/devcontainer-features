#!/bin/bash

set -e

source dev-container-features-test-lib

echo "🧪 Testing deal.II candi feature - Developer mode scenario..."

check "deal.II installation exists" test -d "${DEAL_II_DIR:-/usr/local/dealii-candi}"

# Check that basic installation works even in developer mode
check "deal.II config file exists" test -f "${DEAL_II_DIR}/lib/cmake/deal.II/deal.IIConfig.cmake"

reportResults
