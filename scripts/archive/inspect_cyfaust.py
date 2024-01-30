#!/usr/bin/env python3

import inspect
import os
import sys
from pprint import pprint

BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "build")
sys.path.insert(0, BUILD_PATH)


def inspect_module(module):
    classes = []
    funcs = []
    other = []

    for name, obj in inspect.getmembers(module):
        if inspect.isclass(obj):
            klass = getattr(module, name)
            methods = [k for k,v in inspect.getmembers(klass) if not k.startswith('__')]
            classes.append((name, methods))
        elif inspect.isfunction(obj):
            funcs.append(name)
        else:
            other.append(name)

    pprint(classes)

def dump(module):
    print('-'*79)
    print(module.__name__)
    print()
    inspect_module(module)

try:
    from cyfaust import cyfaust
    dump(cyfaust)
except (ModuleNotFoundError, ImportError):
    from cyfaust import interp
    from cyfaust import signal
    from cyfaust import box
    for mod in [interp, signal, box]:
        dump(mod)

else:
    print("cyfaust has not been built, try `make`")

