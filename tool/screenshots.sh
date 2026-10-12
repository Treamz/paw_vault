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
#   tool/screenshots.sh duo       # just the iPhone Duo set
#
# Apple required sizes (App Store Connect, 2024+):
#   iPhone 6.9"  -> iPhone 16 Pro Max  (1320 x 2868)
#   iPad 13"     -> iPad Pro 13-inch (M4)  (2064 x 2752)  [needed while the app
#                   targets iPad; TARGETED_DEVICE_FAMILY = 1,2]
#   iPhone Duo   -> iPhone Duo  (2853 x 2007 unfolded)
#
# The Duo sizes are not on Apple's published specifications page. They come
# from the live catalog, which is the only place that carries them and which
# Apple asks integrations to read rather than hard-code:
#   GET /v1/appAssetLibraryRefData?fields[appAssetLibraryRefData]=imageSpecs
# The IPHONE_DUO_PROFILE group accepts exactly four, two per fold state:
#   1398x2034 and 2034x1398 folded, 2007x2853 and 2853x2007 unfolded.
# A simulator left unfolded captures at 2853x2007, which is one of them, so
# the run needs no resizing afterwards. Re-read the catalog rather than
# trusting this comment if an upload is ever rejected.
set -euo pipefail

cd "$(dirname "$0")/.."

DRIVER="test_driver/screenshots.dart"
BUNDLE_ID="com.treamz.pawVault"
TARGET="integration_test/screenshots_test.dart"

# label|simulator name
DEVICES_IPHONE=("iphone_6_9|iPhone 16 Pro Max")
DEVICES_IPAD=("ipad_13|iPad Pro 13-inch (M4)")
DEVICES_DUO=("iphone_duo|iPhone Duo")

case "${1:-all}" in
  iphone) DEVICES=("${DEVICES_IPHONE[@]}") ;;
  ipad)   DEVICES=("${DEVICES_IPAD[@]}") ;;
  duo)    DEVICES=("${DEVICES_DUO[@]}") ;;
  all)    DEVICES=("${DEVICES_IPHONE[@]}" "${DEVICES_IPAD[@]}" "${DEVICES_DUO[@]}") ;;
  *) echo "Unknown argument: $1 (use: all | iphone | ipad | duo)"; exit 1 ;;
esac

for entry in "${DEVICES[@]}"; do
  label="${entry%%|*}"
  name="${entry##*|}"

  # Every simulator of this name, not just the first. simctl reports
  # isAvailable=true for devices whose runtime data has gone, and booting one
  # answers "Unable to boot deleted device" -- so the only way to know a
  # candidate is usable is to boot it. `boot` also returns before the device
  # is up, and `flutter drive` then fails with "No supported devices found
  # with name or id matching ...", which is why bootstatus waits here.
  udid=""
  while read -r candidate; do
    [ -n "$candidate" ] || continue
    if xcrun simctl bootstatus "$candidate" -b >/dev/null 2>&1; then
      udid="$candidate"
      break
    fi
    echo "   skipping $candidate — it will not boot"
  done <<EOF
$(xcrun simctl list devices available | grep -F "$name (" | grep -oE '[0-9A-F-]{36}')
EOF

  if [ -z "$udid" ]; then
    echo "⚠️  No bootable simulator named: $name — skipping."
    echo "    Create it in Xcode > Settings > Components, or list with: xcrun simctl list devices"
    continue
  fi

  echo "📱 $name ($label) — $udid"

  # Clear the app before capturing. A system permission alert raised by an
  # earlier run outlives it, sits over the app, and makes every capture the
  # same blank grey frame — which is what produced blank App Store
  # screenshots for a long time. Uninstalling takes any pending alert with
  # it. The screenshot suite itself never asks for permission (it uses a
  # silent notification scheduler), so nothing raises a new one.
  xcrun simctl terminate "$udid" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl uninstall "$udid" "$BUNDLE_ID" 2>/dev/null || true

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
