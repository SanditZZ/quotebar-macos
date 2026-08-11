#!/usr/bin/env bash
#
# refresh-icon-cache.sh — make macOS notice a changed app icon.
#
# macOS caches an app's icon against its bundle in the Launch Services
# database. A development build keeps the same bundle path across rebuilds, so
# once a stale icon is cached — most commonly the placeholder grid recorded
# before the icon set existed — Finder, the Dock and Spotlight keep showing it
# no matter how many times the app is rebuilt.
#
# Ported from idle-tapper-macos's script of the same name.
#
# Usage:
#   scripts/refresh-icon-cache.sh              # the Debug build in DerivedData
#   scripts/refresh-icon-cache.sh /path/to/App.app

set -euo pipefail

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

APP_PATH="${1:-}"

if [ -z "${APP_PATH}" ]; then
    APP_PATH="$(find "${HOME}/Library/Developer/Xcode/DerivedData" \
        -maxdepth 5 -name "QuoteBar.app" -path "*/Build/Products/Debug/*" \
        2>/dev/null | head -1)"
fi

if [ -z "${APP_PATH}" ] || [ ! -d "${APP_PATH}" ]; then
    echo "No app bundle found. Build first, or pass the path explicitly." >&2
    exit 1
fi

if [ ! -x "${LSREGISTER}" ]; then
    echo "lsregister not found at the expected path — macOS may have moved it." >&2
    exit 1
fi

echo "==> Refreshing icon cache for ${APP_PATH}"

touch "${APP_PATH}"
"${LSREGISTER}" -f "${APP_PATH}"
killall Dock 2>/dev/null || true

echo "==> Done. Finder, the Dock and Spotlight should now show the current icon."
echo "    If Spotlight still disagrees, give its index a few seconds to catch up."
