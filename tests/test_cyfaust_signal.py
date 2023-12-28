import os, sys
BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

from cyfaust.signal import *

from testutils import print_section, print_entry

def test_create_source_from_signals():

    print_entry("test_create_source_from_signals")

    with signal_context():
        
    	sv = SignalVector()
    	sv.add(sig_real(10.8))
    	code = sv.create_source("test_dsp", "cpp")
    	assert len(code) > 0
    	print(code)


if __name__ == '__main__':
    print_section("testing cyfaust.signal")
    test_create_source_from_signals()
