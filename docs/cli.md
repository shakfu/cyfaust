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

List all DSP parameters (sliders, buttons, bargraphs) by parsing the
expanded DSP code:

```bash
cyfaust params synth.dsp
```

Example output:

```text
Parameters (3):
------------------------------------------------------------
  [0] frequency (hslider)
      Init: 440, Range: [50, 2000], Step: 1
  [1] gain (vslider)
      Init: 0.5, Range: [0, 1], Step: 0.01
  [2] gate (button)
```

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

Export DSP metadata, parameters, and library dependencies as JSON:

```bash
cyfaust json instrument.dsp --pretty
cyfaust json instrument.dsp -o metadata.json
```

| Option | Description |
|--------|-------------|
| `-o`, `--output` | Output JSON file (default: stdout) |
| `-p`, `--pretty` | Pretty-print JSON output |
