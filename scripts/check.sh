#!/bin/bash
# ============================================================
# check.sh
# Local CI check script, simulating the GitHub Actions CI process
# Usage: ./scripts/check.sh
# ============================================================

set -e
cd "$(dirname "$0")/.."

run_step() {
    local name="$1"
    shift
    echo ""
    echo "$name"
    "$@"
    echo "Passed: $name"
}

run_format_step() {
    echo ""
    echo "dart format check"

    if dart format --output=none --set-exit-if-changed lib test pigeons; then
        echo "Passed: dart format check"
    else
        echo "Dart format found unformatted files. Auto-formatting..."
        dart format lib test pigeons
        echo "Passed: dart format auto-fix"
    fi
}

run_step "flutter pub get"            flutter pub get
run_format_step
run_step "flutter analyze"            flutter analyze
run_step "flutter test"               flutter test --reporter compact
run_step "flutter build apk --debug"  flutter build apk --debug

echo ""
echo "All checks passed!"