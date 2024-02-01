# TODO

## cyfaust

- [ ] Fix Soundfile support so that it works out of the box without compilation.

- [ ] Add `cython/__main__.py` commandline interface.

- [ ] Add additional python debug checks

## cyfaust.interp

- [ ] Complete `InterpreterDsp.build_user_interface` to properly accept `fi.UI* instances`

- [ ] Complete `InterpreterDsp.metadata` and `fi.Meta* m` parameter

## cyfaust.box

- [ ] Try to find a use for `getUserData`: Return the xtended type of a box

- [ ] Add classes (thin wrappers around `Box`)

- [ ] `box.getparams` and `signal.is_sig_xxx` are inconsistent apis

- [ ] Add more box api tests

## cyfaust.signal

- [ ] Fix `Interval` wrapper and `get_interval`, `set_interval` methods

- [ ] Try to find a use for `getUserData`: Return the xtended type of a box

- [ ] Add classes (thin wrappers around `Signal`)

- [ ] Improve docstrings

- [ ] Add more signal api tests

- [ ] `signal.is_sig_xxx` and `Box.getparams` are inconsistent apis
