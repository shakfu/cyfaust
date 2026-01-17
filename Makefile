# Makefile frontend for cyfaust scikit-build-core project
#
# This Makefile wraps common build commands for convenience.
# The actual build is handled by scikit-build-core via pyproject.toml and CMakeLists.txt

# Build options (set to 1 to enable)
STATIC := 0
INCLUDE_SNDFILE := 1

# Audio backend options (Linux)
ALSA := 1
PULSE := 0
JACK := 0

# Audio backend options (Windows)
ASIO := 0
WASAPI := 1
DSOUND := 0

# Python command (for manage.py)
PYTHON := python3

# Static library paths
LIBFAUST := ./lib/static/libfaust.a
LIBSAMPLERATE := ./lib/static/libsamplerate.a
LIBSNDFILE := ./lib/static/libsndfile.a

# Build CMAKE_ARGS from options
CMAKE_OPTS := -DSTATIC=$(if $(filter 1,$(STATIC)),ON,OFF)
CMAKE_OPTS += -DINCLUDE_SNDFILE=$(if $(filter 1,$(INCLUDE_SNDFILE)),ON,OFF)
CMAKE_OPTS += -DALSA=$(if $(filter 1,$(ALSA)),ON,OFF)
CMAKE_OPTS += -DPULSE=$(if $(filter 1,$(PULSE)),ON,OFF)
CMAKE_OPTS += -DJACK=$(if $(filter 1,$(JACK)),ON,OFF)
CMAKE_OPTS += -DASIO=$(if $(filter 1,$(ASIO)),ON,OFF)
CMAKE_OPTS += -DWASAPI=$(if $(filter 1,$(WASAPI)),ON,OFF)
CMAKE_OPTS += -DDSOUND=$(if $(filter 1,$(DSOUND)),ON,OFF)

export CMAKE_ARGS := $(CMAKE_OPTS)

.PHONY: all sync faust samplerate sndfile build rebuild test wheel sdist \
        release verify-sync pytest clean distclean reset help

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

samplerate: $(LIBSAMPLERATE)
	@echo "libsamplerate DONE"

sndfile: $(LIBSAMPLERATE) $(LIBSNDFILE)
	@echo "libsndfile DONE"

# ----------------------------------------------------------------------------
# Build commands (via uv + scikit-build-core)
# ----------------------------------------------------------------------------

# Sync environment (initial setup)
sync: faust
	uv sync

# Build/rebuild the extension after code changes
build: faust
	uv sync --reinstall-package cyfaust

# Alias for build
rebuild: build

# Run tests
test: build verify-sync
	uv run pytest tests/ -v
	@rm -f DumpCode-*.txt DumpMem-*.txt

# Build wheel
wheel: faust
	uv build --wheel

# Build source distribution
sdist: faust
	uv build --sdist

# Build release wheel (static build)
release: faust
	CMAKE_ARGS="-DSTATIC=ON $(CMAKE_OPTS)" uv build --wheel

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
	@echo "  faust       - Download and build libfaust"
	@echo "  samplerate  - Build libsamplerate"
	@echo "  sndfile     - Build libsndfile"
	@echo ""
	@echo "Build targets:"
	@echo "  all         - Build/rebuild the extension (default)"
	@echo "  sync        - Sync environment (initial setup)"
	@echo "  build       - Rebuild extension after code changes"
	@echo "  rebuild     - Alias for build"
	@echo "  wheel       - Build wheel distribution"
	@echo "  sdist       - Build source distribution"
	@echo "  release     - Build static wheel (for distribution)"
	@echo ""
	@echo "Test targets:"
	@echo "  test        - Run tests"
	@echo "  pytest      - Run pytest directly"
	@echo ""
	@echo "Cleanup targets:"
	@echo "  clean       - Remove build artifacts"
	@echo "  distclean   - Remove all generated files"
	@echo "  reset       - Full reset including dependencies"
	@echo ""
	@echo "Build options (set via make VAR=1):"
	@echo "  STATIC=1          - Build with static libfaust"
	@echo "  INCLUDE_SNDFILE=1 - Include sndfile support (default)"
	@echo "  ALSA=1            - Enable ALSA (Linux, default)"
	@echo "  PULSE=1           - Enable PulseAudio (Linux)"
	@echo "  JACK=1            - Enable JACK (Linux/macOS)"
	@echo "  WASAPI=1          - Enable WASAPI (Windows, default)"
	@echo "  ASIO=1            - Enable ASIO (Windows)"
	@echo "  DSOUND=1          - Enable DirectSound (Windows)"
	@echo ""
	@echo "Example:"
	@echo "  make STATIC=1 build    # Static build"
	@echo "  make JACK=1 build      # Enable JACK support"
