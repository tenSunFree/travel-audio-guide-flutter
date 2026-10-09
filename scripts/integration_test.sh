#!/usr/bin/env bash
# scripts/integration_test.sh
#
# Run the hermetic App-level integration tests (integration_test/) on a
# device or emulator.
#
# SLOW by design (builds + installs an APK, boots the app per file), so it is
# intentionally NOT part of scripts/check.sh / pre-push.
#
# The tests fake every external service (Taipei Travel API, Supabase Auth,
# audio playback, notifications, analytics), so no env/*.json secrets are
# required. The only build-time requirement is the staging Firebase config
# (android/app/src/staging/google-services.json), because the Android
# google-services Gradle plugin needs it to build the staging flavor.
#
# Usage:
#   bash scripts/integration_test.sh
#   make integration-test
#
# Options (environment variables):
#   DEVICE_ID              Target device, e.g. emulator-5554 (default: auto)
#   FLAVOR                 Android flavor (default: staging)
#   TARGET                 A single test file or directory (default: integration_test)
#   INTEGRATION_ENV_FILE   Optional --dart-define-from-file (not needed by the hermetic tests)
#
# Examples:
#   DEVICE_ID=emulator-5554 make integration-test
#   TARGET=integration_test/browse_flow_test.dart make integration-test

set -euo pipefail
cd "$(dirname "$0")/.."
source "scripts/_fvm.sh"

DEVICE_ID="${DEVICE_ID:-}"
FLAVOR="${FLAVOR:-staging}"
TARGET="${TARGET:-integration_test}"
INTEGRATION_ENV_FILE="${INTEGRATION_ENV_FILE:-}"

if [[ ! -e "$TARGET" ]]; then
    echo "ERROR: test target not found: $TARGET"
    exit 1
fi

if [[ "$FLAVOR" == "staging" && ! -f "android/app/src/staging/google-services.json" ]]; then
    echo "ERROR: android/app/src/staging/google-services.json is missing."
    echo "The staging flavor cannot be built without it (google-services Gradle plugin)."
    exit 1
fi

ARGS=(test "$TARGET" --flavor "$FLAVOR")

if [[ -n "$INTEGRATION_ENV_FILE" ]]; then
    if [[ ! -f "$INTEGRATION_ENV_FILE" ]]; then
        echo "ERROR: INTEGRATION_ENV_FILE not found: $INTEGRATION_ENV_FILE"
        exit 1
    fi
    ARGS+=(--dart-define-from-file="$INTEGRATION_ENV_FILE")
fi

if [[ -n "$DEVICE_ID" ]]; then
    ARGS+=(-d "$DEVICE_ID")
fi

echo ""
echo "==> Integration tests"
echo "    target : $TARGET"
echo "    flavor : $FLAVOR"
echo "    device : ${DEVICE_ID:-<auto>}"
echo ""

# FLUTTER_CMD may be "fvm flutter" (two words), so it is intentionally unquoted,
# the same way scripts/check.sh uses it.
$FLUTTER_CMD "${ARGS[@]}"

echo ""
echo "Integration tests passed!"