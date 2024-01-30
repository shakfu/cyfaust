# cyfaust scripts

This folder contains some python and shell scripts which may be run directly or triggered by the Makefile.


## Required

- `manage.py`: main cross-platform cyfaust project mgmt script which can be used directly or called by the `Makefile` frontend in the case of macos and linux as well as the github workflows. 

	```bash
	% ./scripts/manage.py --help
	usage: manage.py [-h] [-v]  ...

	options:
	  -h, --help     show this help message and exit
	  -v, --version  show program's version number and exit

	subcommands:
	  valid subcommands

	                 additional help
	    build        build cyfaust
	    clean        clean project detritus
	    setup        setup faust
	    test         test cyfaust modules
	    wheel        build cyfaust wheel
	```

	It has the following features:

	- installs all platform-specific dependencies.

	- downloads, builds, and installs `faust`` into the project's `bin`, `lib`, and `share` folders. It uses the following patched files in the `scripts/patch` folder:

		- `faust.mk`

		- `interp_plus_backend.cmake`

		- `interp_plus_target.cmake`

		- `rtaudio-dsp.h`

	- downloads, builds, and installs `libsndfile` and `libsamplerate` into project's `lib` and `include` folders (wip).

	- handles wheel building ops.

	- etc..


- `gen_htmldoc.py`: a script to use pydoc to generate html documentation of the cyfaust api writing to `docs/api`. (may be integrated into `manage.py` at some point.)


## Testing

- `setup_debug_python.py`: builds a local debug python and installs it into `cyfaust/python` for additional debugging capabilities.

- `test_cpp_tests.sh`: builds c and c++ faust interpreter tests.

- `mkvenv.sh`: creates a virtualenv `venv` in the project and install cyfaust using it.

- `inspect_cyfaust.py`: cyfaust object reflection code using `inspect` module


## Unused or used just once

- `setup_libfaust_llvm.sh`: downloads, builds llvm faust.

- `build_wheel.py`: example of solving macos wheel building issues on github runners which default to `universal2` wheel builds.

- contents of the `scripts/static` folder, contains scripts which were use to parse and generate code and also for a prior cmake-based build.


