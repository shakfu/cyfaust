# distutils: language = c++

from libcpp.string cimport string
from libcpp.map cimport map
from libc.stdlib cimport malloc, free
from cython.operator cimport dereference as deref, preincrement as inc

from . cimport faust_interp as fi
from . cimport faust_gui as fg
from . cimport faust_signal as fs


from .common cimport ParamArray
from .common import ParamArray

from .box cimport Box
from .box import Box

from .signal cimport SignalVector
from .signal import SignalVector

import weakref

from collections import namedtuple

# Widget kind strings indexed by APIUI ItemType enum value (see faust_gui.pxd).
_PARAM_KINDS = (
    "button",     # 0 kButton
    "checkbox",   # 1 kCheckButton
    "vslider",    # 2 kVSlider
    "hslider",    # 3 kHSlider
    "nentry",     # 4 kNumEntry
    "hbargraph",  # 5 kHBargraph
    "vbargraph",  # 6 kVBargraph
)

# Bargraphs (ItemType 5, 6) are read-only outputs; all other kinds are settable
# input controls.
_BARGRAPH_TYPES = frozenset((5, 6))

Param = namedtuple(
    "Param",
    ["path", "label", "kind", "is_input", "init", "min", "max", "step", "index"],
)
Param.__doc__ = """One DSP control parameter, mirroring py-faust-rs's Param.

path  -- full UI path, e.g. /Oscillator/freq
label -- leaf label, e.g. freq
kind  -- button, checkbox, hslider, vslider, nentry, hbargraph, or vbargraph
is_input -- False for bargraphs (metering outputs), True otherwise
init/min/max/step -- declared range metadata
index -- APIUI parameter index used to address the control (the cyfaust
         analogue of py-faust-rs's real-heap zone offset)
"""

# Every live InterpreterDspFactory wrapper, weakly referenced. delete_all_dsp_
# factories() uses this to invalidate wrappers whose C++ factory it destroys, so
# their __dealloc__ cannot double-free (see delete_all_dsp_factories).
cdef object _live_factories = weakref.WeakSet()


## ---------------------------------------------------------------------------
## faust/dsp/libfaust


def generate_sha1(data: str) -> str:
    """Generate SHA1 key from a string."""
    return fi.generateSHA1(data.encode('utf8')).decode()

def expand_dsp_from_file(filename: str, *args) -> tuple(str, str):
    """Expand dsp in a file into a self-contained dsp string.
    
    Returns sha key for expanded dsp string and expanded dsp string
    """
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg, sha_key 
    error_msg.reserve(4096)
    sha_key.reserve(100) # sha1 is 40 chars
    cdef string result = fi.expandDSPFromFile(
        filename.encode('utf8'),
        params.argc,
        params.argv,
        sha_key,
        error_msg
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return (sha_key.decode(), result.decode())

def expand_dsp_from_string(name_app: str, dsp_content: str, *args) -> tuple(str, str):
    """Expand dsp in a file into a self-contained dsp string."""
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg, sha_key 
    error_msg.reserve(4096)
    sha_key.reserve(128) # sha1 is 40 chars
    cdef string result = fi.expandDSPFromString(
        name_app.encode('utf8'),
        dsp_content.encode('utf8'),
        params.argc,
        params.argv,
        sha_key,
        error_msg
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return (sha_key.decode(), result.decode())

def generate_auxfiles_from_file(filename: str, *args) -> bool:
    """Generate additional files from a file.

    Auxfiles can be other backends, SVG, XML, JSON...
    """
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    result = fi.generateAuxFilesFromFile(
        filename.encode('utf8'),
        params.argc,
        params.argv,
        error_msg
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return result

def generate_auxfiles_from_string(name_app: str, dsp_content: str, *args) -> bool:
    """Generate additional files from a string.

    Auxfiles can be other backends, SVG, XML, JSON...
    """
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    result = fi.generateAuxFilesFromString(
        name_app.encode('utf8'),
        dsp_content.encode('utf8'),
        params.argc,
        params.argv,
        error_msg
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return result

## ---------------------------------------------------------------------------
## faust/audio/rtaudio-dsp


cdef class RtAudioDriver:
    """faust audio driver using rtaudio cross-platform lib."""
    cdef fi.rtaudio *ptr
    cdef bint ptr_owner

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            del self.ptr
            self.ptr = NULL

    def __cinit__(self, int srate, int bsize):
        self.ptr = new fi.rtaudio(srate, bsize)
        self.ptr_owner = True

    def set_dsp(self, dsp: InterpreterDsp):
        """"set InterpreterDsp instance."""
        self.ptr.setDsp(<fi.dsp*>dsp.ptr)

    def init(self, dsp: InterpreterDsp) -> bool:
        """initialize with dsp instance."""
        name = "RtAudioDriver".encode('utf8')
        if self.ptr.init(name, dsp.get_numinputs(), dsp.get_numoutputs()):
            self.set_dsp(dsp)
            return True
        return False

    def start(self):
        """start audio driver."""
        if not self.ptr.start():
            print("RtAudioDriver: could not start")

    def stop(self):
        """stop audio driver."""
        self.ptr.stop()

    @property
    def buffersize(self):
        """get buffersize"""
        return self.ptr.getBufferSize()

    @property
    def samplerate(self):
        """get samplerate."""
        return self.ptr.getSampleRate()

    @property
    def numinputs(self):
        """get number of inputs."""
        return self.ptr.getNumInputs()

    @property
    def numoutputs(self):
        """get number of outputs."""
        return self.ptr.getNumOutputs()

## ---------------------------------------------------------------------------
## faust/dsp/interpreter-dsp


def get_version():
    """Returns the library version as a static string."""
    return fi.getCLibFaustVersion().decode()


cdef class InterpreterDspFactory:
    """Interpreter DSP factory class."""

    cdef fi.interpreter_dsp_factory* ptr
    cdef bint ptr_owner
    cdef set instances
    cdef object __weakref__          # make wrappers weak-referenceable

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False
        self.instances = set()
        _live_factories.add(self)

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            instances = self.instances.copy()
            while instances:
                i = instances.pop()
                i.delete()
            fi.deleteInterpreterDSPFactory(self.ptr)
            self.ptr = NULL

    cdef void _invalidate(self):
        """Drop our reference to a C++ factory destroyed out-of-band (e.g. by
        delete_all_dsp_factories) so __dealloc__ won't delete it a second time."""
        self.ptr = NULL
        self.ptr_owner = False

    def get_name(self) -> str:
        """Return factory name."""
        return self.ptr.getName().decode()

    def get_sha_key(self) -> str:
        """Return factory SHA key."""
        return self.ptr.getSHAKey().decode()
    
    def get_dsp_code(self) -> str:
        """Return factory expanded DSP code."""
        return self.ptr.getDSPCode().decode()

    def get_json(self) -> str:
        """Return JSON description of the DSP (UI + metadata)."""
        return self.ptr.getJSON().decode()

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

    def create_dsp_instance(self) -> InterpreterDsp:
        """Create a new DSP instance, to be deleted with C++ 'delete'"""
        cdef fi.interpreter_dsp* dsp = self.ptr.createDSPInstance()
        cdef InterpreterDsp instance = InterpreterDsp.from_ptr(dsp)
        instance._factory_ref = weakref.ref(self)
        self.instances.add(instance)
        return instance

    def set_memory_manager(self, object manager):
        """Set a custom memory manager to be used when creating instances.
        
        Args:
            manager: A memory manager object (currently None to reset to default)
        """
        # For now, only support None to reset to default
        if manager is None:
            self.ptr.setMemoryManager(NULL)
        else:
            raise NotImplementedError("Custom memory managers not yet supported in Python interface")

    def get_memory_manager(self):
        """Return the currently set custom memory manager.
        
        Returns:
            None if no custom manager is set, otherwise raises NotImplementedError
        """
        cdef fi.dsp_memory_manager* manager = self.ptr.getMemoryManager()
        if manager == NULL:
            return None
        else:
            # Custom memory managers not yet fully supported in Python interface
            raise NotImplementedError("Custom memory managers not yet fully supported in Python interface")

    def class_init(self, int sample_rate):
        """Initialize the static tables for all factory instances.
        
        Args:
            sample_rate: The sample rate in Hz
        """
        self.ptr.classInit(sample_rate)

    def write_to_bitcode(self) -> str:
        """Write a Faust DSP factory into a bitcode string."""
        return fi.writeInterpreterDSPFactoryToBitcode(self.ptr).decode()

    def write_to_bitcode_file(self, bit_code_path: str) -> bool:
        """Write a Faust DSP factory into a bitcode file."""
        return fi.writeInterpreterDSPFactoryToBitcodeFile(
            self.ptr, bit_code_path.encode('utf8'))

    @staticmethod
    cdef InterpreterDspFactory from_ptr(fi.interpreter_dsp_factory* ptr, bint owner=False):
        """Wrap external factory from pointer"""
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr = ptr
        factory.owner = owner
        return factory

    @staticmethod
    def from_sha_key(str sha_key) -> InterpreterDspFactory:
        """create an interpreter dsp factory from a sha key"""
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.getInterpreterDSPFactoryFromSHAKey(
            sha_key.encode())
        return factory

    @staticmethod
    def from_file(str filepath, *args) -> InterpreterDspFactory:
        """create an interpreter dsp factory from a file"""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.createInterpreterDSPFactoryFromFile(
            filepath.encode('utf8'),
            params.argc,
            params.argv,
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_signals(str name_app, SignalVector signals, *args) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a vector of output signals."""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.createInterpreterDSPFactoryFromSignals(
            name_app.encode('utf8'),
            <fs.tvec>signals.ptr,
            params.argc,
            params.argv,
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return
        return factory
    
    @staticmethod
    def from_boxes(str name_app, Box box, *args) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a box expression."""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.createInterpreterDSPFactoryFromBoxes(
            name_app.encode('utf8'),
            box.ptr,
            params.argc,
            params.argv,
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_bitcode_file(str bit_code_path) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a bitcode file."""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.readInterpreterDSPFactoryFromBitcodeFile(
            bit_code_path.encode('utf8'),
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_string(str name_app, str code, *args) -> InterpreterDspFactory:
        """Create an interpreter dsp factory from a string"""
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        cdef ParamArray params = ParamArray(args)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.createInterpreterDSPFactoryFromString(
            name_app.encode('utf8'),
            code.encode('utf8'),
            params.argc,
            params.argv,
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return
        assert factory.ptr, "factory.ptr is NULL (should not be)"
        return factory

    @staticmethod
    def from_bitcode(str bitcode) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a bitcode string.

        Note that the library keeps an internal cache of all allocated
        factories so that the compilation of the same DSP code (that is
        the same bitcode code string) will return the same
        (reference counted) factory pointer.

        bitcode - the bitcode string
        error_msg - the error string to be filled

        returns the DSP factory on success, otherwise a null pointer.
        """
        cdef string error_msg
        error_msg.reserve(4096)
        cdef InterpreterDspFactory factory = InterpreterDspFactory.__new__(
            InterpreterDspFactory)
        factory.ptr_owner = True
        factory.ptr = <fi.interpreter_dsp_factory*>fi.readInterpreterDSPFactoryFromBitcode(
            bitcode.encode('utf8'),
            error_msg,
        )
        if not error_msg.empty():
            print(error_msg.decode())
            return
        assert factory.ptr, "factory pointer is NULL (should not be)"
        return factory


cdef class MetaCollector:
    """Collects DSP metadata into a Python dictionary."""
    cdef fg.MetaCollector* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = new fg.MetaCollector()
        self.ptr_owner = True

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            del self.ptr
            self.ptr = NULL

    def get_metadata(self) -> dict:
        """Return collected metadata as a Python dictionary."""
        cdef dict result = {}
        cdef map[string, string] meta_map = self.ptr.getMeta()
        cdef map[string, string].iterator it = meta_map.begin()
        while it != meta_map.end():
            result[deref(it).first.decode('utf8')] = deref(it).second.decode('utf8')
            inc(it)
        return result


cdef class InterpreterDsp:
    """DSP instance class with methods."""

    cdef fi.interpreter_dsp* ptr
    cdef bint ptr_owner
    cdef fg.SoundUI* sound_ui
    cdef fg.APIUI* api_ui            # lazily built zone map for get/set_param
    cdef object _params_cache        # cached list[Param] once the UI is built
    cdef object _factory_ref         # weakref to the owning factory (or None)

    def __dealloc__(self):
        if self.sound_ui:
            del self.sound_ui
            self.sound_ui = NULL
        if self.api_ui:
            del self.api_ui
            self.api_ui = NULL
        if self.ptr and self.ptr_owner:
            del self.ptr
            self.ptr = NULL

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False
        self.sound_ui = NULL
        self.api_ui = NULL
        self._params_cache = None
        self._factory_ref = None

    def delete(self):
        """Delete the underlying DSP instance.

        Idempotent: nulls the pointer after freeing so a second call -- e.g. the
        parent factory deleting its tracked instances on teardown after the user
        already called delete() -- is a safe no-op rather than a double free.
        """
        if self.sound_ui:
            del self.sound_ui
            self.sound_ui = NULL
        if self.api_ui:
            del self.api_ui
            self.api_ui = NULL
        if self.ptr:
            del self.ptr
            self.ptr = NULL

    @staticmethod
    cdef InterpreterDsp from_ptr(fi.interpreter_dsp* ptr, bint owner=False):
        """Wrap the dsp instance and manage its lifetime."""
        cdef InterpreterDsp dsp = InterpreterDsp.__new__(InterpreterDsp)
        dsp.ptr_owner = owner
        dsp.ptr = ptr
        return dsp

    def get_numinputs(self) -> int:
        """Return instance number of audio inputs."""
        return self.ptr.getNumInputs()

    def get_numoutputs(self) -> int:
        """Return instance number of audio outputs."""
        return self.ptr.getNumOutputs()

    def get_samplerate(self) -> int:
        """Return the sample rate currently used by the instance."""
        return self.ptr.getSampleRate()

    def init(self, int sample_rate):
        """Global init, calls static class init and instance init."""
        self.ptr.init(sample_rate)

    def instance_init(self, int sample_rate):
        """Init instance state."""
        self.ptr.instanceInit(sample_rate)

    def instance_constants(self, int sample_rate):
        """Init instance constant state."""
        self.ptr.instanceConstants(sample_rate)

    def instance_reset_user_interface(self):
        """Init default control parameters values."""
        self.ptr.instanceResetUserInterface()

    def instance_clear(self):
        """Init instance state but keep the control parameter values."""
        self.ptr.instanceClear()

    def clone(self) -> InterpreterDsp:
        """Return a clone of the instance.

        The clone is registered with the same factory as this instance so its
        C++ pointer is freed on the factory's ordered teardown -- exactly like a
        create_dsp_instance() result. Without this a clone (ptr_owner=False, and
        tracked by no factory) would leak, since its __dealloc__ frees nothing.
        """
        cdef fi.interpreter_dsp* dsp = self.ptr.clone()
        cdef InterpreterDsp instance = InterpreterDsp.from_ptr(dsp)
        cdef InterpreterDspFactory factory
        if self._factory_ref is not None:
            factory = self._factory_ref()
            if factory is not None:
                instance._factory_ref = self._factory_ref
                factory.instances.add(instance)
        return instance

    def build_user_interface(self, str sound_directory="", int sample_rate=-1):
        """Trigger the ui_interface parameter with instance specific calls

        Calls are made to 'openTabBox', 'addButton',
        'addVerticalSlider'... in order to build the UI.

        This method also loads any soundfiles referenced in the DSP code.

        Args:
            sound_directory: Base directory for soundfile paths (default: current directory)
            sample_rate: Sample rate for resampling soundfiles (-1 for no resampling)
        """
        # Clean up previous SoundUI if it exists
        if self.sound_ui:
            del self.sound_ui
            self.sound_ui = NULL

        # Create SoundUI to handle soundfile loading
        # Parameters: sound_directory, sample_rate, reader (NULL for default), is_double
        self.sound_ui = new fg.SoundUI(
            sound_directory.encode('utf8'),
            sample_rate,
            <fg.SoundfileReader*>NULL,
            False  # is_double=False for float audio
        )
        self.ptr.buildUserInterface(<fg.UI*>self.sound_ui)

    cdef _ensure_param_ui(self):
        """Build the APIUI zone map onto this instance once (idempotent).

        `buildUserInterface` can be called for several UI objects independently,
        so this coexists with `build_user_interface`'s SoundUI. The captured
        zone pointers stay valid for the instance's lifetime.
        """
        if self.api_ui is NULL:
            self.api_ui = new fg.APIUI()
            self.ptr.buildUserInterface(<fg.UI*>self.api_ui)
            self._params_cache = None

    cdef list _collect_params(self):
        cdef int n = self.api_ui.getParamsCount()
        cdef int i
        cdef int itype
        cdef list out = []
        for i in range(n):
            itype = self.api_ui.getParamItemType(i)
            kind = _PARAM_KINDS[itype] if 0 <= itype < len(_PARAM_KINDS) else "unknown"
            out.append(Param(
                path=self.api_ui.getParamAddress(i).decode('utf8'),
                label=self.api_ui.getParamLabel(i).decode('utf8'),
                kind=kind,
                is_input=itype not in _BARGRAPH_TYPES,
                init=float(self.api_ui.getParamInit(i)),
                min=float(self.api_ui.getParamMin(i)),
                max=float(self.api_ui.getParamMax(i)),
                step=float(self.api_ui.getParamStep(i)),
                index=i,
            ))
        return out

    def params(self) -> list:
        """List the DSP's UI control parameters as `Param` objects.

        Mirrors py-faust-rs's `params()`: each entry carries the full UI path,
        leaf label, widget kind, input/output flag, and init/min/max/step range,
        in UI-declaration order. Buttons, checkboxes, sliders and nentries are
        settable inputs; bargraphs are read-only outputs.
        """
        self._ensure_param_ui()
        if self._params_cache is None:
            self._params_cache = self._collect_params()
        return list(self._params_cache)

    cdef _resolve(self, str key):
        """Resolve a full UI path or unambiguous leaf label to its `Param`.

        Matches py-faust-rs's resolution order: an exact path wins first;
        otherwise a unique leaf label is accepted; unknown or ambiguous keys
        raise `ValueError`.
        """
        self._ensure_param_ui()
        if self._params_cache is None:
            self._params_cache = self._collect_params()
        params = self._params_cache
        for p in params:
            if p.path == key:
                return p
        by_label = [p for p in params if p.label == key]
        if len(by_label) == 1:
            return by_label[0]
        if len(by_label) > 1:
            raise ValueError(
                f"ambiguous parameter label {key!r}; use the full path")
        available = [p.path for p in params]
        raise ValueError(f"unknown parameter {key!r}; available: {available}")

    def get_param(self, str key) -> float:
        """Read a control parameter by full path or unambiguous leaf label.

        Works for input controls and output bargraphs (the latter reflect the
        most recent `compute`).
        """
        p = self._resolve(key)
        return float(self.api_ui.getParamValue(<int>p.index))

    def set_param(self, str key, float value):
        """Set an input control parameter; takes effect on the next `compute`.

        Bargraphs (outputs) cannot be set. `key` is a full UI path or an
        unambiguous leaf label. The value is not clamped to the declared
        `[min, max]` range (matching Faust's `setParamValue` semantics).
        """
        p = self._resolve(key)
        if not p.is_input:
            raise ValueError(
                f"parameter {p.path!r} is an output ({p.kind}) and cannot be set")
        self.api_ui.setParamValue(<int>p.index, value)

    def control(self):
        """Read all controllers (buttons, sliders, etc.), and update the DSP state.
        
        This method updates the DSP state to be used by 'frame' or 'compute'.
        Note: This method will only be functional with the -ec (--external-control) option.
        """
        self.ptr.control()

    def frame(self, float[::1] inputs not None, float[::1] outputs not None):
        """DSP instance computation to process one single frame.
        
        Args:
            inputs: input audio buffer as memoryview of floats
            outputs: output audio buffer as memoryview of floats
            
        Note: This method will only be functional with the -os (--one-sample) option.
        """
        self.ptr.frame(&inputs[0], &outputs[0])
        
    def compute(self, int count, float[:, ::1] inputs not None, float[:, ::1] outputs not None):
        """DSP instance computation with successive in/out audio buffers.

        Args:
            count: number of frames to compute
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

    def compute_timestamped(self, double date_usec, int count, float[:, ::1] inputs not None, float[:, ::1] outputs not None):
        """DSP instance computation with timestamp for sample-accurate timing.

        The timestamp parameter is provided for API compatibility with compiled DSP
        backends that support sample-accurate scheduling. The interpreter backend
        currently processes the audio immediately and the timestamp is stored for
        potential future use.

        Args:
            date_usec: timestamp in microseconds (stored but not used by interpreter)
            count: number of frames to compute
            inputs: 2D input audio buffers as memoryview [channels, samples]
            outputs: 2D output audio buffers as memoryview [channels, samples]
        """
        # Note: The interpreter backend doesn't currently support timestamped
        # scheduling - it delegates to the standard compute method.
        # The timestamp is accepted for API compatibility.
        cdef float** input_ptrs = <float**>malloc(inputs.shape[0] * sizeof(float*))
        cdef float** output_ptrs = <float**>malloc(outputs.shape[0] * sizeof(float*))

        try:
            for i in range(inputs.shape[0]):
                input_ptrs[i] = &inputs[i, 0]
            for i in range(outputs.shape[0]):
                output_ptrs[i] = &outputs[i, 0]

            # Call the standard compute - timestamp is for API compatibility
            self.ptr.compute(count, input_ptrs, output_ptrs)
        finally:
            free(input_ptrs)
            free(output_ptrs)

    def metadata(self) -> dict:
        """Get DSP metadata as a dictionary.

        Returns:
            dict: Dictionary of metadata key-value pairs (e.g., name, author, version, etc.)
        """
        cdef MetaCollector collector = MetaCollector()
        self.ptr.metadata(<fg.Meta*>collector.ptr)
        return collector.get_metadata()


def get_dsp_factory_from_sha_key(str sha_key) -> InterpreterDspFactory:
    """Get the Faust DSP factory associated with a given SHA key."""
    return InterpreterDspFactory.from_sha_key(sha_key)

def create_dsp_factory_from_file(filename: str, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a DSP source code as a file."""
    return InterpreterDspFactory.from_file(filename, *args)

def create_dsp_factory_from_string(name_app: str, code: str, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a DSP source code as a string."""
    return InterpreterDspFactory.from_string(name_app, code, *args)

def create_dsp_factory_from_signals(str name_app, SignalVector signals, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a vector of output signals."""
    return InterpreterDspFactory.from_signals(name_app, signals, *args)

def create_dsp_factory_from_boxes(str name_app, Box box, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from boxes."""
    return InterpreterDspFactory.from_boxes(name_app, box, *args)

def delete_all_dsp_factories():
    """Delete all Faust DSP factories kept in the library cache.

    Invalidates every live Python factory wrapper first. delete_all destroys the
    underlying C++ factories in libfaust's cache, so without this each wrapper's
    __dealloc__ would later call deleteInterpreterDSPFactory() on an already-freed
    factory -- a double free that aborts with 'deleteDSPFactory factory not found!'.
    """
    for f in list(_live_factories):
        (<InterpreterDspFactory>f)._invalidate()
    fi.deleteAllInterpreterDSPFactories()

def get_all_dsp_factories():
    """Return Faust DSP factories of the library cache as a vector of their SHA keys."""
    return [key.decode() for key in fi.getAllInterpreterDSPFactories()]

def start_multithreaded_access_mode() -> bool:
    """Start multi-thread access mode."""
    return fi.startMTDSPFactories()

def stop_multithreaded_access_mode():
    """Stop multi-thread access mode."""
    fi.stopMTDSPFactories()

def read_dsp_factory_from_bitcode(str bitcode) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a bitcode string."""
    return InterpreterDspFactory.from_bitcode(bitcode)

def read_dsp_factory_from_bitcode_file(str bitcode_path) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a bitcode file."""
    return InterpreterDspFactory.from_bitcode_file(bitcode_path)

