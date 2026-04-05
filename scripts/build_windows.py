#!/usr/bin/env python3
"""Local Windows wheel build script for cyfaust.

Replicates the CI build-release workflow steps for Windows:
  1. Setup faust (if needed)
  2. Build libsamplerate (if needed)
  3. Build libsndfile (if needed)
  4. Generate static sources
  5. Build wheel with STATIC=ON

Usage:
    python scripts/build_windows.py            # full build
    python scripts/build_windows.py --skip-deps # skip dependency builds
    python scripts/build_windows.py --test      # build + install + test
    python scripts/build_windows.py --clean     # clean build artifacts first
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB_STATIC = ROOT / "lib" / "static"
SCRIPTS = ROOT / "scripts"
DIST = ROOT / "dist"

REQUIRED_LIBS = {
    "libfaust.lib": "faust",
    "samplerate.lib": "samplerate",
    "sndfile.lib": "sndfile",
}


def run(cmd: list[str], env: dict | None = None, **kwargs) -> None:
    print(f"\n>>> {' '.join(cmd)}")
    merged_env = {**os.environ, **(env or {})}
    subprocess.run(cmd, check=True, env=merged_env, cwd=str(ROOT), **kwargs)


def check_deps() -> list[str]:
    missing = []
    for lib, dep_name in REQUIRED_LIBS.items():
        if not (LIB_STATIC / lib).exists():
            missing.append(dep_name)
    return missing


def build_deps(force: bool = False) -> None:
    if force:
        missing = list(REQUIRED_LIBS.values())
    else:
        missing = check_deps()

    if not missing:
        print("All dependencies found in lib/static/")
        return

    for dep in missing:
        print(f"\nBuilding {dep}...")
        run([sys.executable, str(SCRIPTS / "manage.py"), "setup", f"--{dep}"])


def generate_static() -> None:
    print("\nGenerating static sources...")
    run([sys.executable, str(SCRIPTS / "generate_static.py")])


def clean() -> None:
    print("\nCleaning build artifacts...")
    for d in [ROOT / "build", ROOT / "_skbuild", DIST]:
        if d.exists():
            print(f"  Removing {d}")
            import shutil
            shutil.rmtree(d, ignore_errors=True)


def build_wheel() -> None:
    print("\nBuilding wheel (STATIC=ON)...")
    run(["uv", "build", "--wheel"], env={"CMAKE_ARGS": "-DSTATIC=ON"})

    wheels = list(DIST.glob("*.whl"))
    if wheels:
        print(f"\nWheel built successfully:")
        for w in wheels:
            print(f"  {w.name}")
    else:
        print("\nERROR: No wheel found in dist/", file=sys.stderr)
        sys.exit(1)


def test_wheel() -> None:
    wheels = sorted(DIST.glob("*.whl"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not wheels:
        print("ERROR: No wheel found in dist/ to test", file=sys.stderr)
        sys.exit(1)

    whl = wheels[0]
    print(f"\nInstalling {whl.name}...")
    run([sys.executable, "-m", "pip", "install", str(whl), "--force-reinstall"])

    print("\nRunning import test...")
    run([sys.executable, "-c", "import cyfaust; print('cyfaust imported successfully')"])
    run([
        sys.executable, "-c",
        "from cyfaust import get_version; print('libfaust version:', get_version())"
    ])

    print("\nRunning pytest...")
    test_files = [
        "tests/test_cyfaust_common.py",
        "tests/test_box_coverage.py",
        "tests/test_signal_coverage.py",
        "tests/test_new_methods.py",
    ]
    existing = [t for t in test_files if (ROOT / t).exists()]
    if existing:
        run([sys.executable, "-m", "pytest"] + existing + ["-v", "-o", "pythonpath="])
    else:
        print("  No test files found, skipping.")


def main():
    if sys.platform != "win32":
        print("ERROR: This script is for Windows only.", file=sys.stderr)
        sys.exit(1)

    parser = argparse.ArgumentParser(description="Build cyfaust wheel on Windows")
    parser.add_argument("--skip-deps", action="store_true",
                        help="Skip dependency builds (assumes libs exist)")
    parser.add_argument("--rebuild-deps", action="store_true",
                        help="Force rebuild all dependencies")
    parser.add_argument("--test", action="store_true",
                        help="Install and test the wheel after building")
    parser.add_argument("--clean", action="store_true",
                        help="Clean build artifacts before building")
    args = parser.parse_args()

    print("=" * 60)
    print("cyfaust Windows Local Build")
    print("=" * 60)

    if args.clean:
        clean()

    if not args.skip_deps:
        build_deps(force=args.rebuild_deps)
    else:
        missing = check_deps()
        if missing:
            print(f"WARNING: Missing libs: {', '.join(missing)}")
            print("Run without --skip-deps to build them.")
            sys.exit(1)

    generate_static()
    build_wheel()

    if args.test:
        test_wheel()

    print("\n" + "=" * 60)
    print("Build complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
