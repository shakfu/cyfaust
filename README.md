# cyfaust

The aim of the cyfaust project is develop a minimal, modular, self-contained, cross-platform [cython](https://github.com/cython/cython) wrapper of the [Faust](https://github.com/grame-cncm/faust) *interpreter* and the [RtAudio](https://github.com/thestk/rtaudio) cross-platform audio driver.

To this end, a decent amount of progress has been made, with current code running successfully on faust version `2.81.2`, and with some key work left to do (see [Project Status](https://github.com/shakfu/cyfaust?tab=readme-ov-file#project-status) below). 

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

## Project Status

The project is still relatively early stage and a work-in-progress, with key remaining parts not yet implemented (see the project's [TODO](https://github.com/shakfu/cyfaust/blob/main/TODO.md) file.

Nonetheless,

- A good chunk of the faust interpreter (in Faust version `2.81.2`), and also the box and signal apis have been wrapped with tntegration of the rtaudio cross-platform audio driver.

- Works on macOS, Linux and Windows.

- Provides two build variants: one dynamically-linked to `libfaust.(so|dylib)` and the other statically-linked to `libfaust.(a|lib)`

Current priorities are to work through remaining items in the `TODO` list.

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

2. `libsndile` and `libsamplerate` for faust `soundfile` primitive support (not yet implemented)

Platform specific requirements are covered in the next sections.

## Windows

To build cyfaust you will need python to be installed (3.9+), a c++ compiler such as [visual studio community edition](https://visualstudio.microsoft.com/vs/community/) and make sure to install c++ and Windows SDK development support, as well as `git`, and `cmake`.

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

- Faust version `2.81.2` will be used as it is a stable reference to work with and is used by the setup scripts.

- The script can be run again and will create (and overwrite) the corresponding files in the `bin`, `include`, `lib` and `share` folders.

To build the default dynamically-linked package and/or wheel:

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

For the static variant just set the environment variable `STATIC=1` at the end of the above make commands or at the beginning of the python3 commands.

For example:

```bash
make STATIC=1
```

etc.

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
