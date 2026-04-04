# Command-Line Interface

cyfaust provides a CLI accessible via `cyfaust` or `python -m cyfaust`.

```bash
cyfaust <command> [options]
```

## Commands

### version

Show cyfaust and libfaust version information:

```bash
cyfaust version
```

### info

Display DSP metadata, inputs, outputs, and dependencies:

```bash
cyfaust info synth.dsp
```

### compile

Compile Faust DSP to a target backend:

```bash
cyfaust compile synth.dsp -b cpp -o synth.cpp
cyfaust compile synth.dsp -b rust -o synth.rs
cyfaust compile synth.dsp -b c -o synth.c
```

Supported backends: `cpp`, `c`, `rust`, `codebox`

### expand

Expand Faust DSP to self-contained code with all imports resolved:

```bash
cyfaust expand filter.dsp -o filter_expanded.dsp
cyfaust expand filter.dsp --sha-only  # output only SHA1 key
```

### diagram

Generate SVG block diagrams:

```bash
cyfaust diagram synth.dsp -o diagrams/
```
