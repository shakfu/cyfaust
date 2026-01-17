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
- [x] Implement `control()` method for control-rate processing
- [x] Implement `frame()` method for single-frame processing
- [x] Implement `compute_timestamped()` method for sample-accurate timing (API compatible, interpreter delegates to standard compute)
- [x] Implement `metadata()` method returning DSP metadata as a Python dictionary

### Medium Priority

- [x] Add `cyfaust/__main__.py` command-line interface
- [ ] Add additional Python debug/validation checks

## cyfaust.interp

- [x] `InterpreterDsp.build_user_interface` now accepts optional parameters for sound directory and sample rate
- [x] `InterpreterDsp.metadata()` now returns a Python dictionary of metadata key-value pairs

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
