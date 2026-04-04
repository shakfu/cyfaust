# cyfaust.signal

The Signal API provides lower-level DSP composition using Faust's signal algebra. All signal operations must be performed within a `signal_context`.

## Context Manager

### signal_context

```python
from cyfaust.signal import signal_context

with signal_context():
    # all signal operations here
    ...
```

Creates and destroys the Faust library context required for signal operations.

---

## Classes

### Signal

Faust Signal expression wrapper.

```python
from cyfaust.signal import Signal
```

#### Static Factory Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `from_input(idx)` | `Signal` | Signal from input channel index |
| `from_int(value)` | `Signal` | Integer constant signal |
| `from_float(value)` | `Signal` | Float constant signal |
| `from_real(value)` | `Signal` | Alias for `from_float` |
| `from_soundfile(label)` | `Signal` | Soundfile signal |
| `from_button(label)` | `Signal` | Button UI signal |
| `from_checkbox(label)` | `Signal` | Checkbox UI signal |
| `from_vslider(label, init, min, max, step)` | `Signal` | Vertical slider signal |
| `from_hslider(label, init, min, max, step)` | `Signal` | Horizontal slider signal |
| `from_numentry(label, init, min, max, step)` | `Signal` | Number entry signal |
| `from_read_only_table(n, init, ridx)` | `Signal` | Read-only table |
| `from_write_read_table(n, init, widx, wsig, ridx)` | `Signal` | Read/write table |

#### Instance Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `to_string(shared, max_size)` | `str` | Convert to string representation |
| `print(shared, max_size)` | | Print signal expression |
| `create_source(name_app, lang, *args)` | `str` | Generate source code |
| `simplify_to_normal_form()` | `Signal` | Simplify to normal form |
| `ffname()` | `str` | Foreign function name |
| `ffarity()` | `int` | Foreign function arity |

#### Composition Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `attach(other)` | `Signal` | Attach signal |
| `delay(d)` | `Signal` | Delay by `d` samples |
| `select2(s1, s2)` | `Signal` | 2-way selector |
| `select3(s1, s2, s3)` | `Signal` | 3-way selector |
| `int_cast()` | `Signal` | Cast to integer |
| `float_cast()` | `Signal` | Cast to float |
| `recursion()` | `Signal` | Create recursive signal |
| `self_rec()` | `Signal` | Self-reference for recursion |
| `self_n(id)` | `Signal` | Multi-output self-reference |
| `recursion_n(rf)` | `SignalVector` | Multi-output recursive signal |
| `vbargraph(label, min, max)` | `Signal` | Vertical bargraph |
| `hbargraph(label, min, max)` | `Signal` | Horizontal bargraph |

#### Operators

`Signal` supports Python operators that map to Faust operations:

| Operator | Faust equivalent |
|----------|-----------------|
| `a + b` | `sig_add(a, b)` |
| `a - b` | `sig_sub(a, b)` |
| `a * b` | `sig_mul(a, b)` |
| `a / b` | `sig_div(a, b)` |
| `a % b` | `sig_rem(a, b)` |
| `a == b` | `sig_eq(a, b)` |
| `a != b` | `sig_ne(a, b)` |
| `a > b` | `sig_gt(a, b)` |
| `a >= b` | `sig_ge(a, b)` |
| `a < b` | `sig_lt(a, b)` |
| `a <= b` | `sig_le(a, b)` |
| `a & b` | `sig_and(a, b)` |
| `a \| b` | `sig_or(a, b)` |
| `a ^ b` | `sig_xor(a, b)` |
| `a << b` | `sig_leftshift(a, b)` |
| `a >> b` | `sig_lrightshift(a, b)` |

Reverse operators (`__radd__`, etc.) are supported for `int` and `float` left operands.

#### Math Methods

Unary: `abs()`, `acos()`, `asin()`, `atan()`, `ceil()`, `cos()`, `exp()`, `exp10()`, `floor()`, `log()`, `log10()`, `rint()`, `sin()`, `sqrt()`, `tan()`

Binary: `delay()`, `remainder()`, `pow()`, `min()`, `max()`, `fmod()`

All return `Signal`.

#### Type Checking Methods

`is_int()`, `is_float()`, `is_input()`, `is_output()`, `is_delay1()`, `is_delay()`, `is_prefix()`, `is_read_table()`, `is_write_table()`, `is_gen()`, `is_doc_constant_tbl()`, `is_doc_write_tbl()`, `is_doc_access_tbl()`, `is_select2()`, `is_assert_bounds()`, `is_highest()`, `is_lowest()`, `is_bin_op()`, `is_ffun()`, `is_fconst()`, `is_fvar()`, `is_proj()`, `is_rec()`, `is_int_cast()`, `is_float_cast()`, `is_button()`, `is_checkbox()`, `is_waveform()`, `is_hslider()`, `is_vslider()`, `is_num_entry()`, `is_hbargraph()`, `is_vbargraph()`, `is_attach()`, `is_enable()`, `is_control()`, `is_soundfile()`, `is_soundfile_length()`, `is_soundfile_rate()`, `is_soundfile_buffer()`

All return `dict` with extracted parameters (or empty `dict` if type doesn't match), except `is_waveform()` which returns `bool`.

---

### SignalVector

A vector of Signal expressions (wraps `std::vector<CTree*>`).

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `add(sig)` | | Add a Signal to the vector |
| `create_source(name_app, lang, *args)` | `str` | Generate source code from signals |
| `simplify_to_normal_form()` | `SignalVector` | Simplify signals to normal form |

Supports iteration via `for sig in signal_vector`.

---

### Interval

Signal interval wrapper with low, high, and LSB bounds.

```python
from cyfaust.signal import Interval

ival = Interval(lo=0.0, hi=1.0, lsb=0)
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `low` | `float` | Lower bound |
| `high` | `float` | Upper bound |
| `lsb` | `float` | Least significant bit |

---

## Enums

### SType

Signal type: `kSInt` (integer), `kSReal` (float). Used with `sig_fconst`, `sig_fvar`.

### SOperator

Binary operator type: `kAdd`, `kSub`, `kMul`, `kDiv`, `kRem`, `kLsh`, `kARsh`, `kLRsh`, `kGT`, `kLT`, `kGE`, `kLE`, `kEQ`, `kNE`, `kAND`, `kOR`, `kXOR`. Used with `sig_bin_op`.

---

## Module-Level Functions

### Primitives

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_int(n)` | `Signal` | Integer constant |
| `sig_real(n)` | `Signal` | Float constant |
| `sig_float(n)` | `Signal` | Alias for `sig_real` |
| `sig_input(idx)` | `Signal` | Input channel signal |

### Delay

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_delay(s, d)` | `Signal` | Delay signal `s` by `d` samples |
| `sig_delay1(s)` | `Signal` | One-sample delay |

### Casting

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_int_cast(s)` | `Signal` | Cast to integer |
| `sig_float_cast(s)` | `Signal` | Cast to float |

### Tables

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_readonly_table(n, init, ridx)` | `Signal` | Read-only table |
| `sig_write_read_table(n, init, widx, wsig, ridx)` | `Signal` | Read/write table |
| `sig_waveform_int(view)` | `Signal` | Waveform from int memoryview |
| `sig_waveform_float(view)` | `Signal` | Waveform from float memoryview |

### Soundfiles

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_soundfile(*paths)` | `Signal` | Soundfile from paths |
| `sig_soundfile_length(sf, part)` | `Signal` | Soundfile length |
| `sig_soundfile_rate(sf, part)` | `Signal` | Soundfile sample rate |
| `sig_soundfile_buffer(sf, chan, part, ridx)` | `Signal` | Soundfile buffer access |

### Selectors

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_select2(selector, s1, s2)` | `Signal` | 2-way selector |
| `sig_select3(selector, s1, s2, s3)` | `Signal` | 3-way selector |

### Arithmetic Operators

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_add(x, y)` | `Signal` | Addition |
| `sig_sub(x, y)` | `Signal` | Subtraction |
| `sig_mul(x, y)` | `Signal` | Multiplication |
| `sig_div(x, y)` | `Signal` | Division |
| `sig_rem(x, y)` | `Signal` | Remainder |
| `sig_pow(x, y)` | `Signal` | Power |
| `sig_fmod(x, y)` | `Signal` | Floating-point modulo |
| `sig_remainder(x, y)` | `Signal` | IEEE remainder |
| `sig_min(x, y)` | `Signal` | Minimum |
| `sig_max(x, y)` | `Signal` | Maximum |
| `sig_atan2(x, y)` | `Signal` | Arc tangent (2-arg) |
| `sig_bin_op(op, x, y)` | `Signal` | Generic binary operator |

### Bitwise Operators

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_leftshift(x, y)` | `Signal` | Left shift |
| `sig_lrightshift(x, y)` | `Signal` | Logical right shift |
| `sig_arightshift(x, y)` | `Signal` | Arithmetic right shift |
| `sig_and(x, y)` | `Signal` | Bitwise AND |
| `sig_or(x, y)` | `Signal` | Bitwise OR |
| `sig_xor(x, y)` | `Signal` | Bitwise XOR |

### Comparison Operators

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_gt(x, y)` | `Signal` | Greater than |
| `sig_lt(x, y)` | `Signal` | Less than |
| `sig_ge(x, y)` | `Signal` | Greater or equal |
| `sig_le(x, y)` | `Signal` | Less or equal |
| `sig_eq(x, y)` | `Signal` | Equal |
| `sig_ne(x, y)` | `Signal` | Not equal |

### Math Functions (Unary)

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_abs(x)` | `Signal` | Absolute value |
| `sig_acos(x)` | `Signal` | Arc cosine |
| `sig_asin(x)` | `Signal` | Arc sine |
| `sig_atan(x)` | `Signal` | Arc tangent |
| `sig_ceil(x)` | `Signal` | Ceiling |
| `sig_cos(x)` | `Signal` | Cosine |
| `sig_exp(x)` | `Signal` | Exponential |
| `sig_exp10(x)` | `Signal` | Base-10 exponential |
| `sig_floor(x)` | `Signal` | Floor |
| `sig_log(x)` | `Signal` | Natural logarithm |
| `sig_log10(x)` | `Signal` | Base-10 logarithm |
| `sig_rint(x)` | `Signal` | Round to nearest int |
| `sig_sin(x)` | `Signal` | Sine |
| `sig_sqrt(x)` | `Signal` | Square root |
| `sig_tan(x)` | `Signal` | Tangent |

### UI Elements

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_button(label)` | `Signal` | Button |
| `sig_checkbox(label)` | `Signal` | Checkbox |
| `sig_vslider(label, init, min, max, step)` | `Signal` | Vertical slider |
| `sig_hslider(label, init, min, max, step)` | `Signal` | Horizontal slider |
| `sig_numentry(label, init, min, max, step)` | `Signal` | Number entry |
| `sig_vbargraph(label, min, max, s)` | `Signal` | Vertical bargraph |
| `sig_hbargraph(label, min, max, s)` | `Signal` | Horizontal bargraph |

### Recursion

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_self()` | `Signal` | Self-reference for recursion |
| `sig_recursion(s)` | `Signal` | Create recursive signal |
| `sig_self_n(id)` | `Signal` | Multi-output self-reference |
| `sig_recursion_n(rf)` | `SignalVector` | Multi-output recursive signal |

### Foreign Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_fconst(type, name, file)` | `Signal` | Foreign constant |
| `sig_fvar(type, name, file)` | `Signal` | Foreign variable |

### Misc

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_attach(s1, s2)` | `Signal` | Attach signal (s2 depends on s1) |
| `simplify_to_normal_form(s)` | `Signal` | Simplify single signal |
| `simplify_to_normal_form2(vec)` | `SignalVector` | Simplify signal vector |
| `create_source_from_signals(name_app, osigs, lang, *args)` | `str` | Generate source code |

### Introspection / Type Checking

Functions prefixed with `is_sig_*` test the type of a signal and return a `dict` with extracted parameters (or empty dict if type doesn't match):

| Function | Returns | Description |
|----------|---------|-------------|
| `is_sig_int(t)` | `dict` | Is integer constant? |
| `is_sig_float(t)` | `dict` | Is float constant? |
| `is_sig_input(t)` | `dict` | Is input? |
| `is_sig_output(t)` | `dict` | Is output? |
| `is_sig_delay1(t)` | `dict` | Is one-sample delay? |
| `is_sig_delay(t)` | `dict` | Is delay? |
| `is_sig_prefix(t)` | `dict` | Is prefix? |
| `is_sig_readonly_table(s)` | `dict` | Is read-only table? |
| `is_sig_read_write_table(u)` | `dict` | Is read/write table? |
| `is_sig_gen(t)` | `dict` | Is generator? |
| `is_sig_select2(t)` | `dict` | Is 2-way selector? |
| `is_sig_assert_bounds(t)` | `dict` | Is assert bounds? |
| `is_sig_highest(t)` | `dict` | Is highest? |
| `is_sig_lowest(t)` | `dict` | Is lowest? |
| `is_sig_bin_op(s)` | `dict` | Is binary operator? |
| `is_sig_ffun(s)` | `dict` | Is foreign function? |
| `is_sig_fconst(s)` | `dict` | Is foreign constant? |
| `is_sig_fvar(s)` | `dict` | Is foreign variable? |
| `is_proj(s)` | `dict` | Is projection? |
| `is_rec(s)` | `dict` | Is recursion? |
| `is_sig_int_cast(s)` | `dict` | Is int cast? |
| `is_sig_float_cast(s)` | `dict` | Is float cast? |
| `is_sig_button(s)` | `dict` | Is button? |
| `is_sig_checkbox(s)` | `dict` | Is checkbox? |
| `is_sig_waveform(s)` | `bool` | Is waveform? |
| `is_sig_hslider(u)` | `dict` | Is horizontal slider? |
| `is_sig_vslider(u)` | `dict` | Is vertical slider? |
| `is_sig_numentry(u)` | `dict` | Is number entry? |
| `is_sig_hbargraph(s)` | `dict` | Is horizontal bargraph? |
| `is_sig_vbargraph(s)` | `dict` | Is vertical bargraph? |
| `is_sig_attach(s)` | `dict` | Is attach? |
| `is_sig_enable(s)` | `dict` | Is enable? |
| `is_sig_control(s)` | `dict` | Is control? |
| `is_sig_soundfile(s)` | `dict` | Is soundfile? |
| `is_sig_soundfile_length(s)` | `dict` | Is soundfile length? |
| `is_sig_soundfile_rate(s)` | `dict` | Is soundfile rate? |
| `is_sig_soundfile_buffer(s)` | `dict` | Is soundfile buffer? |

### Utility

| Function | Returns | Description |
|----------|---------|-------------|
| `print_signal(sig, shared, max_size)` | `str` | Print signal expression |
| `ffname(s)` | `str` | Foreign function name |
| `ffarity(s)` | `int` | Foreign function arity |
| `tree2str(s)` | `str` | Convert tree to string |
| `xtended_arity(s)` | `int` | Extended arity |
| `xtended_name(s)` | `str` | Extended name |
| `is_nil(s)` | `bool` | Is nil signal? |
| `create_lib_context()` | | Create library context (use `signal_context` instead) |
| `destroy_lib_context()` | | Destroy library context |

### Helper Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `sig_or_float(var)` | `Signal` | Convert `float \| Signal` to Signal |
| `sig_or_int(var)` | `Signal` | Convert `int \| Signal` to Signal |
