cmake_minimum_required(VERSION 3.15...3.30)
project(${SKBUILD_PROJECT_NAME} VERSION ${SKBUILD_PROJECT_VERSION} LANGUAGES C CXX)

# ----------------------------------------------------------------------------
# Options (can be set via CMAKE_ARGS or pyproject.toml)
# ----------------------------------------------------------------------------
option(STATIC "Build with static libfaust" OFF)
option(INCLUDE_SNDFILE "Include sndfile/samplerate support" ON)

# Linux audio backends
option(ALSA "Enable ALSA support (Linux)" ON)
option(PULSE "Enable PulseAudio support (Linux)" OFF)
option(JACK "Enable JACK support (Linux/macOS)" OFF)

# Windows audio backends
option(ASIO "Enable ASIO support (Windows)" OFF)
option(WASAPI "Enable WASAPI support (Windows)" ON)
option(DSOUND "Enable DirectSound support (Windows)" OFF)

# ----------------------------------------------------------------------------
# Find Python
# ----------------------------------------------------------------------------
find_package(Python REQUIRED COMPONENTS Interpreter Development.Module)

# ----------------------------------------------------------------------------
# C++ Standard
# ----------------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
endif()

# ----------------------------------------------------------------------------
# Common paths
# ----------------------------------------------------------------------------
set(CYFAUST_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/cyfaust")
set(STATIC_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/static/cyfaust")
set(INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")
set(LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib")

# ----------------------------------------------------------------------------
# Common definitions and include directories
# ----------------------------------------------------------------------------
set(COMMON_DEFINITIONS INTERP_DSP=1)
set(COMMON_INCLUDE_DIRS ${INCLUDE_DIR})

if(INCLUDE_SNDFILE)
    list(APPEND COMMON_DEFINITIONS INCLUDE_SNDFILE=1 _SAMPLERATE=1)
endif()

# ----------------------------------------------------------------------------
# Platform-specific configuration
# ----------------------------------------------------------------------------
set(PLATFORM_LIBRARIES)
set(PLATFORM_LINK_FLAGS)
set(EXTRA_OBJECTS)

# RtAudio sources - gui_statics.cpp only needed for dynamic builds
# (static builds define GUI statics in faust_player.pxd)
set(RTAUDIO_SOURCES
    "${INCLUDE_DIR}/rtaudio/RtAudio.cpp"
    "${INCLUDE_DIR}/rtaudio/rtaudio_c.cpp"
)
if(NOT STATIC)
    list(APPEND RTAUDIO_SOURCES "${CYFAUST_SRC_DIR}/gui_statics.cpp")
endif()

if(APPLE)
    # macOS configuration
    list(APPEND COMMON_DEFINITIONS __MACOSX_CORE__)
    list(APPEND PLATFORM_LIBRARIES pthread)

    # Detect minimum macOS version
    if(NOT DEFINED CMAKE_OSX_DEPLOYMENT_TARGET)
        if(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
            set(CMAKE_OSX_DEPLOYMENT_TARGET "15.0")
        else()
            set(CMAKE_OSX_DEPLOYMENT_TARGET "10.9")
        endif()
    endif()

    # macOS frameworks
    find_library(COREFOUNDATION_FRAMEWORK CoreFoundation REQUIRED)
    find_library(COREAUDIO_FRAMEWORK CoreAudio REQUIRED)
    find_library(COREMIDI_FRAMEWORK CoreMIDI REQUIRED)
    list(APPEND PLATFORM_LIBRARIES
        ${COREFOUNDATION_FRAMEWORK}
        ${COREAUDIO_FRAMEWORK}
        ${COREMIDI_FRAMEWORK}
    )

    if(JACK)
        list(APPEND COMMON_DEFINITIONS __UNIX_JACK__)
        list(APPEND PLATFORM_LIBRARIES jack)
    endif()

    # Find Homebrew for sndfile/samplerate static libs
    if(INCLUDE_SNDFILE)
        execute_process(
            COMMAND brew --prefix
            OUTPUT_VARIABLE HOMEBREW_PREFIX
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
        if(HOMEBREW_PREFIX)
            list(APPEND COMMON_INCLUDE_DIRS "${HOMEBREW_PREFIX}/include")
            list(APPEND EXTRA_OBJECTS
                "${HOMEBREW_PREFIX}/lib/libFLAC.a"
                "${HOMEBREW_PREFIX}/lib/libogg.a"
                "${HOMEBREW_PREFIX}/lib/libvorbis.a"
                "${HOMEBREW_PREFIX}/lib/libvorbisenc.a"
                "${HOMEBREW_PREFIX}/lib/libvorbisfile.a"
                "${HOMEBREW_PREFIX}/lib/libopus.a"
                "${HOMEBREW_PREFIX}/lib/libmpg123.a"
                "${HOMEBREW_PREFIX}/lib/libmp3lame.a"
                "${HOMEBREW_PREFIX}/lib/libsndfile.a"
                "${HOMEBREW_PREFIX}/lib/libsamplerate.a"
            )
        endif()
    endif()

elseif(UNIX AND NOT APPLE)
    # Linux configuration
    list(APPEND PLATFORM_LIBRARIES pthread)
    add_compile_options(-include limits)

    if(ALSA)
        list(APPEND COMMON_DEFINITIONS __LINUX_ALSA__)
        list(APPEND PLATFORM_LIBRARIES asound)
    endif()

    if(PULSE)
        list(APPEND COMMON_DEFINITIONS __LINUX_PULSE__)
        list(APPEND PLATFORM_LIBRARIES pulse)
    endif()

    if(JACK)
        list(APPEND COMMON_DEFINITIONS __UNIX_JACK__)
        list(APPEND PLATFORM_LIBRARIES jack)
    endif()

elseif(WIN32)
    # Windows configuration
    list(APPEND PLATFORM_LIBRARIES winmm ole32)

    if(ASIO)
        list(APPEND COMMON_DEFINITIONS __WINDOWS_ASIO__)
        list(APPEND RTAUDIO_SOURCES
            "${INCLUDE_DIR}/rtaudio/asio/asio.cpp"
            "${INCLUDE_DIR}/rtaudio/asio/asiodrivers.cpp"
            "${INCLUDE_DIR}/rtaudio/asio/asiolist.cpp"
            "${INCLUDE_DIR}/rtaudio/asio/iasiothiscallresolver.cpp"
        )
    endif()

    if(WASAPI)
        list(APPEND COMMON_DEFINITIONS __WINDOWS_WASAPI__)
        list(APPEND PLATFORM_LIBRARIES ksuser mfplat mfuuid wmcodecdspuuid)
    endif()

    if(DSOUND)
        list(APPEND COMMON_DEFINITIONS __WINDOWS_DS__)
        list(APPEND PLATFORM_LIBRARIES dsound)
    endif()
endif()

# ----------------------------------------------------------------------------
# Static vs Dynamic libfaust linking
# ----------------------------------------------------------------------------
if(STATIC)
    if(WIN32)
        list(APPEND EXTRA_OBJECTS "${LIB_DIR}/static/libfaust.lib" "Ws2_32.lib")
    else()
        list(APPEND EXTRA_OBJECTS "${LIB_DIR}/static/libfaust.a")
    endif()
else()
    list(APPEND PLATFORM_LIBRARIES faust)
    link_directories(${LIB_DIR})
    if(UNIX)
        set(CMAKE_BUILD_RPATH "${LIB_DIR}")
        set(CMAKE_INSTALL_RPATH "${LIB_DIR}")
    endif()
endif()

# ----------------------------------------------------------------------------
# Helper function to create Cython extension
# ----------------------------------------------------------------------------
function(add_cython_extension NAME PYX_FILE)
    set(options WITH_RTAUDIO)
    set(oneValueArgs)
    set(multiValueArgs EXTRA_SOURCES DEFINITIONS)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Output C++ file in binary dir
    get_filename_component(PYX_NAME ${PYX_FILE} NAME_WE)
    set(CXX_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${PYX_NAME}.cpp")

    # Cython command to generate C++
    add_custom_command(
        OUTPUT ${CXX_OUTPUT}
        COMMAND Python::Interpreter -m cython
            -3 --cplus
            "${PYX_FILE}"
            --output-file "${CXX_OUTPUT}"
        DEPENDS ${PYX_FILE}
        COMMENT "Cythonizing ${PYX_FILE}"
        VERBATIM
    )

    # Collect sources
    set(SOURCES ${CXX_OUTPUT})
    if(ARG_WITH_RTAUDIO)
        list(APPEND SOURCES ${RTAUDIO_SOURCES})
    endif()
    if(ARG_EXTRA_SOURCES)
        list(APPEND SOURCES ${ARG_EXTRA_SOURCES})
    endif()

    # Create the module
    python_add_library(${NAME} MODULE ${SOURCES} WITH_SOABI)

    # Include directories
    target_include_directories(${NAME} PRIVATE ${COMMON_INCLUDE_DIRS})

    # Definitions
    target_compile_definitions(${NAME} PRIVATE ${COMMON_DEFINITIONS})
    if(ARG_DEFINITIONS)
        target_compile_definitions(${NAME} PRIVATE ${ARG_DEFINITIONS})
    endif()

    # Link libraries
    target_link_libraries(${NAME} PRIVATE ${PLATFORM_LIBRARIES})

    # Extra objects (static libraries)
    if(EXTRA_OBJECTS)
        target_link_libraries(${NAME} PRIVATE ${EXTRA_OBJECTS})
    endif()

    # Install
    install(TARGETS ${NAME} DESTINATION cyfaust)
endfunction()

# ----------------------------------------------------------------------------
# Build extensions (dynamic build - multiple modules)
# ----------------------------------------------------------------------------
if(NOT STATIC)
    # interp module - main interpreter with RtAudio
    add_cython_extension(interp
        "${CYFAUST_SRC_DIR}/interp.pyx"
        WITH_RTAUDIO
    )

    # common module
    add_cython_extension(common "${CYFAUST_SRC_DIR}/common.pyx")

    # signal module
    add_cython_extension(signal "${CYFAUST_SRC_DIR}/signal.pyx")

    # box module
    add_cython_extension(box "${CYFAUST_SRC_DIR}/box.pyx")

    # player module
    add_cython_extension(player "${CYFAUST_SRC_DIR}/player.pyx")

else()
    # Static build - single monolithic module
    # First, run cythonize on the static source
    set(STATIC_CXX_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/cyfaust.cpp")

    add_custom_command(
        OUTPUT ${STATIC_CXX_OUTPUT}
        COMMAND Python::Interpreter -m cython
            -3 --cplus
            "${STATIC_SRC_DIR}/cyfaust.pyx"
            --output-file "${STATIC_CXX_OUTPUT}"
        DEPENDS "${STATIC_SRC_DIR}/cyfaust.pyx"
        COMMENT "Cythonizing static cyfaust.pyx"
        VERBATIM
    )

    python_add_library(cyfaust MODULE
        ${STATIC_CXX_OUTPUT}
        ${RTAUDIO_SOURCES}
        WITH_SOABI
    )

    target_include_directories(cyfaust PRIVATE ${COMMON_INCLUDE_DIRS})
    target_compile_definitions(cyfaust PRIVATE ${COMMON_DEFINITIONS})
    target_link_libraries(cyfaust PRIVATE ${PLATFORM_LIBRARIES})
    if(EXTRA_OBJECTS)
        target_link_libraries(cyfaust PRIVATE ${EXTRA_OBJECTS})
    endif()

    install(TARGETS cyfaust DESTINATION cyfaust)
endif()

# ----------------------------------------------------------------------------
# Install Python files and resources
# ----------------------------------------------------------------------------
set(RESOURCES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/resources")

if(NOT STATIC)
    # Install __init__.py
    install(FILES "${CYFAUST_SRC_DIR}/__init__.py" DESTINATION cyfaust)

    # Install resources directory (Faust libraries and architectures)
    # Note: src/cyfaust/resources is a symlink to ../../resources
    install(DIRECTORY "${RESOURCES_DIR}/" DESTINATION cyfaust/resources)
else()
    # Static build uses different source location
    install(FILES "${STATIC_SRC_DIR}/__init__.py" DESTINATION cyfaust)
    install(DIRECTORY "${RESOURCES_DIR}/" DESTINATION cyfaust/resources)
endif()
