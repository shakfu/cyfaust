import os
import platform
from setuptools import Extension, setup
from Cython.Build import cythonize

WITH_DYLIB = os.getenv("WITH_DYLIB", True)

INCLUDE_DIRS = []
LIBRARY_DIRS = []
EXTRA_OBJECTS = []
EXTRA_LINK_ARGS = ['-mmacosx-version-min=13.6']
LIBRARIES = ["pthread"]

if WITH_DYLIB:
    LIBRARIES.append('faust.2')
else:
    EXTRA_OBJECTS.append('lib/libfaust.a')

CWD = os.getcwd()
LIB = os.path.join(CWD, 'lib')
LIBRARY_DIRS.append(LIB)
INCLUDE_DIRS.append(os.path.join(CWD, 'include'))
EXTRA_COMPILE_ARGS = ['-std=c++11']

# add local rpath
if platform.system() == 'Darwin' and WITH_DYLIB:
    EXTRA_LINK_ARGS.append('-Wl,-rpath,'+LIB)

os.environ['LDFLAGS'] = " ".join([
    "-framework CoreFoundation",
    "-framework CoreAudio"
])

extensions = [
    Extension("cyfaust.interp", 
        [
            "src/cyfaust/interp.pyx", 
            "include/rtaudio/RtAudio.cpp",
            "include/rtaudio/rtaudio_c.cpp",
        ],
        define_macros = [
            ("INTERP_DSP", 1),
            ("__MACOSX_CORE__", None)
        ],
        include_dirs = INCLUDE_DIRS,
        libraries = LIBRARIES,
        library_dirs = LIBRARY_DIRS,
        extra_objects = EXTRA_OBJECTS,
        extra_compile_args = EXTRA_COMPILE_ARGS,
        extra_link_args = EXTRA_LINK_ARGS,
    ),
    Extension("cyfaust.common", ["src/cyfaust/common.pyx"],
        define_macros = [],
        include_dirs = INCLUDE_DIRS,
        libraries = LIBRARIES,
        library_dirs = LIBRARY_DIRS,
        extra_objects = EXTRA_OBJECTS,
        extra_compile_args = EXTRA_COMPILE_ARGS,
        extra_link_args = EXTRA_LINK_ARGS,
    ),
    Extension("cyfaust.signal", ["src/cyfaust/signal.pyx"],
        define_macros = [],
        include_dirs = INCLUDE_DIRS,
        libraries = LIBRARIES,
        library_dirs = LIBRARY_DIRS,
        extra_objects = EXTRA_OBJECTS,
        extra_compile_args = EXTRA_COMPILE_ARGS,
        extra_link_args = EXTRA_LINK_ARGS,
    ),
    Extension("cyfaust.box", ["src/cyfaust/box.pyx"],
        define_macros = [],
        include_dirs = INCLUDE_DIRS,
        libraries = LIBRARIES,
        library_dirs = LIBRARY_DIRS,
        extra_objects = EXTRA_OBJECTS,
        extra_compile_args = EXTRA_COMPILE_ARGS,
        extra_link_args = EXTRA_LINK_ARGS,
    ),
]

setup(
    name='cyfaust',
    version='0.0.1',
    ext_modules=cythonize(
        extensions,
        language_level="3str",
    ),
    package_dir = {"cyfaust": "src/cyfaust"},
    packages=['cyfaust']
)
