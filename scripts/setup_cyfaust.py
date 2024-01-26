#!/usr/bin/env python3
"""setup_cyfaust.py

NOTE: not ready for use. This is a work-in-progress!

Consolidating and refactoriing a few scripts into one:

- install_deps.py
- setup_faust.py
- setup_sndfile.sh (which also install libsamplerate)

class structure:
    CustomFormatter(logging.Formatter)
    Project
    ShellCmd
        DependencyMgr
        FaustBuilder
        SndfileBuilder
        SamplerateBuilder
"""
import logging
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

Pathlike = str | Path

PLATFORM = platform.system()
ARCH = platform.machine()

DEBUG = True


class CustomFormatter(logging.Formatter):
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

    def git_clone(self, url: str, recurse: bool = False, branch: str | None = None):
        """git clone a repository source tree from a url"""
        _cmds = ["git clone --depth 1"]
        if branch:
            _cmds.append(f"--branch '{branch}'")
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

    def makedirs(self, path: Pathlike, mode=511, exist_ok=True):
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

    def remove(self, path: Pathlike):
        """Remove file or folder."""
        path = Path(path)
        if path.is_dir():
            self.log.info("remove folder: %s", path)
            shutil.rmtree(path, ignore_errors=(not DEBUG))
        else:
            self.log.info("remove file: %s", path)
            try:
                path.unlink()
            except FileNotFoundError:
                self.log.warning("file not found: %s", path)

    def pip_install(
        self,
        *pkgs,
        reqs: str | None = None,
        upgrade: bool = False,
        pip: str | None = None,
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
        _cmds.append("install")
        if update:
            _cmds.append("--upgrade")
        _cmds.extend(pkgs)
        self.cmd(" ".join(_cmds))

    def brew_install(self, *pkgs, update=False):
        """install using homebrew"""
        _pkgs = " ".join(pkgs)
        if update:
            self.cmd("brew update")
        self.cmd(f"brew install {_pkgs}")

    def cmake_config(self, src_dir: Pathlike, build_dir: Pathlike, **options):
        """activate cmake configuration / generation stage"""
        opts = " ".join(f"-D{k}={v}" for k, v in options.items())
        self.cmd(f"cmake -S {src_dir} -B {build_dir} {opts}")

    def cmake_build(self, build_dir: Pathlike):
        """activate cmake build stage"""
        self.cmd(f"cmake --build {build_dir}")

    def cmake_install(self, build_dir: Pathlike, prefix: str | None = None):
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
    def install_py_pkgs(self):
        self.pip_install(reqs="requirements.txt")

    def install_sys_pkgs(self):
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

    def process(self):
        self.install_py_pkgs()
        self.install_sys_pkgs()


class Project:
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
        self.downloads = self.build / "downloads"


class FaustBuilder(ShellCmd):
    def __init__(self, version="2.69.3"):
        self.version = version
        self.project = Project()
        self.libname = "libfaust"
        self.faust = self.project.build / "faust"
        self.root = self.faust / "root"
        self.backends = self.faust / "build" / "backends"
        self.targets = self.faust / "build" / "targets"
        self.log = logging.getLogger(self.__class__.__name__)

    @property
    def staticlib_name(self):
        return f"{self.libname}.a"

    @property
    def dylib_name(self):
        if PLATFORM == "Darwin":
            return f"{self.libname}.2.dylib"
        elif PLATFORM == "Linux":
            return f"{self.libname}.so.2"
        else:
            raise SystemExit("platform not supported")

    @property
    def dylib_linkname(self):
        if PLATFORM == "Darwin":
            return f"{self.libname}.dylib"
        elif PLATFORM == "Linux":
            return f"{self.libname}.so"
        else:
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

    def get_faust(self):
        self.log.info("update from faust main repo")
        self.makedirs(self.project.build)
        self.chdir(self.project.build)
        self.git_clone("https://github.com/grame-cncm/faust.git", branch=self.version)
        self.makedirs(self.project.build / "faust" / "build" / "faustdir")
        self.copy(self.project.patch / "faust.mk", self.faust / "Makefile")
        self.copy(
            self.project.patch / "interp_plus_backend.cmake",
            self.backends / "interp_plus.cmake",
        )
        self.copy(
            self.project.patch / "interp_plus_target.cmake",
            self.targets / "interp_plus.cmake",
        )
        self.chdir(self.faust)
        self.cmd("make interp")
        self.cmd("PREFIX=`pwd`/root make install")

    def remove_current(self):
        self.log.info("remove current faust libs")
        for e in ["faust", "faust-config", "faustpath"]:
            self.remove(self.project.bin / e)
        self.remove(self.project.include / "faust")
        # self.remove(self.project.lib)
        if self.dylib.exists():
            self.remove(self.dylib)
        if self.dylib_link.exists():
            self.remove(self.dylib_link)
        if self.staticlib.exists():
            self.remove(self.staticlib)
        self.remove(self.project.share / "faust")

    def copy_executables(self):
        self.log.info("copy executables")
        self.makedirs(self.project.bin)
        for e in ["faust", "faust-config", "faustpath"]:
            self.copy(self.root / "bin" / e, self.project.bin / e)

    def copy_headers(self):
        self.log.info("update headers")
        self.makedirs(self.project.include)
        self.copy(self.root / "include" / "faust", self.project.include / "faust")

    def copy_sharedlib(self):
        self.log.info("copy_sharedlib")
        self.makedirs(self.project.lib)
        self.copy(self.root / "lib" / self.dylib_name, self.dylib)
        self.dylib_link.symlink_to(self.dylib)

    def copy_staticlib(self):
        self.log.info("copy staticlib")
        self.makedirs(self.project.lib_static)
        self.copy(self.root / "lib" / self.staticlib_name, self.staticlib)

    def copy_stdlib(self):
        self.log.info("copy stdlib")
        self.makedirs(self.project.share / "faust")
        for lib in (self.root / "share" / "faust").glob("*.lib"):
            self.copy(lib, self.project.share / "faust" / lib.name)

    def copy_examples(self):
        self.log.info("copy examples")
        self.copy(
            self.root / "share" / "faust" / "examples",
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
        self.remove_current()
        self.copy_executables()
        self.copy_headers()
        self.copy_staticlib()
        self.copy_sharedlib()
        self.copy_stdlib()
        self.copy_examples()
        self.patch_audio_driver()


class SndfileBuilder(ShellCmd):
    def __init__(self, version="2.69.3"):
        self.version = version
        self.project = Project()
        self.libname = "libsndfile"
        self.src = self.project.downloads / self.libname
        self.build_dir = self.src / "build"
        self.prefix = self.project.build / "prefix"
        self.log = logging.getLogger(self.__class__.__name__)

    def process(self):
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
        self.log.info("installing libsndfile to %s", self.project.lib_static)
        self.copy(
            self.prefix / 'lib' / f"{self.libname}.a", 
            self.project.lib_static)


class SamplerateBuilder(ShellCmd):
    def __init__(self, version="2.69.3"):
        self.version = version
        self.project = Project()
        self.libname = "libsamplerate"
        self.src = self.project.downloads / self.libname
        self.build_dir = self.src / "build"
        self.prefix = self.project.build / "prefix"
        self.log = logging.getLogger(self.__class__.__name__)

    def process(self):
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
        self.log.info("installing libsamplerate to %s", self.project.lib_static)
        self.copy(
            self.prefix / 'lib' / f"{self.libname}.a", 
            self.project.lib_static)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="setup cyfaust project dependencies")

    def opt(long_opt, short_opt, desc):
        return parser.add_argument(long_opt, short_opt, action="store_true", help=desc)

    opt("--deps", "-d", "install platform dependencies")
    opt("--faust", "-f", "build/install libfaust")
    opt("--sndfile", "-s", "build/install libsndfile")
    opt("--samplerate", "-r", "build/install libsamplerate")
    opt("--all", "-a", "build/install all")

    args = parser.parse_args()

    if args.all:
        for mgr_class in [
            DependencyMgr,
            FaustBuilder,
            SndfileBuilder,
            SamplerateBuilder,
        ]:
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