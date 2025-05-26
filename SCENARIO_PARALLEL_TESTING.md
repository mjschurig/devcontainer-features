# Parallel Scenario Testing Implementation

This document describes the implementation of parallel scenario testing for dev container features, where each scenario defined in `scenarios.json` files runs as a separate worker in GitHub Actions.

## Overview

Previously, the workflows used a matrix strategy that tested each feature against multiple base images. Now, the workflows create a matrix based on feature-scenario combinations, allowing each scenario to run in parallel with its specific configuration.

## Key Changes

### 1. Workflow Matrix Strategy

**Before:**
```yaml
strategy:
  matrix:
    feature: ${{ fromJson(needs.detect-changes.outputs.features_json) }}
    base-image:
      - "mcr.microsoft.com/devcontainers/base:ubuntu"
      - "mcr.microsoft.com/devcontainers/base:debian"
```

**After:**
```yaml
strategy:
  matrix:
    include: ${{ fromJson(needs.detect-changes.outputs.feature_scenarios) }}
```

### 2. Scenario Detection Logic

Both `test.yml` and `release.yml` workflows now include logic to:

1. **Parse scenarios.json files**: Extract scenario names (object keys) from each feature's test directory
2. **Create feature-scenario combinations**: Generate a matrix that includes:
   - `feature`: The feature name
   - `scenario`: The scenario name
   - `image`: The base image for that scenario (from scenarios.json or default)

### 3. Scenario-Specific Test Execution

The test steps now:

1. **Check for scenario-specific scripts**: Look for `test/{feature}/{scenario}.sh` files
2. **Create temporary devcontainer.json**: Extract the scenario configuration from scenarios.json and convert feature names to local syntax (prepend `./src/`)
3. **Run scenario tests**: Execute either the scenario-specific script or fall back to general testing

**Important**: The workflows automatically convert feature names from `"feature-name"` to `"./src/feature-name"` to ensure compatibility with the devcontainer CLI's local feature requirements.

## File Structure

### Scenarios Configuration

Each feature can have a `test/{feature}/scenarios.json` file with this structure:

```json
{
  "default": {
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
      "feature-name": {}
    }
  },
  "with_option": {
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
      "feature-name": {
        "option": "value"
      }
    }
  },
  "debian_base": {
    "image": "mcr.microsoft.com/devcontainers/base:debian",
    "features": {
      "feature-name": {}
    }
  },
  "idempotency": {
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
      "feature-name": {}
    },
    "runTwice": true
  }
}
```

### Scenario-Specific Test Scripts

For each scenario, you can create a specific test script:

- `test/{feature}/default.sh`
- `test/{feature}/with_option.sh`
- `test/{feature}/debian_base.sh`
- `test/{feature}/idempotency.sh`

If a scenario-specific script doesn't exist, the workflow falls back to the general `scripts/test-feature.sh` with the scenario's base image.

## Benefits

### 1. True Parallel Execution

Each scenario runs as a separate GitHub Actions job, allowing:
- **Faster testing**: Scenarios run simultaneously instead of sequentially
- **Better resource utilization**: Multiple runners can work on different scenarios
- **Independent failure handling**: One scenario failure doesn't block others

### 2. Scenario-Specific Configuration

Each scenario can specify:
- **Custom base images**: Different scenarios can test against different OS distributions
- **Feature options**: Each scenario can test different feature configurations
- **Special behaviors**: Like `runTwice` for idempotency testing

### 3. Improved Visibility

The GitHub Actions UI now shows:
- Individual job status for each scenario
- Clear identification of which scenario failed
- Parallel execution timeline

## Example Workflow Execution

For a feature with 5 scenarios, the workflow now creates 5 parallel jobs:

```
✅ test-features (deal-ii, default, mcr.microsoft.com/devcontainers/base:ubuntu)
✅ test-features (deal-ii, with_mpi, mcr.microsoft.com/devcontainers/base:ubuntu)
❌ test-features (deal-ii, with_petsc, mcr.microsoft.com/devcontainers/base:ubuntu)
✅ test-features (deal-ii, with_trilinos, mcr.microsoft.com/devcontainers/base:ubuntu)
✅ test-features (deal-ii, idempotency, mcr.microsoft.com/devcontainers/base:ubuntu)
```

## New Scripts

### `scripts/test-feature-scenarios.sh`

A new script that can run all scenarios for a feature locally in parallel:

```bash
# Test all scenarios for deal-ii feature
./scripts/test-feature-scenarios.sh deal-ii

# Test all scenarios for trilinos feature
./scripts/test-feature-scenarios.sh trilinos
```

This script:
- Reads the scenarios.json file
- Runs each scenario in parallel as background processes
- Collects and reports results
- Provides detailed error information for failed scenarios

## Migration Guide

### For Existing Features

1. **Create scenarios.json**: If your feature doesn't have one, create `test/{feature}/scenarios.json`
2. **Define scenarios**: Add scenarios that cover your feature's different configurations
3. **Create scenario scripts**: Optionally create scenario-specific test scripts for complex scenarios

### Example Migration

**Before** (testing with multiple base images):
```bash
# Manual testing against different images
./scripts/test-feature.sh my-feature mcr.microsoft.com/devcontainers/base:ubuntu
./scripts/test-feature.sh my-feature mcr.microsoft.com/devcontainers/base:debian
```

**After** (scenario-based testing):
```json
{
  "default": {
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": { "my-feature": {} }
  },
  "debian": {
    "image": "mcr.microsoft.com/devcontainers/base:debian",
    "features": { "my-feature": {} }
  },
  "with_options": {
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
      "my-feature": {
        "option1": "value1",
        "option2": true
      }
    }
  }
}
```

```bash
# Test all scenarios in parallel
./scripts/test-feature-scenarios.sh my-feature
```

## Backward Compatibility

- Features without scenarios.json files will get a default scenario with Ubuntu base image
- Existing test.sh scripts continue to work as fallbacks
- The general test-feature.sh script remains functional for manual testing

## Performance Impact

- **Reduced total test time**: Parallel execution significantly reduces overall workflow duration
- **Increased runner usage**: More GitHub Actions runners are used simultaneously
- **Better failure isolation**: Failed scenarios don't impact others, allowing partial success states

## Technical Implementation Details

### Local Feature Reference Fix

The devcontainer CLI requires local features to be prefixed with `./` to distinguish them from registry features. To handle this, the workflows automatically convert feature names in scenarios.json from:

```json
{
  "features": {
    "deal-ii": {}
  }
}
```

To:

```json
{
  "features": {
    "./src/deal-ii": {}
  }
}
```

This conversion happens automatically in both GitHub Actions workflows and the local test script, ensuring compatibility without requiring changes to existing scenarios.json files.
