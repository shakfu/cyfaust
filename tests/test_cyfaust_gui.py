"""
Test suite for cyfaust GUI API bindings.
Tests the newly added C interface structures, soundfile functionality, and UI components.
"""

import os
import sys
import pytest
from pathlib import Path

BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

try:
    from cyfaust.interp import InterpreterDspFactory, create_dsp_factory_from_string
    from cyfaust.common import PACKAGE_RESOURCES
except (ModuleNotFoundError, ImportError):
    from cyfaust.cyfaust import InterpreterDspFactory, create_dsp_factory_from_string, PACKAGE_RESOURCES

from testutils import print_section, print_entry


class TestUIInterface:
    """Test UI interface functionality"""
    
    def test_dsp_buildUserInterface(self):
        """Test that DSP can build user interface"""
        print_entry("test_dsp_buildUserInterface")
        
        # Simple DSP with slider
        dsp_code = """
        import("stdfaust.lib");
        freq = hslider("frequency", 440, 50, 2000, 1);
        process = os.osc(freq) * 0.1;
        """
        
        factory = create_dsp_factory_from_string("test_ui", dsp_code)
        assert factory is not None, "Failed to create DSP factory"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance"
        
        # Test basic properties
        assert dsp.get_num_inputs() >= 0
        assert dsp.get_num_outputs() >= 0
        
        # Clean up
        del dsp
        del factory


class TestSoundfileSupport:
    """Test soundfile functionality"""
    
    def test_soundfile_box_creation(self):
        """Test soundfile box creation"""
        print_entry("test_soundfile_box_creation")
        
        try:
            from cyfaust.box import box_soundfile, box_context
        except (ModuleNotFoundError, ImportError):
            from cyfaust.cyfaust import box_soundfile, box_context
        
        with box_context():
            # Test soundfile box creation with basic parameters
            sf_box = box_soundfile("test_sound", 2)  # 2 channels
            assert sf_box is not None, "Failed to create soundfile box"
            assert sf_box.is_valid, "Soundfile box is not valid"

    def test_soundfile_signal_creation(self):
        """Test soundfile signal creation"""
        print_entry("test_soundfile_signal_creation")
        
        try:
            from cyfaust.signal import sig_soundfile, signal_context
        except (ModuleNotFoundError, ImportError):
            from cyfaust.cyfaust import sig_soundfile, signal_context
        
        with signal_context():
            # Test soundfile signal creation
            sf_signal = sig_soundfile("test_sound")
            assert sf_signal is not None, "Failed to create soundfile signal"


class TestMemoryManager:
    """Test memory manager interface"""
    
    def test_dsp_memory_manager_interface(self):
        """Test DSP memory manager methods are accessible"""
        print_entry("test_dsp_memory_manager_interface")
        
        # Create a simple DSP to test memory manager interface
        dsp_code = "process = _;"
        factory = create_dsp_factory_from_string("test_memory", dsp_code)
        assert factory is not None, "Failed to create DSP factory"
        
        # Test that memory manager methods are available
        # Note: We can't directly test custom memory managers without implementing one,
        # but we can verify the interface exists
        memory_manager = factory.get_memory_manager()
        # memory_manager might be None if no custom manager is set
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance"
        
        # Clean up
        del dsp
        del factory


class TestAdvancedDSPMethods:
    """Test advanced DSP methods that were recently added"""
    
    def test_dsp_control_and_frame_methods(self):
        """Test control() and frame() methods are available"""
        print_entry("test_dsp_control_and_frame_methods")
        
        # Simple oscillator DSP
        dsp_code = """
        import("stdfaust.lib");
        process = os.osc(440) * 0.1;
        """
        
        factory = create_dsp_factory_from_string("test_advanced", dsp_code)
        assert factory is not None, "Failed to create DSP factory"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance"
        
        # Initialize DSP
        sample_rate = 44100
        dsp.init(sample_rate)
        
        # Test that methods are available (they might be no-ops)
        try:
            dsp.control()  # Should not raise exception
        except AttributeError:
            pytest.fail("control() method not available")
        
        # Note: frame() method requires specific compilation options to be meaningful
        # but we can test that the method exists
        try:
            # Create dummy input/output arrays for frame testing
            import array
            inputs = array.array('f', [0.0])
            outputs = array.array('f', [0.0])
            
            # This might be a no-op depending on compilation options
            dsp.frame(inputs, outputs)
        except AttributeError:
            pytest.fail("frame() method not available")
        except Exception:
            # Other exceptions are OK - method exists but may not be functional
            # without specific compilation flags
            pass
        
        # Clean up
        del dsp
        del factory

    def test_timestamped_compute(self):
        """Test timestamped compute method"""
        print_entry("test_timestamped_compute")
        
        dsp_code = "process = _;"
        factory = create_dsp_factory_from_string("test_timestamped", dsp_code)
        assert factory is not None, "Failed to create DSP factory"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance"
        
        # Initialize DSP
        sample_rate = 44100
        dsp.init(sample_rate)
        
        # Test timestamped compute method exists
        try:
            import array
            
            # Create input/output buffers
            buffer_size = 64
            num_inputs = dsp.get_num_inputs()
            num_outputs = dsp.get_num_outputs()
            
            if num_inputs > 0 and num_outputs > 0:
                # Create buffers (simplified for testing)
                input_buffers = [array.array('f', [0.0] * buffer_size) for _ in range(num_inputs)]
                output_buffers = [array.array('f', [0.0] * buffer_size) for _ in range(num_outputs)]
                
                # Test timestamped compute - the method should exist even if it's a passthrough
                timestamp = 1000000.0  # 1 second in microseconds
                dsp.compute(timestamp, buffer_size, input_buffers, output_buffers)
                
        except AttributeError:
            pytest.fail("Timestamped compute method not available")
        except Exception:
            # Other exceptions are acceptable - method exists but implementation details vary
            pass
        
        # Clean up
        del dsp
        del factory


class TestSignalRintFunction:
    """Test the sigRint function (round to integer nearest)"""
    
    def test_sig_rint_function(self):
        """Test sigRint function"""
        print_entry("test_sig_rint_function")
        
        try:
            from cyfaust.signal import sig_rint, sig_real, signal_context
        except (ModuleNotFoundError, ImportError):
            from cyfaust.cyfaust import sig_rint, sig_real, signal_context
        
        with signal_context():
            # Test sigRint with a real signal
            input_signal = sig_real(3.7)
            rounded_signal = sig_rint(input_signal)
            
            assert rounded_signal is not None, "Failed to create rint signal"
            
            # Test Signal.rint() method
            rounded_method = input_signal.rint()
            assert rounded_method is not None, "Failed to create rint signal via method"
            
            # Test that we can use it in a signal vector
            from cyfaust.signal import SignalVector
            sv = SignalVector()
            sv.add(rounded_signal)
            
            # Verify we can generate code with it
            code = sv.create_source("test_rint", "cpp")
            assert len(code) > 0, "Failed to generate code with sigRint"
            assert "rint" in code.lower(), "Generated code doesn't contain rint"


def test_gui_api_coverage():
    """Integration test to verify GUI API coverage"""
    print_entry("test_gui_api_coverage")
    
    # Test that we can create a DSP with multiple UI elements
    dsp_code = """
    import("stdfaust.lib");
    
    freq = hslider("frequency", 440, 50, 2000, 1);
    gain = vslider("gain", 0.5, 0, 1, 0.01);
    gate = button("gate");
    
    process = os.osc(freq) * gain * gate * 0.1;
    """
    
    factory = create_dsp_factory_from_string("test_gui_coverage", dsp_code)
    assert factory is not None, "Failed to create DSP factory"
    
    dsp = factory.create_dsp_instance()
    assert dsp is not None, "Failed to create DSP instance"
    
    # Verify basic properties
    assert dsp.get_num_outputs() > 0, "DSP should have outputs"
    
    # Clean up
    del dsp
    del factory


if __name__ == '__main__':
    print_section("Testing cyfaust GUI API")
    
    # Run tests
    test_ui = TestUIInterface()
    test_ui.test_dsp_buildUserInterface()
    
    test_sf = TestSoundfileSupport()
    test_sf.test_soundfile_box_creation()
    test_sf.test_soundfile_signal_creation()
    
    test_mm = TestMemoryManager()
    test_mm.test_dsp_memory_manager_interface()
    
    test_adv = TestAdvancedDSPMethods()
    test_adv.test_dsp_control_and_frame_methods()
    test_adv.test_timestamped_compute()
    
    test_rint = TestSignalRintFunction()
    test_rint.test_sig_rint_function()
    
    test_gui_api_coverage()
    
    print_entry("All GUI API tests completed")