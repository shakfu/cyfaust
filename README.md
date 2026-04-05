# cyfaust

The cyfaust project provides a minimal, modular, self-contained, cross-platform [cython](https://github.com/cython/cython) wrapper of the [Faust](https://github.com/grame-cncm/faust) DSP language and the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver.

- **Dual Backends**: Interpreter (default, ~8MB) or LLVM JIT (~33MB, faster execution)
- **Box API**: Fully wrapped with both functional and object-oriented interfaces
- **Signal API**: Fully wrapped with both functional and object-oriented interfaces
- **Platform Support**: macOS, Linux, and Windows
- **Build Variants**: Dynamic (`libfaust.so|dylib`) and static (`libfaust.a|lib`)
- **Faust Version**: `2.83.1`
- **Documentation**: [cyfaust-docs](https://shakfu.github.io/cyfaust/)

## Installation

To install cyfaust with the faust interpreter backend (default):

```sh
pip install cyfaust
```

To install with the LLVM JIT backend:

```sh
pip install cyfaust-llvm
```

## Features

- Python-oriented cross-platform implementation of the [Faust](https://faustdoc.grame.fr/manual/embedding/) DSP language

- **Two backend options**:
  - **Interpreter** (default): Compact ~8MB binary, good for development and most use cases
  - **LLVM JIT**: ~33MB binary with native code compilation for maximum performance

- Provides the following submodules (in the default build):

  - `cyfaust.interp`: wraps the faust interpreter and the rtaudio audio driver

  - `cyfaust.box`: wraps the [faust box api](https://faustdoc.grame.fr/tutorials/box-api/)

  - `cyfaust.signal`: wraps the [faust signal api](https://faustdoc.grame.fr/tutorials/signal-api/)

  - `cyfaust.common`: common utilities and classes

- Self-contained, minimal, and modular design

- Can generate code using the following backends: c++, c, rust, codebox

- Can generate auxiliary files such as SVG block diagrams of DSP

- Dual functional/OO design for box and signal APIs with minimal code duplication

- Implements [Memoryviews](https://cython.readthedocs.io/en/latest/src/userguide/memoryviews.html) for read/write buffer using `numpy` or `array.array`

- Both dynamic and static build variants can be packaged as a self-contained python wheel

- Command-line interface for common operations

## Quick Start

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

See the [Getting Started](https://shakfu.github.io/cyfaust/getting-started/) guide and [Examples](https://shakfu.github.io/cyfaust/examples/) for more usage patterns including the Box API, Signal API, buffer computation, and serialization.

## Command-Line Interface

cyfaust provides a CLI accessible via the `cyfaust` command or `python -m cyfaust`:

```bash
cyfaust <command> [options]
```

| Command | Description |
|---------|-------------|
| `version` | Show cyfaust and libfaust version information |
| `info` | Display DSP metadata, inputs, outputs, and dependencies |
| `compile` | Compile Faust DSP to target backend (cpp, c, rust, codebox) |
| `expand` | Expand Faust DSP to self-contained code with all imports resolved |
| `diagram` | Generate SVG block diagrams |
| `play` | Play a DSP file with RtAudio |
| `params` | List all DSP parameters (sliders, buttons, etc.) |
| `validate` | Check a DSP file for errors |
| `bitcode` | Save/load compiled DSP as bitcode for faster loading |
| `json` | Export DSP metadata as JSON |

Examples:

```bash
cyfaust play osc.dsp -d 5                     # play for 5 seconds
cyfaust compile synth.dsp -b cpp -o synth.cpp  # compile to C++
cyfaust params synth.dsp                       # list parameters
cyfaust json instrument.dsp --pretty           # export metadata
cyfaust validate filter.dsp --strict           # check for errors
```

See the full [CLI Reference](https://shakfu.github.io/cyfaust/cli/) for all options.

## Building from Source

```bash
git clone https://github.com/shakfu/cyfaust.git
cd cyfaust
make        # builds libfaust + installs for development
make test   # run tests
```

Common build targets:

```bash
make                   # dynamic interpreter build (default)
make STATIC=1 build    # static interpreter build
make build-llvm        # static LLVM build
make wheel             # build wheel
make wheel-llvm        # build LLVM wheel (cyfaust-llvm)
make wheel-windows     # Windows one-shot (deps + wheel + delvewheel)
```

Build options (set via `make VAR=1`):

| Option | Default | Description |
|--------|---------|-------------|
| `STATIC` | 0 | Build with static `libfaust` |
| `LLVM` | 0 | Build with LLVM backend (requires `STATIC=1`) |
| `INCLUDE_SNDFILE` | 1 | Include sndfile support |
| `ALSA` | 1 | ALSA audio (Linux) |
| `PULSE` | 0 | PulseAudio (Linux) |
| `JACK` | 0 | JACK (Linux/macOS) |
| `WASAPI` | 1 | WASAPI (Windows) |
| `ASIO` | 0 | ASIO (Windows) |
| `DSOUND` | 0 | DirectSound (Windows) |

### Windows

On Windows, use the provided build script instead of `make`:

```bash
# Full build (checks deps, generates static sources, builds wheel)
python scripts/build_windows.py

# Clean build artifacts first
python scripts/build_windows.py --clean

# Skip dependency builds (if libs already exist in lib/static/)
python scripts/build_windows.py --skip-deps

# Force rebuild all dependencies
python scripts/build_windows.py --rebuild-deps

# Build + install + run tests
python scripts/build_windows.py --test
```

Prerequisites: Visual Studio 2022 (or MSVC Build Tools), Python 3.10+, [uv](https://docs.astral.sh/uv/), and CMake.

See the full [Building from Source](https://shakfu.github.io/cyfaust/building/) guide for platform prerequisites, LLVM backend details, and wheel building instructions.

## Platform Support

**Interpreter backend (cyfaust):**

| Platform | Architecture | Status |
|----------|-------------|--------|
| macOS | arm64 (Apple Silicon) | Supported |
| macOS | x86_64 (Intel) | Supported |
| Linux | x86_64 | Supported |
| Linux | aarch64 | Supported |
| Windows | x86_64 | Supported |

**LLVM backend (cyfaust-llvm):**

| Platform | Architecture | Status |
|----------|-------------|--------|
| macOS | arm64 (Apple Silicon) | Supported |
| macOS | x86_64 (Intel) | Supported |
| Linux | x86_64 | Supported |
| Linux | aarch64 | Supported |
| Windows | x86_64 | Planned |

## Prior Art of Faust + Python

- [DawDreamer](https://github.com/DBraun/DawDreamer) by David Braun: Digital Audio Workstation with Python; VST instruments/effects, parameter automation, FAUST, JAX, Warp Markers, and JUCE processors. Full-featured and well-maintained. Use this for actual work! (pybind11)

- [faust_python](https://github.com/marcecj/faust_python) by Marc Joliet: A Python FAUST wrapper implemented using the CFFI (updated 2015). There's a more recent (updated in 2019) [fork](https://github.com/hrtlacek/faust_python) by Patrik Lechner. (cffi)

- [pyfaust](https://github.com/amstan/pyfaust) by Alexandru Stan: Embed Faust DSP Programs in Python. (cffi)

- [faust-ctypes](https://gitlab.com/adud2/faust-ctypes): a port of Marc Joliet's FaustPy from CFFI to Ctypes. (ctypes)

- [faustpp](https://github.com/jpcima/faustpp): A post-processor for faust, which enables more flexible code generation.
