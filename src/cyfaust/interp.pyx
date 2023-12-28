# distutils: language = c++

from libcpp.string cimport string

from . cimport faust_interp as fi
from . cimport faust_box as fb
from . cimport faust_signal as fs

from .common cimport ParamArray
from .common import ParamArray

from .box cimport Box
from .box import Box

from .signal cimport SignalVector
from .signal import SignalVector



## ---------------------------------------------------------------------------
## faust/dsp/libfaust
##

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

def expand_dsp_from_string(name_app: str, dsp_content: str, *args) -> str:
    """Expand dsp in a file into a self-contained dsp string."""
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg, sha_key 
    error_msg.reserve(4096)
    sha_key.reserve(100) # sha1 is 40 chars
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

def generate_auxfiles_from_file(filename: str, *args) -> str:
    """Generate additional files (other backends, SVG, XML, JSON...) from a file."""
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
        return False
    return result

def generate_auxfiles_from_string(name_app: str, dsp_content: str, *args) -> str:
    """Generate additional files (other backends, SVG, XML, JSON...) from a string."""
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
        return False
    return result

## ---------------------------------------------------------------------------
## faust/audio/rtaudio-dsp
##

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
        self.ptr.setDsp(<fi.dsp*>dsp.ptr)

    def init(self, dsp: InterpreterDsp) -> bool:
        """initialize with dsp instance."""
        name = "RtAudioDriver".encode('utf8')
        if self.ptr.init(name, dsp.get_numinputs(), dsp.get_numoutputs()):
            self.set_dsp(dsp)
            return True
        return False

    def start(self):
        if not self.ptr.start():
            print("RtAudioDriver: could not start")

    def stop(self):
        self.ptr.stop()

    def get_buffersize(self):
        return self.ptr.getBufferSize()

    def get_samplerate(self):
        return self.ptr.getSampleRate()

    def get_numinputs(self):
        return self.ptr.getNumInputs()

    def get_numoutputs(self):
        return self.ptr.getNumOutputs()

## ---------------------------------------------------------------------------
## faust/dsp/interpreter-dsp
##


def get_version():
    """Get the version of the library.

    returns the library version as a static string.
    """
    return fi.getCLibFaustVersion().decode()


cdef class InterpreterDspFactory:
    """Interpreter DSP factory class."""

    cdef fi.interpreter_dsp_factory* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            fi.deleteInterpreterDSPFactory(self.ptr)
            self.ptr = NULL

    def get_name(self) -> str:
        """Return factory name."""
        return self.ptr.getName().decode()

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
        return self.ptr.getWarningMessages()

    def create_dsp_instance(self) -> InterpreterDsp:
        """Create a new DSP instance, to be deleted with C++ 'delete'"""
        cdef fi.interpreter_dsp* dsp = self.ptr.createDSPInstance()
        return InterpreterDsp.from_ptr(dsp)

    cdef set_memory_manager(self, fi.dsp_memory_manager* manager):
        """Set a custom memory manager to be used when creating instances"""
        self.ptr.setMemoryManager(manager)

    cdef fi.dsp_memory_manager* get_memory_manager(self):
        """Set a custom memory manager to be used when creating instances"""
        return self.ptr.getMemoryManager()

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
        if error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_string(str name_app, str code, *args) -> InterpreterDspFactory:
        """create an interpreter dsp factory from a string"""
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
        if error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_bitcode(str bitcode) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a bitcode string."""
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
        return factory


cdef class InterpreterDsp:
    """DSP instance class with methods."""

    cdef fi.interpreter_dsp* ptr
    cdef bint ptr_owner

    # def __dealloc__(self):
    #     if self.ptr and self.ptr_owner:
    #         del self.ptr
    #         self.ptr = NULL

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    @staticmethod
    cdef InterpreterDsp from_ptr(fi.interpreter_dsp* ptr):
        """Wrap the dsp instance and manage its lifetime."""
        cdef InterpreterDsp dsp = InterpreterDsp.__new__(InterpreterDsp)
        dsp.ptr_owner = True
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
        """Return a clone of the instance."""
        cdef fi.interpreter_dsp* dsp = self.ptr.clone()
        return InterpreterDsp.from_ptr(dsp)

    def build_user_interface(self):
        """Trigger the ui_interface parameter with instance specific calls."""
        cdef fi.PrintUI ui_interface
        self.ptr.buildUserInterface(<fi.UI*>&ui_interface)

    # cdef build_user_interface(self, fi.UI* ui_interface):
    #     """Trigger the ui_interface parameter with instance specific calls."""
    #     self.ptr.buildUserInterface(ui_interface)

    cdef metadata(self, fi.Meta* m):
        """Trigger the meta parameter with instance specific calls."""
        self.ptr.metadata(m)


def get_dsp_factory_from_sha_key(str sha_key) -> InterpreterDspFactory:
    """Get the Faust DSP factory associated with a given SHA key."""
    return InterpreterDspFactory.from_sha_key(sha_key.encode())

def create_dsp_factory_from_file(filename: str, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a DSP source code as a file."""
    return InterpreterDspFactory.from_file(filename, *args)

def create_dsp_factory_from_string(name_app: str, code: str, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a DSP source code as a string."""
    return InterpreterDspFactory.from_string(name_app, code, *args)

def delete_all_dsp_factories():
    """Delete all Faust DSP factories kept in the library cache."""
    fi.deleteAllInterpreterDSPFactories()

def get_all_dsp_factories():
    """Return Faust DSP factories of the library cache as a vector of their SHA keys."""
    return fi.getAllInterpreterDSPFactories()

def start_multithreaded_access_mode() -> bool:
    """Start multi-thread access mode."""
    return fi.startMTDSPFactories()

def stop_multithreaded_access_mode():
    """Stop multi-thread access mode."""
    fi.stopMTDSPFactories()

def create_interpreter_dsp_factory_from_signals(str name_app, SignalVector signals, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a vector of output signals."""
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    cdef fi.interpreter_dsp_factory *factory = fi.createInterpreterDSPFactoryFromSignals(
        name_app.encode('utf8'),
        <fs.tvec>signals.ptr, 
        params.argc,
        params.argv,
        error_msg)
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return InterpreterDspFactory.from_ptr(factory)

def create_interpreter_dsp_factory_from_boxes(str name_app, Box box, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from boxes."""
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    cdef fi.interpreter_dsp_factory *factory = fi.createInterpreterDSPFactoryFromBoxes(
        name_app.encode('utf8'),
        box.ptr,
        params.argc,
        params.argv,
        error_msg)
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return InterpreterDspFactory.from_ptr(factory)

## ---------------------------------------------------------------------------
## faust/dsp/libfaust-box
##

# include "faust_box.pxi"



## ---------------------------------------------------------------------------
## faust/dsp/libfaust-signal
##

# include "faust_signal.pxi"


