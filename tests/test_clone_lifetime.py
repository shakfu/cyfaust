"""Lifetime/teardown tests for InterpreterDsp.clone().

clone() returns an instance with ptr_owner=False. It used to be tracked by no
factory, so nothing ever freed its C++ pointer (its __dealloc__ frees nothing
when ptr_owner is False) -- a leak unless the caller manually called delete().
It is now registered with the same factory as its parent, so the pointer is
freed on the factory's ordered teardown, exactly like a create_dsp_instance()
result.

These tests assert the clone is tracked (the leak fix) and that the tracking
does not re-introduce a double-free/use-after-free at interpreter exit across a
range of teardown orderings.
"""

import gc
import subprocess
import sys
from pathlib import Path

import pytest

try:
    from cyfaust.interp import create_dsp_factory_from_string
except (ModuleNotFoundError, ImportError):
    from cyfaust.cyfaust import create_dsp_factory_from_string

PROJECT_ROOT = Path(__file__).parent.parent
LIBS = str(PROJECT_ROOT / "resources" / "libraries")
DSP = 'import("stdfaust.lib"); process = os.osc(440)*0.1;'


def _factory():
    return create_dsp_factory_from_string("clonetest", DSP, "-I", LIBS)


def _set_referrers(obj):
    """Sets that reference obj. The factory tracks instances in a (cdef) set, so
    a tracked instance has one such referrer; an untracked clone has none."""
    return [r for r in gc.get_referrers(obj) if isinstance(r, set)]


def test_clone_is_functional():
    """A clone is a usable DSP with the same I/O shape as its parent."""
    f = _factory()
    d = f.create_dsp_instance()
    d.init(44100)
    c = d.clone()
    c.init(44100)
    assert c.get_numinputs() == d.get_numinputs()
    assert c.get_numoutputs() == d.get_numoutputs()


def test_created_instance_is_tracked():
    """Control: a create_dsp_instance() result is tracked by the factory."""
    f = _factory()
    d = f.create_dsp_instance()
    assert _set_referrers(d), "created instance should be tracked by the factory"


def test_clone_is_tracked_by_factory():
    """The leak fix: a clone is now retained by its factory's instance set.

    Before the fix the clone had no set referrer, so its C++ pointer was freed
    by nobody. Asserted indirectly because the tracking set is an internal cdef
    member not exposed to Python.
    """
    f = _factory()
    d = f.create_dsp_instance()
    c = d.clone()
    assert _set_referrers(c), "clone is tracked by no factory set -> would leak"


def test_clone_of_clone_is_tracked():
    """The factory weakref propagates through a chain of clones."""
    f = _factory()
    d = f.create_dsp_instance()
    c2 = d.clone().clone()
    assert _set_referrers(c2), "clone-of-clone not tracked -> would leak"


def _run_teardown(scenario: str) -> subprocess.CompletedProcess:
    """Run a clone scenario in a fresh interpreter and return the result.

    The body runs, then the process exits and tears down -- the moment any
    double-free/use-after-free in the factory/instance teardown would surface as
    a non-zero exit code.
    """
    src = (
        "try:\n"
        "    from cyfaust.interp import create_dsp_factory_from_string, delete_all_dsp_factories\n"
        "except ImportError:\n"
        "    from cyfaust.cyfaust import create_dsp_factory_from_string, delete_all_dsp_factories\n"
        f"LIBS = {LIBS!r}\n"
        f"DSP = {DSP!r}\n"
        "f = create_dsp_factory_from_string('ct', DSP, '-I', LIBS)\n"
        "d = f.create_dsp_instance(); d.init(44100)\n"
        + scenario
    )
    return subprocess.run(
        [sys.executable, "-c", src],
        cwd=str(PROJECT_ROOT),
        capture_output=True,
        text=True,
    )


@pytest.mark.parametrize(
    "name,scenario",
    [
        ("plain", "c = d.clone(); c.init(44100)\n"),
        ("clone_of_clone", "c = d.clone().clone(); c.init(44100)\n"),
        ("explicit_delete", "c = d.clone(); c.init(44100); c.delete()\n"),
        ("delete_then_exit", "c = d.clone(); c.delete(); c.delete()\n"),  # idempotent
        ("delete_all", "c = d.clone(); c.init(44100); delete_all_dsp_factories()\n"),
        ("drop_parent", "c = d.clone(); del d\n"),
    ],
)
def test_clone_teardown_no_crash(name, scenario):
    """Clone teardown is crash-free across orderings (guards the new tracking)."""
    r = _run_teardown(scenario)
    assert r.returncode == 0, f"{name}: rc={r.returncode}\nSTDERR:\n{r.stderr}"
