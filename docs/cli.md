# Command-Line Interface

cyfaust provides a CLI accessible via `cyfaust` or `python -m cyfaust`.

```bash
cyfaust <command> [options]
```

For help on any command:

```bash
cyfaust <command> --help
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

| Option | Description |
|--------|-------------|
| `-b`, `--backend` | Target backend (default: `cpp`) |
| `-o`, `--output` | Output file (default: stdout) |

### expand

Expand Faust DSP to self-contained code with all imports resolved:

```bash
cyfaust expand filter.dsp -o filter_expanded.dsp
cyfaust expand filter.dsp --sha-only  # output only SHA1 key
```

| Option | Description |
|--------|-------------|
| `-o`, `--output` | Output file (default: stdout) |
| `--sha-only` | Only output the SHA1 key |

### diagram

Generate SVG block diagrams:

```bash
cyfaust diagram synth.dsp -o diagrams/
```

| Option | Description |
|--------|-------------|
| `-o`, `--output` | Output directory for SVG files |

### play

Play a Faust DSP file through speakers using RtAudio:

```bash
cyfaust play osc.dsp              # play until Ctrl+C
cyfaust play osc.dsp -d 5         # play for 5 seconds
cyfaust play osc.dsp -r 48000     # use 48kHz sample rate
cyfaust play osc.dsp -b 1024      # use 1024-sample buffer
```

| Option | Description |
|--------|-------------|
| `-d`, `--duration` | Duration in seconds (default: play until Ctrl+C) |
| `-r`, `--samplerate` | Sample rate in Hz (default: 44100) |
| `-b`, `--buffersize` | Buffer size in samples (default: 512) |

### params

List a DSP's controls, or read and drive their values, via the runtime UI
parameter API (`InterpreterDsp.params`/`get_param`/`set_param`). The DSP is
compiled and instantiated, so the output reflects exactly what the compiled DSP
exposes -- full UI path, widget kind, input/output flag, and current value --
rather than a static parse of the source.

```bash
cyfaust params synth.dsp
```

Example output:

```text
Parameters (3):
------------------------------------------------------------
  [0] /synth/freq (hslider, input) = 440.0
  [1] /synth/gain (vslider, input) = 0.5
  [2] /synth/gate (button, input) = 0.0
```

Add `--verbose` for the range metadata of each control:

```text
  [0] /synth/freq (hslider, input) = 440.0
      init=440.0, range=[50.0, 2000.0], step=1.0
```

Read or set specific controls by full path or unambiguous leaf label (both
`--get` and `--set` are repeatable); a `--set` is applied before any `--get`:

```bash
cyfaust params synth.dsp --get gain            # gain = 0.5
cyfaust params synth.dsp --set gain 0.8 --get gain
```

Bargraphs are read-only outputs; setting one, or naming an unknown/ambiguous
control, exits non-zero with an error.

| Option | Description |
|--------|-------------|
| `-v`, `--verbose` | Show init/range/step for each control |
| `--get PATH` | Get a control value by path or label (repeatable) |
| `--set PATH VALUE` | Set a control value by path or label (repeatable) |
| `--sample-rate` | Sample rate used to initialize the DSP (default: 48000) |

### validate

Check a Faust DSP file for compilation errors:

```bash
cyfaust validate filter.dsp
cyfaust validate filter.dsp --strict  # treat warnings as errors
```

| Option | Description |
|--------|-------------|
| `--strict` | Treat warnings as errors (non-zero exit code) |

### bitcode

Save a compiled DSP factory as bitcode for faster reloading, or load
an existing bitcode file and display its info:

```bash
cyfaust bitcode save synth.dsp -o synth.fbc
cyfaust bitcode load synth.fbc
```

| Option | Description |
|--------|-------------|
| `mode` | `save` or `load` |
| `-o`, `--output` | Output bitcode file (save mode only, default: `<name>.fbc`) |

### json

Export DSP metadata, parameters, and library dependencies as JSON. The
`parameters` entries are derived from the runtime UI parameter API (the same
source as `cyfaust params`), so each carries the full UI `path`, `label`,
widget `type`, `is_input` flag, current `value`, and range (`min`/`max`, plus
`init`/`step` for settable inputs):

```bash
cyfaust json instrument.dsp --pretty
cyfaust json instrument.dsp -o metadata.json
```

Excerpt:

```json
{
  "name": "synth",
  "inputs": 0,
  "outputs": 1,
  "parameters": [
    {
      "path": "/synth/gain",
      "label": "gain",
      "type": "vslider",
      "is_input": true,
      "value": 0.5,
      "min": 0.0,
      "max": 1.0,
      "init": 0.5,
      "step": 0.01
    }
  ]
}
```

| Option | Description |
|--------|-------------|
| `-o`, `--output` | Output JSON file (default: stdout) |
| `-p`, `--pretty` | Pretty-print JSON output |
