# distutils: language = c++

from libcpp.string cimport string
from libc.stdlib cimport malloc, free
from cython.operator cimport dereference as deref

from . cimport faust_interp as fi
from . cimport faust_gui as fg
from . cimport faust_player as fp

from .common cimport ParamArray
from .common import ParamArray

## ---------------------------------------------------------------------------
## Sound Player Classes

cdef class SoundBasePlayer:
    """Base class for Faust sound players."""

    cdef fp.sound_base_player* _player
    cdef object _filename

    def __cinit__(self, filename: str):
        self._filename = filename
        self._player = new fp.sound_base_player(filename.encode('utf-8'))
        if self._player == NULL:
            raise MemoryError("Failed to create sound_base_player")

    def __dealloc__(self):
        if self._player != NULL:
            del self._player

    def get_num_inputs(self) -> int:
        """Get number of input channels."""
        return self._player.getNumInputs()

    def get_num_outputs(self) -> int:
        """Get number of output channels."""
        return self._player.getNumOutputs()

    def get_sample_rate(self) -> int:
        """Get sample rate."""
        return self._player.getSampleRate()

    def init(self, sample_rate: int):
        """Initialize the player with given sample rate."""
        self._player.init(sample_rate)

    def instance_init(self, sample_rate: int):
        """Initialize the player instance with given sample rate."""
        self._player.instanceInit(sample_rate)

    def instance_constants(self, sample_rate: int):
        """Set instance constants for given sample rate."""
        self._player.instanceConstants(sample_rate)

    def instance_reset_user_interface(self):
        """Reset user interface to default values."""
        self._player.instanceResetUserInterface()

    def instance_clear(self):
        """Clear instance state."""
        self._player.instanceClear()

    @property
    def filename(self) -> str:
        """Get the filename of the sound file."""
        return self._filename

    def compute(self, count: int, inputs, outputs):
        """Compute audio output for given number of frames."""
        cdef int num_inputs = self._player.getNumInputs()
        cdef int num_outputs = self._player.getNumOutputs()

        # Allocate input and output arrays
        cdef fg.FAUSTFLOAT** c_inputs = NULL
        cdef fg.FAUSTFLOAT** c_outputs = NULL
        cdef fg.FAUSTFLOAT[:] output_view

        if num_inputs > 0:
            c_inputs = <fg.FAUSTFLOAT**>malloc(num_inputs * sizeof(fg.FAUSTFLOAT*))
            if c_inputs == NULL:
                raise MemoryError("Failed to allocate input arrays")

            # For sound players, inputs are typically not used (num_inputs = 0)
            for i in range(num_inputs):
                c_inputs[i] = NULL

        if num_outputs > 0:
            c_outputs = <fg.FAUSTFLOAT**>malloc(num_outputs * sizeof(fg.FAUSTFLOAT*))
            if c_outputs == NULL:
                if c_inputs != NULL:
                    free(c_inputs)
                raise MemoryError("Failed to allocate output arrays")
            
            # Map Python arrays to C arrays using memoryviews
            for i in range(num_outputs):
                if i < len(outputs):
                    output_view = outputs[i]
                    c_outputs[i] = &output_view[0]
                else:
                    c_outputs[i] = NULL
        
        try:
            self._player.compute(count, c_inputs, c_outputs)
        finally:
            if c_inputs != NULL:
                free(c_inputs)
            if c_outputs != NULL:
                free(c_outputs)


cdef class SoundMemoryPlayer(SoundBasePlayer):
    """Memory-based sound player that loads entire file into memory."""
    
    cdef fp.sound_memory_player* _memory_player
    
    def __cinit__(self, filename: str):
        # Parent __cinit__ already called
        del self._player  # Remove base player
        self._memory_player = new fp.sound_memory_player(filename.encode('utf-8'))
        if self._memory_player == NULL:
            raise MemoryError("Failed to create sound_memory_player")
        self._player = self._memory_player  # Set base pointer
    
    def __dealloc__(self):
        # Memory player cleanup handled by parent
        pass


cdef class SoundDtdPlayer(SoundBasePlayer):
    """Direct-to-disk sound player that streams from file."""
    
    cdef fp.sound_dtd_player* _dtd_player
    
    def __cinit__(self, filename: str):
        # Parent __cinit__ already called
        del self._player  # Remove base player
        self._dtd_player = new fp.sound_dtd_player(filename.encode('utf-8'))
        if self._dtd_player == NULL:
            raise MemoryError("Failed to create sound_dtd_player")
        self._player = self._dtd_player  # Set base pointer
    
    def __dealloc__(self):
        # DTD player cleanup handled by parent
        pass


cdef class SoundPositionManager:
    """Manager for sound player position control via GUI."""
    
    cdef fp.PositionManager* _manager
    
    def __cinit__(self):
        self._manager = new fp.PositionManager()
        if self._manager == NULL:
            raise MemoryError("Failed to create PositionManager")
    
    def __dealloc__(self):
        if self._manager != NULL:
            del self._manager
    
    def add_dsp(self, SoundBasePlayer player):
        """Add a sound player to be managed."""
        if player._player != NULL:
            self._manager.addDSP(player._player)
    
    def remove_dsp(self, SoundBasePlayer player):
        """Remove a sound player from management."""
        if player._player != NULL:
            self._manager.removeDSP(player._player)


## ---------------------------------------------------------------------------
## Convenience functions

def create_memory_player(filename: str) -> SoundMemoryPlayer:
    """Create a memory-based sound player."""
    return SoundMemoryPlayer(filename)

def create_dtd_player(filename: str) -> SoundDtdPlayer:
    """Create a direct-to-disk sound player."""
    return SoundDtdPlayer(filename)

def create_position_manager() -> SoundPositionManager:
    """Create a position manager for GUI control."""
    return SoundPositionManager()