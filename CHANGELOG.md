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

- Added additional test-or-fail checks in `manage.py`

## [0.0.4]

### cyfaust

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

### cyfaust

- Added Linux support

### cyfaust.interp

- Added improved dsp resource cleanup mechanism for `InterpreterFactoryDSP` which greatly improved stability (see [docs/cle§anuping-up.md](https://github.com/shakfu/cyfaust/blob/main/docs/devnotes/cleaning-up.md))

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
