#!/usr/bin/env python3

"""manage.py: cross-platform cyfaust build manager.

It only uses python stdlib modules to do the following:

- General Shell ops
- Dependency download, build, install
- Module compilation
- Wheel building
- Alternative frontend to Makefile

models:
    CustomFormatter(logging.Formatter)
    MetaCommander(type)
    Project
    ShellCmd
        DependencyMgr
        Builder
            FaustBuilder
            SndfileBuilder
            SamplerateBuilder
        Application
    WheelFile(dataclass)
    WheelBuilder

It has an argparse-based cli api:

usage: manage.py [-h] [-v]  ...

    options:
    -h, --help     show this help message and exit
    -v, --version  show program's version number and exit

    subcommands:
                    additional help
        build        build cyfaust
        clean        clean project detritus
        setup        setup faust
        test         test cyfaust modules
        wheel        build cyfaust wheel

"""
import argparse
import logging
import os
import platform
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Union, Optional, List


PYTHON = sys.executable
PLATFORM = platform.system()
ARCH = platform.machine()
PY_VER_MINOR = sys.version_info.minor

DEBUG = True


# ----------------------------------------------------------------------------
# type aliases

Pathlike = Union[str, Path]


# ----------------------------------------------------------------------------
# setup_cyfaust


class CustomFormatter(logging.Formatter):
    """custom logging formatting class"""

    white = "\x1b[97;20m"
    grey = "\x1b[38;20m"
    green = "\x1b[32;20m"
    cyan = "\x1b[36;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    # fmt = "%(asctime)s - {}%(levelname)-8s{} - %(name)s.%(funcName)s - %(message)s"
    fmt = "%(asctime)s - {}%(levelname)s{} - %(name)s.%(funcName)s - %(message)s"

    FORMATS = {
        logging.DEBUG: fmt.format(grey, reset),
        logging.INFO: fmt.format(green, reset),
        logging.WARNING: fmt.format(yellow, reset),
        logging.ERROR: fmt.format(red, reset),
        logging.CRITICAL: fmt.format(bold_red, reset),
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt, datefmt="%H:%M:%S")
        return formatter.format(record)


handler = logging.StreamHandler()
handler.setFormatter(CustomFormatter())
logging.basicConfig(level=logging.DEBUG if DEBUG else logging.INFO, handlers=[handler])


class ShellCmd:
    """Provides platform agnostic file/folder handling."""

    log: logging.Logger

    def cmd(self, shellcmd: str, cwd: Pathlike = "."):
        """Run shell command within working directory"""
        self.log.info(shellcmd)
        subprocess.call(shellcmd, shell=True, cwd=str(cwd))

    def git_clone(self, url: str, recurse: bool = False, branch: Optional[str] = None):
        """git clone a repository source tree from a url"""
        _cmds = ["git clone --depth 1"]
        if branch:
            _cmds.append(f"--branch {branch}")
        if recurse:
            _cmds.append("--recurse-submodules --shallow-submodules")
        _cmds.append(url)
        self.cmd(" ".join(_cmds))

    def getenv(self, key: str, default: bool = False) -> bool:
        """convert '0','1' env values to bool {True, False}"""
        self.log.info("checking env variable: %s", key)
        return bool(int(os.getenv(key, default)))

    def chdir(self, path: Pathlike):
        """Change current workding directory to path"""
        self.log.info("changing working dir to: %s", path)
        os.chdir(path)

    def chmod(self, path: Pathlike, perm=0o777):
        """Change permission of file"""
        self.log.info("change permission of %s to %s", path, perm)
        os.chmod(path, perm)

    def get(self, shellcmd: str) -> str:
        """get output of shellcmd"""
        self.log.info("getting output of '%s'", shellcmd)
        return subprocess.check_output(shellcmd.split(), encoding="utf8").strip()

    def makedirs(self, path: Pathlike, mode: int = 511, exist_ok: bool = True):
        """Recursive directory creation function"""
        self.log.info("making directory: %s", path)
        os.makedirs(path, mode, exist_ok)

    def move(self, src: Pathlike, dst: Pathlike):
        """Move from src path to dst path."""
        self.log.info("move path %s to %s", src, dst)
        shutil.move(src, dst)

    def copy(self, src: Pathlike, dst: Pathlike):
        """copy file or folders -- tries to be behave like `cp -rf`"""
        self.log.info("copy %s to %s", src, dst)
        src, dst = Path(src), Path(dst)
        if src.is_dir():
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)

    def remove(self, path: Pathlike, silent:bool = False):
        """Remove file or folder."""
        path = Path(path)
        if path.is_dir():
            if not silent:
                self.log.info("remove folder: %s", path)
            shutil.rmtree(path, ignore_errors=not DEBUG)
        else:
            if not silent:
                self.log.info("remove file: %s", path)
            try:
                path.unlink()
            except FileNotFoundError:
                if not silent:
                    self.log.warning("file not found: %s", path)

    def pip_install(
        self,
        *pkgs,
        reqs: Optional[str] = None,
        upgrade: bool = False,
        pip: Optional[str] = None,
    ):
        """Install python packages using pip"""
        _cmds = []
        if pip:
            _cmds.append(pip)
        else:
            _cmds.append("pip3")
        _cmds.append("install")
        if reqs:
            _cmds.append(f"-r {reqs}")
        else:
            if upgrade:
                _cmds.append("--upgrade")
            _cmds.extend(pkgs)
        self.cmd(" ".join(_cmds))

    def apt_install(self, *pkgs, update: bool = False):
        """install debian packages using apt"""
        _cmds = []
        _cmds.append("sudo apt install")
        if update:
            _cmds.append("--upgrade")
        _cmds.extend(pkgs)
        self.cmd(" ".join(_cmds))

    def brew_install(self, *pkgs, update: bool = False):
        """install using homebrew"""
        _pkgs = " ".join(pkgs)
        if update:
            self.cmd("brew update")
        self.cmd(f"brew install {_pkgs}")

    def cmake_config(self, src_dir: Pathlike, build_dir: Pathlike, *scripts, **options):
        """activate cmake configuration / generation stage"""
        _cmds = [f"cmake -S {src_dir} -B {build_dir}"]
        if scripts:
            _cmds.append(" ".join(f"-C {path}" for path in scripts))
        if options:
            _cmds.append(" ".join(f"-D{k}={v}" for k, v in options.items()))
        self.cmd(" ".join(_cmds))

    def cmake_build(self, build_dir: Pathlike, release: bool = False):
        """activate cmake build stage"""
        _cmd = f"cmake --build {build_dir}"
        if release:
            _cmd += " --config Release"
        self.cmd(_cmd)

    def cmake_install(self, build_dir: Pathlike, prefix: Optional[str] = None):
        """activate cmake install stage"""
        _cmds = ["cmake --install", str(build_dir)]
        if prefix:
            _cmds.append(f"--prefix {prefix}")
        self.cmd(" ".join(_cmds))

    def install_name_tool(self, src: Pathlike, dst: Pathlike, mode: str = "id"):
        """change dynamic shared library install names"""
        _cmd = f"install_name_tool -{mode} {src} {dst}"
        self.log.info(_cmd)
        self.cmd(_cmd)


class DependencyMgr(ShellCmd):
    """Manages cyfaust pip and system dependencies.

    
    platforms: ["Darwin", "Linux (debian)", Windowss]
    """
    def __init__(self):
        self.log = logging.getLogger(self.__class__.__name__)

    def install_py_pkgs(self):
        """install python packages"""
        self.pip_install(reqs="requirements.txt")

    def install_sys_pkgs(self):
        """install os packages"""
        sys_pkgs = []

        if PLATFORM == "Darwin":
            sys_pkgs.extend(["python", "cmake"])

            print("install macos system dependencies")
            self.brew_install(*sys_pkgs)

        elif PLATFORM == "Linux":
            sys_pkgs.append("patchelf")

            ALSA = self.getenv("ALSA", default=True)
            PULSE = self.getenv("PULSE")
            JACK = self.getenv("JACK")

            if ALSA:
                sys_pkgs.append("libasound2-dev")

            if PULSE:
                sys_pkgs.append("libpulse-dev")

            if JACK:
                sys_pkgs.append("libjack-jackd2-dev")

            print("install linux system dependencies")
            self.apt_install(*sys_pkgs)

        elif PLATFORM == "Windows":
            # this is a placeholder
            pass

    def process(self):
        """run all relevant processes"""
        self.install_py_pkgs()
        self.install_sys_pkgs()


class Project:
    """Utility class to hold project directory structure
    """
    def __init__(self):
        self.cwd = Path.cwd()
        self.bin = self.cwd / "bin"
        self.include = self.cwd / "include"
        self.lib = self.cwd / "lib"
        self.lib_static = self.lib / "static"
        self.share = self.cwd / "share"
        self.scripts = self.cwd / "scripts"
        self.patch = self.scripts / "patch"
        self.build = self.cwd / "build"
        self.tests = self.cwd / "tests"
        self.downloads = self.build / "downloads"


class Builder(ShellCmd):
    """Abstract builder class with additional methods common to subclasses.
    """
    LIBNAME = "libname"
    DYLIB_SUFFIX_OSX = ".0.dylib"
    DYLIB_SUFFIX_LIN = ".so.0"
    DYLIB_SUFFIX_WIN = ".dll"

    def __init__(self, version: str = "0.0.1"):
        self.version = version
        self.project = Project()

    def setup_project(self):
        folders = [
            self.project.build,
            self.project.downloads,
            self.project.bin,
            self.project.share,
            self.project.lib_static,
        ]
        for folder in folders:
            if not folder.exists():
                self.makedirs(folder)

    @property
    def staticlib_name(self):
        suffix = ".a"
        if PLATFORM == "Windows":
            suffix = ".lib"
        return f"{self.LIBNAME}{suffix}"

    @property
    def dylib_name(self):
        if PLATFORM == "Darwin":
            return f"{self.LIBNAME}{self.DYLIB_SUFFIX_OSX}"
        if PLATFORM == "Linux":
            return f"{self.LIBNAME}{self.DYLIB_SUFFIX_LIN}"
        if PLATFORM == "Windows":
            return f"{self.LIBNAME}{self.DYLIB_SUFFIX_WIN}"
        raise SystemExit("platform not supported")

    @property
    def dylib_linkname(self):
        if PLATFORM == "Darwin":
            return f"{self.LIBNAME}.dylib"
        if PLATFORM == "Linux":
            return f"{self.LIBNAME}.so"
        raise SystemExit("platform not supported")

    @property
    def dylib(self):
        return self.project.lib / self.dylib_name

    @property
    def dylib_link(self):
        return self.project.lib / self.dylib_linkname

    @property
    def staticlib(self):
        return self.project.lib_static / self.staticlib_name


class FaustBuilder(Builder):
    """Manages all aspects of the interpreter-centric faust build for cyfaust,
    """
    LIBNAME = "libfaust"
    DYLIB_SUFFIX_OSX = ".2.dylib"
    DYLIB_SUFFIX_LIN = ".so.2"
    DYLIB_SUFFIX_WIN = ".dll"

    def __init__(self, version: str = "2.69.3"):
        super().__init__(version)
        self.src = self.project.downloads / "faust"
        self.sourcedir = self.src / "build"
        self.faustdir = self.sourcedir / "faustdir"
        self.backends = self.sourcedir / "backends"
        self.targets = self.sourcedir / "targets"
        self.prefix = self.project.build / "prefix"
        self.log = logging.getLogger(self.__class__.__name__)

    def get_faust(self):
        self.log.info("update from faust main repo")
        self.setup_project()
        self.makedirs(self.project.downloads)
        self.chdir(self.project.downloads)
        self.git_clone("https://github.com/grame-cncm/faust.git", branch=self.version)

    def build_faust(self):
        self.makedirs(self.faustdir)

        if PLATFORM in ["Linux", "Darwin"]:
            self.copy(self.project.patch / "faust.mk", self.src / "Makefile")

            self.copy(
                self.project.patch / "interp_plus_backend.cmake",
                self.backends / "interp_plus.cmake",
            )
            self.copy(
                self.project.patch / "interp_plus_target.cmake",
                self.targets / "interp_plus.cmake",
            )

            self.chdir(self.src)
            self.cmd("make interp")
            self.cmd(f"PREFIX={self.prefix} make install")

        elif PLATFORM == "Windows":
            self.copy(
                self.project.patch / "interp_plus_backend.cmake",
                self.backends / "interp.cmake",
            )
            self.copy(
                self.project.patch / "interp_plus_target.cmake",
                self.targets / "interp.cmake",
            )
            self.cmake_config(
                self.sourcedir,
                self.faustdir,
                # scripts
                self.backends / "interp.cmake",
                self.targets / "interp.cmake",
                # options
                CMAKE_BUILD_TYPE="Release",
                WORKLET="OFF",
                INCLUDE_LLVM="OFF",
                USE_LLVM_CONFIG="OFF",
                LLVM_PACKAGE_VERSION="",
                LLVM_LIBS="",
                LLVM_LIB_DIR="",
                LLVM_INCLUDE_DIRS="",
                LLVM_DEFINITIONS="",
                LLVM_LD_FLAGS="",
                LIBSDIR="lib",
                BUILD_HTTP_STATIC="OFF",
            )
            self.cmake_build(build_dir=self.faustdir, release=True)
            # install doesn't work on windows
            # self.cmake_install(build_dir=self.faustdir, prefix=self.prefix)

        else:
            raise SystemExit("platform not supported")

    def remove_current(self):
        self.log.info("remove current faust libs")

        if PLATFORM == "Windows":
            self.remove(self.project.bin / "faust.exe")
            dylib = self.project.lib / "faust.dll"
            if dylib.exists():
                self.remove(dylib)
            if self.staticlib.exists():
                self.remove(self.staticlib)
        else:
            for e in ["faust", "faust-config", "faustpath"]:
                self.remove(self.project.bin / e)
            self.remove(self.project.include / "faust")
            if self.dylib.exists():
                self.remove(self.dylib)
            if self.dylib_link.exists():
                self.remove(self.dylib_link)
            if self.staticlib.exists():
                self.remove(self.staticlib)
            self.remove(self.project.share / "faust")

    def copy_executables(self):
        self.log.info("copy executables")
        if PLATFORM == "Windows":
            self.copy(
                self.sourcedir / "bin" / "Release" / "faust.exe",
                self.project.bin
            )
        else:
            for e in ["faust", "faust-config", "faustpath"]:
                self.copy(self.prefix / "bin" / e, self.project.bin / e)

    def copy_headers(self):
        self.log.info("update headers")
        self.copy(self.prefix / "include" / "faust", self.project.include / "faust")

    def copy_sharedlib(self):
        self.log.info("copy_sharedlib")
        if PLATFORM == "Windows":
            self.copy(
                self.sourcedir / "lib" / "Release" / "faust.dll", self.project.lib
            )
            self.copy(
                self.sourcedir / "lib" / "Release" / "faust.lib", self.project.lib
            )
        else:
            self.copy(self.prefix / "lib" / self.dylib_name, self.dylib)
            if not dylib_link.exists():
                self.dylib_link.symlink_to(self.dylib)

    def copy_staticlib(self):
        self.log.info("copy staticlib")
        if PLATFORM == "Windows":
            self.copy(
                self.sourcedir / "lib" / "libfaust.lib",
                self.staticlib
                # self.project.lib_static
            )
        else:
            self.copy(self.prefix / "lib" / self.staticlib_name, self.staticlib)

    def copy_stdlib(self):
        self.log.info("copy stdlib")
        self.makedirs(self.project.share / "faust")
        for lib in (self.prefix / "share" / "faust").glob("*.lib"):
            self.copy(lib, self.project.share / "faust" / lib.name)

    def copy_examples(self):
        self.log.info("copy examples")
        self.copy(
            self.prefix / "share" / "faust" / "examples",
            self.project.share / "faust" / "examples",
        )
        self.remove(self.project.share / "faust" / "examples" / "SAM")
        self.remove(self.project.share / "faust" / "examples" / "bela")

    def patch_audio_driver(self):
        self.copy(
            self.project.patch / "rtaudio-dsp.h",
            self.project.include / "faust" / "audio" / "rtaudio-dsp.h",
        )

    def process(self):
        self.get_faust()
        self.build_faust()
        self.remove_current()
        self.copy_executables()
        self.copy_staticlib()
        self.copy_sharedlib()
        if PLATFORM in ["Linux", "Darwin"]:
            self.copy_headers()
            self.patch_audio_driver()
        # skip since resources already contains these
        # self.copy_stdlib()
        # self.copy_examples()


class SndfileBuilder(Builder):
    """Builds mimimal version of libsndfile
    """
    LIBNAME = "libsndfile"

    def __init__(self, version: str = "0.0.1"):
        super().__init__(version)
        self.src = self.project.downloads / self.LIBNAME
        self.build_dir = self.src / "build"
        self.prefix = self.project.build / "prefix"
        self.log = logging.getLogger(self.__class__.__name__)

    def process(self):
        self.setup_project()
        self.makedirs(self.project.downloads)
        self.makedirs(self.prefix)
        self.chdir(self.project.downloads)
        self.git_clone("https://github.com/libsndfile/libsndfile.git")
        self.makedirs(self.build_dir)
        self.cmake_config(
            src_dir=self.src,
            build_dir=self.build_dir,
            CMAKE_BUILD_TYPE="Release",
            BUILD_SHARED_LIBS="OFF",
            BUILD_PROGRAMS="OFF",
            BUILD_EXAMPLES="OFF",
            BUILD_TESTING="OFF",
            ENABLE_EXTERNAL_LIBS="OFF",
            ENABLE_MPEG="OFF",
            ENABLE_CPACK="OFF",
            ENABLE_PACKAGE_CONFIG="OFF",
            INSTALL_PKGCONFIG_MODULE="OFF",
            INSTALL_MANPAGES="OFF",
        )
        self.cmake_build(self.build_dir)
        self.cmake_install(self.build_dir, prefix=self.prefix)
        self.log.info("installing %s", self.staticlib)
        self.copy(self.prefix / "lib" / self.staticlib_name, self.project.lib_static)


class SamplerateBuilder(Builder):
    """Builds mimimal version of libsamplerate
    """
    LIBNAME = "libsamplerate"

    def __init__(self, version="0.0.1"):
        super().__init__(version)
        self.src = self.project.downloads / self.LIBNAME
        self.build_dir = self.src / "build"
        self.prefix = self.project.build / "prefix"
        self.log = logging.getLogger(self.__class__.__name__)

    def process(self):
        self.setup_project()
        self.makedirs(self.project.downloads)
        self.makedirs(self.prefix)
        self.chdir(self.project.downloads)
        self.git_clone("https://github.com/libsndfile/libsamplerate.git")
        self.makedirs(self.build_dir)
        self.cmake_config(
            src_dir=self.src,
            build_dir=self.build_dir,
            CMAKE_BUILD_TYPE="Release",
            BUILD_SHARED_LIBS="OFF",
            BUILD_TESTING="OFF",
            LIBSAMPLERATE_EXAMPLES="OFF",
            LIBSAMPLERATE_INSTALL="ON",
        )
        self.cmake_build(self.build_dir)
        self.cmake_install(self.build_dir, prefix=self.prefix)
        self.log.info("installing %s", self.staticlib)
        self.copy(self.prefix / "lib" / self.staticlib_name, self.project.lib_static)


# ----------------------------------------------------------------------------
# wheel_builder


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
    build: Optional[str]
    python_tags: List[str]
    abi_tags: List[str]
    platform_tags: List[str]

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
    def from_path(cls, path: Pathlike) -> "WheelFilename":
        """Parse a wheel filename into its components"""
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
    """cyfaust wheel builder

    Automates wheel building and handle special cases
    when building cyfaust locally and on github actions,
    especially whenc considering the number of different products given
    build-variants * platforms * architectures:
        {dynamic, static} * {macos, linux} * {x86_64, arm64|aarch64}
    """

    def __init__(self, src_folder: str ="dist", dst_folder: str = "wheels", universal: bool = False):
        self.cwd = Path.cwd()
        self.src_folder = self.cwd / src_folder
        self.dst_folder = self.cwd / dst_folder
        self.lib_folder = self.cwd / "lib"
        self.build_folder = self.cwd / "build"
        self.universal = universal

    def cmd(self, shellcmd, cwd: Pathlike = "."):
        subprocess.call(shellcmd, shell=True, cwd=str(cwd))

    def get(self, shellcmd, cwd: Pathlike = ".", shell: bool = False) -> str:
        """get output of shellcmd"""
        if not shell:
            shellcmd = shellcmd.split()
        return subprocess.check_output(
            shellcmd, encoding="utf8", shell=shell, cwd=str(cwd)
        ).strip()

    def getenv(self, key: str) -> bool:
        """convert '0','1' env values to bool {True, False}"""
        return bool(int(os.getenv(key, False)))

    def get_min_osx_ver(self) -> str:
        """set MACOSX_DEPLOYMENT_TARGET

        credits: cibuildwheel
        ref: https://github.com/pypa/cibuildwheel/blob/main/cibuildwheel/macos.py
        thanks: @henryiii
        post: https://github.com/pypa/wheel/issues/573

        For arm64, the minimal deployment target is 11.0.
        On x86_64 (or universal2), use 10.9 as a default.
        """
        min_osx_ver = "10.9"
        if self.is_macos_arm64 and not self.universal:
            min_osx_ver = "11.0"
        os.environ["MACOSX_DEPLOYMENT_TARGET"] = min_osx_ver
        return min_osx_ver

    @property
    def is_static(self):
        return self.getenv("STATIC")

    @property
    def is_macos_arm64(self):
        return PLATFORM == "Darwin" and ARCH == "arm64"

    @property
    def is_macos_x86_64(self):
        return PLATFORM == "Darwin" and ARCH == "x86_64"

    @property
    def is_linux_x86_64(self):
        return PLATFORM == "Linux" and ARCH == "x86_64"

    @property
    def is_linux_aarch64(self):
        return PLATFORM == "Linux" and ARCH == "aarch64"

    def clean(self):
        if self.build_folder.exists():
            shutil.rmtree(self.build_folder, ignore_errors=True)
        if self.src_folder.exists():
            shutil.rmtree(self.src_folder)

    def reset(self):
        self.clean()
        if self.dst_folder.exists():
            shutil.rmtree(self.dst_folder)

    def check(self) -> bool:
        assert self.dst_folder.glob("*.whl"), "no 'fixed' wheels created"

    def makedirs(self):
        if not self.dst_folder.exists():
            self.dst_folder.mkdir()

    def build_wheel(self, static: bool = False, override: bool = True):
        assert PY_VER_MINOR >= 8, "only supporting python >= 3.8"

        _cmd = f'"{PYTHON}" setup.py bdist_wheel'

        if PLATFORM == "Darwin":
            ver = self.get_min_osx_ver()
            if self.universal:
                prefix = (
                    f"ARCHFLAGS='-arch arm64 -arch x86_64' "
                    f"_PYTHON_HOST_PLATFORM='macosx-{ver}-universal2' "
                )
            else:
                prefix = (
                    f"ARCHFLAGS='-arch {ARCH}' "
                    f"_PYTHON_HOST_PLATFORM='macosx-{ver}-{ARCH}' "
                )

            _cmd = prefix + _cmd

        if static:
            os.environ["STATIC"] = "1"
        self.cmd(_cmd)

    def test_wheels(self):
        venv = self.dst_folder / "venv"
        if venv.exists():
            shutil.rmtree(venv)

        for wheel in self.dst_folder.glob("*.whl"):
            self.cmd("virtualenv venv", cwd=self.dst_folder)
            if PLATFORM in ["Linux", "Darwin"]:
                vpy = venv / "bin" / "python"
                vpip = venv / "bin" / "pip"
            elif PLATFORM == "Windows":
                vpy = venv / "Scripts" / "python"
                vpip = venv / "Scripts" / "pip"
            else:
                raise SystemExit("platform not supported")

            self.cmd(f"{vpip} install {wheel}")
            if "static" in str(wheel):
                target = "static"
                imported = "cyfaust"
                print("static variant test")
            else:
                target = "dynamic"
                imported = "interp"
                print("dynamic variant test")
            val = self.get(
                f'{vpy} -c "from cyfaust import {imported};print(len(dir({imported})))"',
                shell=True,
                cwd=self.dst_folder,
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
        lib = self.lib_folder
        if PLATFORM == "Darwin":
            self.cmd(f"delocate-wheel -v --wheel-dir {dst} {src}/*.whl")
        elif PLATFORM == "Linux":
            self.cmd(
                f"auditwheel repair --plat linux_{ARCH} --wheel-dir {dst} {src}/*.whl"
            )
        elif PLATFORM == "Windows":
            for whl in self.src_folder.glob("*.whl"):
                self.cmd(f"delvewheel repair --add-path {lib} --wheel-dir {dst} {whl}")
        else:
            raise SystemExit("platform not supported")

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
        if self.is_static:
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


# ----------------------------------------------------------------------------
# argdeclare

cmd = os.system


# option decorator
def option(*args, **kwds):
    def _decorator(func):
        _option = (args, kwds)
        if hasattr(func, "options"):
            func.options.append(_option)
        else:
            func.options = [_option]
        return func

    return _decorator


# arg decorator
arg = option


# combines option decorators
def option_group(*options):
    def _decorator(func):
        for option in options:
            func = option(func)
        return func

    return _decorator


class MetaCommander(type):
    def __new__(cls, classname, bases, classdict):
        classdict = dict(classdict)
        subcmds = {}
        for name, func in list(classdict.items()):
            if name.startswith("do_"):
                name = name[3:]
                subcmd = {"name": name, "func": func, "options": []}
                if hasattr(func, "options"):
                    subcmd["options"] = func.options
                subcmds[name] = subcmd
        classdict["_argparse_subcmds"] = subcmds
        return type.__new__(cls, classname, bases, classdict)


class Application(ShellCmd, metaclass=MetaCommander):
    """
    Commandline class for `manage.py`
    """
    name = "manage"
    description = "cyfaust build manager"
    version = "0.0.4"
    epilog = ""
    default_args = ["--help"]

    def __init__(self):
        self.project = Project()
        self.log = logging.getLogger(self.__class__.__name__)

    def parse_args(self):
        parser = argparse.ArgumentParser(
            # prog = self.name,
            formatter_class=argparse.RawDescriptionHelpFormatter,
            description=self.__doc__,
            epilog=self.epilog,
        )
        return parser

    def cmdline(self):
        self.parser = self.parse_args()

        self.parser.add_argument(
            "-v", "--version", action="version", version="%(prog)s " + self.version
        )

        subparsers = self.parser.add_subparsers(
            title="subcommands",
            description="valid subcommands",
            help="additional help",
            metavar="",
        )

        for name in sorted(self._argparse_subcmds.keys()):
            subcmd = self._argparse_subcmds[name]
            subparser = subparsers.add_parser(
                subcmd["name"], help=subcmd["func"].__doc__
            )
            for args, kwds in subcmd["options"]:
                subparser.add_argument(*args, **kwds)
            subparser.set_defaults(func=subcmd["func"])

        if len(sys.argv) <= 1:
            options = self.parser.parse_args(self.default_args)
        else:
            options = self.parser.parse_args()

        self.options = options
        options.func(self, options)

    # ------------------------------------------------------------------------
    # setup

    @option("--deps", "-d", help="install platform dependencies", action="store_true")
    @option("--faust", "-f", help="build libfaust", action="store_true")
    @option("--sndfile", "-s", help="build libsndfile", action="store_true")
    @option("--samplerate", "-r", help="build libsamplerate", action="store_true")
    @option("--all", "-a", help="build all", action="store_true")
    def do_setup(self, args):
        """setup faust"""

        _classes = [
            DependencyMgr,
            FaustBuilder,
            SndfileBuilder,
            SamplerateBuilder,
        ]

        if args.all:
            for mgr_class in _classes:
                mgr = mgr_class()
                mgr.process()
                sys.exit()

        if args.deps:
            mgr = DependencyMgr()
            mgr.process()

        if args.faust:
            fb = FaustBuilder()
            fb.process()

        if args.sndfile:
            sfb = SndfileBuilder()
            sfb.process()

        if args.samplerate:
            srb = SamplerateBuilder()
            srb.process()

    # ------------------------------------------------------------------------
    # build

    @option("--static", "-s", action="store_true", help="build static variant")
    def do_build(self, args):
        """build cyfaust"""
        _cmd = f'"{PYTHON}" setup.py build --build-lib build'
        if args.static:
            os.environ["STATIC"] = "1"
        self.cmd(_cmd)
        if PLATFORM == "Windows":
            cyfaust = self.project.build / "cyfaust"
            if cyfaust.exists():
                if not (cyfaust / "faust.dll").exists():
                    self.copy("lib/faust.dll", "build/cyfaust")
                if not (cyfaust / "resources").exists():
                    self.copy("resources", "build/cyfaust/resources")

    # ------------------------------------------------------------------------
    # wheel

    @option("--release", "-r", help="build and release all wheels", action="store_true")
    @option(
        "--build",
        "-b",
        help="build single wheel based on STATIC env var",
        action="store_true",
    )
    @option("--dynamic", "-d", help="build dynamic variant", action="store_true")
    @option("--static", "-s", help="build static variant", action="store_true")
    @option("--universal", "-u", help="build universal wheel", action="store_true")
    @option("--test", "-t", help="test built wheels", action="store_true")
    def do_wheel(self, args):
        """build cyfaust wheel"""

        if args.release:
            b = WheelBuilder(universal=args.universal)
            b.release()

        elif args.build:
            b = WheelBuilder(universal=args.universal)
            b.build()

        elif args.dynamic:
            b = WheelBuilder(universal=args.universal)
            b.build_dynamic_wheel()
            b.check()
            b.clean()

        elif args.static:
            b = WheelBuilder(universal=args.universal)
            b.build_static_wheel()
            b.check()
            b.clean()

        if args.test:
            b = WheelBuilder()
            b.test_wheels()

    # ------------------------------------------------------------------------
    # test

    @option("--pytest", "-p", help="run pytest", action="store_true")
    def do_test(self, args):
        """test cyfaust modules"""
        if args.pytest:
            self.cmd("pytest -vv tests")
        else:
            for t in self.project.tests.glob("test_*.py"):
                self.cmd(f'"{PYTHON}" {t}')

    # ------------------------------------------------------------------------
    # clean

    @option("--reset", "-r", help="reset project", action="store_true")
    @option("--verbose", "-v", help="verbose cleaning ops", action="store_true")
    def do_clean(self, args):
        """clean project detritus"""
        cwd = self.project.cwd
        _targets = ["build", "dist", "venv", "MANIFEST.in"]
        if args.reset:
            _targets += ["python", "bin", "lib", "share", "wheels"]
        _pats = [".*_cache", "*.egg-info", "__pycache__", ".DS_Store"]
        for t in _targets:
            self.remove(cwd / t, silent=not args.verbose)
        for p in _pats:
            for m in cwd.glob(p):
                self.remove(m, silent=not args.verbose)
            for m in cwd.glob("**/" + p):
                self.remove(m, silent=not args.verbose)


if __name__ == "__main__":
    Application().cmdline()
