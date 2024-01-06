# import os, sys, pathlib
# BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
# sys.path.insert(0, BUILD_PATH)

# import pytest

# from cyfaust.box import *
# from cyfaust.signal import SignalVector
# from cyfaust.interp import create_dsp_factory_from_boxes

# from testutils import print_section, print_entry


# # test architectures
# @pytest.mark.skip(reason="architecture resource dependency not finalized")
# def test_box_create_source_cpp_arch():
#     print_entry("test_box_create_source_cpp")
#     with box_context():
#         b = box_int(7).par(box_float(3.14))
#         assert b.is_valid, "box is not valid"
#         print(f'Box inputs: {b.inputs}, outputs: {b.outputs}')
#         code = b.create_source("test_dsp", "cpp", "-a", "ca-qt.cpp", "-A", "./resources/architecture")
#         print("code length", len(code))
#         assert len(code) == 14007
#         assert "BEGIN ARCHITECTURE SECTION" in code
#         # print(code)


# if __name__ == '__main__':
#     print_section("testing cyfaust.box")
#     test_box_create_source_cpp_arch()


