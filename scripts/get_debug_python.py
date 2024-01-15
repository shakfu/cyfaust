#!/usr/bin/env python3

import os
import subprocess
from pathlib import Path

# config
DEFAULT_PYTHON_VERSION = "3.11.7"

# directories
CWD = Path.cwd()
BUILD = CWD / 'build'
DOWNLOADS = BUILD / 'downloads'
PYTHON_PREFIX = CWD / 'python' # local prefix for debug python (.gitignored)
PYTHON = PYTHON_PREFIX / 'bin' / 'python3'

VERSION = os.getenv("VERSION", DEFAULT_PYTHON_VERSION)
PYTHON_URL = f"https://www.python.org/ftp/python/{VERSION}/Python-{VERSION}.tar.xz"
PYTHON_ARCHIVE = Path(PYTHON_URL).name
PYTHON_FOLDER_NAME = Path(Path(PYTHON_URL).stem).stem
PYTHON_FOLDER = DOWNLOADS / PYTHON_FOLDER_NAME 
DEBUG_FOLDER = PYTHON_FOLDER / 'debug'
CONFIG_OPTIONS = [
	"--enable-shared",
	"--disable-test-modules",
	"--without-static-libpython",

	"--with-pydebug",
	# "--with-trace-refs",
	# "--with-valgrind",
	"--with-address-sanitizer",
	# "--with-memory-sanitizer",
	"--with-undefined-behavior-sanitizer",
]

EXTRA_CFLAGS = [
	"-DPy_DEBUG",
]

REQUIRED_PACKAGES = [
	"pkgconfig",
	"cython",
	"pytest",
	"delocate",
]

def cmd(shellcmd, cwd='.'):
	subprocess.call(shellcmd, shell=True, cwd=str(cwd))


def main():
	BUILD.mkdir(exist_ok=True)
	PYTHON_PREFIX.mkdir(exist_ok=True)
	DOWNLOADS.mkdir(exist_ok=True)
	cmd(f"wget {PYTHON_URL}", cwd=DOWNLOADS)
	cmd(f"tar xvf {PYTHON_ARCHIVE}", cwd=DOWNLOADS)
	DEBUG_FOLDER.mkdir(exist_ok=True)
	config_opts = " ".join(CONFIG_OPTIONS)
	cmd(f"../configure --prefix {PYTHON_PREFIX} {config_opts}", cwd=DEBUG_FOLDER)
	# extra_cflags = " ".join(EXTRA_CFLAGS)
	# cmd(f'make EXTRA_CFLAGS="{extra_cflags}"', cwd=DEBUG_FOLDER)
	cmd("make", cwd=DEBUG_FOLDER)
	cmd("make install", cwd=DEBUG_FOLDER)
	required_pkgs = " ".join(REQUIRED_PACKAGES)
	cmd("./python/bin/pip3 install --upgrade pip", cwd=CWD)
	cmd(f"./python/bin/pip3 install {required_pkgs}", cwd=CWD)

def install_memray():
	memray = DOWNLOADS / 'memray'
	cmd("git clone https://github.com/bloomberg/memray.git", cwd=DOWNLOADS)
	cmd(f"{PYTHON} setup.py build", cwd=memray)
	cmd(f"{PYTHON} setup.py install", cwd=memray)



if __name__ == '__main__':
	main()
	install_memray()

