import os, sys, time
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

from cyfaust import interp
from cyfaust.signal import *

from testutils import print_section, print_entry

def test_create_source_from_signals1():

    print_entry("test_create_source_from_signals1")

    with signal_context():
    	sv = SignalVector()
    	sv.add(sig_real(10.8))
    	code = sv.create_source("test1", "cpp")
    	assert len(code) > 0
    	# print(code)

def test_create_source_from_signals2():

    print_entry("test_create_source_from_signals2")

    with signal_context():
        sv = SignalVector()
        in1 = sig_input(0)
        sv.add(in1 + sig_real(0.5))
        sv.add(in1 * sig_real(1.5))
        code = sv.create_source("test2", "cpp")
        assert len(code) > 0
        # print(code)

def test_create_dsp_factory_from_signals1():

    print_entry("test_create_dsp_factory_from_signals1")

    with signal_context():
        sv = SignalVector()
        in1 = sig_input(0)
        sv.add(sig_delay(in1 + sig_real(0.5), sig_int(500)))
        sv.add(sig_delay(in1 * sig_real(1.5), sig_int(3000)))
        factory = interp.create_dsp_factory_from_signals("test3", sv)
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
        factory = interp.create_dsp_factory_from_signals("test4", sv)
        assert factory
        print("compile options:", factory.get_compile_options())
        print("library list:", factory.get_library_list())
        print("sha key", factory.get_sha_key())
        dsp = factory.create_dsp_instance()
        assert dsp


def test_create_dsp_factory_from_signals3():

    print_entry("test_create_dsp_factory_from_signals3")

    with signal_context():
        sv = SignalVector()
        sf = sig_soundfile("tests/amen.wav")
        rdx = sig_int(0)
        part = sig_int(0)
        wridx = sig_int_cast(sig_max(sig_int(9),
            sig_min(rdx, sig_sub(sig_soundfile_length(sf,
            sig_int(0)),
            sig_int(1)))))
        sv.add(sig_soundfile_length(sf, part))
        sv.add(sig_soundfile_rate(sf, part))
        sv.add(sig_soundfile_buffer(sf, sig_int(0), part, wridx))
        factory = interp.create_dsp_factory_from_signals("sndfile_test", sv)
        assert factory
        print("compile options:", factory.get_compile_options())
        print("library list:", factory.get_library_list())
        print("sha key", factory.get_sha_key())
        dsp = factory.create_dsp_instance()
        assert dsp
        dsp.build_user_interface()
        audio = interp.RtAudioDriver(48000, 256)
        audio.init(dsp)
        audio.start()
        time.sleep(1)


if __name__ == '__main__':
    print_section("testing cyfaust.signal")
    test_create_source_from_signals1()
    test_create_source_from_signals2()
    test_create_dsp_factory_from_signals1()
    test_create_dsp_factory_from_signals2()
    # test_create_dsp_factory_from_signals3()


