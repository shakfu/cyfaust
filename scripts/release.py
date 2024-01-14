#!/usr/bin/env python3
"""

CREDITS:
	wheel parsing code is derived from
	from https://github.com/wheelodex/wheel-filename
	Copyright (c) 2020-2022 John Thorvald Wodder II

This code uses dataclasses instead of the original which uses NamedTuple
"""
import os
import os.path
import re
import shutil
from dataclasses import dataclass
from pathlib import Path

PYTHON_TAG_RGX = r"[\w\d]+"
ABI_TAG_RGX = r"[\w\d]+"
PLATFORM_TAG_RGX = r"[\w\d]+"

WHEEL_FILENAME_PATTERN = re.compile(
    r"(?P<project>[A-Za-z0-9](?:[A-Za-z0-9._]*[A-Za-z0-9])?)"
    r"-(?P<version>[A-Za-z0-9_.!+]+)"
    r"(?:-(?P<build>[0-9][\w\d.]*))?"
    r"-(?P<python_tags>{0}(?:\.{0})*)"
    r"-(?P<abi_tags>{1}(?:\.{1})*)"
    r"-(?P<platform_tags>{2}(?:\.{2})*)"
    r"\.[Ww][Hh][Ll]".format(PYTHON_TAG_RGX, ABI_TAG_RGX, PLATFORM_TAG_RGX)
)

@dataclass
class WheelFilename:
    project: str
    version: str
    build: str | None
    python_tags: list[str]
    abi_tags: list[str]
    platform_tags: list[str]

    def __str__(self) -> str:
        if self.build:
            fmt = "{0.project}-{0.version}-{0.build}-{1}-{2}-{3}.whl"
        else:
            fmt = "{0.project}-{0.version}-{1}-{2}-{3}.whl"
        return fmt.format(
            self,
            ".".join(self.python_tags),
            ".".join(self.abi_tags),
            ".".join(self.platform_tags),
        )

def parse_wheel_filename(filename: str) -> WheelFilename:
    """Parse a wheel filename into its components
    """
    basename = os.path.basename(filename)
    m = WHEEL_FILENAME_PATTERN.fullmatch(basename)
    if not m:
        raise TypeError("incorrect wheel name")
    return WheelFilename(
        project=m.group("project"),
        version=m.group("version"),
        build=m.group("build"),
        python_tags=m.group("python_tags").split("."),
        abi_tags=m.group("abi_tags").split("."),
        platform_tags=m.group("platform_tags").split("."),
    )

cmd = os.system

CWD = Path.cwd()
DIST = CWD / "dist"
WHEELS =  CWD / "wheels"
WHEELS.mkdir(exist_ok=True)


print("building dynamic build wheel")
cmd("make clean")
cmd("make wheel")
for wheel in DIST.glob("*.whl"):
	shutil.move(wheel, WHEELS)


print("building static build wheel")
cmd("make clean")
cmd("make wheel STATIC=1")
for wheel in DIST.glob("*.whl"):
	name = wheel.name
	w = parse_wheel_filename(name)
	w.project = "cyfaust-static"
	new_name = str(w)
	os.rename(wheel, new_name)
	shutil.move(new_name, WHEELS)



