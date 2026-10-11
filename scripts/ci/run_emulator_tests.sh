#!/usr/bin/env bash
#
# scripts/ci/run_emulator_tests.sh
#
# CI-only Android emulator wrapper.
#
# Responsibilities:
#
#   1. Wait for emulator
#   2. Disable automatic rotation
#   3. Run integration tests for requested rotations
#   4. Collect diagnostics on failure
#   5. Restore natural orientation before exit
#
# The actual Flutter integration-test command remains in:
#
#   scripts/integration_test.sh
#
# Environment:
#
#   DEVICE_ID
#     adb serial
#     default: emulator-5554
#
#   ROTATIONS
#     Space-separated Android user_rotation values.
#
#       0 = natural orientation
#       1 = natural orientation + 90 degrees
#
#     default: "0"
#
#   LABEL
#     Artifact directory label.
#     default: local
#
#   FLAVOR
#     Forwarded to scripts/integration_test.sh.
#     default: staging
#
# Example:
#
#   DEVICE_ID=emulator-5554 \
#   ROTATIONS="0 1" \
#   LABEL=tablet-api36 \
#   FLAVOR=staging \
#   bash scripts/ci/run_emulator_tests.sh
#

set -euo pipefail

cd "$(dirname "$0")/../.."

DEVICE_ID="${DEVICE_ID:-emulator-5554}"
ROTATIONS="${ROTATIONS:-0}"
LABEL="${LABEL:-local}"
FLAVOR="${FLAVOR:-staging}"

OUT_DIR="build/ci-artifacts/${LABEL}"

mkdir -p "$OUT_DIR"


# ---------------------------------------------------------------------------
# adb helper
# ---------------------------------------------------------------------------

adb_device() {
    command adb -s "$DEVICE_ID" "$@"
}


# ---------------------------------------------------------------------------
# Diagnostics
# ---------------------------------------------------------------------------

collect_diagnostics() {
    local status=$?

    # Disable the EXIT trap while this function is executing.
    trap - EXIT

    if [[ $status -ne 0 ]]; then
        echo ""
        echo "==> Integration tests failed (exit=$status)"
        echo "==> Collecting emulator diagnostics..."

        adb_device logcat -d -v threadtime \
            > "$OUT_DIR/logcat.txt" \
            2>&1 || true

        adb_device exec-out screencap -p \
            > "$OUT_DIR/screen.png" \
            2>/dev/null || true

        adb_device shell dumpsys window displays \
            > "$OUT_DIR/window-displays.txt" \
            2>&1 || true

        adb_device shell dumpsys activity activities \
            > "$OUT_DIR/activities.txt" \
            2>&1 || true

        adb_device shell getprop \
            > "$OUT_DIR/getprop.txt" \
            2>&1 || true
    fi

    # Always leave the emulator in natural orientation.
    adb_device shell settings put system user_rotation 0 \
        >/dev/null 2>&1 || true

    exit "$status"
}

trap collect_diagnostics EXIT


# ---------------------------------------------------------------------------
# Wait for emulator
# ---------------------------------------------------------------------------

echo "==> Waiting for emulator: $DEVICE_ID"

adb_device wait-for-device

# Android can report adb-ready before boot is actually complete.
echo "==> Waiting for Android boot completion..."

for _ in {1..60}; do

    BOOT_COMPLETED="$(
        adb_device shell getprop sys.boot_completed \
            2>/dev/null \
            | tr -d '\r'
    )"

    if [[ "$BOOT_COMPLETED" == "1" ]]; then
        break
    fi

    sleep 2
done

BOOT_COMPLETED="$(
    adb_device shell getprop sys.boot_completed \
        2>/dev/null \
        | tr -d '\r'
)"

if [[ "$BOOT_COMPLETED" != "1" ]]; then
    echo "ERROR: emulator did not finish booting."
    exit 1
fi


# ---------------------------------------------------------------------------
# Device information
# ---------------------------------------------------------------------------

MODEL="$(
    adb_device shell getprop ro.product.model \
        | tr -d '\r'
)"

API="$(
    adb_device shell getprop ro.build.version.sdk \
        | tr -d '\r'
)"

ANDROID_VERSION="$(
    adb_device shell getprop ro.build.version.release \
        | tr -d '\r'
)"

SIZE="$(
    adb_device shell wm size \
        | tr -d '\r' \
        | tail -n 1
)"

DENSITY="$(
    adb_device shell wm density \
        | tr -d '\r' \
        | tail -n 1
)"

echo ""
echo "==> Emulator"
echo "    id      : $DEVICE_ID"
echo "    model   : $MODEL"
echo "    Android : $ANDROID_VERSION"
echo "    API     : $API"
echo "    size    : $SIZE"
echo "    density : $DENSITY"
echo "    flavor  : $FLAVOR"
echo "    rotation: $ROTATIONS"
echo ""


# ---------------------------------------------------------------------------
# Orientation setup
#
# Disable accelerometer-controlled rotation so user_rotation is deterministic.
# ---------------------------------------------------------------------------

adb_device shell settings put system accelerometer_rotation 0


# ---------------------------------------------------------------------------
# Integration test runs
# ---------------------------------------------------------------------------

for rotation in $ROTATIONS; do

    case "$rotation" in
        0|1|2|3)
            ;;
        *)
            echo "ERROR: invalid user_rotation: $rotation"
            exit 1
            ;;
    esac

    echo ""
    echo "============================================================"
    echo "Integration tests"
    echo "Rotation: $rotation"
    echo "============================================================"
    echo ""

    adb_device shell settings put system user_rotation "$rotation"

    # Allow WindowManager + Flutter surface to settle.
    sleep 3

    echo "==> Window rotation"

    adb_device shell dumpsys window displays \
        2>/dev/null \
        | grep -m1 -E 'mCurrentRotation|rotation=' \
        || true

    echo ""
    echo "==> Running Flutter integration suite"
    echo ""

    DEVICE_ID="$DEVICE_ID" \
    FLAVOR="$FLAVOR" \
        bash scripts/integration_test.sh

done


# ---------------------------------------------------------------------------
# Success
# ---------------------------------------------------------------------------

echo ""
echo "============================================================"
echo "All emulator integration tests passed."
echo "============================================================"
