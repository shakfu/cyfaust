# TODO


##  cyfaust

- [ ] Add Linux support

	- [x] compile without errors: added `CPPFLAGS=-'include limits'` to env

	- [ ] Fix large binaries

	- [ ] Fix segfault in cases of dsp_from_boxes / signals

- [ ] Fix Soundfile support so that it works out of the box without compilation.

- [ ] Add more tests

- [ ] Add `cython/__main__.py` commandline interface.

- [ ] Fix SANITIZE option if possible (failing on both macos and linux)

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
