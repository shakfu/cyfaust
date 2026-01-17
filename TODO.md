# TODO

## General

- [x] Stay in sync with major faust releases (currently tracking `2.83.1`)

## cyfaust - Core API

### Completed

- [x] Fix Soundfile support so that it works out of the box without compilation
- [x] Implement `get_memory_manager()` and `set_memory_manager()` factory methods
- [x] Implement `class_init()` factory method
- [x] Implement `build_user_interface()` with optional `sound_directory` and `sample_rate` parameters
- [x] Add static build generation script (`scripts/generate_static.py`)

### High Priority

- [ ] Implement `control()` method for control-rate processing
- [ ] Implement `frame()` method for single-frame processing
- [ ] Implement timestamped `compute()` variant for sample-accurate timing
- [ ] Implement `metadata()` method with proper `Meta` interface support

### Medium Priority

- [ ] Add `cyfaust/__main__.py` command-line interface
- [ ] Add additional Python debug/validation checks

## cyfaust.interp

- [x] `InterpreterDsp.build_user_interface` now accepts optional parameters for sound directory and sample rate

- [ ] Complete `InterpreterDsp.metadata` to properly accept `fi.Meta*` parameter

## cyfaust.box

### High Priority

- [ ] Add more box API tests to improve coverage

### Medium Priority

- [ ] Harmonize `box.getparams` and `signal.is_sig_xxx` APIs for consistency
- [ ] Add thin wrapper classes around `Box` for specific box types

### Low Priority

- [ ] Investigate use case for `getUserData` (returns xtended type of a box)

## cyfaust.signal

### High Priority

- [ ] Fix `Interval` wrapper and implement `get_interval`, `set_interval` methods
- [ ] Add more signal API tests to improve coverage

### Medium Priority

- [ ] Harmonize `signal.is_sig_xxx` and `box.getparams` APIs for consistency
- [ ] Add thin wrapper classes around `Signal` for specific signal types
- [ ] Improve docstrings throughout the signal module

### Low Priority

- [ ] Investigate use case for `getUserData` (returns xtended type of a signal)
