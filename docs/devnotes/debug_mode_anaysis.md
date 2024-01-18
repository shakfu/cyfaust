# Debug Mode Analysis

Build a debug python python with folllowing configurations:

```python
CONFIG_OPTIONS = [
 "--enable-shared",
 "--disable-test-modules",
 "--without-static-libpython",

 "--with-pydebug",
 "--with-address-sanitizer",
 "--with-undefined-behavior-sanitizer",
]
````

## Undefine Bahavious

```bash
>> testing cyfaust.interp
-------------------------------------------------------------------------------
test_interp_create_dsp_factory_from_file1
faust version: 2.69.3
compile options: -lang interp -ct 1 -es 1 -mcd 16 -single -ftz 0
library list: []
sha key 3B1074C7CA6B6752C8D1BDE61E91D62FF666E51C
openVerticalBox label : [Noise]
declare key : [acc val : 0 0 -10 0 10]
declare key : [style val : knob]
addVerticalSlider label : [/Noise/Volume init : 0.5 min : 0 max : 1 step : 0.1]
closeBox
./cyfaust/include/faust/audio/rtaudio-dsp.h:65:27: runtime error: variable length array bound evaluates to non-positive value 0
SUMMARY: UndefinedBehaviorSanitizer: undefined-behavior ./cyfaust/include/faust/audio/rtaudio-dsp.h:65:27 in

RtApiCore::stopStream(): the stream is already stopped!


RtApiCore::stopStream(): the stream is already stopped!
```

In `include/faust/audio/rtaudio-dsp.h:65`:

```c++
class rtaudio : public audio {
    
    protected:
        
        dsp* fDsp;
        RtAudio fAudioDAC;
        unsigned int fSampleRate;
        unsigned int fBufferSize;
         
        //----------------------------------------------------------------------------
        //  number of physical input and output channels of the PA device
        //----------------------------------------------------------------------------
        int fDevNumInChans;
        int fDevNumOutChans;
        
        virtual int processAudio(double streamTime, void* inbuf, void* outbuf, unsigned long frames) 
        {
            AVOIDDENORMALS;
            
            float* inputs[fDsp->getNumInputs()];   // <----- ERROR is here 
            float* outputs[fDsp->getNumOutputs()];
            
            for (int i = 0; i < fDsp->getNumInputs(); i++) {
                inputs[i] = &(static_cast<float*>(inbuf))[i * frames];
            }
            for (int i = 0; i < fDsp->getNumOutputs(); i++) {
                outputs[i] = &(static_cast<float*>(outbuf))[i * frames];
            }

            // process samples
            fDsp->compute(streamTime * 1000000., frames, inputs, outputs);
            return 0;
        }
 ```

- Basically if the project has not inputs or is just output audio, `fDsp->getNumInputs()` will be 0 and hence rhe undefined behaivour.
