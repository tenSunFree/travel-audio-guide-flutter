#!/usr/bin/env bash
# scripts/doctor.sh
#
# Local development environment health check.
# The purpose is not to run tests, but to confirm that your computer environment is ready for developing this project.
#
# Severity Level:
#   FAIL -> Truly impossible to develop with (git / flutter / dart are all required), will result in exit code 1
#   WARN -> Recommended to complete, but will not hinder development (Java, Android SDK, gitleaks, hooks, environment files, etc.)
#
# Usage: bash scripts/doctor.sh

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || cd "$(dirname "$0")/.."

EXIT_CODE=0

# Detect whether it is running under WSL (Windows Subsystem for Linux).
# If Flutter/FVM for this project is installed on Windows, WSL cannot directly execute Windows .bat files,
# resulting in strange error messages such as "Trying to read .bat content as a bash script" (e.g., @echo/rem: command not found).
# In this case, it is recommended to use Git Bash (MINGW64) to execute this series of scripts instead of WSL.
if grep -qi microsoft /proc/version 2>/dev/null || [[ "$(uname -r 2>/dev/null)" == *[Mm]icrosoft* ]]; then
    echo ""
    echo "[WARN] Detected currently executing in WSL"
    echo "       If your Flutter/FVM is installed on Windows (e.g., C:\\flutter...),"
    echo "       Please use Git Bash (MINGW64) to execute this series of scripts to avoid errors caused by .bat files failing to execute."
fi

# Find the first existing candidate command.
# On Windows, `dart pub global activate xxx` often only installs shims like xxx.bat/xxx.exe.
# Git Bash's `command -v` doesn't automatically auto-completion file extensions (unlike Windows PATHEXT).
# Therefore, this code explicitly tries several common file extensions to ensure accurate detection on macOS/Linux/Windows (Git Bash).
resolve_cmd() {
    local base="$1"
    local candidate

    for candidate in "$base" "$base.exe" "$base.bat" "$base.cmd"; do
        if command -v "$candidate" >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

check_cmd() {
    local label="$1"
    local base_cmd="$2"
    local required="$3" # required | optional

    local resolved
    if resolved=$(resolve_cmd "$base_cmd"); then
        local version
        version=$("$resolved" --version 2>&1 | sed '/^[[:space:]]*$/d' | head -n1)
        echo "[OK]   $label ($version)"
    elif [ "$required" = "required" ]; then
        echo "[FAIL] $label not installed"
        EXIT_CODE=1
    else
        echo "[WARN] $label not installed (installation recommended)"
    fi
}

check_file() {
    local label="$1"
    local path="$2"

    if [ -f "$path" ]; then
        echo "[OK]   $label ($path)"
    else
        echo "[WARN] $label does not exist: $path"
    fi
}

echo ""
echo "=== Required Tools (Failure will result in immediate failure) ==="
check_cmd "Git"     git     required
check_cmd "Flutter" flutter required
check_cmd "Dart"    dart    required

echo ""
echo "=== Suggested Tools (Missing tools will only be suggested and will not hinder development) ==="
check_cmd "Java"     java     optional
check_cmd "FVM"      fvm      optional
check_cmd "gitleaks" gitleaks optional

echo ""
echo "=== Environment configuration file (env/) ==="
check_file "dev environment settings"     "env/dev.json"
check_file "release environment settings" "env/release.json"
if [ ! -f "env/dev.json" ]; then
    echo "       Tip: Copy env/example.json to env/dev.json, then fill in the required runtime configuration."
fi

echo ""
echo "=== FVM Version Lock ==="
if [ -f ".fvmrc" ] || [ -f ".fvm/fvm_config.json" ]; then
    echo "[OK]   Flutter version locked"
else
    echo "[WARN] Flutter version not yet locked using FVM (recommended for multi-user collaboration)."
fi

echo ""
echo "=== Git Hooks ==="
check_file "pre-commit hook" ".git/hooks/pre-commit"
check_file "pre-push hook"   ".git/hooks/pre-push"
check_file "commit-msg hook" ".git/hooks/commit-msg"
if [ ! -f ".git/hooks/pre-commit" ] || [ ! -f ".git/hooks/pre-push" ] || [ ! -f ".git/hooks/commit-msg" ]; then
    echo "       Tip: bash scripts/setup-hooks.sh"
fi

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "The environment is missing some necessary tools. Please add them according to the [FAIL] above and then run it again."
    exit 1
fi

source "scripts/_fvm.sh"

echo ""
echo "=== flutter doctor (Complete Android/iOS toolchain check) ==="
$FLUTTER_CMD doctor

echo ""
echo "Environment check passed, development can begin!"
exit 0