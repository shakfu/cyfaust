# TODO


##  cyfaust

- [ ] Add Linux support (almost done except requires `#include <limits>` in `faust/export.h`)

- [ ] Add more tests


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

