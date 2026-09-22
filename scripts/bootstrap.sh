#!/usr/bin/env bash
# scripts/bootstrap.sh
#
# One-click initialization of the development environment reduces onboarding costs for new engineers.
# This includes: checking the environment -> installing dependencies -> creating an environment profile -> installing git hooks.
#
# Usage: bash scripts/bootstrap.sh

set -euo pipefail
cd "$(dirname "$0")/.."
source "scripts/_fvm.sh"

run_step() {
    local name="$1"
    shift
    echo ""
    echo "==> $name"
    "$@"
    echo "Passed: $name"
}

echo ""
echo "=== bootstrap: Initialize the development environment ==="

run_step "Check local environment" bash scripts/doctor.sh
run_step "Install Flutter dependencies" $FLUTTER_CMD pub get
run_step "Install app_lints dependencies" bash -c "cd packages/app_lints && $DART_CMD pub get"

if [ ! -f "env/dev.json" ]; then
    echo ""
    echo "==> Create env/dev.json"
    cp env/example.json env/dev.json
    echo "The env/dev.json file has been created. Please fill in the required runtime configuration values."
else
    echo ""
    echo "[OK] The env/dev.json file already exists, so we will skip creating it."
fi

run_step "Install git hooks" bash scripts/setup-hooks.sh

echo ""
echo "=== Bootstrap complete! ==="
echo "Common commands:"
echo "  bash scripts/format.sh       # Automatic formatting (will modify files)"
echo "  bash scripts/check.sh        # Local CI check (will not modify files)"
echo "  bash scripts/secret-scan.sh  # Full confidential scan"
echo "  bash scripts/doctor.sh       # Recheck environment"
echo "  bash scripts/run_dev.sh      # Start development mode"