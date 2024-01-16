# TODO


##  cyfaust

- [ ] Add github workflows

- [ ] Add Linux support

	- [ ] Fix segfault in cases of dsp_from_boxes / signals (maybe only a problem on arm64 linux?)

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
