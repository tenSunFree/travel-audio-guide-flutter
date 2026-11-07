#!/usr/bin/env bash
# scripts/_fvm.sh
#
# Shared helper for selecting Flutter/Dart commands.
# This file is intended to be sourced by other scripts, not executed directly.
#
# Usage:
#   cd "$(dirname "$0")/.."
#   source "scripts/_fvm.sh"
#   $FLUTTER_CMD pub get
#   $DART_CMD format lib test integration_test pigeons
#
# Note: on Windows, `dart pub global activate fvm` typically installs a
# `fvm.bat` shim rather than a bare `fvm` executable. Git Bash's `command -v`
# does not automatically resolve `.bat`/`.cmd` the way Windows' PATHEXT does,
# so we check a few common extensions explicitly.

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is intended to be sourced, not executed directly."
    echo "Usage:"
    echo "  source scripts/_fvm.sh"
    exit 1
fi

FLUTTER_CMD="flutter"
DART_CMD="dart"

FVM_CMD=""
for candidate in fvm fvm.exe fvm.bat fvm.cmd; do
    if command -v "$candidate" >/dev/null 2>&1; then
        FVM_CMD="$candidate"
        break
    fi
done

if [ -n "$FVM_CMD" ] && { [ -f ".fvmrc" ] || [ -f ".fvm/fvm_config.json" ]; }; then
    FLUTTER_CMD="$FVM_CMD flutter"
    DART_CMD="$FVM_CMD dart"
    echo "[fvm] FVM config detected. Using $FVM_CMD flutter / $FVM_CMD dart."
fi