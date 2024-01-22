import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build'))


import time
import shutil
from pathlib import Path

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
except (ModuleNotFoundError, ImportError) as err:
    from cyfaust.cyfaust import (
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

        signal_context, SignalVector, 
        sig_input, sig_int, sig_delay, sig_real,

        box_context, box_float, box_int,
    )

from testutils import print_section, print_entry

TEMP_PATH = "/tmp/FaustDSP.fbc"

# FIXME:
# if audio is skipped, avoids occassional errors
# probably due to audio buffers to being cleaned up properly
# investigate further!
SKIP_AUDIO = False


## ---------------------------------------------------------------------------
## utility testing functions

def dsp_from_file(testname, dsp_path, skip_audio=False):

    print_entry(testname)

    factory = create_dsp_factory_from_file(dsp_path)
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

def dsp_from_string(testname, dsp_string, dump_to_bitcode=False,  skip_audio=False):
    print_entry(testname)

    factory = create_dsp_factory_from_string("FaustDSP", dsp_string)
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


def test_interp_version():
    print_entry("test_interp_version")

    assert get_version()

def test_interp_create_dsp_factory_from_file1():
    assert dsp_from_file(
        testname="test_interp_create_dsp_factory_from_file1",
        dsp_path="tests/dsp/noise.dsp",
        skip_audio=SKIP_AUDIO,
    )


def test_interp_create_dsp_factory_from_file2():
    assert dsp_from_file(
        testname="test_interp_create_dsp_factory_from_file2",
        dsp_path="tests/dsp/osc.dsp",
        skip_audio=SKIP_AUDIO,
    )

def test_interp_create_dsp_factory_from_file2():
    assert dsp_from_file(
        testname="test_interp_create_dsp_factory_from_file3",
        dsp_path="tests/dsp/vco.dsp",
        skip_audio=SKIP_AUDIO,
    )

def test_interp_create_dsp_factory_from_string1():
    assert dsp_from_string(
        testname="test_interp_create_dsp_factory_from_string1",
        dsp_string="process = 0.5,0.6;",
        dump_to_bitcode=True,
        skip_audio=SKIP_AUDIO,
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
    
    # dsp.build_user_interface()

    # if not SKIP_AUDIO:
    #     audio = RtAudioDriver(48000, 256)

    #     audio.init(dsp)

    #     audio.start()
    #     # FIXME: sleep causes crash!
    #     time.sleep(1)
    #     audio.stop()


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

# FIXME: crashes for some reason!
# def test_delete_all_dsp_factories():
#     print_entry("test_delete_all_dsp_factories")

#     f1 = create_dsp_factory_from_string("FaustDSP", 
#         """process = 0,0 : soundfile("sound[url:{'tests/amen.wav'}]", 0);""")
#     assert f1

#     f2 = create_dsp_factory_from_string("FaustDSP", "process = 0.5,0.6;")
#     assert f2

#     assert len(get_all_dsp_factories()) == 2

#     delete_all_dsp_factories()

#     assert len(get_all_dsp_factories()) == 0

def test_get_dsp_factory_from_sha_key():
    print_entry("test_get_dsp_factory_from_sha_key")
    f1 = create_dsp_factory_from_string("FaustDSP", "process = 0.5,0.6;")
    assert f1
    key = get_all_dsp_factories()[0]
    assert isinstance(key, str)
    print(key)
    assert key
    f2 = get_dsp_factory_from_sha_key(key)
    assert f2


def test_interp_warning_message():
    print_entry("test_interp_warning_message")

    warn_code = "process = rwtable(10, 10.0, idx, _, idx) with { idx = +(1)~_; };"

    factory = create_dsp_factory_from_string("FaustDSP", warn_code, "-wall")
    assert factory

    print("compile options:", factory.get_compile_options())
    print("warning msgs:", factory.get_warning_messages())

def test_interp_read_dsp_factory_from_bitcode_file():
    print_entry("test_interp_read_dsp_factory_from_bitcode_file")

    factory = InterpreterDspFactory.from_bitcode_file(TEMP_PATH)
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

    if not SKIP_AUDIO:
        audio = RtAudioDriver(48000, 256)

        audio.init(dsp)

        audio.start()
        time.sleep(1)
        audio.stop()


# FIXME: control output location of svg file "-o out.svg" doesn't work  
def test_interp_generate_auxfiles_from_string():
    print_entry("test_interp_generate_auxfiles_from_string")
    eg = "process = _,3.14 : +;"
    assert generate_auxfiles_from_string("svgdsp", eg, "-svg", "-o", "/tmp/out.cpp")
    svg_folder = Path("svgdsp-svg")
    process_svg = svg_folder / "process.svg"
    assert svg_folder.exists()
    assert process_svg.exists()
    process_svg.unlink()
    svg_folder.rmdir()


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


def test_create_dsp_factory_from_signals1():
    print_entry("test_create_dsp_factory_from_signals1")
    with signal_context():
        sv = SignalVector()
        in1 = sig_input(0)
        sv.add(sig_delay(in1 + sig_real(0.5), sig_int(500)))
        sv.add(sig_delay(in1 * sig_real(1.5), sig_int(3000)))
        factory = create_dsp_factory_from_signals("test3", sv)
        assert factory
        print("compile options:", factory.get_compile_options())
        print("library list:", factory.get_library_list())
        print("sha key", factory.get_sha_key())
        dsp = factory.create_dsp_instance()
        assert dsp


def test_create_dsp_factory_from_signals2():
    print_entry("test_create_dsp_factory_from_signals2")
    with signal_context():
        sv = SignalVector()
        s1 = sig_delay(sig_input(0), sig_int(500)) + sig_real(0.5)
        sv.add(s1);
        sv.add(s1);
        factory = create_dsp_factory_from_signals("test4", sv)
        assert factory
        print("compile options:", factory.get_compile_options())
        print("library list:", factory.get_library_list())
        print("sha key", factory.get_sha_key())
        dsp = factory.create_dsp_instance()
        assert dsp

## ---------------------------------------------------------------------------
## faust/dsp/libfaust.h
##

def test_generate_sha1():
    print_entry("test_generate_sha1")
    assert generate_sha1("hello") == 'AAF4C61DDCC5E8A2DABEDE0F3B482CD9AEA9434D'

def test_expand_dsp_from_file():
    print_entry("test_expand_dsp_from_file")
    sha, expanded = None, None
    sha, expanded = expand_dsp_from_file("tests/dsp/osc.dsp")
    assert sha
    assert expanded
    # print(expanded)

def test_expand_dsp_from_string():
    print_entry("test_expand_dsp_from_string")
    sha, expanded = None, None
    with open("tests/dsp/osc.dsp") as f:
        content = f.read()
    sha, expanded = expand_dsp_from_string("osc_dsp", content)
    assert sha
    assert expanded

def test_generate_auxfiles_from_file():
    print_entry("test_generate_auxfiles_from_file")
    assert generate_auxfiles_from_file("tests/dsp/osc.dsp", "-svg", "-o", "/tmp/out.cpp")
    svg_folder = Path("osc-svg")
    process_svg = svg_folder / "process.svg"
    assert svg_folder.exists()
    assert process_svg.exists()
    shutil.rmtree(svg_folder)
    

if __name__ == '__main__':
    print_section("testing cyfaust.interp")
    if 'TRACE' in os.environ:
        import tracemalloc
    test_interp_version()
    test_interp_create_dsp_factory_from_file1()
    test_interp_create_dsp_factory_from_file2()
    test_interp_create_dsp_factory_from_file2()
    test_interp_create_dsp_factory_from_string1()
    test_interp_create_dsp_factory_from_string2()
    test_get_all_dsp_factories()
    # test_delete_all_dsp_factories()
    test_get_dsp_factory_from_sha_key()
    test_interp_warning_message()
    test_interp_read_dsp_factory_from_bitcode_file()
    test_interp_generate_auxfiles_from_string()
    test_create_dsp_factory_from_boxes()
    test_create_dsp_factory_from_signals1()
    test_create_dsp_factory_from_signals2()
    # libfaust
    test_generate_sha1()
    test_expand_dsp_from_file()
    test_expand_dsp_from_string()
    test_generate_auxfiles_from_file()
    if 'TRACE' in os.environ:
        print_entry("TRACEMALLOC ANALYSIS")
        snapshot = tracemalloc.take_snapshot()
        top_stats = snapshot.statistics('lineno')
        print("[ Top 10 ]")
        for stat in top_stats[:10]:
            print(stat)



