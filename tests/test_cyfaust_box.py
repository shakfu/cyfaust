from cyfaust import *

# functional way
def test_create_source_from_boxes():
    with box_context():
        box = box_par(box_int(7), box_float(3.14))
        assert box.is_valid, "box is not valid"
        print(f'Box inputs: {box.inputs}, outputs: {box.outputs}')
        code = create_source_from_boxes("test_dsp", box, "cpp")
        assert len(code) == 1960
        assert "class mydsp : public dsp" in code
        print(code)

# mixed functional / object-oriented way
def test_box_create_source():
    with box_context():
        box = box_par(box_int(7), box_float(3.14))
        assert box.is_valid, "box is not valid"
        print(f'Box inputs: {box.inputs}, outputs: {box.outputs}')
        code = box.create_source("test_dsp", "cpp")
        assert len(code) == 1960
        assert "class mydsp : public dsp" in code
        print(code)

if __name__ == '__main__':
    test_create_source_from_boxes()
    test_box_create_source()
