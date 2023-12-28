import os, sys
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

print("CWD:", os.getcwd())

import time
from cyfaust import interp

from testutils import print_section


def test_cyfaust_interpreter():
    print("faust version:", interp.get_version())

    factory = interp.create_dsp_factory_from_file('tests/noise.dsp')

    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()

    # FIXME: doesn't work!!
    # ui = interp.PrintUI()
    # dsp.build_user_interface(ui)
    
    # bypass
    dsp.build_user_interface()

    audio = interp.RtAudioDriver(48000, 256)

    # audio.init("FaustDSP", dsp)
    audio.init(dsp)

    audio.start()
    time.sleep(1)
    # audio.stop() # not needed here


if __name__ == '__main__':
    print_section("testing cyfaust interpreter")
    test_cyfaust_interpreter()
