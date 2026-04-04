# Getting Started

## Installation

Install cyfaust with the Faust interpreter backend (default):

```sh
pip install cyfaust
```

For the LLVM JIT backend (faster execution, larger binary):

```sh
pip install cyfaust-llvm
```

## Basic Usage

### Creating a DSP from a String

```python
from cyfaust.interp import create_dsp_factory_from_string, RtAudioDriver
import time

# Define Faust DSP code
code = """
import("stdfaust.lib");
process = os.osc(440);
"""

# Create factory and DSP instance
factory = create_dsp_factory_from_string("osc", code)
dsp = factory.create_dsp_instance()
dsp.init(48000)

# Play through speakers
driver = RtAudioDriver(48000, 256)
driver.init(dsp)
driver.start()
time.sleep(2)
driver.stop()
```

### Creating a DSP from a File

```python
from cyfaust.interp import create_dsp_factory_from_file, RtAudioDriver

factory = create_dsp_factory_from_file("synth.dsp")
dsp = factory.create_dsp_instance()
dsp.init(48000)
```

### Using the Box API

The Box API allows programmatic construction of Faust circuits:

```python
from cyfaust.box import box_context, box_int, box_float, box_wire, box_seq, box_par
from cyfaust.interp import create_dsp_factory_from_boxes

with box_context():
    # Create a simple gain effect: input * 0.5
    gain = box_seq(box_wire(), box_par(box_wire(), box_float(0.5)))

    factory = create_dsp_factory_from_boxes("gain", gain)
    dsp = factory.create_dsp_instance()
```

### Using the Signal API

The Signal API provides lower-level DSP construction:

```python
from cyfaust.signal import signal_context, sig_input, sig_real, sig_mul, SignalVector
from cyfaust.interp import create_dsp_factory_from_signals

with signal_context():
    # Create a gain effect: input(0) * 0.5
    s = sig_mul(sig_input(0), sig_real(0.5))

    signals = SignalVector()
    signals.add(s)

    factory = create_dsp_factory_from_signals("gain", signals)
    dsp = factory.create_dsp_instance()
```

### Computing Audio Buffers

```python
import numpy as np
from cyfaust.interp import create_dsp_factory_from_string

factory = create_dsp_factory_from_string("osc",
    "import(\"stdfaust.lib\"); process = os.osc(440);")
dsp = factory.create_dsp_instance()
dsp.init(48000)
dsp.build_user_interface()

n_frames = 1024
inputs = np.zeros((dsp.get_numinputs(), n_frames), dtype=np.float32)
outputs = np.zeros((dsp.get_numoutputs(), n_frames), dtype=np.float32)

dsp.compute(n_frames, inputs, outputs)
# outputs now contains generated audio samples
```

### Serialization

DSP factories can be serialized to bitcode for faster reloading:

```python
from cyfaust.interp import create_dsp_factory_from_string, read_dsp_factory_from_bitcode

# Save
factory = create_dsp_factory_from_string("osc",
    "import(\"stdfaust.lib\"); process = os.osc(440);")
factory.write_to_bitcode_file("osc.fbc")

# Load
factory2 = read_dsp_factory_from_bitcode_file("osc.fbc")
```
