#!/usr/bin/env python3

import os
import platform
import sys


def build_wheel(universal=False):
    """wheel build config (special cases macos wheels) for github runners
    
    ref: https://github.com/pypa/cibuildwheel/blob/main/cibuildwheel/macos.py
    """
    assert sys.version_info.minor >= 8, "applies to python >= 3.8"

    _platform = platform.system()
    _arch = platform.machine()
    _cmd = "python3 setup.py bdist_wheel"

    if _platform == "Darwin":
        _min_osx_ver = "10.9"

        if _arch == 'arm64' and not universal:
            _min_osx_ver = "11.0"

        if universal:
            _prefix = (f"ARCHFLAGS='-arch arm64 -arch x86_64' "
                       f"_PYTHON_HOST_PLATFORM='macosx-{_min_osx_ver}-universal2'")
        else:
            _prefix = (f"ARCHFLAGS='-arch {_arch}' "
                       f"_PYTHON_HOST_PLATFORM='macosx-{_min_osx_ver}-{_arch}'")

        _cmd = " ".join([_prefix, _cmd])

    os.system(_cmd)

if __name__ == '__main__':
    build_wheel()
