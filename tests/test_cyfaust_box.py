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
        print(code)

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
        print(code)

if __name__ == '__main__':
    print_section("testing cyfaust.box")
    test_create_source_from_boxes()
    test_box_create_source()
