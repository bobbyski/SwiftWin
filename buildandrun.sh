#!/usr/bin/env sh

# Builds the selected demo, then runs it.
#
# Usage:
#   sh ./buildandrun.sh           # builds and runs SwiftWinUIDemo
#   sh ./buildandrun.sh ui        # builds and runs SwiftWinUIDemo
#   sh ./buildandrun.sh legacy    # builds and runs SwiftWinLegacyDemo
#
# Platform note:
# SwiftPM places executables under .build/debug on macOS/Linux and under a
# target-triple folder such as .build/aarch64-unknown-windows-msvc/debug on
# Windows. This script checks both shapes so one command works in Unix-like
# shells on Windows, macOS, and Linux.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT_DIR"

DEMO=${1:-ui}

case "$DEMO" in
    ui|swiftwinui|SwiftWinUIDemo)
        PRODUCT="SwiftWinUIDemo"
        ;;
    legacy|swiftwinlegacy|SwiftWinLegacyDemo)
        PRODUCT="SwiftWinLegacyDemo"
        ;;
    *)
        echo "Unknown demo: $DEMO" >&2
        echo "Use: ./buildandrun.sh [ui|legacy]" >&2
        exit 64
        ;;
esac

swift build --product "$PRODUCT"

exec sh "$ROOT_DIR/run.sh" "$DEMO"
