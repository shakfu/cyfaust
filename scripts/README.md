# cyfaust scripts

This folder contains some python and shell scripts which may be required triggered by the Makefile, used for testing, or created to be run on a one-off basis.


## Required

- `setup_faust.py`: downloads, builds, and installs faust into the project's `bin`, `lib`, and `share` folders. It uses the following patches files in the `scripts/patch` folder:

	- `faust.mk`

	- `interp_plus_backend.cmake`

	- `interp_plus_target.cmake`

	- `rtaudio-dsp.h`

- `setup_sndfile.sh`: downloads, builds, and installs libsndfile and libsamplerate into project's `lib` and `include` folders (wip).

- `wheel_mgr.py`: handles wheel building ops.

## Testing

- `setup_debug_python.py`: builds a local debug python and installs it into `cyfaust/python` for additional debugging capabilities.

- `test_cpp_tests.sh`: builds c and c++ faust interpreter tests.

- `mkvenv.sh`: creates a virtualenv `venv` in the project and install cyfaust using it.

- `inspect_cyfaust.py`: cyfaust object reflection code using `inspect` module


## Unused or used just once

- `install_deps.py`: install all dependencies irrespective of platform.

- `setup_libfaust_llvm.sh`: downloads, builds llvm faust.

- `build_wheel.py`: example of solving macos wheel building on github runners which default to `universal2` wheel builds.

- `gen_htmldoc.py`: beginnings of a script to generate htmldocs from cyfaust (not really working).

- contents of the `scripts/static` folder, contains scripts which were use to parse and generate code and also for a prior cmake-based build.


