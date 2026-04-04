# cyfaust

A minimal, modular, self-contained, cross-platform [Cython](https://github.com/cython/cython) wrapper of the [Faust](https://github.com/grame-cncm/faust) DSP language and the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver.

## Features

- **Dual Backends**: Interpreter (default, ~8MB) or LLVM JIT (~71MB, faster execution)
- **Box API**: Fully wrapped with both functional and object-oriented interfaces
- **Signal API**: Fully wrapped with both functional and object-oriented interfaces
- **Platform Support**: macOS, Linux, and Windows
- **Build Variants**: Dynamic (`libfaust.so|dylib`) and static (`libfaust.a|lib`)
- **Faust Version**: `2.83.1`

## Quick Example

```python
from cyfaust.interp import create_dsp_factory_from_string, RtAudioDriver
import time

# Create a DSP factory from Faust code
factory = create_dsp_factory_from_string("test",
    "import(\"stdfaust.lib\"); process = os.osc(440);")

# Create a DSP instance and initialize it
dsp = factory.create_dsp_instance()
dsp.init(48000)

# Play audio through RtAudio
driver = RtAudioDriver(48000, 256)
driver.init(dsp)
driver.start()
time.sleep(2)
driver.stop()
```

## Modules

| Module | Description |
|--------|-------------|
| [`cyfaust.interp`](api/interp.md) | Faust interpreter backend, DSP factory creation, and RtAudio driver |
| [`cyfaust.box`](api/box.md) | Faust Box API for functional signal composition |
| [`cyfaust.signal`](api/signal.md) | Faust Signal API for lower-level DSP composition |
| [`cyfaust.common`](api/common.md) | Shared utilities and classes |
| [`cyfaust.player`](api/player.md) | Sound file player classes using RtAudio |
