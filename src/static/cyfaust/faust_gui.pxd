"""
Provides cython header interface to some faust/gui/*.h files

"""
from libcpp.string cimport string
from libcpp.vector cimport vector

# DEF INCLUDE_SNDFILE = True

# Forward declaration - will be fully defined in faust_interp.pxd
cdef extern from "faust/dsp/dsp.h":
    cdef cppclass dsp

cdef extern from "faust/gui/CInterface.h":
    ctypedef float FAUSTFLOAT
    
    # Function pointer types for UI interface
    ctypedef void (*openTabBoxFun)(void* ui_interface, const char* label)
    ctypedef void (*openHorizontalBoxFun)(void* ui_interface, const char* label)
    ctypedef void (*openVerticalBoxFun)(void* ui_interface, const char* label)
    ctypedef void (*closeBoxFun)(void* ui_interface)
    ctypedef void (*addButtonFun)(void* ui_interface, const char* label, FAUSTFLOAT* zone)
    ctypedef void (*addCheckButtonFun)(void* ui_interface, const char* label, FAUSTFLOAT* zone)
    ctypedef void (*addVerticalSliderFun)(void* ui_interface, const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
    ctypedef void (*addHorizontalSliderFun)(void* ui_interface, const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
    ctypedef void (*addNumEntryFun)(void* ui_interface, const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
    ctypedef void (*addHorizontalBargraphFun)(void* ui_interface, const char* label, FAUSTFLOAT* zone, FAUSTFLOAT min, FAUSTFLOAT max)
    ctypedef void (*addVerticalBargraphFun)(void* ui_interface, const char* label, FAUSTFLOAT* zone, FAUSTFLOAT min, FAUSTFLOAT max)
    ctypedef void (*addSoundfileFun)(void* ui_interface, const char* label, const char* url, void** sf_zone)
    ctypedef void (*declareFun)(void* ui_interface, FAUSTFLOAT* zone, const char* key, const char* value)
    
    # UIGlue structure for C interface
    ctypedef struct UIGlue:
        void* uiInterface
        openTabBoxFun openTabBox
        openHorizontalBoxFun openHorizontalBox
        openVerticalBoxFun openVerticalBox
        closeBoxFun closeBox
        addButtonFun addButton
        addCheckButtonFun addCheckButton
        addVerticalSliderFun addVerticalSlider
        addHorizontalSliderFun addHorizontalSlider
        addNumEntryFun addNumEntry
        addHorizontalBargraphFun addHorizontalBargraph
        addVerticalBargraphFun addVerticalBargraph
        addSoundfileFun addSoundfile
        declareFun declare
    
    # Function pointer types for Meta interface
    ctypedef void (*metaDeclareFun)(void* ui_interface, const char* key, const char* value)
    
    # MetaGlue structure for C interface
    ctypedef struct MetaGlue:
        void* metaInterface
        metaDeclareFun declare
    
    # DSP interface function pointer types
    ctypedef char dsp_imp
    ctypedef dsp_imp* (*newDspFun)()
    ctypedef void (*destroyDspFun)(dsp_imp* dsp)
    ctypedef int (*getNumInputsFun)(dsp_imp* dsp)
    ctypedef int (*getNumOutputsFun)(dsp_imp* dsp)
    ctypedef void (*buildUserInterfaceFun)(dsp_imp* dsp, UIGlue* ui)
    ctypedef int (*getSampleRateFun)(dsp_imp* dsp)
    ctypedef void (*initFun)(dsp_imp* dsp, int sample_rate)
    ctypedef void (*classInitFun)(int sample_rate)
    ctypedef void (*staticInitFun)(dsp_imp* dsp, int sample_rate)
    ctypedef void (*instanceInitFun)(dsp_imp* dsp, int sample_rate)
    ctypedef void (*instanceConstantsFun)(dsp_imp* dsp, int sample_rate)
    ctypedef void (*instanceResetUserInterfaceFun)(dsp_imp* dsp)
    ctypedef void (*instanceClearFun)(dsp_imp* dsp)
    ctypedef void (*computeFun)(dsp_imp* dsp, int len, FAUSTFLOAT** inputs, FAUSTFLOAT** outputs)
    ctypedef void (*metadataFun)(MetaGlue* meta)
    
    # Memory manager function pointer types
    ctypedef void* (*allocateFun)(void* manager_interface, size_t size)
    ctypedef void (*destroyFun)(void* manager_interface, void* ptr)
    
    # MemoryManagerGlue structure for C interface
    ctypedef struct MemoryManagerGlue:
        void* managerInterface
        allocateFun allocate
        destroyFun destroy

cdef extern from "faust/gui/meta.h":
    cdef cppclass Meta:
        void declare(const char* key, const char* value)

cdef extern from "faust/gui/UI.h":
    cdef cppclass UIReal[REAL]:
        UIReal() except +
        # widget's layouts
        void openTabBox(const char* label)
        void openHorizontalBox(const char* label)
        void openVerticalBox(const char* label)
        void closeBox()
        # active widgets
        void addButton(const char* label, REAL* zone)
        void addCheckButton(const char* label, REAL* zone)
        void addVerticalSlider(const char* label, REAL* zone, REAL init, REAL min, REAL max, REAL step)
        void addHorizontalSlider(const char* label, REAL* zone, REAL init, REAL min, REAL max, REAL step)
        void addNumEntry(const char* label, REAL* zone, REAL init, REAL min, REAL max, REAL step)
        # passive widgets
        void addHorizontalBargraph(const char* label, REAL* zone, REAL min, REAL max)
        void addVerticalBargraph(const char* label, REAL* zone, REAL min, REAL max)
        # soundfiles - excluded because UIReal is a template base class not directly exposed
        # Use SoundUI class instead (see below) for soundfile functionality
        # void addSoundfile(const char* label, const char* filename, Soundfile** sf_zone)
        # metadata declarations
        void declare(REAL* zone, const char* key, const char* value)

    cdef cppclass UI(UIReal[FAUSTFLOAT]):
        UI() except +
        # void declare(const char* key, const char* value)

cdef extern from "faust/gui/GUI.h":
    cdef cppclass GUI:
        GUI()
        void addCallback(FAUSTFLOAT* zone, void* foo, void* data)
        void removeCallback(FAUSTFLOAT* zone)
        void updateAllGuis()
        void updateAllZones()
        void updateAll()
        bint isRunning()
        void run()
        void stop()
        void declare(FAUSTFLOAT* zone, const char* key, const char* val)

cdef extern from "faust/gui/PrintUI.h":
    cdef cppclass PrintUI:
        PrintUI() except +
        void openTabBox(const char* label)
        void openHorizontalBox(const char* label)
        void openVerticalBox(const char* label)
        void closeBox()
        void addButton(const char* label, FAUSTFLOAT* zone)
        void addCheckButton(const char* label, FAUSTFLOAT* zone)
        void addVerticalSlider(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
        void addHorizontalSlider(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
        void addNumEntry(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT init, FAUSTFLOAT min, FAUSTFLOAT max, FAUSTFLOAT step)
        void addHorizontalBargraph(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT min, FAUSTFLOAT max)
        void addVerticalBargraph(const char* label, FAUSTFLOAT* zone, FAUSTFLOAT min, FAUSTFLOAT max)
        # soundfiles - excluded because PrintUI is for debugging/inspection only
        # Use SoundUI class instead (see below) for actual soundfile functionality
        # void addSoundfile(const char* label, const char* filename,  Soundfile** sf_zone)
        void declare(FAUSTFLOAT* zone, const char* key, const char* val)

# Soundfile functionality - always included for full functionality
cdef extern from "faust/gui/Soundfile.h":
    # Constants from Soundfile.h
    int BUFFER_SIZE
    int SAMPLE_RATE  
    int MAX_CHAN
    int MAX_SOUNDFILE_PARTS
    
    cdef cppclass Soundfile:
        void* fBuffers # will correspond to a double** or float** pointer chosen at runtime
        int* fLength   # length of each part (so fLength[P] contains the length in frames of part P)
        int* fSR       # sample rate of each part (so fSR[P] contains the SR of part P)
        int* fOffset   # offset of each part in the global buffer (so fOffset[P] contains the offset in frames of part P)
        int fChannels  # max number of channels of all concatenated files
        int fParts     # the total number of loaded parts
        bint fIsDouble # keep the sample format (float or double)

        Soundfile(int cur_chan, int length, int max_chan, int total_parts, bint is_double)
        void* allocBufferReal[REAL](int cur_chan, int length, int max_chan)            
        void copyToOut(int size, int channels, int max_channels, int offset, void* buffer)
        void shareBuffers(int cur_chan, int max_chan)
        void copyToOutReal[REAL](int size, int channels, int max_channels, int offset, void* buffer)
        void getBuffersOffsetReal[REAL](void* buffers, int offset)
        void emptyFile(int part, int& offset)

    cdef cppclass SoundfileReader:
        SoundfileReader() except +
        void setSampleRate(int sample_rate)   
        Soundfile* createSoundfile(const vector[string]& path_name_list, int max_chan, bint is_double)
        vector[string] checkFiles(const vector[string]& sound_directories, const vector[string]& file_name_list)
        string checkFile(const vector[string]& sound_directories, const string& file_name)
        bint isResampling(int sample_rate)
        
    # Global soundfile support
    vector[string] gPathNameList
    Soundfile* defaultsound
        
cdef extern from "faust/gui/SoundUI.h":
    cdef cppclass SoundUI:
        SoundUI(const string& sound_directory, int sample_rate, SoundfileReader* reader, bint is_double) except +
        void addSoundfile(const char* label, const char* url, Soundfile** sf_zone)
        @staticmethod
        string getBinaryPath()
        @staticmethod
        string getBinaryPathFrom(const string& path)
        @staticmethod
        vector[string] getSoundfilePaths(dsp* dsp)
        
    # SoundUI interface for DSP classes
    cdef cppclass SoundUIInterface:
        void addSoundfile(const char* label, const char* filename, Soundfile** sf_zone)
