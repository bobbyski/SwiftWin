#!/usr/bin/env sh

# Runs a previously built demo executable.
#
# Usage:
#   sh ./run.sh           # runs SwiftWinUIDemo
#   sh ./run.sh ui        # runs SwiftWinUIDemo
#   sh ./run.sh legacy    # runs SwiftWinLegacyDemo

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
        echo "Use: ./run.sh [ui|legacy]" >&2
        exit 64
        ;;
esac

find_executable() {
    if [ -x "$ROOT_DIR/.build/debug/$PRODUCT" ]; then
        printf '%s\n' "$ROOT_DIR/.build/debug/$PRODUCT"
        return 0
    fi

    if [ -x "$ROOT_DIR/.build/debug/$PRODUCT.exe" ]; then
        printf '%s\n' "$ROOT_DIR/.build/debug/$PRODUCT.exe"
        return 0
    fi

    for candidate in "$ROOT_DIR"/.build/*/debug/"$PRODUCT" "$ROOT_DIR"/.build/*/debug/"$PRODUCT.exe"; do
        if [ -x "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

if EXECUTABLE=$(find_executable); then
    exec "$EXECUTABLE"
fi

echo "Could not find a built executable for $PRODUCT." >&2
echo "Run ./buildandrun.sh $DEMO first." >&2
exit 66
