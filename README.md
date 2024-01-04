# cyfaust

A [cython](https://github.com/cython/cython) wrapper of the [Faust](https://github.com/grame-cncm/faust) *interpreter* and the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver.

Built with the objective of having a minimal, modular, self-contained, cross-platform python3 extension.

This project started off as a [faustlab](https://github.com/shakfu/faustlab) subproject of the same name which was built as a single statically compiled module. After this was modularized into a package, it was spun off as this project which exclusively uses a standard python build systems (setup.py, etc..)

## Features

- Python-oriented implementation of the faust intrepreter

- Provides the following submodules:

    - `cyfaust.interp`: wraps the faust interpreter and the rtaudio audio driver

    - `cyfaust.box`: wraps the faust box api

    - `cyfaust.signal`: wraps the faust signal api

    - `cyfaust.common`: common utilities and classes

- Self-contained, minimal, and modular design

- Does not use LLVM to keep size low.

- Can generate code using the following backends:
     - c++
     - c
     - rust
     - codebox

- Can generate auxiliary files such as svg block diagrams of dsp

- Dual functional/oo design for box and signal api with minimal code duplication.

- Implements Memorviews for read/write to numpy buffers

- Can be converted to a self-contained python wheel (2MB): the submodules are dymically linked to `libfaust.dylib` which is embedded in the wheel.


## Status

Wrapping and modularization are mostly complete except for a few areas (see `TODO`). Current focus is on creating a test suite, and working through remaining items in the todo list.

## Usage

Requires:

- `python3` with dev libraries installed

- `cython`

Optional

- `make` (build frontend)


Developed and tested only on macOS x86_64 and arm64 for the time being.

1. `./scripts/setup.sh`

    - This will download faust into the `build` directory, configure it, build it, and install the build into a local `prefix` inside the `build` directory/

    - The faust executable, staticlib / dylib, headers and stdlib from the newly installed local prefix will be copied into the project directory and and will create (and overwrite) the corresponding files in the `bin`, `include`, `lib` and `share` folders.

2. `make`
    
    - will build `cyfaust`

3. `make test` will run the tests in sequence. You can also run `pytest` to do the same.


## Prior Art of Faust + Python

- [DawDreamer](https://github.com/DBraun/DawDreamer) by David Braun: Digital Audio Workstation with Python; VST instruments/effects, parameter automation, FAUST, JAX, Warp Markers, and JUCE processors. Full-featured and well-maintained. Use this for actual work! (pybind11)

- [faust_python](https://github.com/marcecj/faust_python) by Marc Joliet: A Python FAUST wrapper implemented using the CFFI. There's a more recent [fork](https://github.com/hrtlacek/faust_python]) by Patrik Lechner. (cffi)

- [pyfaust](https://github.com/amstan/pyfaust) by Alexandru Stan: Embed Faust DSP Programs in Python. (cffi)

- [faust-ctypes](https://gitlab.com/adud2/faust-ctypes): a port of Marc Joliet's FaustPy from CFFI to Ctypes. (ctypes)

- [faustpp](https://github.com/jpcima/faustpp): A post-processor for faust, which enables more flexible code generation.

