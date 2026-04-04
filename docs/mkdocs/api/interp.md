# cyfaust.interp

The interpreter module provides the core Faust DSP compilation and audio playback functionality.

## Classes

### InterpreterDspFactory

Factory class for creating DSP instances from Faust code.

```python
from cyfaust.interp import InterpreterDspFactory
```

#### Static Factory Methods

| Method | Description |
|--------|-------------|
| `from_file(filepath, *args)` | Create factory from a `.dsp` file |
| `from_string(name_app, code, *args)` | Create factory from Faust source code string |
| `from_signals(name_app, signals, *args)` | Create factory from a `SignalVector` |
| `from_boxes(name_app, box, *args)` | Create factory from a `Box` expression |
| `from_sha_key(sha_key)` | Retrieve cached factory by SHA key |
| `from_bitcode(bitcode)` | Create factory from a bitcode string |
| `from_bitcode_file(path)` | Create factory from a bitcode file |

All factory methods accept optional `*args` for Faust compiler options (e.g., `"-vec"`, `"-vs"`, `"512"`).

#### Instance Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `get_name()` | `str` | Factory name |
| `get_sha_key()` | `str` | Factory SHA key |
| `get_dsp_code()` | `str` | Expanded DSP source code |
| `get_compile_options()` | `str` | Compile options used |
| `get_library_list()` | `list[str]` | Library dependencies |
| `get_include_pathnames()` | `list[str]` | Include paths used |
| `get_warning_messages()` | `list[str]` | Compilation warnings |
| `create_dsp_instance()` | `InterpreterDsp` | Create a new DSP instance |
| `write_to_bitcode()` | `str` | Serialize to bitcode string |
| `write_to_bitcode_file(path)` | `bool` | Serialize to bitcode file |
| `set_memory_manager(manager)` | | Set custom memory manager (None to reset) |
| `get_memory_manager()` | | Get current memory manager |
| `class_init(sample_rate)` | | Initialize static tables for all instances |

#### Example

```python
from cyfaust.interp import InterpreterDspFactory

# From string
factory = InterpreterDspFactory.from_string("osc",
    "import(\"stdfaust.lib\"); process = os.osc(440);")

# From file
factory = InterpreterDspFactory.from_file("synth.dsp")

# With compiler options
factory = InterpreterDspFactory.from_string("osc",
    "import(\"stdfaust.lib\"); process = os.osc(440);",
    "-vec", "-vs", "512")
```

---

### InterpreterDsp

DSP instance created from a factory. Provides audio computation and control.

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
| `clone()` | `InterpreterDsp` | Clone the DSP instance |
| `build_user_interface(sound_directory, sample_rate)` | | Build UI and load soundfiles |
| `compute(count, inputs, outputs)` | | Compute audio frames |
| `frame(inputs, outputs)` | | Compute a single frame (requires `-os` option) |
| `control()` | | Read controllers and update state (requires `-ec` option) |
| `metadata()` | `dict` | Get DSP metadata (name, author, etc.) |

#### Audio Computation

```python
import numpy as np

dsp = factory.create_dsp_instance()
dsp.init(48000)
dsp.build_user_interface()

n_frames = 1024
inputs = np.zeros((dsp.get_numinputs(), n_frames), dtype=np.float32)
outputs = np.zeros((dsp.get_numoutputs(), n_frames), dtype=np.float32)

dsp.compute(n_frames, inputs, outputs)
```

---

### RtAudioDriver

Real-time audio driver using the RtAudio cross-platform library.

```python
from cyfaust.interp import RtAudioDriver
```

#### Constructor

```python
RtAudioDriver(srate: int, bsize: int)
```

- `srate`: Sample rate in Hz
- `bsize`: Buffer size in frames

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `init(dsp)` | `bool` | Initialize with a DSP instance |
| `set_dsp(dsp)` | | Set DSP instance |
| `start()` | | Start audio playback |
| `stop()` | | Stop audio playback |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `buffersize` | `int` | Buffer size |
| `samplerate` | `int` | Sample rate |
| `numinputs` | `int` | Number of inputs |
| `numoutputs` | `int` | Number of outputs |

#### Example

```python
from cyfaust.interp import create_dsp_factory_from_string, RtAudioDriver
import time

factory = create_dsp_factory_from_string("osc",
    "import(\"stdfaust.lib\"); process = os.osc(440);")
dsp = factory.create_dsp_instance()
dsp.init(48000)
dsp.build_user_interface()

driver = RtAudioDriver(48000, 256)
driver.init(dsp)
driver.start()
time.sleep(2)
driver.stop()
```

---

### MetaCollector

Collects DSP metadata into a Python dictionary. Used internally by `InterpreterDsp.metadata()`.

| Method | Returns | Description |
|--------|---------|-------------|
| `get_metadata()` | `dict` | Collected metadata key-value pairs |

---

## Module-Level Functions

### Factory Creation

| Function | Returns | Description |
|----------|---------|-------------|
| `create_dsp_factory_from_file(filename, *args)` | `InterpreterDspFactory` | Create factory from a `.dsp` file |
| `create_dsp_factory_from_string(name_app, code, *args)` | `InterpreterDspFactory` | Create factory from source string |
| `create_dsp_factory_from_signals(name_app, signals, *args)` | `InterpreterDspFactory` | Create factory from signals |
| `create_dsp_factory_from_boxes(name_app, box, *args)` | `InterpreterDspFactory` | Create factory from boxes |

### Factory Cache

| Function | Returns | Description |
|----------|---------|-------------|
| `get_dsp_factory_from_sha_key(sha_key)` | `InterpreterDspFactory` | Retrieve cached factory |
| `get_all_dsp_factories()` | `list[str]` | List all cached factory SHA keys |
| `delete_all_dsp_factories()` | | Clear factory cache |

### Serialization

| Function | Returns | Description |
|----------|---------|-------------|
| `read_dsp_factory_from_bitcode(bitcode)` | `InterpreterDspFactory` | Deserialize from bitcode string |
| `read_dsp_factory_from_bitcode_file(path)` | `InterpreterDspFactory` | Deserialize from bitcode file |

### DSP Expansion

| Function | Returns | Description |
|----------|---------|-------------|
| `expand_dsp_from_file(filename, *args)` | `tuple[str, str]` | Expand DSP file to `(sha_key, code)` |
| `expand_dsp_from_string(name_app, code, *args)` | `tuple[str, str]` | Expand DSP string to `(sha_key, code)` |

### Auxiliary File Generation

| Function | Returns | Description |
|----------|---------|-------------|
| `generate_auxfiles_from_file(filename, *args)` | `bool` | Generate SVG, XML, JSON, etc. from file |
| `generate_auxfiles_from_string(name_app, code, *args)` | `bool` | Generate auxiliary files from string |

### Utilities

| Function | Returns | Description |
|----------|---------|-------------|
| `get_version()` | `str` | Library version string |
| `generate_sha1(data)` | `str` | Generate SHA1 hash from string |

### Multi-Threading

| Function | Returns | Description |
|----------|---------|-------------|
| `start_multithreaded_access_mode()` | `bool` | Enable multi-thread factory access |
| `stop_multithreaded_access_mode()` | | Disable multi-thread factory access |
