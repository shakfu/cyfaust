"""Tests for scripts/generate_static.py, the static-variant source generator.

The generator consolidates the dynamic modules in src/cyfaust/*.pyx into a single
monolithic src/static/cyfaust/cyfaust.pyx. It strips each module's top-level
imports and is responsible for re-emitting them in the generated header; a bug
where collected imports were dropped broke the static build when interp.pyx added
`import weakref` for the factory double-free fix. These tests pin that behavior.
"""

import importlib.util
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).parent.parent
GEN_SCRIPT = PROJECT_ROOT / "scripts" / "generate_static.py"


def _load_generator():
    """Import scripts/generate_static.py as a module (not on sys.path)."""
    spec = importlib.util.spec_from_file_location("generate_static", GEN_SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture
def gen(monkeypatch):
    """The generator module, with CWD pinned to the project root.

    The generator reads sources via the relative path Path("src/cyfaust"), so it
    must run from the project root regardless of where pytest was invoked.
    """
    monkeypatch.chdir(PROJECT_ROOT)
    mod = _load_generator()
    mod.COLLECTED_IMPORTS.clear()
    return mod


def _generate_full_source(gen):
    """Reproduce generate_static_pyx()'s output as a string, without writing.

    Modules are processed first so COLLECTED_IMPORTS is populated before the
    header is generated, mirroring the real generation order.
    """
    gen.COLLECTED_IMPORTS.clear()
    contents = [c for m in gen.MODULES if (c := gen.process_module(m))]
    return gen.generate_header() + "\n".join(contents) + gen.generate_llvm_footer()


def test_weakref_collected_from_interp(gen):
    """interp.pyx's `import weakref` is collected during module processing."""
    gen.process_module("interp")
    assert "import weakref" in gen.COLLECTED_IMPORTS


def test_weakref_survives_generation(gen):
    """`import weakref` is re-emitted, and lands before its first use.

    This is the regression guard: the generator strips the import from the module
    body, so if generate_header() fails to re-emit it the static build dies with
    "undeclared name not builtin: weakref".
    """
    source = _generate_full_source(gen)
    assert "import weakref" in source
    assert source.index("import weakref") < source.index("weakref.WeakSet()")


def test_header_does_not_duplicate_hardcoded_imports(gen):
    """An import the hardcoded header already provides is not re-emitted.

    `import os` (from common.pyx) and the partial `from cython.operator cimport
    dereference as deref` (from player.pyx, a prefix of the fuller header line)
    are both already present, so the dedup must leave them at one occurrence each.
    """
    _generate_full_source(gen)
    header = gen.generate_header()
    assert header.count("import os") == 1
    assert header.count("from cython.operator cimport dereference as deref") == 1
