#!/usr/bin/env bash
#
# check-embedded-frameworks.sh — prove the app can actually load what it links.
#
# This exists because of a bug that shipped past a completely green test suite.
# Adding Sparkle embedded Sparkle.framework into Contents/Frameworks, but this
# project's hand-written project.pbxproj had never needed
# LD_RUNPATH_SEARCH_PATHS — it had no frameworks until then. The result built
# without a warning, passed all 145 tests, and died instantly on launch:
#
#   dyld: Library not loaded: @rpath/Sparkle.framework/Versions/B/Sparkle
#
# Unit tests cannot catch this. They run inside a test host that resolves
# frameworks differently, so the suite is green either way. The only way to
# know is to inspect the built binary, which is what this does.
#
# Checks, in order of how badly each one bites:
#   1. Every @rpath-relative load command resolves to a real file.
#   2. The bundle declares the LC_RPATH that makes that possible.
#   3. Every framework in Contents/Frameworks is actually loadable.
#
# Usage:
#   scripts/check-embedded-frameworks.sh <path-to-.app>
#
# Exit code is 0 only when the app would launch.

set -euo pipefail

APP="${1:-}"

if [ -z "${APP}" ]; then
    echo "usage: $0 <path-to-.app>" >&2
    exit 2
fi

if [ ! -d "${APP}" ]; then
    echo "✗ No app bundle at ${APP}" >&2
    exit 1
fi

if [ -t 1 ]; then
    BOLD=$'\033[1m'; GREEN=$'\033[32m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
    BOLD=""; GREEN=""; RED=""; RESET=""
fi
info() { printf '%s==>%s %s\n' "${BOLD}" "${RESET}" "$1"; }
pass() { printf '%s✓%s %s\n' "${GREEN}" "${RESET}" "$1"; }
fail() { printf '%s✗%s %s\n' "${RED}" "${RESET}" "$1" >&2; }

# The executable is named by Info.plist, not by the bundle's filename — a
# bundle can be renamed or staged under a different name, and guessing from the
# directory would then fail for a reason that has nothing to do with linking.
NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' \
    "${APP}/Contents/Info.plist" 2>/dev/null || basename "${APP}" .app)"
BINARY="${APP}/Contents/MacOS/${NAME}"
FRAMEWORKS="${APP}/Contents/Frameworks"

[ -f "${BINARY}" ] || { fail "No executable at ${BINARY}"; exit 1; }

FAILURES=0

# ---------------------------------------------------------------------------
# 1. Every @rpath load command has to resolve against a declared runpath
#
# This mirrors what dyld actually does: for each @rpath/X dependency it tries
# every LC_RPATH entry in turn, and the library loads if any one of them hits.
# Checking a single hardcoded directory instead would report a false failure
# for QuoteBar.debug.dylib, which Xcode puts in Contents/MacOS and reaches via
# a plain @executable_path runpath.
# ---------------------------------------------------------------------------
info "Checking @rpath dependencies of ${NAME}"

# otool -L lists the install names this binary will ask dyld for. The ones
# starting @rpath are the embedded ones; system libraries are absolute paths
# and dyld always finds them.
#
# Deduplicated: on a universal binary otool walks every architecture, so each
# dependency and each runpath would otherwise be reported once per slice.
RPATH_DEPS="$(otool -L "${BINARY}" | awk '$1 ~ /^@rpath\// {print $1}' | sort -u)"

# Each LC_RPATH command is followed by a `path <value> (offset …)` line.
RPATHS="$(otool -l "${BINARY}" | awk '/LC_RPATH/ {found=1; next} found && /^ *path / {print $2; found=0}' | sort -u)"

# Resolve a runpath's variables to a real directory. For the main executable
# @loader_path and @executable_path are both Contents/MacOS.
expand_runpath() {
    local runpath="$1"
    runpath="${runpath//@executable_path/${APP}/Contents/MacOS}"
    runpath="${runpath//@loader_path/${APP}/Contents/MacOS}"
    printf '%s' "${runpath}"
}

if [ -z "${RPATH_DEPS}" ]; then
    pass "No @rpath dependencies — nothing to resolve"
else
    while IFS= read -r dep; do
        RELATIVE="${dep#@rpath/}"
        RESOLVED=""

        while IFS= read -r runpath; do
            [ -n "${runpath}" ] || continue
            CANDIDATE="$(expand_runpath "${runpath}")/${RELATIVE}"
            if [ -f "${CANDIDATE}" ]; then
                RESOLVED="${CANDIDATE}"
                break
            fi
        done <<< "${RPATHS}"

        if [ -n "${RESOLVED}" ]; then
            pass "${dep}"
        else
            fail "${dep} does not resolve against any declared runpath"
            fail "The app links something it cannot find, and will crash on launch."
            fail "Fix: add LD_RUNPATH_SEARCH_PATHS to the target's build settings."
            if [ -n "${RPATHS}" ]; then
                printf '  declared runpaths: %s\n' "$(echo "${RPATHS}" | tr '\n' ' ')" >&2
            else
                printf '  the binary declares NO runpaths at all\n' >&2
            fi
            FAILURES=$((FAILURES + 1))
        fi
    done <<< "${RPATH_DEPS}"
fi

# ---------------------------------------------------------------------------
# 2. The runpath that makes an embedded framework reachable
#
# Checked separately from resolution above so the diagnostic names the actual
# cause. A bundle can carry frameworks whose load commands happen to resolve
# some other way today and still be one build-setting change from breaking.
# ---------------------------------------------------------------------------
if compgen -G "${FRAMEWORKS}/*.framework" > /dev/null 2>&1; then
    info "Checking LC_RPATH"

    if printf '%s\n' "${RPATHS}" | grep -qx '@executable_path/../Frameworks'; then
        pass "@executable_path/../Frameworks is on the runpath"
    else
        fail "@executable_path/../Frameworks is MISSING from the runpath"
        fail "The bundle embeds frameworks the executable cannot reach."
        fail "Fix: add LD_RUNPATH_SEARCH_PATHS to the target's build settings."
        FAILURES=$((FAILURES + 1))
    fi
fi

# ---------------------------------------------------------------------------
# 3. Every embedded framework should be a real, loadable Mach-O
# ---------------------------------------------------------------------------
if [ -d "${FRAMEWORKS}" ]; then
    info "Checking embedded frameworks"

    for framework in "${FRAMEWORKS}"/*.framework; do
        [ -e "${framework}" ] || continue
        FW_NAME="$(basename "${framework}" .framework)"

        # A framework's binary is reached through the Versions/Current symlink;
        # resolve it rather than guessing a version letter.
        FW_BINARY="${framework}/Versions/Current/${FW_NAME}"
        [ -f "${FW_BINARY}" ] || FW_BINARY="${framework}/${FW_NAME}"

        if [ ! -f "${FW_BINARY}" ]; then
            fail "${FW_NAME}.framework has no binary"
            FAILURES=$((FAILURES + 1))
            continue
        fi

        if file "${FW_BINARY}" | grep -q 'Mach-O'; then
            pass "${FW_NAME}.framework"
        else
            fail "${FW_NAME}.framework binary is not Mach-O"
            FAILURES=$((FAILURES + 1))
        fi
    done
fi

# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------
if [ "${FAILURES}" -ne 0 ]; then
    printf '\n%s%s✗ %s would not launch (%d problem(s))%s\n' \
        "${BOLD}" "${RED}" "${NAME}" "${FAILURES}" "${RESET}" >&2
    exit 1
fi

printf '\n%s%s✓ %s can load every framework it links%s\n' \
    "${BOLD}" "${GREEN}" "${NAME}" "${RESET}"
