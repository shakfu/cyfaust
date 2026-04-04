# cyfaust.common

Shared utilities and classes used across cyfaust modules.

## Functions

### get_package_resources

```python
get_package_resources() -> tuple[str, str, str, str]
```

Returns the paths of the bundled Faust architecture and library files as a tuple of compiler flags: `("-A", arch_path, "-I", lib_path)`.

These paths are automatically appended to compiler arguments by `ParamArray`, so you typically don't need to call this directly.

---

## Classes

### ParamArray

```python
ParamArray(args: tuple)
```

Wrapper around a Faust parameter array. Automatically appends the package resource paths (Faust standard libraries and architecture files) to the provided arguments.

Used internally by factory creation functions to pass compiler options to libfaust.

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `dump()` | | Print all parameters |
| `as_list()` | `list[str]` | Return parameters as a list of strings |

#### Example

```python
from cyfaust.common import ParamArray

params = ParamArray(("-vec", "-vs", "512"))
params.dump()
# -vec
# -vs
# 512
# -A
# /path/to/architecture
# -I
# /path/to/libraries
```

---

## Constants

### PACKAGE_RESOURCES

```python
PACKAGE_RESOURCES: tuple[str, str, str, str]
```

Pre-computed tuple of package resource flags. Equal to `get_package_resources()`.
