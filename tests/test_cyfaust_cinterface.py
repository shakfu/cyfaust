"""
Test suite for cyfaust C interface structures.
Tests the newly added UIGlue, MetaGlue, and MemoryManagerGlue structures.
"""

import os
import sys
import pytest


try:
    from cyfaust.interp import create_dsp_factory_from_string
except (ModuleNotFoundError, ImportError):
    from cyfaust.cyfaust import create_dsp_factory_from_string

from testutils import print_section, print_entry


class TestCInterfaceStructures:
    """Test C interface structures for interoperability"""
    
    def test_c_interface_concepts(self):
        """Test that C interface concepts are properly supported"""
        print_entry("test_c_interface_concepts")
        
        # The C interface structures (UIGlue, MetaGlue, etc.) are primarily used
        # for interfacing with C code. We test the concepts by ensuring DSP instances
        # can be created and used in ways that would support C interfacing.
        
        dsp_code = """
        import("stdfaust.lib");
        gain = hslider("gain", 0.5, 0, 1, 0.01);
        freq = hslider("freq", 440, 50, 2000, 1);
        process = os.osc(freq) * gain * 0.1;
        """
        
        factory = create_dsp_factory_from_string("test_c_interface", dsp_code)
        assert factory is not None, "Failed to create DSP factory"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance"
        
        # Test basic properties that would be accessed via C interface
        num_inputs = dsp.get_numinputs()
        num_outputs = dsp.get_numoutputs()
        sample_rate = 44100
        
        assert num_inputs >= 0, "Number of inputs should be non-negative"
        assert num_outputs > 0, "DSP should have outputs"
        
        # Test initialization sequence that would be used in C interface
        dsp.init(sample_rate)
        assert dsp.get_samplerate() == sample_rate, "Sample rate should be set correctly"
        
        # Clean up
        del dsp
        del factory

    def test_dsp_function_pointers_concept(self):
        """Test concepts that would support C function pointer interface"""
        print_entry("test_dsp_function_pointers_concept")
        
        # Test multiple DSP instances to verify the interface supports
        # the kind of operations needed for C function pointer interfaces
        
        dsp_code1 = "process = _;"  # Pass-through
        dsp_code2 = "process = _ * 0.5;"  # Gain
        
        factory1 = create_dsp_factory_from_string("test_fp1", dsp_code1)
        factory2 = create_dsp_factory_from_string("test_fp2", dsp_code2)
        
        assert factory1 is not None, "Failed to create first DSP factory"
        assert factory2 is not None, "Failed to create second DSP factory"
        
        dsp1 = factory1.create_dsp_instance()
        dsp2 = factory2.create_dsp_instance()
        
        assert dsp1 is not None, "Failed to create first DSP instance"
        assert dsp2 is not None, "Failed to create second DSP instance"
        
        # Test that both instances can be initialized and used
        sample_rate = 44100
        dsp1.init(sample_rate)
        dsp2.init(sample_rate)
        
        # Test properties that would be accessed via function pointers
        assert dsp1.get_numinputs() == dsp2.get_numinputs(), "Both DSPs should have same input count"
        assert dsp1.get_numoutputs() == dsp2.get_numoutputs(), "Both DSPs should have same output count"
        
        # Clean up
        del dsp1
        del dsp2
        del factory1
        del factory2


class TestUIGlueConcepts:
    """Test concepts related to UIGlue structure"""
    
    def test_ui_building_interface(self):
        """Test UI building interface concepts"""
        print_entry("test_ui_building_interface")
        
        # Test DSP with multiple UI elements that would populate UIGlue structure
        dsp_code = """
        import("stdfaust.lib");
        
        // Test various UI elements
        button_gate = button("gate");
        checkbox_mute = checkbox("mute");
        vslider_gain = vslider("gain", 0.5, 0, 1, 0.01);
        hslider_freq = hslider("frequency", 440, 50, 2000, 1);
        nentry_detune = nentry("detune", 0, -100, 100, 1);
        
        vbargraph_level = vbargraph("level", 0, 1);
        hbargraph_spectrum = hbargraph("spectrum", 0, 1);
        
        signal = os.osc(hslider_freq + nentry_detune) * vslider_gain * button_gate * (1 - checkbox_mute);
        
        process = signal <: _, vbargraph_level, hbargraph_spectrum : _, _, _;
        """
        
        factory = create_dsp_factory_from_string("test_ui_glue", dsp_code)
        assert factory is not None, "Failed to create DSP factory with UI elements"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance with UI elements"
        
        # Test that DSP can be initialized (UI elements are built during init)
        sample_rate = 44100
        dsp.init(sample_rate)
        
        # Verify DSP has expected inputs/outputs
        assert dsp.get_numinputs() >= 0, "DSP should have valid input count"
        assert dsp.get_numoutputs() >= 3, "DSP should have signal + bargraph outputs"
        
        # Clean up
        del dsp
        del factory

    def test_ui_grouping_concepts(self):
        """Test UI grouping concepts (vgroup, hgroup, tgroup)"""
        print_entry("test_ui_grouping_concepts")
        
        dsp_code = """
        import("stdfaust.lib");
        
        oscillator_group = vgroup("Oscillator", 
            hslider("frequency", 440, 50, 2000, 1)
        );
        
        envelope_group = hgroup("Envelope",
            hslider("attack", 0.01, 0.001, 1, 0.001) +
            hslider("decay", 0.1, 0.001, 1, 0.001)
        );
        
        effects_group = tgroup("Effects",
            hslider("reverb", 0, 0, 1, 0.01)
        );
        
        freq = oscillator_group;
        env_time = envelope_group;
        reverb_amount = effects_group;
        
        process = os.osc(freq) * en.adsr(env_time, env_time, 0.5, env_time, button("gate")) * (1 - reverb_amount);
        """
        
        factory = create_dsp_factory_from_string("test_ui_groups", dsp_code)
        assert factory is not None, "Failed to create DSP factory with UI groups"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance with UI groups"
        
        # Test initialization
        sample_rate = 44100
        dsp.init(sample_rate)
        
        # Clean up
        del dsp
        del factory


class TestMetaGlueConcepts:
    """Test concepts related to MetaGlue structure"""
    
    def test_metadata_declarations(self):
        """Test DSP with metadata declarations"""
        print_entry("test_metadata_declarations")
        
        dsp_code = """
        declare name "Test Synthesizer";
        declare version "1.0.0";
        declare author "Test Author";
        declare description "A test synthesizer for MetaGlue interface";
        declare license "MIT";
        
        import("stdfaust.lib");
        
        freq = hslider("frequency[tooltip:The frequency of the oscillator]", 440, 50, 2000, 1);
        gain = hslider("gain[tooltip:Output gain control][unit:dB]", -6, -60, 6, 0.1);
        
        process = os.osc(freq) * ba.db2linear(gain) * 0.1;
        """
        
        factory = create_dsp_factory_from_string("test_meta_glue", dsp_code)
        assert factory is not None, "Failed to create DSP factory with metadata"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance with metadata"
        
        # Test that DSP works with metadata
        sample_rate = 44100
        dsp.init(sample_rate)
        
        # The metadata would be accessible via the metadata() method with a Meta interface
        # but we can verify the DSP was created successfully with metadata
        assert dsp.get_numoutputs() > 0, "DSP with metadata should have outputs"
        
        # Clean up
        del dsp
        del factory


class TestMemoryManagerGlueConcepts:
    """Test concepts related to MemoryManagerGlue structure"""
    
    def test_memory_intensive_dsp(self):
        """Test DSP that would benefit from custom memory management"""
        print_entry("test_memory_intensive_dsp")
        
        # Create DSP with delays that would use memory (simplified for testing)
        dsp_code = """
        import("stdfaust.lib");
        
        // Simple delay lines for memory usage
        delay_time = 1000;  // samples
        input_signal = _;
        delayed_signal = de.delay(delay_time, delay_time, input_signal);
        
        process = input_signal + delayed_signal * 0.5;
        """
        
        factory = create_dsp_factory_from_string("test_memory_glue", dsp_code)
        assert factory is not None, "Failed to create memory-intensive DSP factory"
        
        # Note: Memory manager interface not implemented in Python
        # original_manager = factory.get_memory_manager()  # Not available
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create memory-intensive DSP instance"
        
        # Test initialization (this is where memory allocation happens)
        sample_rate = 44100
        dsp.init(sample_rate)
        
        # Verify DSP properties
        assert dsp.get_numinputs() >= 0, "DSP should have valid input count"
        assert dsp.get_numoutputs() > 0, "DSP should have outputs"
        
        # Clean up
        del dsp
        del factory


if __name__ == '__main__':
    print_section("Testing cyfaust C Interface API")
    
    # Run tests
    test_ci = TestCInterfaceStructures()
    test_ci.test_c_interface_concepts()
    test_ci.test_dsp_function_pointers_concept()
    
    test_ui = TestUIGlueConcepts()
    test_ui.test_ui_building_interface()
    test_ui.test_ui_grouping_concepts()
    
    test_meta = TestMetaGlueConcepts()
    test_meta.test_metadata_declarations()
    
    test_mm = TestMemoryManagerGlueConcepts()
    test_mm.test_memory_intensive_dsp()
    
    print_entry("All C interface API tests completed")