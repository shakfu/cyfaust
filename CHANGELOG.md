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

## [Unreleased]

### Added

- Added a runtime UI parameter API to `InterpreterDsp`: `params()`, `get_param(key)`, and `set_param(key, value)`. `params()` lists the DSP's controls as `Param` namedtuples (full UI path, leaf label, widget kind, input/output flag, and `init`/`min`/`max`/`step` range, in UI-declaration order); `get_param`/`set_param` address a control by full UI path or unambiguous leaf label, with a set taking effect on the next `compute`. Buttons, checkboxes, sliders, and nentries are settable inputs; bargraphs are read-only outputs (setting one raises `ValueError`), and unknown or ambiguous keys raise `ValueError`. Backed by Faust's `APIUI` (newly declared in `faust_gui.pxd`), built lazily onto the instance via `buildUserInterface` alongside the existing `SoundUI` and freed with it. Previously control values could not be read or set at runtime -- the `cyfaust params`/`json` CLI only regex-parsed the expanded DSP source. Adds `tests/test_cyfaust_params.py`
- Wired the `cyfaust params` and `cyfaust json` CLI commands to the runtime UI parameter API instead of regex-parsing the expanded DSP source, so their output reflects exactly what the compiled DSP exposes (full UI path, widget kind, input/output flag, range, and current value). `cyfaust params` gains `--get PATH` and `--set PATH VALUE` (both repeatable) to read and drive controls, plus `--sample-rate`; `cyfaust json` emits richer `parameters` entries (`path`, `type`, `is_input`, `value`, and range). Removes the now-unused `_UI_PATTERNS` regex table. Extends `tests/test_cli.py`

### Fixed

- Fixed `make` failing from a clean checkout with `LNK1181: cannot open input file ...\lib\static\sndfile.lib`. With `INCLUDE_SNDFILE=1` (the default) the link step pulls in `sndfile.lib` and `samplerate.lib` (see `CMakeLists.txt`), but the `build`/`sync`/`pytest` targets declared only `faust` as a prerequisite, so those libs were never provisioned -- only `wheel-windows` listed them. A new `SNDFILE_DEPS` variable (the samplerate/sndfile libs when `INCLUDE_SNDFILE=1`, empty otherwise) is now a prerequisite of `build`, `sync`, and `pytest`, so a plain `make` builds them before the link step
- Fixed `python scripts/manage.py setup --all` building only the first prerequisite: the `sys.exit()` was indented inside the builder loop, so it ran `DependencyMgr` and quit before faust/sndfile/samplerate. The exit now runs after the full loop completes
- Fixed `SndfileBuilder`/`SamplerateBuilder` re-cloning their source trees unconditionally on every run -- a `git clone` into an existing directory that failed silently (since `ShellCmd.cmd` does not check exit codes). Both now skip the clone when the source already exists, mirroring `FaustLLVMBuilder`
- Fixed `scripts/generate_static.py` emitting CRLF line endings on Windows: it wrote `src/static/cyfaust/cyfaust.pyx` and the synced `.pxd` files via `Path.write_text()`, which translates `\n` to the platform line ending, so regenerating on Windows produced CRLF files that conflict with the repo's `.gitattributes` (`eol=lf`) and showed up as phantom diffs. Both writes now pass `newline=""` to force LF on every platform

### Removed

- Removed the dead `build` and `wheel` subcommands from `scripts/manage.py` (and the supporting `WheelBuilder`/`WheelFilename` classes), which shelled out to `setup.py build_ext`/`bdist_wheel` -- `setup.py` was removed earlier, and building cyfaust and its wheels is driven by the `Makefile` via `uv` + scikit-build-core. The now-unused `re`, `dataclass`, and `List` imports were dropped. `manage.py` retains the `setup`, `python`, `test`, and `clean` subcommands that CI and the Makefile depend on

### Changed

- Ported `scripts/verify_build_sync.sh` to `scripts/verify_build_sync.py` (the `verify-sync` make target now invokes `$(PYTHON)`), removing the bash dependency. The shell script used bash arrays and failed under a POSIX `sh` with `syntax error: unexpected "("`; the Python port is portable across Windows/macOS/Linux and consistent with the other `scripts/*.py` invoked from the Makefile
- Updated `docs/building.md` to drop the removed `manage.py build`/`wheel` examples (adding `setup --all`) and clarify that `manage.py` provisions the native dependencies while the `Makefile` builds cyfaust and its wheels

## [0.1.4]

### Fixed

- Fixed a double-free / segfault in `InterpreterDsp.delete()` (both the dynamic `interp.pyx` and static `cyfaust.pyx` variants). `delete()` called `del self.ptr` but left `self.ptr` non-null, so when the parent `InterpreterDspFactory.__dealloc__` later freed its tracked instances on teardown, an instance the user had already deleted explicitly was freed a second time (reproducible as create -> init -> `delete()` -> interpreter exit, giving exit code 139). `delete()` now mirrors `__dealloc__` (frees `sound_ui` and the dsp pointer, then nulls both), making a second `delete()` or the factory's teardown a safe no-op. With thanks to [@olilarkin](https://github.com/olilarkin) for the report and fix ([#1](https://github.com/shakfu/cyfaust/pull/1))
- Fixed a double-free / segfault when `delete_all_dsp_factories()` runs before live factory wrappers are garbage-collected. `deleteAllInterpreterDSPFactories()` destroys every C++ factory in libfaust's cache, but the Python `InterpreterDspFactory` wrappers still held `ptr_owner=True` and a now-dangling `ptr`, so their later `__dealloc__` called `deleteInterpreterDSPFactory()` on already-freed memory -> double free (reproducible as create -> `delete_all_dsp_factories()` -> interpreter exit, giving exit code 139 with `WARNING : deleteDSPFactory factory not found!`). Live wrappers are now tracked in a module-level `weakref.WeakSet` and invalidated (pointer nulled, ownership cleared) before the cache is destroyed, so their teardown becomes a safe no-op. With thanks to [@olilarkin](https://github.com/olilarkin) for the report and fix ([#2](https://github.com/shakfu/cyfaust/pull/2))
- Fixed stale generated source in the static build variant: `src/static/cyfaust/cyfaust.pyx` had drifted from its dynamic sources and was regenerated via `make generate-static`, correcting `is_sig_doc_access_tbl()` to return `tbl`/`ridx` dict keys (previously the stale `n`/`widx`) in the static build
- Fixed `scripts/generate_static.py` silently dropping new top-level imports: it collected standard imports from the dynamic modules but never emitted them, so the hardcoded header was the only import source. Any import not already hardcoded (e.g. the `import weakref` added for the factory fix above) was lost, breaking the static build with `undeclared name not builtin`. The generator now re-emits collected imports the header does not already provide
- Fixed a memory leak in `InterpreterDsp.clone()`: the cloned instance was created with `ptr_owner=False` and, unlike a `create_dsp_instance()` result, was tracked by no factory, so its C++ pointer was freed by nobody on garbage collection (leaking unless the caller manually called `delete()`). Clones now hold a weak reference to their parent's factory and register themselves in that factory's tracked instances, so they are freed on the factory's ordered teardown like any other instance. The weak backref keeps this cycle-free

- Fixed Windows CI build failure introduced in 0.1.3: the bundled-resources refresh (`copy_stdlib()`, `copy_examples()`, `copy_architecture()`) was called unconditionally in `FaustBuilder.process()`, but it sources from the install prefix populated by `make install`, which the Windows build skips. The refresh is now gated to Linux/macOS; Windows consumes the committed `resources` as-is, mirroring how the committed headers are handled
- Fixed Windows static wheel build failing with MSVC C2131 (VLAs) in the bundled `include/faust/dsp/sound-player.h`. The 0.1.3 Faust 2.85.5 bump re-introduced the variable-length arrays at three sites because `copy_headers()`/`install_headers()` overwrite the committed header from upstream faust on Unix, reverting the existing VLA -> `std::vector` patch, which was only re-applied on Windows. The committed header is re-patched, and `patch_headers_for_msvc()` now runs unconditionally after the header refresh (idempotent; `std::vector` is portable) so a future Faust bump cannot silently regress the Windows build

### Added

- Added a `verify-generated` make target (wired into `test`) that regenerates the static source and fails if `src/static/cyfaust/cyfaust.pyx` is stale, preventing the dynamic and static variants from silently diverging
- Added `build-static` and `test-static` make targets to build and run the test suite against the static (monolithic) variant, which the default `test` target does not exercise

## [0.1.3]

### Added

- Updated bundled Faust to `2.85.5` (from `2.83.1`)

- Added `get_json()` to `InterpreterDspFactory` and `LlvmDspFactory` (both dynamic and static variants), wrapping the new factory-level `getJSON()` API introduced in Faust 2.85.x, which returns the DSP's JSON description (UI + metadata)

- Added `FaustBuilder.copy_architecture()` to `manage.py`, which refreshes `resources/architecture` from the built Faust source. The full architecture tree is copied, minus unpopulated git submodule paths (oboe, py2max) and heavyweight entries inappropriate for the wheel (the prebuilt `ios-libsndfile.a` binary, mobile project trees `android`/`iOS`/`smartKeyboard`, and vendored C libraries `httpdlib`/`osclib`/`svgplot`), reducing the tree from ~42MB to ~13MB

- Added `scripts/build_windows.py` for local Windows wheel builds, supporting both static (default) and dynamic (`--dynamic`) linking modes with dependency checks, optional cleaning, and test options

- Re-enabled Windows in `cyfaust-release.yml` workflow (static interpreter wheels for Python 3.10-3.14, with sndfile/samplerate built from source and non-audio test suite)

### Changed

- Refreshed bundled `resources/libraries` for Faust 2.85.5: added 9 new standard library files (`debug`, `doc`, `env`, `hysteresis`, `lfo`, `linearalgebra`, `motion`, `operator`, `pitchenv`) and synced `stdfaust.lib` and the library examples
- Extracted `patch_headers_for_msvc()` from `FaustLLVMBuilder` into a standalone idempotent function in `manage.py`, now called from both `FaustBuilder` and `FaustLLVMBuilder` on Windows
- Added static build (`cyfaust.cyfaust`) import fallbacks to `test_box_coverage.py` and `test_signal_coverage.py` so they work on Windows CI

### Fixed

- Fixed stale bundled `resources` on Faust version updates: `FaustBuilder.copy_stdlib()` and `copy_examples()` wrote to the gitignored, non-bundled `share/faust` directory and were disabled in `process()`. They now sync into the tracked-and-bundled `resources/libraries` (and `resources/libraries/examples`), and are re-enabled along with the new `copy_architecture()` so a Faust bump refreshes the bundled standard library, examples, and architecture files
- Fixed remaining VLAs in `include/faust/dsp/sound-player.h` (3 locations) that caused MSVC C2131 errors on Windows CI

## [0.1.2]

### Added

- Added mkdocs documentation site at <https://shakfu.github.io/cyfaust/>
  - New Examples page with advanced usage patterns (parameter control, frame processing, cloning, timestamped compute, initialization lifecycle)
  - New Building from Source page consolidating build instructions, platform prerequisites, build options, and LLVM backend details
  - New Developer Notes section with validated internal references (resource cleanup, Box API design, Soundfile API, useful links)
  - Complete CLI reference documenting all 10 commands (added play, params, validate, bitcode, json)
  - Architecture diagram (d2/SVG) on the API Reference overview page
  - Documented Box and Signal OO instance methods, operators, math methods, and type checking in API docs
  - Documented `SType`/`SOperator` enums and DSP conversion functions in API docs
- Added `.pyi` type stub files for all 5 Cython modules (`interp`, `box`, `signal`, `common`, `player`) with `py.typed` marker for mypy/IDE support
- Added `test_box_coverage.py` with 171 tests covering primitives, composition, operators, arithmetic, bitwise, comparison, logical, math, UI elements, groups, selectors, tables, type checking, DSP conversion, and BoxVector (coverage ~12% -> ~65%)
- Added `test_signal_coverage.py` with 153 tests covering primitives, arithmetic, bitwise, comparison, logical, math, delay, casting, tables, soundfiles, selectors, recursion, UI elements, attach, foreign functions, type checking with dict key validation, normalization, source generation, Signal OO interface, SignalVector, Interval, and enums (coverage ~6% -> ~65%)
- Added `make docs-diagram` target to regenerate architecture diagram
- Added `make qa` pipeline: ruff lint, mypy typecheck, ruff format
- Added ruff and mypy configuration in `pyproject.toml`

### Changed

- Reorganized `docs/devnotes/` to `docs/dev/` and cleaned up stale files
- Streamlined README.md to link to docs site for detailed build/CLI/API information
- Updated documentation link in `pyproject.toml` to point to the docs site
- Extracted duplicated UI regex patterns in `__main__.py` into module-level `_UI_PATTERNS`
- Fixed Makefile lint target to reference `tests/` (was `test/`)
- Fixed explicit re-export in `src/cyfaust/__init__.py` for ruff F401
- Added `noqa` annotations for star imports in static build `__init__.py`

- Added full Windows support for dynamic builds with `delvewheel` integration:
  - New `wheel-windows` Makefile target builds a complete Windows wheel in one shot
  - Automatic `faust.dll` bundling via delvewheel for distributable wheels
  - DLL search path handling in `__init__.py` for development builds

- Added Windows support to `FaustLLVMBuilder` for downloading LLVM libraries:
  - Automatically uses existing Faust installation at `C:\Program Files\Faust`
  - Falls back to downloading and extracting the installer with 7-zip
  - Note: LLVM backend not supported on Windows - the prebuilt `libfaustwithllvm.lib` has MSVC ABI incompatibilities (built with different MSVC version and runtime library settings). Use interpreter backend on Windows.

- Added CMake build-time check that prevents LLVM builds on Windows with helpful error message

- Updated Makefile for Windows compatibility:
  - Auto-detect platform and use `python` instead of `python3` on Windows
  - Use `.lib` extension for static libraries on Windows
  - Added `--add-path lib` to delvewheel command for finding `faust.dll`

- Updated CMakeLists.txt for Windows:
  - Added libsndfile and libsamplerate static library linking on Windows

- Removed stale developer docs: `debug_mode_anaysis.md`, `x86_errors.md`, `ci/` directory, `faust-gui.md`, `universal2.md`

### Fixed

- Fixed `is_sig_doc_access_tbl` using wrong dict keys (`n`/`widx` instead of `tbl`/`ridx`) -- copy-paste error from `is_sig_doc_write_tbl`

- Fixed Variable Length Array (VLA) usage in `include/faust/dsp/sound-player.h`:
  - MSVC does not support VLAs; replaced with `std::vector` for cross-platform compatibility

- Fixed `src/cyfaust/__init__.py` to automatically locate `faust.dll` on Windows:
  - Searches project lib directory for development builds
  - Works with delvewheel-bundled wheels for distribution

- Removed `src/cyfaust/resources` symlink placeholder that caused wheel build conflicts on Windows



## [0.1.1]

### Added

- Added LLVM backend support as an alternative to the interpreter backend:
  - LLVM backend compiles Faust DSP to native machine code via LLVM JIT for faster execution
  - New classes: `LlvmDspFactory`, `LlvmDsp`, `LlvmRtAudioDriver`
  - New factory functions: `llvm_create_dsp_factory_from_file()`, `llvm_create_dsp_factory_from_string()`, etc.
  - Additional serialization formats: LLVM IR (`write_to_ir()`), machine code, object code
  - `get_dsp_machine_target()` function to query current machine's LLVM target triple
  - `register_foreign_function()` for custom C function integration in DSP code
  - Runtime detection via `cyfaust.LLVM_BACKEND` flag
  - Build with `make build-llvm` or `CMAKE_ARGS="-DSTATIC=ON -DLLVM=ON"`
  - Note: LLVM build produces ~71MB binary vs ~8MB for interpreter (includes full LLVM)
  - Note: Currently only tested on macOS; Linux and Windows support planned for future releases

- Added `FaustLLVMBuilder` to `scripts/manage.py` for downloading prebuilt `libfaustwithllvm.a`

- Added Makefile targets for LLVM builds:
  - `faustwithllvm` - Download libfaustwithllvm static library
  - `build-llvm` - Build with LLVM backend
  - `test-llvm` - Run tests with LLVM build
  - `wheel-llvm` - Build LLVM wheel

## [0.1.0]

### Added

- Added new DSP instance methods to `InterpreterDsp`:
  - `control()`: Read all controllers and update DSP state (for use with `-ec` option)
  - `frame()`: Single-frame processing (for use with `-os` option)
  - `compute_timestamped()`: Audio processing with timestamp for sample-accurate timing (API compatible, delegates to standard compute in interpreter)
  - `metadata()`: Returns DSP metadata as a Python dictionary (name, author, version, license, etc.)

- Added `MetaCollector` class to `faust_gui.pxd` for collecting DSP metadata into a C++ map

- Added command-line interface (`cyfaust` or `python -m cyfaust`) with commands:
  - `version`: Show cyfaust and libfaust version
  - `compile`: Compile Faust DSP to cpp, c, rust, or codebox backends
  - `diagram`: Generate SVG block diagrams
  - `expand`: Expand Faust DSP to self-contained code
  - `info`: Show DSP metadata, inputs, outputs, and library dependencies
  - `play`: Play a DSP file with RtAudio (supports duration, sample rate options)
  - `params`: List all DSP parameters (sliders, buttons, bargraphs)
  - `validate`: Check DSP files for errors (with optional strict mode)
  - `bitcode`: Save/load compiled DSP as bitcode for faster loading
  - `json`: Export DSP metadata and parameters as JSON

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

- Fixed static build duplicate symbol error by excluding `gui_statics.cpp` from static builds (static builds define GUI statics in `faust_player.pxd`)

### Added

- Added `scripts/generate_static.py` to consolidate dynamic module sources into a single monolithic `cyfaust.pyx` for static builds:
  - Processes `common`, `interp`, `box`, `signal`, and `player` modules in dependency order
  - Removes relative imports and collects standard imports
  - Syncs `.pxd` declaration files from dynamic to static directory
  - Generates auto-generated header with proper Cython directives

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

- Added `manage.py`, a cross-platform python build management script for cyfaust, which consolidates and replaces all prior build-related scripts. It is used by the `Makefile` frontend and can also be used on its own to facilitate cross-platform build operations.

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
