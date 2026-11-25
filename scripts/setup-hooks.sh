#!/bin/bash
# ============================================================
# setup-hooks.sh
# One-click installation project: git hooks (pre-commit + commit-msg + pre-push)
# Hook templates are located in scripts/hooks/ and copied to the repository-local Git hooks directory.
# Usage: bash scripts/setup-hooks.sh
# ============================================================

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

HOOKS_SRC_DIR="scripts/hooks"
HOOKS_DIR="$(git rev-parse --path-format=absolute --git-common-dir)/hooks"
ACTIVE_HOOKS_DIR="$(git rev-parse --path-format=absolute --git-path hooks)"
if [[ "$ACTIVE_HOOKS_DIR" != "$HOOKS_DIR" ]]; then
    echo "ERROR: Git uses a custom core.hooksPath: $ACTIVE_HOOKS_DIR" >&2
    echo "Review that directory before installing hooks; no files were overwritten." >&2
    exit 1
fi
mkdir -p -- "$HOOKS_DIR"

install_hook() {
    local name="$1"

    if [ ! -f "$HOOKS_SRC_DIR/$name" ]; then
        echo "Hook source file not found: $HOOKS_SRC_DIR/$name"
        exit 1
    fi

    cp "$HOOKS_SRC_DIR/$name" "$HOOKS_DIR/$name"
    chmod +x "$HOOKS_DIR/$name"
    echo "Installed: $HOOKS_DIR/$name"
}

install_hook "pre-commit"
install_hook "commit-msg"
install_hook "pre-push"

echo ""
echo "Git hooks installation complete!"
echo "  - pre-commit: dart format + flutter analyze + custom lints(staged) + secret scan(staged)"
echo "  - commit-msg: Conventional Commits format check"
echo "  - pre-push:   scripts/check.sh (pub get + format + analyze + custom lints + test + build)"
