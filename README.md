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

While this project has been developed and tested primarily on macOS (`x86_64` and `arm64`), there have been recent efforts to support Linux (`amd64` and `aarch64`).

## Features

- Python-oriented implementation of the [faust interpreter](https://faustdoc.grame.fr/manual/embedding/#using-libfaust-with-the-interpreter-backend)

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

## Status

- Supports most of faust interpreter, box and signals apis (see [TODO](https://github.com/shakfu/cyfaust/blob/main/TODO.md))

- Works on macOS and Linux {x86_64, arm64}

- Provides two build variants: one dynamically-linked to `libfaust.[so|dylib]` and the other statically-linked to `libfaust.a`

- Several github workflows are provided which automate the testing and building of cyfaust wheels using supported github runners.

Current priorities are to work through remaining items in the `TODO` list.

## Setup and Requirements

In summary,

| #  | platform | step                    | command                                                      |
|:--:|:-------- | :---------------------- |:------------------------------------------------------------ |
| 1a | macOS    | install pre-reqs        | `brew install python cmake`                                  |
| 1b | linux    | install pre-reqs        | `sudo apt install python3-dev cmake libasound2-dev patchelf` |
| 2  | common   | install python pkgs     | `pip3 install -r requirements.txt`                           |
| 3* | common   | build/install faustlib  | `./scripts/setup_faust.py`                                   |
| 4  | common   | build cyfaust           | `make`                                                       |
| 5  | common   | test cyfaust            | `make pytest`                                                |

`*`: Note that step 3 can be skipped: you don't have to manually type `./scripts/setup_faust.py` if you just type `make` (see 3 below).

Also note that 1a and 1b are platform-specific, and that 1-3 are only to be done once to set up the build environment, while 4 and 5 can be run any number of times thereafter.

1. Platform specific requirements are as follows:

    For macOS, something like this:

    ```bash
    brew install python cmake
    ```

    For Linux, something like this:

    ```bash
    sudo apt update
    sudo apt install python3-dev cmake libasound2-dev patchelf
    ```

2. Then (in either case) install the required python packages as follows:

    ```bash
    pip3 install -r requirements
    ```

3. Run `./scripts/setup_faust.py`:

    - Manually running this step is not strictly necessary, as the default `make` command will check if `libfaust.a` has been built and if it hasn't it will run  `./scripts/setup_faust.py`.

    - This will download faust into the `build` directory, then configure (and patch) it for an interpreter build, build it, and install it into the following (.gitignored) folders in the project directory:

        - `bin`, containing the faust executables,
        - `lib`, the dynamic and static versions of `libfaust` and
        - `share`, the faust standard libs and examples.

    - Faust version `2.69.3` will be used as it is known to work and is used by the setup scripts.

    - The script can be run again and will create (and overwrite) the corresponding files in the `bin`, `include`, `lib` and `share` folders.

4. To build the default dynamically-linked package and/or wheel:

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

5. To run the tests

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
