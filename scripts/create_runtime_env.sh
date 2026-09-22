#!/usr/bin/env bash
# scripts/create_runtime_env.sh
#
# CI-only: combine GitHub Actions vars/secrets into env/ci.json,
# so Flutter build commands can use --dart-define-from-file instead of
# many scattered --dart-define flags.
# This file exists only during CI runner execution and must never be committed.
#
# Required:
#   SUPABASE_URL
#   SUPABASE_PUBLISHABLE_KEY
#   BACKEND_BASE_URL
#   APP_ENV
#
# Optional:
#   SENTRY_DSN
#   APP_RELEASE
#
# Usage:
#   bash scripts/create_runtime_env.sh
#   bash scripts/create_runtime_env.sh env/custom.json

set -euo pipefail

OUTPUT="${1:-env/ci.json}"

required_vars=(
  SUPABASE_URL
  SUPABASE_PUBLISHABLE_KEY
  BACKEND_BASE_URL
  APP_ENV
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "::error::Missing runtime configuration: $var"
    exit 1
  fi
done

if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq is required to create runtime configuration."
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

jq -n \
  --arg supabaseUrl "$SUPABASE_URL" \
  --arg supabasePublishableKey "$SUPABASE_PUBLISHABLE_KEY" \
  --arg backendBaseUrl "$BACKEND_BASE_URL" \
  --arg sentryDsn "${SENTRY_DSN:-}" \
  --arg appEnv "$APP_ENV" \
  --arg appRelease "${APP_RELEASE:-}" \
  '{
    SUPABASE_URL: $supabaseUrl,
    SUPABASE_PUBLISHABLE_KEY: $supabasePublishableKey,
    BACKEND_BASE_URL: $backendBaseUrl,
    SENTRY_DSN: $sentryDsn,
    APP_ENV: $appEnv,
    APP_RELEASE: $appRelease
  }' > "$OUTPUT"

echo "Runtime configuration created: $OUTPUT"
