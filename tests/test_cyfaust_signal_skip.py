import os, sys, time
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

import pytest

from cyfaust import interp
from cyfaust.signal import *

from testutils import print_section, print_entry

@pytest.mark.skip(reason="causes segfault (also c++ version as well)")
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




