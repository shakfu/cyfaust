# Building from Source

cyfaust uses [scikit-build-core](https://scikit-build-core.readthedocs.io/) with CMake for builds and [uv](https://docs.astral.sh/uv/) as the package manager. A `Makefile` wraps common commands for convenience.

## Build Variants

cyfaust has two build variants:

**Dynamic** (default for development) -- links to `libfaust.dylib` / `libfaust.so` / `faust.dll`:

```text
cyfaust/
    __init__.py
    box.cpython-311-darwin.so
    common.cpython-311-darwin.so
    interp.cpython-311-darwin.so
    signal.cpython-311-darwin.so
    resources/
        architecture/
        libraries/
```

**Static** (for distribution) -- links `libfaust.a` / `libfaust.lib` into a single module:

```text
cyfaust/
    __init__.py
    cyfaust.cpython-311-darwin.so
    resources/
        architecture/
        libraries/
```

## Backends

| Feature | cyfaust (interpreter) | cyfaust-llvm |
|---------|----------------------|--------------|
| Binary size | ~8MB | ~33MB |
| DSP execution | Bytecode interpreter | Native machine code (LLVM JIT) |
| Compilation speed | Fast | Slower (JIT compilation) |
| Runtime performance | Good | Best |
| Use case | Development, lightweight deployment | Production, performance-critical |

## Platform Prerequisites

### macOS

Requires Xcode or CommandLine tools:

```bash
xcode-select --install
brew install python cmake
```

### Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install build-essential git cmake python3-dev
sudo apt install libasound2-dev patchelf
sudo apt install libsndfile1-dev libsamplerate0-dev
```

For the LLVM backend, also install:

```bash
sudo apt install libtinfo-dev
```

### Windows

- Python 3.10+
- [Visual Studio Community Edition](https://visualstudio.microsoft.com/vs/community/) with C++ and Windows SDK
- `git` and `cmake`
- [uv](https://docs.astral.sh/uv/) package manager
- GNU Make (via [Git for Windows](https://gitforwindows.org/) or [w64devkit](https://github.com/skeeto/w64devkit))

## Quick Start

Clone and build:

```bash
git clone https://github.com/shakfu/cyfaust.git
cd cyfaust
make        # builds libfaust + installs for development
make test   # run tests
```

This downloads Faust into the `build` directory, configures it for an interpreter build, builds it, and installs into `.gitignored` folders: `bin`, `lib`, `share`.

## Build Targets

### Development

```bash
make                   # dynamic interpreter build (default)
make STATIC=1 build    # static interpreter build
make build-llvm        # static LLVM build
make test              # run tests (interpreter)
make test-llvm         # run tests (LLVM)
```

### Wheels

```bash
make wheel             # build wheel (uses STATIC setting)
make wheel-static      # static wheel (libfaust embedded)
make wheel-dynamic     # dynamic wheel (libfaust bundled via delocate)
make wheel-llvm        # LLVM wheel (cyfaust-llvm package)
make wheel-windows     # Windows one-shot (deps + wheel + delvewheel)
make release           # static wheels for Python 3.10-3.14
```

### Direct uv/cmake Builds

```bash
# Dynamic
uv build --wheel

# Static
CMAKE_ARGS="-DSTATIC=ON" uv build --wheel

# Static LLVM
CMAKE_ARGS="-DSTATIC=ON -DLLVM=ON" uv build --wheel
```

## Build Options

Set via `make VAR=1`:

| Option | Default | Description |
|--------|---------|-------------|
| `STATIC` | 0 | Build with static `libfaust` |
| `LLVM` | 0 | Build with LLVM backend (requires `STATIC=1`) |
| `INCLUDE_SNDFILE` | 1 | Include sndfile support |

### Audio Backend Options

**Linux:**

| Option | Default | Description |
|--------|---------|-------------|
| `ALSA` | 1 | ALSA audio |
| `PULSE` | 0 | PulseAudio |
| `JACK` | 0 | JACK Audio Connection Kit |

**Windows:**

| Option | Default | Description |
|--------|---------|-------------|
| `WASAPI` | 1 | Windows Audio Session API |
| `ASIO` | 0 | Steinberg ASIO |
| `DSOUND` | 0 | DirectSound |

Example:

```bash
make JACK=1 build       # enable JACK support on Linux/macOS
```

## LLVM Backend

The LLVM backend (`cyfaust-llvm`) compiles Faust DSP to native machine code
via LLVM JIT.

### Building LLVM Wheels

```bash
# Download prebuilt libfaustwithllvm (~300MB)
make faustwithllvm

# Build for development
make build-llvm

# Build distributable wheel
make wheel-llvm
```

### Detecting Backend at Runtime

```python
import cyfaust

print(f"LLVM Backend: {cyfaust.LLVM_BACKEND}")

if cyfaust.LLVM_BACKEND:
    print(cyfaust.get_dsp_machine_target())
```

## Build Management Script

For finer control, use `scripts/manage.py` directly:

```bash
python3 scripts/manage.py setup --deps       # install prerequisites
python3 scripts/manage.py setup --faust      # build libfaust
python3 scripts/manage.py setup --samplerate # build libsamplerate
python3 scripts/manage.py setup --sndfile    # build libsndfile
python3 scripts/manage.py setup --llvm       # download libfaustwithllvm
python3 scripts/manage.py build              # build cyfaust (dynamic)
python3 scripts/manage.py build --static     # build cyfaust (static)
python3 scripts/manage.py test               # run tests
python3 scripts/manage.py wheel --release    # build release wheels
```

## Platform Support

**Interpreter backend (cyfaust):**

| Platform | Architecture | Status |
|----------|-------------|--------|
| macOS | arm64 (Apple Silicon) | Supported |
| macOS | x86_64 (Intel) | Supported |
| Linux | x86_64 | Supported |
| Linux | aarch64 | Supported |
| Windows | x86_64 | Supported |

**LLVM backend (cyfaust-llvm):**

| Platform | Architecture | Status |
|----------|-------------|--------|
| macOS | arm64 (Apple Silicon) | Supported |
| macOS | x86_64 (Intel) | Supported |
| Linux | x86_64 | Supported |
| Linux | aarch64 | Supported |
| Windows | x86_64 | Planned |
