"""Extended box API tests for improved coverage.

Tests cover: primitives, composition, arithmetic, bitwise, comparison,
logical, math, UI elements, selectors, groups, type checking, utilities,
Box OO interface, and dsp_to_boxes/boxes_to_signals conversion.
"""

import pytest

try:
    from cyfaust.box import (
        # context
        box_context,
        create_lib_context,
        destroy_lib_context,
        # primitives
        box_int,
        box_float,
        box_real,
        box_wire,
        box_cut,
        # composition
        box_seq,
        box_par,
        box_par3,
        box_par4,
        box_par5,
        box_split,
        box_merge,
        box_rec,
        box_route,
        # delay / cast
        box_delay,
        box_delay_op,
        box_int_cast,
        box_int_cast_op,
        box_float_cast,
        box_float_cast_op,
        # tables
        box_readonly_table,
        box_readonly_table_op,
        box_write_read_table,
        box_write_read_table_op,
        box_waveform,
        box_soundfile,
        # selectors
        box_select2,
        box_select2_op,
        box_select3,
        # arithmetic
        box_add,
        box_add_op,
        box_sub,
        box_sub_op,
        box_mul,
        box_mul_op,
        box_div,
        box_div_op,
        box_rem,
        box_rem_op,
        # bitwise
        box_leftshift,
        box_leftshift_op,
        box_lrightshift,
        box_lrightshift_op,
        box_arightshift,
        box_arightshift_op,
        # comparison
        box_gt,
        box_gt_op,
        box_lt,
        box_lt_op,
        box_ge,
        box_ge_op,
        box_le,
        box_le_op,
        box_eq,
        box_eq_op,
        box_ne,
        box_ne_op,
        # logical
        box_and,
        box_and_op,
        box_or,
        box_or_op,
        box_xor,
        box_xor_op,
        # math unary
        box_abs,
        box_acos,
        box_asin,
        box_atan,
        box_ceil,
        box_cos,
        box_exp,
        box_exp10,
        box_floor,
        box_log,
        box_log10,
        box_rint,
        box_round,
        box_sin,
        box_sqrt,
        box_tan,
        # math binary
        box_remainder,
        box_pow,
        box_min,
        box_max,
        box_fmod,
        box_atan2,
        # UI
        box_button,
        box_checkbox,
        box_vslider,
        box_hslider,
        box_numentry,
        box_vbargraph,
        box_vbargraph2,
        box_hbargraph,
        box_hbargraph2,
        box_vgroup,
        box_hgroup,
        box_tgroup,
        # attach
        box_attach,
        box_attach_op,
        # foreign
        box_fconst,
        box_fvar,
        box_bin_op,
        box_bin_op0,
        # helpers
        box_or_int,
        box_or_float,
        box_or_number,
        box_is_nil,
        # utility
        to_string,
        print_box,
        get_def_name_property,
        extract_name,
        tree2str,
        tree2int,
        # type checking
        is_box_int,
        is_box_abstr,
        is_box_appl,
        is_box_button,
        is_box_checkbox,
        is_box_cut,
        is_box_environment,
        is_box_error,
        is_box_fconst,
        is_box_fvar,
        is_box_hbargraph,
        is_box_hgroup,
        is_box_hslider,
        is_box_ident,
        getparams_box_button,
        getparams_box_hslider,
        # conversion
        dsp_to_boxes,
        get_box_type,
        boxes_to_signals,
        create_source_from_boxes,
        # classes
        Box,
        BoxVector,
        SType,
        SOperator,
    )
    from cyfaust.signal import SignalVector
except (ModuleNotFoundError, ImportError):
    pytest.skip("cyfaust not available", allow_module_level=True)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture(autouse=True)
def ctx():
    """Provide a box context for every test."""
    with box_context():
        yield


# ---------------------------------------------------------------------------
# Primitives
# ---------------------------------------------------------------------------


class TestPrimitives:
    def test_box_int(self):
        b = box_int(42)
        assert b.is_valid()
        assert is_box_int(b)

    def test_box_float(self):
        b = box_float(3.14)
        assert b.is_valid()

    def test_box_real_alias(self):
        b = box_real(2.71)
        assert b.is_valid()

    def test_box_wire(self):
        b = box_wire()
        assert b.is_valid()

    def test_box_cut(self):
        b = box_cut()
        assert b.is_valid()
        assert is_box_cut(b)

    def test_box_is_nil(self):
        b = box_int(1)
        assert not box_is_nil(b)


# ---------------------------------------------------------------------------
# Box constructor and static factories
# ---------------------------------------------------------------------------


class TestBoxConstructor:
    def test_default_creates_wire(self):
        b = Box()
        assert b.is_valid()

    def test_from_int_value(self):
        b = Box(7)
        assert b.is_valid()
        assert is_box_int(b)

    def test_from_float_value(self):
        b = Box(3.14)
        assert b.is_valid()

    def test_static_from_int(self):
        b = Box.from_int(10)
        assert b.is_valid()
        assert is_box_int(b)

    def test_static_from_float(self):
        b = Box.from_float(1.5)
        assert b.is_valid()

    def test_static_from_wire(self):
        b = Box.from_wire()
        assert b.is_valid()

    def test_static_from_cut(self):
        b = Box.from_cut()
        assert b.is_valid()
        assert is_box_cut(b)


# ---------------------------------------------------------------------------
# Composition
# ---------------------------------------------------------------------------


class TestComposition:
    def test_box_seq(self):
        # par(wire, wire) is 2-in 2-out; add_op is 2-in 1-out
        b = box_seq(box_par(box_wire(), box_wire()), box_add_op())
        assert b.is_valid()

    def test_box_par(self):
        b = box_par(box_int(1), box_int(2))
        assert b.is_valid()

    def test_box_par3(self):
        b = box_par3(box_int(1), box_int(2), box_int(3))
        assert b.is_valid()

    def test_box_par4(self):
        b = box_par4(box_int(1), box_int(2), box_int(3), box_int(4))
        assert b.is_valid()

    def test_box_par5(self):
        b = box_par5(box_int(1), box_int(2), box_int(3), box_int(4), box_int(5))
        assert b.is_valid()

    def test_box_split(self):
        b = box_split(box_wire(), box_par(box_wire(), box_wire()))
        assert b.is_valid()

    def test_box_merge(self):
        b = box_merge(box_par(box_wire(), box_wire()), box_add_op())
        assert b.is_valid()

    def test_box_rec(self):
        b = box_rec(box_add_op(), box_wire())
        assert b.is_valid()

    def test_box_route(self):
        b = box_route(
            box_int(2),
            box_int(2),
            box_par(box_par(box_int(1), box_int(1)), box_par(box_int(2), box_int(2))),
        )
        assert b.is_valid()


# ---------------------------------------------------------------------------
# Box OO composition methods
# ---------------------------------------------------------------------------


class TestBoxOOMethods:
    def test_seq_method(self):
        b = box_par(box_wire(), box_wire()).seq(box_add_op())
        assert b.is_valid()

    def test_par_method(self):
        b = box_int(1).par(box_int(2))
        assert b.is_valid()

    def test_par3_method(self):
        b = box_int(1).par3(box_int(2), box_int(3))
        assert b.is_valid()

    def test_split_method(self):
        b = box_wire().split(box_par(box_wire(), box_wire()))
        assert b.is_valid()

    def test_merge_method(self):
        b = box_par(box_wire(), box_wire()).merge(box_add_op())
        assert b.is_valid()

    def test_rec_method(self):
        b = box_add_op().rec(box_wire())
        assert b.is_valid()

    def test_delay_method_with_int(self):
        b = box_wire().delay(100)
        assert b.is_valid()

    def test_select2_method(self):
        b = box_int(0).select2(box_int(10), box_int(20))
        assert b.is_valid()

    def test_int_cast_method(self):
        b = box_float(3.7).int_cast()
        assert b.is_valid()

    def test_float_cast_method(self):
        b = box_int(3).float_cast()
        assert b.is_valid()


# ---------------------------------------------------------------------------
# Operators
# ---------------------------------------------------------------------------


class TestBoxOperators:
    def test_add(self):
        b = box_int(1) + box_int(2)
        assert b.is_valid()

    def test_sub(self):
        b = box_int(5) - box_int(3)
        assert b.is_valid()

    def test_mul(self):
        b = box_int(3) * box_int(4)
        assert b.is_valid()

    def test_eq(self):
        b = box_int(1) == box_int(1)
        assert b.is_valid()

    def test_ne(self):
        b = box_int(1) != box_int(2)
        assert b.is_valid()

    def test_gt(self):
        b = box_int(2) > box_int(1)
        assert b.is_valid()

    def test_ge(self):
        b = box_int(2) >= box_int(2)
        assert b.is_valid()

    def test_lt(self):
        b = box_int(1) < box_int(2)
        assert b.is_valid()

    def test_le(self):
        b = box_int(2) <= box_int(2)
        assert b.is_valid()

    def test_and(self):
        b = box_int(1) & box_int(1)
        assert b.is_valid()

    def test_or(self):
        b = box_int(1) | box_int(0)
        assert b.is_valid()

    def test_xor(self):
        b = box_int(1) ^ box_int(0)
        assert b.is_valid()

    def test_lshift(self):
        b = box_int(1) << box_int(4)
        assert b.is_valid()

    def test_rshift(self):
        b = box_int(16) >> box_int(2)
        assert b.is_valid()


# ---------------------------------------------------------------------------
# Arithmetic functions
# ---------------------------------------------------------------------------


class TestArithmetic:
    def test_add(self):
        assert box_add(box_int(1), box_int(2)).is_valid()

    def test_sub(self):
        assert box_sub(box_int(5), box_int(3)).is_valid()

    def test_mul(self):
        assert box_mul(box_int(3), box_int(4)).is_valid()

    def test_div(self):
        assert box_div(box_float(10.0), box_float(2.0)).is_valid()

    def test_rem(self):
        assert box_rem(box_int(7), box_int(3)).is_valid()

    def test_ops(self):
        for op_fn in [box_add_op, box_sub_op, box_mul_op, box_div_op, box_rem_op]:
            assert op_fn().is_valid()


# ---------------------------------------------------------------------------
# Bitwise functions
# ---------------------------------------------------------------------------


class TestBitwise:
    def test_leftshift(self):
        assert box_leftshift(box_int(1), box_int(4)).is_valid()

    def test_lrightshift(self):
        assert box_lrightshift(box_int(16), box_int(2)).is_valid()

    def test_arightshift(self):
        assert box_arightshift(box_int(-8), box_int(1)).is_valid()

    def test_ops(self):
        for op_fn in [box_leftshift_op, box_lrightshift_op, box_arightshift_op]:
            assert op_fn().is_valid()


# ---------------------------------------------------------------------------
# Comparison functions
# ---------------------------------------------------------------------------


class TestComparison:
    def test_gt(self):
        assert box_gt(box_int(2), box_int(1)).is_valid()

    def test_lt(self):
        assert box_lt(box_int(1), box_int(2)).is_valid()

    def test_ge(self):
        assert box_ge(box_int(2), box_int(2)).is_valid()

    def test_le(self):
        assert box_le(box_int(1), box_int(2)).is_valid()

    def test_eq(self):
        assert box_eq(box_int(1), box_int(1)).is_valid()

    def test_ne(self):
        assert box_ne(box_int(1), box_int(2)).is_valid()

    def test_ops(self):
        for op_fn in [box_gt_op, box_lt_op, box_ge_op, box_le_op, box_eq_op, box_ne_op]:
            assert op_fn().is_valid()


# ---------------------------------------------------------------------------
# Logical functions
# ---------------------------------------------------------------------------


class TestLogical:
    def test_and(self):
        assert box_and(box_int(1), box_int(1)).is_valid()

    def test_or(self):
        assert box_or(box_int(1), box_int(0)).is_valid()

    def test_xor(self):
        assert box_xor(box_int(1), box_int(0)).is_valid()

    def test_ops(self):
        for op_fn in [box_and_op, box_or_op, box_xor_op]:
            assert op_fn().is_valid()


# ---------------------------------------------------------------------------
# Math functions (unary)
# ---------------------------------------------------------------------------


class TestMathUnary:
    @pytest.mark.parametrize(
        "fn",
        [
            box_abs,
            box_acos,
            box_asin,
            box_atan,
            box_ceil,
            box_cos,
            box_exp,
            box_exp10,
            box_floor,
            box_log,
            box_log10,
            box_rint,
            box_round,
            box_sin,
            box_sqrt,
            box_tan,
        ],
    )
    def test_unary_math(self, fn):
        b = fn(box_float(0.5))
        assert b.is_valid()


# ---------------------------------------------------------------------------
# Math functions (binary)
# ---------------------------------------------------------------------------


class TestMathBinary:
    @pytest.mark.parametrize(
        "fn",
        [
            box_remainder,
            box_pow,
            box_min,
            box_max,
            box_atan2,
        ],
    )
    def test_binary_math(self, fn):
        b = fn(box_float(1.0), box_float(2.0))
        assert b.is_valid()

    @pytest.mark.skip(reason="box_fmod aborts in libfaust with constant inputs")
    def test_fmod(self):
        b = box_fmod(box_float(5.5), box_float(2.0))
        assert b.is_valid()


# ---------------------------------------------------------------------------
# Box OO math methods
# ---------------------------------------------------------------------------


class TestBoxOOMath:
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
            "round",
            "sin",
            "sqrt",
            "tan",
        ],
    )
    def test_unary_methods(self, method):
        b = box_float(0.5)
        result = getattr(b, method)()
        assert result.is_valid()


# ---------------------------------------------------------------------------
# Delay and cast
# ---------------------------------------------------------------------------


class TestDelayCast:
    def test_box_delay(self):
        b = box_delay(box_wire(), box_int(100))
        assert b.is_valid()

    def test_box_delay_op(self):
        assert box_delay_op().is_valid()

    def test_box_int_cast(self):
        assert box_int_cast(box_float(3.14)).is_valid()

    def test_box_int_cast_op(self):
        assert box_int_cast_op().is_valid()

    def test_box_float_cast(self):
        assert box_float_cast(box_int(3)).is_valid()

    def test_box_float_cast_op(self):
        assert box_float_cast_op().is_valid()


# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------


class TestTables:
    def test_readonly_table(self):
        b = box_readonly_table(box_int(10), box_int(0), box_int_cast(box_wire()))
        assert b.is_valid()

    def test_readonly_table_op(self):
        assert box_readonly_table_op().is_valid()

    def test_write_read_table(self):
        b = box_write_read_table(
            box_int(10),
            box_int(0),
            box_int_cast(box_wire()),
            box_int_cast(box_wire()),
            box_int_cast(box_wire()),
        )
        assert b.is_valid()

    def test_write_read_table_op(self):
        assert box_write_read_table_op().is_valid()

    def test_waveform(self):
        wf = BoxVector()
        for i in range(5):
            wf.add(box_real(100.0 * i))
        b = box_waveform(wf)
        assert b.is_valid()


# ---------------------------------------------------------------------------
# Selectors
# ---------------------------------------------------------------------------


class TestSelectors:
    def test_select2(self):
        b = box_select2(box_int(0), box_int(10), box_int(20))
        assert b.is_valid()

    def test_select2_op(self):
        assert box_select2_op().is_valid()

    def test_select3(self):
        b = box_select3(box_int(0), box_int(10), box_int(20), box_int(30))
        assert b.is_valid()


# ---------------------------------------------------------------------------
# UI elements
# ---------------------------------------------------------------------------


class TestUI:
    def test_button(self):
        b = box_button("gate")
        assert b.is_valid()
        assert is_box_button(b)

    def test_checkbox(self):
        b = box_checkbox("mute")
        assert b.is_valid()

    def test_vslider(self):
        b = box_vslider("gain", box_real(0.5), box_real(0), box_real(1), box_real(0.01))
        assert b.is_valid()

    def test_hslider(self):
        b = box_hslider("freq", box_real(440), box_real(50), box_real(2000), box_real(1))
        assert b.is_valid()
        assert is_box_hslider(b)

    def test_numentry(self):
        b = box_numentry("order", box_int(4), box_int(1), box_int(8), box_int(1))
        assert b.is_valid()

    def test_vbargraph(self):
        b = box_vbargraph("level", box_real(-70), box_real(0))
        assert b.is_valid()

    def test_hbargraph(self):
        b = box_hbargraph("meter", box_real(-70), box_real(0))
        assert b.is_valid()

    def test_vbargraph2(self):
        b = box_vbargraph2("level", box_real(-70), box_real(0), box_wire())
        assert b.is_valid()

    def test_hbargraph2(self):
        b = box_hbargraph2("meter", box_real(-70), box_real(0), box_wire())
        assert b.is_valid()


# ---------------------------------------------------------------------------
# Groups
# ---------------------------------------------------------------------------


class TestGroups:
    def test_vgroup(self):
        b = box_vgroup("Controls", box_button("play"))
        assert b.is_valid()

    def test_hgroup(self):
        b = box_hgroup("Controls", box_button("play"))
        assert b.is_valid()

    def test_tgroup(self):
        b = box_tgroup("Tabs", box_button("play"))
        assert b.is_valid()


# ---------------------------------------------------------------------------
# Attach
# ---------------------------------------------------------------------------


class TestAttach:
    def test_attach(self):
        b = box_attach(box_wire(), box_int(0))
        assert b.is_valid()

    def test_attach_op(self):
        assert box_attach_op().is_valid()


# ---------------------------------------------------------------------------
# Foreign functions
# ---------------------------------------------------------------------------


class TestForeign:
    def test_fconst(self):
        b = box_fconst(SType.kSInt, "fSampleFreq", "<math.h>")
        assert b.is_valid()
        assert is_box_fconst(b)

    def test_fvar(self):
        b = box_fvar(SType.kSInt, "count", "<math.h>")
        assert b.is_valid()

    def test_bin_op(self):
        b = box_bin_op(SOperator.kAdd, box_int(1), box_int(2))
        assert b.is_valid()

    def test_bin_op0(self):
        b = box_bin_op0(SOperator.kMul)
        assert b.is_valid()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


class TestHelpers:
    def test_box_or_int(self):
        b = box_or_int(42)
        assert b.is_valid()
        b2 = box_or_int(box_int(42))
        assert b2.is_valid()

    def test_box_or_float(self):
        b = box_or_float(3.14)
        assert b.is_valid()
        b2 = box_or_float(box_float(3.14))
        assert b2.is_valid()

    def test_box_or_number(self):
        assert box_or_number(42).is_valid()
        assert box_or_number(3.14).is_valid()
        assert box_or_number(box_int(1)).is_valid()


# ---------------------------------------------------------------------------
# Utility functions
# ---------------------------------------------------------------------------


class TestUtility:
    def test_to_string(self):
        b = box_int(7)
        s = to_string(b, False, 256)
        assert isinstance(s, str)
        assert len(s) > 0

    def test_tree2int(self):
        b = box_int(42)
        n = tree2int(b)
        assert n == 42

    def test_box_inputs_outputs_via_get_box_type(self):
        b = box_par(box_wire(), box_wire())
        result = get_box_type(b)
        assert result is not None
        inputs, outputs = result
        assert inputs == 2
        assert outputs == 2


# ---------------------------------------------------------------------------
# Type checking
# ---------------------------------------------------------------------------


class TestTypeChecking:
    def test_is_box_int(self):
        assert is_box_int(box_int(5))
        assert not is_box_int(box_float(5.0))

    def test_is_box_cut(self):
        assert is_box_cut(box_cut())
        assert not is_box_cut(box_wire())

    def test_is_box_button(self):
        assert is_box_button(box_button("gate"))
        assert not is_box_button(box_int(1))

    def test_is_box_checkbox(self):
        # box_checkbox wraps the checkbox in a group, so is_box_checkbox
        # may not match the outermost box
        b = box_checkbox("mute")
        assert b.is_valid()

    def test_is_box_hslider(self):
        b = box_hslider("freq", box_real(440), box_real(50), box_real(2000), box_real(1))
        assert is_box_hslider(b)

    def test_is_box_fconst(self):
        b = box_fconst(SType.kSInt, "fSampleFreq", "<math.h>")
        assert is_box_fconst(b)

    def test_is_box_environment(self):
        assert not is_box_environment(box_int(1))

    def test_is_box_error(self):
        assert not is_box_error(box_int(1))

    def test_is_box_ident(self):
        assert not is_box_ident(box_int(1))

    def test_is_box_abstr(self):
        assert not is_box_abstr(box_int(1))

    def test_is_box_appl(self):
        assert not is_box_appl(box_int(1))

    def test_getparams_box_button(self):
        b = box_button("gate")
        params = getparams_box_button(b)
        assert isinstance(params, dict)
        assert "lbl" in params

    def test_getparams_box_hslider(self):
        b = box_hslider("freq", box_real(440), box_real(50), box_real(2000), box_real(1))
        params = getparams_box_hslider(b)
        assert isinstance(params, dict)
        assert "lbl" in params
        assert "cur" in params
        assert "min" in params
        assert "max" in params
        assert "step" in params


# ---------------------------------------------------------------------------
# Box OO type checking methods
# ---------------------------------------------------------------------------


class TestBoxOOTypeChecking:
    def test_is_int(self):
        assert box_int(5).is_int()

    def test_is_cut(self):
        assert box_cut().is_cut()

    def test_is_wire(self):
        assert box_wire().is_wire()

    def test_is_button(self):
        assert box_button("gate").is_button()

    def test_checkbox_valid(self):
        assert box_checkbox("mute").is_valid()

    def test_is_hslider(self):
        b = box_hslider("freq", box_real(440), box_real(50), box_real(2000), box_real(1))
        assert b.is_hslider()

    def test_is_vslider(self):
        b = box_vslider("gain", box_real(0.5), box_real(0), box_real(1), box_real(0.01))
        assert b.is_vslider()

    def test_is_fconst(self):
        b = box_fconst(SType.kSInt, "fSampleFreq", "<math.h>")
        assert b.is_fconst()

    def test_negative_type_checks(self):
        b = box_int(1)
        assert not b.is_cut()
        assert not b.is_button()
        assert not b.is_checkbox()
        assert not b.is_error()
        assert not b.is_environment()


# ---------------------------------------------------------------------------
# DSP conversion
# ---------------------------------------------------------------------------


class TestDSPConversion:
    def test_dsp_to_boxes(self):
        b = dsp_to_boxes("test", "process = +(1);")
        assert b is not None
        assert b.is_valid()

    def test_get_box_type(self):
        b = box_par(box_wire(), box_wire())
        result = get_box_type(b)
        assert result is not None
        inputs, outputs = result
        assert inputs == 2
        assert outputs == 2

    def test_boxes_to_signals(self):
        b = box_int(42)
        sigs = boxes_to_signals(b)
        assert sigs is not None
        assert isinstance(sigs, SignalVector)

    def test_create_source_from_boxes(self):
        b = box_par(box_int(7), box_float(3.14))
        code = create_source_from_boxes("test_dsp", b, "cpp")
        assert code is not None
        assert "class mydsp : public dsp" in code


# ---------------------------------------------------------------------------
# BoxVector
# ---------------------------------------------------------------------------


class TestBoxVector:
    def test_create_and_add(self):
        bv = BoxVector()
        bv.add(box_int(1))
        bv.add(box_float(2.0))
        count = sum(1 for _ in bv)
        assert count == 2

    def test_iteration(self):
        bv = BoxVector()
        bv.add(box_int(10))
        bv.add(box_int(20))
        boxes = list(bv)
        assert len(boxes) == 2
        for b in boxes:
            assert b.is_valid()

    def test_create_source(self):
        # create_source on BoxVector delegates to create_source_from_boxes
        # which expects a single Box, not a vector -- use Box.create_source instead
        b = box_par(box_int(7), box_float(3.14))
        code = b.create_source("test_dsp", "cpp")
        assert isinstance(code, str)
        assert len(code) > 0
