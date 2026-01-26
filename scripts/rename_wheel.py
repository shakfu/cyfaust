#!/usr/bin/env python3
"""Rename a wheel package (including internal metadata).

This script properly renames a wheel by:
1. Extracting the wheel contents
2. Renaming the .dist-info directory
3. Updating METADATA and RECORD files
4. Repacking with the new name

Usage:
    python rename_wheel.py <wheel_path> <new_name>

Example:
    python rename_wheel.py dist/cyfaust-0.1.1-cp313-cp313-linux_x86_64.whl cyfaust-llvm
"""

import argparse
import hashlib
import os
import re
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path


def get_wheel_info(wheel_path: Path) -> dict:
    """Extract wheel info from filename."""
    # Pattern: {distribution}-{version}(-{build tag})?-{python tag}-{abi tag}-{platform tag}.whl
    name = wheel_path.stem
    parts = name.split('-')

    if len(parts) >= 5:
        return {
            'distribution': parts[0],
            'version': parts[1],
            'python': parts[-3],
            'abi': parts[-2],
            'platform': parts[-1],
            'build': '-'.join(parts[2:-3]) if len(parts) > 5 else None
        }
    raise ValueError(f"Invalid wheel filename: {wheel_path}")


def normalize_name(name: str) -> str:
    """Normalize package name according to PEP 503."""
    return re.sub(r'[-_.]+', '_', name).lower()


def hash_file(path: Path) -> str:
    """Calculate SHA256 hash of a file in base64url format."""
    sha256 = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            sha256.update(chunk)
    import base64
    return 'sha256=' + base64.urlsafe_b64encode(sha256.digest()).rstrip(b'=').decode('ascii')


def rename_wheel(wheel_path: Path, new_name: str, output_dir: Path = None) -> Path:
    """Rename a wheel package including internal metadata."""

    wheel_path = Path(wheel_path)
    if not wheel_path.exists():
        raise FileNotFoundError(f"Wheel not found: {wheel_path}")

    info = get_wheel_info(wheel_path)
    old_name = info['distribution']
    old_name_normalized = normalize_name(old_name)
    new_name_normalized = normalize_name(new_name)

    if output_dir is None:
        output_dir = wheel_path.parent
    output_dir = Path(output_dir)

    # Create new wheel filename
    new_wheel_name = wheel_path.name.replace(old_name, new_name_normalized)
    new_wheel_path = output_dir / new_wheel_name

    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        extract_dir = tmpdir / 'wheel'

        # Extract wheel
        with zipfile.ZipFile(wheel_path, 'r') as zf:
            zf.extractall(extract_dir)

        # Find and rename .dist-info directory
        old_dist_info = None
        for item in extract_dir.iterdir():
            if item.name.endswith('.dist-info'):
                old_dist_info = item
                break

        if old_dist_info is None:
            raise ValueError("No .dist-info directory found in wheel")

        new_dist_info_name = old_dist_info.name.replace(old_name, new_name_normalized)
        new_dist_info = extract_dir / new_dist_info_name
        old_dist_info.rename(new_dist_info)

        # Update METADATA
        metadata_path = new_dist_info / 'METADATA'
        if metadata_path.exists():
            content = metadata_path.read_text()
            content = re.sub(
                r'^Name:\s*.*$',
                f'Name: {new_name}',
                content,
                flags=re.MULTILINE
            )
            metadata_path.write_text(content)

        # Update top_level.txt if exists
        top_level_path = new_dist_info / 'top_level.txt'
        # Keep as 'cyfaust' since the import name doesn't change

        # Regenerate RECORD
        record_path = new_dist_info / 'RECORD'
        record_lines = []

        for root, dirs, files in os.walk(extract_dir):
            for filename in files:
                filepath = Path(root) / filename
                relpath = filepath.relative_to(extract_dir)

                if relpath == record_path.relative_to(extract_dir):
                    # RECORD itself has no hash
                    record_lines.append(f"{relpath},,")
                else:
                    file_hash = hash_file(filepath)
                    file_size = filepath.stat().st_size
                    record_lines.append(f"{relpath},{file_hash},{file_size}")

        record_path.write_text('\n'.join(sorted(record_lines)) + '\n')

        # Repack wheel
        with zipfile.ZipFile(new_wheel_path, 'w', zipfile.ZIP_DEFLATED) as zf:
            for root, dirs, files in os.walk(extract_dir):
                for filename in files:
                    filepath = Path(root) / filename
                    arcname = filepath.relative_to(extract_dir)
                    zf.write(filepath, arcname)

    return new_wheel_path


def main():
    parser = argparse.ArgumentParser(description='Rename a wheel package')
    parser.add_argument('wheel', help='Path to the wheel file')
    parser.add_argument('new_name', help='New package name (e.g., cyfaust-llvm)')
    parser.add_argument('-o', '--output', help='Output directory (default: same as input)')
    parser.add_argument('-d', '--delete', action='store_true', help='Delete original wheel after renaming')

    args = parser.parse_args()

    wheel_path = Path(args.wheel)
    output_dir = Path(args.output) if args.output else None

    try:
        new_wheel = rename_wheel(wheel_path, args.new_name, output_dir)
        print(f"Created: {new_wheel}")

        if args.delete and new_wheel != wheel_path:
            wheel_path.unlink()
            print(f"Deleted: {wheel_path}")

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
