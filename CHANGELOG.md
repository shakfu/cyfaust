# CHANGELOG

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Commons Changelog](https://common-changelog.org). This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Types of Changes

- Added: for new features.
- Changed: for changes in existing functionality.
- Deprecated: for soon-to-be removed features.
- Removed: for now removed features.
- Fixed: for any bug fixes.
- Security: in case of vulnerabilities.

---

## [0.0.x]

### cyfaust

- Added Windows support to `setup_cyfaust.py`. It can now build a faust interpreter-centric `libfaust.lib`, `libfaust.dll` and `faust.exe`.

- Added experimental faust github workflow to build faust interp-enabled `libfaust.(a|dll)`

- Added enhancements to `gen_htmldoc.py` python script and makefile target, `make docs`, to generate api docs in html for both build variants.

- Fixed issue with upload artifact which caused an error in wheel building. Now artifact names are properly differentiated as per the new `actions/upload-artifact@v4` requirements.

- Added caching to github workflows using `actions/cache@v4`: this means that `libfaust` dynamic/static libs keyed by `runner-os` are now cached (across all workflows) between runs which greatly reduces workflow run times. For example, `cyfaust-test` which previously ran for 32 mins now runs in 5.2 mins if a cached lib is available.

- Changed workflow actions, as nodejs 16 actions are deprecated, to latest versions: actions/checkout@v4, actions/setup-python@v5, and actions/upload-artifact@v4

- Added thirdparty licenses to `docs/licenses`

- Added `scripts/setup_cyfaust.py` which consolidates the following scripts:

	- `setup_faust.py`
	- `setup_sndfile.py`
	- `install_deps.py`

- Added `libsndfile` & `libsamplerate` setup script

- Added working github workflows

- Fixed github action wheel building issue (thanks to [@henryiii for the solution](https://github.com/pypa/wheel/issues/573#issuecomment-1902083893!). This means that cyfaust workflows are now working as expected.

- Added `scripts/build_wheel.py` example of solution for above case.

- Added infrastructure for additional rtaudio audio driver support

### cyfaust.interp

### cyfaust.box

### cyfaust.signal



## [0.0.3]

### cyfaust

- Added Linux support

### cyfaust.interp

- Added improved dsp resource cleanup mechanism for `InterpreterFactoryDSP` which greatly improved stability (see [docs/cleanuping-up.md](https://github.com/shakfu/cyfaust/blob/main/docs/devnotes/cleaning-up.md))

- Fixed test code to ensure rtaudio streams were properly stopped and closed.

### cyfaust.box

- Added additional docstrings


## [0.0.1-2]

### cyfaust

- Embedded faust architecture and standard library files in the cyfaust package

- Created two build variants (dynamic, static) of cyfaust package

- Added cyfaust project

### cyfaust.interp

- Wrapped the faust interpreter api in cython

### cyfaust.box

- Wrapped most of the faust box api in cython

### cyfaust.signal

- Wrapped most of the faust signal api in cython
