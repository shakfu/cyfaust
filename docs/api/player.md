# cyfaust.player

Sound file player classes for audio playback using RtAudio.

## Classes

### SoundBasePlayer

Base class for Faust sound players.

```python
from cyfaust.player import SoundBasePlayer

player = SoundBasePlayer("audio.wav")
```

#### Constructor

```python
SoundBasePlayer(filename: str)
```

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `get_num_inputs()` | `int` | Number of input channels |
| `get_num_outputs()` | `int` | Number of output channels |
| `get_sample_rate()` | `int` | Sample rate |
| `init(sample_rate)` | | Initialize with given sample rate |
| `instance_init(sample_rate)` | | Initialize instance with sample rate |
| `instance_constants(sample_rate)` | | Set instance constants |
| `instance_reset_user_interface()` | | Reset UI to default values |
| `instance_clear()` | | Clear instance state |
| `compute(count, inputs, outputs)` | | Compute audio output frames |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `filename` | `str` | Sound file path |

---

### SoundMemoryPlayer

Memory-based sound player that loads the entire file into memory. Subclass of `SoundBasePlayer`.

```python
from cyfaust.player import SoundMemoryPlayer, create_memory_player

player = SoundMemoryPlayer("audio.wav")
# or
player = create_memory_player("audio.wav")
```

---

### SoundDtdPlayer

Direct-to-disk sound player that streams from file. Subclass of `SoundBasePlayer`.

```python
from cyfaust.player import SoundDtdPlayer, create_dtd_player

player = SoundDtdPlayer("audio.wav")
# or
player = create_dtd_player("audio.wav")
```

---

### SoundPositionManager

Manager for sound player position control via GUI.

```python
from cyfaust.player import SoundPositionManager, create_position_manager

manager = create_position_manager()
manager.add_dsp(player)
```

#### Methods

| Method | Description |
|--------|-------------|
| `add_dsp(player)` | Add a sound player to be managed |
| `remove_dsp(player)` | Remove a sound player from management |

---

## Convenience Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `create_memory_player(filename)` | `SoundMemoryPlayer` | Create a memory-based sound player |
| `create_dtd_player(filename)` | `SoundDtdPlayer` | Create a direct-to-disk sound player |
| `create_position_manager()` | `SoundPositionManager` | Create a position manager for GUI control |
