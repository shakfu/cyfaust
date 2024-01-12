import os, sys, time
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

try:
    from cyfaust.interp import create_dsp_factory_from_signals
    from cyfaust.signal import (
        signal_context, SignalVector, sig_input,
        sig_real, sig_int, sig_delay
    )
except ImportError:
    from cyfaust.cyfaust import (
        create_dsp_factory_from_signals,
        signal_context, SignalVector, sig_input,
        sig_real, sig_int, sig_delay
    )

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


if __name__ == '__main__':
    print_section("testing cyfaust.signal")
    if 'TRACE' in os.environ:
        import tracemalloc
    test_create_source_from_signals1()
    test_create_source_from_signals2()
    test_create_dsp_factory_from_signals1()
    test_create_dsp_factory_from_signals2()
    if 'TRACE' in os.environ:
        print_entry("TRACEMALLOC ANALYSIS")
        snapshot = tracemalloc.take_snapshot()
        top_stats = snapshot.statistics('lineno')
        print("[ Top 10 ]")
        for stat in top_stats[:10]:
            print(stat)


