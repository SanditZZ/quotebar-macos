#!/usr/bin/env bash
#
# package-release.sh — run the release pipeline's build and packaging steps
# locally, so the artifacts can be installed and tested before the workflow is
# ever allowed near main.
#
# This deliberately mirrors .github/workflows/release.yml step for step,
# including the awk parsing and the release-notes generation, so a failure here
# is a failure there. It stops short of the two things that cannot be rehearsed
# locally: notarization and `gh release create`.
#
# Output: build/dist/ (gitignored, alongside the build products)
#
# Usage:
#   scripts/package-release.sh                # build + package
#   scripts/package-release.sh --skip-build   # repackage the existing build

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
REPO_ROOT="$PWD"

DIST="${REPO_ROOT}/build/dist"
BUILD_DIR="${REPO_ROOT}/build"
APP="${BUILD_DIR}/Build/Products/Release/QuoteBar.app"
SKIP_BUILD=false
[ "${1:-}" = "--skip-build" ] && SKIP_BUILD=true

if [ -t 1 ]; then
    BOLD=$'\033[1m'; GREEN=$'\033[32m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
    BOLD=""; GREEN=""; RED=""; RESET=""
fi
info() { printf '%s==>%s %s\n' "${BOLD}" "${RESET}" "$1"; }
pass() { printf '%s✓%s %s\n' "${GREEN}" "${RESET}" "$1"; }
fail() { printf '%s✗%s %s\n' "${RED}" "${RESET}" "$1" >&2; }
trap 'fail "Release packaging FAILED"' ERR

# ---------------------------------------------------------------------------
# 1. Resolve version — identical awk to the workflow's "Resolve version" step
# ---------------------------------------------------------------------------
info "Resolving version from build settings"

VERSION="$(xcodebuild -project QuoteBar.xcodeproj -target QuoteBar \
  -configuration Release -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/ MARKETING_VERSION =/ {print $2; exit}' | tr -d '[:space:]')"

BUILD="$(xcodebuild -project QuoteBar.xcodeproj -target QuoteBar \
  -configuration Release -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/ CURRENT_PROJECT_VERSION =/ {print $2; exit}' | tr -d '[:space:]')"

if [ -z "${VERSION}" ]; then
    fail "Could not read MARKETING_VERSION from the project — the workflow would fail here too"
    exit 1
fi
pass "MARKETING_VERSION = ${VERSION}, CURRENT_PROJECT_VERSION = ${BUILD}"

# ---------------------------------------------------------------------------
# 2. Build (Release)
# ---------------------------------------------------------------------------
if [ "${SKIP_BUILD}" = true ] && [ -d "${APP}" ]; then
    info "Skipping build, reusing ${APP}"
else
    info "Building Release (warnings treated as errors)"
    set -o pipefail
    xcodebuild build \
        -project QuoteBar.xcodeproj \
        -scheme QuoteBar \
        -configuration Release \
        -derivedDataPath build \
        CODE_SIGNING_ALLOWED=NO \
        SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
        | { command -v xcpretty >/dev/null 2>&1 && xcpretty || cat; }
    pass "Build clean"
fi

[ -d "${APP}" ] || { fail "No app bundle at ${APP}"; exit 1; }

# ---------------------------------------------------------------------------
# 3. Ad-hoc sign — the unsigned path the workflow takes with no certificate
#
# --deep is required here and not merely convenient: the bundle now carries
# Sparkle.framework and its XPC services, and an unsigned nested framework
# makes the whole app fail to launch under the hardened runtime.
# ---------------------------------------------------------------------------
info "Signing ad-hoc"
codesign --force --deep \
    --entitlements QuoteBar/QuoteBar.entitlements \
    --sign - "${APP}"
codesign --verify --deep --strict --verbose=2 "${APP}"
pass "Ad-hoc signature valid"

# ---------------------------------------------------------------------------
# 4. Prove it can actually load Sparkle
#
# A release that ships a bundle which cannot find its own framework is the one
# failure the test suite is structurally unable to catch. Checked here, before
# packaging, so a broken build never reaches a DMG.
# ---------------------------------------------------------------------------
info "Checking embedded frameworks"
scripts/check-embedded-frameworks.sh "${APP}"

# ---------------------------------------------------------------------------
# 5. Package — ditto for the zip, hdiutil for the DMG
# ---------------------------------------------------------------------------
info "Packaging zip and DMG"
STAGING="${BUILD_DIR}/dmg-staging"
rm -rf "${DIST}" "${STAGING}"
mkdir -p "${DIST}" "${STAGING}"

ditto -c -k --keepParent "${APP}" "${DIST}/QuoteBar-${VERSION}.zip"

cp -pR "${APP}" "${STAGING}/"
ln -s /Applications "${STAGING}/Applications"
hdiutil create \
    -volname "QuoteBar" \
    -srcfolder "${STAGING}" \
    -ov -format UDZO \
    "${DIST}/QuoteBar-${VERSION}.dmg"
rm -rf "${STAGING}"

( cd "${DIST}" && shasum -a 256 ./*.zip ./*.dmg > "checksums-${VERSION}.txt" )
pass "Artifacts written"

# ---------------------------------------------------------------------------
# 6. Release notes — identical awk to the workflow's "Build release notes"
# ---------------------------------------------------------------------------
info "Generating release notes"
NOTES_BODY="${DIST}/notes-body.md"

if awk -v v="## [${VERSION}]" 'index($0, v) == 1 {found=1} END {exit !found}' CHANGELOG.md; then
    awk -v v="## [${VERSION}]" '
      index($0, v) == 1 {capture=1; next}
      capture && /^## \[/ {exit}
      capture && /^\[[^]]+\]: / {exit}
      capture {print}
    ' CHANGELOG.md > "${NOTES_BODY}"
    pass "Extracted the [${VERSION}] section from CHANGELOG.md ($(wc -l < "${NOTES_BODY}" | tr -d ' ') lines)"
else
    echo "See the commit history for what changed in this version." > "${NOTES_BODY}"
    fail "No [${VERSION}] section in CHANGELOG.md — notes would fall back to the commit-history line"
fi

{
    echo "## Install"
    echo
    echo "Download \`QuoteBar-${VERSION}.dmg\`, open it, and drag **QuoteBar** to Applications."
    echo
    echo "> [!IMPORTANT]"
    echo "> This build is **not notarized by Apple**, so macOS will refuse to open it the first time."
    echo "> After moving it to Applications, run this once:"
    echo ">"
    echo "> \`\`\`bash"
    echo "> xattr -dr com.apple.quarantine /Applications/QuoteBar.app"
    echo "> \`\`\`"
    echo ">"
    echo "> Alternatively open it once, then go to **System Settings → Privacy & Security** and click **Open Anyway**."
    echo "> On macOS 15 and later, Control-clicking the app no longer works as a bypass."
    echo
    echo "Run QuoteBar from **Applications**, not from the disk image or Downloads — it updates itself in place, so a copy left elsewhere never picks up new versions."
    echo
    echo "Requires macOS 14 (Sonoma) or later. The app lives in the menu bar and has no Dock icon."
    echo
    echo "## What changed"
    echo
    cat "${NOTES_BODY}"
    echo
    echo "## Verify your download"
    echo
    echo "\`\`\`bash"
    echo "shasum -a 256 -c checksums-${VERSION}.txt"
    echo "\`\`\`"
} > "${DIST}/release-notes.md"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\n%s%s✓ Release artifacts ready%s\n\n' "${BOLD}" "${GREEN}" "${RESET}"
ls -lh "${DIST}"
printf '\nChecksums:\n'
cat "${DIST}/checksums-${VERSION}.txt"
printf '\nInstall locally:\n'
printf '  open %s/QuoteBar-%s.dmg\n' "${DIST}" "${VERSION}"
printf '  # drag to Applications, then:\n'
printf '  xattr -dr com.apple.quarantine /Applications/QuoteBar.app\n'
printf '  open /Applications/QuoteBar.app\n'
