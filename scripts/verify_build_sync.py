#!/usr/bin/env python3
"""Build Variant Synchronization Verification Script

Verifies that the dynamic and static build variants stay synchronized:

1. The shared .pxd header files are byte-identical between variants.
2. The runtime DSP classes of the two backends -- the interpreter's
   `InterpreterDsp` and the LLVM JIT's `LlvmDsp` -- expose the same public
   method set (a parity check), so a method added to one backend cannot
   silently miss the other.

`InterpreterDsp` lives in the generated static source and is copied verbatim
from `src/cyfaust/interp.pyx` by `scripts/generate_static.py`, so the check
parses that source of truth directly. `LlvmDsp` in
`src/static/cyfaust/backend_llvm.pxi` is hand-maintained and is NOT
regenerated, which is exactly why it can drift.
"""

import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Files to check for synchronization
FILES_TO_CHECK = [
    "faust_gui.pxd",
    "faust_box.pxd",
    "faust_signal.pxd",
]

# ---------------------------------------------------------------------------
# Runtime DSP class parity
# ---------------------------------------------------------------------------

# (source file, class name) of each backend's runtime DSP instance class.
INTERP_DSP = (Path("src/cyfaust/interp.pyx"), "InterpreterDsp")
LLVM_DSP = (Path("src/static/cyfaust/backend_llvm.pxi"), "LlvmDsp")

# Public methods present on InterpreterDsp but intentionally absent from
# LlvmDsp, each with the reason it cannot (yet) be ported. These are excused
# from the parity check; every OTHER difference is treated as accidental drift.
# When one of these is genuinely ported to LlvmDsp, drop it from this map (the
# check flags stale entries so the map cannot rot).
INTERP_ONLY_ALLOWED = {
    "control": "llvm_dsp binding has no control() (needs -ec); not in faust_llvm.pxd",
    "frame": "llvm_dsp binding has no frame() (needs -os); not in faust_llvm.pxd",
    "compute_timestamped": "llvm_dsp binding has no timestamped compute(); not in faust_llvm.pxd",
}

# Public methods present on LlvmDsp but intentionally absent from
# InterpreterDsp (currently none). Same stale-entry hygiene applies.
LLVM_ONLY_ALLOWED: dict[str, str] = {}


def public_methods(path: Path, classname: str) -> set[str]:
    """Return the public `def` method names of `classname` in a .pyx/.pxi file.

    Public means a method defined at class-body indent (4 spaces) whose name
    does not start with an underscore, so dunders (`__cinit__`) and cdef helper
    conventions (`_resolve`) are excluded. cdef methods are also excluded since
    they are not part of the Python-visible API.
    """
    lines = path.read_text().splitlines()
    start = None
    for i, ln in enumerate(lines):
        if re.match(rf"^cdef class {re.escape(classname)}\b", ln):
            start = i
            break
    if start is None:
        raise SystemExit(f"ERROR: class {classname} not found in {path}")

    methods = set()
    for ln in lines[start + 1:]:
        # A non-indented, non-comment line ends the class body.
        if re.match(r"^\S", ln) and not ln.startswith("#"):
            break
        m = re.match(r"^    def ([A-Za-z_]\w*)\(", ln)
        if m and not m.group(1).startswith("_"):
            methods.add(m.group(1))
    return methods


def check_class_parity() -> int:
    """Assert InterpreterDsp and LlvmDsp expose the same public methods.

    Returns the number of parity errors found.
    """
    interp_path, interp_name = INTERP_DSP
    llvm_path, llvm_name = LLVM_DSP
    interp = public_methods(PROJECT_ROOT / interp_path, interp_name)
    llvm = public_methods(PROJECT_ROOT / llvm_path, llvm_name)

    interp_only = interp - llvm
    llvm_only = llvm - interp

    print(f"Checking runtime DSP class parity: {interp_name} vs {llvm_name}")

    errors = 0

    unexpected_interp_only = sorted(interp_only - set(INTERP_ONLY_ALLOWED))
    if unexpected_interp_only:
        errors += 1
        for name in unexpected_interp_only:
            print(
                f"  ERROR: {interp_name}.{name}() has no {llvm_name} counterpart.\n"
                f"         Port it into src/static/cyfaust/backend_llvm.pxi, or add "
                f"it to\n         INTERP_ONLY_ALLOWED with a reason if the gap is "
                f"intentional."
            )

    unexpected_llvm_only = sorted(llvm_only - set(LLVM_ONLY_ALLOWED))
    if unexpected_llvm_only:
        errors += 1
        for name in unexpected_llvm_only:
            print(
                f"  ERROR: {llvm_name}.{name}() has no {interp_name} counterpart.\n"
                f"         Port it into src/cyfaust/interp.pyx, or add it to\n"
                f"         LLVM_ONLY_ALLOWED with a reason if the gap is intentional."
            )

    # Stale-allowlist hygiene: an allowed difference that no longer exists means
    # the method reached parity (or was renamed); the entry must be removed.
    stale_interp = sorted(set(INTERP_ONLY_ALLOWED) - interp_only)
    for name in stale_interp:
        errors += 1
        print(
            f"  ERROR: INTERP_ONLY_ALLOWED lists {name!r}, but it is no longer "
            f"{interp_name}-only.\n         Remove the stale allowlist entry."
        )
    stale_llvm = sorted(set(LLVM_ONLY_ALLOWED) - llvm_only)
    for name in stale_llvm:
        errors += 1
        print(
            f"  ERROR: LLVM_ONLY_ALLOWED lists {name!r}, but it is no longer "
            f"{llvm_name}-only.\n         Remove the stale allowlist entry."
        )

    if errors == 0:
        shared = len(interp & llvm)
        excused = len(INTERP_ONLY_ALLOWED) + len(LLVM_ONLY_ALLOWED)
        print(
            f"  OK: {shared} shared public methods; "
            f"{excused} documented intentional difference(s)"
        )
    print()
    return errors


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

    pxd_errors = errors
    errors += check_class_parity()

    if errors == 0:
        print("SUCCESS: All build variants are synchronized!")
        return 0

    print(f"FAILURE: {errors} synchronization error(s)")
    if pxd_errors:
        print()
        print("To fix .pxd drift, run:")
        for name in FILES_TO_CHECK:
            print(f"  cp src/cyfaust/{name} src/static/cyfaust/{name}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
