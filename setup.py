import os
import platform
import subprocess

from Cython.Build import cythonize
from setuptools import Extension, find_namespace_packages, setup

# ----------------------------------------------------------------------------
# helper funcs

def getenv(key):
    """convert '0','1' env values to bool {True, False}"""
    return bool(int(os.getenv(key, False)))
 
 

# ----------------------------------------------------------------------------
# VARS

VERSION="0.0.2"


# ----------------------------------------------------------------------------
# OPTIONS (to be set as environment variables)



STATIC = getenv("STATIC")       # set static or dynamic build here

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
EXTRA_COMPILE_ARGS = []
RTAUDIO_SRC = [
    "include/rtaudio/RtAudio.cpp",
    "include/rtaudio/rtaudio_c.cpp",
]

# ----------------------------------------------------------------------------
# CONDITIONAL CONFIGURATION

if STATIC:
    EXTRA_OBJECTS.append('lib/static/libfaust.a')
else:
    LIBRARIES.append('faust')
    EXTRA_LINK_ARGS.append('-Wl,-rpath,' + LIB) # add local rpath


# platform specific configuration
if PLATFORM == 'Darwin':
    # EXTRA_COMPILE_ARGS.append("-std=c++11")
    EXTRA_COMPILE_ARGS.extend(["-std=c++11", "-stdlib=libc++"])
    EXTRA_LINK_ARGS.append('-mmacosx-version-min=10.9')
    DEFINE_MACROS.append(("__MACOSX_CORE__", None)) # rtaudio for macos
    os.environ['LDFLAGS'] = " ".join([
        "-framework CoreFoundation",
        "-framework CoreAudio"
    ])
elif PLATFORM == 'Linux':
    os.environ['CPPFLAGS'] = '-include limits'
    EXTRA_COMPILE_ARGS.append("-std=c++11")
    DEFINE_MACROS.append(("__LINUX_ALSA__", None))
    LIBRARIES.append("asound")
else:
    raise SystemExit(f"plaform '{PLATFORM}' not currently supported")


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
    )


# ----------------------------------------------------------------------------
# COMMON SETUP CONFIG

common = {
   "name": "cyfaust",
   "version": VERSION,
   "include_package_data": True,
}

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
        **common,
        ext_modules=cythonize(
            extensions,
            language_level="3str",
        ),
        package_dir = {"": "src/static"},
        packages=find_namespace_packages(
            where="src/static", 
            include=["cyfaust*"],
        )
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
        **common,
        ext_modules=cythonize(
            extensions,
            language_level="3str",
        ),
        package_dir={"": "src"},
        packages=find_namespace_packages(where="src", include=["cyfaust*"]),
    )
