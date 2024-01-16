#!/usr/bin/env python3
"""release.py: cross-platform wheel building ops

This script does the following:

- builds a dynamic wheel then fixes it with either `delocate` or `auditwheel`
- builds a static wheel, renames wheel to give `-static` suffix
- collects fixed wheels in a `wheels` folder
- cleans up `build` and `dist` folders

"""
import os
import os.path
import re
import shutil
from dataclasses import dataclass
import platform
from pathlib import Path
import subprocess

PLATFORM = platform.system()

@dataclass
class WheelFilename:
    """Wheel filename dataclass with parser.

    credits:
        wheel parsing code is derived from
        from https://github.com/wheelodex/wheel-filename
        Copyright (c) 2020-2022 John Thorvald Wodder II

    This version uses dataclasses instead of NamedTuples in the original
    and packages the parsing function and the regex patterns in the 
    class itself.
    """

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

    @classmethod
    def from_path(cls, path: str | Path) -> 'WheelFilename':
        """Parse a wheel filename into its components
        """
        basename = Path(path).name
        # basename = os.path.basename(filename)
        m = cls.WHEEL_FILENAME_PATTERN.fullmatch(basename)
        if not m:
            raise TypeError("incorrect wheel name")
        return cls(
            project=m.group("project"),
            version=m.group("version"),
            build=m.group("build"),
            python_tags=m.group("python_tags").split("."),
            abi_tags=m.group("abi_tags").split("."),
            platform_tags=m.group("platform_tags").split("."),
        )


class WheelBuilder:
    def __init__(self, src_folder='dist', dst_folder='wheels'):
        self.cwd = Path.cwd()
        self.src_folder = self.cwd / src_folder
        self.dst_folder = self.cwd / dst_folder
        self.build_folder = self.cwd / 'build'
        self.arch = self.get("uname -m")

    def cmd(self, shellcmd):
        os.system(shellcmd)

    def get(self, shellcmd) -> str:
        """get output of shellcmd"""
        return subprocess.check_output(
            shellcmd.split(), encoding='utf8').strip()

    def getenv(self, key):
        """convert '0','1' env values to bool {True, False}"""
        return bool(int(os.getenv(key, False)))
 
    def is_static(self):
        return self.getenv('STATIC')

    def clean(self):
        if self.build_folder.exists():
            shutil.rmtree(self.build_folder)
        if self.src_folder.exists():
            shutil.rmtree(self.src_folder)

    def build_wheel(self, static=False):
        if static:
            self.cmd("STATIC=1 python3 setup.py bdist_wheel")            
        else:
            self.cmd("python3 setup.py bdist_wheel")

    def build_dynamic_wheel(self):
        print("building dynamic build wheel")
        self.clean()
        self.build_wheel()
        src = self.src_folder
        dst = self.dst_folder
        arch = self.arch
        if PLATFORM == "Darwin":
            self.cmd(f"delocate-wheel -v --wheel-dir {dst} {src}/*.whl")
        elif PLATFORM == "Linux":
            self.cmd(f"auditwheel repair --plat linux_{arch} --wheel-dir {dst} {src}/*.whl")
        else:
            raise SystemExit("Windows platform not supported")

    def build_static_wheel(self):
        print("building static build wheel")
        self.clean()
        self.build_wheel(static=True)
        for wheel in self.src_folder.glob("*.whl"):
            w = WheelFilename.from_path(wheel)
            w.project = "cyfaust-static"
            renamed_wheel = str(w)
            os.rename(wheel, renamed_wheel)
            shutil.move(renamed_wheel, self.dst_folder)

    def build(self):
        self.build_dynamic_wheel()
        self.build_static_wheel()
        assert self.dst_folder.glob("*.whl"), "no fixed wheels created"
        self.clean()


if __name__ == '__main__':
    b = WheelBuilder()
    b.build()
