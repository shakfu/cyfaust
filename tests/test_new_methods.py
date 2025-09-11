"""
Test suite for newly implemented methods in cyfaust.
Tests control(), frame(), compute() variants and factory methods.
"""

import os
import sys
import pytest
import numpy as np
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
        create_dsp_factory_from_string
    )
    DYNAMIC_BUILD = True
except (ModuleNotFoundError, ImportError):
    # Static build imports
    from cyfaust.cyfaust import (
        RtAudioDriver, InterpreterDspFactory,
        create_dsp_factory_from_string
    )
    DYNAMIC_BUILD = False


class TestNewDSPMethods:
    """Test newly implemented DSP methods"""
    
    def test_control_method(self):
        """Test control() method implementation"""
        print_entry("test_control_method")
        
        dsp_code = """
        import("stdfaust.lib");
        freq = hslider("frequency", 440, 50, 2000, 1);
        gain = hslider("gain", 0.5, 0, 1, 0.01);
        process = os.osc(freq) * gain * 0.1;
        """
        
        factory = create_dsp_factory_from_string("test_control", dsp_code)
        assert factory is not None, "Failed to create factory"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance"
        
        # Initialize DSP
        sample_rate = 44100
        dsp.init(sample_rate)
        
        # Test control method
        try:
            dsp.control()  # Should not raise exception
            print("✓ control() method available")
        except AttributeError:
            print("× control() method not available")
            raise
        
        # Clean up
        del dsp
        del factory

    def test_frame_method(self):
        """Test frame() method for single-frame processing"""
        print_entry("test_frame_method")
        
        # Simple pass-through DSP
        dsp_code = "process = _;"
        
        factory = create_dsp_factory_from_string("test_frame", dsp_code)
        assert factory is not None, "Failed to create factory"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance"
        
        # Initialize DSP
        sample_rate = 44100
        dsp.init(sample_rate)
        
        num_inputs = dsp.get_numinputs()
        num_outputs = dsp.get_numoutputs()
        
        if num_inputs > 0 and num_outputs > 0:
            # Test frame method with numpy arrays
            try:
                inputs = np.zeros(num_inputs, dtype=np.float32)
                outputs = np.zeros(num_outputs, dtype=np.float32)
                
                # Fill inputs with test signal
                if num_inputs > 0:
                    inputs[0] = 0.5
                
                dsp.frame(inputs, outputs)
                
                print(f"✓ frame() method processed {num_inputs} → {num_outputs} channels")
                print(f"  Input: {inputs[0] if num_inputs > 0 else 'N/A'}")
                print(f"  Output: {outputs[0] if num_outputs > 0 else 'N/A'}")
                
            except AttributeError:
                print("× frame() method not available")
                raise
            except Exception as e:
                print(f"× frame() method error: {e}")
                raise
        else:
            print("⚠ Skipping frame test - no inputs or outputs")
        
        # Clean up
        del dsp
        del factory

    def test_compute_method(self):
        """Test compute() method for multi-frame processing"""
        print_entry("test_compute_method")
        
        # Simple gain DSP
        dsp_code = "process = _ * 0.5;"
        
        factory = create_dsp_factory_from_string("test_compute", dsp_code)
        assert factory is not None, "Failed to create factory"
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance"
        
        # Initialize DSP
        sample_rate = 44100
        dsp.init(sample_rate)
        
        num_inputs = dsp.get_numinputs()
        num_outputs = dsp.get_numoutputs()
        
        if num_inputs > 0 and num_outputs > 0:
            try:
                buffer_size = 64
                
                # Create 2D arrays [channels, samples]
                inputs = np.ones((num_inputs, buffer_size), dtype=np.float32) * 0.8
                outputs = np.zeros((num_outputs, buffer_size), dtype=np.float32)
                
                dsp.compute(buffer_size, inputs, outputs)
                
                print(f"✓ compute() method processed {buffer_size} frames")
                print(f"  {num_inputs} inputs → {num_outputs} outputs")
                if num_outputs > 0:
                    print(f"  Output level: {np.mean(outputs[0]):.3f}")
                
            except AttributeError:
                print("× compute() method not available")
                raise
            except Exception as e:
                print(f"× compute() method error: {e}")
                raise
        else:
            print("⚠ Skipping compute test - no inputs or outputs")
        
        # Clean up
        del dsp
        del factory



class TestNewFactoryMethods:
    """Test newly implemented factory methods"""
    
    def test_memory_manager_methods(self):
        """Test memory manager methods"""
        print_entry("test_memory_manager_methods")
        
        dsp_code = "process = _;"
        
        factory = create_dsp_factory_from_string("test_memory_manager", dsp_code)
        assert factory is not None, "Failed to create factory"
        
        try:
            # Test get_memory_manager
            manager = factory.get_memory_manager()
            print(f"✓ get_memory_manager() returned: {manager}")
            
            # Test set_memory_manager (with None for Python interface)
            factory.set_memory_manager(None)
            print("✓ set_memory_manager() completed")
            
        except AttributeError as e:
            print(f"× Memory manager methods not available: {e}")
            raise
        except Exception as e:
            print(f"⚠ Memory manager methods available but limited in Python: {e}")
        
        # Clean up
        del factory

    def test_class_init_method(self):
        """Test class_init() method"""
        print_entry("test_class_init_method")
        
        dsp_code = """
        import("stdfaust.lib");
        process = no.noise * 0.1;
        """
        
        factory = create_dsp_factory_from_string("test_class_init", dsp_code)
        assert factory is not None, "Failed to create factory"
        
        try:
            sample_rate = 48000
            factory.class_init(sample_rate)
            print(f"✓ class_init({sample_rate}) completed successfully")
            
        except AttributeError:
            print("× class_init() method not available")
            raise
        except Exception as e:
            print(f"× class_init() method error: {e}")
            raise
        
        # Clean up
        del factory


class TestIntegrationWithNewMethods:
    """Integration tests using the new methods"""
    
    def test_complete_dsp_workflow(self):
        """Test complete DSP workflow with new methods"""
        print_entry("test_complete_dsp_workflow")
        
        dsp_code = """
        import("stdfaust.lib");
        freq = hslider("frequency", 440, 50, 2000, 1);
        gain = vslider("gain", 0.3, 0, 1, 0.01);
        gate = button("gate");
        
        envelope = gate : en.adsr(0.01, 0.1, 0.8, 0.2);
        oscillator = os.osc(freq);
        
        process = oscillator * gain * envelope;
        """
        
        factory = create_dsp_factory_from_string("test_workflow", dsp_code)
        assert factory is not None, "Failed to create factory"
        
        # Test factory methods
        factory.class_init(44100)
        manager = factory.get_memory_manager()
        factory.set_memory_manager(manager)
        
        dsp = factory.create_dsp_instance()
        assert dsp is not None, "Failed to create DSP instance"
        
        # Initialize DSP
        sample_rate = 44100
        dsp.init(sample_rate)
        dsp.instance_init(sample_rate)
        dsp.instance_constants(sample_rate)
        dsp.instance_clear()
        
        # Test control method
        dsp.control()
        
        num_inputs = dsp.get_numinputs()
        num_outputs = dsp.get_numoutputs()
        
        if num_outputs > 0:
            # Test frame processing
            if num_inputs > 0:
                inputs = np.zeros(num_inputs, dtype=np.float32)
                outputs = np.zeros(num_outputs, dtype=np.float32)
                dsp.frame(inputs, outputs)
            
            # Test buffer processing
            buffer_size = 64
            inputs_2d = np.zeros((max(1, num_inputs), buffer_size), dtype=np.float32)
            outputs_2d = np.zeros((num_outputs, buffer_size), dtype=np.float32)
            
            dsp.compute(buffer_size, inputs_2d, outputs_2d)
            
            
            print(f"✓ Complete workflow test successful")
            print(f"  DSP: {num_inputs} inputs → {num_outputs} outputs")
            print(f"  Processed {buffer_size} frames")
        
        # Clean up
        del dsp
        del factory


if __name__ == '__main__':
    print_section(f"Testing New Methods Implementation ({'dynamic' if DYNAMIC_BUILD else 'static'} build)")
    
    # Test DSP methods
    test_dsp = TestNewDSPMethods()
    test_dsp.test_control_method()
    test_dsp.test_frame_method()
    test_dsp.test_compute_method()
    
    # Test factory methods
    test_factory = TestNewFactoryMethods()
    test_factory.test_memory_manager_methods()
    test_factory.test_class_init_method()
    
    # Integration test
    test_integration = TestIntegrationWithNewMethods()
    test_integration.test_complete_dsp_workflow()
    
    print_entry("All new method tests completed successfully!")