import os, sys, pathlib
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

try:
    from cyfaust.box import (
        create_source_from_boxes, BoxVector,
        box_add, box_add_op, box_mul,
        box_context, box_par, box_int, box_float, box_real,
        box_delay, box_hslider, box_vslider,
        box_max, box_int_cast,
        box_readonly_table, box_write_read_table,
        box_rec, box_min,
        box_soundfile, box_split, box_wire, 
        box_waveform, box_fconst, box_fvar
    )
    from cyfaust.signal import SignalVector, SType
    from cyfaust.interp import create_dsp_factory_from_boxes
    from cyfaust.common import PACKAGE_RESOURCES
except ImportError:
    from cyfaust.cyfaust import (
        create_source_from_boxes, BoxVector,
        box_add, box_add_op, box_mul,
        box_context, box_par, box_int, box_float, box_real,
        box_delay, box_hslider, box_vslider,
        box_max, box_int_cast,
        box_readonly_table, box_write_read_table,
        box_rec, box_min,
        box_soundfile, box_split, box_wire, 
        box_waveform, box_fconst, box_fvar,

        SignalVector, SType,
        create_dsp_factory_from_boxes,
        PACKAGE_RESOURCES
    )

from testutils import print_section, print_entry


def test_create_dsp_factory_from_boxes():
    print_entry("test_create_dsp_factory_from_boxes")
    with box_context():
        b = box_int(7).par(box_float(3.14))
        assert b.is_valid, "box is not valid"
        factory = create_dsp_factory_from_boxes("dspme", b)
        assert factory

        print("compile options:", factory.get_compile_options())
        print("library list:", factory.get_library_list())
        print("include pathnames:", factory.get_include_pathnames())

        print("factory name:", factory.get_name())
        print("factory key:", factory.get_sha_key())
    
        dsp = factory.create_dsp_instance()
        assert dsp

# functional way
def test_create_source_from_boxes():
    print_entry("test_create_source_from_boxes")
    with box_context():
        b = box_par(box_int(7), box_float(3.14))
        assert b.is_valid, "box is not valid"
        print(f'Box inputs: {b.inputs}, outputs: {b.outputs}')
        code = create_source_from_boxes("test_dsp", b, "cpp")
        assert len(code) == 1960
        assert "class mydsp : public dsp" in code
        # print(code)


# mixed functional / object-oriented wa
# note use of `par` abd `b.create_source()`
def test_box_create_source_cpp():
    print_entry("test_box_create_source_cpp")
    with box_context():
        b = box_int(7).par(box_float(3.14))
        assert b.is_valid, "box is not valid"
        print(f'Box inputs: {b.inputs}, outputs: {b.outputs}')
        code = b.create_source("test_dsp", "cpp")
        assert len(code) == 1960
        assert "class mydsp : public dsp" in code
        # print(code)

def test_box_create_source_c():
    print_entry("test_box_create_source_c")
    with box_context():
        b = box_int(7).par(box_float(3.14))
        assert b.is_valid, "box is not valid"
        print(f'Box inputs: {b.inputs}, outputs: {b.outputs}')
        code = b.create_source("test_dsp", "c")
        assert len(code) == 2305
        assert "mydsp* dsp = (mydsp*)calloc(1, sizeof(mydsp))" in code
        # print(code)

def test_box_create_source_codebox():
    print_entry("test_box_create_source_codebox")
    with box_context():
        b = box_int(7).par(box_float(3.14))
        assert b.is_valid, "box is not valid"
        print(f'Box inputs: {b.inputs}, outputs: {b.outputs}')
        code = b.create_source("test_dsp", "codebox")
        assert len(code) == 801
        assert "function dspsetup()" in code
        # print("code length:", len(code))
        print(code)

def test_box_create_source_rust():
    print_entry("test_box_create_source_rust")
    with box_context():
        b = box_int(7).par(box_float(3.14))
        assert b.is_valid, "box is not valid"
        print(f'Box inputs: {b.inputs}, outputs: {b.outputs}')
        code = b.create_source("test_dsp", "rust")
        assert len(code) == 2286
        assert "impl FaustDsp for mydsp" in code
        # print("code length:", len(code))
        print(code)

def test_box_split():
    print_entry("test_box_split")
    with box_context():
        b = box_split(
            box_wire(), 
            box_par(
                box_add(box_delay(box_wire(), box_real(500)), box_real(0.5)),
                box_mul(box_delay(box_wire(),box_real(3000)), box_real(1.5))))
        assert b.is_valid()
        b.print()

def test_box_hslider():
    print_entry("test_box_hslider")
    with box_context():
        b = box_mul(
            box_wire(), 
                 box_hslider("Freq [midi:ctrl 7][style:knob]", 
                    box_real(100), 
                    box_real(100), 
                    box_real(2000), 
                    box_real(1)))
        assert b.is_valid()
        b.print()

def test_box_vslider():
    print_entry("test_box_vslider")
    with box_context():
        b = box_mul(box_vslider("h:Oscillator/freq", 
                box_real(440), 
                box_real(50), 
                box_real(1000), 
                box_real(0.1)),
             box_vslider("h:Oscillator/gain", 
                box_real(0), 
                box_real(0), 
                box_real(1), 
                box_real(0.01)))
        assert b.is_valid()
        b.print()

def test_box_rec():
    print_entry("test_box_rec")
    with box_context():
        b = box_rec(box_add_op(), box_wire())
        assert b.is_valid()
        b.print()


def test_box_fconst():
    print_entry("test_box_fconst")
    def SR():
        return box_min(box_real(192000.0), 
            box_max(box_real(1.0), 
                box_fconst(SType.kSInt, "fSampleFreq", "<math.h>")))

    def BS():
        return box_fvar(SType.kSInt, "count", "<math.h>")
    with box_context():
        b = box_par(SR(), BS())
        assert b.is_valid()
        b.print()


def test_box_readonly_table():
    print_entry("test_box_readonly_table")
    with box_context():
        b = box_readonly_table(box_int(10), box_int(1), box_int_cast(box_wire()))
        assert b.is_valid()
        b.print()


def test_box_write_readonly_table():
    print_entry("test_box_write_readonly_table")
    with box_context():
        b = box_write_read_table(
            box_int(10), 
            box_int(1), 
            box_int_cast(box_wire()), 
            box_int_cast(box_wire()), 
            box_int_cast(box_wire()))
        assert b.is_valid()
        b.print()

def test_box_waveform():
    print_entry("test_box_waveform")
    with box_context():
        waveform = BoxVector()
        for i in range(5):
            waveform.add(box_real(100*i))
        b = box_waveform(waveform);
        assert b.is_valid()
        b.print()

def test_box_soundfile():
    print_entry("test_box_soundfile")
    with box_context():
        b = box_soundfile("sound[url:{'tango.wav'}]", 
            box_int(2),  
            box_int(0),  
            box_int(0))
        assert b.is_valid()
        b.print()

# test architectures
def test_box_create_source_cpp_arch():
    print_entry("test_box_create_source_cpp_arch")
    print("PACKAGE_RESOURCES:", PACKAGE_RESOURCES)
    with box_context():
        b = box_int(7).par(box_float(3.14))
        assert b.is_valid, "box is not valid"
        print(f'Box inputs: {b.inputs}, outputs: {b.outputs}')
        code = b.create_source("test_dsp", "cpp", "-a", "ca-qt.cpp")
        assert code
        # print("code length", len(code))
        # assert len(code) == 14007
        assert "BEGIN ARCHITECTURE SECTION" in code
        # print(code)


if __name__ == '__main__':
    print_section("testing cyfaust.box")
    if 'TRACE' in os.environ:
        import tracemalloc
    test_create_dsp_factory_from_boxes()
    test_create_source_from_boxes()
    test_box_create_source_cpp()
    test_box_create_source_c()
    test_box_create_source_codebox()
    test_box_create_source_rust()
    test_box_split()
    test_box_hslider()
    test_box_vslider()
    test_box_rec()
    test_box_fconst()
    test_box_readonly_table()
    test_box_write_readonly_table()
    test_box_waveform()
    test_box_soundfile()
    test_box_create_source_cpp_arch()
    if 'TRACE' in os.environ:
        print_entry("TRACEMALLOC ANALYSIS")
        snapshot = tracemalloc.take_snapshot()
        top_stats = snapshot.statistics('lineno')
        print("[ Top 10 ]")
        for stat in top_stats[:10]:
            print(stat)

