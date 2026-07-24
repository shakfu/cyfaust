"""Tests for scripts/verify_build_sync.py, the build-variant sync guard.

The guard keeps the two runtime backends from drifting apart. Beyond the byte
identity of the shared .pxd files, it enforces that the interpreter's
`InterpreterDsp` and the LLVM JIT's `LlvmDsp` expose the same public method set:
`InterpreterDsp` is amalgamated into the static source by generate_static.py,
whereas `LlvmDsp` in backend_llvm.pxi is hand-maintained and NOT regenerated, so
a method added to one backend can silently miss the other (this is exactly how
the runtime param API first shipped without an LLVM counterpart). These tests
pin the extraction and the drift/stale-allowlist detection.
"""

import importlib.util
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).parent.parent
VERIFY_SCRIPT = PROJECT_ROOT / "scripts" / "verify_build_sync.py"


def _load_verifier():
    """Import scripts/verify_build_sync.py as a module (not on sys.path)."""
    spec = importlib.util.spec_from_file_location("verify_build_sync", VERIFY_SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture
def vbs():
    """The verifier module (its paths are anchored to PROJECT_ROOT already)."""
    return _load_verifier()


def test_public_methods_extracts_api(vbs):
    """public_methods() picks up Python-visible methods and drops private ones."""
    interp_path, interp_name = vbs.INTERP_DSP
    methods = vbs.public_methods(PROJECT_ROOT / interp_path, interp_name)
    # Representative public API of the DSP instance.
    assert {"params", "get_param", "set_param", "compute", "init"} <= methods
    # cdef helpers / dunders must be excluded.
    assert not any(m.startswith("_") for m in methods)


def test_llvm_and_interp_are_in_parity(vbs):
    """The shipped classes satisfy the parity check (no accidental drift)."""
    assert vbs.check_class_parity() == 0


def test_param_api_present_on_both_backends(vbs):
    """The runtime param API exists on both DSP classes, not just one.

    This is the concrete regression the guard was added for.
    """
    interp = vbs.public_methods(PROJECT_ROOT / vbs.INTERP_DSP[0], vbs.INTERP_DSP[1])
    llvm = vbs.public_methods(PROJECT_ROOT / vbs.LLVM_DSP[0], vbs.LLVM_DSP[1])
    for name in ("params", "get_param", "set_param"):
        assert name in interp, f"{name} missing from {vbs.INTERP_DSP[1]}"
        assert name in llvm, f"{name} missing from {vbs.LLVM_DSP[1]}"


def test_allowed_differences_are_genuinely_interp_only(vbs):
    """Every INTERP_ONLY_ALLOWED entry really is absent from LlvmDsp.

    A stale entry (method since ported) would mask a future genuine drift, so
    the guard rejects it; this asserts the shipped allowlist is not already stale.
    """
    interp = vbs.public_methods(PROJECT_ROOT / vbs.INTERP_DSP[0], vbs.INTERP_DSP[1])
    llvm = vbs.public_methods(PROJECT_ROOT / vbs.LLVM_DSP[0], vbs.LLVM_DSP[1])
    interp_only = interp - llvm
    assert set(vbs.INTERP_ONLY_ALLOWED) == interp_only


def test_drift_is_detected(vbs, monkeypatch):
    """A method on InterpreterDsp with no LlvmDsp counterpart fails the check."""
    real = vbs.public_methods

    def missing_set_param(path, cls):
        m = real(path, cls)
        return m - {"set_param"} if cls == vbs.LLVM_DSP[1] else m

    monkeypatch.setattr(vbs, "public_methods", missing_set_param)
    assert vbs.check_class_parity() > 0


def test_stale_allowlist_entry_is_detected(vbs, monkeypatch):
    """An allowlisted difference that reached parity fails the check."""
    real = vbs.public_methods

    def control_ported(path, cls):
        m = real(path, cls)
        # Pretend control() was ported to LlvmDsp, so it is no longer interp-only
        # while still sitting in INTERP_ONLY_ALLOWED.
        return m | {"control"} if cls == vbs.LLVM_DSP[1] else m

    monkeypatch.setattr(vbs, "public_methods", control_ported)
    assert vbs.check_class_parity() > 0


def test_new_llvm_only_method_is_detected(vbs, monkeypatch):
    """A method unique to LlvmDsp (not in the LLVM allowlist) fails the check."""
    real = vbs.public_methods

    def extra(path, cls):
        m = real(path, cls)
        return m | {"llvm_special"} if cls == vbs.LLVM_DSP[1] else m

    monkeypatch.setattr(vbs, "public_methods", extra)
    assert vbs.check_class_parity() > 0
