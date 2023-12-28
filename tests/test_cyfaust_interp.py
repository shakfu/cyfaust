import os, sys
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

print("CWD:", os.getcwd())

import time
from cyfaust import interp

from testutils import print_section, print_entry

TEMP_PATH = "/tmp/FaustDSP.fbc"


def test_interp_from_file():
    print_entry("test_interp_from_file")

    print("faust version:", interp.get_version())

    factory = interp.create_dsp_factory_from_file('tests/noise.dsp')

    assert factory
    
    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()

    assert dsp

    # FIXME: doesn't work!!
    # ui = interp.PrintUI()
    # dsp.build_user_interface(ui)
    
    # bypass
    dsp.build_user_interface()

    audio = interp.RtAudioDriver(48000, 256)

    audio.init(dsp)

    audio.start()
    time.sleep(1)
    # audio.stop() # not needed here



def test_interp_from_string():
    print_entry("test_interp_from_string")

    # For bitcode file write/read test
    

    factory = interp.create_dsp_factory_from_string("FaustDSP", "process = 0.5,0.6;")

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

    audio = interp.RtAudioDriver(48000, 256)

    audio.init(dsp)

    audio.start()
    time.sleep(1)

def test_interp_warning_message():
    print_entry("test_interp_warning_message")

    warn_code = "process = rwtable(10, 10.0, idx, _, idx) with { idx = +(1)~_; };"

    factory = interp.create_dsp_factory_from_string("FaustDSP", warn_code, "-wall")

    assert factory

    print("compile options:", factory.get_compile_options())
    print("warning msgs:", factory.get_warning_messages())

def test_interp_from_bitcode_file():
    print_entry("test_interp_from_bitcode_file")

    factory = interp.InterpreterDspFactory.from_bitcode_file(TEMP_PATH)

    assert factory

    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("include pathnames:", factory.get_include_pathnames())

    print("factory name:", factory.get_name())
    print("factory key:", factory.get_sha_key())
        
    dsp = factory.create_dsp_instance()

    assert dsp

    # bypass
    # dsp.build_user_interface()

    audio = interp.RtAudioDriver(48000, 256)

    audio.init(dsp)

    audio.start()
    time.sleep(1)
    


if __name__ == '__main__':
    print_section("testing cyfaust.interp")
    test_interp_from_file()
    test_interp_from_string()
    test_interp_warning_message()
    test_interp_from_bitcode_file()


