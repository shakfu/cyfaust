# cyfaust

A [cython](https://github.com/cython/cython) wrapper of the [Faust](https://github.com/grame-cncm/faust) *interpreter* and the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver.

The objective is to end up with a minimal, modular, self-contained, cross-platform python3 extension.

This project started off as a [faustlab](https://github.com/shakfu/faustlab) subproject and was spun-off into its own project.

## Status

cyfaust is a python package which consists of the following builtin modules:

- `cyfaust.interp`: wraps the faust interpreter and the rtaudio audio driver
- `cyfaust.box`: wraps the faust box api
- `cyfaust.signal`: wraps the faust signal api
- `cyfaust.common`: commons utilities and classes

Wrapping and modularization are mostly complete except for a few areas the task at hand is to create a test suite.

## Usage

Requires:

- `python3` with dev libraries installed

- `cython`

Optional

- `make` (build frontend)


Developed and tested only on macOS x86_64 and arm64 for the time being.

1. `./scripts/setup.sh`

    - This will download faust into the `build` directory, configure it, build it, and install the build into a local `prefix` inside the `build` directory/

    - The faust executable, staticlib, headers and stdlib from the newly installed local prefix will be copied into the project directory and and will create (and overwrite) the corresponding files in the `bin`, `include`, `lib` and `share` folders.

2. `make`
    
    - will build `cyfaust`

3. `make test` will test the `cyfaust.interp` module and audio driver and will interpret a `noise.dsp` mmodule and produce "noise" if successful.


## Prior Art of Faust + Python

- [DawDreamer](https://github.com/DBraun/DawDreamer) by David Braun: Digital Audio Workstation with Python; VST instruments/effects, parameter automation, FAUST, JAX, Warp Markers, and JUCE processors. Full-featured and well-maintained. Use this for actual work! (pybind11)

- [faust_python](https://github.com/marcecj/faust_python) by Marc Joliet: A Python FAUST wrapper implemented using the CFFI. There's a more recent [fork](https://github.com/hrtlacek/faust_python]) by Patrik Lechner. (cffi)

- [pyfaust](https://github.com/amstan/pyfaust) by Alexandru Stan: Embed Faust DSP Programs in Python. (cffi)

- [faust-ctypes](https://gitlab.com/adud2/faust-ctypes): a port of Marc Joliet's FaustPy from CFFI to Ctypes. (ctypes)

- [faustpp](https://github.com/jpcima/faustpp): A post-processor for faust, which enables more flexible code generation.

