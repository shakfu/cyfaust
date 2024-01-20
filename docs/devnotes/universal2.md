# Hell is an uninvited universal2 wheel

## The problem

This project, cyfaust, is built and tested on the following platforms:

- macos x86_64
- macos arm64
- linux (ubuntu 22.04) x86_64
- linux (debian) aarch64

In all of the above, cyfaust

- builds without errors (`make`)
- passes unit tests without errors. (`make pytest`)
- builds wheels without errors (`make release`)
- passes wheel test without error (`scripts/wheel_mgr.py --test`)

Now when the above is done using a github action workflow, the same positive result occurs on the runner, yet the runner builds, in the case of `macos-latest`, a `universal2` wheel which once downloaded onto a macos M1 `arm64` system can be installed into a `virtualenv` and tested for universality, i.e. that it contains both arm64 and x86_64 code, (which it passes), but if one tries to import it, the following error occurs:

```bash
ImportError: dlopen($HOME/venv/lib/python3.11/site-packages/cyfaust/interp.cpython-311-darwin.so, 0x0002): symbol not found in flat namespace '__Z12generateSHA1RKNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEE'
```

## Problem Analysis

- The runner is an x86_64 machine

- It has a universal (dual architecture) python installed which always compiles wheels as `universal2` (it is not clear how to switch this off)

- When it builds the wheel it becomes `cyfaust-0.0.2-cp311-cp311-macosx_10_9_universal2.whl`.

- The problem is that during the build process  `delocate` fixed the `libfaust.dylib` as x86_64 and yet the rest of the wheel is built as a `universal2`

- When the wheel is downloaded onto an arm64 machine it runs except for `libfaust.dylib` which is the wrong architecture and hence the error above.

## Sketching the Solution

One of 

1. Compile binary dependencies (`libfaust.a`) as universal binaries

	OR

2. Force the wheel on the runner to be compiled as its native architecture: x86_64.

Now (2) should be easy, but somehow it isn't...

What to do?


## Tried the following:

1. Prefix `ARCHFLAGS='-arch {ARCH}` to `python3 setup.py`

	```bash
	ARCHFLAGS='-arch x86_64' python3 setup.py bdist_wheel
	```

	This **does** force the contents of the wheel to be `{ARCH}` but does not change its tag which remains `universal2`.


2. Set the tag using `--plat-name {tag-name}` to `python3 setup.py bdist_wheel`:

	```bash
	python3 setup.py bdist_wheel --plat-name macosx_13_x86_64
	```

	This doesn't work and gives an error while testing the wheel:

	```bash
	ERROR: cyfaust-0.0.3-cp311-cp311-macosx_13_x86_64.whl is not a supported wheel on this platform.
	```

What to do?

## Actual Solution

Asked about the above case [here](https://github.com/pypa/wheel/issues/573#issuecomment-1902083893)

@henryiii was kind enough to point in the right direction of how cibuildwheel solved this issue:

> You are building with a universal2 build of Python. Setuptools will ask Python what it was built as and uses that. You can set `_PYTHON_HOST_PLATFORM` (along with `ARCHFLAGS`) to override this. (Though cibuildwheel does all this for you, FYI, [code here](https://github.com/pypa/cibuildwheel/blob/93542c397cfe940bcbb8f1eff5c37d345ea16653/cibuildwheel/macos.py#L247-L260)).

The code below is illustrative of how to solve this:

```python
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
```



