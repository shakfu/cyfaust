# cyfaust scripts

This folder contains some python and shell scripts which may be required triggered by the Makefile, used for testing, or created to be run on a one-off basis.


## Required

- `manage.py`: main cross-platform cyfaust project mgmt script which can used directly or called by the `Makefile` frontend and the github workflwos. 

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

	- installs all dependencies irrespective of platform.

	- downloads, builds, and installs faust into the project's `bin`, `lib`, and `share` folders. It uses the following patches files in the `scripts/patch` folder:

		- `faust.mk`

		- `interp_plus_backend.cmake`

		- `interp_plus_target.cmake`

		- `rtaudio-dsp.h`

	- downloads, builds, and installs libsndfile and libsamplerate into project's `lib` and `include` folders (wip).

	- handles wheel building ops.


- `gen_htmldoc.py`: a script to generate htmldocs from cyfaust writing to `docs/api`. (may be integrated into `manage.py` at some point.)


## Testing

- `setup_debug_python.py`: builds a local debug python and installs it into `cyfaust/python` for additional debugging capabilities.

- `test_cpp_tests.sh`: builds c and c++ faust interpreter tests.

- `mkvenv.sh`: creates a virtualenv `venv` in the project and install cyfaust using it.

- `inspect_cyfaust.py`: cyfaust object reflection code using `inspect` module


## Unused or used just once

- `setup_libfaust_llvm.sh`: downloads, builds llvm faust.

- `build_wheel.py`: example of solving macos wheel building on github runners which default to `universal2` wheel builds.

- contents of the `scripts/static` folder, contains scripts which were use to parse and generate code and also for a prior cmake-based build.


