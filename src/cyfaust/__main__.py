#!/usr/bin/env python3
"""cyfaust command-line interface.

Usage:
    python -m cyfaust <command> [options]

Commands:
    version     Show cyfaust and libfaust version information
    compile     Compile Faust DSP to various backends (cpp, c, rust, codebox)
    diagram     Generate SVG block diagram from Faust DSP
    expand      Expand Faust DSP to self-contained code
    info        Show DSP information (metadata, inputs, outputs)

Examples:
    python -m cyfaust version
    python -m cyfaust compile examples/noise.dsp -o noise.cpp
    python -m cyfaust diagram examples/noise.dsp -o noise.svg
    python -m cyfaust info examples/noise.dsp
"""

import argparse
import sys
import os
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


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        prog='python -m cyfaust',
        description='cyfaust command-line interface for Faust DSP processing',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python -m cyfaust version
  python -m cyfaust compile noise.dsp -b cpp -o noise.cpp
  python -m cyfaust diagram synth.dsp
  python -m cyfaust expand filter.dsp -o filter_expanded.dsp
  python -m cyfaust info instrument.dsp
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

    # Parse arguments
    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        return 0

    return args.func(args)


if __name__ == '__main__':
    sys.exit(main())
