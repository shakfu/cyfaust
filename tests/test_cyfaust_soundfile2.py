import os

import time
import tempfile

try:
    from cyfaust.interp import (
        RtAudioDriver,
        create_dsp_factory_from_file,
        create_dsp_factory_from_string,
        get_all_dsp_factories,
    )
except (ModuleNotFoundError, ImportError):
    from cyfaust.cyfaust import (
        RtAudioDriver,
        create_dsp_factory_from_file,
        create_dsp_factory_from_string,
        get_all_dsp_factories,
    )

from testutils import print_entry

TEMP_DIR = tempfile.gettempdir()
TEMP_PATH = os.path.join(TEMP_DIR, "FaustDSP.fbc")

# FIXME:
# if audio is skipped, avoids occassional errors
# probably due to audio buffers to being cleaned up properly
# investigate further!
SKIP_AUDIO = False


## ---------------------------------------------------------------------------
## utility testing functions

def dsp_from_file(testname, dsp_path, skip_audio=False, *args):

    print_entry(testname)

    factory = create_dsp_factory_from_file(dsp_path, *args)
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

    if not skip_audio:
        audio = RtAudioDriver(48000, 256)

        audio.init(dsp)

        audio.start()
        time.sleep(1)
        audio.stop()

    return True


## ---------------------------------------------------------------------------
## faust/dsp/interpreter-dsp


def test_interp_create_dsp_factory_from_string2():
    print_entry("test_interp_create_dsp_factory_from_string2")

    factory = create_dsp_factory_from_string("FaustDSP", 
        """process = 0,0 : soundfile("sound[url:{'tests/wav/amen.wav'}]", 0);""")
    assert factory
        
    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("include pathnames:", factory.get_include_pathnames())
    print("name:", factory.get_name())
    print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()
    assert dsp

def test_get_all_dsp_factories():
    print_entry("test_get_all_dsp_factories")

    factory = create_dsp_factory_from_string("FaustDSP", 
        """process = 0,0 : soundfile("sound[url:{'tests/amen.wav'}]", 0);""")
    assert factory
        
    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("include pathnames:", factory.get_include_pathnames())
    print("name:", factory.get_name())
    print("sha key", factory.get_sha_key())

    assert get_all_dsp_factories()
    print(get_all_dsp_factories())


def test_soundfile_from_file1():
    assert dsp_from_file(
        testname="test_soundfile_from_file1",
        dsp_path="tests/dsp/soundfile.dsp",
        skip_audio=False,
    )

