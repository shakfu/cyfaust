#!/usr/bin/env python3

import os
import shutil
import logging
import platform
from pathlib import Path

PLATFORM = platform.system()


DEBUG=True


class CustomFormatter(logging.Formatter):

    white = "\x1b[97;20m"
    grey = "\x1b[38;20m"
    green = "\x1b[32;20m"
    cyan = "\x1b[36;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    fmt = "%(asctime)s - {}%(levelname)-8s{} - %(name)s.%(funcName)s - %(message)s"

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
logging.basicConfig(
    level=logging.DEBUG if DEBUG else logging.INFO,
    handlers=[handler]
)


class ShellCmd:
    """Provides platform agnostic file/folder handling."""

    def cmd(self, shellcmd, *args, **kwargs):
        """Run shell command with args and keywords"""
        _cmd = shellcmd.format(*args, **kwargs)
        self.log.info(_cmd)
        os.system(_cmd)

    __call__ = cmd

    def chdir(self, path):
        """Change current workding directory to path"""
        self.log.info("changing working dir to: %s", path)
        os.chdir(path)

    def chmod(self, path, perm=0o777):
        """Change permission of file"""
        self.log.info("change permission of %s to %s", path, perm)
        os.chmod(path, perm)

    def makedirs(self, path, mode=511, exist_ok=True):
        """Recursive directory creation function"""
        self.log.info("making directory: %s", path)
        os.makedirs(path, mode, exist_ok)

    def move(self, src, dst):
        """Move from src path to dst path."""
        self.log.info("move path %s to %s", src, dst)
        shutil.move(src, dst)

    def copy(self, src: Path, dst: Path):
        """copy file or folders -- tries to be behave like `cp -rf`"""
        self.log.info("copy %s to %s", src, dst)
        src, dst = Path(src), Path(dst)
        # if dst.exists():
        #     dst = dst / src.name
        if src.is_dir():
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)

    def remove(self, path):
        """Remove file or folder."""
        if path.is_dir():
            self.log.info("remove folder: %s", path)
            shutil.rmtree(path, ignore_errors=(not DEBUG))
        else:
            self.log.info("remove file: %s", path)
            try:
                # path.unlink(missing_ok=True)
                path.unlink()
            except FileNotFoundError:
                self.log.warning("file not found: %s", path)

    def install_name_tool(self, src, dst, mode="id"):
        """change dynamic shared library install names"""
        _cmd = f"install_name_tool -{mode} {src} {dst}"
        self.log.info(_cmd)
        self.cmd(_cmd)


class FaustBuilder(ShellCmd):
    def __init__(self, version="2.69.3"):
        self.version = version
        self.cwd = Path.cwd()
        self.bin = self.cwd / "bin"
        self.include = self.cwd / "include"
        self.lib = self.cwd / "lib"
        self.share = self.cwd / "share"
        self.build = self.cwd / "build"
        self.scripts = self.cwd / "scripts"
        self.faust = self.build / "faust"
        self.root = self.faust / "root"
        self.backends = self.faust / "build" / "backends"
        self.targets = self.faust / "build" / "targets"
        self.log = logging.getLogger(self.__class__.__name__)

    def get_faust(self):
        self.log.info("update from faust main repo")
        self.makedirs(self.build)
        self.chdir(self.build)
        self.cmd(
            f"git clone --depth 1 --branch '{self.version}' https://github.com/grame-cncm/faust.git"
        )
        self.makedirs(self.build / "faust" / "build" / "faustdir")
        self.copy(self.scripts / "faust.mk", self.faust / "Makefile")
        self.copy(
            self.scripts / "interp_plus_backend.cmake",
            self.backends / "interp_plus.cmake"
        )
        self.copy(
            self.scripts / "interp_plus_target.cmake",
            self.targets / "interp_plus.cmake"
        )
        self.chdir(self.faust)
        self.cmd("make interp")
        self.cmd("PREFIX=`pwd`/root make install")

    def remove_current(self):
        self.log.info("remove current faust libs")
        for e in ["faust", "faust-config", "faustpath"]:
            self.remove(self.bin / e)
        self.remove(self.include / "faust")
        self.remove(self.lib / "libfaust.a")
        self.remove(self.share / "faust")

    def copy_executables(self):
        self.log.info("copy executables")
        self.makedirs(self.bin)
        for e in ["faust", "faust-config", "faustpath"]:
            self.copy(self.root / "bin" / e, self.bin / e)

    def copy_headers(self):
        self.log.info("update headers")
        self.makedirs(self.include)
        self.copy(self.root / "include" / "faust", self.include / "faust")

    def copy_sharedlib(self):
        self.log.info("copy_sharedlib")
        self.makedirs(self.lib)
        if PLATFORM == "Darwin":
            self.copy(
                self.root / "lib" / "libfaust.2.dylib", self.lib / "libfaust.2.dylib"
            )
        elif PLATFORM == "Linux":
            self.copy(
                self.root / "lib" / "libfaust.so.2", self.lib / "libfaust.so.2"
            )


    def copy_staticlib(self):
        self.log.info("copy staticlib")
        self.makedirs(self.lib)
        self.copy(self.root / "lib" / "libfaust.a", self.lib / "libfaust.a")

    def copy_stdlib(self):
        self.log.info("copy stdlib")
        self.makedirs(self.share / "faust")
        for lib in (self.root / "share" / "faust").glob("*.lib"):
            self.copy(lib, self.share / "faust" / lib.name)

    def copy_examples(self):
        self.log.info("copy examples")
        self.copy(
            self.root / "share" / "faust" / "examples",
            self.share / "faust" / "examples",
        )
        self.remove(self.share / "faust" / "examples" / "SAM")
        self.remove(self.share / "faust" / "examples" / "bela")

    def patch_audio_driver(self):
        self.copy(
            self.scripts / "rtaudio-dsp.h",
            self.include / "faust" / "audio" / "rtaudio-dsp.h",
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


if __name__ == '__main__':
	b = FaustBuilder()
	b.process()
