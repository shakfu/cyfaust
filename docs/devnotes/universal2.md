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

## The Solution

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

