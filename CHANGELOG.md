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

## [0.0.6]

### Changed

- Updated cyfaust to faust `2.83.1` (all tests pass)

- Dropped setuptools in favor of `scikit-build-core` and `uv`:
  - Added `CMakeLists.txt` for CMake-based build with Cython
  - Updated `pyproject.toml` for scikit-build-core configuration
  - Updated `Makefile` to use `uv` commands while keeping `manage.py` for dependencies
  - Removed `setup.py` and `MANIFEST.in` (no longer needed)

- Updated all GitHub workflows to use the new build system:
  - Replaced `pip` with `uv` via `astral-sh/setup-uv@v4` action
  - Updated build commands: `uv sync`, `uv build --wheel`, `uv run pytest`
  - Static builds now use `CMAKE_ARGS="-DSTATIC=ON"` environment variable
  - Updated Python version options: dropped 3.8/3.9, added 3.13/3.14
  - Updated macOS runners: dropped deprecated macos-11/12, added macos-13/14
  - Updated Ubuntu runners: added ubuntu-24.04
  - Set `MACOSX_DEPLOYMENT_TARGET` to 10.13 for better compatibility

- Updated `pyproject.toml` for PyPI publication readiness:
  - Added full project metadata (authors, maintainers, keywords, classifiers)
  - Added project URLs (homepage, repository, documentation, issues, changelog)
  - Updated `requires-python` to `>=3.10`
  - Added SPDX license identifier (MIT)

### Fixed

- Fixed soundfile playback by using `SoundUI` instead of `PrintUI` in `build_user_interface()`:
  - The Faust `soundfile` primitive now correctly loads and plays audio files
  - Added `SoundUI` lifetime management to `InterpreterDsp` class
  - Method now accepts optional `sound_directory` and `sample_rate` parameters
  - This also eliminates the `DumpMem-*.txt` and `DumpCode-*.txt` debug files that were being generated due to assertion failures

- Fixed test assertions in `test_cyfaust_box.py` to use minimum bounds (`>=`) instead of exact length checks, accommodating Faust version variability in generated code output

### Added

- Synced Cython `.pxd` declarations with Faust 2.83.1 C++ headers:
  - Added `MemType` enum to `faust_interp.pxd`
  - Added `generateAuxFilesFromFile2()` and `generateAuxFilesFromString2()` functions
  - Added `MapUI` and `PathBuilder` classes to `faust_gui.pxd`
  - Added `getSigNature()` and `sigBranches()` to `faust_signal.pxd`
  - Added second `SoundUI` constructor accepting vector of directories
  - Added `rtaudio.init(const char*, dsp*)` overload
  - Added `Soundfile.Directories` typedef

## [0.0.5]

- Updated cyfaust to faust `2.81.2` (all tests pass)

- Updated cyfaust to faust `2.75.7` (all tests pass)

- Added `scripts/faust_config.py` to generate faust backen and target configurations.

- Added `PythonBuilder` and `PythonDebugBuilder` builders to `manage.py` to enable testing python versions against cyfaust.

- Fixed `SndfileBuilder` and `SamplerateBuilder` in `manage.py` such that `sndfile.lib` and `samplerate.lib` can be built on Windows.

- Changed `rtaudio::processAudio()` in `faust/audio/rtaudi-dsp.h` to the more efficient `alloca` based memory allocation to enable faust to build on windows and for consistency with other faust code (thanks @sletz).

- Added [taskfile.yml](https://taskfile.dev/) as optional windows frontend to `manage.py`

- Added additional test-or-fail checks in `manage.py`

## [0.0.4]

- Added Windows support (MSVC): both dynamic and static variants can now be built on Windows with 100% tests passing (only WASAPI audio has been tested so far).

- Added  `manage.py`, a cross-platform python build management script for cyfaust, which consolidates and replaces all prior build-related scripts. It is used by the `Makefile` frontend and can also be used on its own to facilitate cross-platform build operations.

- Added enhancements to `gen_htmldoc.py` python script and makefile target, `make docs`, to generate api docs in html for both build variants.

- Added thirdparty licenses to `docs/licenses`

- Added infrastructure for additional rtaudio audio driver support

- Added cyfaust github workflows:

  - Added several working github workflows:

    - `cyfaust-test`: to test individual build case,

    - `cyfaust-test-all`: to test all builds,

    - `cyfaust-wheel`: to test and produce a wheel release,

    - `cyfaust-wheel-all`: to test and produce wheels across supported platforms.

  - Fixed github action wheel building issue (thanks to [@henryiii for the solution](https://github.com/pypa/wheel/issues/573#issuecomment-1902083893!). This means that cyfaust workflows are now working as expected.

  - Added caching to github workflows using `actions/cache@v4`: this means that `libfaust` dynamic/static libs keyed by `runner-os` are now cached (across all workflows) between runs which greatly reduces workflow run times. As a case in point,`cyfaust-test` which previously ran for 32 mins now runs in 5.2 mins if a cached lib is available.

  - Changed workflow actions, as nodejs 16 actions are deprecated, to latest versions: actions/checkout@v4, actions/setup-python@v5, and actions/upload-artifact@v4

  - Fixed issue with upload artifact which caused an error in wheel building. Now artifact names are properly differentiated as per the new `actions/upload-artifact@v4` requirements.

## [0.0.3]

- Added Linux support

- Added improved dsp resource cleanup mechanism for `InterpreterFactoryDSP` which greatly improved stability (see [docs/cle§anuping-up.md](https://github.com/shakfu/cyfaust/blob/main/docs/devnotes/cleaning-up.md))

- Fixed test code to ensure rtaudio streams were properly stopped and closed.

- Added additional docstrings

## [0.0.1-2]

- Embedded faust architecture and standard library files in the cyfaust package

- Created two build variants (dynamic, static) of cyfaust package

- Added cyfaust project

- Wrapped the faust interpreter api in cython

- Wrapped most of the faust box api in cython

- Wrapped most of the faust signal api in cython
