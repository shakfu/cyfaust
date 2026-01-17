# cyfaust

The aim of the cyfaust project is develop a minimal, modular, self-contained, cross-platform [cython](https://github.com/cython/cython) wrapper of the [Faust](https://github.com/grame-cncm/faust) *interpreter* and the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver.

The project is now running on Faust version `2.83.1` with the full interpreter API wrapped, including the box and signal APIs (see [Project Status](#project-status) below). 

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

## Features

- Python-oriented cross-platform implementation of the [faust interpreter](https://faustdoc.grame.fr/manual/embedding/#using-libfaust-with-the-interpreter-backend)

- Provides the following submodules (in the default build):

  - `cyfaust.interp`: wraps the faust interpreter and the rtaudio audio driver

  - `cyfaust.box`: wraps the [faust box api](https://faustdoc.grame.fr/tutorials/box-api/)

  - `cyfaust.signal`: wraps the [faust signal api](https://faustdoc.grame.fr/tutorials/signal-api/)

  - `cyfaust.common`: common utilities and classes

- Self-contained, minimal, and modular design

- Deliberately does not use LLVM to remove dependency on `libLLVM.[dylib|so]` and keep size of python extension low (libLLVM14 is 94MB).

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

## Project Status

The project provides a complete wrapping of the Faust interpreter API:

- **Interpreter API**: Fully wrapped with RtAudio cross-platform audio driver integration
- **Box API**: Fully wrapped with both functional and object-oriented interfaces
- **Signal API**: Fully wrapped with both functional and object-oriented interfaces
- **Platform Support**: macOS, Linux, and Windows
- **Build Variants**: Dynamic (`libfaust.so|dylib`) and static (`libfaust.a|lib`)
- **Faust Version**: `2.83.1`

See the project's [TODO](https://github.com/shakfu/cyfaust/blob/main/TODO.md) for remaining enhancements.

## Setup and Requirements

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

## Windows

To build cyfaust you will need python to be installed (3.10+), a c++ compiler such as [visual studio community edition](https://visualstudio.microsoft.com/vs/community/) and make sure to install c++ and Windows SDK development support, as well as `git`, and `cmake`.

Then do something like the following in a terminal:

```bash
git clone https://github.com/shakfu/cyfaust.git
cd cyfaust
pip install -r requirements.txt # or python3 scripts/manage.py setup --deps
python scripts/manage.py setup --faust
# then pick from 3, 4 or 6. For example
python scripts/manage.py build
pytest
# etc..
```

## macOS & Linux

On macOS and Linux, a `Makefile` is available as a frontend to the above `manage.py` script to make it a little quicker to use.

The following setup sequence is illustrative of this and is also useful if you want to setup cyfaust manually.

For macOS, having Xcode or the CommandLine tools (`xcode-select --install`) installed is required, and then you will need to have python and cmake installed. If you use [Homebrew](https://brew.sh), this is simply:

```bash
brew install python cmake
```

For Linux, if you are on a Debian-derived system, you will need something like the following:

```bash
sudo apt update
sudo apt install build-essential git cmake python3-dev # you probably have these already
sudo apt install libasound2-dev patchelf
```

Then

```bash
git clone https://github.com/shakfu/cyfaust.git
cd cyfaust
pip3 install -r requirements
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

For the static variant, set the `STATIC=1` environment variable with make, or use `CMAKE_ARGS` for direct builds:

```bash
make STATIC=1
```

or

```bash
CMAKE_ARGS="-DSTATIC=ON" uv build --wheel
```

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
