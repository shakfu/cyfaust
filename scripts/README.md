# cyfaust scripts

A significant effort was put into moving more complex setup and/or build logic from the project's `Makefile` or bash scripts to python scripts. These are generally triggered from the `Makefile` (there is an open question on whether these should be integrated into one `manage.py` script:

- `setup_faust.py`: downloads, builds, and installs faust into the project's `bin`, `lib`, and `share` folders

- `wheel_mgr.py`: handles wheel building ops.

- `get_debug_python.py`: builds a local debug python and installs it into `cyfaust/python` for additional debugging capabilities.

- `build_wheel.py`: example of solving macos wheel building on github runners which default to `universal2` wheel builds.

