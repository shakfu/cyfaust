# cyfaust

Intended to be a minimal, modular, self-contained, cross-platform [cython](https://github.com/cython/cython) wrapper of the [Faust](https://github.com/grame-cncm/faust) *interpreter* and the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver.

This project started off as a [faustlab](https://github.com/shakfu/faustlab) subproject of the same name.

It has two build variants:

1. The default build is dynamically linked to `libfaust.dylib` or `libfaust.so` and consists of a python package with multiple compiled submodules and embedded resources (faust libraries and architecture files):

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

2. The static build is statically linked (with `libfaust.a`) and consists of a python package with a single compiled submodule and embedded resources (faust libraries and architecture files):

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

Currently dveloped and tested only on macOS `x86_64` and `arm64`. A linux version is intermittently under development.


## Features

- Python-oriented implementation of the faust intrepreter

- Provides the following submodules (in the default build):

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

- Both build variants can be packaged as a self-contained python wheel.


## Status

Wrapping and modularization are mostly complete except for a few areas (see `TODO`). Current priorities are:

- Address any instability, crashes, etc..

- Complete Linux support

- Create further tests

- Working through remaining items in the todo list



## Setup and Requirements


**Requires:**

- `cmake` (to build faust)

- `python3` with dev libraries installed

- `cython`

Optional

- `make` (build frontend)

macOS

- `delocate` (for including `libfaust.dylib` in wheels)


**To Build:**


1. `./scripts/setup.sh` or, `./scripts/setup_faust.py`:

    - Faust version `2.69.3` is known to work and is used by the setup scripts.

    - This will download faust into the `build` directory, configure it, build it, and install the build into a local `prefix` inside the `build` directory/

    - The faust executable, staticlib / dylib, headers and stdlib from the newly installed local prefix will be copied into the project directory and and will create (and overwrite) the corresponding files in the `bin`, `include`, `lib` and `share` folders.

2. To build the default variant package and/or wheel:
    

```bash
make
```

or 

```bash
python3 setup.py build
```
 
and for a wheel:

```bash
make wheel
```

For the static variant just set the environ variable `STATIC=1` at the end of the above make commands or at the beginning of the python3 commands. 

For example:

```bash
make STATIC=1
```

etc.

3. `make test` will run the tests in sequence. You can also run `pytest` to do the same.


## Prior Art of Faust + Python

- [DawDreamer](https://github.com/DBraun/DawDreamer) by David Braun: Digital Audio Workstation with Python; VST instruments/effects, parameter automation, FAUST, JAX, Warp Markers, and JUCE processors. Full-featured and well-maintained. Use this for actual work! (pybind11)

- [faust_python](https://github.com/marcecj/faust_python) by Marc Joliet: A Python FAUST wrapper implemented using the CFFI. There's a more recent [fork](https://github.com/hrtlacek/faust_python]) by Patrik Lechner. (cffi)

- [pyfaust](https://github.com/amstan/pyfaust) by Alexandru Stan: Embed Faust DSP Programs in Python. (cffi)

- [faust-ctypes](https://gitlab.com/adud2/faust-ctypes): a port of Marc Joliet's FaustPy from CFFI to Ctypes. (ctypes)

- [faustpp](https://github.com/jpcima/faustpp): A post-processor for faust, which enables more flexible code generation.

