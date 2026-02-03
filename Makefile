# Makefile frontend for cyfaust scikit-build-core project
#
# This Makefile wraps common build commands for convenience.
# The actual build is handled by scikit-build-core via pyproject.toml and CMakeLists.txt

# Build options (set to 1 to enable)
STATIC := 0
LLVM := 0
INCLUDE_SNDFILE := 1

# Audio backend options (Linux)
ALSA := 1
PULSE := 0
JACK := 0

# Audio backend options (Windows)
ASIO := 0
WASAPI := 1
DSOUND := 0

# Python command (for manage.py) - use 'python' on Windows, 'python3' elsewhere
ifeq ($(OS),Windows_NT)
    PYTHON := python
else
    PYTHON := python3
endif

# Static library paths (Windows uses .lib, Unix uses .a)
ifeq ($(OS),Windows_NT)
    LIBFAUST := ./lib/static/libfaust.lib
    LIBFAUSTWITHLLVM := ./lib/static/libfaustwithllvm.lib
    LIBSAMPLERATE := ./lib/static/samplerate.lib
    LIBSNDFILE := ./lib/static/sndfile.lib
else
    LIBFAUST := ./lib/static/libfaust.a
    LIBFAUSTWITHLLVM := ./lib/static/libfaustwithllvm.a
    LIBSAMPLERATE := ./lib/static/libsamplerate.a
    LIBSNDFILE := ./lib/static/libsndfile.a
endif

# Build CMAKE_ARGS from options
CMAKE_OPTS := -DSTATIC=$(if $(filter 1,$(STATIC)),ON,OFF)
CMAKE_OPTS += -DLLVM=$(if $(filter 1,$(LLVM)),ON,OFF)
CMAKE_OPTS += -DINCLUDE_SNDFILE=$(if $(filter 1,$(INCLUDE_SNDFILE)),ON,OFF)
CMAKE_OPTS += -DALSA=$(if $(filter 1,$(ALSA)),ON,OFF)
CMAKE_OPTS += -DPULSE=$(if $(filter 1,$(PULSE)),ON,OFF)
CMAKE_OPTS += -DJACK=$(if $(filter 1,$(JACK)),ON,OFF)
CMAKE_OPTS += -DASIO=$(if $(filter 1,$(ASIO)),ON,OFF)
CMAKE_OPTS += -DWASAPI=$(if $(filter 1,$(WASAPI)),ON,OFF)
CMAKE_OPTS += -DDSOUND=$(if $(filter 1,$(DSOUND)),ON,OFF)

export CMAKE_ARGS := $(CMAKE_OPTS)

.PHONY: all sync faust faustwithllvm samplerate sndfile build rebuild test wheel sdist \
        generate-static release verify-sync pytest clean distclean reset help \
        wheel-static wheel-dynamic wheel-windows wheel-llvm wheel-repair wheel-check \
        publish publish-test build-llvm test-llvm

# Default target
all: build

# ----------------------------------------------------------------------------
# Dependency management (via manage.py)
# ----------------------------------------------------------------------------
$(LIBFAUST):
	$(PYTHON) scripts/manage.py setup --faust

$(LIBSAMPLERATE):
	$(PYTHON) scripts/manage.py setup --samplerate

$(LIBSNDFILE):
	$(PYTHON) scripts/manage.py setup --sndfile

faust: $(LIBFAUST)
	@echo "libfaust DONE"

$(LIBFAUSTWITHLLVM):
	$(PYTHON) scripts/manage.py setup --faustwithllvm

faustwithllvm: $(LIBFAUSTWITHLLVM)
	@echo "libfaustwithllvm DONE"

samplerate: $(LIBSAMPLERATE)
	@echo "libsamplerate DONE"

sndfile: $(LIBSAMPLERATE) $(LIBSNDFILE)
	@echo "libsndfile DONE"

# ----------------------------------------------------------------------------
# Build commands (via uv + scikit-build-core)
# ----------------------------------------------------------------------------

# Sync environment (initial setup, uses dynamic build for development)
sync: faust
	CMAKE_ARGS="-DSTATIC=OFF" uv sync

# Build/rebuild the extension after code changes (dynamic for development)
build: faust
	CMAKE_ARGS="-DSTATIC=OFF" uv sync --reinstall-package cyfaust

# Alias for build
rebuild: build

# Run tests
test: build verify-sync
	uv run pytest tests/ -v
	@rm -f DumpCode-*.txt DumpMem-*.txt

# Build wheel (uses Makefile's STATIC setting, default dynamic)
wheel: faust
	uv build --wheel

# Build source distribution
sdist: faust
	uv build --sdist

# Generate static source from dynamic modules
generate-static:
	$(PYTHON) scripts/generate_static.py

# Build static wheel (statically linked, no external dylib needed)
wheel-static: faust generate-static
	CMAKE_ARGS="-DSTATIC=ON" uv build --wheel

# Build dynamic wheel (links to libfaust dylib, then bundles via delocate/auditwheel)
wheel-dynamic: faust
	CMAKE_ARGS="-DSTATIC=OFF" uv build --wheel
	$(MAKE) wheel-repair

# Build LLVM static wheel (LLVM JIT backend, ~71MB binary)
# Renames to cyfaust-llvm for PyPI distribution
wheel-llvm: faustwithllvm generate-static
	CMAKE_ARGS="-DSTATIC=ON -DLLVM=ON" uv build --wheel
	$(PYTHON) scripts/rename_wheel.py dist/cyfaust-*.whl cyfaust-llvm --delete

# Build with LLVM backend (for development)
build-llvm: faustwithllvm generate-static
	CMAKE_ARGS="-DSTATIC=ON -DLLVM=ON" uv sync --reinstall-package cyfaust

# Test LLVM build
test-llvm: build-llvm
	uv run pytest tests/ -v
	@rm -f DumpCode-*.txt DumpMem-*.txt

# Repair wheel by bundling dynamic libraries (platform-specific)
wheel-repair:
ifeq ($(shell uname),Darwin)
	@echo "Running delocate to bundle libfaust.dylib..."
	DYLD_LIBRARY_PATH=lib uv run delocate-wheel -v dist/*.whl
else ifeq ($(shell uname),Linux)
	@echo "Running auditwheel to bundle libfaust.so..."
	LD_LIBRARY_PATH=lib uv run auditwheel repair dist/*.whl -w dist/
else
	@echo "Running delvewheel to bundle faust.dll..."
	uv run delvewheel repair --add-path lib dist/*.whl -w dist/
endif

# Build Windows wheel in one shot (builds all dependencies, wheel, and bundles DLL)
# Usage: make wheel-windows
wheel-windows: faust samplerate sndfile
	@echo "Building Windows wheel with bundled faust.dll..."
	CMAKE_ARGS="-DSTATIC=OFF" uv build --wheel
	uv run delvewheel repair --add-path lib dist/*.whl -w dist/
	@echo "Windows wheel built successfully in dist/"

# Build release wheels (static, for PyPI distribution)
release: faust generate-static
	CMAKE_ARGS="-DSTATIC=ON" uv build --wheel --python 3.10
	CMAKE_ARGS="-DSTATIC=ON" uv build --wheel --python 3.11
	CMAKE_ARGS="-DSTATIC=ON" uv build --wheel --python 3.12
	CMAKE_ARGS="-DSTATIC=ON" uv build --wheel --python 3.13
	CMAKE_ARGS="-DSTATIC=ON" uv build --wheel --python 3.14
	uv run twine check dist/*

# ----------------------------------------------------------------------------
# Publishing (via twine)
# ----------------------------------------------------------------------------

# Check wheel/sdist with twine
wheel-check:
	uv run twine check dist/*

# Publish to TestPyPI
publish-test: wheel-check
	uv run twine upload --repository testpypi dist/*

# Publish to PyPI
publish: wheel-check
	uv run twine upload dist/*

# Verify static/dynamic build sync
verify-sync:
	@./scripts/verify_build_sync.sh

# Run pytest directly
pytest: faust
	uv run pytest tests/ -vv
	@rm -f DumpCode-*.txt DumpMem-*.txt

# ----------------------------------------------------------------------------
# Cleanup
# ----------------------------------------------------------------------------

# Clean build artifacts
clean:
	@$(PYTHON) scripts/manage.py clean
	@rm -rf build/ dist/ *.egg-info/ src/*.egg-info/
	@rm -rf .pytest_cache/ CMakeCache.txt CMakeFiles/
	@rm -f DumpCode-*.txt DumpMem-*.txt
	@find . -name "*.so" -delete 2>/dev/null || true
	@find . -name "*.pyd" -delete 2>/dev/null || true
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Clean everything including CMake cache
distclean: clean

# Full reset (remove dependencies too)
reset:
	@$(PYTHON) scripts/manage.py clean --reset

# ----------------------------------------------------------------------------
# Help
# ----------------------------------------------------------------------------
help:
	@echo "cyfaust build system (scikit-build-core + uv)"
	@echo ""
	@echo "Dependency targets:"
	@echo "  faust         - Download libfaust (interpreter backend)"
	@echo "  faustwithllvm - Download libfaustwithllvm (LLVM JIT backend)"
	@echo "  samplerate    - Build libsamplerate"
	@echo "  sndfile       - Build libsndfile"
	@echo ""
	@echo "Build targets:"
	@echo "  all          - Build/rebuild the extension (default)"
	@echo "  sync         - Sync environment (initial setup)"
	@echo "  build        - Rebuild extension after code changes"
	@echo "  rebuild      - Alias for build"
	@echo "  build-llvm   - Build with LLVM backend (static, ~71MB)"
	@echo "  wheel        - Build wheel (uses STATIC setting)"
	@echo "  wheel-static - Build static wheel (libfaust embedded)"
	@echo "  wheel-dynamic- Build dynamic wheel (libfaust bundled via delocate)"
	@echo "  wheel-windows- Build Windows wheel (one-shot: deps + wheel + delvewheel)"
	@echo "  wheel-llvm   - Build LLVM wheel (libfaustwithllvm embedded)"
	@echo "  wheel-repair - Bundle dynamic libs into wheel (delocate/auditwheel)"
	@echo "  sdist        - Build source distribution"
	@echo "  release      - Build static wheels for all Python versions"
	@echo ""
	@echo "Test targets:"
	@echo "  test        - Run tests (interpreter build)"
	@echo "  test-llvm   - Run tests (LLVM build)"
	@echo "  pytest      - Run pytest directly"
	@echo ""
	@echo "Publishing targets:"
	@echo "  wheel-check - Check wheel/sdist with twine"
	@echo "  publish-test - Publish to TestPyPI"
	@echo "  publish     - Publish to PyPI"
	@echo ""
	@echo "Cleanup targets:"
	@echo "  clean       - Remove build artifacts"
	@echo "  distclean   - Remove all generated files"
	@echo "  reset       - Full reset including dependencies"
	@echo ""
	@echo "Build options (set via make VAR=1):"
	@echo "  STATIC=1          - Build with static libfaust"
	@echo "  LLVM=1            - Build with LLVM backend (requires STATIC=1)"
	@echo "  INCLUDE_SNDFILE=1 - Include sndfile support (default)"
	@echo "  ALSA=1            - Enable ALSA (Linux, default)"
	@echo "  PULSE=1           - Enable PulseAudio (Linux)"
	@echo "  JACK=1            - Enable JACK (Linux/macOS)"
	@echo "  WASAPI=1          - Enable WASAPI (Windows, default)"
	@echo "  ASIO=1            - Enable ASIO (Windows)"
	@echo "  DSOUND=1          - Enable DirectSound (Windows)"
	@echo ""
	@echo "Example:"
	@echo "  make build              # Dynamic interpreter build (default)"
	@echo "  make STATIC=1 build     # Static interpreter build"
	@echo "  make build-llvm         # Static LLVM build"
	@echo "  make JACK=1 build       # Enable JACK support"
