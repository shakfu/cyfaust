#!/usr/bin/env python3
"""release.py: cross-platform wheel building ops

This script manages wheel related build and testing. 

It does the following:

- builds a dynamic wheel then fixes it with either `delocate` or `auditwheel`
- builds a static wheel, renames wheel to give `-static` suffix
- collects fixed wheels in a `wheels` folder
- cleans up `build` and `dist` folders
- tests the wheels in a virtualenv

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
    def __init__(self, src_folder='dist', dst_folder='wheels', native_arch=True):
        self.cwd = Path.cwd()
        self.src_folder = self.cwd / src_folder
        self.dst_folder = self.cwd / dst_folder
        self.build_folder = self.cwd / 'build'
        self.native_arch = native_arch
        self.arch = self.get("uname -m")

    def cmd(self, shellcmd, cwd='.'):
        subprocess.call(shellcmd, shell=True, cwd=str(cwd))


    def get(self, shellcmd, cwd='.', shell=False) -> str:
        """get output of shellcmd"""
        if not shell:
            shellcmd = shellcmd.split() 
        return subprocess.check_output(
            shellcmd, encoding='utf8', shell=shell, cwd=str(cwd)).strip()

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

    def reset(self):
        self.clean()
        if self.dst_folder.exists():
            shutil.rmtree(self.dst_folder)

    def check(self):
        assert self.dst_folder.glob("*.whl"), "no 'fixed' wheels created"

    def makedirs(self):
        if not self.dst_folder.exists():
            self.dst_folder.mkdir()

    # def build_wheel(self, static=False):
    #     arch = ""
    #     if self.native_arch:
    #         arch = f"ARCHFLAGS='-arch {self.arch}'"
    #     if static:
    #         self.cmd(f"STATIC=1 {arch} python3 setup.py bdist_wheel")            
    #     else:
    #         self.cmd(f"{arch} python3 setup.py bdist_wheel")

    def build_wheel(self, static=False):
        if static:
            self.cmd(f"STATIC=1 python3 setup.py bdist_wheel")            
        else:
            self.cmd(f"python3 setup.py bdist_wheel")

    def test_wheels(self):
        venv = self.dst_folder / 'venv'
        if venv.exists():
            shutil.rmtree(venv)

        for wheel in self.dst_folder.glob("*.whl"):
            self.cmd("virtualenv venv", cwd=self.dst_folder)
            vpy = venv / 'bin' / 'python'
            vpip = venv / 'bin' / 'pip'
            self.cmd(f"{vpip} install {wheel}")
            if "static" in str(wheel):
                target = "static"
                imported='cyfaust'
                print("static variant test")
            else:
                target = "dynamic"
                imported='interp'
                print("dynamic variant test")
            val = self.get(f"{vpy} -c 'from cyfaust import {imported};print(len(dir({imported})))'",
                shell=True, cwd=self.dst_folder
            )
            print(f"cyfaust.{imported} # objects: {val}")        
            assert val, f"cyfaust {target} wheel test: FAILED" 
            print(f"cyfaust {target} wheel test: OK")
            if venv.exists():
                shutil.rmtree(venv)


    def build_dynamic_wheel(self):
        print("building dynamic build wheel")
        self.clean()
        self.makedirs()
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
        self.makedirs()
        self.build_wheel(static=True)
        for wheel in self.src_folder.glob("*.whl"):
            w = WheelFilename.from_path(wheel)
            w.project = "cyfaust-static"
            renamed_wheel = str(w)
            os.rename(wheel, renamed_wheel)
            shutil.move(renamed_wheel, self.dst_folder)

    def build(self):
        if self.is_static():
            self.build_static_wheel()
        else:
            self.build_dynamic_wheel()
        self.check()
        self.clean()


    def release(self):
        self.reset()
        self.build_dynamic_wheel()
        self.build_static_wheel()
        self.check()
        self.clean()


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='manage cyfaust project wheels')

    def opt(long_opt, short_opt, desc):
        return parser.add_argument(long_opt, short_opt, action='store_true', help=desc)

    opt("--release", "-r", "build and release all wheels")
    opt("--build", "-b", "build single wheel based on STATIC env var")
    opt("--build-dynamic", "-d", "build dynamic variant")
    opt("--build-static", "-s", "build static variant")
    opt("--test", "-t", "test built wheels")

    args = parser.parse_args()
    if args.release:
        b = WheelBuilder()
        b.release()

    elif args.build:
        b = WheelBuilder()
        b.build()

    elif args.build_dynamic:
        b = WheelBuilder()
        b.build_dynamic_wheel()
        b.check()
        b.clean()

    elif args.build_static:
        b = WheelBuilder()
        b.build_static_wheel()
        b.check()
        b.clean()

    if args.test:
        b = WheelBuilder()
        b.test_wheels()

