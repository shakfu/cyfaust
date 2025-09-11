import os
import sys


import time
import tempfile

try:
    from cyfaust.interp import (
        RtAudioDriver,
        InterpreterDspFactory,
        get_version, 
        create_dsp_factory_from_file,
        create_dsp_factory_from_string,
        create_dsp_factory_from_boxes,
        create_dsp_factory_from_signals,
        generate_auxfiles_from_string,
        get_all_dsp_factories,
        get_dsp_factory_from_sha_key,
        delete_all_dsp_factories,

        generate_sha1,
        expand_dsp_from_file,
        expand_dsp_from_string,
        generate_auxfiles_from_file,
    )
    from cyfaust.signal import (
        signal_context, SignalVector, 
        sig_input, sig_int, sig_delay, sig_real,
    )
    from cyfaust.box import (
        box_context, box_float, box_int,
    )
except (ModuleNotFoundError, ImportError):
    from cyfaust.cyfaust import (
        RtAudioDriver,
        create_dsp_factory_from_file,
        create_dsp_factory_from_string,
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

def dsp_from_string(testname, dsp_string, dump_to_bitcode=False,  skip_audio=False, *args):
    print_entry(testname)

    factory = create_dsp_factory_from_string("FaustDSP", dsp_string, *args)
    assert factory

    if dump_to_bitcode:
        factory.write_to_bitcode_file(TEMP_PATH)
        
    print("compile options:", factory.get_compile_options())
    print("library list:", factory.get_library_list())
    print("include pathnames:", factory.get_include_pathnames())
    print("name:", factory.get_name())
    print("sha key", factory.get_sha_key())

    dsp = factory.create_dsp_instance()
    assert dsp
    
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

def test_soundfile_from_file1():
    assert dsp_from_file(
        testname="test_soundfile_from_file1",
        dsp_path="tests/dsp/soundfile.dsp",
        skip_audio=False,
    )

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
    
    dsp.build_user_interface()

    if not SKIP_AUDIO:
        audio = RtAudioDriver(48000, 256)

        audio.init(dsp)

        audio.start()
        time.sleep(1)
        audio.stop()





