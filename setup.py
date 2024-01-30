import os
import platform
import subprocess

from Cython.Build import cythonize
from setuptools import Extension, find_namespace_packages, setup

# ----------------------------------------------------------------------------
# helper funcs


def getenv(key: str, default: bool = False) -> bool:
    """convert '0','1' env values to bool {True, False}"""
    return bool(int(os.getenv(key, default)))


def get_min_osx_ver(platform, arch):
    min_osx_ver = os.getenv("MACOSX_DEPLOYMENT_TARGET")
    if not min_osx_ver:
        min_osx_ver = "10.9"
        if platform == "Darwin" and arch == "arm64":
            min_osx_ver = "11.0"
    return min_osx_ver


# ----------------------------------------------------------------------------
# VARS

VERSION = "0.0.4"

# ----------------------------------------------------------------------------
# OPTIONS (to be set as environment variables)

# set cyfaust static or dynamic build here
STATIC = getenv("STATIC")

# sndfile (+ libsamplerate)
INCLUDE_SNDFILE = getenv("INCLUDE_SNDFILE", default=False)

# rtaudio apis
# linux
ALSA = getenv("ALSA", default=True)
PULSE = getenv("PULSE")
JACK = getenv("JACK")
# windows
ASIO = getenv("ASIO")
WASAPI = getenv("WASAPI", default=True)
DSOUND = getenv("DSOUND")

# ----------------------------------------------------------------------------
# COMMON

PLATFORM = platform.system()
ARCH = platform.machine()

CWD = os.getcwd()

# local directories
LIB = os.path.join(CWD, "lib")
INCLUDE = os.path.join(CWD, "include")

# common configuration
INCLUDE_DIRS = [INCLUDE]
LIBRARY_DIRS = [LIB]
EXTRA_OBJECTS = []
EXTRA_LINK_ARGS = []
LIBRARIES = []
DEFINE_MACROS = [("INTERP_DSP", 1)]
EXTRA_COMPILE_ARGS = []
RTAUDIO_SRC = [
    "include/rtaudio/RtAudio.cpp",
    "include/rtaudio/rtaudio_c.cpp",
]

# ----------------------------------------------------------------------------
# CONDITIONAL CONFIGURATION

if STATIC:
    if PLATFORM == "Windows":
        EXTRA_OBJECTS.append("lib/static/libfaust.lib")
        EXTRA_OBJECTS.extend([
            # "msvcrt.lib",
            "Ws2_32.lib",
        ])
        # EXTRA_COMPILE_ARGS.append("/MT")
    else:
        EXTRA_OBJECTS.append("lib/static/libfaust.a")

else:
    LIBRARIES.append("faust")
    if PLATFORM in ["Linux", "Darwin"]:
        EXTRA_LINK_ARGS.append("-Wl,-rpath," + LIB)  # add local rpath

if INCLUDE_SNDFILE:
    DEFINE_MACROS.append(("INCLUDE_SNDFILE", 1))
    EXTRA_OBJECTS.extend(
        [
            "lib/static/libsndfile.a",
            "lib/static/libsamplerate.a",
        ]
    )


# platform specific configuration
if PLATFORM in ["Darwin", "Linux"]:
    LIBRARIES.append("pthread")

if PLATFORM == "Darwin":
    MIN_OSX_VER = get_min_osx_ver(PLATFORM, ARCH)
    os.environ["MACOSX_DEPLOYMENT_TARGET"] = MIN_OSX_VER
    EXTRA_COMPILE_ARGS.extend(["-std=c++11", "-stdlib=libc++"])
    EXTRA_LINK_ARGS.append(f"-mmacosx-version-min={MIN_OSX_VER}")
    DEFINE_MACROS.append(("__MACOSX_CORE__", None))  # rtaudio for macos
    if JACK:
        DEFINE_MACROS.append(("__UNIX_JACK__", None))
        LIBRARIES.append("jack")
    os.environ["LDFLAGS"] = " ".join(
        ["-framework CoreFoundation", "-framework CoreAudio"]
    )

elif PLATFORM == "Linux":
    os.environ["CPPFLAGS"] = "-include limits"
    EXTRA_COMPILE_ARGS.append("-std=c++11")
    if ALSA:
        DEFINE_MACROS.append(("__LINUX_ALSA__", None))
        LIBRARIES.append("asound")
    if PULSE:
        DEFINE_MACROS.append(("__LINUX_PULSE__", None))
        LIBRARIES.append("pulse")
    if JACK:
        DEFINE_MACROS.append(("__UNIX_JACK__", None))
        LIBRARIES.append("jack")

elif PLATFORM == "Windows":
    LIBRARIES.extend([
        "winmm",
        "ole32",
    ])
    if ASIO:
        DEFINE_MACROS.append(("__WINDOWS_ASIO__", None))
        RTAUDIO_SRC.extend([
            "include/rtaudio/asio/asio.cpp",
            "include/rtaudio/asio/asiodrivers.cpp",
            "include/rtaudio/asio/asiolist.cpp",
            "include/rtaudio/asio/iasiothiscallresolver.cpp",
        ])
    if WASAPI:
        DEFINE_MACROS.append(("__WINDOWS_WASAPI__", None))
        LIBRARIES.extend([
            "ksuser",
            "mfplat",
            "mfuuid",
            "wmcodecdspuuid",
        ])
    if DSOUND:
        DEFINE_MACROS.append(("__WINDOWS_DS__", None))
        LIBRARIES.append("dsound")

else:
    raise SystemExit(f"platform '{PLATFORM}' not currently supported")


def mk_extension(name, sources, define_macros=None):
    return Extension(
        name=name,
        sources=sources,
        define_macros=define_macros if define_macros else [],
        include_dirs=INCLUDE_DIRS,
        libraries=LIBRARIES,
        library_dirs=LIBRARY_DIRS,
        extra_objects=EXTRA_OBJECTS,
        extra_compile_args=EXTRA_COMPILE_ARGS,
        extra_link_args=EXTRA_LINK_ARGS,
        language="c++",
    )


# ----------------------------------------------------------------------------
# COMMON SETUP CONFIG

common = {
    "name": "cyfaust",
    "version": VERSION,
    "description": "A cython wrapper of the faust interpreter with rtaudio.",
    "python_requires": ">=3.8",
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
        mk_extension(
            "cyfaust.cyfaust",
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
        package_dir={"": "src/static"},
        packages=find_namespace_packages(
            where="src/static",
            include=["cyfaust*"],
        ),
    )

# ----------------------------------------------------------------------------
# DEFAULT DYNAMIC BUILD VARIANT

else:
    with open("MANIFEST.in", "w") as f:
        f.write("graft src/cyfaust/resources\n")
        f.write("exclude src/cyfaust/*.cpp\n")

    extensions = [
        mk_extension(
            "cyfaust.interp",
            sources=["src/cyfaust/interp.pyx"] + RTAUDIO_SRC,
            define_macros=DEFINE_MACROS,
        ),
        mk_extension("cyfaust.common", ["src/cyfaust/common.pyx"]),
        mk_extension("cyfaust.signal", ["src/cyfaust/signal.pyx"]),
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
