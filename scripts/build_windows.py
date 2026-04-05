#!/usr/bin/env python3
"""Local Windows wheel build script for cyfaust.

Builds statically-linked wheels (default) or dynamically-linked wheels.

Static build (default):
  1. Setup faust (if needed)
  2. Build libsamplerate (if needed)
  3. Build libsndfile (if needed)
  4. Generate static sources
  5. Build wheel with STATIC=ON

Dynamic build (--dynamic):
  1. Setup faust (if needed)
  2. Build libsamplerate (if needed)
  3. Build libsndfile (if needed)
  4. Build wheel with STATIC=OFF
  5. Repair wheel with delvewheel (bundles faust.dll)

Usage:
    python scripts/build_windows.py              # static wheel (default)
    python scripts/build_windows.py --dynamic    # dynamic wheel with bundled faust.dll
    python scripts/build_windows.py --skip-deps  # skip dependency builds
    python scripts/build_windows.py --test       # build + install + test
    python scripts/build_windows.py --clean      # clean build artifacts first
"""

import argparse
import glob
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"
LIB_STATIC = LIB / "static"
SCRIPTS = ROOT / "scripts"
DIST = ROOT / "dist"

REQUIRED_STATIC_LIBS = {
    "libfaust.lib": "faust",
    "samplerate.lib": "samplerate",
    "sndfile.lib": "sndfile",
}

REQUIRED_DYNAMIC_LIBS = {
    "faust.dll": "faust",
    "faust.lib": "faust",
    "samplerate.lib": "samplerate",
    "sndfile.lib": "sndfile",
}


def run(cmd: list[str], env: dict | None = None, **kwargs) -> None:
    print(f"\n>>> {' '.join(cmd)}")
    merged_env = {**os.environ, **(env or {})}
    subprocess.run(cmd, check=True, env=merged_env, cwd=str(ROOT), **kwargs)


def check_deps(dynamic: bool = False) -> list[str]:
    missing = []
    if dynamic:
        for lib, dep_name in REQUIRED_DYNAMIC_LIBS.items():
            path = LIB / lib if lib in ("faust.dll", "faust.lib") else LIB_STATIC / lib
            if not path.exists():
                if dep_name not in missing:
                    missing.append(dep_name)
    else:
        for lib, dep_name in REQUIRED_STATIC_LIBS.items():
            if not (LIB_STATIC / lib).exists():
                missing.append(dep_name)
    return missing


def build_deps(force: bool = False, dynamic: bool = False) -> None:
    if force:
        deps = list(set(REQUIRED_DYNAMIC_LIBS.values() if dynamic
                        else REQUIRED_STATIC_LIBS.values()))
    else:
        deps = check_deps(dynamic)

    if not deps:
        print("All dependencies found.")
        return

    for dep in deps:
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
            shutil.rmtree(d, ignore_errors=True)


def build_static_wheel() -> None:
    print("\nBuilding static wheel (STATIC=ON)...")
    run(["uv", "build", "--wheel"], env={"CMAKE_ARGS": "-DSTATIC=ON"})
    _check_wheel()


def build_dynamic_wheel() -> None:
    print("\nBuilding dynamic wheel (STATIC=OFF)...")
    run(["uv", "build", "--wheel"], env={"CMAKE_ARGS": "-DSTATIC=OFF"})

    print("\nRepairing wheel with delvewheel (bundling faust.dll)...")
    wheels = list(DIST.glob("*.whl"))
    if not wheels:
        print("ERROR: No wheel found in dist/ to repair", file=sys.stderr)
        sys.exit(1)
    for whl in wheels:
        run(["uv", "run", "delvewheel", "repair",
             "--add-path", str(LIB), str(whl), "-w", str(DIST)])
        # delvewheel creates a repaired wheel alongside the original; remove the original
        repaired = [w for w in DIST.glob("*.whl") if w != whl]
        if repaired:
            whl.unlink()
    _check_wheel()


def _check_wheel() -> None:
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
    parser.add_argument("--dynamic", action="store_true",
                        help="Build dynamically-linked wheel with bundled faust.dll")
    parser.add_argument("--skip-deps", action="store_true",
                        help="Skip dependency builds (assumes libs exist)")
    parser.add_argument("--rebuild-deps", action="store_true",
                        help="Force rebuild all dependencies")
    parser.add_argument("--test", action="store_true",
                        help="Install and test the wheel after building")
    parser.add_argument("--clean", action="store_true",
                        help="Clean build artifacts before building")
    args = parser.parse_args()

    build_type = "dynamic" if args.dynamic else "static"
    print("=" * 60)
    print(f"cyfaust Windows Local Build ({build_type})")
    print("=" * 60)

    if args.clean:
        clean()

    if not args.skip_deps:
        build_deps(force=args.rebuild_deps, dynamic=args.dynamic)
    else:
        missing = check_deps(dynamic=args.dynamic)
        if missing:
            print(f"WARNING: Missing libs: {', '.join(missing)}")
            print("Run without --skip-deps to build them.")
            sys.exit(1)

    if not args.dynamic:
        generate_static()
        build_static_wheel()
    else:
        build_dynamic_wheel()

    if args.test:
        test_wheel()

    print("\n" + "=" * 60)
    print("Build complete!")
    print("=" * 60)


if __name__ == "__main__":
    main()
