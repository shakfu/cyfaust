# API Reference

cyfaust provides Python bindings for the Faust DSP language through the following modules:

| Module | Description |
|--------|-------------|
| [`cyfaust.interp`](interp.md) | Faust interpreter backend, DSP factory/instance creation, RtAudio driver |
| [`cyfaust.box`](box.md) | Box API for functional signal composition |
| [`cyfaust.signal`](signal.md) | Signal API for lower-level DSP composition |
| [`cyfaust.common`](common.md) | Shared utilities (ParamArray, resource paths) |
| [`cyfaust.player`](player.md) | Sound file player classes |

## Design

The Box and Signal APIs offer **dual interfaces**:

- **Functional**: Standalone functions like `box_int()`, `sig_input()`, `box_seq()`
- **Object-oriented**: Class methods like `Box.from_int()`, `Signal.from_input()`

Both interfaces produce identical results. The functional API mirrors the C API naming while the OO API provides a more Pythonic interface.

## Context Managers

The Box and Signal APIs require a compilation context. Use the provided context managers:

```python
from cyfaust.box import box_context

with box_context():
    # box operations here
    ...
```

```python
from cyfaust.signal import signal_context

with signal_context():
    # signal operations here
    ...
```
