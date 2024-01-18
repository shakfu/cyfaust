# TODO

- Wrapping and modularization are mostly complete except for a few areas (see `TODO` for details).

- Early focus on stamping out memory leaks and resource cleanup bugs seems to have paid off as the intermittent segfaults which plagued early versions are now relatively rare across the two supported platforms.

- While Linux support has progressed well, there are still some issues to resolve such as:

  - support is more recent, therefore the expectation of more instability and bugs, etc.

  - the more fragmented nature of linux audio drivers (currently ALSA is only supported).

  - binary size and compatibility across linux distributions (the need to build on a `manylinux` container for example)

- A significant effort was put into moving more complex build or setup logic from the `Makefile` or bash scripts to python scripts. These are generally triggered from the `Makefile`:

  - `scripts/setup_faust.py`: downloads, builds, and installs faust into the project's `bin`, `lib`, and `share` folders

  - `scripts/wheel_mgr.py`: handles wheel building ops.

  - `scripts/get_debug_python.py`: builds a local debug python and installs it into `cyfaust/python` for additional debugging capabilities.

- Another current challenge is to automate wheel building across supported platforms and architectures. Despite the availabilty of infrastructure such as github actions and [cibuildwheel](https://github.com/pypa/cibuildwheel), this has proven to be more complex than anticipated.

## cyfaust

- [ ] Add working github workflows

- [ ] Add Linux support

- [ ] Fix Soundfile support so that it works out of the box without compilation.

- [ ] Add more tests

  - [x] Add all interpreter tests

  - [ ] Add all box api tests

  - [ ] Add all signal api test

- [ ] Add `cython/__main__.py` commandline interface.

- [ ] Add additional python debug checks

## cyfaust.interp

- [ ] Complete `InterpreterDsp.build_user_interface` to properly accept `fi.UI* instances`

- [ ] Complete `InterpreterDsp.metadata` and `fi.Meta* m` parameter

## cyfaust.box

- [ ] Try to find a use for `getUserData`: Return the xtended type of a box

- [ ] Add classes (thin wrappers around `Box`)

- [x] Improve docstrings

- [ ] `box.getparams` and `signal.is_sig_xxx` are inconsistent apis

## cyfaust.signal

- [ ] Fix `Interval` wrapper and `get_interval`, `set_interval` methods

- [ ] Try to find a use for `getUserData`: Return the xtended type of a box

- [ ] Add classes (thin wrappers around `Signal`)

- [ ] Improve docstrings

- [ ] `signal.is_sig_xxx` and `Box.getparams` are inconsistent apis
