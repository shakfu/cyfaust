# TODO

## cyfaust - Core API

- [ ] Add additional Python debug/validation checks
- [ ] Guard instance methods against a destroyed backing factory (try option B and verify it is effective). After `delete_all_dsp_factories()` (or the owning factory being otherwise destroyed) any `InterpreterDsp` method that dereferences `self.ptr` -- `clone()`, `init()`, `compute()`, etc. -- is a use-after-free that segfaults (e.g. `clone()` exits 139). `clone()` already holds a weakref to its factory; investigate a shared `_check_live()` helper that raises a catchable `RuntimeError` when the factory weakref is dead or `factory.ptr == NULL`, used across the instance methods, turning the crash into a clean exception. Confirm it actually prevents the segfault (the naive `owner=True` fallback in `clone()` did not -- the crash is in `self.ptr.clone()` before teardown). Note the consistency cost: either guard all such methods or none.

## cyfaust.box

### High Priority

- [x] Add more box API tests to improve coverage (~12% currently)

### Medium Priority

- [ ] Add thin wrapper classes around `Box` for specific box types

### Low Priority

- [ ] Uncomment and expose `getUserData` wrapper (declared in .pxd, commented out in .pyx)

## cyfaust.signal

### High Priority

- [x] Add more signal API tests to improve coverage (~6% currently)
- [ ] Enable `get_interval` and `set_interval` methods on `Signal` (wrapper code is ready but libfaust aborts on raw signal trees -- requires type-inferred signals, needs a safe guard or upstream fix)

### Medium Priority

- [ ] Add thin wrapper classes around `Signal` for specific signal types
- [ ] Improve docstrings throughout the signal module (~44% coverage vs box's ~98%)

### Low Priority

- [ ] Uncomment and expose `getUserData` wrapper (declared in .pxd, commented out in .pyx)
