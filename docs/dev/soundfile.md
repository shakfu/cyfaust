# Soundfile API Reference

Reference for Faust's soundfile loading system, relevant to implementing
soundfile support in cyfaust's Cython bindings.

## Links

- [Developing a new soundfile loader](https://faustdoc.grame.fr/manual/architectures/#developing-a-new-soundfile-loader)
- [Sound files support](https://faustdoc.grame.fr/manual/soundfiles/)
- [Soundfile primitive](https://faustdoc.grame.fr/manual/syntax/#soundfile-primitive)

## Soundfile (gui/Soundfile.h)

```python
class Soundfile:
    void* fBuffers   # double** or float** pointer chosen at runtime
    int* fLength     # length of each part (fLength[P] = length in frames of part P)
    int* fSR         # sample rate of each part (fSR[P] = SR of part P)
    int* fOffset     # offset of each part in global buffer (fOffset[P] = offset in frames)
    int fChannels    # max number of channels of all concatenated files
    int fParts       # total number of loaded parts
    bool fIsDouble   # sample format (float or double)

    def __init__(cur_chan: int, length: int, max_chan: int, total_parts: int, is_double: bool)

    def allocBufferReal[REAL](cur_chan: int, length: int, max_chan: int) -> REAL**
    def copyToOut(size: int, channels: int, max_channels: int, offset: int, buffer: void*)
    def shareBuffers(cur_chan: int, max_chan: int)
    def copyToOutReal[REAL](size: int, channels: int, max_channels: int, offset: int, buffer: void*)
    def getBuffersOffsetReal[REAL](buffers: void*, offset: int)
    def emptyFile(part: int, offset: int&)
```

## SoundfileReader (gui/Soundfile.h)

```python
class SoundfileReader:
    """The generic soundfile reader."""

    int fDriverSR

    def checkFile(sound_directories: list[str], file_name: str) -> str
        """Check if a soundfile exists and return its real path_name."""

    def isResampling(sample_rate: int) -> bool

    # To be implemented by subclasses:

    def checkFile(path_name: str) -> bool
        """Check the availability of a sound resource."""

    def checkFile(buffer: bytes, size: int) -> bool
        """Check the availability of a sound resource from a buffer."""

    def getParamsFile(path_name: str) -> tuple[int, int]
        """Get the channels and length values of the given sound resource."""

    def readFile(soundfile: Soundfile, path_name: str, part: int, offset: int&, max_chan: int)
        """Read one sound resource and fill the soundfile structure."""

    def setSampleRate(sample_rate: int)

    def createSoundfile(path_name_list: list[str], max_chan: int, is_double: bool) -> Soundfile

    def checkFiles(sound_directories: list[str], file_name_list: list[str]) -> list[str]
        """Check if all soundfiles exist and return their real path names."""
```

## SoundUI (gui/SoundUI.h)

```python
class SoundUI(SoundUIInterface):
    soundfile_dirs: list[str]
    soundfile_map: dict[str, Soundfile]
    soundfile_reader: SoundfileReader
    is_double: bool

    def __init__(sound_dir: str = "", sample_rate: int = -1,
                 reader: SoundfileReader = None, is_double: bool = False)
        """Create a soundfile loader.

        sound_dir    -- base directory for relative file paths
        sample_rate  -- audio driver SR (may differ from file SR, for resampling)
        reader       -- alternative soundfile reader (e.g. LibsndfileReader)
        is_double    -- whether Faust code was compiled in -double mode
        """

    def addSoundfile(label: str, url: str, sf_zone: Soundfile**)

    @staticmethod
    def getBinaryPath() -> str
        """Get the path of the running executable or plugin."""

    @staticmethod
    def getBinaryPathFrom(path: str) -> str
        """Get the path of the running executable or plugin from a given path."""
```

## MemoryReader (gui/MemoryReader.h)

```python
class MemoryReader(SoundfileReader):
    """Prepare sound resources in memory for use by SoundUI.addSoundfile.

    The Soundfile object's fLength, fOffset, fSampleRate and fBuffers fields
    must be filled with appropriate values.
    """

    def checkFile(path_name: str) -> bool
    def getParamsFile(path_name: str) -> tuple[int, int]
    def readFile(soundfile: Soundfile, path_name: str, part: int, offset: int&, max_chan: int)
```
