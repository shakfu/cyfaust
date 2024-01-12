import os
import platform
import subprocess
from setuptools import Extension, setup
from Cython.Build import cythonize

# ----------------------------------------------------------------------------
# CONFIGURABLE VARIABLES

VERSION="0.0.2"


# ----------------------------------------------------------------------------
# OPTIONS

# convert '0','1' env values to bool
getenv = lambda key: bool(int(os.getenv(key, False)))

STATIC = getenv("STATIC")       # set static or dynamic build here
SANITIZE = getenv("SANITIZE")   # enable address/leak sanitizer 

# ----------------------------------------------------------------------------
# COMMON

PLATFORM = platform.system()
CWD = os.getcwd()
LIB = os.path.join(CWD, 'lib')
INCLUDE = os.path.join(CWD, 'include')

# common configuration
INCLUDE_DIRS = [INCLUDE]
LIBRARY_DIRS = [LIB]
EXTRA_OBJECTS = []
EXTRA_LINK_ARGS = []
LIBRARIES = ["pthread"]
DEFINE_MACROS = [("INTERP_DSP", 1)]
EXTRA_COMPILE_ARGS = ['-std=c++11']
RTAUDIO_SRC = [
    "include/rtaudio/RtAudio.cpp",
    "include/rtaudio/rtaudio_c.cpp",
]

# ----------------------------------------------------------------------------
# CONDITIONAL CONFIGURATION

if SANITIZE: # FIXME: not working for now !!
    os.environ["ASAN_OPTIONS"]="detect_leaks=1"
    EXTRA_COMPILE_ARGS.append("-fsanitize=address")
    EXTRA_LINK_ARGS.append("-static-libsan")


if STATIC:
    EXTRA_OBJECTS.append('lib/libfaust.a')
else:
    EXTRA_LINK_ARGS.append('-Wl,-rpath,' + LIB) # add local rpath


# platform specific  configuration
if PLATFORM == 'Darwin':
    EXTRA_LINK_ARGS.append('-mmacosx-version-min=13.6')
    DEFINE_MACROS.append(("__MACOSX_CORE__", None)) # rtaudio for macos
    if not STATIC:
        LIBRARIES.append('faust.2')
    os.environ['LDFLAGS'] = " ".join([
        "-framework CoreFoundation",
        "-framework CoreAudio"
    ])
elif PLATFORM == 'Linux':
    os.environ['CPPFLAGS'] = '-include limits'
    DEFINE_MACROS.append(("__LINUX_ALSA__", None))
    LIBRARIES.append("asound")
    if not STATIC:
        LIBRARIES.append("faust")


def mk_extension(name, sources, define_macros=None):
    return Extension(
        name=name,
        sources=sources,
        define_macros=define_macros if define_macros else [],
        include_dirs = INCLUDE_DIRS,
        libraries = LIBRARIES,
        library_dirs = LIBRARY_DIRS,
        extra_objects = EXTRA_OBJECTS,
        extra_compile_args = EXTRA_COMPILE_ARGS,
        extra_link_args = EXTRA_LINK_ARGS,
        language="c++",
        # py_limited_api=True,
    )

# ----------------------------------------------------------------------------
# STATIC BUILD VARIANT

if STATIC:

    # forces cythonize in this case
    subprocess.call("cythonize cyfaust.pyx", cwd="src/static/cyfaust", shell=True)

    with open("MANIFEST.in", "w") as f:
        f.write("graft src/static/cyfaust/resources\n")
        f.write("exclude src/static/cyfaust/*.cpp\n")

    extensions = [
        mk_extension("cyfaust.cyfaust", 
            sources=["src/static/cyfaust/cyfaust.pyx"] + RTAUDIO_SRC,
            define_macros=DEFINE_MACROS,
        ),
    ]

    setup(
        name='cyfaust',
        version=VERSION,
        ext_modules=cythonize(
            extensions,
            language_level="3",
        ),
        package_dir = {"cyfaust": "src/static/cyfaust"},
        packages=['cyfaust'],
        include_package_data=True
    )

# ----------------------------------------------------------------------------
# DEFAULT DYNAMIC BUILD VARIANT

else:

    with open("MANIFEST.in", "w") as f:
        f.write("graft src/cyfaust/resources\n")
        f.write("exclude src/cyfaust/*.cpp\n")

    extensions = [
        mk_extension("cyfaust.interp", 
            sources=["src/cyfaust/interp.pyx"] + RTAUDIO_SRC,
            define_macros=DEFINE_MACROS,
        ),
        mk_extension("cyfaust.common", ["src/cyfaust/common.pyx"]),
        mk_extension("cyfaust.signal",["src/cyfaust/signal.pyx"]),
        mk_extension("cyfaust.box", ["src/cyfaust/box.pyx"]),
    ]

    setup(
        name='cyfaust',
        version=VERSION,
        ext_modules=cythonize(
            extensions,
            language_level="3",
        ),
        package_dir = {"cyfaust": "src/cyfaust"},
        packages=['cyfaust'],
        include_package_data=True
    )
