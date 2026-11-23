#!/usr/bin/env bash
# scripts/fetch_web_sqlite_assets.sh
#
# Downloads the two files Drift needs on Flutter Web into web/:
#   - sqlite3.wasm      (from simolus3/sqlite3.dart, tag sqlite3-<version>)
#   - drift_worker.js   (from simolus3/drift,        tag drift-<version>)
#
# Versions are read from pubspec.lock so the assets always match the
# resolved `sqlite3` / `drift` packages. Re-run after upgrading either one
# (CI runs it before every web build).
#
# Usage:
#   bash scripts/fetch_web_sqlite_assets.sh [output_dir]   # default: web

set -euo pipefail

OUT_DIR="${1:-web}"
LOCK_FILE="pubspec.lock"

lock_version() {
  # Prints the resolved version of package $1 from pubspec.lock.
  awk -v pkg="$1" '
    $0 ~ "^  " pkg ":$" { in_pkg = 1; next }
    in_pkg && /^    version:/ { gsub(/"/, "", $2); print $2; exit }
    in_pkg && /^  [a-z_0-9]+:$/ { exit }
  ' "$LOCK_FILE"
}

SQLITE3_VERSION="$(lock_version sqlite3)"
DRIFT_VERSION="$(lock_version drift)"

if [[ -z "$SQLITE3_VERSION" || -z "$DRIFT_VERSION" ]]; then
  echo "::error::Could not read sqlite3/drift versions from $LOCK_FILE (run flutter pub get first)."
  exit 1
fi

mkdir -p "$OUT_DIR"

download() {
  local url="$1" dest="$2"
  echo "Downloading $url"
  curl --fail --silent --show-error --location --retry 3 --output "$dest.tmp" "$url"
  if [[ ! -s "$dest.tmp" ]]; then
    echo "::error::Downloaded file is empty: $url"
    rm -f "$dest.tmp"
    exit 1
  fi
  mv "$dest.tmp" "$dest"
}

download \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${SQLITE3_VERSION}/sqlite3.wasm" \
  "$OUT_DIR/sqlite3.wasm"
download \
  "https://github.com/simolus3/drift/releases/download/drift-${DRIFT_VERSION}/drift_worker.js" \
  "$OUT_DIR/drift_worker.js"

# Refuse an HTML error page or a truncated file under a successful HTTP status.
if [[ "$(head -c4 "$OUT_DIR/sqlite3.wasm" | od -An -tx1 | tr -d ' \n')" != "0061736d" ]]; then
  echo "::error::sqlite3.wasm has an invalid WebAssembly header"
  exit 1
fi
node --check "$OUT_DIR/drift_worker.js"

echo "Drift web assets ready in $OUT_DIR (sqlite3 ${SQLITE3_VERSION}, drift ${DRIFT_VERSION})."
