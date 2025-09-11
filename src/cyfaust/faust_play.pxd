# distutils: language=c++

from libc.stdint cimport *
from libcpp.string cimport string
from libcpp.map cimport map
from libcpp.pair cimport pair

from .faust_interp cimport dsp, UI, Meta
from .faust_gui cimport FAUSTFLOAT

# Import GUI from faust_gui module which should have the complete definition
from .faust_gui cimport GUI

# Forward declarations for additional types we need
cdef extern from "faust/gui/GUI.h":
    cdef cppclass uiCallbackItem
    
cdef extern from "faust/gui/ring-buffer.h":
    cdef cppclass ringbuffer_t

cdef extern from "faust/dsp/sound-player.h":

    # Constants
    cdef int BUFFER_SIZE
    cdef int RING_BUFFER_SIZE
    cdef int HALF_RING_BUFFER_SIZE
    
    # Base sound player class
    cdef cppclass sound_base_player(dsp):
        sound_base_player(const string& filename) except +
        
        # DSP interface methods
        int getNumInputs()
        int getNumOutputs()
        void buildUserInterface(UI* ui_interface)
        int getSampleRate()
        void init(int sample_rate)
        void instanceInit(int sample_rate)
        void instanceConstants(int sample_rate)
        void instanceResetUserInterface()
        void instanceClear()
        sound_base_player* clone()
        void metadata(Meta* m)
        void compute(int count, FAUSTFLOAT** inputs, FAUSTFLOAT** outputs)
        
        # Static methods
        @staticmethod
        void classInit(int sample_rate)
        
        @staticmethod
        void setFrame(FAUSTFLOAT val, void* arg)

        # Zone access methods
        FAUSTFLOAT* getCurFramesZone()
        FAUSTFLOAT* getSetFramesZone()

    # Memory-based sound player
    cdef cppclass sound_memory_player(sound_base_player):
        sound_memory_player(const string& filename) except +
        sound_memory_player* clone()

    # Direct-to-disk sound player  
    cdef cppclass sound_dtd_player(sound_base_player):
        sound_dtd_player(const string& filename) except +
        sound_dtd_player* clone()

    # Position manager for GUI control
    cdef cppclass PositionManager(GUI):
        PositionManager()
        void addDSP(sound_base_player* dsp)
        void removeDSP(sound_base_player* dsp)
