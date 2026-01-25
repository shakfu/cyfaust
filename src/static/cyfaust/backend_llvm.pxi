# backend_llvm.pxi - LLVM backend implementation for cyfaust
#
# This file contains the Python wrapper classes for the Faust LLVM backend.
# It is included conditionally in cyfaust.pyx when building with LLVM support.
#
# The LLVM backend compiles Faust DSP code to native machine code via LLVM JIT,
# providing much faster execution than the interpreter backend.
#
# NOTE: This file is included via `include "backend_llvm.pxi"` in cyfaust.pyx
# The following are already imported in the parent file:
#   - libc.stdlib (malloc, free)
#   - libcpp.string, libcpp.vector, libcpp.map
#   - faust_box as fb, faust_signal as fs, faust_gui as fg

# Import LLVM backend declarations (LLVM-specific)
from . cimport faust_llvm as fl

# -----------------------------------------------------------------------------
# LLVM-specific utility functions
# -----------------------------------------------------------------------------

def get_dsp_machine_target() -> str:
    """Get the target (triple + CPU) of the current machine.

    Returns:
        str: The LLVM target triple, e.g., 'arm64-apple-darwin24.6.0'
    """
    return fl.getDSPMachineTarget().decode()

def register_foreign_function(str function_name):
    """Register a custom foreign function in libfaust.

    The function must be compiled and exported by the host binary running
    the DSP code, so that it can be used in DSP code via the 'ffunction' primitive.

    Note: All needed functions must be registered before compiling DSP code.

    Args:
        function_name: The function name to make available in DSP code
    """
    fl.registerForeignFunction(function_name.encode('utf8'))

# -----------------------------------------------------------------------------
# LlvmDspFactory - LLVM DSP factory class
# -----------------------------------------------------------------------------

cdef class LlvmDspFactory:
    """LLVM DSP factory class.

    Creates DSP instances compiled to native machine code via LLVM JIT.
    Much faster execution than the interpreter backend.

    Key differences from InterpreterDspFactory:
        - Factory creation requires 'target' and 'opt_level' parameters
        - Use get_dsp_machine_target() module function to query current machine target
        - Supports additional serialization formats: LLVM IR, machine code, object code
    """

    cdef fl.llvm_dsp_factory* ptr
    cdef bint ptr_owner
    cdef set instances

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False
        self.instances = set()

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            instances = self.instances.copy()
            while instances:
                i = instances.pop()
                i.delete()
            fl.deleteDSPFactory(self.ptr)
            self.ptr = NULL

    # -------------------------------------------------------------------------
    # Factory properties
    # -------------------------------------------------------------------------

    def get_name(self) -> str:
        """Return factory name."""
        return self.ptr.getName().decode()

    # Note: getTarget() method exists in header but symbol not in static library
    # Use get_dsp_machine_target() module function instead for current machine target

    def get_sha_key(self) -> str:
        """Return factory SHA key."""
        return self.ptr.getSHAKey().decode()

    def get_dsp_code(self) -> str:
        """Return factory expanded DSP code."""
        return self.ptr.getDSPCode().decode()

    def get_compile_options(self) -> str:
        """Return factory compile options."""
        return self.ptr.getCompileOptions().decode()

    def get_library_list(self) -> list[str]:
        """Get the Faust DSP factory list of library dependancies."""
        return self.ptr.getLibraryList()

    def get_include_pathnames(self) -> list[str]:
        """Get the list of all used includes."""
        return self.ptr.getIncludePathnames()

    def get_warning_messages(self) -> list[str]:
        """Get warning messages list for a given compilation."""
        return [msg.decode() for msg in self.ptr.getWarningMessages()]

    # -------------------------------------------------------------------------
    # DSP instance creation
    # -------------------------------------------------------------------------

    def create_dsp_instance(self) -> LlvmDsp:
        """Create a new DSP instance.

        The factory keeps track of all allocated instances.
        """
        cdef fl.llvm_dsp* dsp = self.ptr.createDSPInstance()
        instance = LlvmDsp.from_ptr(dsp)
        self.instances.add(instance)
        return instance

    def class_init(self, int sample_rate):
        """Initialize the static tables for all factory instances.

        Args:
            sample_rate: The sample rate in Hz
        """
        self.ptr.classInit(sample_rate)

    # -------------------------------------------------------------------------
    # Memory manager
    # -------------------------------------------------------------------------

    def set_memory_manager(self, object manager):
        """Set a custom memory manager to be used when creating instances.

        Args:
            manager: A memory manager object (currently None to reset to default)
        """
        if manager is None:
            self.ptr.setMemoryManager(NULL)
        else:
            raise NotImplementedError("Custom memory managers not yet supported in Python interface")

    def get_memory_manager(self):
        """Return the currently set custom memory manager.

        Returns:
            None if no custom manager is set
        """
        cdef fl.dsp_memory_manager* manager = self.ptr.getMemoryManager()
        if manager == NULL:
            return None
        else:
            raise NotImplementedError("Custom memory managers not yet fully supported in Python interface")

    # -------------------------------------------------------------------------
    # Bitcode serialization (base64 encoded LLVM bitcode)
    # -------------------------------------------------------------------------

    def write_to_bitcode(self) -> str:
        """Write factory into a base64 encoded LLVM bitcode string."""
        return fl.writeDSPFactoryToBitcode(self.ptr).decode()

    def write_to_bitcode_file(self, str bit_code_path) -> bool:
        """Write factory into a LLVM bitcode file.

        Args:
            bit_code_path: Path to the output bitcode file

        Returns:
            True on success, False on failure
        """
        return fl.writeDSPFactoryToBitcodeFile(self.ptr, bit_code_path.encode('utf8'))

    # -------------------------------------------------------------------------
    # LLVM IR serialization (textual format)
    # -------------------------------------------------------------------------

    def write_to_ir(self) -> str:
        """Write factory into a LLVM IR (textual) string."""
        return fl.writeDSPFactoryToIR(self.ptr).decode()

    def write_to_ir_file(self, str ir_code_path) -> bool:
        """Write factory into a LLVM IR (textual) file.

        Args:
            ir_code_path: Path to the output IR file

        Returns:
            True on success, False on failure
        """
        return fl.writeDSPFactoryToIRFile(self.ptr, ir_code_path.encode('utf8'))

    # -------------------------------------------------------------------------
    # Machine code serialization (base64 encoded native code)
    # -------------------------------------------------------------------------

    def write_to_machine(self, str target="") -> str:
        """Write factory into a base64 encoded machine code string.

        Args:
            target: LLVM target (empty string = current machine settings)

        Returns:
            Base64 encoded machine code string
        """
        return fl.writeDSPFactoryToMachine(self.ptr, target.encode('utf8')).decode()

    def write_to_machine_file(self, str machine_code_path, str target="") -> bool:
        """Write factory into a machine code file.

        Args:
            machine_code_path: Path to the output machine code file
            target: LLVM target (empty string = current machine settings)

        Returns:
            True on success, False on failure
        """
        return fl.writeDSPFactoryToMachineFile(
            self.ptr,
            machine_code_path.encode('utf8'),
            target.encode('utf8')
        )

    # -------------------------------------------------------------------------
    # Object code serialization
    # -------------------------------------------------------------------------

    def write_to_objectcode_file(self, str object_code_path, str target="") -> bool:
        """Write factory into an object code file (.o).

        Args:
            object_code_path: Path to the output object file
            target: LLVM target (empty string = current machine settings)

        Returns:
            True on success, False on failure
        """
        return fl.writeDSPFactoryToObjectcodeFile(
            self.ptr,
            object_code_path.encode('utf8'),
            target.encode('utf8')
        )

    # -------------------------------------------------------------------------
    # Static factory methods
    # -------------------------------------------------------------------------

    @staticmethod
    cdef LlvmDspFactory from_ptr(fl.llvm_dsp_factory* ptr, bint owner=False):
        """Wrap external factory from pointer."""
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        factory.ptr = ptr
        factory.ptr_owner = owner
        return factory

    @staticmethod
    def from_sha_key(str sha_key) -> LlvmDspFactory:
        """Get factory from SHA key (if in cache)."""
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.getDSPFactoryFromSHAKey(sha_key.encode())
        if factory.ptr == NULL:
            return None
        return factory

    @staticmethod
    def from_file(str filepath, str target="", int opt_level=-1, *args) -> LlvmDspFactory:
        """Create an LLVM DSP factory from a DSP file.

        Args:
            filepath: Path to the DSP source file
            target: LLVM target (empty string = current machine)
            opt_level: LLVM optimization level (-1 to 4, -1 = max)
            *args: Additional Faust compiler arguments

        Returns:
            LlvmDspFactory on success, None on failure
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.createDSPFactoryFromFile(
            filepath.encode('utf8'),
            params.argc,
            params.argv,
            target.encode('utf8'),
            error_msg,
            opt_level,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return None
        if factory.ptr == NULL:
            return None
        return factory

    @staticmethod
    def from_string(str name_app, str code, str target="", int opt_level=-1, *args) -> LlvmDspFactory:
        """Create an LLVM DSP factory from a DSP string.

        Args:
            name_app: Application name
            code: DSP source code as string
            target: LLVM target (empty string = current machine)
            opt_level: LLVM optimization level (-1 to 4, -1 = max)
            *args: Additional Faust compiler arguments

        Returns:
            LlvmDspFactory on success, None on failure
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.createDSPFactoryFromString(
            name_app.encode('utf8'),
            code.encode('utf8'),
            params.argc,
            params.argv,
            target.encode('utf8'),
            error_msg,
            opt_level,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return None
        if factory.ptr == NULL:
            return None
        return factory

    @staticmethod
    def from_signals(str name_app, SignalVector signals, str target="", int opt_level=-1, *args) -> LlvmDspFactory:
        """Create an LLVM DSP factory from a vector of output signals.

        Args:
            name_app: Application name
            signals: Vector of output signals
            target: LLVM target (empty string = current machine)
            opt_level: LLVM optimization level (-1 to 4, -1 = max)
            *args: Additional Faust compiler arguments

        Returns:
            LlvmDspFactory on success, None on failure
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.createDSPFactoryFromSignals(
            name_app.encode('utf8'),
            <fs.tvec>signals.ptr,
            params.argc,
            params.argv,
            target.encode('utf8'),
            error_msg,
            opt_level,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return None
        if factory.ptr == NULL:
            return None
        return factory

    @staticmethod
    def from_boxes(str name_app, Box box, str target="", int opt_level=-1, *args) -> LlvmDspFactory:
        """Create an LLVM DSP factory from a box expression.

        Args:
            name_app: Application name
            box: Box expression
            target: LLVM target (empty string = current machine)
            opt_level: LLVM optimization level (-1 to 4, -1 = max)
            *args: Additional Faust compiler arguments

        Returns:
            LlvmDspFactory on success, None on failure
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.createDSPFactoryFromBoxes(
            name_app.encode('utf8'),
            box.ptr,
            params.argc,
            params.argv,
            target.encode('utf8'),
            error_msg,
            opt_level,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return None
        if factory.ptr == NULL:
            return None
        return factory

    # -------------------------------------------------------------------------
    # Factory creation from serialized formats
    # -------------------------------------------------------------------------

    @staticmethod
    def from_bitcode(str bitcode, str target="", int opt_level=-1) -> LlvmDspFactory:
        """Create an LLVM DSP factory from a base64 encoded bitcode string.

        Args:
            bitcode: Base64 encoded LLVM bitcode
            target: LLVM target (empty string = current machine)
            opt_level: LLVM optimization level (-1 to 4, -1 = max)

        Returns:
            LlvmDspFactory on success, None on failure
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.readDSPFactoryFromBitcode(
            bitcode.encode('utf8'),
            target.encode('utf8'),
            error_msg,
            opt_level,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return None
        if factory.ptr == NULL:
            return None
        return factory

    @staticmethod
    def from_bitcode_file(str bit_code_path, str target="", int opt_level=-1) -> LlvmDspFactory:
        """Create an LLVM DSP factory from a bitcode file.

        Args:
            bit_code_path: Path to bitcode file
            target: LLVM target (empty string = current machine)
            opt_level: LLVM optimization level (-1 to 4, -1 = max)

        Returns:
            LlvmDspFactory on success, None on failure
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.readDSPFactoryFromBitcodeFile(
            bit_code_path.encode('utf8'),
            target.encode('utf8'),
            error_msg,
            opt_level,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return None
        if factory.ptr == NULL:
            return None
        return factory

    @staticmethod
    def from_ir(str ir_code, str target="", int opt_level=-1) -> LlvmDspFactory:
        """Create an LLVM DSP factory from LLVM IR (textual) string.

        Args:
            ir_code: LLVM IR string
            target: LLVM target (empty string = current machine)
            opt_level: LLVM optimization level (-1 to 4, -1 = max)

        Returns:
            LlvmDspFactory on success, None on failure
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.readDSPFactoryFromIR(
            ir_code.encode('utf8'),
            target.encode('utf8'),
            error_msg,
            opt_level,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return None
        if factory.ptr == NULL:
            return None
        return factory

    @staticmethod
    def from_ir_file(str ir_code_path, str target="", int opt_level=-1) -> LlvmDspFactory:
        """Create an LLVM DSP factory from LLVM IR (textual) file.

        Args:
            ir_code_path: Path to IR file
            target: LLVM target (empty string = current machine)
            opt_level: LLVM optimization level (-1 to 4, -1 = max)

        Returns:
            LlvmDspFactory on success, None on failure
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.readDSPFactoryFromIRFile(
            ir_code_path.encode('utf8'),
            target.encode('utf8'),
            error_msg,
            opt_level,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return None
        if factory.ptr == NULL:
            return None
        return factory

    @staticmethod
    def from_machine(str machine_code, str target="") -> LlvmDspFactory:
        """Create an LLVM DSP factory from base64 encoded machine code string.

        Args:
            machine_code: Base64 encoded machine code
            target: LLVM target (empty string = current machine)

        Returns:
            LlvmDspFactory on success, None on failure
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.readDSPFactoryFromMachine(
            machine_code.encode('utf8'),
            target.encode('utf8'),
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return None
        if factory.ptr == NULL:
            return None
        return factory

    @staticmethod
    def from_machine_file(str machine_code_path, str target="") -> LlvmDspFactory:
        """Create an LLVM DSP factory from machine code file.

        Args:
            machine_code_path: Path to machine code file
            target: LLVM target (empty string = current machine)

        Returns:
            LlvmDspFactory on success, None on failure
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef LlvmDspFactory factory = LlvmDspFactory.__new__(LlvmDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fl.llvm_dsp_factory*>fl.readDSPFactoryFromMachineFile(
            machine_code_path.encode('utf8'),
            target.encode('utf8'),
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return None
        if factory.ptr == NULL:
            return None
        return factory


# -----------------------------------------------------------------------------
# LlvmDsp - LLVM DSP instance class
# -----------------------------------------------------------------------------

cdef class LlvmDsp:
    """LLVM DSP instance class with methods.

    Represents a DSP instance compiled to native machine code via LLVM JIT.
    """

    cdef fl.llvm_dsp* ptr
    cdef bint ptr_owner
    cdef fg.SoundUI* sound_ui

    def __dealloc__(self):
        if self.sound_ui:
            del self.sound_ui
            self.sound_ui = NULL
        if self.ptr and self.ptr_owner:
            del self.ptr
            self.ptr = NULL

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False
        self.sound_ui = NULL

    def delete(self):
        """Manually delete the DSP instance."""
        del self.ptr

    @staticmethod
    cdef LlvmDsp from_ptr(fl.llvm_dsp* ptr, bint owner=False):
        """Wrap the dsp instance and manage its lifetime."""
        cdef LlvmDsp dsp = LlvmDsp.__new__(LlvmDsp)
        dsp.ptr_owner = owner
        dsp.ptr = ptr
        return dsp

    # -------------------------------------------------------------------------
    # DSP properties
    # -------------------------------------------------------------------------

    def get_numinputs(self) -> int:
        """Return instance number of audio inputs."""
        return self.ptr.getNumInputs()

    def get_numoutputs(self) -> int:
        """Return instance number of audio outputs."""
        return self.ptr.getNumOutputs()

    def get_samplerate(self) -> int:
        """Return the sample rate currently used by the instance."""
        return self.ptr.getSampleRate()

    # -------------------------------------------------------------------------
    # Initialization
    # -------------------------------------------------------------------------

    def init(self, int sample_rate):
        """Global init, calls static class init and instance init.

        Args:
            sample_rate: The sample rate in Hz
        """
        self.ptr.init(sample_rate)

    def instance_init(self, int sample_rate):
        """Init instance state.

        Args:
            sample_rate: The sample rate in Hz
        """
        self.ptr.instanceInit(sample_rate)

    def instance_constants(self, int sample_rate):
        """Init instance constant state.

        Args:
            sample_rate: The sample rate in Hz
        """
        self.ptr.instanceConstants(sample_rate)

    def instance_reset_user_interface(self):
        """Init default control parameters values."""
        self.ptr.instanceResetUserInterface()

    def instance_clear(self):
        """Init instance state but keep the control parameter values."""
        self.ptr.instanceClear()

    # -------------------------------------------------------------------------
    # Clone and metadata
    # -------------------------------------------------------------------------

    def clone(self) -> LlvmDsp:
        """Return a clone of the instance."""
        cdef fl.llvm_dsp* dsp = self.ptr.clone()
        return LlvmDsp.from_ptr(dsp)

    def metadata(self) -> dict:
        """Get DSP metadata as a dictionary.

        Returns:
            dict: Dictionary of metadata key-value pairs
        """
        cdef MetaCollector collector = MetaCollector()
        self.ptr.metadata(<fg.Meta*>collector.ptr)
        return collector.get_metadata()

    # -------------------------------------------------------------------------
    # User interface
    # -------------------------------------------------------------------------

    def build_user_interface(self, str sound_directory="", int sample_rate=-1):
        """Trigger the ui_interface parameter with instance specific calls.

        Calls are made to 'openTabBox', 'addButton',
        'addVerticalSlider'... in order to build the UI.

        This method also loads any soundfiles referenced in the DSP code.

        Args:
            sound_directory: Base directory for soundfile paths (default: current directory)
            sample_rate: Sample rate for resampling soundfiles (-1 for no resampling)
        """
        if self.sound_ui:
            del self.sound_ui
            self.sound_ui = NULL

        self.sound_ui = new fg.SoundUI(
            sound_directory.encode('utf8'),
            sample_rate,
            <fg.SoundfileReader*>NULL,
            False  # is_double=False for float audio
        )
        self.ptr.buildUserInterface(<fg.UI*>self.sound_ui)

    # -------------------------------------------------------------------------
    # Audio computation
    # -------------------------------------------------------------------------

    def compute(self, int count, float[:, ::1] inputs not None, float[:, ::1] outputs not None):
        """DSP instance computation with successive in/out audio buffers.

        Args:
            count: Number of frames to compute
            inputs: 2D input audio buffers as memoryview [channels, samples]
            outputs: 2D output audio buffers as memoryview [channels, samples]
        """
        cdef float** input_ptrs = <float**>malloc(inputs.shape[0] * sizeof(float*))
        cdef float** output_ptrs = <float**>malloc(outputs.shape[0] * sizeof(float*))

        try:
            for i in range(inputs.shape[0]):
                input_ptrs[i] = &inputs[i, 0]
            for i in range(outputs.shape[0]):
                output_ptrs[i] = &outputs[i, 0]

            self.ptr.compute(count, input_ptrs, output_ptrs)
        finally:
            free(input_ptrs)
            free(output_ptrs)


# -----------------------------------------------------------------------------
# RtAudioDriver for LLVM DSP
# -----------------------------------------------------------------------------

cdef class LlvmRtAudioDriver:
    """Faust audio driver using rtaudio cross-platform lib for LLVM DSP."""
    cdef fl.rtaudio *ptr
    cdef bint ptr_owner

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            del self.ptr
            self.ptr = NULL

    def __cinit__(self, int srate, int bsize):
        self.ptr = new fl.rtaudio(srate, bsize)
        self.ptr_owner = True

    def set_dsp(self, dsp: LlvmDsp):
        """Set LlvmDsp instance."""
        self.ptr.setDsp(<fl.dsp*>dsp.ptr)

    def init(self, dsp: LlvmDsp) -> bool:
        """Initialize with dsp instance."""
        name = "LlvmRtAudioDriver".encode('utf8')
        if self.ptr.init(name, dsp.get_numinputs(), dsp.get_numoutputs()):
            self.set_dsp(dsp)
            return True
        return False

    def start(self):
        """Start audio driver."""
        if not self.ptr.start():
            print("LlvmRtAudioDriver: could not start")

    def stop(self):
        """Stop audio driver."""
        self.ptr.stop()

    @property
    def buffersize(self):
        """Get buffersize."""
        return self.ptr.getBufferSize()

    @property
    def samplerate(self):
        """Get samplerate."""
        return self.ptr.getSampleRate()

    @property
    def numinputs(self):
        """Get number of inputs."""
        return self.ptr.getNumInputs()

    @property
    def numoutputs(self):
        """Get number of outputs."""
        return self.ptr.getNumOutputs()


# -----------------------------------------------------------------------------
# Module-level factory functions
# -----------------------------------------------------------------------------

def llvm_get_version():
    """Returns the library version as a static string."""
    return fl.getCLibFaustVersion().decode()

def llvm_get_dsp_factory_from_sha_key(str sha_key) -> LlvmDspFactory:
    """Get the Faust DSP factory associated with a given SHA key."""
    return LlvmDspFactory.from_sha_key(sha_key)

def llvm_create_dsp_factory_from_file(str filename, str target="", int opt_level=-1, *args) -> LlvmDspFactory:
    """Create an LLVM DSP factory from a DSP source code file.

    Args:
        filename: Path to the DSP source file
        target: LLVM target (empty string = current machine)
        opt_level: LLVM optimization level (-1 to 4, -1 = max)
        *args: Additional Faust compiler arguments
    """
    return LlvmDspFactory.from_file(filename, target, opt_level, *args)

def llvm_create_dsp_factory_from_string(str name_app, str code, str target="", int opt_level=-1, *args) -> LlvmDspFactory:
    """Create an LLVM DSP factory from a DSP source code string.

    Args:
        name_app: Application name
        code: DSP source code as string
        target: LLVM target (empty string = current machine)
        opt_level: LLVM optimization level (-1 to 4, -1 = max)
        *args: Additional Faust compiler arguments
    """
    return LlvmDspFactory.from_string(name_app, code, target, opt_level, *args)

def llvm_create_dsp_factory_from_signals(str name_app, SignalVector signals, str target="", int opt_level=-1, *args) -> LlvmDspFactory:
    """Create an LLVM DSP factory from a vector of output signals."""
    return LlvmDspFactory.from_signals(name_app, signals, target, opt_level, *args)

def llvm_create_dsp_factory_from_boxes(str name_app, Box box, str target="", int opt_level=-1, *args) -> LlvmDspFactory:
    """Create an LLVM DSP factory from a box expression."""
    return LlvmDspFactory.from_boxes(name_app, box, target, opt_level, *args)

def llvm_delete_all_dsp_factories():
    """Delete all Faust DSP factories kept in the library cache."""
    fl.deleteAllDSPFactories()

def llvm_get_all_dsp_factories() -> list[str]:
    """Return Faust DSP factories of the library cache as a vector of their SHA keys."""
    return [key.decode() for key in fl.getAllDSPFactories()]

def llvm_start_multithreaded_access_mode() -> bool:
    """Start multi-thread access mode."""
    return fl.startMTDSPFactories()

def llvm_stop_multithreaded_access_mode():
    """Stop multi-thread access mode."""
    fl.stopMTDSPFactories()

def llvm_read_dsp_factory_from_bitcode(str bitcode, str target="", int opt_level=-1) -> LlvmDspFactory:
    """Create an LLVM DSP factory from a base64 encoded bitcode string."""
    return LlvmDspFactory.from_bitcode(bitcode, target, opt_level)

def llvm_read_dsp_factory_from_bitcode_file(str bitcode_path, str target="", int opt_level=-1) -> LlvmDspFactory:
    """Create an LLVM DSP factory from a bitcode file."""
    return LlvmDspFactory.from_bitcode_file(bitcode_path, target, opt_level)

def llvm_read_dsp_factory_from_ir(str ir_code, str target="", int opt_level=-1) -> LlvmDspFactory:
    """Create an LLVM DSP factory from LLVM IR (textual) string."""
    return LlvmDspFactory.from_ir(ir_code, target, opt_level)

def llvm_read_dsp_factory_from_ir_file(str ir_code_path, str target="", int opt_level=-1) -> LlvmDspFactory:
    """Create an LLVM DSP factory from LLVM IR (textual) file."""
    return LlvmDspFactory.from_ir_file(ir_code_path, target, opt_level)

def llvm_read_dsp_factory_from_machine(str machine_code, str target="") -> LlvmDspFactory:
    """Create an LLVM DSP factory from base64 encoded machine code string."""
    return LlvmDspFactory.from_machine(machine_code, target)

def llvm_read_dsp_factory_from_machine_file(str machine_code_path, str target="") -> LlvmDspFactory:
    """Create an LLVM DSP factory from machine code file."""
    return LlvmDspFactory.from_machine_file(machine_code_path, target)
