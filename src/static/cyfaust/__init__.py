# cyfaust - Python bindings for the Faust DSP language
#
# This module provides Python access to:
#   - Faust DSP compilation (interpreter or LLVM backend)
#   - Box and Signal APIs for programmatic DSP construction
#   - RtAudio integration for real-time audio playback
#   - Sound file players for audio file processing

# Import everything from the compiled Cython module
from .cyfaust import *

# Import specific items we need to reference
from .cyfaust import get_version

# -----------------------------------------------------------------------------
# LLVM Backend Detection
# -----------------------------------------------------------------------------
# Check if LLVM backend classes are available (built with CMAKE_ARGS="-DLLVM=ON")
try:
    from .cyfaust import LlvmDspFactory, LlvmDsp
    LLVM_BACKEND = True
except ImportError:
    LLVM_BACKEND = False

# Version info
__version__ = get_version()

# Explicitly define key exports for documentation/IDE support
__all__ = [
    # Version
    '__version__',
    'get_version',
    'LLVM_BACKEND',

    # Common utilities
    'PACKAGE_RESOURCES',
    'ParamArray',
    'generate_sha1',
    'expand_dsp_from_file',
    'expand_dsp_from_string',
    'generate_auxfiles_from_file',
    'generate_auxfiles_from_string',

    # Interpreter backend (always available)
    'InterpreterDspFactory',
    'InterpreterDsp',
    'MetaCollector',
    'RtAudioDriver',
    'get_dsp_factory_from_sha_key',
    'create_dsp_factory_from_file',
    'create_dsp_factory_from_string',
    'create_dsp_factory_from_signals',
    'create_dsp_factory_from_boxes',
    'delete_all_dsp_factories',
    'get_all_dsp_factories',
    'start_multithreaded_access_mode',
    'stop_multithreaded_access_mode',
    'read_dsp_factory_from_bitcode',
    'read_dsp_factory_from_bitcode_file',

    # Box API
    'Box',
    'BoxVector',
    'Interval',
    'create_source_from_boxes',
    'create_lib_context',
    'destroy_lib_context',
    'dsp_to_boxes',
    'boxes_to_signals',

    # Signal API
    'Signal',
    'SignalVector',
    'create_source_from_signals',
    'simplify_to_normal_form',

    # Sound players
    'SoundBasePlayer',
    'SoundMemoryPlayer',
    'SoundDtdPlayer',
    'SoundPositionManager',
    'create_memory_player',
    'create_dtd_player',
    'create_position_manager',
]

# Add LLVM exports to __all__ if available
if LLVM_BACKEND:
    __all__.extend([
        # LLVM backend classes
        'LlvmDspFactory',
        'LlvmDsp',
        'LlvmRtAudioDriver',

        # LLVM-specific utilities
        'get_dsp_machine_target',
        'register_foreign_function',

        # LLVM factory functions
        'llvm_get_version',
        'llvm_get_dsp_factory_from_sha_key',
        'llvm_create_dsp_factory_from_file',
        'llvm_create_dsp_factory_from_string',
        'llvm_create_dsp_factory_from_signals',
        'llvm_create_dsp_factory_from_boxes',
        'llvm_delete_all_dsp_factories',
        'llvm_get_all_dsp_factories',
        'llvm_start_multithreaded_access_mode',
        'llvm_stop_multithreaded_access_mode',
        'llvm_read_dsp_factory_from_bitcode',
        'llvm_read_dsp_factory_from_bitcode_file',
        'llvm_read_dsp_factory_from_ir',
        'llvm_read_dsp_factory_from_ir_file',
        'llvm_read_dsp_factory_from_machine',
        'llvm_read_dsp_factory_from_machine_file',
    ])
