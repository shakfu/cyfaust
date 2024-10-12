"""
Provides cython header interface to some faust/gui/*.h files

"""
from libcpp.string cimport string
from libcpp.vector cimport vector

from .faust_interp cimport dsp

DEF INCLUDE_SNDFILE = True



cdef extern from "faust/gui/CInterface.h":
    ctypedef float FAUSTFLOAT
    ctypedef struct UIGlue
    ctypedef struct MetaGlue

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
        # soundfiles
        void addSoundfile(const char* label, const char* filename, Soundfile** sf_zone)
        # metadata declarations
        void declare(REAL* zone, const char* key, const char* value)

    cdef cppclass UI(UIReal[FAUSTFLOAT]):
        UI() except +
        # void declare(const char* key, const char* value)


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
        void addSoundfile(const char* label, const char* filename,  Soundfile** sf_zone)
        void declare(FAUSTFLOAT* zone, const char* key, const char* val)

IF INCLUDE_SNDFILE:

    cdef extern from "faust/gui/Soundfile.h":
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
        
    cdef extern from "faust/gui/SoundUI.h":
        cdef cppclass SoundUI:
            SoundUI(const string& sound_directory = "", int sample_rate = -1, SoundfileReader* reader = nullptr, bint is_double = false)
            void addSoundfile(const char* label, const char* url, Soundfile** sf_zone)
            @staticmethod
            string getBinaryPath()
            @staticmethod
            string getBinaryPathFrom(const string& path)
            @staticmethod
            vector[string] getSoundfilePaths(dsp* dsp)
