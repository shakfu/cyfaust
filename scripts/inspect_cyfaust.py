#!/usr/bin/env python3

import os, sys

BUILD_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "build")
os.chdir(BUILD_PATH)
sys.path.insert(0, BUILD_PATH)

import inspect

import cyfaust

classes = []
funcs = []
other = []

for name, obj in inspect.getmembers(cyfaust):
    if inspect.isclass(obj):
        klass = getattr(cyfaust, name)
        methods = [k for k,v in inspect.getmembers(klass) if not k.startswith('__')]
        classes.append((name, methods))
    elif inspect.isfunction(obj):
        funcs.append(name)
    else:
        other.append(name)


print(classes)