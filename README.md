# cyfaust

The cyfaust project provides a minimal, modular, self-contained, cross-platform [cython](https://github.com/cython/cython) wrapper of the [Faust](https://github.com/grame-cncm/faust) DSP language and the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver.

- **Dual Backends**: Interpreter (default, ~8MB) or LLVM JIT (~71MB, faster execution)
- **Box API**: Fully wrapped with both functional and object-oriented interfaces
- **Signal API**: Fully wrapped with both functional and object-oriented interfaces
- **Platform Support**: macOS, Linux, and Windows
- **Build Variants**: Dynamic (`libfaust.so|dylib`) and static (`libfaust.a|lib`)
- **Faust Version**: `2.83.1`

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
  - **LLVM JIT**: ~71MB binary with native code compilation for maximum performance

- Provides the following submodules (in the default build):

  - `cyfaust.interp`: wraps the faust interpreter and the rtaudio audio driver

  - `cyfaust.box`: wraps the [faust box api](https://faustdoc.grame.fr/tutorials/box-api/)

  - `cyfaust.signal`: wraps the [faust signal api](https://faustdoc.grame.fr/tutorials/signal-api/)

  - `cyfaust.common`: common utilities and classes

- Self-contained, minimal, and modular design

- Default build uses interpreter backend to keep binary size low (~8MB vs ~71MB with LLVM)

- Can generate code using the following backends:

  - c++
  - c
  - rust
  - codebox

- Can generate auxiliary files such as svg block diagrams of dsp

- Dual functional/oo design for box and signal apis with minimal code duplication.

- Implements [Memorviews](https://cython.readthedocs.io/en/latest/src/userguide/memoryviews.html) for read/write buffer using `numpy` or `array.array`.

- Both dynamic and static build variants can be packaged as a self-contained python wheel.

- Includes several github workflows to automate the testing and building of cyfaust wheels for a number of supported platforms

- Command-line interface for common operations

## Command-Line Interface

cyfaust provides a CLI accessible via the `cyfaust` command or `python -m cyfaust`:

```bash
cyfaust <command> [options]
# or: python -m cyfaust <command> [options]
```

### Commands

**version** - Show cyfaust and libfaust version information:
```bash
cyfaust version
```

**info** - Display DSP metadata, inputs, outputs, and dependencies:
```bash
cyfaust info synth.dsp
```

**compile** - Compile Faust DSP to target backend (cpp, c, rust, codebox):
```bash
cyfaust compile synth.dsp -b cpp -o synth.cpp
cyfaust compile synth.dsp -b rust -o synth.rs
```

**expand** - Expand Faust DSP to self-contained code with all imports resolved:
```bash
cyfaust expand filter.dsp -o filter_expanded.dsp
cyfaust expand filter.dsp --sha-only  # output only SHA1 key
```

**diagram** - Generate SVG block diagrams:
```bash
cyfaust diagram synth.dsp -o output_dir
```

**play** - Play a DSP file with RtAudio:
```bash
cyfaust play osc.dsp              # play until Ctrl+C
cyfaust play osc.dsp -d 5         # play for 5 seconds
cyfaust play osc.dsp -r 48000     # use 48kHz sample rate
```

**params** - List all DSP parameters (sliders, buttons, etc.):
```bash
cyfaust params synth.dsp
```

**validate** - Check a DSP file for errors:
```bash
cyfaust validate filter.dsp
cyfaust validate filter.dsp --strict  # treat warnings as errors
```

**bitcode** - Save/load compiled DSP as bitcode for faster loading:
```bash
cyfaust bitcode save synth.dsp -o synth.fbc
cyfaust bitcode load synth.fbc
```

**json** - Export DSP metadata as JSON:
```bash
cyfaust json instrument.dsp --pretty
cyfaust json instrument.dsp -o metadata.json
```

For detailed help on any command:
```bash
cyfaust <command> --help
```

## Building

It has two build variants:

1. The default build is dynamically linked to `libfaust.dylib`, `libfaust.so` or `faust.dll` depending on your platform and consists of a python package with multiple compiled submodules and embedded resources (faust libraries and architecture files):

    ```bash
    % tree -L 3
    .
    └── cyfaust
        ├── __init__.py
        ├── box.cpython-311-darwin.so
        ├── common.cpython-311-darwin.so
        ├── interp.cpython-311-darwin.so
        ├── signal.cpython-311-darwin.so
        └── resources
            ├── architecture
            └── libraries
    ```

2. The static build is statically linked (with `libfaust.a` or `libfaust.lib`) and consists of a python package with a single compiled submodule and embedded resources (faust libraries and architecture files):

    ```bash
    % tree -L 3
    .
    └── cyfaust
        ├── __init__.py
        ├── cyfaust.cpython-311-darwin.so
        └── resources
            ├── architecture
            └── libraries
    ```

While this project was initially developed and tested primarily on macOS (`x86_64`, `arm64`), Linux (`amd64`, `aarch64`) and Windows (`amd64`) are now supported in recent releases.

See the project's [TODO](https://github.com/shakfu/cyfaust/blob/main/TODO.md) for remaining enhancements.

### Setup and Requirements

cyfaust has a build management script, `scripts/manage.py`, which simplifies cross-platform project setup and builds and also build automation in the case of github workflows.

```bash
usage: manage.py [-h] [-v]  ...

cyfaust build manager

options:
  -h, --help     show this help message and exit
  -v, --version  show program's version number and exit

subcommands:
  valid subcommands

                 additional help
    build        build packages
    clean        clean detritus
    setup        setup prerequisites
    test         test modules
    wheel        build wheels
```

A brief guide to its use is provided in the following table:

| #  | platform | step                    | command                                       |
|:--:|:-------- | :---------------------- |:--------------------------------------------- |
| 1* | common   | install prerequisites   | `python3 scripts/manage.py setup --deps`      |
| 2  | common   | build/install faustlib  | `python3 scripts/manage.py setup --faust`     |
| 3  | common   | build cyfaust (dynamic) | `python3 scripts/manage.py build`             |
| 4  | common   | build cyfaust (static)  | `python3 scripts/manage.py build --static`    |
| 5  | common   | test cyfaust            | `python3 scripts/manage.py test` or `pytest`  |
| 6  | common   | build cyfaust wheels    | `python3 scripts/manage.py wheel --release`   |
| 7  | common   | test cyfaust wheels     | `python3 scripts/manage.py wheel --test`      |

[`*`] Prerequisites consists of general and platform-specific requirements.

The general requirements are:

1. `libfaust` configured to be built with the c, c++, codebox, interp_comp, and rust backends and the executable, static and dynamic targets.

2. `libsndfile` and `libsamplerate` for faust `soundfile` primitive support

Platform specific requirements are covered in the next sections.

### Windows

To build cyfaust you will need:
- Python 3.10+ installed
- [Visual Studio Community Edition](https://visualstudio.microsoft.com/vs/community/) with C++ and Windows SDK development support
- `git` and `cmake`
- [uv](https://docs.astral.sh/uv/) package manager (recommended)
- GNU Make (via [Git for Windows](https://gitforwindows.org/) or [w64devkit](https://github.com/skeeto/w64devkit))

#### Quick Start (One-Shot Wheel Build)

The easiest way to build a distributable Windows wheel:

```bash
git clone https://github.com/shakfu/cyfaust.git
cd cyfaust
make wheel-windows
```

This single command:
1. Downloads and builds libfaust (interpreter backend)
2. Builds libsamplerate and libsndfile
3. Builds the Python wheel
4. Bundles `faust.dll` into the wheel via delvewheel

The resulting wheel in `dist/` is fully self-contained and can be installed anywhere.

#### Development Build

For development (editable install):

```bash
git clone https://github.com/shakfu/cyfaust.git
cd cyfaust
make          # builds dependencies and installs for development
make test     # run tests
```

#### Manual Build Steps

If you prefer manual control or don't have `make`:

```bash
git clone https://github.com/shakfu/cyfaust.git
cd cyfaust
pip install uv
python scripts/manage.py setup --faust      # build libfaust
python scripts/manage.py setup --samplerate # build libsamplerate
python scripts/manage.py setup --sndfile    # build libsndfile
CMAKE_ARGS="-DSTATIC=OFF" uv sync           # development install
uv run pytest tests/                        # run tests
```

To build a wheel manually:

```bash
CMAKE_ARGS="-DSTATIC=OFF" uv build --wheel
uv run delvewheel repair --add-path lib dist/*.whl -w dist/
```

### macOS, Linux & Windows (with Make)

A `Makefile` is available as a frontend to the `manage.py` script on all platforms. On Windows, you can use GNU Make from [Git for Windows](https://gitforwindows.org/) (Git Bash) or [w64devkit](https://github.com/skeeto/w64devkit).

The following setup sequence is illustrative of this and is also useful if you want to setup cyfaust manually.

For macOS, having Xcode or the CommandLine tools (`xcode-select --install`) installed is required, and then you will need to have python and cmake installed. If you use [Homebrew](https://brew.sh), this is simply:

```bash
brew install python cmake
```

For Linux, if you are on a Debian-derived system, you will need something like the following:

```bash
sudo apt update
sudo apt install build-essential git cmake python3-dev # you probably have these already
sudo apt install libasound2-dev patchelf # for alsa sound driver and fixing dynamic libs
sudo apt install libsndfile1-dev libsamplerate0-dev # specifically for faust
```

Then

```bash
git clone https://github.com/shakfu/cyfaust.git
cd cyfaust
make # or python3 scripts/manage.py setup --faust
```

- This will download faust into the `build` directory, then configure (and patch) it for an interpreter build, build it, and install it into the following (.gitignored) folders in the project directory:

  - `bin`, containing the faust executables,
  - `lib`, the dynamic and static versions of `libfaust` and
  - `share`, the faust standard libs and examples.

- Faust version `2.83.1` will be used as it is a stable reference to work with and is used by the setup scripts.

- The script can be run again and will create (and overwrite) the corresponding files in the `bin`, `include`, `lib` and `share` folders.

To build the default dynamically-linked package and/or wheel:

```bash
make
```

or using `uv` (the project now uses `scikit-build-core`):

```bash
uv build --wheel
```

For a wheel:

```bash
make wheel
```

For a Windows wheel with bundled DLL (one-shot build):

```bash
make wheel-windows
```

For the static variant, set the `STATIC=1` environment variable with make, or use `CMAKE_ARGS` for direct builds:

```bash
make STATIC=1
```

or

```bash
CMAKE_ARGS="-DSTATIC=ON" uv build --wheel
```

### LLVM Backend (cyfaust-llvm)

The LLVM backend compiles Faust DSP code to native machine code via LLVM JIT, offering significantly faster execution compared to the interpreter backend. It is distributed as a separate package: `cyfaust-llvm`.

#### Interpreter vs LLVM

| Feature | cyfaust (interpreter) | cyfaust-llvm |
|---------|----------------------|--------------|
| Binary size | ~8MB | ~33MB |
| DSP execution | Bytecode interpreter | Native machine code |
| Compilation speed | Fast | Slower (JIT compilation) |
| Runtime performance | Good | Best |
| Use case | Development, lightweight deployment | Production, performance-critical |

#### Installation

Install from PyPI:

```bash
pip install cyfaust-llvm
```

Both packages provide the same API via `from cyfaust import cyfaust` - only the backend differs.

#### Building from Source

##### Prerequisites

**macOS:**
```bash
# Install Xcode CommandLine tools if not already installed
xcode-select --install

# Install dependencies via Homebrew
brew install python cmake
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt update
sudo apt install build-essential git cmake python3-dev
sudo apt install libasound2-dev patchelf
sudo apt install libsndfile1-dev libsamplerate0-dev
sudo apt install libtinfo-dev  # Required for LLVM
```

##### Build Steps (macOS & Linux)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/shakfu/cyfaust.git
   cd cyfaust
   ```

2. **Download the prebuilt LLVM-enabled libfaust:**
   ```bash
   # Using make
   make faustwithllvm

   # Or using manage.py directly
   python3 scripts/manage.py setup --llvm
   ```

   This downloads `libfaustwithllvm.a` (~300MB) from the official Faust releases:
   - macOS: Downloads DMG for your architecture (arm64 or x86_64)
   - Linux: Downloads zip for your architecture (x86_64 or aarch64)

3. **Build for development:**
   ```bash
   make build-llvm
   ```

4. **Run tests:**
   ```bash
   make test-llvm
   ```

##### Building Wheels

To build a distributable wheel:

```bash
make wheel-llvm
```

This creates `dist/cyfaust_llvm-<version>-<platform>.whl`.

Or build directly with uv/cmake:

```bash
# First ensure libfaustwithllvm.a is downloaded
make faustwithllvm

# Generate static sources
python3 scripts/generate_static.py

# Build wheel
CMAKE_ARGS="-DSTATIC=ON -DLLVM=ON" uv build --wheel

# Rename to cyfaust-llvm (required for PyPI)
python3 scripts/rename_wheel.py dist/cyfaust-*.whl cyfaust-llvm --delete
```

#### Usage

The API is identical regardless of backend:

```python
from cyfaust import cyfaust

# Create a DSP factory from Faust code
factory = cyfaust.create_dsp_factory_from_string(
    "volume",
    "process = *(hslider(\"gain\", 0.5, 0, 1, 0.01));"
)

# Create DSP instance
dsp = factory.create_dsp_instance()
print(f"Inputs: {dsp.get_num_inputs()}, Outputs: {dsp.get_num_outputs()}")
```

#### Detecting Backend at Runtime

```python
import cyfaust

# Check which backend is available
print(f"LLVM Backend: {cyfaust.LLVM_BACKEND}")

if cyfaust.LLVM_BACKEND:
    # LLVM-specific: get target machine info
    print(cyfaust.get_dsp_machine_target())
    # e.g., 'x86_64-pc-linux-gnu' or 'arm64-apple-darwin24.6.0'
```

#### Platform Support

**Interpreter Backend (cyfaust):**

| Platform | Architecture | Status |
|----------|-------------|--------|
| macOS | arm64 (Apple Silicon) | Supported |
| macOS | x86_64 (Intel) | Supported |
| Linux | x86_64 | Supported |
| Linux | aarch64 | Supported |
| Windows | x86_64 | Supported |

**LLVM Backend (cyfaust-llvm):**

| Platform | Architecture | Status |
|----------|-------------|--------|
| macOS | arm64 (Apple Silicon) | Supported |
| macOS | x86_64 (Intel) | Supported |
| Linux | x86_64 | Supported |
| Linux | aarch64 | Supported |
| Windows | x86_64 | Planned |

To run the tests

```bash
make test
```

or

```bash
make pytest
```

## Prior Art of Faust + Python

- [DawDreamer](https://github.com/DBraun/DawDreamer) by David Braun: Digital Audio Workstation with Python; VST instruments/effects, parameter automation, FAUST, JAX, Warp Markers, and JUCE processors. Full-featured and well-maintained. Use this for actual work! (pybind11)

- [faust_python](https://github.com/marcecj/faust_python) by Marc Joliet: A Python FAUST wrapper implemented using the CFFI (updated 2015). There's a more recent (updated in 2019) [fork](https://github.com/hrtlacek/faust_python) by Patrik Lechner. (cffi)

- [pyfaust](https://github.com/amstan/pyfaust) by Alexandru Stan: Embed Faust DSP Programs in Python. (cffi)

- [faust-ctypes](https://gitlab.com/adud2/faust-ctypes): a port of Marc Joliet's FaustPy from CFFI to Ctypes. (ctypes)

- [faustpp](https://github.com/jpcima/faustpp): A post-processor for faust, which enables more flexible code generation.
