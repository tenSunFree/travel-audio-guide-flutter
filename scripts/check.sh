#!/usr/bin/env bash
# scripts/check.sh
# Local CI check script, simulating the GitHub Actions CI process
# Usage: bash scripts/check.sh

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

run_step "flutter pub get" $FLUTTER_CMD pub get

run_step "app_lints pub get" bash -c "cd packages/app_lints && $DART_CMD pub get"

run_step "app_lints analyze" bash -c "cd packages/app_lints && $DART_CMD analyze"

echo ""
echo "==> dart format check"
if $DART_CMD format --output=none --set-exit-if-changed lib test integration_test pigeons; then
    echo "Passed: dart format check"
else
    echo ""
    echo "An unformatted file was found. Please execute:"
    echo "  bash scripts/format.sh"
    echo "After confirming that the git diff is correct, then add, commit, or push."
    exit 1
fi

run_step "flutter analyze" $FLUTTER_CMD analyze

# Run the test suite once, with coverage enabled, so a single test run both
# validates the code and refreshes the local coverage/lcov.info file.
# (Do NOT also run scripts/coverage.sh here — that would run the whole
# test suite a second time for no benefit.)
run_step "flutter test with coverage" \
  $FLUTTER_CMD test --coverage --reporter compact

# Verify that Flutter actually generated a usable LCOV report.
# Mirrors the same check used in .github/workflows/ci.yml so local and CI
# behavior stay consistent.
echo ""
echo "==> verify coverage report"

if [[ ! -s coverage/lcov.info ]]; then
    echo "ERROR: coverage/lcov.info was not generated or is empty."
    exit 1
fi

source_count=$(grep -c '^SF:' coverage/lcov.info || true)

if [[ "$source_count" -eq 0 ]]; then
    echo "ERROR: coverage/lcov.info contains no source-file records."
    exit 1
fi

echo "Passed: coverage report"
echo "Coverage report: coverage/lcov.info ($source_count source files)"

# This project sets two flavors in android/app/build.gradle.kts: staging and production.
# Therefore, you cannot directly run `flutter build apk --debug` without the `--flavor` option.
# Otherwise, Gradle will produce app-staging-debug.apk and app-production-debug.apk.
# Flutter tools will report an error if app-debug.apk is not found in the expected path:
# "Gradle build failed to produce an .apk file."
#
# Local pre-push only builds staging (daily development environment), thereby achieving faster inspection speed;
# The complete build and verification of production flavors is handled by .github/workflows/ci.yml after push;
# The two do not replace each other, they just have different functions.
run_step "flutter build staging debug apk" $FLUTTER_CMD build apk --debug --flavor staging -t lib/main_staging.dart

echo ""
echo "All checks passed!"