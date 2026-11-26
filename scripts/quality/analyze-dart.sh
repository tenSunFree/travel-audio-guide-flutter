#!/usr/bin/env bash
# scripts/quality/analyze-dart.sh
#
# Single entry point for custom-lint enforcement (packages/app_lints).
#
# 1. Checks that the custom analyzer plugin reports a deliberate violation
#    in a separate probe invocation (verify-lint-plugin.sh).
# 2. Runs `dart analyze --fatal-infos` on an EXPLICIT list of Dart files.
#
# Why explicit files: in this project, analyzing a directory or the whole
# project can pass silently on a warm analysis cache (the custom rules'
# diagnostics disappear), and `flutter analyze` does not report them at all.
# Analyzing explicit files was observed to report them every time.
#
# Usage:
#   bash scripts/quality/analyze-dart.sh            # all tracked Dart files
#   bash scripts/quality/analyze-dart.sh --staged   # staged Dart files (pre-commit)
#
# --staged:
#   * escalates to the full analysis when lint inputs (plugin, analysis
#     options, dependencies, these scripts) are staged, since they can change
#     the result for every file;
#   * refuses to run when a staged file (or a lint input) also has UNSTAGED
#     edits, because dart analyze reads the working tree, not the index.
# This is a working-tree check, not an isolated index snapshot; CI validates
# the actual commit. Unrelated working-tree edits can affect diagnostics.

set -euo pipefail
cd "$(dirname "$0")/../.."
source scripts/_fvm.sh

case "${1:-}" in
    '') mode=all ;;
    --staged) mode=staged ;;
    *) echo "Usage: $0 [--staged]" >&2; exit 2 ;;
esac
if [[ $# -gt 1 ]]; then echo "Usage: $0 [--staged]" >&2; exit 2; fi

lint_inputs=(analysis_options.yaml pubspec.yaml pubspec.lock .fvmrc
             packages/app_lints scripts/_fvm.sh scripts/quality)

# changed <git diff args>: returns 0 if there are differences, 1 if none, and
# aborts on any git failure (fail closed; never mistake an error for "clean").
changed() {
    local rc=0
    git --literal-pathspecs diff --quiet "$@" || rc=$?
    case "$rc" in
        0) return 1 ;;
        1) return 0 ;;
        *) echo "ERROR: git diff failed (exit $rc); refusing to pass." >&2; exit 1 ;;
    esac
}

list="$(mktemp)"
trap 'rm -f -- "$list"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

fail_listing() {
    echo "ERROR: could not list Dart files to analyze; refusing to pass." >&2
    exit 1
}

# Keep one definition of the application analysis scope for both modes.
is_source_dart() {
    case "$1" in
        *.g.dart|*.freezed.dart|lib/config/firebase/firebase_options_*.dart) return 1 ;;
        lib/*.dart|test/*.dart|integration_test/*.dart|pigeons/*.dart) return 0 ;;
        *) return 1 ;;
    esac
}

if [[ "$mode" == staged ]]; then
    if changed -- "${lint_inputs[@]}"; then
        echo "ERROR: lint configuration has unstaged changes; stage or restore them." >&2
        exit 1
    fi
    # git diff cannot see new untracked inputs, which may affect the plugin.
    git ls-files --others --exclude-standard -z -- "${lint_inputs[@]}" > "$list" \
        || fail_listing
    if [[ -s "$list" ]]; then
        echo "ERROR: untracked lint inputs exist; stage or remove them before committing." >&2
        exit 1
    fi
    # --no-renames reports a rename as delete + add, so the new path is kept.
    git diff --cached --name-only --no-renames --diff-filter=ACMT -z -- > "$list" \
        || fail_listing

    # Always check staged sources BEFORE deciding whether to escalate to all.
    while IFS= read -r -d '' file; do
        if is_source_dart "$file" && changed -- "$file"; then
            echo "ERROR: $file has unstaged changes; stage or restore them." >&2
            exit 1
        fi
    done < "$list"

    if changed --cached -- "${lint_inputs[@]}"; then
        echo "Lint plugin, analysis options or dependencies are staged: running the full analysis."
        mode=all
    fi
fi
if [[ "$mode" == all ]]; then
    git ls-files -z -- lib test integration_test pigeons > "$list" || fail_listing
fi

files=()
while IFS= read -r -d '' file; do
    if [[ "$file" == lib/app_lints_smoke_probe.dart ]]; then
        echo "ERROR: the temporary lint probe must never be tracked." >&2
        exit 1
    fi
    if ! is_source_dart "$file"; then continue; fi
    if [[ ! -f "$file" || -L "$file" ]]; then
        echo "ERROR: expected regular Dart file is missing or a symlink: $file" >&2
        exit 1
    fi
    files+=("$file")
done < "$list"

if [[ ${#files[@]} -eq 0 ]]; then
    if [[ "$mode" == all ]]; then
        echo "ERROR: no tracked Dart files found in the analysis scope." >&2
        exit 1
    fi
    echo "No staged Dart files to analyze; skipped."
    exit 0
fi

bash scripts/quality/verify-lint-plugin.sh

# _fvm.sh yields a command string such as "fvm dart"; split it once and keep
# every file argument separately quoted.
read -r -a dart_cmd <<< "$DART_CMD"

echo "Analyzing ${#files[@]} Dart file(s) as explicit paths ($mode)..."

failed=0
batch=()
# Conservative size budget for Windows cmd.exe / fvm.bat (limit 8191 chars).
length=256
run_batch() {
    local rc=0
    "${dart_cmd[@]}" analyze --fatal-infos "$@" || rc=$?
    case "$rc" in
        0) ;;
        130|143) exit "$rc" ;;
        *) failed=1 ;;
    esac
}
for file in "${files[@]}"; do
    cost=$(( ${#file} * 2 + 4 ))
    if (( cost + 256 > 6000 )); then
        echo "ERROR: Dart file path exceeds the command-line budget: $file" >&2
        exit 1
    fi
    if (( ${#batch[@]} > 0 && (length + cost > 6000 || ${#batch[@]} >= 100) )); then
        run_batch "${batch[@]}"
        batch=()
        length=256
    fi
    batch+=("$file")
    length=$(( length + cost ))
done
if [[ ${#batch[@]} -gt 0 ]]; then
    run_batch "${batch[@]}"
fi

if [[ "$failed" -ne 0 ]]; then
    echo "ERROR: dart analyze reported issues (see above)." >&2
    exit 1
fi
echo "Passed: dart analyze (${#files[@]} file(s), $mode)."
