#!/bin/bash
# Build Variant Synchronization Verification Script
#
# This script verifies that the dynamic and static build variants
# have synchronized .pxd header files to prevent API divergence.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Verifying build variant synchronization..."
echo "Project root: $PROJECT_ROOT"
echo

# Files to check for synchronization
FILES_TO_CHECK=(
    "faust_gui.pxd"
    "faust_box.pxd"
    "faust_signal.pxd"
)

ERRORS=0

for file in "${FILES_TO_CHECK[@]}"; do
    DYNAMIC="$PROJECT_ROOT/src/cyfaust/$file"
    STATIC="$PROJECT_ROOT/src/static/cyfaust/$file"

    echo "Checking: $file"

    if [ ! -f "$DYNAMIC" ]; then
        echo "  ERROR: Dynamic build file not found: $DYNAMIC"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    if [ ! -f "$STATIC" ]; then
        echo "  ERROR: Static build file not found: $STATIC"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    if ! diff -q "$DYNAMIC" "$STATIC" > /dev/null 2>&1; then
        echo "  ERROR: Files differ!"
        echo "  Run: diff $DYNAMIC $STATIC"
        echo
        ERRORS=$((ERRORS + 1))
    else
        echo "  OK: Files are synchronized"
    fi
    echo
done

if [ $ERRORS -eq 0 ]; then
    echo "SUCCESS: All files are synchronized!"
    exit 0
else
    echo "FAILURE: $ERRORS file(s) are not synchronized"
    echo
    echo "To fix, run:"
    for file in "${FILES_TO_CHECK[@]}"; do
        echo "  cp src/cyfaust/$file src/static/cyfaust/$file"
    done
    exit 1
fi
