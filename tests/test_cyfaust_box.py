import os, sys
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

from cyfaust.box import *

from testutils import print_section, print_entry

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
def test_box_create_source():

    print_entry("test_box_create_source")

    with box_context():
        b = box_int(7).par(box_float(3.14))
        assert b.is_valid, "box is not valid"
        print(f'Box inputs: {b.inputs}, outputs: {b.outputs}')
        code = b.create_source("test_dsp", "cpp")
        assert len(code) == 1960
        assert "class mydsp : public dsp" in code
        # print(code)

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

    # Reproduce the 'BS' definition in platform.lib 
    # BS = fvariable(int count, <dummy.h>);
    def BS():
        return box_fvar(SType.kSInt, "count", "<math.h>")
    with box_context():
        b = box_par(SR(), BS())
        assert b.is_valid()
        b.print()






if __name__ == '__main__':
    print_section("testing cyfaust.box")
    test_create_source_from_boxes()
    test_box_create_source()
    test_box_split()
    test_box_hslider()
    test_box_vslider()
    test_box_rec()
    test_box_fconst()

