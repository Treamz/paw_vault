#!/usr/bin/env bash
#
# Captures App Store screenshots by running the integration_test screenshot
# suite on each required simulator size. Output goes to:
#   build/screenshots/<label>/NN_screen.png
#
# Usage:
#   tool/screenshots.sh           # all device sizes below
#   tool/screenshots.sh iphone    # just the iPhone 6.9" set
#   tool/screenshots.sh ipad      # just the iPad 13" set
#
# Apple required sizes (App Store Connect, 2024+):
#   iPhone 6.9"  -> iPhone 16 Pro Max  (1320 x 2868)
#   iPad 13"     -> iPad Pro 13-inch (M4)  (2064 x 2752)  [needed while the app
#                   targets iPad; TARGETED_DEVICE_FAMILY = 1,2]
set -euo pipefail

cd "$(dirname "$0")/.."

DRIVER="test_driver/screenshots.dart"
TARGET="integration_test/screenshots_test.dart"

# label|simulator name
DEVICES_IPHONE=("iphone_6_9|iPhone 16 Pro Max")
DEVICES_IPAD=("ipad_13|iPad Pro 13-inch (M4)")

case "${1:-all}" in
  iphone) DEVICES=("${DEVICES_IPHONE[@]}") ;;
  ipad)   DEVICES=("${DEVICES_IPAD[@]}") ;;
  all)    DEVICES=("${DEVICES_IPHONE[@]}" "${DEVICES_IPAD[@]}") ;;
  *) echo "Unknown argument: $1 (use: all | iphone | ipad)"; exit 1 ;;
esac

for entry in "${DEVICES[@]}"; do
  label="${entry%%|*}"
  name="${entry##*|}"

  udid="$(xcrun simctl list devices available | grep -F "$name (" | head -1 | grep -oE '[0-9A-F-]{36}' || true)"
  if [ -z "$udid" ]; then
    echo "⚠️  Simulator not found: $name — skipping."
    echo "    Create it in Xcode > Settings > Components, or list with: xcrun simctl list devices"
    continue
  fi

  echo "📱 $name ($label) — $udid"
  xcrun simctl boot "$udid" 2>/dev/null || true

  out="build/screenshots/$label"
  rm -rf "$out"
  SCREENSHOT_DIR="$out" flutter drive \
    --driver="$DRIVER" \
    --target="$TARGET" \
    -d "$udid"

  echo "✅ $label -> $out"
done

echo
echo "Done. Screenshots in build/screenshots/<size>/."
