# distutils: language = c++

from libc.stdlib cimport malloc, free
from libcpp.string cimport string
from libcpp.vector cimport vector

cimport faust_interp as fi
cimport faust_box as fb
cimport faust_signal as fs


## ---------------------------------------------------------------------------
## python c-api functions
##

cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)

## ---------------------------------------------------------------------------
## common utility classes / functions
##

cdef class ParamArray:
    """wrapper classs around faust parameter array"""
    cdef const char ** argv
    cdef int argc

    def __cinit__(self, tuple ptuple):
        self.argc = len(ptuple)
        self.argv = <const char **>malloc(self.argc * sizeof(char *))
        for i in range(self.argc):
            self.argv[i] = PyUnicode_AsUTF8(ptuple[i])

    def __iter__(self):
        for i in range(self.argc):
            yield self.argv[i].decode()

    def dump(self):
        for i in self:
            print(i)

    def as_list(self):
        return list(self)

    def __dealloc__(self):
        if self.argv:
            free(self.argv)



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
        return [msg.decode() for msg in self.ptr.getWarningMessages()]

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
        if not error_msg.empty():
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
        if not error_msg.empty():
            print(error_msg.decode())
            return
        return factory

    @staticmethod
    def from_bitcode(str bitcode) -> InterpreterDspFactory:
        """Create a Faust DSP factory from a bitcode string.

        Note that the library keeps an internal cache of all allocated factories so that
        the compilation of the same DSP code (that is the same bitcode code string) will return
        the same (reference counted) factory pointer.

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
        """Trigger the ui_interface parameter with instance specific calls
        to 'openTabBox', 'addButton', 'addVerticalSlider'... in order to build the UI.
        
        ui_interface - the user interface builder
        """
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

def create_dsp_factory_from_signals(str name_app, SignalVector signals, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a vector of output signals."""
    return InterpreterDspFactory.from_signals(name_app, signals, *args)

def create_dsp_factory_from_boxes(str name_app, Box box, *args) -> InterpreterDspFactory:
    """Create a Faust DSP factory from boxes."""
    return InterpreterDspFactory.from_boxes(name_app, box, *args)

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

def read_dsp_factory_from_bitcode(str bitcode) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a bitcode string."""
    return InterpreterDspFactory.from_bitcode(bitcode)

def read_dsp_factory_from_bitcode_file(str bitcode_path) -> InterpreterDspFactory:
    """Create a Faust DSP factory from a bitcode file."""
    return InterpreterDspFactory.from_bitcode_file(bitcode_path)



## ---------------------------------------------------------------------------
## faust/dsp/libfaust-box

def box_or_int(var):
    if isinstance(var, int):
        return Box.from_int(var)
    if isinstance(var, Box):
        assert is_box_int(var), "box is not an int box"
        return var
    raise TypeError("argument must be an int or a boxInt")

def box_or_float(var):
    if isinstance(var, float):
        return Box.from_real(var)
    elif isinstance(var, Box):
        assert is_box_real(var), "box is not a float box"
        return var
    raise TypeError("argument must be an float or a boxReal")


class box_context:
    def __enter__(self):
        fb.createLibContext()
    def __exit__(self, type, value, traceback):
        fb.destroyLibContext()


cdef class BoxVector:
    """wraps tvec: a std::vector<CTree*>"""
    cdef vector[fb.Box] ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr_owner = False

    def __iter__(self):
        for i in self.ptr:
            yield Box.from_ptr(i)

    @staticmethod
    cdef BoxVector from_ptr(fb.tvec ptr):
        """Wrap a fs.tvec instance."""
        cdef BoxVector bv = BoxVector.__new__(BoxVector)
        bv.ptr = ptr
        return bv

    cdef add_ptr(self, fb.Box b):
        self.ptr.push_back(b)

    def add(self, Box b):
        self.ptr.push_back(b.ptr)

    # def create_source(self, name_app: str, lang, *args) -> str:
    #     """Create source code in a target language from a signal expression."""
    #     return create_source_from_signals(name_app, self, lang, *args)

    # def simplify_to_normal_form(self) -> SignalVector:
    #     """Simplify a signal list to its normal form.

    #     returns the signal vector in normal form.
    #     """
    #     return simplify_to_normal_form2(self)


cdef class Box:
    """faust Box wrapper.
    """
    cdef fb.Box ptr
    cdef public int inputs
    cdef public int outputs

    def __cinit__(self):
        self.ptr = NULL
        self.inputs = 0
        self.outputs = 0

    def __init__(self, value = None):
        if not value:
            self.ptr = fb.boxWire()
        elif isinstance(value, int):
            self.ptr = fb.boxInt(value)
        elif isinstance(value, float):
            self.ptr = fb.boxReal(value)

    @staticmethod
    cdef Box from_ptr(fb.Box ptr, bint ptr_owner=False):
        """Wrap external factory from pointer"""
        cdef Box box = Box.__new__(Box)
        box.ptr = ptr
        return box

    @staticmethod
    def from_int(int value) -> Box:
        """Create box from int"""
        return box_int(value)

    @staticmethod
    def from_float(float value) -> Box:
        """Create box from float"""
        return box_float(value)

    from_real = from_float

    @staticmethod
    def from_wire() -> Box:
        """Create box from wire box, copies its input to its output"""
        return box_wire()

    @staticmethod
    def from_cut() -> Box:
        """Create box from a cut box, to stop/terminate a signal"""
        return box_cut()

    @staticmethod
    def from_soundfile(str label, chan: Box | int, part: Box | None, ridx: Box | int | None) -> Box:
        """Create a soundfile block.

        label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
        chan - the number of outputs channels, a constant numerical expression (see [1])

        (box_soundfile2 parameters)
        part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])
        ridx - the read index (an integer between 0 and the selected sound length)

        returns the soundfile box.
        """
        return box_soundfile(label, chan, part, ridx)

    @staticmethod
    def from_readonly_table(n: Box | int, Box init, ridx: Box | int) -> Box:
        """Create a read only table.

        n - the table size, a constant numerical expression
        init - the table content
        ridx - the read index (an int between 0 and n-1)

        returns the table box.
        """
        _n = box_or_int(n)
        _ridx = box_or_int(ridx)
        return box_readonly_table(_n, init, _ridx)

    @staticmethod
    def from_write_read_table(n: Box | int, Box init, widx: Box | int, Box wsig, ridx: Box | int) -> Box:
        """Create a read/write table.

        n - the table size, a constant numerical expression (see [1])
        init - the table content
        widx - the write index (an integer between 0 and n-1)
        wsig - the input of the table
        ridx - the read index (an integer between 0 and n-1)

        returns the table box.
        """
        _n = box_or_int(n)
        _ridx = box_or_int(ridx)
        _widx = box_or_int(widx)
        return box_write_read_table(_n, init, _widx, wsig, _ridx)

    @staticmethod
    def from_waveform(BoxVector wf) -> Box:
        """Create a waveform.

        wf - the content of the waveform as a vector of boxInt or boxDouble boxes

        returns the waveform box.
        """
        return box_waveform(wf)
 
    @staticmethod
    def from_fconst(fb.SType type, str name, str file) -> Box:
        """Create a foreign constant box.

        type - the foreign constant type of SType
        name - the foreign constant name
        file - the include file where the foreign constant is defined

        returns the foreign constant box.
        """
        return box_fconst(type, name, file)

    @staticmethod
    def from_fvar(fb.SType type, str name, str file) -> Box:
        """Create a foreign variable box.

        type - the foreign variable type of SType
        name - the foreign variable name
        file - the include file where the foreign variable is defined

        returns the foreign variable box.
        """
        return box_fvar(type, name, file)

    def is_valid(self) -> bool:
        """Return true if box is defined, false otherwise

        sets number of inputs and outputs as a side-effect
        """
        return fb.getBoxType(self.ptr, &self.inputs, &self.outputs)

    def to_string(self, shared: bool = False, max_size: int = 256) -> str:
        """Convert the box to a string

        box - the box to be converted
        shared - whether the identical sub boxes are converted as identifiers
        max_size - the maximum number of characters to be converted (possibly 
                   needed for big expressions in non shared mode)

        returns the box as a string
        """
        return to_string(self, shared, max_size).decode()

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this box."""
        print_box(self, shared, max_size)

    def create_source(self, str name_app, str lang, *args) -> str:
        """Create source code in a target language from a box expression.

        name_app - the name of the Faust program
        lang - the target source code's language which can be one of 
            'c', 'cpp', 'cmajor', 'codebox', 'csharp', 'dlang', 'fir', 
            'interp', 'java', 'jax','jsfx', 'julia', 'ocpp', 'rust' or 'wast'
            (depending of which of the corresponding backends are compiled in libfaust)
        args - tuple of parameters if any

        returns a string of source code on success, printing error_msg if error.
        """
        return create_source_from_boxes(name_app, self, lang, *args)

    def __add__(self, Box other):
        """Add this box to another."""
        return box_add(self, other)

    def __radd__(self, Box other):
        """Reverse add this box to another."""
        return box_add(self, other)

    def __sub__(self, Box other):
        """Subtract this box from another."""
        return box_sub(self, other)

    def __rsub__(self, Box other):
        """Subtract this box from another."""
        return box_sub(self, other)

    def __mul__(self, Box other):
        """Multiply this box with another."""
        return box_mul(self, other)

    def __rmul__(self, Box other):
        """Reverse multiply this box with another."""
        return box_mul(self, other)

    def __div__(self, Box other):
        """Divide this box with another."""
        return box_div(self, other)

    def __rdiv__(self, Box other):
        """Reverse divide this box with another."""
        return box_div(self, other)

    def __eq__(self, Box other):
        """Compare for equality with another box."""
        return box_eq(self, other)

    def __ne__(self, Box other):
        """Assert this box is not equal with another box."""
        return box_ne(self, other)

    def __gt__(self, Box other):
        """Is this box greater than another box."""
        return box_gt(self, other)

    def __ge__(self, Box other):
        """Is this box greater than or equal from another box."""
        return box_ge(self, other)

    def __lt__(self, Box other):
        """Is this box lesser than another box."""
        return box_lt(self, other)

    def __le__(self, Box other):
        """Is this box lesser than or equal from another box."""
        return box_le(self, other)

    def __and__(self, Box other):
        """logical and with another box"""
        return box_and(self, other)

    def __or__(self, Box other):
        """logical or with another box"""
        return box_or(self, other)

    def __xor__(self, Box other):
        """logical xor with another box"""
        return box_xor(self, other)

    def __lshift__(self, Box other):
        """bitwise left-shift"""
        return box_leftshift(self, other)

    def __rshift__(self, Box other):
        """bitwise right-shift"""
        return box_lrightshift(self, other)

    # TODO: ???
    # Box boxARightShift()
    # Box boxARightShift(Box b1, Box b2)

    def tree2str(self):
        """Convert this box tree (such as the label of a UI) to a string."""
        return fb.tree2str(self.ptr).decode()

    def tree2int(self):
        """If this box tree has a node of type int, return it, otherwise error."""
        return fb.tree2int(self.ptr).decode()

    def abs(self) -> Box:
        """returns an absolute value box of this instance."""
        return box_abs(self)

    def acos(self) -> Box:
        """returns an arccosine box of this instance."""
        return box_acos(self)

    def tan(self) -> Box:
        """returns a tangent box of this instance."""
        return box_tan(self)

    def sqrt(self) -> Box:
        """returns a sqrt box of this instance."""
        return box_sqrt(self)

    def sin(self) -> Box:
        """returns a sin box of this instance."""
        return box_sin(self)

    def rint(self) -> Box:
        """returns a round to nearest int box of this instance."""
        return box_rint(self)

    def round(self) -> Box:
        """returns a round box of this instance."""
        return box_round(self)

    def log(self) -> Box:
        """returns a log box of this instance."""
        return box_log(self)

    def log10(self) -> Box:
        """returns a log10 box of this instance."""        
        return box_log10(self)

    def floor(self) -> Box:
        """returns a floor box of this instance."""
        return box_floor(self)

    def exp(self) -> Box:
        """returns an exp box of this instance."""
        return box_exp(self)

    def exp10(self) -> Box:
        """returns an exp10 box of this instance."""
        return box_exp10(self)

    def cos(self) -> Box:
        """returns an cosine box of this instance."""
        return box_cos(self)

    def ceil(self) -> Box:
        """returns an ceiling box of this instance."""
        return box_ceil(self)

    def atan(self) -> Box:
        """returns an arc tangent box of this instance."""
        return box_atan(self)

    def asin(self) -> Box:
        """returns an arc sine box of this instance."""
        return box_asin(self)

    # boolean methods ----------------

    def is_nil(self) -> bool:
        """Check if a box is nil."""
        return box_is_nil(self)

    def is_abstr(self) -> bool:
        return is_box_abstr(self)

    def is_appl(self) -> bool:
        return is_box_appl(self)

    def is_button(self) -> bool:
        return is_box_button(self)

    def is_case(self) -> bool:
        return is_box_case(self)

    def is_checkbox(self) -> bool:
        return is_box_checkbox(self)

    def is_cut(self) -> bool:
        return is_box_cut(self)

    def is_environment(self) -> bool:
        return is_box_environment(self)

    def is_error(self) -> bool:
        return is_box_error(self)

    def is_fconst(self) -> bool:
        return is_box_fconst(self)

    def is_ffun(self) -> bool:
        return is_box_ffun(self)

    def is_fvar_(self) -> bool:
        return is_box_fvar(self)

    def is_hbargraph(self) -> bool:
        return is_box_hbargraph(self)

    def is_hgroup(self) -> bool:
        return is_box_hgroup(self)

    def is_hslider(self) -> bool:
        return is_box_hslider(self)

    def is_ident(self) -> bool:
        return is_box_ident(self)

    def is_int(self) -> bool:
        return is_box_int(self)

    def is_numentry(self) -> bool:
        return is_box_numentry(self)

    def is_prim0(self) -> bool:
        return is_box_prim0(self)

    def is_prim1(self) -> bool:
        return is_box_prim1(self)

    def is_prim2(self) -> bool:
        return is_box_prim2(self)

    def is_prim3(self) -> bool:
        return is_box_prim3(self)

    def is_prim4(self) -> bool:
        return is_box_prim4(self)

    def is_prim5(self) -> bool:
        return is_box_prim5(self)

    def is_real(self) -> bool:
        return is_box_real(self)

    def is_slot(self) -> bool:
        return is_box_slot(self)

    def is_soundfile(self) -> bool:
        return is_box_soundfile(self)

    def is_symbolic(self) -> bool:
        return is_box_symbolic(self)

    def is_tgroup(self) -> bool:
        return is_box_tgroup(self)

    def is_vgroup(self) -> bool:
        return is_box_vgroup(self)

    def is_vslider(self) -> bool:
        return is_box_vslider(self)

    def is_hslider(self) -> bool:
        return is_box_hslider(self)

    def is_waveform(self) -> bool:
        return is_box_waveform(self)

    def is_wire(self) -> bool:
        return is_box_wire(self)


    def int_cast(self) -> Box:
        """return an int casted box."""
        return box_int_cast(self)


    def float_cast(self) -> Box:
        """return a float/double casted box.""

        s - the signal to be casted as float/double value 
            (depends of -single or -double compilation parameter)

        returns the casted box.
        """
        return box_float_cast(self)


    def seq(self, Box y) -> Box:
        """The sequential composition of two blocks (e.g., A:B)

        expects: outputs(A)=inputs(B)

        returns the seq box.
        """
        return box_seq(self, y)

    def par(self, Box y) -> Box:
        """The parallel composition of two blocks (e.g., A,B).

        Creates a two block-diagram with one block on top of the other,
        without connections.

        returns the par box.
        """
        return box_par(self, y)


    def par3(self, Box y, Box z) -> Box:
        """The parallel composition of three blocks (e.g., A,B,C).
        
        Creates a three block-diagram with one block on top of the other,
        without connections.

        returns the par box.    
        """
        return box_par3(self, y, z)


    def par4(self, Box b, Box c, Box d) -> Box:
        """The parallel composition of four blocks (e.g., A,B,C,D).

        Creates a four block-diagram with one block on top of the other,
        without connections.

        returns the par box.
        """
        return box_par4(self, b, c, d)


    def par5(self, Box b, Box c, Box d, Box e) -> Box:
        """The parallel composition of five blocks (e.g., A,B,C,D,E).

        Creates a five block-diagram with one block on top of the other,
        without connections.

        returns the par box.
        """
        return box_par4(self, b, c, d, e)


    def split(self, Box y) -> Box:
        """The split composition (e.g., A<:B) operator is used to distribute
        the outputs of A to the inputs of B.

        For the operation to be valid, the number of inputs of B
        must be a multiple of the number of outputs of A: outputs(A).k=inputs(B)

        returns the split box.
        """
        return box_split(self, y)


    def merge(self, Box y) -> Box:
        """The merge composition (e.g., A:>B) is the dual of the split composition.

        The number of outputs of A must be a multiple of the number of inputs of B:
        outputs(A)=k.inputs(B)

        returns the merge box.
        """
        return box_merge(self, y)


    def rec(self, Box y) -> Box:
        """The recursive composition (e.g., A~B) is used to create cycles in the
        block-diagram in order to express recursive computations.

        It is the most complex operation in terms of connections:
        outputs(A)≥inputs(B) and inputs(A)≥outputs(B)

        returns the rec box.
        """
        return box_rec(self, y)


    def get_def_name_property(self) -> Box | None:
        """Returns the identifier (if any) the expression was a definition of.

        b the expression
        id reference to the identifier

        returns the identifier if the expression b was a definition of id
        else returns None
        """
        cdef fb.Box id = NULL
        if fb.getDefNameProperty(self.ptr, id):
            return Box.from_ptr(id)

    def extract_name(self) -> str:
        """Extract the name from a label.

        full_label the label to be analyzed

        returns the extracted name
        """
        return extract_name(self)

    def delay(self, d: int | Box) -> Box:
        """Create a delayed box.

        s - the box to be delayed
        d - the delay box that doesn't have to be fixed but must be bounded
            and cannot be negative

        returns the delayed box.
        """
        if isinstance(d, int):
            return box_delay(self, Box.from_int(d))
        else:
            return box_delay(self, d.ptr)

    def select2(self, Box b1, Box b2) -> Box:
        """return a selector between two boxes.

        selector - when 0 at time t returns s1[t], otherwise returns s2[t]
        s1 - first box to be selected
        s2 - second box to be selected

        returns the selected box depending of the selector value at each time t.
        """
        return box_select2(self, b1, b2)


    def select3(self, Box b1, Box b2, Box b3) -> Box:
        """return a selector between three boxes.

        selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t],
                   otherwise returns s3[t]
        s1 - first box to be selected
        s2 - second box to be selected
        s3 - third box to be selected

        returns the selected box depending of the selector value at each time t.
        """
        return box_select3(self, b1, b2, b3)


def to_string(Box box, bint shared, int max_size) -> str:
    """Convert the box to a string

    box - the box to be converted
    shared - whether the identical sub boxes are converted as identifiers
    max_size - the maximum number of characters to be converted (possibly 
               needed for big expressions in non shared mode)

    returns the box as a string
    """
    return fb.printBox(box.ptr, shared, max_size).decode()


def print_box(Box box, bint shared, int max_size) -> str:
    """Print the box.

    box - the box to be printed
    shared - whether the identical sub boxes are printed as identifiers
    max_size - the maximum number of characters to be printed (possibly 
               needed for big expressions in non shared mode)

    returns the printed box as a string
    """
    return print(fb.printBox(box.ptr, shared, max_size).decode())


def get_def_name_property(Box b) -> Box | None:
    """Returns the identifier (if any) the expression was a definition of.

    b the expression
    id reference to the identifier

    returns the identifier if the expression b was a definition of id
    else returns None
    """
    cdef fb.Box id = NULL
    if fb.getDefNameProperty(b.ptr, id):
        return Box.from_ptr(id)

def extract_name(Box full_label) -> str:
    """Extract the name from a label.

    full_label the label to be analyzed

    returns the extracted name
    """
    return fb.extractName(full_label.ptr).decode()

def create_lib_context():
    """Create global compilation context, has to be done first."""
    fb.createLibContext()

def destroy_lib_context():
    """Destroy global compilation context, has to be done last."""
    fb.destroyLibContext()


# cdef void* get_user_data(Box b):
#     """Return the xtended type of a box.

#     b - the box whose xtended type to return

#     returns a pointer to xtended type if it exists, otherwise nullptr.
#     """
#     return fb.getUserData(b.ptr)


def box_is_nil(Box b) -> bool:
    """Check if a box is nil.

    b - the box

    returns true if the box is nil, otherwise false.
    """
    return fb.isNil(b.ptr)


def tree2str(Box b) -> str:
    """Convert a box (such as the label of a UI) to a string.

    b - the box to convert

    returns a string representation of a box.
    """
    return fb.tree2str(b.ptr).decode()


def tree2int(Box b) -> int:
    """If t has a node of type int, return it. Otherwise error

    b - the box to convert

    returns the int value of the box.
    """
    return fb.tree2int(b.ptr)



def box_int(int n) -> Box:
    """Constant integer : for all t, x(t) = n.

    n - the integer

    returns the integer box.
    """
    cdef fb.Box b = fb.boxInt(n)
    return Box.from_ptr(b)


def box_float(float n) -> Box:
    """Constant real : for all t, x(t) = n.

    n - the float/double value (depends of -single or -double compilation parameter)

    returns the float/double box.
    """
    cdef fb.Box b = fb.boxReal(n)
    return Box.from_ptr(b)

box_real = box_float


def box_wire() -> Box:
    """The identity box, copy its input to its output.

    returns the identity box.
    """
    cdef fb.Box b = fb.boxWire()
    return Box.from_ptr(b)


def box_cut() -> Box:
    """The cut box, to stop/terminate a signal.

    returns the cut box.
    """
    cdef fb.Box b = fb.boxCut()
    return Box.from_ptr(b)


def box_seq(Box x, Box y) -> Box:
    """The sequential composition of two blocks (e.g., A:B)
    expects: outputs(A)=inputs(B)

    returns the seq box.
    """
    cdef fb.Box b = fb.boxSeq(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_par(Box x, Box y) -> Box:
    """The parallel composition of two blocks (e.g., A,B).

    It places the two block-diagrams one on top of the other,
    without connections.

    returns the par box.
    """
    cdef fb.Box b = fb.boxPar(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_par3(Box x, Box y, Box z) -> Box:
    """The parallel composition of three blocks (e.g., A,B,C).
    
    It places the three block-diagrams one on top of the other,
    without connections.

    returns the par box.    
    """
    cdef fb.Box b = fb.boxPar3(x.ptr, y.ptr, z.ptr)
    return Box.from_ptr(b)


def box_par4(Box a, Box b, Box c, Box d) -> Box:
    """The parallel composition of four blocks (e.g., A,B,C,D).

    It places the four block-diagrams one on top of the other,
    without connections.

    returns the par box.
    """
    cdef fb.Box p = fb.boxPar4(a.ptr, b.ptr, c.ptr, d.ptr)
    return Box.from_ptr(p)


def box_par5(Box a, Box b, Box c, Box d, Box e) -> Box:
    """The parallel composition of five blocks (e.g., A,B,C,D,E).

    It places the five block-diagrams one on top of the other,
    without connections.

    returns the par box.
    """
    cdef fb.Box p = fb.boxPar5(a.ptr, b.ptr, c.ptr, d.ptr, e.ptr)
    return Box.from_ptr(p)

def box_split(Box x, Box y) -> Box:
    """The split composition (e.g., A<:B) operator is used to distribute
    the outputs of A to the inputs of B.

    For the operation to be valid, the number of inputs of B
    must be a multiple of the number of outputs of A:
    outputs(A).k=inputs(B)

    returns the split box.
    """
    cdef fb.Box b = fb.boxSplit(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_merge(Box x, Box y) -> Box:
    """The merge composition (e.g., A:>B) is the dual of the split composition.

    The number of outputs of A must be a multiple of the number of inputs of B:
    outputs(A)=k.inputs(B)

    returns the merge box.
    """
    cdef fb.Box b = fb.boxMerge(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_rec(Box x, Box y) -> Box:
    """The recursive composition (e.g., A~B) is used to create cycles
    in the block-diagram in order to express recursive computations.

    It is the most complex operation in terms of connections:
    outputs(A)≥inputs(B) and inputs(A)≥outputs(B)

    returns the rec box.
    """
    cdef fb.Box b = fb.boxRec(x.ptr, y.ptr)
    return Box.from_ptr(b)

def box_route(Box n, Box m, Box r) -> Box:
    """The route primitive facilitates the routing of signals in Faust.

    It has the following syntax:
    route(A,B,a,b,c,d,...) or route(A,B,(a,b),(c,d),...)

    n - the number of input signals
    m - the number of output signals
    r - the routing description, a 'par' expression of
        a,b / (a,b) input/output pairs

    returns the route box.
    """
    cdef fb.Box b = fb.boxRoute(n.ptr, m.ptr, r.ptr)
    return Box.from_ptr(b)


def box_delay_op() -> Box:
    """Create a delayed box.

    returns the delayed box.
    """
    cdef fb.Box b = fb.boxDelay()
    return Box.from_ptr(b)


def box_delay(Box b, Box d) -> Box:
    """Create a delayed box.

    s - the box to be delayed
    d - the delay box that doesn't have to be fixed but must be bounded
        and cannot be negative

    returns the delayed box.
    """
    cdef fb.Box _b = fb.boxDelay(b.ptr, d.ptr)
    return Box.from_ptr(_b)


def box_int_cast_op() -> Box:
    """Create a casted box.

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxIntCast()
    return Box.from_ptr(_b)


def box_int_cast(Box b) -> Box:
    """Create a casted box.

    s - the box to be casted in integer

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxIntCast(b.ptr)
    return Box.from_ptr(_b)


def box_float_cast_op() -> Box:
    """Create a casted box."""
    cdef fb.Box _b = fb.boxFloatCast()
    return Box.from_ptr(_b)


def box_float_cast(Box b) -> Box:
    """Create a casted box.

    s - the signal to be casted as float/double value (depends of 
        -single or -double compilation parameter)

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxFloatCast(b.ptr)
    return Box.from_ptr(_b)


def box_readonly_table_op() -> Box:
    """Create a read only table.

    returns the table box.
    """
    cdef fb.Box b = fb.boxReadOnlyTable()
    return Box.from_ptr(b)


def box_readonly_table(Box n, Box init, Box ridx) -> Box:
    """Create a read only table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    ridx - the read index (an int between 0 and n-1)

    returns the table box.
    """
    cdef fb.Box b = fb.boxReadOnlyTable(n.ptr, init.ptr, ridx.ptr)
    return Box.from_ptr(b)

def box_write_read_table_op() -> Box:
    """Create a read/write table.
    
    returns the table box.
    """
    cdef fb.Box b = fb.boxWriteReadTable()
    return Box.from_ptr(b)

def box_write_read_table(Box n, Box init, Box widx, Box wsig, Box ridx) -> Box:
    """Create a read/write table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    widx - the write index (an integer between 0 and n-1)
    wsig - the input of the table
    ridx - the read index (an integer between 0 and n-1)

    returns the table box.
    """
    cdef fb.Box b = fb.boxWriteReadTable(n.ptr, init.ptr, widx.ptr, wsig.ptr, ridx.ptr)
    return Box.from_ptr(b)


def box_waveform(BoxVector wf):
    """Create a waveform.

    wf - the content of the waveform as a vector of boxInt or boxDouble boxes

    returns the waveform box.
    """
    cdef fb.Box b = fb.boxWaveform(<const fs.tvec>wf.ptr)
    return Box.from_ptr(b)


def box_soundfile(str label, chan: Box | int, part: Box | None, ridx: Box | int | None) -> Box:
    """Create a soundfile block.

    label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
    chan - the number of outputs channels, a constant numerical expression (see [1])

    (box_soundfile2 parameters)
    part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])
    ridx - the read index (an integer between 0 and the selected sound length)

    returns the soundfile box.
    """
    _chan = box_or_int(chan)
    if part and ridx:
        _ridx = box_or_int(ridx)
        return __box_soundfile2(label, _chan, part, _ridx)
    else:
        return __box_soundfile1(label, _chan)


cdef Box __box_soundfile1(str label, Box chan):
    """Create a soundfile block.

    label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
    chan - the number of outputs channels, a constant numerical expression (see [1])

    returns the soundfile box.
    """
    cdef fb.Box b = fb.boxSoundfile(label.encode('utf8'), chan.ptr)
    return Box.from_ptr(b)


cdef Box __box_soundfile2(str label, Box chan, Box part, Box ridx):
    """Create a soundfile block.

    label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
    chan - the number of outputs channels, a constant numerical expression (see [1])
    part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])
    ridx - the read index (an integer between 0 and the selected sound length)

    returns the soundfile box.
    """
    cdef fb.Box b = fb.boxSoundfile(label.encode('utf8'), chan.ptr, part.ptr, ridx.ptr)
    return Box.from_ptr(b)


def box_select2(Box selector, Box b1, Box b2) -> Box:
    """Create a selector between two boxes.

    selector - when 0 at time t returns s1[t], otherwise returns s2[t]
    s1 - first box to be selected
    s2 - second box to be selected

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect2(selector.ptr, b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_select2_op() -> Box:
    """Create a selector between two boxes.

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect2()
    return Box.from_ptr(b)


def box_select3(Box selector, Box b1, Box b2, Box b3) -> Box:
    """Create a selector between three boxes.

    selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t], 
               otherwise returns s3[t]
    s1 - first box to be selected
    s2 - second box to be selected
    s3 - third box to be selected

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect3(selector.ptr, b1.ptr, b2.ptr, b3.ptr)
    return Box.from_ptr(b)

def box_fconst(fb.SType type, str name, str file) -> Box:
    """Create a foreign constant box.

    type - the foreign constant type of SType
    name - the foreign constant name
    file - the include file where the foreign constant is defined

    returns the foreign constant box.
    """
    cdef fb.Box b = fb.boxFConst(type, name.encode('utf8'), file.encode('utf8'))
    return Box.from_ptr(b)

def box_fvar(fb.SType type, str name, str file) -> Box:
    """Create a foreign variable box.

    type - the foreign variable type of SType
    name - the foreign variable name
    file - the include file where the foreign variable is defined

    returns the foreign variable box.
    """
    cdef fb.Box b = fb.boxFVar(type, name.encode('utf8'), file.encode('utf8'))
    return Box.from_ptr(b)

def box_bin_op0(fb.SOperator op) -> Box:
    """Generic binary mathematical functions.

    op - the operator in SOperator set

    returns the result box of op(x,y).
    """
    cdef fb.Box b = fb.boxBinOp(op)
    return Box.from_ptr(b)

def box_bin_op(fb.SOperator op, Box b1, Box b2) -> Box:
    """Generic binary mathematical functions.

    op - the operator in SOperator set

    returns the result box of op(x,y).
    """
    cdef fb.Box b = fb.boxBinOp(op, b1.ptr, b2.ptr)
    return Box.from_ptr(b)



def box_add_op() -> Box:
    cdef fb.Box b = fb.boxAdd()
    return Box.from_ptr(b)

def box_add(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxAdd(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_sub_op() -> Box:
    cdef fb.Box b = fb.boxSub()
    return Box.from_ptr(b)

def box_sub(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxSub(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_mul_op() -> Box:
    cdef fb.Box b = fb.boxMul()
    return Box.from_ptr(b)

def box_mul(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxMul(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_div_op() -> Box:
    cdef fb.Box b = fb.boxDiv()
    return Box.from_ptr(b)

def box_div(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxDiv(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_rem_op() -> Box:
    cdef fb.Box b = fb.boxRem()
    return Box.from_ptr(b)

def box_rem(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxRem(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_leftshift_op() -> Box:
    cdef fb.Box b = fb.boxLeftShift()
    return Box.from_ptr(b)

def box_leftshift(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLeftShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_lrightshift_op() -> Box:
    cdef fb.Box b = fb.boxLRightShift()
    return Box.from_ptr(b)

def box_lrightshift(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLRightShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_arightshift_op() -> Box:
    cdef fb.Box b = fb.boxARightShift()
    return Box.from_ptr(b)

def box_arightshift(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxARightShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_gt_op() -> Box:
    cdef fb.Box b = fb.boxGT()
    return Box.from_ptr(b)

def box_gt(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxGT(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_lt_op() -> Box:
    cdef fb.Box b = fb.boxLT()
    return Box.from_ptr(b)

def box_lt(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLT(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_ge_op() -> Box:
    cdef fb.Box b = fb.boxGE()
    return Box.from_ptr(b)

def box_ge(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxGE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_le_op() -> Box:
    cdef fb.Box b = fb.boxLE()
    return Box.from_ptr(b)

def box_le(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxLE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_eq_op() -> Box:
    cdef fb.Box b = fb.boxEQ()
    return Box.from_ptr(b)

def box_eq(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxEQ(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_ne_op() -> Box:
    cdef fb.Box b = fb.boxNE()
    return Box.from_ptr(b)

def box_ne(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxNE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_and_op() -> Box:
    cdef fb.Box b = fb.boxAND()
    return Box.from_ptr(b)

def box_and(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxAND(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_or_op() -> Box:
    cdef fb.Box b = fb.boxOR()
    return Box.from_ptr(b)

def box_or(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxOR(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_xor_op() -> Box:
    cdef fb.Box b = fb.boxXOR()
    return Box.from_ptr(b)

def box_xor(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxXOR(b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_abs_op() -> Box:
    cdef fb.Box b = fb.boxAbs()
    return Box.from_ptr(b)

def box_abs(Box x) -> Box:
    cdef fb.Box b = fb.boxAbs(x.ptr)
    return Box.from_ptr(b)

def box_acos_op() -> Box:
    cdef fb.Box b = fb.boxAcos()
    return Box.from_ptr(b)

def box_acos(Box x) -> Box:
    cdef fb.Box b = fb.boxAcos(x.ptr)
    return Box.from_ptr(b)

def box_tan_op() -> Box:
    cdef fb.Box b = fb.boxTan()
    return Box.from_ptr(b)

def box_tan(Box x) -> Box:
    cdef fb.Box b = fb.boxTan(x.ptr)
    return Box.from_ptr(b)

def box_sqrt_op() -> Box:
    cdef fb.Box b = fb.boxSqrt()
    return Box.from_ptr(b)

def box_sqrt(Box x) -> Box:
    cdef fb.Box b = fb.boxSqrt(x.ptr)
    return Box.from_ptr(b)

def box_sin_op() -> Box:
    cdef fb.Box b = fb.boxSin()
    return Box.from_ptr(b)

def box_sin(Box x) -> Box:
    cdef fb.Box b = fb.boxSin(x.ptr)
    return Box.from_ptr(b)

def box_rint_op() -> Box:
    cdef fb.Box b = fb.boxRint()
    return Box.from_ptr(b)

def box_rint(Box x) -> Box:
    cdef fb.Box b = fb.boxRint(x.ptr)
    return Box.from_ptr(b)

def box_round_op() -> Box:
    cdef fb.Box b = fb.boxRound()
    return Box.from_ptr(b)

def box_round(Box x) -> Box:
    cdef fb.Box b = fb.boxRound(x.ptr)
    return Box.from_ptr(b)

def box_log_op() -> Box:
    cdef fb.Box b = fb.boxLog()
    return Box.from_ptr(b)

def box_log(Box x) -> Box:
    cdef fb.Box b = fb.boxLog(x.ptr)
    return Box.from_ptr(b)

def box_log10_op() -> Box:
    cdef fb.Box b = fb.boxLog10()
    return Box.from_ptr(b)

def box_log10(Box x) -> Box:
    cdef fb.Box b = fb.boxLog10(x.ptr)
    return Box.from_ptr(b)

def box_floor_op() -> Box:
    cdef fb.Box b = fb.boxFloor()
    return Box.from_ptr(b)

def box_floor(Box x) -> Box:
    cdef fb.Box b = fb.boxFloor(x.ptr)
    return Box.from_ptr(b)

def box_exp_op() -> Box:
    cdef fb.Box b = fb.boxExp()
    return Box.from_ptr(b)

def box_exp(Box x) -> Box:
    cdef fb.Box b = fb.boxExp(x.ptr)
    return Box.from_ptr(b)

def box_exp10_op() -> Box:
    cdef fb.Box b = fb.boxExp10()
    return Box.from_ptr(b)

def box_exp10(Box x) -> Box:
    cdef fb.Box b = fb.boxExp10(x.ptr)
    return Box.from_ptr(b)

def box_cos_op() -> Box:
    cdef fb.Box b = fb.boxCos()
    return Box.from_ptr(b)

def box_cos(Box x) -> Box:
    cdef fb.Box b = fb.boxCos(x.ptr)
    return Box.from_ptr(b)

def box_ceil_op() -> Box:
    cdef fb.Box b = fb.boxCeil()
    return Box.from_ptr(b)

def box_ceil(Box x) -> Box:
    cdef fb.Box b = fb.boxCeil(x.ptr)
    return Box.from_ptr(b)

def box_atan_op() -> Box:
    cdef fb.Box b = fb.boxAtan()
    return Box.from_ptr(b)

def box_atan(Box x) -> Box:
    cdef fb.Box b = fb.boxAtan(x.ptr)
    return Box.from_ptr(b)

def box_asin_op() -> Box:
    cdef fb.Box b = fb.boxAsin()
    return Box.from_ptr(b)

def box_asin(Box x) -> Box:
    cdef fb.Box b = fb.boxAsin(x.ptr)
    return Box.from_ptr(b)



def box_remainder_op() -> Box:
    cdef fb.Box b = fb.boxRemainder()
    return Box.from_ptr(b)

def box_remainder(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxRemainder(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_pow_op() -> Box:
    cdef fb.Box b = fb.boxPow()
    return Box.from_ptr(b)

def box_pow(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxPow(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_min_op() -> Box:
    cdef fb.Box b = fb.boxMin()
    return Box.from_ptr(b)

def box_min(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxMin(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_max_op() -> Box:
    cdef fb.Box b = fb.boxMax()
    return Box.from_ptr(b)

def box_max(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxMax(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_fmod_op() -> Box:
    cdef fb.Box b = fb.boxFmod()
    return Box.from_ptr(b)

def box_fmod(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxFmod(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_atan2_op() -> Box:
    cdef fb.Box b = fb.boxAtan2()
    return Box.from_ptr(b)

def box_atan2(Box b1, Box b2) -> Box:
    cdef fb.Box b = fb.boxAtan2(b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_button(str label) -> Box:
    """Create a button box.

    label - the label definition (see [2])

    returns the button box.
    """
    cdef fb.Box b = fb.boxButton(label.encode('utf8'))
    return Box.from_ptr(b)


def box_checkbox(str label) -> Box:
    """Create a checkbox box.

    label - the label definition (see [2])

    returns the checkbox box.
    """
    cdef fb.Box b = fb.boxCheckbox(label.encode('utf8'))
    return Box.from_ptr(b)


def box_vslider(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create a vertical slider box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression (see [1])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    step - the step box, a constant numerical expression (see [1])

    returns the vertical slider box.
    """
    cdef fb.Box b = fb.boxVSlider(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)

def box_hslider(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create an horizontal slider box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression (see [1])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    step - the step box, a constant numerical expression (see [1])

    returns the horizontal slider box.
    """
    cdef fb.Box b = fb.boxHSlider(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)

def box_numentry(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create a num entry box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression (see [1])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    step - the step box, a constant numerical expression (see [1])

    returns the num entry box.
    """
    cdef fb.Box b = fb.boxNumEntry(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)


def box_vbargraph(str label, Box min, Box max) -> Box:
    """Create a vertical bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the vertical bargraph box.
    """
    cdef fb.Box b = fb.boxVBargraph(label.encode('utf8'), min.ptr, max.ptr)
    return Box.from_ptr(b)

def box_vbargraph2(str label, Box min, Box max, Box x) -> Box:
    """Create a vertical bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the vertical bargraph box.
    """
    cdef fb.Box b = fb.boxVBargraph(label.encode('utf8'), min.ptr, max.ptr, x.ptr)
    return Box.from_ptr(b)

def box_hbargraph(str label, Box min, Box max) -> Box:
    """Create a horizontal bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the horizontal bargraph box.
    """
    cdef fb.Box b = fb.boxHBargraph(label.encode('utf8'), min.ptr, max.ptr)
    return Box.from_ptr(b)

def box_hbargraph2(str label, Box min, Box max, Box x) -> Box:
    """Create a horizontal bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression (see [1])
    max - the max box, a constant numerical expression (see [1])
    x - the input box

    returns the horizontal bargraph box.
    """
    cdef fb.Box b = fb.boxHBargraph(label.encode('utf8'), min.ptr, max.ptr, x.ptr)
    return Box.from_ptr(b)


def box_vgroup(str label, Box group) -> Box:
    """Create a vertical group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the vertical group box.
    """
    cdef fb.Box b = fb.boxVGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)


def box_hgroup(str label, Box group) -> Box:
    """Create a horizontal group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the horizontal group box.
    """
    cdef fb.Box b = fb.boxHGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)

def box_tgroup(str label, Box group) -> Box:
    """Create a tab group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the tab group box.
    """
    cdef fb.Box b = fb.boxTGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)

def box_attach_op() -> Box:
    """Create an attach box.

    returns the attach box.
    """
    cdef fb.Box b = fb.boxAttach()
    return Box.from_ptr(b)


def box_attach(Box b1, Box b2) -> Box:
    """Create an attach box.

    The attach primitive takes two input boxes and produces one output box
    which is a copy of the first input. The role of attach is to force
    its second input boxes to be compiled with the first one.

    returns the attach box.
    """
    cdef fb.Box b = fb.boxAttach(b1.ptr, b2.ptr)
    return Box.from_ptr(b)


# cdef fb.Box box_prim2(fb.prim2 foo):
#     return fb.boxPrim2(foo)

def is_box_abstr(Box t) -> bool:
    return fb.isBoxAbstr(t.ptr)

def getparams_box_abstr(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxAbstr(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def getparams_box_access(Box t) -> dict:
    cdef fb.Box exp = NULL
    cdef fb.Box id = NULL
    if fb.isBoxAccess(t.ptr, exp, id):
        return dict(
            exp=Box.from_ptr(exp),
            id=Box.from_ptr(id),
        )
    else:
        return {}

def is_box_appl(Box t) -> bool:
    return fb.isBoxAppl(t.ptr)

def getparams_box_appl(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxAppl(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def is_box_button(Box b) -> bool:
    return fb.isBoxButton(b.ptr)

def getparams_box_button(Box b) -> dict:
    cdef fb.Box lbl = NULL
    if fb.isBoxButton(b.ptr, lbl):
        return dict(
            lbl=Box.from_ptr(lbl),
        )
    else:
        return {}

def is_box_case(Box b) -> bool:
    return fb.isBoxCase(b.ptr)

def getparams_box_case(Box b) -> dict:
    cdef fb.Box rules = NULL
    if fb.isBoxCase(b.ptr, rules):
        return dict(
            rules=Box.from_ptr(rules),
        )
    else:
        return {}

def is_box_checkbox(Box b) -> bool:
    return fb.isBoxCheckbox(b.ptr)

def getparams_box_checkbox(Box b) -> dict:
    cdef fb.Box lbl = NULL
    if fb.isBoxCheckbox(b.ptr, lbl):
        return dict(
            lbl=Box.from_ptr(lbl),
        )
    else:
        return {}

def getparams_box_component(Box b) -> dict:
    cdef fb.Box filename = NULL
    if fb.isBoxComponent(b.ptr, filename):
        return dict(
            filename=Box.from_ptr(filename),
        )
    else:
        return {}

def is_box_cut(Box t) -> bool:
    return fb.isBoxCut(t.ptr)

def is_box_environment(Box b) -> bool:
    return fb.isBoxEnvironment(b.ptr)

def is_box_error(Box t) -> bool:
    return fb.isBoxError(t.ptr)

def is_box_fconst(Box b) -> bool:
    return fb.isBoxFConst(b.ptr)

def getparams_box_fconst(Box b) -> dict:
    cdef fb.Box type = NULL
    cdef fb.Box name = NULL
    cdef fb.Box file = NULL
    if fb.isBoxFConst(b.ptr, type, name, file):
        return dict(
            type=Box.from_ptr(type),
            name=Box.from_ptr(name),
            file=Box.from_ptr(file),
        )
    else:
        return {}

def is_box_ffun(Box b) -> bool:
    return fb.isBoxFFun(b.ptr)

def getparams_box_ffun(Box b) -> dict:
    cdef fb.Box ff = NULL
    if fb.isBoxFFun(b.ptr, ff):
        return dict(
            ff=Box.from_ptr(ff),
        )
    else:
        return {}

def is_box_fvar(Box b) -> bool:
    return fb.isBoxFVar(b.ptr)

def getparams_box_fvar(Box b) -> dict:
    cdef fb.Box type = NULL
    cdef fb.Box name = NULL
    cdef fb.Box file = NULL
    if fb.isBoxFVar(b.ptr, type, name, file):
        return dict(
            type=Box.from_ptr(type),
            name=Box.from_ptr(name),
            file=Box.from_ptr(file),
        )
    else:
        return {}

def is_box_hbargraph(Box b) -> bool:
    return fb.isBoxHBargraph(b.ptr)

def getparams_box_hbargraph(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    if fb.isBoxHBargraph(b.ptr, lbl, min, max):
        return dict(
            lbl=Box.from_ptr(lbl),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
        )
    else:
        return {}

def is_box_hgroup(Box b) -> bool:
    return fb.isBoxHGroup(b.ptr)

def getparams_box_hgroup(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box x = NULL
    if fb.isBoxHGroup(b.ptr, lbl, x):
        return dict(
            lbl=Box.from_ptr(lbl),
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_hslider(Box b) -> bool:
    return fb.isBoxHSlider(b.ptr)

def getparams_box_hslider(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box cur = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    cdef fb.Box step = NULL
    if fb.isBoxHSlider(b.ptr, lbl, cur, min, max, step):
        return dict(
            lbl=Box.from_ptr(lbl),
            cur=Box.from_ptr(cur),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
            step=Box.from_ptr(step),
        )
    else:
        return {}

def is_box_ident(Box t) -> bool:
    return fb.isBoxIdent(t.ptr)

def get_box_id(Box t) -> str | None:
    cdef const char** cstr = <const char**> malloc(1024 * sizeof(char*))
    if fb.isBoxIdent(t.ptr, cstr):
        return cstr[0].decode()


def getparams_box_inputs(Box t) -> dict:
    cdef fb.Box x = NULL
    if fb.isBoxInputs(t.ptr, x):
        return dict(
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_int(Box t) -> bool:
    return fb.isBoxInt(t.ptr)

def getparams_box_int(Box t) -> dict:
    cdef int i = 0
    if fb.isBoxInt(t.ptr, &i):
        return dict(
            i=i,
        )
    else:
        return {}

def getparams_box_ipar(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxIPar(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_iprod(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxIProd(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_iseq(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxISeq(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_isum(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxISum(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_library(Box b) -> dict:
    cdef fb.Box filename = NULL
    if fb.isBoxLibrary(b.ptr, filename):
        return dict(
            filename=Box.from_ptr(filename),
        )
    else:
        return {}

def getparams_box_merge(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxMerge(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def getparams_box_metadata(Box b) -> dict:
    cdef fb.Box exp = NULL
    cdef fb.Box mdlist = NULL
    if fb.isBoxMetadata(b.ptr, exp, mdlist):
        return dict(
            exp=Box.from_ptr(exp),
            mdlist=Box.from_ptr(mdlist),
        )
    else:
        return {}

def is_box_numentry(Box b) -> bool:
    return fb.isBoxNumEntry(b.ptr)

def getparams_box_num_entry(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box cur = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    cdef fb.Box step = NULL
    if fb.isBoxNumEntry(b.ptr, lbl, cur, min, max, step):
        return dict(
            lbl=Box.from_ptr(lbl),
            cur=Box.from_ptr(cur),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
            step=Box.from_ptr(step),
        )
    else:
        return {}

def getparams_box_outputs(Box t) -> dict:
    cdef fb.Box x = NULL
    if fb.isBoxOutputs(t.ptr, x):
        return dict(
            x=Box.from_ptr(x),
        )
    else:
        return {}

def getparams_box_par(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxPar(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}




def is_box_prim0_(Box b) -> bool:
    cdef fb.prim0 p
    return fb.isBoxPrim0(b.ptr, &p)

def is_box_prim1_(Box b) -> bool:
    cdef fb.prim1 p
    return fb.isBoxPrim1(b.ptr, &p)

def is_box_prim2_(Box b) -> bool:
    cdef fb.prim2 p
    return fb.isBoxPrim2(b.ptr, &p)

def is_box_prim3_(Box b) -> bool:
    cdef fb.prim3 p
    return fb.isBoxPrim3(b.ptr, &p)

def is_box_prim4_(Box b) -> bool:
    cdef fb.prim4 p
    return fb.isBoxPrim4(b.ptr, &p)

def is_box_prim5_(Box b) -> bool:
    cdef fb.prim5 p
    return fb.isBoxPrim5(b.ptr, &p)


def is_box_prim0(Box b) -> bool:
    return fb.isBoxPrim0(b.ptr)

def is_box_prim1(Box b) -> bool:
    return fb.isBoxPrim1(b.ptr)

def is_box_prim2(Box b) -> bool:
    return fb.isBoxPrim2(b.ptr)

def is_box_prim3(Box b) -> bool:
    return fb.isBoxPrim3(b.ptr)

def is_box_prim4(Box b) -> bool:
    return fb.isBoxPrim4(b.ptr)

def is_box_prim5(Box b) -> bool:
    return fb.isBoxPrim5(b.ptr)



def is_box_real(Box t) -> bool:
    return fb.isBoxReal(t.ptr)

def getparams_box_real(Box t) -> dict:
    cdef double r
    if fb.isBoxReal(t.ptr, &r):
        return dict(
            r=r,
        )
    else:
        return {}

def getparams_box_rec(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxRec(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def getparams_box_route(Box b) -> dict:
    cdef fb.Box n = NULL
    cdef fb.Box m = NULL
    cdef fb.Box r = NULL
    if fb.isBoxRoute(b.ptr, n, m, r):
        return dict(
            n=Box.from_ptr(n),
            m=Box.from_ptr(m),
            r=Box.from_ptr(r),
        )
    else:
        return {}

def getparams_box_seq(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxSeq(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def is_box_slot(Box t) -> bool:
    return fb.isBoxSlot(t.ptr)

def getparams_box_slot(Box t) -> dict:
    cdef int id = 0
    if fb.isBoxSlot(t.ptr, &id):
        return dict(
            id=id,
        )
    else:
        return {}

def is_box_soundfile(Box b) -> bool:
    return fb.isBoxSoundfile(b.ptr)

def getparams_box_soundfile(Box b) -> dict:
    cdef fb.Box label = NULL
    cdef fb.Box chan = NULL
    if fb.isBoxSoundfile(b.ptr, label, chan):
        return dict(
            label=Box.from_ptr(label),
            chan=Box.from_ptr(chan),
        )
    else:
        return {}

def getparams_box_split(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxSplit(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def is_box_symbolic(Box t) -> bool:
    return fb.isBoxSymbolic(t.ptr)

def getparams_box_symbolic(Box t) -> dict:
    cdef fb.Box slot = NULL
    cdef fb.Box body = NULL
    if fb.isBoxSymbolic(t.ptr, slot, body):
        return dict(
            slot=Box.from_ptr(slot),
            body=Box.from_ptr(body),
        )
    else:
        return {}

def is_box_tgroup(Box b) -> bool:
    return fb.isBoxTGroup(b.ptr)

def getparams_box_tgroup(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box x = NULL
    if fb.isBoxTGroup(b.ptr, lbl, x):
        return dict(
            lbl=Box.from_ptr(lbl),
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_vbargraph(Box b) -> bool:
    return fb.isBoxVBargraph(b.ptr)

def getparams_box_vbargraph(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    if fb.isBoxVBargraph(b.ptr, lbl, min, max):
        return dict(
            lbl=Box.from_ptr(lbl),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
        )
    else:
        return {}

def is_box_vgroup(Box b) -> bool:
    return fb.isBoxVGroup(b.ptr)

def getparams_box_vgroup(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box x = NULL
    if fb.isBoxVGroup(b.ptr, lbl, x):
        return dict(
            lbl=Box.from_ptr(lbl),
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_vslider(Box b) -> bool:
    return fb.isBoxVSlider(b.ptr)

def getparams_box_vslider(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box cur = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    cdef fb.Box step = NULL
    if fb.isBoxVSlider(b.ptr, lbl, cur, min, max, step):
        return dict(
            lbl=Box.from_ptr(lbl),
            cur=Box.from_ptr(cur),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
            step=Box.from_ptr(step),
        )
    else:
        return {}

def is_box_waveform(Box b) -> bool:
    return fb.isBoxWaveform(b.ptr)

def is_box_wire(Box t) -> bool:
    return fb.isBoxWire(t.ptr)

def getparams_box_with_local_def(Box t) -> dict:
    cdef fb.Box body = NULL
    cdef fb.Box ldef = NULL
    if fb.isBoxWithLocalDef(t.ptr, body, ldef):
        return dict(
            body=Box.from_ptr(body),
            ldef=Box.from_ptr(ldef),
        )
    else:
        return {}


def dsp_to_boxes(str name_app, str dsp_content, *args) -> Box:
    """Compile a DSP source code as a string in a flattened box

    name_app - the name of the Faust program
    dsp_content - the Faust program as a string
    argc - the number of parameters in argv array
    argv - the array of parameters
    inputs - the place to return the number of inputs of the resulting box
    outputs - the place to return the number of outputs of the resulting box
    error_msg - the error string to be filled

    returns a flattened box on success, otherwise a null pointer.
    """
    cdef ParamArray params = ParamArray(args)
    cdef int inputs, outputs
    cdef string error_msg
    error_msg.reserve(4096)
    cdef fb.Box b = fb.DSPToBoxes(
        name_app.encode('utf8'),
        dsp_content.encode('utf8'),
        params.argc,
        params.argv,
        &inputs,
        &outputs,
        error_msg,
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return Box.from_ptr(b)


def get_box_type(Box b) -> tuple[int, int] | None:
    """Return the number of inputs and outputs of a box

    box - the box we want to know the number of inputs and outputs
    inputs - the place to return the number of inputs
    outputs - the place to return the number of outputs

    returns true if type is defined, false if undefined.
    """
    cdef int inputs, outputs
    if fb.getBoxType(b.ptr, &inputs, &outputs):
        return (inputs, outputs)

def boxes_to_signals(Box b) -> SignalVector | None:
    """Compile a box expression in a list of signals in normal form
    (see simplifyToNormalForm in libfaust-signal.h)

    box - the box expression
    error_msg - the error string to be filled

    returns a list of signals in normal form on success, otherwise an empty list.
    """
    cdef string error_msg
    error_msg.reserve(4096)
    cdef fs.tvec vec = fb.boxesToSignals(b.ptr, error_msg)
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return SignalVector.from_ptr(vec)


def create_source_from_boxes(str name_app, Box box, str lang, *args) -> str:
    """Create source code in a target language from a box expression.

    name_app - the name of the Faust program
    box - the box expression
    lang - the target source code's language which can be one of 
        'c', 'cpp', 'cmajor', 'codebox', 'csharp', 'dlang', 'fir', 
        'interp', 'java', 'jax','jsfx', 'julia', 'ocpp', 'rust' or 'wast'
        (depending of which of the corresponding backends are compiled in libfaust)
    argc - the number of parameters in argv array
    argv - the array of parameters
    error_msg - the error string to be filled

    returns a string of source code on success, setting error_msg on error.
    """
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    cdef string code = fb.createSourceFromBoxes(
        name_app.encode('utf8'),
        box.ptr,
        lang.encode('utf8'),
        params.argc,
        params.argv, 
        error_msg)
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return code.decode()


## ---------------------------------------------------------------------------
## faust/dsp/libfaust-signal
##


def sig_or_float(var):
    if isinstance(var, float):
        return Signal.from_real(var)
    elif isinstance(var, Signal):
        assert is_sig_real(var), "signal is not a float Signal"
        return var
    raise TypeError("argument must be an float or a sigReal")

def sig_or_int(var):
    if isinstance(var, int):
        return Signal.from_int(var)
    elif isinstance(var, Signal):
        assert is_sig_int(var), "signal is not an int Signal"
        return var
    raise TypeError("argument must be an int")


class signal_context:
    def __enter__(self):
        # Create global compilation context, has to be done first.
        fs.createLibContext()
    def __exit__(self, type, value, traceback):
        # Destroy global compilation context, has to be done last.
        fs.destroyLibContext()


cdef class SignalVector:
    """wraps tvec: a std::vector<CTree*>"""
    cdef vector[fs.Signal] ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr_owner = False

    def __iter__(self):
        for i in self.ptr:
            yield Signal.from_ptr(i)

    @staticmethod
    cdef SignalVector from_ptr(fs.tvec ptr):
        """Wrap a fs.tvec instance."""
        cdef SignalVector sv = SignalVector.__new__(SignalVector)
        sv.ptr = ptr
        return sv

    cdef add_ptr(self, fs.Signal sig):
        self.ptr.push_back(sig)

    def add(self, Signal sig):
        self.ptr.push_back(sig.ptr)

    def create_source(self, name_app: str, lang, *args) -> str:
        """Create source code in a target language from a signal expression."""
        return create_source_from_signals(name_app, self, lang, *args)

    def simplify_to_normal_form(self) -> SignalVector:
        """Simplify a signal list to its normal form.

        returns the signal vector in normal form.
        """
        return simplify_to_normal_form2(self)



cdef class Interval:
    """wraps fs.Interval struct/class"""
    cdef fs.Interval *ptr

    def __dealloc__(self):
        if self.ptr:
            del self.ptr

    def __cinit__(self, double lo, double hi, int lsb):
        self.ptr = new fs.Interval(lo, hi, lsb)

    @staticmethod
    cdef Interval from_ptr(fs.Interval* ptr):
        """Wrap Interval from pointer"""
        cdef Interval ival = Interval.__new__(Interval)
        ival.ptr = ptr
        return ival

    @property
    def low(self) -> float:
        return self.ptr.fLo

    @property
    def high(self) -> float:
        return self.ptr.fHi

    @property
    def lsb(self) -> float:
        return self.ptr.fLSB


cdef class Signal:
    """faust Signal wrapper.
    """
    cdef fs.Signal ptr

    def __cinit__(self):
        self.ptr = NULL

    @staticmethod
    cdef Signal from_ptr(fs.Signal ptr, bint ptr_owner=False):
        """Wrap Signal from pointer"""
        cdef Signal sig = Signal.__new__(Signal)
        sig.ptr = ptr
        return sig

    @staticmethod
    def from_input(int idx) -> Signal:
        """Create signal from int"""
        return sig_input(idx)

    @staticmethod
    def from_int(int value) -> Signal:
        """Create signal from int"""
        return sig_int(value)

    @staticmethod
    def from_float(float value) -> Signal:
        """Create signal from float"""
        return sig_real(value)

    from_real = from_float

    @staticmethod
    def from_soundfile(str label) -> Signal:
        """Create signal from soundfile."""
        return sig_soundfile(label)

    @staticmethod
    def from_button(str label) -> Signal:
        """Create a button signal."""
        return sig_button(label)

    @staticmethod
    def from_checkbox(str label) -> Signal:
        """Create a checkbox signal."""
        return sig_checkbox(label)

    @staticmethod
    def from_vslider(str label, init: float | Signal, min: float | Signal, 
                                max: float | Signal, step: float | Signal) -> Signal:
        """Create a vertical slider signal."""
        _init = sig_or_float(init)
        _min = sig_or_float(min)
        _max = sig_or_float(max)
        _step = sig_or_float(step)
        return sig_vslider(label, _init, _min, _max, _step)

    @staticmethod
    def from_hslider(str label, init: float | Signal, min: float | Signal, 
                                max: float | Signal, step: float | Signal) -> Signal:
        """Create a horizontal slider signal."""
        _init = sig_or_float(init)
        _min = sig_or_float(min)
        _max = sig_or_float(max)
        _step = sig_or_float(step)
        return sig_hslider(label, _init, _min, _max, _step)

    @staticmethod
    def from_numentry(str label, init: float | Signal, min: float | Signal, 
                                max: float | Signal, step: float | Signal) -> Signal:
        """Create a num entry signal."""
        _init = sig_or_float(init)
        _min = sig_or_float(min)
        _max = sig_or_float(max)
        _step = sig_or_float(step)
        return sig_numentry(label, _init, _min, _max, _step)

    @staticmethod
    def from_read_only_table(n: int | Signal, Signal init, ridx: int | Signal):
        """Create a read-only table.

        n - the table size, a constant numerical expression (see [1])
        init - the table content
        ridx - the read index (an int between 0 and n-1)
     
        returns the table signal.
        """
        _n = sig_or_int(n)
        _ridx = sig_or_int(ridx)
        return sig_readonly_table(_n, init, _ridx)

    @staticmethod
    def from_write_read_table(int n, Signal init, int widx, Signal wsig, int ridx):
        """Create a read-write-only table.

        n - the table size, a constant numerical expression (see [1])
        init - the table content
        widx - the write index (an integer between 0 and n-1)
        wsig - the input of the table
        ridx - the read index (an int between 0 and n-1)
     
        returns the table signal.
        """
        _n = sig_or_int(n)
        _widx = sig_or_int(widx)
        _ridx = sig_or_int(ridx)
        return sig_write_read_table(_n, init, _widx, wsig, _ridx)


    def create_source(self, name_app: str, lang, *args) -> str:
        """Create source code in a target language from a signal expression."""
        return create_source_from_signals(name_app, lang, *args)

    def simplify_to_normal_form(self) -> Signal:
        """Simplify a signal to its normal form."""
        cdef fs.Signal s = fs.simplifyToNormalForm(self.ptr)
        return Signal.from_ptr(s)

    def to_string(self, shared: bool = False, max_size: int = 256) -> str:
        """retur this signal printed as a string."""
        return print_signal(self, shared, max_size)

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this signal."""
        print(print_signal(self, shared, max_size))

    def ffname(self) -> str:
        """Return the name parameter of a foreign function."""
        return ffname(self)

    def ffarity(self) -> int:
        """Return the arity of a foreign function."""
        return ffarity(self)

    # def get_interval(self) -> Interval:
    #     """Get the signal interval."""
    #     cdef fs.Interval *ival = <fs.Interval*>fs.getSigInterval(self.ptr)
    #     return Interval.from_ptr(ival)

    # def set_interval(self, Interval iv):
    #     """Set the signal interval."""
    #     fs.setSigInterval(self.ptr, iv.ptr)

    def attach(self, Signal other) -> Signal:
        """Create an attached signal from another signal
        
        The attach primitive takes two input signals and produces 
        one output signal which is a copy of the first input.

        The role of attach is to force the other input signal to be 
        compiled with this one.
        """
        return sig_attach(self, other)

    def vbargraph(self, str label, min: float | Signal, max: float | Signal) -> Signal:
        """Create a vertical bargraph signal from this signal"""
        _min = sig_or_float(min)
        _max = sig_or_float(max)
        return sig_vbargraph(label, _min, _max, self)

    def hbargraph(self, str label, min: float | Signal, max: float | Signal) -> Signal:
        """Create a horizontal bargraph signal from this signal"""
        _min = sig_or_float(min)
        _max = sig_or_float(max)
        return sig_hbargraph(label, _min, _max, self)

    def int_cast(self) -> Signal:
        """Create a casted signal.

        s - the signal to be casted in integer

        returns the casted signal.
        """
        return sig_int_cast(self)


    def float_cast(self) -> Signal:
        """Create a casted signal.

        s - the signal to be casted as float/double value (depends of -single or -double compilation parameter)

        returns the casted signal.
        """
        return sig_float_cast(self)


    def select2(self, Signal s1, Signal s2) -> Signal:
        """Create a selector between two signals.

        selector - when 0 at time t returns s1[t], otherwise returns s2[t]
        (selector is automatically wrapped with sigIntCast)
        s1 - first signal to be selected
        s2 - second signal to be selected

        returns the selected signal depending of the selector value at each time t.
        """
        return sig_select2(self, s1, s2)


    def select3(self, Signal s1, Signal s2, Signal s3) -> Signal:
        """Create a selector between three signals.

        selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t], otherwise returns s3[t]
        (selector is automatically wrapped with sigIntCast)
        s1 - first signal to be selected
        s2 - second signal to be selected
        s3 - third signal to be selected

        returns the selected signal depending of the selector value at each time t.
        """
        return sig_select3(self, s1, s2, s3)


    def recursion(self) -> Signal:
        """Create a recursive signal. 

        Use sigSelf() to refer to the recursive signal inside 
        the sigRecursion expression.
        
        s - the signal to recurse on.
        
        returns the signal with a recursion.
        """
        return sig_recursion(self)


    def self_rec(self) -> Signal:
        """Create a recursive signal inside the sigRecursion expression.

        returns the recursive signal.
        """
        return sig_self()

    def self_n(self, int id) -> Signal:
        """Create a recursive signal inside the sigRecursionN expression.

        id - the recursive signal index (starting from 0, up to the number of outputs signals in the recursive block)

        returns the recursive signal.
        """
        return sig_self_n(id)

    def recursion_n(self, SignalVector rf) -> SignalVector:
        """Create a recursive block of signals. 

        Use sigSelfN() to refer to the recursive signal inside 
        the sigRecursionN expression.

        rf - the list of signals to recurse on.

        returns the list of signals with recursions.
        """
        return sig_self_n(rf)


    def __add__(self, Signal other) -> Signal:
        """Add this signal to another."""
        return sig_add(self, other)

    def __radd__(self, Signal other) -> Signal:
        """Reverse add this signal to another."""
        return sig_add(self, other)

    def __sub__(self, Signal other) -> Signal:
        """Subtract this box from another."""
        return sig_sub(self, other)

    def __rsub__(self, Signal other) -> Signal:
        """Subtract this box from another."""
        return sig_sub(self, other)

    def __mul__(self, Signal other) -> Signal:
        """Multiply this box with another."""
        return sig_mul(self, other)

    def __rmul__(self, Signal other) -> Signal:
        """Reverse multiply this box with another."""
        return sig_mul(self, other)

    def __div__(self, Signal other) -> Signal:
        """Divide this box with another."""
        return sig_div(self, other)

    def __rdiv__(self, Signal other) -> Signal:
        """Reverse divide this box with another."""
        return sig_div(self, other)

    def __eq__(self, Signal other):
        """Compare for equality with another signal."""
        return sig_eq(self, other)

    def __ne__(self, Signal other):
        """Assert this box is not equal with another signal."""
        return sig_ne(self, other)

    def __gt__(self, Signal other):
        """Is this box greater than another signal."""
        return sig_gt(self, other)

    def __ge__(self, Signal other):
        """Is this box greater than or equal from another signal."""
        return sig_ge(self, other)

    def __lt__(self, Signal other):
        """Is this box lesser than another signal."""
        return sig_lt(self, other)

    def __le__(self, Signal other):
        """Is this box lesser than or equal from another signal."""
        return sig_le(self, other)

    def __and__(self, Signal other):
        """logical and with another signal."""
        return sig_and(self, other)

    def __or__(self, Signal other):
        """logical or with another signal."""
        return sig_or(self, other)

    def __xor__(self, Signal other):
        """logical xor with another signal."""
        return sig_xor(self, other)

    # TODO: check sigRem = modulo if this is correct
    def __mod__(self, Signal other):
        """modulo of other Signal"""
        return sig_rem(self, other)

    def __lshift__(self, Signal other):
        """bitwise left-shift"""
        return sig_leftshift(self, other)

    def __rshift__(self, Signal other):
        """bitwise right-shift"""
        return sig_lrightshift(self, other)

    # nullary funcs

    def abs(self) -> Signal:
        return sig_abs(self)

    def acos(self) -> Signal:
        return sig_acos(self)

    def tan(self) -> Signal:
        return sig_tan(self)

    def sqrt(self) -> Signal:
        return sig_sqrt(self)

    def sin(self) -> Signal:
        return sig_sin(self)

    def rint(self) -> Signal:
        return sig_rint(self)

    def log(self) -> Signal:
        return sig_log(self)

    def log10(self) -> Signal:
        return sig_log10(self)

    def floor(self) -> Signal:
        return sig_floor(self)

    def exp(self) -> Signal:
        return sig_exp(self)

    def exp10(self) -> Signal:
        return sig_exp10(self)

    def cos(self) -> Signal:
        return sig_cos(self)

    def ceil(self) -> Signal:
        return sig_ceil(self)

    def atan(self) -> Signal:
        return sig_atan(self)

    def asin(self) -> Signal:
        return sig_asin(self)


    # binary funcs

    def delay(self, d: Signal | int) -> Signal:
        _d = sig_or_int(d)
        return sig_delay(self, _d)

    def remainder(self, Signal y) -> Signal:
        return sig_remainder(self, y)

    def pow(self, Signal y) -> Signal:
        return sig_pow(self, y)

    def min(self, Signal y) -> Signal:
        return sig_min(self, y)

    def max(self, Signal y) -> Signal:
        return sig_max(self, y)

    def fmod(self, Signal y) -> Signal:
        return sig_fmod(self, y)



    # boolean funcs ---------------------


    def is_int(self) -> bool:
        cdef int i
        return fs.isSigInt(self.ptr, &i)

    def is_float(self) -> bool:
        cdef double f
        return fs.isSigReal(self.ptr, &f)

    def is_input(self) -> bool:
        cdef int i
        return fs.isSigInput(self.ptr, &i)

    def is_output(self) -> bool:
        cdef int i
        cdef fs.Signal t0 = NULL
        return fs.isSigOutput(self.ptr, &i, t0)

    def is_delay1(self) -> bool:
        cdef fs.Signal t0 = NULL
        return fs.isSigDelay1(self.ptr, t0)

    def is_delay(self) -> bool:
        cdef fs.Signal t0 = NULL
        cdef fs.Signal t1 = NULL
        return fs.isSigDelay(self.ptr, t0, t1)

    def is_prefix(self) -> bool:
        cdef fs.Signal t0 = NULL
        cdef fs.Signal t1 = NULL
        return fs.isSigPrefix(self.ptr, t0, t1)

    def is_read_table(self) -> bool:
        cdef fs.Signal t = NULL
        cdef fs.Signal i = NULL
        return fs.isSigRDTbl(self.ptr, t, t)

    def is_write_table(self) -> bool:
        cdef fs.Signal id = NULL
        cdef fs.Signal t = NULL
        cdef fs.Signal i = NULL
        cdef fs.Signal s = NULL
        return fs.isSigWRTbl(self.ptr, id, t, i, s)

    def is_gen(self) -> bool:
        cdef fs.Signal x = NULL
        return fs.isSigGen(self.ptr, x)

    def is_doc_constant_tbl(self) -> bool:
        cdef fs.Signal n = NULL
        cdef fs.Signal sig = NULL
        return fs.isSigDocConstantTbl(self.ptr, n, sig)

    def is_doc_write_tbl(self) -> bool:
        cdef fs.Signal n = NULL
        cdef fs.Signal sig = NULL
        cdef fs.Signal widx = NULL
        cdef fs.Signal wsig = NULL
        return fs.isSigDocWriteTbl(self.ptr, n, sig, widx, wsig)

    def is_doc_access_tbl(self) -> bool:
        cdef fs.Signal tbl = NULL
        cdef fs.Signal ridx = NULL
        return fs.isSigDocAccessTbl(self.ptr, tbl, ridx)

    def is_select2(self) -> bool:
        cdef fs.Signal selector = NULL
        cdef fs.Signal s1 = NULL
        cdef fs.Signal s2 = NULL
        return fs.isSigSelect2(self.ptr, selector, s1, s2)

    def is_assert_bounds(self) -> bool:
        cdef fs.Signal s1 = NULL
        cdef fs.Signal s2 = NULL
        cdef fs.Signal s3 = NULL
        return fs.isSigAssertBounds(self.ptr, s1, s2, s3)

    def is_highest(self) -> bool:
        cdef fs.Signal s = NULL
        return fs.isSigHighest(self.ptr, s)

    def is_lowest(self) -> bool:
        cdef fs.Signal s = NULL
        return fs.isSigLowest(self.ptr, s)

    def is_bin_op(self) -> bool:
        cdef int op = 0
        cdef fs.Signal x = NULL
        cdef fs.Signal y = NULL
        return fs.isSigBinOp(self.ptr, &op, x, y)

    def is_ffun(self) -> bool:
        cdef fs.Signal ff = NULL
        cdef fs.Signal largs = NULL
        return fs.isSigFFun(self.ptr, ff, largs)

    def is_fconst(self) -> bool:
        cdef fs.Signal type = NULL
        cdef fs.Signal name = NULL
        cdef fs.Signal file = NULL
        return fs.isSigFConst(self.ptr, type, name, file)

    def is_fvar(self) -> bool:
        cdef fs.Signal type = NULL
        cdef fs.Signal name = NULL
        cdef fs.Signal file = NULL
        return fs.isSigFVar(self.ptr, type, name, file)

    def is_proj(self) -> bool:
        cdef int i = 0
        cdef fs.Signal rgroup = NULL
        return fs.isProj(self.ptr, &i, rgroup)

    def is_rec(self) -> bool:
        cdef fs.Signal var = NULL
        cdef fs.Signal body = NULL
        return fs.isRec(self.ptr, var, body)

    def is_int_cast(self) -> bool:
        cdef fs.Signal x = NULL
        return fs.isSigIntCast(self.ptr, x)

    def is_float_cast(self) -> bool:
        cdef fs.Signal x = NULL
        return fs.isSigFloatCast(self.ptr, x)

    def is_button(self) -> bool:
        cdef fs.Signal lbl = NULL
        return fs.isSigButton(self.ptr, lbl)

    def is_checkbox(self) -> bool:
        cdef fs.Signal lbl = NULL
        return fs.isSigCheckbox(self.ptr, lbl)

    def is_waveform(self) -> bool:
        return fs.isSigWaveform(self.ptr)

    def is_hslider(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal init = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal step = NULL
        return fs.isSigHSlider(self.ptr, lbl, init, min, max, step)

    def is_vslider(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal init = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal step = NULL
        return fs.isSigVSlider(self.ptr, lbl, init, min, max, step)

    def is_num_entry(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal init = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal step = NULL
        return fs.isSigNumEntry(self.ptr, lbl, init, min, max, step)

    def is_hbargraph(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal x = NULL
        return fs.isSigHBargraph(self.ptr, lbl, min, max, x)

    def is_vbargraph(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal x = NULL
        return fs.isSigVBargraph(self.ptr, lbl, min, max, x)

    def is_attach(self) -> bool:
        cdef fs.Signal s0 = NULL
        cdef fs.Signal s1 = NULL
        return fs.isSigAttach(self.ptr, s0, s1)

    def is_enable(self) -> bool:
        cdef fs.Signal s0 = NULL
        cdef fs.Signal s1 = NULL
        return fs.isSigEnable(self.ptr, s0, s1)

    def is_control(self) -> bool:
        cdef fs.Signal s0 = NULL
        cdef fs.Signal s1 = NULL
        return fs.isSigControl(self.ptr, s0, s1)

    def is_soundfile(self) -> bool:
        cdef fs.Signal label = NULL
        return fs.isSigSoundfile(self.ptr, label)

    def is_soundfile_length(self) -> bool:
        cdef fs.Signal sf = NULL
        cdef fs.Signal part = NULL
        return fs.isSigSoundfileLength(self.ptr, sf, part)

    def is_soundfile_rate(self) -> bool:
        cdef fs.Signal sf = NULL
        cdef fs.Signal part = NULL
        return fs.isSigSoundfileLength(self.ptr, sf, part)

    def is_soundfile_buffer(self) -> bool:
        cdef fs.Signal sf = NULL
        cdef fs.Signal chan = NULL
        cdef fs.Signal part = NULL
        cdef fs.Signal ridx = NULL
        return fs.isSigSoundfileBuffer(self.ptr, sf, chan, part, ridx)




def ffname(Signal s) -> str:
    """Return the name parameter of a foreign function.

    s - the signal
    returns the name
    """
    return fs.ffname(s.ptr).decode()


def ffarity(Signal s) -> int:
    """Return the arity of a foreign function.

    s - the signal
    returns the name
    """
    return fs.ffarity(s.ptr)


def print_signal(Signal sig, bint shared, int max_size) -> str:
    """Print the signal.

    sig - the signal to be printed
    shared - whether the identical sub signals are printed as identifiers
    max_size - the maximum number of characters to be printed (possibly needed for big expressions in non shared mode)

    returns the printed signal as a string
    """
    return fs.printSignal(sig.ptr, shared, max_size).decode()

def create_lib_context():
    """Create global compilation context, has to be done first.
    """
    fs.createLibContext()

def destroy_lib_context():
    """Destroy global compilation context, has to be done last.
    """
    fs.destroyLibContext()

# def get_sig_interval(Signal s) -> Interval:
#     """Get the signal interval.

#     s - the signal

#     returns the signal interval
#     """
#     cdef fs.Interval ival = fs.getSigInterval(s.ptr)
#     return Interval.from_ptr(ival)

# def set_sig_interval(Signal s, Interval inter):
#     """Set the signal interval.

#     s - the signal

#     inter - the signal interval
#     """
#     fs.setSigInterval(s.ptr, inter.ptr)

def is_nil(Signal s) -> bool:
    """Check if a signal is nil.

    s - the signal

    returns true if the signal is nil, otherwise false.
    """
    return fs.isNil(s.ptr)


def tree2str(Signal s):
    """Convert a signal (such as the label of a UI) to a string.

    s - the signal to convert

    returns a string representation of a signal.
    """
    return fs.tree2str(s.ptr).decode()


# cdef void* getUserData(fs.Signal s):
#     """Return the xtended type of a signal.

#     s - the signal whose xtended type to return

#     returns a pointer to xtended type if it exists, otherwise nullptr.
#     """
#     return <void*>fs.getUserData(s)


def xtended_arity(Signal s) -> int:
    """Return the arity of the xtended signal.

    s - the xtended signal

    returns the arity of the xtended signal.
    """
    return fs.xtendedArity(s.ptr)


def xtended_name(Signal s):
    """Return the name of the xtended signal.

    s - the xtended signal

    returns the name of the xtended signal.
    """
    return fs.xtendedName(s.ptr).decode()


def sig_int(int n) -> Signal:
    """Constant integer : for all t, x(t) = n.

    n - the integer

    returns the integer signal.
    """
    cdef fs.Signal s = fs.sigInt(n)
    return Signal.from_ptr(s)


def sig_real(float n) -> Signal:
    """Constant real : for all t, x(t) = n.

    n - the float/double value (depends of -single or -double compilation parameter)

    returns the float/double signal.
    """
    cdef fs.Signal s = fs.sigReal(n)
    return Signal.from_ptr(s)

sig_float = sig_real

def sig_input(int idx) -> Signal:
    """Create an input.

    idx - the input index

    returns the input signal.
    """
    cdef fs.Signal s = fs.sigInput(idx)
    return Signal.from_ptr(s)


def sig_delay(Signal s, Signal d) -> Signal:
    """Create a delayed signal.

    s - the signal to be delayed
    d - the delay signal that doesn't have to be fixed but must be bounded and cannot be negative

    returns the delayed signal.
    """
    cdef fs.Signal _s = fs.sigDelay(s.ptr, d.ptr)
    return Signal.from_ptr(_s)


def sig_delay1(Signal s) -> Signal:
    """Create a one sample delayed signal.

    s - the signal to be delayed

    returns the delayed signal.
    """
    cdef fs.Signal _s = fs.sigDelay1(s.ptr)
    return Signal.from_ptr(_s)


def sig_int_cast(Signal s) -> Signal:
    """Create a casted signal.

    s - the signal to be casted in integer

    returns the casted signal.
    """
    cdef fs.Signal _s = fs.sigIntCast(s.ptr)
    return Signal.from_ptr(_s)


def sig_float_cast(Signal s) -> Signal:
    """Create a casted signal.

    s - the signal to be casted as float/double value (depends of -single or -double compilation parameter)

    returns the casted signal.
    """
    cdef fs.Signal _s = fs.sigFloatCast(s.ptr)
    return Signal.from_ptr(_s)


def sig_readonly_table(Signal n, Signal init, Signal ridx) -> Signal:
    """Create a read only table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    ridx - the read index (an int between 0 and n-1)

    returns the table signal.
    """
    cdef fs.Signal s = fs.sigReadOnlyTable(n.ptr, init.ptr, ridx.ptr)
    return Signal.from_ptr(s)


def sig_write_read_table(Signal n, Signal init, Signal widx, Signal wsig, Signal ridx) -> Signal:
    """Create a read/write table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    widx - the write index (an integer between 0 and n-1)
    wsig - the input of the table
    ridx - the read index (an integer between 0 and n-1)

    returns the table signal.
    """
    cdef fs.Signal s = fs.sigWriteReadTable(
        n.ptr, init.ptr, widx.ptr, wsig.ptr, ridx.ptr)
    return Signal.from_ptr(s)


def sig_waveform_int(int[:] view not None) -> Signal:
    """Create a waveform from a memoryview of ints

    view - memorview of ints

    returns the waveform signal.
    """
    cdef size_t i, n
    cdef fs.tvec wfv
    n = view.shape[0]
    for i in range(n):
        wfv.push_back(fs.sigInt(view[i]))
    cdef fs.Signal wf = fs.sigWaveform(wfv)
    return Signal.from_ptr(wf)

def sig_waveform_float(float[:] view not None) -> Signal:
    """Create a waveform from a memoryview of floats

    view - memorview of floats

    returns the waveform signal.
    """
    cdef size_t i, n
    cdef fs.tvec wfv
    n = view.shape[0]
    for i in range(n):
        wfv.push_back(fs.sigReal(view[i]))
    cdef fs.Signal wf = fs.sigWaveform(wfv)
    return Signal.from_ptr(wf)


def sig_soundfile(*paths) -> Signal:
    """Create a soundfile block.

    label - of form "label[url:{'path1''path2''path3'}]" 
            to describe a list of soundfiles

    returns the soundfile block.
    """
    ps = "".join(repr(p) for p in paths)
    label = f"label[url:{ps}]"
    cdef fs.Signal s = fs.sigSoundfile(label.encode('utf8'))
    return Signal.from_ptr(s)

def sig_soundfile_length(Signal sf, Signal part) -> Signal:
    """Create the length signal of a given soundfile in frames.

    sf - the soundfile
    part - in the [0..255] range to select a given sound number, 
           a constant numerical expression (see [1])

    returns the soundfile length signal.
    """
    cdef fs.Signal s = fs.sigSoundfileLength(sf.ptr, part.ptr)
    return Signal.from_ptr(s)

def sig_soundfile_rate(Signal sf, Signal part) -> Signal:
    """Create the rate signal of a given soundfile in Hz.

    sf - the soundfile
    part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])

    returns the soundfile rate signal.
    """
    cdef fs.Signal s = fs.sigSoundfileRate(sf.ptr, part.ptr)
    return Signal.from_ptr(s)


def sig_soundfile_buffer(Signal sf, Signal chan, Signal part, Signal ridx) -> Signal:
    """Create the buffer signal of a given soundfile.

    sf - the soundfile
    chan - an integer to select a given channel, a constant numerical expression (see [1])
    part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])
    ridx - the read index (an integer between 0 and the selected sound length)

    returns the soundfile buffer signal.
    """
    cdef fs.Signal s = fs.sigSoundfileBuffer(sf.ptr, chan.ptr, part.ptr, ridx.ptr)
    return Signal.from_ptr(s)

def sig_select2(Signal selector, Signal s1, Signal s2) -> Signal:
    """Create a selector between two signals.

    selector - when 0 at time t returns s1[t], otherwise returns s2[t]
    (selector is automatically wrapped with sigIntCast)
    s1 - first signal to be selected
    s2 - second signal to be selected

    returns the selected signal depending of the selector value at each time t.
    """
    cdef fs.Signal s = fs.sigSelect2(selector.ptr, s1.ptr, s2.ptr)
    return Signal.from_ptr(s)


def sig_select3(Signal selector, Signal s1, Signal s2, Signal s3) -> Signal:
    """Create a selector between three signals.

    selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t], otherwise returns s3[t]
    (selector is automatically wrapped with sigIntCast)
    s1 - first signal to be selected
    s2 - second signal to be selected
    s3 - third signal to be selected

    returns the selected signal depending of the selector value at each time t.
    """
    cdef fs.Signal s = fs.sigSelect3(selector.ptr, s1.ptr, s2.ptr, s3.ptr)
    return Signal.from_ptr(s)


def sig_fconst(fs.SType type, str name, str file) -> Signal:
    """Create a foreign constant signal.

    type - the foreign constant type of SType
    name - the foreign constant name
    file - the include file where the foreign constant is defined

    returns the foreign constant signal.
    """
    cdef fs.Signal s = fs.sigFConst(
        type, 
        name.encode('utf8'), 
        file.encode('utf8'))
    return Signal.from_ptr(s)


def sig_fvar(fs.SType type, str name, str file) -> Signal:
    """Create a foreign variable signal.

    type - the foreign variable type of SType
    name - the foreign variable name
    file - the include file where the foreign variable is defined

    returns the foreign variable signal.
    """
    cdef fs.Signal s = fs.sigFVar(
        type, 
        name.encode('utf8'), 
        file.encode('utf8'))
    return Signal.from_ptr(s)


def sig_bin_op(fs.SOperator op, Signal x, Signal y) -> Signal:
    """Generic binary mathematical functions.

    op - the operator in SOperator set
    x - first signal
    y - second signal

    returns the result signal of op(x, y).
    """
    cdef fs.Signal s = fs.sigBinOp(op, x.ptr, y.ptr)
    return Signal.from_ptr(s)


# -----------------------------------------------
# Specific binary mathematical functions.
# x - first signal
# y - second signal
# returns the result signal of fun(x,y).

def sig_add(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigAdd(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_sub(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigSub(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_mul(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigMul(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_div(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigDiv(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_rem(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigRem(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_leftshift(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigLeftShift(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_lrightshift(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigLRightShift(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_arightshift(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigARightShift(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_gt(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigGT(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_lt(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigLT(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_ge(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigGE(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_le(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigLE(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_eq(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigEQ(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_ne(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigNE(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_and(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigAND(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_or(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigOR(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_xor(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigXOR(x.ptr, y.ptr)
    return Signal.from_ptr(s)


# -----------------------------------------------
# Extended unary mathematical functions

def sig_abs(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigAbs(x.ptr)
    return Signal.from_ptr(s)

def sig_acos(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigAcos(x.ptr)
    return Signal.from_ptr(s)

def sig_tan(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigTan(x.ptr)
    return Signal.from_ptr(s)

def sig_sqrt(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigSqrt(x.ptr)
    return Signal.from_ptr(s)

def sig_sin(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigSin(x.ptr)
    return Signal.from_ptr(s)

def sig_rint(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigRint(x.ptr)
    return Signal.from_ptr(s)

def sig_log(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigLog(x.ptr)
    return Signal.from_ptr(s)

def sig_log10(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigLog10(x.ptr)
    return Signal.from_ptr(s)

def sig_floor(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigFloor(x.ptr)
    return Signal.from_ptr(s)

def sig_exp(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigExp(x.ptr)
    return Signal.from_ptr(s)

def sig_exp10(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigExp10(x.ptr)
    return Signal.from_ptr(s)

def sig_cos(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigCos(x.ptr)
    return Signal.from_ptr(s)

def sig_ceil(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigCeil(x.ptr)
    return Signal.from_ptr(s)

def sig_atan(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigAtan(x.ptr)
    return Signal.from_ptr(s)

def sig_asin(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigAsin(x.ptr)
    return Signal.from_ptr(s)

# -----------------------------------------------
# Extended binary mathematical functions.

def sig_remainder(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigRemainder(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_pow(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigPow(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_min(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigMin(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_max(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigMax(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_fmod(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigFmod(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_atan2(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigAtan2(x.ptr, y.ptr)
    return Signal.from_ptr(s)


# -----------------------------------------------

def sig_self() -> Signal:
    """Create a recursive signal inside the sigRecursion expression.

    returns the recursive signal.
    """
    cdef fs.Signal s = fs.sigSelf()
    return Signal.from_ptr(s)

def sig_recursion(Signal s) -> Signal:
    """Create a recursive signal. Use sigSelf() to refer to the
    recursive signal inside the sigRecursion expression.

    s - the signal to recurse on.

    returns the signal with a recursion.
    """
    cdef fs.Signal _s = fs.sigRecursion(s.ptr)
    return Signal.from_ptr(_s)

def sig_self_n(int id) -> Signal:
    """Create a recursive signal inside the sigRecursionN expression.

    id - the recursive signal index (starting from 0, up to the number of outputs signals in the recursive block)

    returns the recursive signal.
    """
    cdef fs.Signal s = fs.sigSelfN(id)
    return Signal.from_ptr(s)

def sig_recursion_n(SignalVector rf) -> SignalVector:
    """Create a recursive block of signals. 

    Use sigSelfN() to refer to the recursive signal inside 
    the sigRecursionN expression.

    rf - the list of signals to recurse on.

    returns the list of signals with recursions.
    """
    cdef fs.tvec rv = fs.sigRecursionN(rf.ptr)
    return SignalVector.from_ptr(rv)


def sig_button(str label) -> Signal:
    """Create a button signal.

    label - the label definition (see [2])

    returns the button signal.
    """
    cdef fs.Signal s = fs.sigButton(label.encode('utf8'))
    return Signal.from_ptr(s)


def sig_checkbox(str label) -> Signal:
    """Create a checkbox signal.

    label - the label definition (see [2])

    returns the checkbox signal.
    """
    cdef fs.Signal s = fs.sigCheckbox(label.encode('utf8'))
    return Signal.from_ptr(s)


def sig_vslider(str label, Signal init, Signal min, Signal max, Signal step) -> Signal:
    """Create a vertical slider signal.

    label - the label definition (see [2])
    init - the init signal, a constant numerical expression (see [1])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    step - the step signal, a constant numerical expression (see [1])

    returns the vertical slider signal.
    """
    cdef fs.Signal s = fs.sigVSlider(
        label.encode('utf8'),
        init.ptr,
        min.ptr,
        max.ptr,
        step.ptr,
    )
    return Signal.from_ptr(s)


def sig_hslider(str label, Signal init, Signal min, Signal max, Signal step) -> Signal:
    """Create an horizontal slider signal.

    label - the label definition (see [2])
    init - the init signal, a constant numerical expression (see [1])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    step - the step signal, a constant numerical expression (see [1])

    returns the horizontal slider signal.
    """
    cdef fs.Signal s = fs.sigHSlider(
        label.encode('utf8'),
        init.ptr,
        min.ptr,
        max.ptr,
        step.ptr,
    )
    return Signal.from_ptr(s)


def sig_numentry(str label, Signal init, Signal min, Signal max, Signal step) -> Signal:
    """Create a num entry signal.

    label - the label definition (see [2])
    init - the init signal, a constant numerical expression (see [1])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    step - the step signal, a constant numerical expression (see [1])

    returns the num entry signal.
    """
    cdef fs.Signal s = fs.sigNumEntry(
        label.encode('utf8'),
        init.ptr,
        min.ptr,
        max.ptr,
        step.ptr,
    )
    return Signal.from_ptr(s)


def sig_vbargraph(str label, Signal min, Signal max, Signal s):
    """Create a vertical bargraph signal.

    label - the label definition (see [2])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    s - the input signal

    returns the vertical bargraph signal.
    """
    cdef fs.Signal _s = fs.sigVBargraph(
        label.encode('utf8'),
        min.ptr,
        max.ptr,
        s.ptr,
    )
    return Signal.from_ptr(_s)


def sig_hbargraph(str label, Signal min, Signal max, Signal s):
    """Create an horizontal bargraph signal.

    label - the label definition (see [2])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    s - the input signal

    returns the horizontal bargraph signal.
    """
    cdef fs.Signal _s = fs.sigHBargraph(
        label.encode('utf8'),
        min.ptr,
        max.ptr,
        s.ptr,
    )
    return Signal.from_ptr(_s)



def sig_attach(Signal s1, Signal s2) -> Signal:
    """Create an attach signal.

    The attach primitive takes two input signals and produces one output signal
    which is a copy of the first input. The role of attach is to force
    its second input signal to be compiled with the first one.

    s1 - the first signal
    s2 - the second signal

    returns the attach signal.
    """
    cdef fs.Signal s = fs.sigAttach(s1.ptr, s2.ptr)
    return Signal.from_ptr(s)




# Test each signal and fill additional signal specific parameters.
# returns true and fill the specific parameters if the signal is of a given type, false otherwise

def is_sig_int(Signal t) -> dict:
    cdef int i = 0
    if fs.isSigInt(t.ptr, &i):
        return dict(i=i)
    else:
        return {}

def is_sig_float(Signal t) -> dict:
    cdef double r = 0.0
    if fs.isSigReal(t.ptr, &r):
        return dict(r=r)
    else:
        return {}

is_sig_real = is_sig_float

def is_sig_input(Signal t) -> dict:
    cdef int i = 0
    if fs.isSigInput(t.ptr, &i):
        return dict(i=i)
    else:
        return {}

def is_sig_output(Signal t) -> dict:
    cdef int i = 0
    cdef fs.Signal t0 = NULL
    if fs.isSigOutput(t.ptr, &i, t0):
        return dict(i=i, t0=Signal.from_ptr(t0))
    else:
        return {}

def is_sig_delay1(Signal t) -> dict:
    cdef fs.Signal t0 = NULL
    if fs.isSigDelay1(t.ptr, t0):
        return dict(t0=Signal.from_ptr(t0))
    else:
        return {}

def is_sig_delay(Signal t) -> dict:
    cdef fs.Signal t0 = NULL
    cdef fs.Signal t1 = NULL
    if fs.isSigDelay(t.ptr, t0, t1):
        return dict(
            t0=Signal.from_ptr(t0),
            t1=Signal.from_ptr(t1),
        )
    else:
        return {}


def is_sig_prefix(Signal t) -> dict:
    cdef fs.Signal t0 = NULL
    cdef fs.Signal t1 = NULL
    if fs.isSigPrefix(t.ptr, t0, t1):
        return dict(
            t0=Signal.from_ptr(t0),
            t1=Signal.from_ptr(t1),
        )
    else:
        return {}


def is_sig_readonly_table(Signal s) -> dict:
    cdef fs.Signal t = NULL
    cdef fs.Signal i = NULL
    if fs.isSigRDTbl(s.ptr, t, i):
        return dict(
            t=Signal.from_ptr(t),
            i=Signal.from_ptr(i),
        )
    else:
        return {}


def is_sig_read_write_table(Signal u) -> dict:
    cdef fs.Signal id = NULL
    cdef fs.Signal t = NULL
    cdef fs.Signal i = NULL
    cdef fs.Signal s = NULL
    if fs.isSigWRTbl(u.ptr, id, t, i, s):
        return dict(
            id=Signal.from_ptr(id),
            t=Signal.from_ptr(t),
            i=Signal.from_ptr(i),
            s=Signal.from_ptr(s),
        )
    else:
        return {}


def is_sig_gen(Signal t) -> dict:
    cdef fs.Signal x = NULL
    if fs.isSigGen(t.ptr, x):
        return dict(x=Signal.from_ptr(x))
    else:
        return {}


def is_sig_doc_constant_tbl(Signal t) -> dict:
    cdef fs.Signal n = NULL
    cdef fs.Signal sig = NULL
    if fs.isSigDocConstantTbl(t.ptr, n, sig):
        return dict(
            n=Signal.from_ptr(n),
            sig=Signal.from_ptr(sig),
        )
    else:
        return {}


def is_sig_doc_write_tbl(Signal t) -> dict:
    cdef fs.Signal n = NULL
    cdef fs.Signal sig = NULL
    cdef fs.Signal widx = NULL
    cdef fs.Signal wsig = NULL
    if fs.isSigDocWriteTbl(t.ptr, n, sig, widx, wsig):
        return dict(
            n=Signal.from_ptr(n),
            sig=Signal.from_ptr(sig),
            widx=Signal.from_ptr(widx),
            wsig=Signal.from_ptr(wsig),
        )
    else:
        return {}


def is_sig_doc_access_tbl(Signal t) -> dict:
    cdef fs.Signal tbl = NULL
    cdef fs.Signal ridx = NULL
    if fs.isSigDocAccessTbl(t.ptr, tbl, ridx):
        return dict(
            n=Signal.from_ptr(tbl),
            widx=Signal.from_ptr(ridx),
        )
    else:
        return {}


def is_sig_select2(Signal t) -> dict:
    cdef fs.Signal selector = NULL
    cdef fs.Signal s1 = NULL
    cdef fs.Signal s2 = NULL
    if fs.isSigSelect2(t.ptr, selector, s1, s2):
        return dict(
            selector=Signal.from_ptr(selector),
            s1=Signal.from_ptr(s1),
            s2=Signal.from_ptr(s2),
        )
    else:
        return {}


def is_sig_assert_bounds(Signal t) -> dict:
    cdef fs.Signal s1 = NULL
    cdef fs.Signal s2 = NULL
    cdef fs.Signal s3 = NULL
    if fs.isSigAssertBounds(t.ptr, s1, s2, s3):
        return dict(
            s1=Signal.from_ptr(s1),
            s2=Signal.from_ptr(s2),
            s3=Signal.from_ptr(s3),
        )
    else:
        return {}


def is_sig_highest(Signal t) -> dict:
    cdef fs.Signal s = NULL
    if fs.isSigHighest(t.ptr, s):
        return dict(s=Signal.from_ptr(s))
    else:
        return {}

def is_sig_lowest(Signal t) -> dict:
    cdef fs.Signal s = NULL
    if fs.isSigLowest(t.ptr, s):
        return dict(s=Signal.from_ptr(s))
    else:
        return {}


def is_sig_bin_op(Signal s) -> dict:
    cdef int op = 0
    cdef fs.Signal x = NULL
    cdef fs.Signal y = NULL
    if fs.isSigBinOp(s.ptr, &op, x, y):
        return dict(
            op=op,
            x=Signal.from_ptr(x),
            y=Signal.from_ptr(y),
        )
    else:
        return {}


def is_sig_ffun(Signal s) -> dict:
    cdef fs.Signal ff = NULL
    cdef fs.Signal largs = NULL
    if fs.isSigFFun(s.ptr, ff, largs):
        return dict(
            ff=Signal.from_ptr(ff),
            largs=Signal.from_ptr(largs),
        )
    else:
        return {}


def is_sig_fconst(Signal s) -> dict:
    cdef fs.Signal type = NULL
    cdef fs.Signal name = NULL
    cdef fs.Signal file = NULL
    if fs.isSigFConst(s.ptr, type, name, file):
        return dict(
            type=Signal.from_ptr(type),
            name=Signal.from_ptr(name),
            file=Signal.from_ptr(file),
        )
    else:
        return {}


def is_sig_fvar(Signal s) -> dict:
    cdef fs.Signal type = NULL
    cdef fs.Signal name = NULL
    cdef fs.Signal file = NULL
    if fs.isSigFVar(s.ptr, type, name, file):
        return dict(
            type=Signal.from_ptr(type),
            name=Signal.from_ptr(name),
            file=Signal.from_ptr(file),
        )
    else:
        return {}


def is_proj(Signal s) -> dict:
    cdef int i = 0
    cdef fs.Signal rgroup = NULL
    if fs.isProj(s.ptr, &i, rgroup):
        return dict(
            i=i,
            rgroup=Signal.from_ptr(rgroup),
        )
    else:
        return {}



def is_rec(Signal s) -> dict:
    cdef fs.Signal var = NULL
    cdef fs.Signal body = NULL
    if fs.isRec(s.ptr, var, body):
        return dict(
            var=Signal.from_ptr(var),
            body=Signal.from_ptr(body),
        )
    else:
        return {}


def is_sig_int_cast(Signal s) -> dict:
    cdef fs.Signal x = NULL
    if fs.isSigIntCast(s.ptr, x):
        return dict(
            x=Signal.from_ptr(x),
        )
    else:
        return {}


def is_sig_float_cast(Signal s) -> dict:
    cdef fs.Signal x = NULL
    if fs.isSigFloatCast(s.ptr, x):
        return dict(
            x=Signal.from_ptr(x),
        )
    else:
        return {}


def is_sig_button(Signal s) -> dict:
    cdef fs.Signal lbl = NULL
    if fs.isSigButton(s.ptr, lbl):
        return dict(
            lbl=Signal.from_ptr(lbl),
        )
    else:
        return {}

def is_sig_checkbox(Signal s) -> dict:
    cdef fs.Signal lbl = NULL
    if fs.isSigCheckbox(s.ptr, lbl):
        return dict(
            lbl=Signal.from_ptr(lbl),
        )
    else:
        return {}


def is_sig_waveform(Signal s) -> bool:
    return fs.isSigWaveform(s.ptr)


def is_sig_hslider(Signal u) -> dict:
    cdef fs.Signal lbl = NULL
    cdef fs.Signal init = NULL
    cdef fs.Signal min = NULL
    cdef fs.Signal max = NULL
    cdef fs.Signal step = NULL
    if fs.isSigHSlider(u.ptr, lbl, init, min, max, step):
        return dict(
            lbl=Signal.from_ptr(lbl),
            init=Signal.from_ptr(init),
            min=Signal.from_ptr(min),
            max=Signal.from_ptr(max),
            step=Signal.from_ptr(step),
        )
    else:
        return {}

def is_sig_vslider(Signal u) -> dict:
    cdef fs.Signal lbl = NULL
    cdef fs.Signal init = NULL
    cdef fs.Signal min = NULL
    cdef fs.Signal max = NULL
    cdef fs.Signal step = NULL
    if fs.isSigVSlider(u.ptr, lbl, init, min, max, step):
        return dict(
            lbl=Signal.from_ptr(lbl),
            init=Signal.from_ptr(init),
            min=Signal.from_ptr(min),
            max=Signal.from_ptr(max),
            step=Signal.from_ptr(step),
        )
    else:
        return {}

def is_sig_numentry(Signal u) -> dict:
    cdef fs.Signal lbl = NULL
    cdef fs.Signal init = NULL
    cdef fs.Signal min = NULL
    cdef fs.Signal max = NULL
    cdef fs.Signal step = NULL
    if fs.isSigNumEntry(u.ptr, lbl, init, min, max, step):
        return dict(
            lbl=Signal.from_ptr(lbl),
            init=Signal.from_ptr(init),
            min=Signal.from_ptr(min),
            max=Signal.from_ptr(max),
            step=Signal.from_ptr(step),
        )
    else:
        return {}


def is_sig_hbargraph(Signal s) -> dict:
    cdef fs.Signal lbl = NULL
    cdef fs.Signal min = NULL
    cdef fs.Signal max = NULL
    cdef fs.Signal x = NULL
    if fs.isSigHBargraph(s.ptr, lbl, min, max, x):
        return dict(
            lbl=Signal.from_ptr(lbl),
            min=Signal.from_ptr(min),
            max=Signal.from_ptr(max),
            x=Signal.from_ptr(x),
        )
    else:
        return {}

def is_sig_vbargraph(Signal s) -> dict:
    cdef fs.Signal lbl = NULL
    cdef fs.Signal min = NULL
    cdef fs.Signal max = NULL
    cdef fs.Signal x = NULL
    if fs.isSigVBargraph(s.ptr, lbl, min, max, x):
        return dict(
            lbl=Signal.from_ptr(lbl),
            min=Signal.from_ptr(min),
            max=Signal.from_ptr(max),
            x=Signal.from_ptr(x),
        )
    else:
        return {}


def is_sig_attach(Signal s) -> dict:
    cdef fs.Signal s0 = NULL
    cdef fs.Signal s1 = NULL
    if fs.isSigAttach(s.ptr, s0, s1):
        return dict(
            s0=Signal.from_ptr(s0),
            s1=Signal.from_ptr(s1),
        )
    else:
        return {}

def is_sig_enable(Signal s) -> dict:
    cdef fs.Signal s0 = NULL
    cdef fs.Signal s1 = NULL
    if fs.isSigEnable(s.ptr, s0, s1):
        return dict(
            s0=Signal.from_ptr(s0),
            s1=Signal.from_ptr(s1),
        )
    else:
        return {}

def is_sig_control(Signal s) -> dict:
    cdef fs.Signal s0 = NULL
    cdef fs.Signal s1 = NULL
    if fs.isSigControl(s.ptr, s0, s1):
        return dict(
            s0=Signal.from_ptr(s0),
            s1=Signal.from_ptr(s1),
        )
    else:
        return {}


def is_sig_soundfile(Signal s) -> dict:
    cdef fs.Signal label = NULL
    if fs.isSigSoundfile(s.ptr, label):
        return dict(
            label=Signal.from_ptr(label),
        )
    else:
        return {}


def is_sig_soundfile_length(Signal s) -> dict:
    cdef fs.Signal sf = NULL
    cdef fs.Signal part = NULL
    if fs.isSigSoundfileLength(s.ptr, sf, part):
        return dict(
            sf=Signal.from_ptr(sf),
            part=Signal.from_ptr(part),
        )
    else:
        return {}

def is_sig_soundfile_rate(Signal s) -> dict:
    cdef fs.Signal sf = NULL
    cdef fs.Signal part = NULL
    if fs.isSigSoundfileRate(s.ptr, sf, part):
        return dict(
            sf=Signal.from_ptr(sf),
            part=Signal.from_ptr(part),
        )
    else:
        return {}


def is_sig_soundfile_buffer(Signal s) -> dict:
    cdef fs.Signal sf = NULL
    cdef fs.Signal chan = NULL
    cdef fs.Signal part = NULL
    cdef fs.Signal ridx = NULL
    if fs.isSigSoundfileBuffer(s.ptr, sf, chan, part, ridx):
        return dict(
            sf=Signal.from_ptr(sf),
            chan=Signal.from_ptr(chan),
            part=Signal.from_ptr(part),
            ridx=Signal.from_ptr(ridx),
        )
    else:
        return {}


def simplify_to_normal_form(Signal s) -> Signal:
    """Simplify a signal to its normal form, where:
     
     - all possible optimisations, simplications, and compile time computations have been done
     - the mathematical functions (primitives and binary functions), delay, select2, soundfile primitive...
     are properly typed (arguments and result)
     - signal cast are properly done when needed

    sig - the signal to be processed

    returns the signal in normal form.
    """
    cdef fs.Signal _s = fs.simplifyToNormalForm(s.ptr)
    return Signal.from_ptr(_s)





def simplify_to_normal_form2(SignalVector vec) -> SignalVector:
    """Simplify a signal list to its normal form, where:
     
     - all possible optimisations, simplications, and compile time computations have been done
     - the mathematical functions (primitives and binary functions), delay, select2, soundfile primitive...
     are properly typed (arguments and result)
     - signal cast are properly done when needed

    siglist - the signal list to be processed

    returns the signal vector in normal form.
    """
    cdef fs.tvec sv = fs.simplifyToNormalForm2(vec.ptr)
    return SignalVector.from_ptr(sv)



def create_source_from_signals(str name_app, SignalVector osigs, str lang, *args) -> str:
    """Create source code in a target language from a vector of output signals.

    name_app - the name of the Faust program
    osigs - the vector of output signals (that will internally be converted 
            in normal form (see simplifyToNormalForm)
    lang -  the target source code's language which can be one of 'c',
            'cpp', 'cmajor', 'codebox', 'csharp', 'dlang', 'fir', 'interp', 'java', 'jax',
            'jsfx', 'julia', 'ocpp', 'rust' or 'wast'
    (depending of which of the corresponding backends are compiled in libfaust)
    argc - the number of parameters in argv array
    argv - the array of parameters
    error_msg - the error string to be filled

    returns a string of source code on success, setting error_msg on error.
    """
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    cdef string code = fs.createSourceFromSignals(
        name_app.encode('utf8'),
        osigs.ptr,
        lang.encode('utf8'),
        params.argc,
        params.argv,
        error_msg,
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return code.decode()


