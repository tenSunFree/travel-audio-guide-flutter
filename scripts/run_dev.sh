#!/bin/bash
# scripts/run_dev.sh
#
# Development mode startup script (macOS / Linux)
# Usage: bash scripts/run_dev.sh [device_id]
# # Example:
# bash scripts/run_dev.sh # Automatically select device
# bash scripts/run_dev.sh emulator-5554

set -e
cd "$(dirname "$0")/.."
source "scripts/_fvm.sh"

ENV_FILE="env/dev.json"

# Confirm that env/dev.json exists
if [ ! -f "$ENV_FILE" ]; then
  echo ""
  echo "找不到 $ENV_FILE"
  echo ""
  echo "請照以下步驟建立："
  echo "  1. cp env/example.json env/dev.json"
  echo "  2. 用編輯器打開 env/dev.json"
  echo "  3. 填入 SUPABASE_URL、SUPABASE_PUBLISHABLE_KEY、BACKEND_BASE_URL 等環境設定"
  echo ""
  exit 1
fi

DEVICE=${1:-""}

echo ""
echo "啟動開發模式..."
echo "    flavor   : staging"
echo "    env file : $ENV_FILE"
if [ -n "$DEVICE" ]; then
  echo "    device   : $DEVICE"
fi
echo ""

if [ -n "$DEVICE" ]; then
  $FLUTTER_CMD run \
    --flavor staging \
    -t lib/main_staging.dart \
    --dart-define-from-file="$ENV_FILE" \
    --device-id="$DEVICE"
else
  $FLUTTER_CMD run \
    --flavor staging \
    -t lib/main_staging.dart \
    --dart-define-from-file="$ENV_FILE"
fi