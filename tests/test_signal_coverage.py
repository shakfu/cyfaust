"""Extended signal API tests for improved coverage.

Tests cover: primitives, arithmetic, bitwise, comparison, logical, math,
delay, casting, tables, soundfiles, selectors, recursion, UI elements,
attach, foreign functions, type checking, normalization, source generation,
Signal OO interface, and SignalVector.
"""

import array

import pytest

try:
    from cyfaust.signal import (
        # context
        signal_context,
        # primitives
        sig_int,
        sig_real,
        sig_float,
        sig_input,
        # delay
        sig_delay,
        sig_delay1,
        # cast
        sig_int_cast,
        sig_float_cast,
        # tables
        sig_readonly_table,
        sig_write_read_table,
        sig_waveform_int,
        sig_waveform_float,
        # soundfile
        sig_soundfile,
        sig_soundfile_length,
        sig_soundfile_rate,
        sig_soundfile_buffer,
        # selectors
        sig_select2,
        sig_select3,
        # arithmetic
        sig_add,
        sig_sub,
        sig_mul,
        sig_div,
        sig_rem,
        sig_bin_op,
        # bitwise
        sig_leftshift,
        sig_lrightshift,
        sig_arightshift,
        # comparison
        sig_gt,
        sig_lt,
        sig_ge,
        sig_le,
        sig_eq,
        sig_ne,
        # logical
        sig_and,
        sig_or,
        sig_xor,
        # math unary
        sig_abs,
        sig_acos,
        sig_asin,
        sig_atan,
        sig_ceil,
        sig_cos,
        sig_exp,
        sig_exp10,
        sig_floor,
        sig_log,
        sig_log10,
        sig_rint,
        sig_sin,
        sig_sqrt,
        sig_tan,
        # math binary
        sig_remainder,
        sig_pow,
        sig_min,
        sig_max,
        sig_fmod,
        sig_atan2,
        # recursion
        sig_self,
        sig_recursion,
        sig_self_n,
        sig_recursion_n,
        # UI
        sig_button,
        sig_checkbox,
        sig_vslider,
        sig_hslider,
        sig_numentry,
        sig_vbargraph,
        sig_hbargraph,
        # misc
        sig_attach,
        sig_fconst,
        sig_fvar,
        # helpers
        sig_or_float,
        sig_or_int,
        # utility
        print_signal,
        is_nil,
        simplify_to_normal_form,
        simplify_to_normal_form2,
        create_source_from_signals,
        # type checking
        is_sig_int,
        is_sig_float,
        is_sig_input,
        is_sig_delay,
        is_sig_delay1,
        is_sig_bin_op,
        is_sig_int_cast,
        is_sig_float_cast,
        is_sig_button,
        is_sig_checkbox,
        is_sig_hslider,
        is_sig_vslider,
        is_sig_numentry,
        is_sig_hbargraph,
        is_sig_vbargraph,
        is_sig_attach,
        is_sig_fconst,
        is_sig_fvar,
        is_sig_select2,
        is_sig_readonly_table,
        is_sig_read_write_table,
        is_sig_soundfile,
        is_sig_soundfile_length,
        is_sig_soundfile_rate,
        is_sig_soundfile_buffer,
        is_sig_waveform,
        # classes
        Signal,
        SignalVector,
        Interval,
        SType,
        SOperator,
    )
    from cyfaust.interp import create_dsp_factory_from_signals
except (ModuleNotFoundError, ImportError):
    pytest.skip("cyfaust not available", allow_module_level=True)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def ctx():
    """Provide a signal context for every test."""
    with signal_context():
        yield


# ---------------------------------------------------------------------------
# Primitives
# ---------------------------------------------------------------------------


class TestPrimitives:
    def test_sig_int(self):
        s = sig_int(42)
        result = is_sig_int(s)
        assert result
        assert result.get("i") == 42

    def test_sig_real(self):
        s = sig_real(3.14)
        result = is_sig_float(s)
        assert result

    def test_sig_float_alias(self):
        s = sig_float(2.71)
        result = is_sig_float(s)
        assert result

    def test_sig_input(self):
        s = sig_input(0)
        result = is_sig_input(s)
        assert result
        assert result.get("i") == 0

    def test_sig_input_channel_1(self):
        s = sig_input(1)
        result = is_sig_input(s)
        assert result
        assert result.get("i") == 1

    def test_is_nil(self):
        s = sig_int(1)
        assert not is_nil(s)


# ---------------------------------------------------------------------------
# Signal constructor and static factories
# ---------------------------------------------------------------------------


class TestSignalConstructor:
    def test_static_from_int(self):
        s = Signal.from_int(10)
        assert is_sig_int(s)

    def test_static_from_float(self):
        s = Signal.from_float(1.5)
        assert is_sig_float(s)

    def test_static_from_real(self):
        s = Signal.from_real(2.5)
        assert is_sig_float(s)

    def test_static_from_input(self):
        s = Signal.from_input(0)
        assert is_sig_input(s)

    def test_static_from_button(self):
        s = Signal.from_button("gate")
        assert is_sig_button(s)

    def test_static_from_checkbox(self):
        s = Signal.from_checkbox("mute")
        assert is_sig_checkbox(s)

    def test_static_from_vslider(self):
        s = Signal.from_vslider("gain", 0.5, 0.0, 1.0, 0.01)
        assert is_sig_vslider(s)

    def test_static_from_hslider(self):
        s = Signal.from_hslider("freq", 440.0, 50.0, 2000.0, 1.0)
        assert is_sig_hslider(s)

    def test_static_from_numentry(self):
        s = Signal.from_numentry("order", 4.0, 1.0, 8.0, 1.0)
        assert is_sig_numentry(s)


# ---------------------------------------------------------------------------
# Arithmetic functions
# ---------------------------------------------------------------------------


class TestArithmetic:
    def test_add(self):
        s = sig_add(sig_int(1), sig_int(2))
        result = is_sig_bin_op(s)
        assert result
        assert result["op"] == int(SOperator.kAdd)
        assert "x" in result and "y" in result

    def test_sub(self):
        s = sig_sub(sig_int(5), sig_int(3))
        result = is_sig_bin_op(s)
        assert result
        assert result["op"] == int(SOperator.kSub)

    def test_mul(self):
        s = sig_mul(sig_int(3), sig_int(4))
        result = is_sig_bin_op(s)
        assert result
        assert result["op"] == int(SOperator.kMul)

    def test_div(self):
        s = sig_div(sig_real(10.0), sig_real(2.0))
        result = is_sig_bin_op(s)
        assert result
        assert result["op"] == int(SOperator.kDiv)

    def test_rem(self):
        s = sig_rem(sig_int(7), sig_int(3))
        result = is_sig_bin_op(s)
        assert result
        assert result["op"] == int(SOperator.kRem)

    def test_bin_op(self):
        s = sig_bin_op(SOperator.kMul, sig_int(3), sig_int(4))
        result = is_sig_bin_op(s)
        assert result
        assert result["op"] == int(SOperator.kMul)


# ---------------------------------------------------------------------------
# Bitwise functions
# ---------------------------------------------------------------------------


class TestBitwise:
    def test_leftshift(self):
        assert is_sig_bin_op(sig_leftshift(sig_int(1), sig_int(4)))

    def test_lrightshift(self):
        assert is_sig_bin_op(sig_lrightshift(sig_int(16), sig_int(2)))

    def test_arightshift(self):
        assert is_sig_bin_op(sig_arightshift(sig_int(-8), sig_int(1)))


# ---------------------------------------------------------------------------
# Comparison functions
# ---------------------------------------------------------------------------


class TestComparison:
    @pytest.mark.parametrize("fn", [sig_gt, sig_lt, sig_ge, sig_le, sig_eq, sig_ne])
    def test_comparison(self, fn):
        s = fn(sig_int(1), sig_int(2))
        assert is_sig_bin_op(s)


# ---------------------------------------------------------------------------
# Logical functions
# ---------------------------------------------------------------------------


class TestLogical:
    @pytest.mark.parametrize("fn", [sig_and, sig_or, sig_xor])
    def test_logical(self, fn):
        s = fn(sig_int(1), sig_int(0))
        assert is_sig_bin_op(s)


# ---------------------------------------------------------------------------
# Signal operators (OO)
# ---------------------------------------------------------------------------


class TestSignalOperators:
    def test_add(self):
        s = sig_int(1) + sig_int(2)
        assert is_sig_bin_op(s)

    def test_sub(self):
        s = sig_int(5) - sig_int(3)
        assert is_sig_bin_op(s)

    def test_mul(self):
        s = sig_int(3) * sig_int(4)
        assert is_sig_bin_op(s)

    def test_radd(self):
        # reverse ops require Signal on both sides in Cython
        s = sig_real(1.0) + sig_real(2.0)
        assert is_sig_bin_op(s)

    def test_rsub(self):
        s = sig_real(5.0) - sig_real(3.0)
        assert is_sig_bin_op(s)

    def test_rmul(self):
        s = sig_real(3.0) * sig_real(4.0)
        assert is_sig_bin_op(s)

    def test_eq(self):
        s = sig_int(1) == sig_int(1)
        assert is_sig_bin_op(s)

    def test_ne(self):
        s = sig_int(1) != sig_int(2)
        assert is_sig_bin_op(s)

    def test_gt(self):
        s = sig_int(2) > sig_int(1)
        assert is_sig_bin_op(s)

    def test_ge(self):
        s = sig_int(2) >= sig_int(2)
        assert is_sig_bin_op(s)

    def test_lt(self):
        s = sig_int(1) < sig_int(2)
        assert is_sig_bin_op(s)

    def test_le(self):
        s = sig_int(2) <= sig_int(2)
        assert is_sig_bin_op(s)

    def test_and(self):
        s = sig_int(1) & sig_int(1)
        assert is_sig_bin_op(s)

    def test_or(self):
        s = sig_int(1) | sig_int(0)
        assert is_sig_bin_op(s)

    def test_xor(self):
        s = sig_int(1) ^ sig_int(0)
        assert is_sig_bin_op(s)

    def test_lshift(self):
        s = sig_int(1) << sig_int(4)
        assert is_sig_bin_op(s)

    def test_rshift(self):
        s = sig_int(16) >> sig_int(2)
        assert is_sig_bin_op(s)

    def test_mod(self):
        s = sig_int(7) % sig_int(3)
        assert is_sig_bin_op(s)


# ---------------------------------------------------------------------------
# Math functions (unary)
# ---------------------------------------------------------------------------


class TestMathUnary:
    @pytest.mark.parametrize(
        "fn",
        [
            sig_abs,
            sig_acos,
            sig_asin,
            sig_atan,
            sig_ceil,
            sig_cos,
            sig_exp,
            sig_exp10,
            sig_floor,
            sig_log,
            sig_log10,
            sig_rint,
            sig_sin,
            sig_sqrt,
            sig_tan,
        ],
    )
    def test_unary_math(self, fn):
        s = fn(sig_real(0.5))
        # unary math produces an ffun signal
        assert s is not None


# ---------------------------------------------------------------------------
# Math functions (binary)
# ---------------------------------------------------------------------------


class TestMathBinary:
    @pytest.mark.parametrize(
        "fn",
        [
            sig_remainder,
            sig_pow,
            sig_min,
            sig_max,
            sig_fmod,
            sig_atan2,
        ],
    )
    def test_binary_math(self, fn):
        s = fn(sig_real(1.0), sig_real(2.0))
        assert s is not None


# ---------------------------------------------------------------------------
# Signal OO math methods
# ---------------------------------------------------------------------------


class TestSignalOOMath:
    @pytest.mark.parametrize(
        "method",
        [
            "abs",
            "acos",
            "asin",
            "atan",
            "ceil",
            "cos",
            "exp",
            "exp10",
            "floor",
            "log",
            "log10",
            "rint",
            "sin",
            "sqrt",
            "tan",
        ],
    )
    def test_unary_methods(self, method):
        s = sig_real(0.5)
        result = getattr(s, method)()
        assert result is not None

    @pytest.mark.parametrize(
        "method",
        [
            "remainder",
            "pow",
            "min",
            "max",
            "fmod",
        ],
    )
    def test_binary_methods(self, method):
        s = sig_real(1.0)
        result = getattr(s, method)(sig_real(2.0))
        assert result is not None


# ---------------------------------------------------------------------------
# Delay
# ---------------------------------------------------------------------------


class TestDelay:
    def test_sig_delay(self):
        s = sig_delay(sig_input(0), sig_int(100))
        result = is_sig_delay(s)
        assert result
        assert "t0" in result and "t1" in result

    def test_sig_delay1(self):
        s = sig_delay1(sig_input(0))
        result = is_sig_delay1(s)
        assert result
        assert "t0" in result

    def test_delay_oo_method(self):
        s = sig_input(0).delay(sig_int(100))
        result = is_sig_delay(s)
        assert result
        assert "t0" in result


# ---------------------------------------------------------------------------
# Casting
# ---------------------------------------------------------------------------


class TestCasting:
    def test_sig_int_cast(self):
        # Use sig_input to avoid constant folding which elides the cast node
        s = sig_int_cast(sig_input(0))
        result = is_sig_int_cast(s)
        assert result
        assert "x" in result

    def test_sig_float_cast(self):
        s = sig_float_cast(sig_input(0))
        result = is_sig_float_cast(s)
        assert result
        assert "x" in result

    def test_int_cast_oo(self):
        s = sig_input(0).int_cast()
        assert is_sig_int_cast(s)

    def test_float_cast_oo(self):
        s = sig_input(0).float_cast()
        assert is_sig_float_cast(s)


# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------


class TestTables:
    def test_readonly_table(self):
        s = sig_readonly_table(sig_int(10), sig_int(0), sig_int_cast(sig_input(0)))
        result = is_sig_readonly_table(s)
        assert result
        assert "t" in result and "i" in result

    def test_write_read_table(self):
        # Faust decomposes write/read tables into sigRDTbl(sigWRTbl4p(...), ridx)
        # so is_sig_read_write_table won't match the outer node; verify construction
        s = sig_write_read_table(
            sig_int(10),
            sig_int(0),
            sig_int_cast(sig_input(0)),
            sig_input(0),
            sig_int_cast(sig_input(0)),
        )
        assert s is not None
        assert "sigRDTbl" in print_signal(s, False, 256)

    def test_waveform_int(self):
        data = array.array("i", [0, 100, 200, 300, 400])
        s = sig_waveform_int(data)
        assert is_sig_waveform(s)

    def test_waveform_float(self):
        data = array.array("f", [0.0, 0.25, 0.5, 0.75, 1.0])
        s = sig_waveform_float(data)
        assert is_sig_waveform(s)


# ---------------------------------------------------------------------------
# Soundfiles
# ---------------------------------------------------------------------------


class TestSoundfiles:
    def test_sig_soundfile(self):
        s = sig_soundfile("test_sound")
        result = is_sig_soundfile(s)
        assert result
        assert "label" in result

    def test_sig_soundfile_length(self):
        sf = sig_soundfile("test_sound")
        s = sig_soundfile_length(sf, sig_int(0))
        result = is_sig_soundfile_length(s)
        assert result
        assert "sf" in result and "part" in result

    def test_sig_soundfile_rate(self):
        sf = sig_soundfile("test_sound")
        s = sig_soundfile_rate(sf, sig_int(0))
        result = is_sig_soundfile_rate(s)
        assert result
        assert "sf" in result and "part" in result

    def test_sig_soundfile_buffer(self):
        sf = sig_soundfile("test_sound")
        s = sig_soundfile_buffer(sf, sig_int(0), sig_int(0), sig_int(0))
        result = is_sig_soundfile_buffer(s)
        assert result
        assert set(result.keys()) == {"sf", "chan", "part", "ridx"}


# ---------------------------------------------------------------------------
# Selectors
# ---------------------------------------------------------------------------


class TestSelectors:
    def test_select2(self):
        s = sig_select2(sig_int(0), sig_int(10), sig_int(20))
        result = is_sig_select2(s)
        assert result
        assert set(result.keys()) == {"selector", "s1", "s2"}

    def test_select3(self):
        s = sig_select3(sig_int(0), sig_int(10), sig_int(20), sig_int(30))
        assert s is not None

    def test_select2_oo(self):
        s = sig_int(0).select2(sig_int(10), sig_int(20))
        assert is_sig_select2(s)

    def test_select3_oo(self):
        s = sig_int(0).select3(sig_int(10), sig_int(20), sig_int(30))
        assert s is not None


# ---------------------------------------------------------------------------
# Recursion
# ---------------------------------------------------------------------------


class TestRecursion:
    def test_sig_self(self):
        s = sig_self()
        assert s is not None

    def test_sig_recursion(self):
        s = sig_recursion(sig_add(sig_self(), sig_int(1)))
        assert s is not None

    def test_sig_self_n(self):
        s = sig_self_n(0)
        assert s is not None

    def test_sig_recursion_n(self):
        rf = SignalVector()
        rf.add(sig_add(sig_self_n(0), sig_int(1)))
        result = sig_recursion_n(rf)
        assert result is not None

    def test_recursion_oo(self):
        s = sig_add(sig_self(), sig_int(1)).recursion()
        assert s is not None


# ---------------------------------------------------------------------------
# UI elements
# ---------------------------------------------------------------------------


class TestUI:
    def test_button(self):
        s = sig_button("gate")
        result = is_sig_button(s)
        assert result
        assert "lbl" in result

    def test_checkbox(self):
        s = sig_checkbox("mute")
        result = is_sig_checkbox(s)
        assert result
        assert "lbl" in result

    def test_vslider(self):
        s = sig_vslider("gain", sig_real(0.5), sig_real(0), sig_real(1), sig_real(0.01))
        result = is_sig_vslider(s)
        assert result
        assert set(result.keys()) == {"lbl", "init", "min", "max", "step"}

    def test_hslider(self):
        s = sig_hslider("freq", sig_real(440), sig_real(50), sig_real(2000), sig_real(1))
        result = is_sig_hslider(s)
        assert result
        assert set(result.keys()) == {"lbl", "init", "min", "max", "step"}

    def test_numentry(self):
        s = sig_numentry("order", sig_int(4), sig_int(1), sig_int(8), sig_int(1))
        result = is_sig_numentry(s)
        assert result
        assert set(result.keys()) == {"lbl", "init", "min", "max", "step"}

    def test_vbargraph(self):
        s = sig_vbargraph("level", sig_real(-70), sig_real(0), sig_input(0))
        result = is_sig_vbargraph(s)
        assert result
        assert set(result.keys()) == {"lbl", "min", "max", "x"}

    def test_hbargraph(self):
        s = sig_hbargraph("meter", sig_real(-70), sig_real(0), sig_input(0))
        result = is_sig_hbargraph(s)
        assert result
        assert set(result.keys()) == {"lbl", "min", "max", "x"}

    def test_vbargraph_oo(self):
        s = sig_input(0).vbargraph("level", -70.0, 0.0)
        assert is_sig_vbargraph(s)

    def test_hbargraph_oo(self):
        s = sig_input(0).hbargraph("meter", -70.0, 0.0)
        assert is_sig_hbargraph(s)


# ---------------------------------------------------------------------------
# Attach and foreign
# ---------------------------------------------------------------------------


class TestAttachForeign:
    def test_attach(self):
        s = sig_attach(sig_input(0), sig_int(0))
        result = is_sig_attach(s)
        assert result
        assert "s0" in result and "s1" in result

    def test_attach_oo(self):
        s = sig_input(0).attach(sig_int(0))
        result = is_sig_attach(s)
        assert result
        assert "s0" in result

    def test_fconst(self):
        s = sig_fconst(SType.kSInt, "fSampleFreq", "<math.h>")
        result = is_sig_fconst(s)
        assert result
        assert set(result.keys()) == {"type", "name", "file"}

    def test_fvar(self):
        s = sig_fvar(SType.kSInt, "count", "<math.h>")
        result = is_sig_fvar(s)
        assert result
        assert set(result.keys()) == {"type", "name", "file"}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


class TestHelpers:
    def test_sig_or_float(self):
        s = sig_or_float(3.14)
        assert is_sig_float(s)
        s2 = sig_or_float(sig_real(3.14))
        assert is_sig_float(s2)

    def test_sig_or_int(self):
        s = sig_or_int(42)
        assert is_sig_int(s)
        s2 = sig_or_int(sig_int(42))
        assert is_sig_int(s2)


# ---------------------------------------------------------------------------
# Type checking (negative cases)
# ---------------------------------------------------------------------------


class TestTypeCheckingNegative:
    def test_int_is_not_float(self):
        assert not is_sig_float(sig_int(1))

    def test_float_is_not_int(self):
        assert not is_sig_int(sig_real(1.0))

    def test_input_is_not_delay(self):
        assert not is_sig_delay(sig_input(0))

    def test_int_is_not_button(self):
        assert not is_sig_button(sig_int(1))

    def test_int_is_not_attach(self):
        assert not is_sig_attach(sig_int(1))

    def test_int_is_not_select2(self):
        assert not is_sig_select2(sig_int(1))


# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------


class TestUtility:
    def test_print_signal(self):
        s = sig_int(42)
        result = print_signal(s, False, 256)
        assert isinstance(result, str)
        assert len(result) > 0

    def test_simplify_to_normal_form(self):
        s = sig_add(sig_int(1), sig_int(2))
        result = simplify_to_normal_form(s)
        assert result is not None

    def test_simplify_to_normal_form2(self):
        sv = SignalVector()
        sv.add(sig_add(sig_int(1), sig_int(2)))
        result = simplify_to_normal_form2(sv)
        assert result is not None


# ---------------------------------------------------------------------------
# Interval
# ---------------------------------------------------------------------------


class TestInterval:
    def test_create(self):
        iv = Interval(0.0, 1.0, 0)
        assert iv.low == 0.0
        assert iv.high == 1.0
        assert iv.lsb == 0.0

    def test_negative_range(self):
        iv = Interval(-1.0, 1.0, 0)
        assert iv.low == -1.0
        assert iv.high == 1.0


# ---------------------------------------------------------------------------
# SignalVector
# ---------------------------------------------------------------------------


class TestSignalVector:
    def test_create_and_add(self):
        sv = SignalVector()
        sv.add(sig_int(1))
        sv.add(sig_real(2.0))
        count = sum(1 for _ in sv)
        assert count == 2

    def test_iteration(self):
        sv = SignalVector()
        sv.add(sig_int(10))
        sv.add(sig_int(20))
        signals = list(sv)
        assert len(signals) == 2

    def test_create_source(self):
        sv = SignalVector()
        sv.add(sig_real(42.0))
        code = sv.create_source("test_dsp", "cpp")
        assert isinstance(code, str)
        assert "class mydsp : public dsp" in code

    def test_create_source_c(self):
        sv = SignalVector()
        sv.add(sig_input(0))
        code = sv.create_source("test_dsp", "c")
        assert isinstance(code, str)
        assert len(code) > 0

    def test_simplify(self):
        sv = SignalVector()
        sv.add(sig_add(sig_int(1), sig_int(2)))
        result = sv.simplify_to_normal_form()
        assert result is not None


# ---------------------------------------------------------------------------
# Source generation and factory creation
# ---------------------------------------------------------------------------


class TestSourceGeneration:
    def test_create_source_from_signals_cpp(self):
        sv = SignalVector()
        sv.add(sig_mul(sig_input(0), sig_real(0.5)))
        code = create_source_from_signals("gain", sv, "cpp")
        assert code is not None
        assert "class mydsp : public dsp" in code

    def test_create_source_from_signals_c(self):
        sv = SignalVector()
        sv.add(sig_mul(sig_input(0), sig_real(0.5)))
        code = create_source_from_signals("gain", sv, "c")
        assert code is not None
        assert len(code) > 0

    def test_create_dsp_factory(self):
        sv = SignalVector()
        sv.add(sig_mul(sig_input(0), sig_real(0.5)))
        factory = create_dsp_factory_from_signals("gain", sv)
        assert factory is not None
        dsp = factory.create_dsp_instance()
        assert dsp is not None
        dsp.init(44100)
        assert dsp.get_numinputs() == 1
        assert dsp.get_numoutputs() == 1

    def test_create_dsp_factory_stereo(self):
        sv = SignalVector()
        sv.add(sig_mul(sig_input(0), sig_real(0.5)))
        sv.add(sig_mul(sig_input(1), sig_real(0.5)))
        factory = create_dsp_factory_from_signals("stereo_gain", sv)
        assert factory is not None
        dsp = factory.create_dsp_instance()
        dsp.init(44100)
        assert dsp.get_numinputs() == 2
        assert dsp.get_numoutputs() == 2


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------


class TestEnums:
    def test_stype_values(self):
        assert int(SType.kSInt) == 0
        assert int(SType.kSReal) == 1

    def test_soperator_values(self):
        assert int(SOperator.kAdd) == 0
        assert int(SOperator.kSub) == 1
        assert int(SOperator.kMul) == 2
        assert int(SOperator.kDiv) == 3
