# faust_llvm.pxd - Cython declarations for Faust LLVM backend
#
# This file declares the C++ API for the Faust LLVM backend (llvm-dsp.h).
# The LLVM backend compiles Faust DSP code to native machine code via LLVM JIT,
# providing much faster execution than the interpreter backend.
#
# Key differences from interpreter backend:
#   - Factory creation functions have additional 'target' and 'opt_level' parameters
#   - Additional serialization formats: LLVM IR, machine code, object code
#   - getDSPMachineTarget() to query current machine's LLVM target triple
#   - registerForeignFunction() for custom C function integration

from libcpp.string cimport string
from libcpp.vector cimport vector

from .faust_box cimport Box, Signal, tvec
from .faust_gui cimport UI, Meta

# -----------------------------------------------------------------------------
# faust/dsp/dsp.h - Base DSP classes (shared with interpreter)
# -----------------------------------------------------------------------------

cdef extern from "faust/dsp/dsp.h":
    # Memory type enum for dsp_memory_manager
    cpdef enum MemType:
        kInt32
        kInt32_ptr
        kFloat
        kFloat_ptr
        kDouble
        kDouble_ptr
        kQuad
        kQuad_ptr
        kFixedPoint
        kFixedPoint_ptr
        kObj
        kObj_ptr
        kSound
        kSound_ptr

    cdef cppclass dsp_memory_manager:
        void begin(size_t count) except +
        void info(const char* name, MemType type, size_t size, size_t size_bytes, size_t reads, size_t writes) except +
        void end() except +
        void* allocate(size_t size) except +
        void destroy(void* ptr) except +

    # Base dsp class declaration
    cdef cppclass dsp:
        int getNumInputs()
        int getNumOutputs()
        void buildUserInterface(UI* ui_interface)
        int getSampleRate()
        void init(int sample_rate)
        void instanceInit(int sample_rate)
        void instanceConstants(int sample_rate)
        void instanceResetUserInterface()
        void instanceClear()
        dsp* clone()
        void metadata(Meta* m)
        void control()
        void frame(float* inputs, float* outputs)
        void compute(int count, float** inputs, float** outputs)
        void compute(double date_usec, int count, float** inputs, float** outputs)

    cdef cppclass decorator_dsp(dsp):
        decorator_dsp(dsp* dsp) except +
        int getNumInputs()
        int getNumOutputs()
        void buildUserInterface(UI* ui_interface)
        int getSampleRate()
        void init(int sample_rate)
        void instanceInit(int sample_rate)
        void instanceConstants(int sample_rate)
        void instanceResetUserInterface()
        void instanceClear()
        decorator_dsp* clone()
        void metadata(Meta* m)
        void control()
        void frame(float* inputs, float* outputs)
        void compute(int count, float** inputs, float** outputs)
        void compute(double date_usec, int count, float** inputs, float** outputs)

    cdef cppclass ScopedNoDenormals:
        ScopedNoDenormals() except +

    cdef cppclass dsp_factory:
        string getName()
        string getSHAKey()
        string getDSPCode()
        string getCompileOptions()
        vector[string] getLibraryList()
        vector[string] getIncludePathnames()
        vector[string] getWarningMessages()
        dsp* createDSPInstance()
        void classInit(int sample_rate)
        void setMemoryManager(dsp_memory_manager* manager)
        dsp_memory_manager* getMemoryManager()

# -----------------------------------------------------------------------------
# faust/dsp/libfaust.h - Common utility functions (shared with interpreter)
# -----------------------------------------------------------------------------

cdef extern from "faust/dsp/libfaust.h":
    string generateSHA1(const string& data)
    string expandDSPFromFile(const string& filename, int argc, const char* argv[], string& sha_key, string& error_msg)
    string expandDSPFromString(const string& name_app, const string& dsp_content, int argc, const char* argv[], string& sha_key, string& error_msg)
    bint generateAuxFilesFromFile(const string& filename, int argc, const char* argv[], string& error_msg)
    string generateAuxFilesFromFile2(const string& filename, int argc, const char* argv[], string& error_msg)
    bint generateAuxFilesFromString(const string& name_app, const string& dsp_content, int argc, const char* argv[], string& error_msg)
    string generateAuxFilesFromString2(const string& name_app, const string& dsp_content, int argc, const char* argv[], string& error_msg)

# -----------------------------------------------------------------------------
# faust/dsp/llvm-dsp.h - LLVM backend specific declarations
# -----------------------------------------------------------------------------

cdef extern from "faust/dsp/llvm-dsp.h":
    # Library version
    const char* getCLibFaustVersion()

    # Forward declarations
    cdef cppclass llvm_dsp_factory
    cdef cppclass llvm_dsp

    # -------------------------------------------------------------------------
    # llvm_dsp - DSP instance class
    # -------------------------------------------------------------------------
    cdef cppclass llvm_dsp:
        # Note: llvm_dsp objects are allocated via llvm_dsp_factory::createDSPInstance()
        int getNumInputs()
        int getNumOutputs()
        void buildUserInterface(UI* ui_interface)
        int getSampleRate()
        void init(int sample_rate)
        void instanceInit(int sample_rate)
        void instanceConstants(int sample_rate)
        void instanceResetUserInterface()
        void instanceClear()
        llvm_dsp* clone()
        void metadata(Meta* m)
        void compute(int count, float** inputs, float** outputs)

    # -------------------------------------------------------------------------
    # llvm_dsp_factory - DSP factory class
    # -------------------------------------------------------------------------
    cdef cppclass llvm_dsp_factory:
        string getName()
        # Note: getTarget() method exists in header but symbol not in static library
        # Use getDSPMachineTarget() free function instead for current machine target
        string getSHAKey()
        string getDSPCode()
        string getCompileOptions()
        vector[string] getLibraryList()
        vector[string] getIncludePathnames()
        vector[string] getWarningMessages()
        llvm_dsp* createDSPInstance()
        void classInit(int sample_rate)
        void setMemoryManager(dsp_memory_manager* manager)
        dsp_memory_manager* getMemoryManager()

    # -------------------------------------------------------------------------
    # Target query function
    # -------------------------------------------------------------------------

    # Get the target (triple + CPU) of the machine
    string getDSPMachineTarget()

    # -------------------------------------------------------------------------
    # Factory creation from DSP source
    # -------------------------------------------------------------------------

    # Get factory from SHA key (if in cache)
    llvm_dsp_factory* getDSPFactoryFromSHAKey(const string& sha_key)

    # Create factory from DSP file
    # target: LLVM machine target (empty string = current machine)
    # opt_level: LLVM IR optimization level (-1 to 4, -1 = max)
    llvm_dsp_factory* createDSPFactoryFromFile(
        const string& filename,
        int argc, const char* argv[],
        const string& target,
        string& error_msg,
        int opt_level)

    # Create factory from DSP string
    llvm_dsp_factory* createDSPFactoryFromString(
        const string& name_app,
        const string& dsp_content,
        int argc, const char* argv[],
        const string& target,
        string& error_msg,
        int opt_level)

    # Create factory from signal vector
    llvm_dsp_factory* createDSPFactoryFromSignals(
        const string& name_app,
        tvec signals_vec,
        int argc, const char* argv[],
        const string& target,
        string& error_msg,
        int opt_level)

    # Create factory from box expression
    llvm_dsp_factory* createDSPFactoryFromBoxes(
        const string& name_app,
        Box box,
        int argc, const char* argv[],
        const string& target,
        string& error_msg,
        int opt_level)

    # -------------------------------------------------------------------------
    # Factory management
    # -------------------------------------------------------------------------

    # Delete a factory (decrements reference counter)
    bint deleteDSPFactory(llvm_dsp_factory* factory)

    # Delete all factories in cache
    void deleteAllDSPFactories()

    # Get all factory SHA keys
    vector[string] getAllDSPFactories()

    # Multi-thread access control
    bint startMTDSPFactories()
    void stopMTDSPFactories()

    # -------------------------------------------------------------------------
    # Bitcode serialization (base64 encoded LLVM bitcode)
    # -------------------------------------------------------------------------

    # Read factory from bitcode string
    llvm_dsp_factory* readDSPFactoryFromBitcode(
        const string& bit_code,
        const string& target,
        string& error_msg,
        int opt_level)

    # Write factory to bitcode string
    string writeDSPFactoryToBitcode(llvm_dsp_factory* factory)

    # Read factory from bitcode file
    llvm_dsp_factory* readDSPFactoryFromBitcodeFile(
        const string& bit_code_path,
        const string& target,
        string& error_msg,
        int opt_level)

    # Write factory to bitcode file
    bint writeDSPFactoryToBitcodeFile(llvm_dsp_factory* factory, const string& bit_code_path)

    # -------------------------------------------------------------------------
    # LLVM IR serialization (textual format)
    # -------------------------------------------------------------------------

    # Read factory from IR string
    llvm_dsp_factory* readDSPFactoryFromIR(
        const string& ir_code,
        const string& target,
        string& error_msg,
        int opt_level)

    # Write factory to IR string
    string writeDSPFactoryToIR(llvm_dsp_factory* factory)

    # Read factory from IR file
    llvm_dsp_factory* readDSPFactoryFromIRFile(
        const string& ir_code_path,
        const string& target,
        string& error_msg,
        int opt_level)

    # Write factory to IR file
    bint writeDSPFactoryToIRFile(llvm_dsp_factory* factory, const string& ir_code_path)

    # -------------------------------------------------------------------------
    # Machine code serialization (base64 encoded native code)
    # -------------------------------------------------------------------------

    # Read factory from machine code string
    llvm_dsp_factory* readDSPFactoryFromMachine(
        const string& machine_code,
        const string& target,
        string& error_msg)

    # Write factory to machine code string
    string writeDSPFactoryToMachine(llvm_dsp_factory* factory, const string& target)

    # Read factory from machine code file
    llvm_dsp_factory* readDSPFactoryFromMachineFile(
        const string& machine_code_path,
        const string& target,
        string& error_msg)

    # Write factory to machine code file
    bint writeDSPFactoryToMachineFile(
        llvm_dsp_factory* factory,
        const string& machine_code_path,
        const string& target)

    # -------------------------------------------------------------------------
    # Object code serialization
    # -------------------------------------------------------------------------

    # Write factory to object code file (.o)
    bint writeDSPFactoryToObjectcodeFile(
        llvm_dsp_factory* factory,
        const string& object_code_path,
        const string& target)

    # -------------------------------------------------------------------------
    # Foreign function registration
    # -------------------------------------------------------------------------

    # Register a custom foreign function for use in DSP code via 'ffunction'
    # Must be called before compiling DSP code that uses the function
    void registerForeignFunction(const string& function_name)

# -----------------------------------------------------------------------------
# faust/audio/rtaudio-dsp.h - RtAudio driver (shared with interpreter)
# -----------------------------------------------------------------------------

cdef extern from "faust/audio/rtaudio-dsp.h":
    cdef cppclass rtaudio:
        rtaudio(int srate, int bsize) except +
        bint init(const char* name, dsp* DSP)
        bint init(const char* name, int numInputs, int numOutputs)
        void setDsp(dsp* DSP)
        bint start()
        void stop()
        int getBufferSize()
        int getSampleRate()
        int getNumInputs()
        int getNumOutputs()
