# Hell is a universal2 wheel

## The problem

cyfaust is built and tested on the following platforms:

- macos x86_64
- macos arm64
- linux (ubuntu 22.04) x86_64
- linux (debian) aarch64

In all of the above cyfaust

- builds without errors (`make`)
- passes unit tests without errors. (`make pytest`)
- builds wheels without errors (`make release`)
- passes wheel test without error (`scripts/wheel_mgr.py --test`)

Now when the above is done using a github action workflow, the same positive result occurs on the runner and the system generates, in the case of `macos-latest`, a `universal2` wheel which once downloaded onto a macos M1 `arm64` system can be installed into a `virtualenv` and tested for universality, i.e. that it contains both arm64 and x86_64 code, (which it passes), but if one tries to import it, the following error occurs:

```bash
ImportError: dlopen($HOME/venv/lib/python3.11/site-packages/cyfaust/interp.cpython-311-darwin.so, 0x0002): symbol not found in flat namespace '__Z12generateSHA1RKNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEE'
```
