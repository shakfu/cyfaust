#!/usr/bin/env python3
"""cyfaust command-line interface.

Usage:
    cyfaust <command> [options]

Commands:
    version     Show cyfaust and libfaust version information
    compile     Compile Faust DSP to various backends (cpp, c, rust, codebox)
    diagram     Generate SVG block diagram from Faust DSP
    expand      Expand Faust DSP to self-contained code
    info        Show DSP information (metadata, inputs, outputs)
    play        Play a Faust DSP file with RtAudio
    params      List all DSP parameters (sliders, buttons, etc.)
    validate    Check a Faust DSP file for errors
    bitcode     Save/load DSP factory as bitcode
    json        Export DSP metadata as JSON

Examples:
    cyfaust version
    cyfaust compile examples/noise.dsp -o noise.cpp
    cyfaust play examples/osc.dsp -d 5
    cyfaust params examples/synth.dsp
    cyfaust info examples/instrument.dsp
"""

import argparse
import json as json_module
import signal
import sys
import os
import time
from pathlib import Path


def get_cyfaust_imports():
    """Import cyfaust modules, handling both dynamic and static builds."""
    try:
        from cyfaust.interp import (
            get_version,
            create_dsp_factory_from_file,
            create_dsp_factory_from_string,
            expand_dsp_from_file,
            generate_auxfiles_from_file,
            RtAudioDriver,
            read_dsp_factory_from_bitcode_file,
        )
        from cyfaust.box import (
            create_source_from_boxes,
            dsp_to_boxes,
            create_lib_context,
            destroy_lib_context,
        )
        return {
            'get_version': get_version,
            'create_dsp_factory_from_file': create_dsp_factory_from_file,
            'create_dsp_factory_from_string': create_dsp_factory_from_string,
            'expand_dsp_from_file': expand_dsp_from_file,
            'generate_auxfiles_from_file': generate_auxfiles_from_file,
            'create_source_from_boxes': create_source_from_boxes,
            'dsp_to_boxes': dsp_to_boxes,
            'create_lib_context': create_lib_context,
            'destroy_lib_context': destroy_lib_context,
            'RtAudioDriver': RtAudioDriver,
            'read_dsp_factory_from_bitcode_file': read_dsp_factory_from_bitcode_file,
        }
    except ImportError:
        from cyfaust.cyfaust import (
            get_version,
            create_dsp_factory_from_file,
            create_dsp_factory_from_string,
            expand_dsp_from_file,
            generate_auxfiles_from_file,
            create_source_from_boxes,
            dsp_to_boxes,
            create_lib_context,
            destroy_lib_context,
            RtAudioDriver,
            read_dsp_factory_from_bitcode_file,
        )
        return {
            'get_version': get_version,
            'create_dsp_factory_from_file': create_dsp_factory_from_file,
            'create_dsp_factory_from_string': create_dsp_factory_from_string,
            'expand_dsp_from_file': expand_dsp_from_file,
            'generate_auxfiles_from_file': generate_auxfiles_from_file,
            'create_source_from_boxes': create_source_from_boxes,
            'dsp_to_boxes': dsp_to_boxes,
            'create_lib_context': create_lib_context,
            'destroy_lib_context': destroy_lib_context,
            'RtAudioDriver': RtAudioDriver,
            'read_dsp_factory_from_bitcode_file': read_dsp_factory_from_bitcode_file,
        }


def cmd_version(args):
    """Show version information."""
    imports = get_cyfaust_imports()
    print(f"cyfaust CLI")
    print(f"libfaust version: {imports['get_version']()}")
    return 0


def cmd_compile(args):
    """Compile Faust DSP to target backend."""
    imports = get_cyfaust_imports()

    if not os.path.exists(args.input):
        print(f"Error: File not found: {args.input}", file=sys.stderr)
        return 1

    # Map backend names
    backend_map = {
        'cpp': 'cpp',
        'c++': 'cpp',
        'c': 'c',
        'rust': 'rust',
        'codebox': 'codebox',
    }

    backend = backend_map.get(args.backend.lower())
    if not backend:
        print(f"Error: Unknown backend '{args.backend}'. "
              f"Choose from: cpp, c, rust, codebox", file=sys.stderr)
        return 1

    # Read DSP file content
    name = Path(args.input).stem
    with open(args.input, 'r') as f:
        dsp_content = f.read()

    # Initialize library context for box operations
    imports['create_lib_context']()
    try:
        # Create box from DSP content
        box = imports['dsp_to_boxes'](name, dsp_content)
        if box is None:
            print(f"Error: Failed to parse DSP file: {args.input}", file=sys.stderr)
            return 1

        # Generate source code
        source = imports['create_source_from_boxes'](name, box, backend)
        if source is None:
            print(f"Error: Failed to generate {backend} code", file=sys.stderr)
            return 1

        # Output
        if args.output:
            with open(args.output, 'w') as f:
                f.write(source)
            print(f"Generated {backend} code: {args.output}")
        else:
            print(source)

        return 0
    finally:
        imports['destroy_lib_context']()


def cmd_diagram(args):
    """Generate SVG block diagram."""
    imports = get_cyfaust_imports()

    if not os.path.exists(args.input):
        print(f"Error: File not found: {args.input}", file=sys.stderr)
        return 1

    # Determine output directory
    if args.output:
        output_dir = str(Path(args.output).parent or '.')
        svg_option = f"-svg"
        output_option = f"-O"
        output_path = output_dir
    else:
        output_dir = '.'
        svg_option = "-svg"
        output_option = "-O"
        output_path = output_dir

    # Generate SVG using auxfiles
    result = imports['generate_auxfiles_from_file'](
        args.input,
        svg_option,
        output_option, output_path
    )

    if result:
        name = Path(args.input).stem
        svg_dir = Path(output_path) / f"{name}-svg"
        print(f"Generated SVG diagram in: {svg_dir}")
        return 0
    else:
        print("Error: Failed to generate SVG diagram", file=sys.stderr)
        return 1


def cmd_expand(args):
    """Expand Faust DSP to self-contained code."""
    imports = get_cyfaust_imports()

    if not os.path.exists(args.input):
        print(f"Error: File not found: {args.input}", file=sys.stderr)
        return 1

    result = imports['expand_dsp_from_file'](args.input)
    if result is None:
        print("Error: Failed to expand DSP", file=sys.stderr)
        return 1

    sha_key, expanded_code = result

    if args.output:
        with open(args.output, 'w') as f:
            f.write(expanded_code)
        print(f"Expanded DSP written to: {args.output}")
        print(f"SHA1 key: {sha_key}")
    else:
        if args.sha_only:
            print(sha_key)
        else:
            print(f"// SHA1: {sha_key}")
            print(expanded_code)

    return 0


def cmd_info(args):
    """Show DSP information."""
    imports = get_cyfaust_imports()

    if not os.path.exists(args.input):
        print(f"Error: File not found: {args.input}", file=sys.stderr)
        return 1

    factory = imports['create_dsp_factory_from_file'](args.input)
    if factory is None:
        print(f"Error: Failed to create DSP factory from: {args.input}", file=sys.stderr)
        return 1

    dsp = factory.create_dsp_instance()
    if dsp is None:
        print("Error: Failed to create DSP instance", file=sys.stderr)
        return 1

    # Initialize to get proper info
    dsp.init(44100)

    print(f"File: {args.input}")
    print(f"Name: {factory.get_name()}")
    print(f"SHA Key: {factory.get_sha_key()}")
    print(f"Compile Options: {factory.get_compile_options()}")
    print(f"Inputs: {dsp.get_numinputs()}")
    print(f"Outputs: {dsp.get_numoutputs()}")

    # Get metadata
    try:
        meta = dsp.metadata()
        if meta:
            print("\nMetadata:")
            for key, value in sorted(meta.items()):
                print(f"  {key}: {value}")
    except Exception:
        pass  # metadata() might not be available in older builds

    # Library dependencies
    libs = factory.get_library_list()
    if libs:
        print(f"\nLibraries ({len(libs)}):")
        for lib in libs:
            print(f"  {lib}")

    # Warnings
    warnings = factory.get_warning_messages()
    if warnings:
        print(f"\nWarnings ({len(warnings)}):")
        for warn in warnings:
            print(f"  {warn}")

    return 0


def cmd_play(args):
    """Play a Faust DSP file with RtAudio."""
    imports = get_cyfaust_imports()

    if not os.path.exists(args.input):
        print(f"Error: File not found: {args.input}", file=sys.stderr)
        return 1

    factory = imports['create_dsp_factory_from_file'](args.input)
    if factory is None:
        print(f"Error: Failed to create DSP factory from: {args.input}", file=sys.stderr)
        return 1

    dsp = factory.create_dsp_instance()
    if dsp is None:
        print("Error: Failed to create DSP instance", file=sys.stderr)
        return 1

    sample_rate = args.samplerate
    buffer_size = args.buffersize

    # Initialize DSP
    dsp.init(sample_rate)

    # Build user interface to enable soundfile support
    try:
        dsp.build_user_interface()
    except Exception:
        pass  # May not be needed for all DSPs

    # Create and initialize audio driver
    driver = imports['RtAudioDriver'](sample_rate, buffer_size)
    if not driver.init(dsp):
        print("Error: Failed to initialize audio driver", file=sys.stderr)
        return 1

    # Setup signal handler for clean exit
    running = [True]

    def signal_handler(signum, frame):
        running[0] = False
        print("\nStopping...")

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    # Start playback
    name = factory.get_name()
    print(f"Playing: {name}")
    print(f"  Sample rate: {sample_rate} Hz")
    print(f"  Buffer size: {buffer_size}")
    print(f"  Inputs: {dsp.get_numinputs()}, Outputs: {dsp.get_numoutputs()}")
    if args.duration:
        print(f"  Duration: {args.duration} seconds")
    print("Press Ctrl+C to stop...")

    driver.start()

    try:
        if args.duration:
            # Play for specified duration
            end_time = time.time() + args.duration
            while running[0] and time.time() < end_time:
                time.sleep(0.1)
        else:
            # Play indefinitely until interrupted
            while running[0]:
                time.sleep(0.1)
    finally:
        driver.stop()
        print("Stopped.")

    return 0


def cmd_params(args):
    """List all DSP parameters by parsing the expanded code."""
    imports = get_cyfaust_imports()

    if not os.path.exists(args.input):
        print(f"Error: File not found: {args.input}", file=sys.stderr)
        return 1

    # Expand DSP to get all UI elements
    result = imports['expand_dsp_from_file'](args.input)
    if result is None:
        print("Error: Failed to expand DSP", file=sys.stderr)
        return 1

    sha_key, expanded_code = result

    # Parse the expanded code to find UI elements
    import re

    # Find sliders, buttons, etc.
    ui_patterns = [
        (r'vslider\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^)]+)\)', 'vslider'),
        (r'hslider\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^)]+)\)', 'hslider'),
        (r'nentry\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^)]+)\)', 'nentry'),
        (r'button\s*\(\s*"([^"]+)"\s*\)', 'button'),
        (r'checkbox\s*\(\s*"([^"]+)"\s*\)', 'checkbox'),
        (r'vbargraph\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*([^)]+)\)', 'vbargraph'),
        (r'hbargraph\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*([^)]+)\)', 'hbargraph'),
    ]

    params = []
    for pattern, ui_type in ui_patterns:
        for match in re.finditer(pattern, expanded_code):
            if ui_type in ['vslider', 'hslider', 'nentry']:
                params.append({
                    'type': ui_type,
                    'label': match.group(1),
                    'init': match.group(2).strip(),
                    'min': match.group(3).strip(),
                    'max': match.group(4).strip(),
                    'step': match.group(5).strip(),
                })
            elif ui_type in ['button', 'checkbox']:
                params.append({
                    'type': ui_type,
                    'label': match.group(1),
                })
            elif ui_type in ['vbargraph', 'hbargraph']:
                params.append({
                    'type': ui_type,
                    'label': match.group(1),
                    'min': match.group(2).strip(),
                    'max': match.group(3).strip(),
                })

    if not params:
        print(f"No parameters found in: {args.input}")
        return 0

    print(f"Parameters ({len(params)}):")
    print("-" * 60)

    for i, p in enumerate(params):
        print(f"  [{i}] {p['label']} ({p['type']})")
        if 'init' in p:
            print(f"      Init: {p['init']}, Range: [{p['min']}, {p['max']}], Step: {p['step']}")
        elif 'min' in p:
            print(f"      Range: [{p['min']}, {p['max']}]")

    return 0


def cmd_validate(args):
    """Validate a Faust DSP file for errors."""
    imports = get_cyfaust_imports()

    if not os.path.exists(args.input):
        print(f"Error: File not found: {args.input}", file=sys.stderr)
        return 1

    # Try to create factory - this will catch compile errors
    factory = imports['create_dsp_factory_from_file'](args.input)

    if factory is None:
        print(f"INVALID: {args.input}")
        print("  Failed to compile DSP")
        return 1

    # Check for warnings
    warnings = factory.get_warning_messages()

    # Try to create DSP instance
    dsp = factory.create_dsp_instance()
    if dsp is None:
        print(f"INVALID: {args.input}")
        print("  Failed to create DSP instance")
        return 1

    # Initialize and check basic properties
    dsp.init(44100)
    num_inputs = dsp.get_numinputs()
    num_outputs = dsp.get_numoutputs()

    if num_outputs == 0 and num_inputs == 0:
        print(f"WARNING: {args.input}")
        print("  DSP has no inputs or outputs")
        if warnings:
            for w in warnings:
                print(f"  Warning: {w}")
        return 0 if not args.strict else 1

    print(f"VALID: {args.input}")
    print(f"  Name: {factory.get_name()}")
    print(f"  Inputs: {num_inputs}, Outputs: {num_outputs}")

    if warnings:
        print(f"  Warnings ({len(warnings)}):")
        for w in warnings:
            print(f"    - {w}")
        if args.strict:
            return 1

    return 0


def cmd_bitcode(args):
    """Save or load DSP factory as bitcode."""
    imports = get_cyfaust_imports()

    if args.mode == 'save':
        # Save DSP to bitcode
        if not os.path.exists(args.input):
            print(f"Error: File not found: {args.input}", file=sys.stderr)
            return 1

        factory = imports['create_dsp_factory_from_file'](args.input)
        if factory is None:
            print(f"Error: Failed to create DSP factory from: {args.input}", file=sys.stderr)
            return 1

        output_path = args.output or (Path(args.input).stem + ".fbc")
        # Use factory method to write bitcode
        result = factory.write_to_bitcode_file(output_path)

        if result:
            print(f"Saved bitcode to: {output_path}")
            return 0
        else:
            print("Error: Failed to write bitcode file", file=sys.stderr)
            return 1

    elif args.mode == 'load':
        # Load bitcode and show info
        if not os.path.exists(args.input):
            print(f"Error: File not found: {args.input}", file=sys.stderr)
            return 1

        factory = imports['read_dsp_factory_from_bitcode_file'](args.input)
        if factory is None:
            print(f"Error: Failed to load bitcode from: {args.input}", file=sys.stderr)
            return 1

        dsp = factory.create_dsp_instance()
        if dsp is None:
            print("Error: Failed to create DSP instance from bitcode", file=sys.stderr)
            return 1

        dsp.init(44100)

        print(f"Loaded bitcode: {args.input}")
        print(f"  Name: {factory.get_name()}")
        print(f"  SHA Key: {factory.get_sha_key()}")
        print(f"  Inputs: {dsp.get_numinputs()}, Outputs: {dsp.get_numoutputs()}")
        return 0

    else:
        print(f"Error: Unknown mode '{args.mode}'. Use 'save' or 'load'.", file=sys.stderr)
        return 1


def cmd_json(args):
    """Export DSP metadata as JSON."""
    imports = get_cyfaust_imports()
    import re

    if not os.path.exists(args.input):
        print(f"Error: File not found: {args.input}", file=sys.stderr)
        return 1

    factory = imports['create_dsp_factory_from_file'](args.input)
    if factory is None:
        print(f"Error: Failed to create DSP factory from: {args.input}", file=sys.stderr)
        return 1

    dsp = factory.create_dsp_instance()
    if dsp is None:
        print("Error: Failed to create DSP instance", file=sys.stderr)
        return 1

    dsp.init(44100)

    # Build JSON structure
    data = {
        "file": args.input,
        "name": factory.get_name(),
        "sha_key": factory.get_sha_key(),
        "compile_options": factory.get_compile_options(),
        "inputs": dsp.get_numinputs(),
        "outputs": dsp.get_numoutputs(),
        "sample_rate": dsp.get_samplerate(),
    }

    # Add metadata
    try:
        meta = dsp.metadata()
        if meta:
            data["metadata"] = meta
    except Exception:
        data["metadata"] = {}

    # Parse parameters from expanded code
    result = imports['expand_dsp_from_file'](args.input)
    if result:
        sha_key, expanded_code = result

        ui_patterns = [
            (r'vslider\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^)]+)\)', 'vslider'),
            (r'hslider\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^)]+)\)', 'hslider'),
            (r'nentry\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^)]+)\)', 'nentry'),
            (r'button\s*\(\s*"([^"]+)"\s*\)', 'button'),
            (r'checkbox\s*\(\s*"([^"]+)"\s*\)', 'checkbox'),
            (r'vbargraph\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*([^)]+)\)', 'vbargraph'),
            (r'hbargraph\s*\(\s*"([^"]+)"\s*,\s*([^,]+)\s*,\s*([^)]+)\)', 'hbargraph'),
        ]

        params = []
        for pattern, ui_type in ui_patterns:
            for match in re.finditer(pattern, expanded_code):
                if ui_type in ['vslider', 'hslider', 'nentry']:
                    params.append({
                        'type': ui_type,
                        'label': match.group(1),
                        'init': match.group(2).strip(),
                        'min': match.group(3).strip(),
                        'max': match.group(4).strip(),
                        'step': match.group(5).strip(),
                    })
                elif ui_type in ['button', 'checkbox']:
                    params.append({
                        'type': ui_type,
                        'label': match.group(1),
                    })
                elif ui_type in ['vbargraph', 'hbargraph']:
                    params.append({
                        'type': ui_type,
                        'label': match.group(1),
                        'min': match.group(2).strip(),
                        'max': match.group(3).strip(),
                    })

        if params:
            data["parameters"] = params

    # Add libraries
    libs = factory.get_library_list()
    if libs:
        data["libraries"] = list(libs)

    # Add warnings
    warnings = factory.get_warning_messages()
    if warnings:
        data["warnings"] = list(warnings)

    # Output
    indent = 2 if args.pretty else None
    json_str = json_module.dumps(data, indent=indent)

    if args.output:
        with open(args.output, 'w') as f:
            f.write(json_str)
        print(f"JSON written to: {args.output}")
    else:
        print(json_str)

    return 0


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        prog='cyfaust',
        description='cyfaust command-line interface for Faust DSP processing',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  cyfaust version
  cyfaust compile noise.dsp -b cpp -o noise.cpp
  cyfaust play osc.dsp -d 5
  cyfaust params synth.dsp
  cyfaust validate filter.dsp
  cyfaust bitcode save synth.dsp -o synth.fbc
  cyfaust json instrument.dsp --pretty
'''
    )

    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # version command
    version_parser = subparsers.add_parser('version', help='Show version information')
    version_parser.set_defaults(func=cmd_version)

    # compile command
    compile_parser = subparsers.add_parser(
        'compile',
        help='Compile Faust DSP to target backend'
    )
    compile_parser.add_argument('input', help='Input Faust DSP file')
    compile_parser.add_argument(
        '-b', '--backend',
        default='cpp',
        choices=['cpp', 'c++', 'c', 'rust', 'codebox'],
        help='Target backend (default: cpp)'
    )
    compile_parser.add_argument(
        '-o', '--output',
        help='Output file (default: stdout)'
    )
    compile_parser.set_defaults(func=cmd_compile)

    # diagram command
    diagram_parser = subparsers.add_parser(
        'diagram',
        help='Generate SVG block diagram'
    )
    diagram_parser.add_argument('input', help='Input Faust DSP file')
    diagram_parser.add_argument(
        '-o', '--output',
        help='Output directory for SVG files'
    )
    diagram_parser.set_defaults(func=cmd_diagram)

    # expand command
    expand_parser = subparsers.add_parser(
        'expand',
        help='Expand Faust DSP to self-contained code'
    )
    expand_parser.add_argument('input', help='Input Faust DSP file')
    expand_parser.add_argument(
        '-o', '--output',
        help='Output file (default: stdout)'
    )
    expand_parser.add_argument(
        '--sha-only',
        action='store_true',
        help='Only output the SHA1 key'
    )
    expand_parser.set_defaults(func=cmd_expand)

    # info command
    info_parser = subparsers.add_parser(
        'info',
        help='Show DSP information'
    )
    info_parser.add_argument('input', help='Input Faust DSP file')
    info_parser.set_defaults(func=cmd_info)

    # play command
    play_parser = subparsers.add_parser(
        'play',
        help='Play a Faust DSP file with RtAudio'
    )
    play_parser.add_argument('input', help='Input Faust DSP file')
    play_parser.add_argument(
        '-d', '--duration',
        type=float,
        help='Duration in seconds (default: play until Ctrl+C)'
    )
    play_parser.add_argument(
        '-r', '--samplerate',
        type=int,
        default=44100,
        help='Sample rate in Hz (default: 44100)'
    )
    play_parser.add_argument(
        '-b', '--buffersize',
        type=int,
        default=512,
        help='Buffer size in samples (default: 512)'
    )
    play_parser.set_defaults(func=cmd_play)

    # params command
    params_parser = subparsers.add_parser(
        'params',
        help='List all DSP parameters'
    )
    params_parser.add_argument('input', help='Input Faust DSP file')
    params_parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Show additional parameter details'
    )
    params_parser.set_defaults(func=cmd_params)

    # validate command
    validate_parser = subparsers.add_parser(
        'validate',
        help='Check a Faust DSP file for errors'
    )
    validate_parser.add_argument('input', help='Input Faust DSP file')
    validate_parser.add_argument(
        '--strict',
        action='store_true',
        help='Treat warnings as errors'
    )
    validate_parser.set_defaults(func=cmd_validate)

    # bitcode command
    bitcode_parser = subparsers.add_parser(
        'bitcode',
        help='Save/load DSP factory as bitcode'
    )
    bitcode_parser.add_argument(
        'mode',
        choices=['save', 'load'],
        help='Operation mode: save DSP to bitcode, or load and display info'
    )
    bitcode_parser.add_argument('input', help='Input file (DSP for save, bitcode for load)')
    bitcode_parser.add_argument(
        '-o', '--output',
        help='Output bitcode file (for save mode, default: <name>.fbc)'
    )
    bitcode_parser.set_defaults(func=cmd_bitcode)

    # json command
    json_parser = subparsers.add_parser(
        'json',
        help='Export DSP metadata as JSON'
    )
    json_parser.add_argument('input', help='Input Faust DSP file')
    json_parser.add_argument(
        '-o', '--output',
        help='Output JSON file (default: stdout)'
    )
    json_parser.add_argument(
        '-p', '--pretty',
        action='store_true',
        help='Pretty-print JSON output'
    )
    json_parser.set_defaults(func=cmd_json)

    # Parse arguments
    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return 0

    return args.func(args)


if __name__ == '__main__':
    sys.exit(main())
