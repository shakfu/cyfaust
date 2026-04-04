# TODO

## cyfaust - Core API

- [ ] Add additional Python debug/validation checks

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
