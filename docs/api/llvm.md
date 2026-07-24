# LLVM Backend

The LLVM backend compiles Faust DSP to **native machine code** via the LLVM
JIT, in contrast to the [`cyfaust.interp`](interp.md) bytecode interpreter. It
provides `LlvmDspFactory`, `LlvmDsp`, and `LlvmRtAudioDriver`, mirroring the
interpreter classes with the same method names, plus factory serialization to
LLVM IR, machine code, and object files.

## Availability

The LLVM classes exist only in a static build compiled with `-DLLVM=ON` (see
[Building from Source](../building.md#llvm-backend)). Guard on the
`LLVM_BACKEND` flag before using them:

```python
import cyfaust

if cyfaust.LLVM_BACKEND:
    from cyfaust import LlvmDspFactory, LlvmDsp
    print(cyfaust.get_dsp_machine_target())  # e.g. arm64-apple-darwin...
```

When the backend is absent, `cyfaust.LLVM_BACKEND` is `False` and the classes
are not importable.

## Classes

### LlvmDspFactory

Factory that JIT-compiles Faust code to a native DSP.

```python
from cyfaust import LlvmDspFactory
```

#### Static Factory Methods

| Method | Description |
|--------|-------------|
| `from_file(filepath, target="", opt_level=-1, *args)` | Create factory from a `.dsp` file |
| `from_string(name_app, code, target="", opt_level=-1, *args)` | Create factory from Faust source string |
| `from_signals(name_app, signals, target="", opt_level=-1, *args)` | Create factory from a `SignalVector` |
| `from_boxes(name_app, box, target="", opt_level=-1, *args)` | Create factory from a `Box` expression |
| `from_sha_key(sha_key)` | Retrieve cached factory by SHA key |
| `from_bitcode(bitcode, target="", opt_level=-1)` | Create factory from a bitcode string |
| `from_bitcode_file(path, target="", opt_level=-1)` | Create factory from a bitcode file |
| `from_ir(ir_code, target="", opt_level=-1)` | Create factory from LLVM IR text |
| `from_ir_file(path, target="", opt_level=-1)` | Create factory from an LLVM IR file |
| `from_machine(machine_code, target="")` | Create factory from machine code |
| `from_machine_file(path, target="")` | Create factory from a machine-code file |

`target` selects the machine target (empty for the host; see
`get_dsp_machine_target()`), `opt_level` is the LLVM optimization level
(`-1` for the default), and `*args` are Faust compiler options (e.g. `"-vec"`,
`"-vs"`, `"512"`).

#### Instance Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `get_name()` | `str` | Factory name |
| `get_sha_key()` | `str` | Factory SHA key |
| `get_dsp_code()` | `str` | Expanded DSP source code |
| `get_json()` | `str` | DSP metadata/UI as a JSON string |
| `get_compile_options()` | `str` | Compile options used |
| `get_library_list()` | `list[str]` | Library dependencies |
| `get_include_pathnames()` | `list[str]` | Include paths used |
| `get_warning_messages()` | `list[str]` | Compilation warnings |
| `create_dsp_instance()` | `LlvmDsp` | Create a new DSP instance |
| `class_init(sample_rate)` | | Initialize static tables for all instances |
| `set_memory_manager(manager)` | | Set custom memory manager (None to reset) |
| `get_memory_manager()` | | Get current memory manager |
| `write_to_bitcode()` | `str` | Serialize to a bitcode string |
| `write_to_bitcode_file(path)` | `bool` | Serialize to a bitcode file |
| `write_to_ir()` | `str` | Serialize to an LLVM IR string |
| `write_to_ir_file(path)` | `bool` | Serialize to an LLVM IR file |
| `write_to_machine(target="")` | `str` | Serialize to machine code |
| `write_to_machine_file(path, target="")` | `bool` | Serialize to a machine-code file |
| `write_to_objectcode_file(path, target="")` | `bool` | Write a native object file |

#### Example

```python
from cyfaust import LlvmDspFactory

factory = LlvmDspFactory.from_string("osc",
    "import(\"stdfaust.lib\"); process = os.osc(440);")

# Cross-compile with an explicit target and optimization level
factory = LlvmDspFactory.from_string("osc",
    "import(\"stdfaust.lib\"); process = os.osc(440);",
    target="", opt_level=3)

# Persist the JIT result for faster reloads
factory.write_to_bitcode_file("osc.bc")
```

---

### LlvmDsp

DSP instance created from an `LlvmDspFactory`. Its API matches
[`InterpreterDsp`](interp.md#interpreterdsp), with the exception of
`control()`, `frame()`, and the timestamped `compute()` overload, which the
`llvm_dsp` binding does not expose.

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `get_numinputs()` | `int` | Number of audio inputs |
| `get_numoutputs()` | `int` | Number of audio outputs |
| `get_samplerate()` | `int` | Current sample rate |
| `init(sample_rate)` | | Global init (class + instance) |
| `instance_init(sample_rate)` | | Init instance state |
| `instance_constants(sample_rate)` | | Init instance constants |
| `instance_reset_user_interface()` | | Reset control parameters to defaults |
| `instance_clear()` | | Clear instance state, keep control values |
| `clone()` | `LlvmDsp` | Clone the DSP instance |
| `build_user_interface(sound_directory, sample_rate)` | | Build UI and load soundfiles |
| `compute(count, inputs, outputs)` | | Compute audio frames |
| `metadata()` | `dict` | Get DSP metadata (name, author, etc.) |
| `params()` | `list[Param]` | List UI controls with path, label, kind, i/o flag, and range |
| `get_param(key)` | `float` | Read a control by full path or unambiguous label |
| `set_param(key, value)` | | Set an input control (takes effect on next `compute`) |
| `delete()` | | Explicitly delete the underlying DSP instance |

#### Runtime Parameters

Identical to the interpreter's
[runtime parameter API](interp.md#runtime-parameters): `params()` returns
`Param` namedtuples (`path`, `label`, `kind`, `is_input`, `init`, `min`,
`max`, `step`, `index`), and controls are addressed by full UI path or
unambiguous leaf label.

```python
from cyfaust import LlvmDspFactory

factory = LlvmDspFactory.from_string(
    "gain", 'process = _ * hslider("gain", 1, 0, 2, 0.01);'
)
dsp = factory.create_dsp_instance()
dsp.init(48000)

for p in dsp.params():
    print(p.path, p.kind, p.init)

dsp.set_param("gain", 0.5)   # takes effect on the next compute()
dsp.get_param("gain")        # 0.5
```

Buttons, checkboxes, sliders, and nentries are settable inputs; bargraphs are
read-only outputs (`set_param` on one raises `ValueError`), as do unknown or
ambiguous keys.

---

### LlvmRtAudioDriver

Real-time audio driver (RtAudio) for the LLVM backend, matching
[`RtAudioDriver`](interp.md#rtaudiodriver) but bound to `LlvmDsp`.

```python
LlvmRtAudioDriver(srate: int, bsize: int)
```

| Member | Kind | Description |
|--------|------|-------------|
| `init(dsp)` | method → `bool` | Initialize with an `LlvmDsp` instance |
| `set_dsp(dsp)` | method | Set the DSP instance |
| `start()` | method | Start audio playback |
| `stop()` | method | Stop audio playback |
| `buffersize` | property | Buffer size |
| `samplerate` | property | Sample rate |
| `numinputs` | property | Number of inputs |
| `numoutputs` | property | Number of outputs |

```python
import time
from cyfaust import LlvmDspFactory, LlvmRtAudioDriver

factory = LlvmDspFactory.from_string("osc",
    "import(\"stdfaust.lib\"); process = os.osc(440);")
dsp = factory.create_dsp_instance()
dsp.init(48000)
dsp.build_user_interface()

driver = LlvmRtAudioDriver(48000, 256)
driver.init(dsp)
driver.start()
time.sleep(2)
driver.stop()
```

---

## Module-Level Functions

The LLVM factory functions mirror the interpreter's, prefixed with `llvm_`, so
both backends can coexist in one static build.

### Factory Creation

| Function | Returns | Description |
|----------|---------|-------------|
| `llvm_create_dsp_factory_from_file(filename, target="", opt_level=-1, *args)` | `LlvmDspFactory` | Create factory from a `.dsp` file |
| `llvm_create_dsp_factory_from_string(name_app, code, target="", opt_level=-1, *args)` | `LlvmDspFactory` | Create factory from source string |
| `llvm_create_dsp_factory_from_signals(name_app, signals, target="", opt_level=-1, *args)` | `LlvmDspFactory` | Create factory from signals |
| `llvm_create_dsp_factory_from_boxes(name_app, box, target="", opt_level=-1, *args)` | `LlvmDspFactory` | Create factory from boxes |

### Factory Cache

| Function | Returns | Description |
|----------|---------|-------------|
| `llvm_get_dsp_factory_from_sha_key(sha_key)` | `LlvmDspFactory` | Retrieve cached factory |
| `llvm_get_all_dsp_factories()` | `list[str]` | List all cached factory SHA keys |
| `llvm_delete_all_dsp_factories()` | | Clear factory cache |

### Serialization

| Function | Returns | Description |
|----------|---------|-------------|
| `llvm_read_dsp_factory_from_bitcode(bitcode, target="", opt_level=-1)` | `LlvmDspFactory` | Deserialize from a bitcode string |
| `llvm_read_dsp_factory_from_bitcode_file(path, target="", opt_level=-1)` | `LlvmDspFactory` | Deserialize from a bitcode file |
| `llvm_read_dsp_factory_from_ir(ir_code, target="", opt_level=-1)` | `LlvmDspFactory` | Deserialize from LLVM IR text |
| `llvm_read_dsp_factory_from_ir_file(path, target="", opt_level=-1)` | `LlvmDspFactory` | Deserialize from an LLVM IR file |
| `llvm_read_dsp_factory_from_machine(machine_code, target="")` | `LlvmDspFactory` | Deserialize from machine code |
| `llvm_read_dsp_factory_from_machine_file(path, target="")` | `LlvmDspFactory` | Deserialize from a machine-code file |

### Multi-Threading

| Function | Returns | Description |
|----------|---------|-------------|
| `llvm_start_multithreaded_access_mode()` | `bool` | Enable multi-thread factory access |
| `llvm_stop_multithreaded_access_mode()` | | Disable multi-thread factory access |

### Utilities

| Function | Returns | Description |
|----------|---------|-------------|
| `llvm_get_version()` | `str` | LLVM backend version string |
| `get_dsp_machine_target()` | `str` | Default machine target triple for the host |
| `register_foreign_function(function_name)` | | Register a foreign function for JIT linkage |
