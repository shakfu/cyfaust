# cyfaust.box

The Box API provides functional signal composition using Faust's box algebra. All box operations must be performed within a `box_context`.

## Context Manager

### box_context

```python
from cyfaust.box import box_context

with box_context():
    # all box operations here
    ...
```

Creates and destroys the Faust library context required for box operations.

---

## Classes

### Box

Faust Box expression wrapper. Supports both functional and object-oriented creation.

```python
from cyfaust.box import Box
```

#### Constructor

```python
Box(value=None)
```

- `None` (default): creates a wire box (copies input to output)
- `int`: creates an integer constant box
- `float`: creates a float constant box

#### Static Factory Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `from_int(value)` | `Box` | Integer constant box |
| `from_float(value)` | `Box` | Float constant box |
| `from_real(value)` | `Box` | Alias for `from_float` |
| `from_wire()` | `Box` | Wire box (copies input to output) |
| `from_cut()` | `Box` | Cut box (terminates a signal) |
| `from_soundfile(label, chan, part, ridx)` | `Box` | Soundfile block |
| `from_readonly_table(n, init, ridx)` | `Box` | Read-only table |
| `from_write_read_table(n, init, widx, wsig, ridx)` | `Box` | Read/write table |
| `from_waveform(wf)` | `Box` | Waveform from BoxVector |
| `from_fconst(type, name, file)` | `Box` | Foreign constant |
| `from_fvar(type, name, file)` | `Box` | Foreign variable |

#### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `inputs` | `int` | Number of inputs |
| `outputs` | `int` | Number of outputs |

#### Instance Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `is_valid()` | `bool` | Check if the box is valid |
| `to_string(shared, max_size)` | `str` | Convert to string representation |
| `print(shared, max_size)` | | Print box expression |
| `create_source(name_app, lang, *args)` | `str` | Generate source code |
| `tree2str()` | `str` | Convert tree to string |
| `tree2int()` | `int` | Convert tree to integer |
| `get_def_name_property()` | `Box \| None` | Get definition name property |
| `extract_name()` | `str` | Extract name from label |

#### Composition Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `seq(other)` | `Box` | Sequential composition |
| `par(other)` | `Box` | Parallel composition |
| `par3(b, c)` | `Box` | Parallel composition (3) |
| `par4(b, c, d)` | `Box` | Parallel composition (4) |
| `par5(b, c, d, e)` | `Box` | Parallel composition (5) |
| `split(other)` | `Box` | Split composition |
| `merge(other)` | `Box` | Merge composition |
| `rec(other)` | `Box` | Recursive composition |
| `delay(d)` | `Box` | Delay by `d` samples (`int` or `Box`) |
| `select2(b1, b2)` | `Box` | 2-way selector |
| `select3(b1, b2, b3)` | `Box` | 3-way selector |
| `int_cast()` | `Box` | Cast to int |
| `float_cast()` | `Box` | Cast to float |

#### Operators

`Box` supports Python operators that map to Faust operations:

| Operator | Faust equivalent |
|----------|-----------------|
| `a + b` | `box_add(a, b)` |
| `a - b` | `box_sub(a, b)` |
| `a * b` | `box_mul(a, b)` |
| `a / b` | `box_div(a, b)` |
| `a % b` | `box_rem(a, b)` |
| `a == b` | `box_eq(a, b)` |
| `a != b` | `box_ne(a, b)` |
| `a > b` | `box_gt(a, b)` |
| `a >= b` | `box_ge(a, b)` |
| `a < b` | `box_lt(a, b)` |
| `a <= b` | `box_le(a, b)` |
| `a & b` | `box_and(a, b)` |
| `a \| b` | `box_or(a, b)` |
| `a ^ b` | `box_xor(a, b)` |
| `a << b` | `box_leftshift(a, b)` |
| `a >> b` | `box_lrightshift(a, b)` |

#### Math Methods

Unary: `abs()`, `acos()`, `asin()`, `atan()`, `ceil()`, `cos()`, `exp()`, `exp10()`, `floor()`, `log()`, `log10()`, `rint()`, `round()`, `sin()`, `sqrt()`, `tan()`

All return `Box`.

#### Type Checking Methods

`is_nil()`, `is_abstr()`, `is_appl()`, `is_button()`, `is_case()`, `is_checkbox()`, `is_cut()`, `is_environment()`, `is_error()`, `is_fconst()`, `is_ffun()`, `is_fvar()`, `is_hbargraph()`, `is_hgroup()`, `is_hslider()`, `is_ident()`, `is_int()`, `is_numentry()`, `is_prim0()` .. `is_prim5()`, `is_real()`, `is_slot()`, `is_soundfile()`, `is_symbolic()`, `is_tgroup()`, `is_vbargraph()`, `is_vgroup()`, `is_vslider()`, `is_waveform()`, `is_wire()`

All return `bool`.

---

### BoxVector

A vector of Box expressions (wraps `std::vector<CTree*>`).

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `add(box)` | | Add a Box to the vector |
| `create_source(name_app, lang, *args)` | `str` | Generate source code from boxes |

Supports iteration via `for box in box_vector`.

---

## Enums

### SType

Signal type: `kSInt` (integer), `kSReal` (float). Used with `box_fconst`, `box_fvar`.

### SOperator

Binary operator type: `kAdd`, `kSub`, `kMul`, `kDiv`, `kRem`, `kLsh`, `kARsh`, `kLRsh`, `kGT`, `kLT`, `kGE`, `kLE`, `kEQ`, `kNE`, `kAND`, `kOR`, `kXOR`. Used with `box_bin_op`.

---

## Module-Level Functions

### DSP Conversion

| Function | Returns | Description |
|----------|---------|-------------|
| `dsp_to_boxes(name_app, dsp_content, *args)` | `Box \| None` | Parse Faust DSP code to a Box expression |
| `get_box_type(b)` | `tuple[int, int] \| None` | Get (inputs, outputs) of a Box |
| `boxes_to_signals(b)` | `SignalVector \| None` | Convert Box to signals |
| `create_source_from_boxes(name_app, box, lang, *args)` | `str \| None` | Generate source code from a Box |

### Primitives

| Function | Returns | Description |
|----------|---------|-------------|
| `box_int(n)` | `Box` | Integer constant |
| `box_float(n)` | `Box` | Float constant |
| `box_real(n)` | `Box` | Alias for `box_float` |
| `box_wire()` | `Box` | Wire (identity) |
| `box_cut()` | `Box` | Cut (terminate signal) |

### Composition

| Function | Returns | Description |
|----------|---------|-------------|
| `box_seq(x, y)` | `Box` | Sequential composition |
| `box_par(x, y)` | `Box` | Parallel composition (2 boxes) |
| `box_par3(x, y, z)` | `Box` | Parallel composition (3 boxes) |
| `box_par4(a, b, c, d)` | `Box` | Parallel composition (4 boxes) |
| `box_par5(a, b, c, d, e)` | `Box` | Parallel composition (5 boxes) |
| `box_split(x, y)` | `Box` | Split composition |
| `box_merge(x, y)` | `Box` | Merge composition |
| `box_rec(x, y)` | `Box` | Recursive composition |
| `box_route(n, m, r)` | `Box` | Route connections |

### Delay

| Function | Returns | Description |
|----------|---------|-------------|
| `box_delay(b, d)` | `Box` | Delay box `b` by `d` samples |
| `box_delay_op()` | `Box` | Delay operator (primitive) |

### Casting

| Function | Returns | Description |
|----------|---------|-------------|
| `box_int_cast(b)` | `Box` | Cast to int |
| `box_int_cast_op()` | `Box` | Int cast operator |
| `box_float_cast(b)` | `Box` | Cast to float |
| `box_float_cast_op()` | `Box` | Float cast operator |

### Tables

| Function | Returns | Description |
|----------|---------|-------------|
| `box_readonly_table(n, init, ridx)` | `Box` | Read-only table |
| `box_readonly_table_op()` | `Box` | Read-only table operator |
| `box_write_read_table(n, init, widx, wsig, ridx)` | `Box` | Read/write table |
| `box_write_read_table_op()` | `Box` | Read/write table operator |
| `box_waveform(wf)` | `Box` | Waveform from BoxVector |
| `box_soundfile(label, chan, part, ridx)` | `Box` | Soundfile block |

### Arithmetic Operators

Each operator has both a primitive form (`_op`) and an applied form.

| Function | Returns | Description |
|----------|---------|-------------|
| `box_add(b1, b2)` | `Box` | Addition |
| `box_sub(b1, b2)` | `Box` | Subtraction |
| `box_mul(b1, b2)` | `Box` | Multiplication |
| `box_div(b1, b2)` | `Box` | Division |
| `box_rem(b1, b2)` | `Box` | Remainder |
| `box_pow(b1, b2)` | `Box` | Power |
| `box_fmod(b1, b2)` | `Box` | Floating-point modulo |
| `box_remainder(b1, b2)` | `Box` | IEEE remainder |
| `box_min(b1, b2)` | `Box` | Minimum |
| `box_max(b1, b2)` | `Box` | Maximum |
| `box_atan2(b1, b2)` | `Box` | Arc tangent (2-arg) |

### Bitwise Operators

| Function | Returns | Description |
|----------|---------|-------------|
| `box_leftshift(b1, b2)` | `Box` | Left shift |
| `box_lrightshift(b1, b2)` | `Box` | Logical right shift |
| `box_arightshift(b1, b2)` | `Box` | Arithmetic right shift |
| `box_and(b1, b2)` | `Box` | Bitwise AND |
| `box_or(b1, b2)` | `Box` | Bitwise OR |
| `box_xor(b1, b2)` | `Box` | Bitwise XOR |

### Comparison Operators

| Function | Returns | Description |
|----------|---------|-------------|
| `box_gt(b1, b2)` | `Box` | Greater than |
| `box_lt(b1, b2)` | `Box` | Less than |
| `box_ge(b1, b2)` | `Box` | Greater or equal |
| `box_le(b1, b2)` | `Box` | Less or equal |
| `box_eq(b1, b2)` | `Box` | Equal |
| `box_ne(b1, b2)` | `Box` | Not equal |

### Math Functions (Unary)

| Function | Returns | Description |
|----------|---------|-------------|
| `box_abs(x)` | `Box` | Absolute value |
| `box_acos(x)` | `Box` | Arc cosine |
| `box_asin(x)` | `Box` | Arc sine |
| `box_atan(x)` | `Box` | Arc tangent |
| `box_ceil(x)` | `Box` | Ceiling |
| `box_cos(x)` | `Box` | Cosine |
| `box_exp(x)` | `Box` | Exponential |
| `box_exp10(x)` | `Box` | Base-10 exponential |
| `box_floor(x)` | `Box` | Floor |
| `box_log(x)` | `Box` | Natural logarithm |
| `box_log10(x)` | `Box` | Base-10 logarithm |
| `box_rint(x)` | `Box` | Round to nearest int |
| `box_round(x)` | `Box` | Round |
| `box_sin(x)` | `Box` | Sine |
| `box_sqrt(x)` | `Box` | Square root |
| `box_tan(x)` | `Box` | Tangent |

### UI Elements

| Function | Returns | Description |
|----------|---------|-------------|
| `box_button(label)` | `Box` | Button |
| `box_checkbox(label)` | `Box` | Checkbox |
| `box_vslider(label, init, min, max, step)` | `Box` | Vertical slider |
| `box_hslider(label, init, min, max, step)` | `Box` | Horizontal slider |
| `box_numentry(label, init, min, max, step)` | `Box` | Number entry |
| `box_vbargraph(label, min, max)` | `Box` | Vertical bargraph |
| `box_vbargraph2(label, min, max, x)` | `Box` | Vertical bargraph (applied) |
| `box_hbargraph(label, min, max)` | `Box` | Horizontal bargraph |
| `box_hbargraph2(label, min, max, x)` | `Box` | Horizontal bargraph (applied) |

### Grouping

| Function | Returns | Description |
|----------|---------|-------------|
| `box_vgroup(label, group)` | `Box` | Vertical group |
| `box_hgroup(label, group)` | `Box` | Horizontal group |
| `box_tgroup(label, group)` | `Box` | Tab group |

### Selectors

| Function | Returns | Description |
|----------|---------|-------------|
| `box_select2(selector, b1, b2)` | `Box` | 2-way selector |
| `box_select2_op()` | `Box` | 2-way selector operator |
| `box_select3(selector, b1, b2, b3)` | `Box` | 3-way selector |

### Foreign Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `box_fconst(type, name, file)` | `Box` | Foreign constant |
| `box_fvar(type, name, file)` | `Box` | Foreign variable |
| `box_bin_op(op, b1, b2)` | `Box` | Generic binary operator |
| `box_bin_op0(op)` | `Box` | Generic binary operator (primitive) |

### Misc

| Function | Returns | Description |
|----------|---------|-------------|
| `box_attach(b1, b2)` | `Box` | Attach box (b2 depends on b1) |
| `box_attach_op()` | `Box` | Attach operator |

### Introspection / Type Checking

Functions prefixed with `is_box_*` test the type of a box expression:

| Function | Returns | Description |
|----------|---------|-------------|
| `is_box_int(t)` | `bool` | Is integer constant? |
| `is_box_real(t)` | `bool` | Is float constant? |
| `is_box_cut(t)` | `bool` | Is cut? |
| `is_box_ident(t)` | `bool` | Is identifier? |
| `is_box_slot(t)` | `bool` | Is slot? |
| `is_box_abstr(t)` | `bool` | Is abstraction? |
| `is_box_appl(t)` | `bool` | Is application? |
| `is_box_button(b)` | `bool` | Is button? |
| `is_box_case(b)` | `bool` | Is case? |
| `is_box_checkbox(b)` | `bool` | Is checkbox? |
| `is_box_environment(b)` | `bool` | Is environment? |
| `is_box_error(t)` | `bool` | Is error? |
| `is_box_fconst(b)` | `bool` | Is foreign constant? |
| `is_box_ffun(b)` | `bool` | Is foreign function? |
| `is_box_fvar(b)` | `bool` | Is foreign variable? |
| `is_box_hbargraph(b)` | `bool` | Is horizontal bargraph? |
| `is_box_hgroup(b)` | `bool` | Is horizontal group? |
| `is_box_hslider(b)` | `bool` | Is horizontal slider? |
| `is_box_numentry(b)` | `bool` | Is number entry? |
| `is_box_prim0(b)` .. `is_box_prim5(b)` | `bool` | Is primitive (0-5 args)? |
| `is_box_soundfile(b)` | `bool` | Is soundfile? |
| `box_is_nil(b)` | `bool` | Is nil? |

Functions prefixed with `getparams_box_*` extract parameters from typed boxes and return a `dict`:

`getparams_box_int`, `getparams_box_real`, `getparams_box_button`, `getparams_box_checkbox`, `getparams_box_hslider`, `getparams_box_hbargraph`, `getparams_box_hgroup`, `getparams_box_num_entry`, `getparams_box_par`, `getparams_box_seq`, `getparams_box_rec`, `getparams_box_route`, `getparams_box_merge`, `getparams_box_slot`, `getparams_box_soundfile`, `getparams_box_abstr`, `getparams_box_access`, `getparams_box_appl`, `getparams_box_case`, `getparams_box_component`, `getparams_box_fconst`, `getparams_box_ffun`, `getparams_box_fvar`, `getparams_box_inputs`, `getparams_box_ipar`, `getparams_box_iprod`, `getparams_box_iseq`, `getparams_box_isum`, `getparams_box_library`, `getparams_box_metadata`, `getparams_box_outputs`

### Utility

| Function | Returns | Description |
|----------|---------|-------------|
| `to_string(box, shared, max_size)` | `str` | Convert box to string |
| `print_box(box, shared, max_size)` | `str` | Print box expression |
| `get_def_name_property(b)` | `Box \| None` | Get definition name |
| `extract_name(full_label)` | `str` | Extract name from label |
| `tree2str(b)` | `str` | Convert tree to string |
| `tree2int(b)` | `int` | Convert tree to integer |
| `create_lib_context()` | | Create library context (use `box_context` instead) |
| `destroy_lib_context()` | | Destroy library context |

### Helper Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `box_or_int(var)` | `Box` | Convert `int \| Box` to Box |
| `box_or_float(var)` | `Box` | Convert `float \| Box` to Box |
| `box_or_number(var)` | `Box` | Convert `int \| float \| Box` to Box |
