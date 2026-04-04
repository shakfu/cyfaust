# Examples

Usage patterns beyond the basics covered in [Getting Started](getting-started.md).

## DSP Introspection

### Metadata

```python
from cyfaust.interp import create_dsp_factory_from_string

code = '''
declare name "TestSynth";
declare author "Test Author";
declare version "1.0";
import("stdfaust.lib");
process = os.osc(440) * 0.1;
'''

factory = create_dsp_factory_from_string("synth", code)
dsp = factory.create_dsp_instance()
dsp.init(44100)

metadata = dsp.metadata()
print(metadata["name"])    # "TestSynth"
print(metadata["author"])  # "Test Author"
```

### Factory Properties

```python
factory = create_dsp_factory_from_file("synth.dsp")

print(factory.get_name())
print(factory.get_sha_key())
print(factory.get_dsp_code())
print(factory.get_compile_options())
print(factory.get_library_list())
print(factory.get_include_pathnames())
```

## Parameter Control

### DSP with UI Elements

```python
code = """
import("stdfaust.lib");
freq = hslider("frequency", 440, 50, 2000, 1);
gain = vslider("gain", 0.5, 0, 1, 0.01);
gate = button("gate");

envelope = gate : en.adsr(0.01, 0.1, 0.8, 0.2);
process = os.osc(freq) * gain * envelope;
"""

factory = create_dsp_factory_from_string("synth", code)
dsp = factory.create_dsp_instance()
dsp.init(44100)

# Build UI to register parameters
dsp.build_user_interface()

# Reset all parameters to their defaults
dsp.instance_reset_user_interface()
```

## Audio Processing

### Frame-by-Frame (Single Sample)

```python
import numpy as np

dsp.init(44100)

inputs = np.zeros(dsp.get_numinputs(), dtype=np.float32)
outputs = np.zeros(dsp.get_numoutputs(), dtype=np.float32)

inputs[0] = 0.5
dsp.frame(inputs, outputs)
# outputs now contains one processed sample
```

### Timestamped Computation

For sample-accurate automation with microsecond timestamps:

```python
import numpy as np

buffer_size = 64
inputs = np.zeros((dsp.get_numinputs(), buffer_size), dtype=np.float32)
outputs = np.zeros((dsp.get_numoutputs(), buffer_size), dtype=np.float32)

timestamp_usec = 1000000.0  # 1 second
dsp.compute_timestamped(timestamp_usec, buffer_size, inputs, outputs)
```

### Cloning DSP Instances

```python
dsp = factory.create_dsp_instance()
dsp.init(44100)

# Clone for parallel processing with independent state
cloned = dsp.clone()
cloned.init(44100)
```

## Real-Time Audio

```python
from cyfaust.interp import create_dsp_factory_from_file, RtAudioDriver
import time

factory = create_dsp_factory_from_file("osc.dsp")
dsp = factory.create_dsp_instance()
dsp.init(48000)

driver = RtAudioDriver(48000, 256)
driver.init(dsp)
driver.start()

time.sleep(2)  # play for 2 seconds

driver.stop()
```

## Box API

### UI Widgets as Boxes

```python
from cyfaust.box import (
    box_context, box_hslider, box_vslider, box_button,
    box_int, box_real, box_soundfile
)

with box_context():
    freq = box_hslider("frequency",
        box_int(440), box_int(50), box_int(2000), box_int(1))
    gain = box_vslider("gain",
        box_real(0.5), box_real(0), box_real(1), box_real(0.01))
    gate = box_button("gate")

    combined = freq * gain * gate
```

### Code Generation from Boxes

```python
from cyfaust.box import box_context, box_wire, box_float, box_seq, box_par
from cyfaust.interp import create_dsp_factory_from_boxes

with box_context():
    # input * 0.5
    gain = box_seq(box_wire(), box_par(box_wire(), box_float(0.5)))

    factory = create_dsp_factory_from_boxes("gain", gain)
    dsp = factory.create_dsp_instance()
```

## Signal API

### Programmatic DSP Construction

```python
from cyfaust.signal import (
    signal_context, SignalVector,
    sig_input, sig_real, sig_mul, sig_delay, sig_int
)
from cyfaust.interp import create_dsp_factory_from_signals

with signal_context():
    input_sig = sig_input(0)
    output = sig_mul(input_sig, sig_real(0.5))

    signals = SignalVector()
    signals.add(output)

    factory = create_dsp_factory_from_signals("gain", signals)
    dsp = factory.create_dsp_instance()
```

### Cross-Compilation from Signals

```python
from cyfaust.signal import signal_context, SignalVector, sig_input, sig_real, sig_mul

with signal_context():
    output = sig_mul(sig_input(0), sig_real(0.5))

    signals = SignalVector()
    signals.add(output)

    cpp_code = signals.create_source("my_dsp", "cpp")
    c_code = signals.create_source("my_dsp", "c")
```

## Initialization Lifecycle

The full DSP initialization sequence, for cases where you need fine-grained
control:

```python
sample_rate = 44100

# Factory-level class init (once per factory)
factory.class_init(sample_rate)

# Instance-level init
dsp.init(sample_rate)

# Or granular initialization:
dsp.instance_constants(sample_rate)    # set sample-rate-dependent constants
dsp.instance_reset_user_interface()    # reset parameters to defaults
dsp.instance_clear()                   # clear internal buffers/state
```
