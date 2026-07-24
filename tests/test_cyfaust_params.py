"""
Test suite for the cyfaust runtime UI parameter API.

Exercises params() / get_param() / set_param(), which expose the DSP's control
zones through an APIUI. Mirrors the behaviour of the sibling py-faust-rs
project's params() bridge.

The same API is provided by both runtime backends -- the interpreter
(InterpreterDsp, always built) and the LLVM JIT (LlvmDsp, only present in a
static build made with `-DLLVM=ON`). Every test runs against each backend that
is available; the LLVM parametrization is skipped otherwise.
"""

import numpy as np
import pytest

# The interpreter factory is exposed at module scope in the dynamic build and
# under cyfaust.cyfaust in the static (monolithic) build.
try:
    from cyfaust.interp import create_dsp_factory_from_string
except (ModuleNotFoundError, ImportError):
    from cyfaust.cyfaust import create_dsp_factory_from_string

# The LLVM factory only exists in a static build compiled with -DLLVM=ON.
try:
    from cyfaust.cyfaust import llvm_create_dsp_factory_from_string
except (ModuleNotFoundError, ImportError):
    llvm_create_dsp_factory_from_string = None

from testutils import print_entry


# Each entry is (backend id, factory-from-string callable). The LLVM entry is
# replaced by a skip marker when that backend was not compiled in.
_BACKENDS = [pytest.param(create_dsp_factory_from_string, id="interp")]
if llvm_create_dsp_factory_from_string is not None:
    _BACKENDS.append(
        pytest.param(llvm_create_dsp_factory_from_string, id="llvm")
    )
else:
    _BACKENDS.append(
        pytest.param(
            None,
            id="llvm",
            marks=pytest.mark.skip(reason="LLVM backend not built (needs -DLLVM=ON)"),
        )
    )


@pytest.fixture(params=_BACKENDS)
def make_dsp(request):
    """Yield a `_make(name, src, sample_rate)` bound to one runtime backend.

    Parametrized over every available backend, so each test that consumes this
    fixture is run once per backend.
    """
    create_factory = request.param

    def _make(name, src, sample_rate=48000):
        # The factory owns the instance (the instance holds only a weak
        # back-ref), so the caller must keep the returned factory alive for the
        # instance to stay valid.
        factory = create_factory(name, src)
        assert factory is not None, "failed to create factory"
        dsp = factory.create_dsp_instance()
        dsp.init(sample_rate)
        return factory, dsp

    return _make


class TestParamEnumeration:
    def test_params_metadata_matches_declaration(self, make_dsp):
        print_entry("test_params_metadata_matches_declaration")
        factory, dsp = make_dsp(
            "p_meta", 'process = _ * hslider("gain", 1, 0, 2, 0.01);'
        )
        params = dsp.params()
        assert len(params) == 1
        p = params[0]
        assert p.path == "/p_meta/gain"
        assert p.label == "gain"
        assert p.kind == "hslider"
        assert p.is_input is True
        assert p.init == pytest.approx(1.0)
        assert p.min == pytest.approx(0.0)
        assert p.max == pytest.approx(2.0)
        assert p.step == pytest.approx(0.01, abs=1e-6)

    def test_widget_kinds_are_mapped(self, make_dsp):
        print_entry("test_widget_kinds_are_mapped")
        factory, dsp = make_dsp(
            "p_kinds",
            'process = button("go"), checkbox("on"), '
            'nentry("n", 2, 0, 8, 1), vslider("v", 0, 0, 1, 0.1);',
        )
        kinds = {p.label: p.kind for p in dsp.params()}
        assert kinds == {
            "go": "button",
            "on": "checkbox",
            "n": "nentry",
            "v": "vslider",
        }

    def test_no_params_for_plain_dsp(self, make_dsp):
        print_entry("test_no_params_for_plain_dsp")
        factory, dsp = make_dsp("p_none", "process = _;")
        assert dsp.params() == []


class TestGetSetParam:
    def test_get_and_set_by_label_and_path(self, make_dsp):
        print_entry("test_get_and_set_by_label_and_path")
        factory, dsp = make_dsp(
            "p_gs", 'process = _ * hslider("gain", 1, 0, 2, 0.01);'
        )
        assert dsp.get_param("gain") == pytest.approx(1.0)  # init
        assert dsp.get_param("/p_gs/gain") == pytest.approx(1.0)

        dsp.set_param("gain", 0.5)
        assert dsp.get_param("gain") == pytest.approx(0.5)
        # Address the same control by full path.
        dsp.set_param("/p_gs/gain", 0.25)
        assert dsp.get_param("gain") == pytest.approx(0.25)

    def test_set_param_affects_compute(self, make_dsp):
        print_entry("test_set_param_affects_compute")
        factory, dsp = make_dsp(
            "p_compute", 'process = _ * hslider("gain", 1, 0, 2, 0.01);'
        )
        dsp.set_param("gain", 0.5)
        x = np.ones((1, 8), dtype="float32")
        y = np.zeros((1, 8), dtype="float32")
        dsp.compute(8, x, y)
        assert np.allclose(y[0], 0.5)

    def test_unknown_key_raises(self, make_dsp):
        print_entry("test_unknown_key_raises")
        factory, dsp = make_dsp(
            "p_unknown", 'process = _ * hslider("gain", 1, 0, 2, 0.01);'
        )
        with pytest.raises(ValueError):
            dsp.get_param("nope")
        with pytest.raises(ValueError):
            dsp.set_param("nope", 1.0)

    def test_ambiguous_label_requires_full_path(self, make_dsp):
        print_entry("test_ambiguous_label_requires_full_path")
        factory, dsp = make_dsp(
            "p_amb",
            'process = hgroup("a", vslider("x", 0, 0, 1, 0.1)), '
            'hgroup("b", vslider("x", 0, 0, 1, 0.1));',
        )
        assert sorted(p.path for p in dsp.params()) == ["/p_amb/a/x", "/p_amb/b/x"]
        with pytest.raises(ValueError):
            dsp.get_param("x")  # ambiguous leaf label
        # Full paths resolve unambiguously.
        dsp.set_param("/p_amb/a/x", 0.5)
        assert dsp.get_param("/p_amb/a/x") == pytest.approx(0.5)
        assert dsp.get_param("/p_amb/b/x") == pytest.approx(0.0)


class TestBargraphOutputs:
    def test_bargraph_is_readonly_output(self, make_dsp):
        print_entry("test_bargraph_is_readonly_output")
        factory, dsp = make_dsp(
            "p_bar", 'process = _ <: attach(_, hbargraph("meter", 0, 1));'
        )
        meter = next(p for p in dsp.params() if p.label == "meter")
        assert meter.kind == "hbargraph"
        assert meter.is_input is False
        # Setting an output must fail.
        with pytest.raises(ValueError):
            dsp.set_param("meter", 0.3)

    def test_bargraph_reflects_last_compute(self, make_dsp):
        print_entry("test_bargraph_reflects_last_compute")
        factory, dsp = make_dsp(
            "p_bar2", 'process = _ <: attach(_, hbargraph("meter", 0, 1));'
        )
        x = np.full((1, 16), 0.7, dtype="float32")
        y = np.zeros((1, 16), dtype="float32")
        dsp.compute(16, x, y)
        # The bargraph zone tracks the (constant) input level.
        assert dsp.get_param("meter") == pytest.approx(0.7, abs=1e-4)
