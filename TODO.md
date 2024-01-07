# TODO


##  cyfaust

- [x] Decide what data files to include in the package {faust stdlib, archtecture files}.

- [ ] Add cyfaust examples


## cyfaust.interp

- [ ] Complete `InterpreterDsp.build_user_interface` to properly accept `fi.UI* instances`

- [ ] Complete `InterpreterDsp.metadata` and `fi.Meta* m` parameter

- [x] How to specify output file for svg, `-o <path.svg>` doesn't work? (not possible)


## cyfaust.box

- [ ] Try to find a use for `getUserData`: Return the xtended type of a box

- [ ] Add classes (thin wrappers around `Box`)

- [x] Improve docstrings

- [ ] `box.getparams` and `signal.is_sig_xxx` are inconsistent apis

- [x] auto set package-local libraries and architecture paths 

```
-A <dir>  --architecture-dir <dir>      add <dir> to the architecture search path.

-I <dir>  --import-dir <dir>            add <dir> to the libraries search path

```


## cyfaust.signal

- [ ] Fix `Interval` wrapper and `get_interval`, `set_interval` methods

- [ ] Try to find a use for `getUserData`: Return the xtended type of a box

- [ ] Add classes (thin wrappers around `Signal`)

- [ ] Improve docstrings

- [ ] `signal.is_sig_xxx` and `Box.getparams` are inconsistent apis

