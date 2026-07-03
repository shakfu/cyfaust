#!/usr/bin/env python3
"""Build Variant Synchronization Verification Script

Verifies that the dynamic and static build variants have synchronized
.pxd header files to prevent API divergence.
"""

import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Files to check for synchronization
FILES_TO_CHECK = [
    "faust_gui.pxd",
    "faust_box.pxd",
    "faust_signal.pxd",
]


def main() -> int:
    print("Verifying build variant synchronization...")
    print(f"Project root: {PROJECT_ROOT}")
    print()

    errors = 0

    for name in FILES_TO_CHECK:
        dynamic = PROJECT_ROOT / "src" / "cyfaust" / name
        static = PROJECT_ROOT / "src" / "static" / "cyfaust" / name

        print(f"Checking: {name}")

        if not dynamic.is_file():
            print(f"  ERROR: Dynamic build file not found: {dynamic}")
            errors += 1
            print()
            continue

        if not static.is_file():
            print(f"  ERROR: Static build file not found: {static}")
            errors += 1
            print()
            continue

        if dynamic.read_bytes() != static.read_bytes():
            print("  ERROR: Files differ!")
            print(f"  Run: diff {dynamic} {static}")
            errors += 1
        else:
            print("  OK: Files are synchronized")
        print()

    if errors == 0:
        print("SUCCESS: All files are synchronized!")
        return 0

    print(f"FAILURE: {errors} file(s) are not synchronized")
    print()
    print("To fix, run:")
    for name in FILES_TO_CHECK:
        print(f"  cp src/cyfaust/{name} src/static/cyfaust/{name}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
