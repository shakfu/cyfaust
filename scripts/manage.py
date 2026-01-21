#!/usr/bin/env python3

"""manage.py: cross-platform cyfaust build manager.

It only uses python stdlib modules to do the following:

- General Shell ops
- Dependency download, build, install
- Module compilation
- Wheel building
- Alternative frontend to Makefile
- Downloads/build a local version python for testing

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
            PythonBuilder
        Application
    WheelFile(dataclass)
    WheelBuilder

It has an argparse-based cli api:

usage: manage.py [-h] [-v]  ...

cyfaust build manager

    clean        clean detritus
    python       build local python
    setup        setup prerequisites
    test         test modules
    wheel        build wheels

"""
import argparse
import filecmp
import logging
import os
import platform
import re
import shutil
import stat
import subprocess
import sys
import tarfile
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Union
from urllib.request import urlretrieve

# ----------------------------------------------------------------------------
# constants

PYTHON = sys.executable
PLATFORM = platform.system()
ARCH = platform.machine()
PY_VER_MINOR = sys.version_info.minor

DEBUG = True

FAUST_VERSION = "2.83.1"

# ----------------------------------------------------------------------------
# type aliases

Pathlike = Union[str, Path]

# ----------------------------------------------------------------------------
# setup


class Project:
    """Utility class to hold project directory structure"""

    def __init__(self):
        self.cwd = Path.cwd()
        self.bin = self.cwd / "bin"
        self.include = self.cwd / "include"
        self.lib = self.cwd / "lib"
        self.lib_static = self.lib / "static"
        self.share = self.cwd / "share"
        self.scripts = self.cwd / "scripts"
        self.src = self.cwd / "src"
        self.patch = self.scripts / "patch"
        self.tests = self.cwd / "tests"
        self.dist = self.cwd / "dist"
        self.wheels = self.cwd / "wheels"
        self.build = self.cwd / "build"
        self.downloads = self.build / "downloads"


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

    def download(self, url: str, tofolder: Optional[Pathlike] = None) -> Pathlike:
        """Download a file from a url to an optional folder"""
        _path = os.path.basename(url)
        if tofolder:
            _path = Path(tofolder).joinpath(_path)
        filename, _ = urlretrieve(url, filename=_path)
        return Path(filename)

    def extract(self, archive: Pathlike, tofolder: Pathlike = '.'):
        """extract a tar archive"""
        if tarfile.is_tarfile(archive):
            with tarfile.open(archive) as f:
                f.extractall(tofolder)
        # elif zipfile.is_zipfile(archive):
        #     with zipfile.open(archive) as f:
        #         f.extractall(tofolder)
        else:
            raise TypeError("cannot extract from this file.")

    def fail(self, msg: Optional[str] = None, *args):
        """exits the program with an optional error msg."""
        if msg:
            self.log.critical(msg, *args)
        sys.exit(1)

    def git_clone(self, url: str, recurse: bool = False, branch: Optional[str] = None, cwd: Pathlike = "."):
        """git clone a repository source tree from a url"""
        _cmds = ["git clone --depth 1"]
        if branch:
            _cmds.append(f"--branch {branch}")
        if recurse:
            _cmds.append("--recurse-submodules --shallow-submodules")
        _cmds.append(url)
        self.cmd(" ".join(_cmds), cwd=cwd)

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

    # def get(self, shellcmd: str) -> str:
    #     """get output of shellcmd"""
    #     self.log.info("getting output of '%s'", shellcmd)
    #     return subprocess.check_output(shellcmd.split(), encoding="utf8").strip()

    def get(self, shellcmd, cwd: Pathlike = ".", shell: bool = False) -> str:
        """get output of shellcmd"""
        if not shell:
            shellcmd = shellcmd.split()
        return subprocess.check_output(
            shellcmd, encoding="utf8", shell=shell, cwd=str(cwd)
        ).strip()

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

    def remove(self, path: Pathlike, silent: bool = False):
        """Remove file or folder."""

        # handle windows error on read-only files
        def remove_readonly(func, path, exc_info):
            "Clear the readonly bit and reattempt the removal"
            if func not in (os.unlink, os.rmdir) or exc_info[1].winerror != 5:
                raise exc_info[1]
            os.chmod(path, stat.S_IWRITE)
            func(path)

        path = Path(path)
        if path.is_dir():
            if not silent:
                self.log.info("remove folder: %s", path)
            shutil.rmtree(path, ignore_errors=not DEBUG, onerror=remove_readonly)
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

            self.log.info("install macOS system dependencies")
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

            self.log.info("install Linux system dependencies")
            self.apt_install(*sys_pkgs)

        elif PLATFORM == "Windows":
            # this is a placeholder
            pass

    def process(self):
        """run all relevant processes"""
        self.install_py_pkgs()
        self.install_sys_pkgs()


class Builder(ShellCmd):
    """Abstract builder class with additional methods common to subclasses."""

    NAME = "name"
    LIBNAME = f"lib{NAME}"
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
    def executable_name(self):
        name = self.NAME
        if PLATFORM == "Windows":
            name = f"{self.NAME}.exe"
        return name

    @property
    def executable(self):
        return self.project.bin / self.executable_name

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
            return f"{self.NAME}{self.DYLIB_SUFFIX_WIN}"
        raise self.fail("platform not supported")

    @property
    def dylib_linkname(self):
        if PLATFORM == "Darwin":
            return f"{self.LIBNAME}.dylib"
        if PLATFORM == "Linux":
            return f"{self.LIBNAME}.so"
        raise self.fail("platform not supported")

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
    """Manages all aspects of the interpreter-centric faust build for cyfaust,"""

    NAME = "faust"
    LIBNAME = f"lib{NAME}"
    DYLIB_SUFFIX_OSX = ".2.dylib"
    DYLIB_SUFFIX_LIN = ".so.2"
    DYLIB_SUFFIX_WIN = ".dll"

    def __init__(self, version: str = FAUST_VERSION):
        super().__init__(version)
        self.src = self.project.downloads / "faust"
        self.sourcedir = self.src / "build"
        self.faustdir = self.sourcedir / "faustdir"
        self.backends = self.sourcedir / "backends"
        self.targets = self.sourcedir / "targets"
        self.prefix = self.project.build / "prefix"
        self.log = logging.getLogger(self.__class__.__name__)

    @property
    def headers(self):
        return self.project.include / "faust"

    def get_faust(self):
        try:
            self.log.info("update from faust main repo")
            self.setup_project()
            self.makedirs(self.project.downloads)
            self.chdir(self.project.downloads)
            self.git_clone(
                "https://github.com/grame-cncm/faust.git", branch=self.version
            )
        finally:
            if not self.src.exists():
                self.fail("git clone faust failed.")
        # Fix invalid gitignore patterns that break scikit-build-core on Linux
        self.fix_gitignore_patterns()

    def fix_gitignore_patterns(self):
        """Fix invalid gitignore syntax in Faust source tree.

        The pathspec library (used by scikit-build-core) rejects trailing
        backslashes with nothing to escape. This fixes patterns like
        'SharpSoundDevice\\' to 'SharpSoundDevice/' (correct directory syntax).
        """
        gitignore_path = (
            self.src / "tests" / "impulse-tests" / "archs" / "csharp" / "IRTest" / ".gitignore"
        )
        if not gitignore_path.exists():
            self.log.warning("gitignore not found: %s", gitignore_path)
            return

        content = gitignore_path.read_text()
        # Fix trailing backslashes (invalid escape) to forward slashes (directory marker)
        fixed_content = content.replace("SharpSoundDevice\\", "SharpSoundDevice/")
        fixed_content = fixed_content.replace("tinyalsa\\", "tinyalsa/")

        if content != fixed_content:
            gitignore_path.write_text(fixed_content)
            self.log.info("fixed invalid gitignore patterns in %s", gitignore_path)

    def build_faust(self):
        self.makedirs(self.faustdir)

        if PLATFORM in ["Linux", "Darwin"]:
            try:
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
            finally:
                # validate build
                dylib = self.prefix / "lib" / self.dylib_name
                if not dylib.exists():
                    self.fail("build faust failed: dylib not found: %s", dylib)

                staticlib = self.prefix / "lib" / self.staticlib_name
                if not staticlib.exists():
                    self.fail("build faust failed: staticlib not found %s", staticlib)

        elif PLATFORM == "Windows":
            try:
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
            finally:
                dylib = self.sourcedir / "lib" / "Release" / "faust.dll"
                if not dylib.exists():
                    self.fail("build faust failed: dylib not found: %s", dylib)

                staticlib = self.sourcedir / "lib" / "Release" / "faust.lib"
                if not staticlib.exists():
                    self.fail("build faust failed: staticlib not found %s", staticlib)

        else:
            raise self.fail("platform not supported")


    def remove_current(self):
        try:
            self.log.info("remove current faust libs")

            # common
            if self.executable.exists():
                self.remove(self.executable)
            if self.dylib.exists():
                self.remove(self.dylib)
            if self.staticlib.exists():
                self.remove(self.staticlib)

            if PLATFORM in ["Linux", "Darwin"]:
                for e in ["faust-config", "faustpath"]:
                    executable = self.project.bin / e
                    if executable.exists():
                        self.remove(executable)
                include = self.project.include / "faust"
                if include.exists():
                    self.remove(include)
                if self.dylib_link.exists():
                    self.remove(self.dylib_link)
                self.remove(self.project.share / "faust")
        finally:
            paths = [
                self.executable,
                self.dylib,
                self.staticlib,
            ]
            if any(p.exists() for p in paths):
                self.fail("remove_current failed")

    def copy_executables(self):
        try:
            self.log.info("copy executables")
            if PLATFORM == "Windows":
                self.copy(
                    self.sourcedir / "bin" / "Release" / "faust.exe", self.project.bin
                )
            else:
                for e in ["faust", "faust-config", "faustpath"]:
                    self.copy(self.prefix / "bin" / e, self.project.bin / e)
        finally:
            if not self.executable.exists():
                self.fail("copy_executables failed")

    def copy_headers(self):
        try:
            self.log.info("update headers")
            self.copy(self.prefix / "include" / "faust", self.headers)
        finally:
            if not self.headers.exists():
                self.fail("copy_headers failed")

    def copy_sharedlib(self):
        self.log.info("copy_sharedlib")
        if PLATFORM == "Windows":
            faust_dll = self.project.lib / "faust.dll"
            faust_lib = self.project.lib / "faust.lib"
            try:
                self.copy(
                    self.sourcedir / "lib" / "Release" / "faust.dll", faust_dll
                )
                self.copy(
                    self.sourcedir / "lib" / "Release" / "faust.lib", faust_lib
                )
            finally:
                if not (faust_dll.exists() and faust_lib.exists()):
                    self.fail("copy_sharedlib failed: %s", self.dylib)
        else:
            try:
                self.copy(self.prefix / "lib" / self.dylib_name, self.dylib)
                if not self.dylib_link.exists():
                    self.dylib_link.symlink_to(self.dylib)
            finally:
                if not self.dylib.exists():
                    self.fail("copy_sharedlib failed: %s", self.dylib)

    def copy_staticlib(self):
        try:
            self.log.info("copy staticlib")
            if PLATFORM == "Windows":
                self.copy(
                    self.sourcedir / "lib" / "libfaust.lib",
                    self.staticlib,
                    # self.project.lib_static
                )
            else:
                self.copy(self.prefix / "lib" / self.staticlib_name, self.staticlib)
        finally:
            if not self.staticlib.exists():
                self.fail("copy_staticlib failed")

    def copy_stdlib(self):
        share_faust = self.project.share / "faust"
        try:
            self.log.info("copy stdlib")
            self.makedirs(share_faust)
            for lib in (self.prefix / "share" / "faust").glob("*.lib"):
                self.copy(lib, share_faust / lib.name)
        finally:
            if not share_faust.exists():
                self.fail("copy_stdlib failed")

    def copy_examples(self):
        try:
            self.log.info("copy examples")
            self.copy(
                self.prefix / "share" / "faust" / "examples",
                self.project.share / "faust" / "examples",
            )
            self.remove(self.project.share / "faust" / "examples" / "SAM")
            self.remove(self.project.share / "faust" / "examples" / "bela")
        finally:
            if not (self.project.share / "faust" / "examples").exists():
                self.fail("copy_examples failed")

    def patch_audio_driver(self):
        src = self.project.patch / "rtaudio-dsp.h"
        dst = self.project.include / "faust" / "audio" / "rtaudio-dsp.h"
        try:
            self.copy(src, dst)
        finally:
            if not filecmp.cmp(src, dst):
                self.fail("patch_audio_driver failed")

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
        # skip since `resources` already contains these
        # self.copy_stdlib()
        # self.copy_examples()
        self.log.info("faust build DONE")


class SndfileBuilder(Builder):
    """Builds mimimal version of libsndfile"""

    NAME = "sndfile"
    LIBNAME = f"lib{NAME}"

    def __init__(self, version: str = "0.0.1"):
        super().__init__(version)
        self.src = self.project.downloads / self.LIBNAME
        self.build_dir = self.src / "build"
        self.prefix = self.project.build / "prefix"
        self.log = logging.getLogger(self.__class__.__name__)

    @property
    def staticlib_name(self):
        if PLATFORM == "Windows":
            return f"{self.NAME}.lib"
        return f"{self.LIBNAME}.a"

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
        self.cmake_build(build_dir=self.build_dir, release=True)
        if PLATFORM == "Windows":
            staticlib = self.build_dir / 'Release' / self.staticlib_name
        else:
            self.cmake_install(self.build_dir, prefix=self.prefix)
            self.log.info("installing %s", self.staticlib)
            staticlib = self.prefix / "lib" / self.staticlib_name
        if not staticlib.exists():
            self.fail("%s build failed", self.staticlib_name)
        self.copy(staticlib, self.staticlib)
        self.log.info(f"{self.staticlib_name} build/install DONE")


class SamplerateBuilder(Builder):
    """Builds mimimal version of libsamplerate"""

    NAME = "samplerate"
    LIBNAME = f"lib{NAME}"

    def __init__(self, version="0.0.1"):
        super().__init__(version)
        self.src = self.project.downloads / self.LIBNAME
        self.build_dir = self.src / "build"
        self.prefix = self.project.build / "prefix"
        self.log = logging.getLogger(self.__class__.__name__)

    @property
    def staticlib_name(self):
        if PLATFORM == "Windows":
            return f"{self.NAME}.lib"
        return f"{self.LIBNAME}.a"

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
        self.cmake_build(build_dir=self.build_dir, release=True)
        if PLATFORM == "Windows":
            staticlib = self.build_dir / 'src' / 'Release' / self.staticlib_name
        else:
            self.cmake_install(self.build_dir, prefix=self.prefix)
            self.log.info("installing %s", self.staticlib)
            staticlib = self.prefix / "lib" / self.staticlib_name
        if not staticlib.exists():
            self.fail("%s build failed", self.staticlib_name)
        self.copy(staticlib, self.staticlib)
        self.log.info(f"{self.staticlib_name} build/install DONE")

# ----------------------------------------------------------------------------
# python_builder

class PythonBuilder(Builder):
    """Builds python locally"""

    NAME = "python"
    LIBNAME = f"lib{NAME}"

    CONFIG_OPTIONS = [
        "--enable-shared",
        "--disable-test-modules",
        "--without-static-libpython",
    ]

    REQUIRED_PACKAGES = [
        "cython",
        "pytest",
    ]

    def __init__(self, version="3.11.7"):
        super().__init__(version)
        self.src = self.project.downloads / self.src_name
        self.build_dir = self.src / "build"
        self.prefix = self.project.cwd / "python"
        self.python = self.prefix / 'bin' / 'python3'
        self.pip = self.prefix / 'bin' / 'pip3'
        self.log = logging.getLogger(self.__class__.__name__)

    @property
    def url(self):
        ver = self.version
        return f"https://www.python.org/ftp/python/{ver}/Python-{ver}.tar.xz"

    @property
    def archive(self):
        return os.path.basename(self.url)

    @property
    def src_name(self):
        return (self.archive).rstrip('.tar.xz')

    def pre_process(self):
        """override by subclass if needed"""

    def post_process(self):
        """override by subclass if needed"""

    def process(self):
        self.pre_process()
        self.project.build.mkdir(exist_ok=True)
        self.project.downloads.mkdir(exist_ok=True)
        self.prefix.mkdir(exist_ok=True)
        archive = self.download(self.url, tofolder=self.project.downloads)
        self.log.info("downloaded %s", archive)
        self.extract(archive, tofolder=self.project.downloads)
        assert self.src.exists(), f"could not extract from {archive}"
        self.build_dir.mkdir(exist_ok=True)
        config_opts = " ".join(self.CONFIG_OPTIONS)
        self.cmd(f"../configure --prefix={self.prefix} {config_opts}", 
            cwd=self.build_dir)
        self.cmd("make", cwd=self.build_dir)
        self.cmd("make install", cwd=self.build_dir)
        required_pkgs = " ".join(self.REQUIRED_PACKAGES)
        self.cmd(f"{self.pip} install --upgrade pip", cwd=self.project.cwd)
        self.cmd(f"{self.pip} install {required_pkgs}", cwd=self.project.cwd)
        self.post_process()

class PythonDebugBuilder(PythonBuilder):
    """Builds debug python locally"""

    NAME = "python"
    LIBNAME = f"lib{NAME}"

    CONFIG_OPTIONS = [
        "--enable-shared",
        "--disable-test-modules",
        "--without-static-libpython",

        "--with-pydebug",
        # "--with-trace-refs",
        # "--with-valgrind",
        # "--with-address-sanitizer",
        # "--with-memory-sanitizer",
        # "--with-undefined-behavior-sanitizer",
    ]

    REQUIRED_PACKAGES = [
        "pkgconfig",
        "cython",
        "pytest",
    ]

    def post_process(self):
        memray = self.project.downloads / 'memray'
        self.git_clone("https://github.com/bloomberg/memray.git",
            cwd=self.project.downloads)
        self.cmd(f"{self.python} setup.py build", cwd=memray)
        self.cmd(f"{self.python} setup.py install", cwd=memray)

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


class WheelBuilder(ShellCmd):
    """cyfaust wheel builder

    Automates wheel building and handle special cases
    when building cyfaust locally and on github actions,
    especially whenc considering the number of different products given
    build-variants * platforms * architectures:
        {dynamic, static} * {macos, linux} * {x86_64, arm64|aarch64}
    """

    def __init__(self, universal: bool = False):
        self.universal = universal
        self.project = Project()
        self.log = logging.getLogger(self.__class__.__name__)

    def get_min_osx_ver(self) -> str:
        """set MACOSX_DEPLOYMENT_TARGET

        credits: cibuildwheel
        ref: https://github.com/pypa/cibuildwheel/blob/main/cibuildwheel/macos.py
        thanks: @henryiii
        post: https://github.com/pypa/wheel/issues/573

        From faust version 2.81.2, on arm64, the minimal deployment target is 15.0.
        On x86_64 (or universal2), use 10.9 as a default.
        """
        min_osx_ver = "10.9"
        if self.is_macos_arm64 and not self.universal:
            min_osx_ver = "15.0"
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
        if self.project.build.exists():
            shutil.rmtree(self.project.build, ignore_errors=True)
        if self.project.dist.exists():
            shutil.rmtree(self.project.dist)

    def reset(self):
        self.clean()
        if self.project.wheels.exists():
            shutil.rmtree(self.project.wheels)

    def check(self):
        have_wheels = bool(self.project.wheels.glob("*.whl"))
        if not have_wheels:
            self.fail("no wheels created")
 
    def makedirs(self):
        if not self.project.wheels.exists():
            self.project.wheels.mkdir()

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
        venv = self.project.wheels / "venv"
        if venv.exists():
            shutil.rmtree(venv)

        for wheel in self.project.wheels.glob("*.whl"):
            self.cmd("virtualenv venv", cwd=self.project.wheels)
            if PLATFORM in ["Linux", "Darwin"]:
                vpy = venv / "bin" / "python"
                vpip = venv / "bin" / "pip"
            elif PLATFORM == "Windows":
                vpy = venv / "Scripts" / "python"
                vpip = venv / "Scripts" / "pip"
            else:
                self.fail("platform not supported")

            self.cmd(f"{vpip} install {wheel}")
            if "static" in str(wheel):
                target = "static"
                imported = "cyfaust"
                self.log.info("static variant test")
            else:
                target = "dynamic"
                imported = "interp"
                self.log.info("dynamic variant test")
            val = self.get(
                f'{vpy} -c "from cyfaust import {imported};print(len(dir({imported})))"',
                shell=True,
                cwd=self.project.wheels,
            )
            self.log.info(f"cyfaust.{imported} # objects: {val}")
            assert val, f"cyfaust {target} wheel test: FAILED"
            self.log.info(f"cyfaust {target} wheel test: OK")
            if venv.exists():
                shutil.rmtree(venv)

    def build_dynamic_wheel(self):
        self.log.info("building dynamic build wheel")
        self.clean()
        self.makedirs()
        self.build_wheel()
        src = self.project.dist
        dst = self.project.wheels
        lib = self.project.lib
        if PLATFORM == "Darwin":
            self.cmd(f"delocate-wheel -v --wheel-dir {dst} {src}/*.whl")
        elif PLATFORM == "Linux":
            self.cmd(
                f"auditwheel repair --plat linux_{ARCH} --wheel-dir {dst} {src}/*.whl"
            )
        elif PLATFORM == "Windows":
            for whl in self.project.dist.glob("*.whl"):
                self.cmd(f"delvewheel repair --add-path {lib} --wheel-dir {dst} {whl}")
        else:
            raise self.fail("platform not supported")

    def build_static_wheel(self):
        self.log.info("building static build wheel")
        self.clean()
        self.makedirs()
        self.build_wheel(static=True)
        for wheel in self.project.dist.glob("*.whl"):
            w = WheelFilename.from_path(wheel)
            w.project = "cyfaust-static"
            renamed_wheel = str(w)
            os.rename(wheel, renamed_wheel)
            dest_wheel = self.project.wheels / renamed_wheel
            if dest_wheel.exists():
                dest_wheel.unlink()
            shutil.move(renamed_wheel, self.project.wheels)

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


# bool option decorator
def opt(long, short, desc):
    return option(long, short, help=desc, action="store_true")


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
    """cyfaust build manager"""

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

    @opt("--deps", "-d", "install platform dependencies")
    @opt("--faust", "-f", "build libfaust")
    @opt("--sndfile", "-s", "build libsndfile")
    @opt("--samplerate", "-r", "build libsamplerate")
    @opt("--all", "-a", "build all")
    def do_setup(self, args):
        """setup prerequisites"""

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
    # python

    @opt("--debug", "-d", "build debug python")
    @option("--version", "-v", default="3.11.7", help="python version")
    def do_python(self, args):
        """build local python"""
        if args.debug:
            builder = PythonDebugBuilder(version=args.version)
        else:
            builder = PythonBuilder(version=args.version)
        builder.process()

    # ------------------------------------------------------------------------
    # build

    @opt("--static", "-s", "build static variant")
    def do_build(self, args):
        """build packages"""
        # _cmd = f'"{PYTHON}" setup.py build --build-lib build'
        _cmd = f'"{PYTHON}" setup.py build_ext --inplace'
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

    @opt("--release", "-r", "build and release all wheels")
    @opt("--build", "-b", "build single wheel based on STATIC env var")
    @opt("--dynamic", "-d", "build dynamic variant")
    @opt("--static", "-s", "build static variant")
    @opt("--universal", "-u", "build universal wheel")
    @opt("--test", "-t", "test built wheels")
    def do_wheel(self, args):
        """build wheels"""

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

    @opt("--pytest", "-p", "run pytest")
    def do_test(self, args):
        """test modules"""
        if args.pytest:
            self.cmd("pytest -vv tests")
        else:
            for t in self.project.tests.glob("test_*.py"):
                self.cmd(f'"{PYTHON}" {t}')

    # ------------------------------------------------------------------------
    # clean

    @opt("--reset", "-r", "reset project")
    @opt("--verbose", "-v", "verbose cleaning ops")
    def do_clean(self, args):
        """clean detritus"""
        cwd = self.project.cwd
        _targets = ["build", "dist", "MANIFEST.in", ".task"]
        if args.reset:
            _targets += ["python", "bin", "lib", "share", "wheels", "venv", ".venv"]
        _pats = [".*_cache", "*.egg-info", "__pycache__", ".DS_Store"]
        for t in _targets:
            self.remove(cwd / t, silent=not args.verbose)
        for p in _pats:
            for m in cwd.glob(p):
                self.remove(m, silent=not args.verbose)
            for m in cwd.glob("**/" + p):
                self.remove(m, silent=not args.verbose)
        # clean built artifacts
        pat = "*.so" # default for MacOs or Linux            
        if PLATFORM == "Windows":
            pat = "*.dll"
        for m in self.project.src.glob(f"**/{pat}"):
            self.remove(m, silent=not args.verbose)


if __name__ == "__main__":
    Application().cmdline()
