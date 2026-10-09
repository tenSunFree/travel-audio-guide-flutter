#!/usr/bin/env bash
# scripts/format.sh
#
# Automatically format project source code (will directly modify the file)
#
# Division of labor with scripts/check.sh:
#   format.sh -> Automatically modifies files (for local use)
#   check.sh -> Only verifies, does not modify (for CI; fails if the format is incorrect)
#
# Usage: bash scripts/format.sh

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

run_step "dart format (lib test integration_test pigeons)" $DART_CMD format lib test integration_test pigeons

echo ""
echo "Formatting complete."
echo "Please run 'git diff' to check the changes, and add/commit only after confirming that everything is correct."