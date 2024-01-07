import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build'))

import time
from pathlib import Path

try:
    from cyfaust.interp import *
except ImportError:
    from cyfaust import *

from testutils import print_section, print_entry

TEMP_PATH = "/tmp/FaustDSP.fbc"

# def test_generate_sha1():
# def test_expand_dsp_from_file():
# def test_expand_dsp_from_string():
# def test_generate_auxfiles_from_file():

## ---------------------------------------------------------------------------
## faust/dsp/interpreter-dsp
##

# def test_get_dsp_factory_from_sha_key():
# def test_create_dsp_factory_from_signals():
# def test_delete_all_dsp_factories():
# def test_get_all_dsp_factories():
# def test_read_dsp_factory_from_bitcode():


def test_interp_version():
    print_entry("test_interp_version")

    assert get_version()

def test_interp_create_dsp_factory_from_file():
    print_entry("test_interp_create_dsp_factory_from_file")

    print("faust version:", get_version())

    factory = create_dsp_factory_from_file('tests/noise.dsp')

    assert factory
    
    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()

    assert dsp

    # FIXME: doesn't work!!
    # ui = PrintUI()
    # dsp.build_user_interface(ui)
    
    # bypass
    dsp.build_user_interface()

    audio = RtAudioDriver(48000, 256)

    audio.init(dsp)

    audio.start()
    time.sleep(1)
    # audio.stop() # not needed here

def test_interp_create_dsp_factory_from_string1():
    print_entry("test_interp_create_dsp_factory_from_string1")

    # For bitcode file write/read test
    

    factory = create_dsp_factory_from_string("FaustDSP", "process = 0.5,0.6;")

    assert factory

    factory.write_to_bitcode_file(TEMP_PATH)
        
    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("include pathnames:", factory.get_include_pathnames())
    print("name:", factory.get_name())
    print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()

    assert dsp
    
    dsp.build_user_interface()

    audio = RtAudioDriver(48000, 256)

    audio.init(dsp)

    audio.start()
    time.sleep(1)

def test_interp_create_dsp_factory_from_string2():
    print_entry("test_interp_create_dsp_factory_from_string2")

    factory = create_dsp_factory_from_string("FaustDSP", 
        """process = 0,0 : soundfile("sound[url:{'tests/amen.wav'}]", 0);""")

    assert factory
        
    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("include pathnames:", factory.get_include_pathnames())
    print("name:", factory.get_name())
    print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()

    assert dsp
    
    dsp.build_user_interface()

    audio = RtAudioDriver(48000, 256)

    audio.init(dsp)

    audio.start()
    # FIXME: sleep causes crash!
    # time.sleep(1)
    # audio.stop() 

def test_interp_warning_message():
    print_entry("test_interp_warning_message")

    warn_code = "process = rwtable(10, 10.0, idx, _, idx) with { idx = +(1)~_; };"

    factory = create_dsp_factory_from_string("FaustDSP", warn_code, "-wall")

    assert factory

    print("compile options:", factory.get_compile_options())
    print("warning msgs:", factory.get_warning_messages())

# def test_interp_read_dsp_factory_from_bitcode_file():
#     print_entry("test_interp_read_dsp_factory_from_bitcode_file")

#     factory = InterpreterDspFactory.from_bitcode_file(TEMP_PATH)

#     assert factory

#     print("compile options:", factory.get_compile_options())
#     print("library list:", factory.get_library_list())
#     print("include pathnames:", factory.get_include_pathnames())

#     print("factory name:", factory.get_name())
#     print("factory key:", factory.get_sha_key())
        
#     dsp = factory.create_dsp_instance()

#     assert dsp

#     # bypass
#     # dsp.build_user_interface()

#     audio = RtAudioDriver(48000, 256)

#     audio.init(dsp)

#     audio.start()
#     time.sleep(1)

# FIXME: control output location of svg file "-o out.svg" doesn't work  
# def test_interp_generate_auxfiles_from_string():
#     print_entry("test_interp_generate_auxfiles_from_string")
#     eg = "process = _,3.14 : +;"
#     assert generate_auxfiles_from_string("svgdsp", eg, "-svg")
#     svg_folder = Path("svgdsp-svg")
#     process_svg = svg_folder / "process.svg"
#     assert svg_folder.exists()
#     assert process_svg.exists()
#     process_svg.unlink()
#     svg_folder.rmdir()



if __name__ == '__main__':
    print_section("testing cyfaust.interp")
    test_interp_version()
    test_interp_create_dsp_factory_from_file()
    test_interp_create_dsp_factory_from_string1()
    test_interp_create_dsp_factory_from_string2()
    test_interp_warning_message()
    # test_interp_read_dsp_factory_from_bitcode_file()
    # test_interp_generate_auxfiles_from_string()


