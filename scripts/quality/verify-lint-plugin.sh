#!/usr/bin/env bash
# scripts/quality/verify-lint-plugin.sh
#
# Proves that the custom analyzer plugin (packages/app_lints) is actually
# loaded and reporting diagnostics when a file is analyzed with an explicit
# path (the mode used by scripts/quality/analyze-dart.sh).
#
# Why: an analysis run exits 0 both when the code is clean AND when the plugin
# silently failed to report, so a green run alone does not prove the custom
# rules ran. This is a negative test: a probe file deliberately calls
# debugPrint(), and analysis must FAIL with an avoid_debug_print diagnostic.
#
# The probe never overwrites an existing file, is removed on exit (including
# Ctrl+C), and is git-ignored as a second safety net.
#
# Usage: bash scripts/quality/verify-lint-plugin.sh

set -euo pipefail
cd "$(dirname "$0")/../.."
source scripts/_fvm.sh

# _fvm.sh yields a command string such as "fvm dart"; split it once.
read -r -a dart_cmd <<< "$DART_CMD"

probe="lib/app_lints_smoke_probe.dart"
log="$(mktemp)"
owned=0

cleanup() {
    if [[ "$owned" == 1 ]]; then rm -f -- "$probe"; fi
    rm -f -- "$log"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Never overwrite or delete a pre-existing file, even an ignored one.
if [[ -e "$probe" || -L "$probe" ]] || ! (set -o noclobber; : > "$probe") 2>/dev/null; then
    echo "ERROR: $probe already exists or cannot be created." >&2
    echo "If it is left over from an interrupted run, delete it and re-run." >&2
    exit 1
fi
owned=1

cat > "$probe" <<'DART'
// Temporary file created by scripts/quality/verify-lint-plugin.sh.
// It must never be committed; it is deleted when the script exits.
import 'package:flutter/foundation.dart';

void lintSmokeProbe() {
  debugPrint('lint smoke test');
}
DART

for attempt in 1 2; do
    status=0
    "${dart_cmd[@]}" analyze --fatal-infos --format=machine "$probe" > "$log" 2>&1 || status=$?
    case "$status" in
        130|143) exit "$status" ;;
    esac

    # Dart analysis exit codes 1/2/3 represent fatal info/warning/error.
    # Match the structured diagnostic's exact code and probe filename, not
    # arbitrary log text. Machine format avoids terminal-width wrapping.
    if [[ "$status" == 1 || "$status" == 2 || "$status" == 3 ]] &&
        awk -F '|' '
            NF >= 8 && $1 ~ /^(INFO|WARNING|ERROR)$/ &&
            tolower($3) == "avoid_debug_print" &&
            $4 ~ /(^|[\/\\])app_lints_smoke_probe[.]dart$/ &&
            $5 ~ /^[0-9]+$/ && $6 ~ /^[0-9]+$/ { found=1 }
            END { exit !found }
        ' "$log"; then
        echo "Passed: custom lint plugin is active (avoid_debug_print reported)."
        exit 0
    fi

    echo "Attempt $attempt/2: no valid avoid_debug_print probe diagnostic (analyzer exit $status)." >&2
done

echo "" >&2
echo "ERROR: the custom lint plugin (packages/app_lints) did not report a" >&2
echo "deliberate violation, so analysis would pass silently without enforcing" >&2
echo "the custom rules. Analyzer output was:" >&2
echo "------------------------------------------------------------" >&2
cat "$log" >&2
echo "------------------------------------------------------------" >&2
echo "Try: (cd packages/app_lints && dart pub get), then re-run." >&2
exit 1
