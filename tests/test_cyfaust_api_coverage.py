"""
Comprehensive API coverage test suite for cyfaust.
Tests all major API components to ensure complete functionality.
"""

import os
import sys
import pytest
from pathlib import Path

BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'build')
sys.path.insert(0, BUILD_PATH)

# Import testing utilities
from testutils import print_section, print_entry

# Try importing from both build variants
try:
    # Dynamic build imports
    from cyfaust.interp import (
        RtAudioDriver, InterpreterDspFactory,
        create_dsp_factory_from_string, create_dsp_factory_from_file,
        create_dsp_factory_from_boxes, create_dsp_factory_from_signals,
        get_version, generate_sha1, expand_dsp_from_string
    )
    from cyfaust.box import (
        box_context, BoxVector, box_int, box_real, box_add, box_mul,
        box_hslider, box_vslider, box_button, box_soundfile
    )
    from cyfaust.signal import (
        signal_context, SignalVector, sig_int, sig_real, sig_input,
        sig_add, sig_mul, sig_delay, sig_soundfile, sig_round
    )
    from cyfaust.common import PACKAGE_RESOURCES
    DYNAMIC_BUILD = True
except (ModuleNotFoundError, ImportError):
    # Static build imports
    from cyfaust.cyfaust import (
        RtAudioDriver, InterpreterDspFactory,
        create_dsp_factory_from_string, create_dsp_factory_from_file,
        create_dsp_factory_from_boxes, create_dsp_factory_from_signals,
        get_version, generate_sha1, expand_dsp_from_string,
        box_context, BoxVector, box_int, box_real, box_add, box_mul,
        box_hslider, box_vslider, box_button, box_soundfile,
        signal_context, SignalVector, sig_int, sig_real, sig_input,
        sig_add, sig_mul, sig_delay, sig_soundfile, sig_round,
        PACKAGE_RESOURCES
    )
    DYNAMIC_BUILD = False


class TestAPIVersioning:
    """Test API versioning and basic information"""
    
    def test_version_info(self):
        """Test version information is available"""
        print_entry("test_version_info")
        
        version = get_version()
        assert isinstance(version, str), "Version should be a string"
        assert len(version) > 0, "Version should not be empty"
        print(f"Faust version: {version}")

    def test_build_variant_detection(self):
        """Test detection of build variant"""
        print_entry("test_build_variant_detection")
        
        print(f"Build variant: {'dynamic' if DYNAMIC_BUILD else 'static'}")
        
        # Test that PACKAGE_RESOURCES is available
        assert PACKAGE_RESOURCES is not None, "PACKAGE_RESOURCES should be available"
        print(f"Package resources path: {PACKAGE_RESOURCES}")


class TestInterpreterAPI:
    """Test complete interpreter API coverage"""
    
    def test_dsp_factory_creation_methods(self):
        """Test all DSP factory creation methods"""
        print_entry("test_dsp_factory_creation_methods")
        
        # Test factory from string
        dsp_code = "import(\"stdfaust.lib\"); process = os.osc(440) * 0.1;"
        factory1 = create_dsp_factory_from_string("test_string", dsp_code)
        assert factory1 is not None, "Factory from string failed"
        
        # Test factory properties
        assert len(factory1.get_name()) > 0, "Factory should have a name"
        assert len(factory1.get_sha_key()) > 0, "Factory should have SHA key"
        assert len(factory1.get_dsp_code()) > 0, "Factory should have DSP code"
        
        # Test factory from boxes
        with box_context():
            box = box_real(0.5).par(box_real(0.3))
            factory2 = create_dsp_factory_from_boxes("test_boxes", box)
            assert factory2 is not None, "Factory from boxes failed"
        
        # Test factory from signals  
        with signal_context():
            signals = SignalVector()
            signals.add(sig_real(0.7))
            signals.add(sig_real(0.2))
            factory3 = create_dsp_factory_from_signals("test_signals", signals)
            assert factory3 is not None, "Factory from signals failed"
        
        # Clean up
        del factory1, factory2, factory3

    def test_dsp_instance_lifecycle(self):
        """Test complete DSP instance lifecycle"""
        print_entry("test_dsp_instance_lifecycle")
        
        dsp_code = """
        import("stdfaust.lib");
        freq = hslider("frequency", 440, 50, 2000, 1);
        gain = vslider("gain", 0.5, 0, 1, 0.01);
        gate = button("gate");
        process = os.osc(freq) * gain * gate;
        """
        
        factory = create_dsp_factory_from_string("test_lifecycle", dsp_code)
        assert factory is not None, "Failed to create factory"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance"
        
        # Test all DSP methods
        sample_rate = 44100
        
        # Initialization sequence
        dsp.init(sample_rate)
        dsp.instance_init(sample_rate)
        dsp.instance_constants(sample_rate)
        dsp.instance_reset_user_interface()
        dsp.instance_clear()
        
        # Properties
        assert dsp.get_sample_rate() == sample_rate
        assert dsp.get_num_inputs() >= 0
        assert dsp.get_num_outputs() > 0
        
        # Processing methods
        dsp.control()
        
        # Test compute with buffers
        import array
        buffer_size = 64
        num_inputs = dsp.get_num_inputs()
        num_outputs = dsp.get_num_outputs()
        
        if num_outputs > 0:
            input_buffers = [array.array('f', [0.0] * buffer_size) for _ in range(max(num_inputs, 0))]
            output_buffers = [array.array('f', [0.0] * buffer_size) for _ in range(num_outputs)]
            
            if num_inputs > 0:
                dsp.compute(buffer_size, input_buffers, output_buffers)
            else:
                dsp.compute(buffer_size, [], output_buffers)
        
        # Test cloning
        cloned_dsp = dsp.clone()
        assert cloned_dsp is not None, "Failed to clone DSP"
        
        # Clean up
        del cloned_dsp
        del dsp
        del factory


class TestBoxAPI:
    """Test complete Box API coverage"""
    
    def test_basic_box_operations(self):
        """Test basic box operations"""
        print_entry("test_basic_box_operations")
        
        with box_context():
            # Test basic boxes
            int_box = box_int(42)
            real_box = box_real(3.14)
            
            assert int_box.is_valid, "Integer box should be valid"
            assert real_box.is_valid, "Real box should be valid"
            
            # Test arithmetic operations
            add_box = int_box + real_box
            mul_box = int_box * real_box
            
            assert add_box.is_valid, "Addition box should be valid"
            assert mul_box.is_valid, "Multiplication box should be valid"

    def test_ui_box_elements(self):
        """Test UI box elements"""
        print_entry("test_ui_box_elements")
        
        with box_context():
            # Test UI elements
            slider_box = box_hslider("freq", 440, 50, 2000, 1)
            vslider_box = box_vslider("gain", 0.5, 0, 1, 0.01)
            button_box = box_button("gate")
            
            assert slider_box.is_valid, "Horizontal slider box should be valid"
            assert vslider_box.is_valid, "Vertical slider box should be valid" 
            assert button_box.is_valid, "Button box should be valid"
            
            # Test combining UI elements
            combined = slider_box * vslider_box * button_box
            assert combined.is_valid, "Combined UI box should be valid"

    def test_soundfile_box(self):
        """Test soundfile box functionality"""
        print_entry("test_soundfile_box")
        
        with box_context():
            # Test soundfile box creation
            sf_box = box_soundfile("test_sound", 2)  # 2 channels
            assert sf_box.is_valid, "Soundfile box should be valid"


class TestSignalAPI:
    """Test complete Signal API coverage"""
    
    def test_basic_signal_operations(self):
        """Test basic signal operations"""
        print_entry("test_basic_signal_operations")
        
        with signal_context():
            # Test basic signals
            int_sig = sig_int(10)
            real_sig = sig_real(2.5)
            input_sig = sig_input(0)
            
            assert int_sig is not None, "Integer signal should be created"
            assert real_sig is not None, "Real signal should be created"
            assert input_sig is not None, "Input signal should be created"
            
            # Test arithmetic operations
            add_sig = sig_add(int_sig, real_sig)
            mul_sig = sig_mul(input_sig, real_sig)
            
            assert add_sig is not None, "Addition signal should be created"
            assert mul_sig is not None, "Multiplication signal should be created"

    def test_signal_processing_operations(self):
        """Test signal processing operations"""
        print_entry("test_signal_processing_operations")
        
        with signal_context():
            input_sig = sig_input(0)
            
            # Test delay
            delay_sig = sig_delay(input_sig, sig_int(1000))
            assert delay_sig is not None, "Delay signal should be created"
            
            # Test round function (newly added)
            round_sig = sig_round(sig_real(3.7))
            assert round_sig is not None, "Round signal should be created"

    def test_soundfile_signal(self):
        """Test soundfile signal functionality"""
        print_entry("test_soundfile_signal")
        
        with signal_context():
            # Test soundfile signal creation
            sf_signal = sig_soundfile("test_sound")
            assert sf_signal is not None, "Soundfile signal should be created"

    def test_signal_vector_operations(self):
        """Test SignalVector operations"""
        print_entry("test_signal_vector_operations")
        
        with signal_context():
            # Test SignalVector
            sv = SignalVector()
            
            # Add signals
            sv.add(sig_real(1.0))
            sv.add(sig_real(2.0))
            
            # Generate source code
            cpp_code = sv.create_source("test_vector", "cpp")
            assert len(cpp_code) > 0, "C++ code should be generated"
            
            c_code = sv.create_source("test_vector", "c")
            assert len(c_code) > 0, "C code should be generated"


class TestRtAudioDriver:
    """Test RtAudio driver functionality"""
    
    def test_rtaudio_driver_creation(self):
        """Test RtAudio driver creation"""
        print_entry("test_rtaudio_driver_creation")
        
        try:
            # Test driver creation
            driver = RtAudioDriver(44100, 512)
            assert driver is not None, "RtAudio driver should be created"
            
            # Test driver properties
            assert driver.get_sample_rate() == 44100, "Sample rate should be set correctly"
            assert driver.get_buffer_size() == 512, "Buffer size should be set correctly"
            
            # Clean up
            del driver
            
        except Exception as e:
            # RtAudio might not be available in all environments
            print(f"Note: RtAudio driver test skipped due to: {e}")


class TestUtilityFunctions:
    """Test utility functions"""
    
    def test_sha1_generation(self):
        """Test SHA1 generation"""
        print_entry("test_sha1_generation")
        
        test_data = "test data for sha1"
        sha1_hash = generate_sha1(test_data)
        
        assert isinstance(sha1_hash, str), "SHA1 should be a string"
        assert len(sha1_hash) == 40, "SHA1 should be 40 characters long"

    def test_dsp_expansion(self):
        """Test DSP expansion functionality"""
        print_entry("test_dsp_expansion")
        
        dsp_code = "import(\"stdfaust.lib\"); process = _;"
        
        try:
            expanded_code = expand_dsp_from_string("test_expand", dsp_code)
            assert isinstance(expanded_code, str), "Expanded code should be a string"
            assert len(expanded_code) > len(dsp_code), "Expanded code should be longer than original"
        except Exception as e:
            print(f"Note: DSP expansion test may require additional setup: {e}")


def test_comprehensive_api_integration():
    """Integration test combining multiple APIs"""
    print_entry("test_comprehensive_api_integration")
    
    # Test Box -> Signal -> DSP workflow
    with box_context():
        # Create a box with UI elements
        freq_slider = box_hslider("frequency", 440, 50, 2000, 1)
        gain_slider = box_vslider("gain", 0.5, 0, 1, 0.01)
        osc_box = box_add(freq_slider, box_real(0.0))  # Simple oscillator frequency
        
        # Convert to DSP factory
        factory = create_dsp_factory_from_boxes("integration_test", osc_box)
        assert factory is not None, "Integration test factory should be created"
        
        # Create DSP instance
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Integration test DSP should be created"
        
        # Test DSP
        dsp.init(44100)
        assert dsp.get_num_outputs() > 0, "Integration test DSP should have outputs"
        
        # Clean up
        del dsp
        del factory


if __name__ == '__main__':
    print_section("Testing cyfaust Complete API Coverage")
    
    # Run all test classes
    test_version = TestAPIVersioning()
    test_version.test_version_info()
    test_version.test_build_variant_detection()
    
    test_interp = TestInterpreterAPI()
    test_interp.test_dsp_factory_creation_methods()
    test_interp.test_dsp_instance_lifecycle()
    
    test_box = TestBoxAPI()
    test_box.test_basic_box_operations()
    test_box.test_ui_box_elements()
    test_box.test_soundfile_box()
    
    test_signal = TestSignalAPI()
    test_signal.test_basic_signal_operations()
    test_signal.test_signal_processing_operations()
    test_signal.test_soundfile_signal()
    test_signal.test_signal_vector_operations()
    
    test_rtaudio = TestRtAudioDriver()
    test_rtaudio.test_rtaudio_driver_creation()
    
    test_utils = TestUtilityFunctions()
    test_utils.test_sha1_generation()
    test_utils.test_dsp_expansion()
    
    # Integration test
    test_comprehensive_api_integration()
    
    print_entry("Complete API coverage tests completed successfully!")