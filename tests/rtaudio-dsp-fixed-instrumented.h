/************************** BEGIN rtaudio-dsp.h *************************
 FAUST Architecture File
 Copyright (C) 2003-2022 GRAME, Centre National de Creation Musicale
 ---------------------------------------------------------------------
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation; either version 2.1 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 
 EXCEPTION : As a special exception, you may create a larger work
 that contains this FAUST architecture section and distribute
 that work under terms of your choice, so long as this FAUST
 architecture section is not modified.
 ************************************************************************/

#ifndef __rtaudio_dsp__
#define __rtaudio_dsp__

#include <stdio.h>
#include <assert.h>
#include <rtaudio/RtAudio.h>
#include <stdlib.h>

#include "faust/audio/audio.h"
#include "faust/dsp/dsp-adapter.h"

#define FORMAT RTAUDIO_FLOAT32


double streamTimePrintIncrement = 1.0; // seconds
double streamTimePrintTime = 1.0; // seconds


/******************************************************************************
 *******************************************************************************
 
 RTAUDIO INTERFACE
 
 *******************************************************************************
 *******************************************************************************/

class rtaudio : public audio {
    
    protected:
        
        dsp* fDsp;
        RtAudio fAudioDAC;
        unsigned int fSampleRate;
        unsigned int fBufferSize;
         
        //----------------------------------------------------------------------------
        // 	number of physical input and output channels of the PA device
        //----------------------------------------------------------------------------
        int	fDevNumInChans;
        int	fDevNumOutChans;
        
        virtual int processAudio(double streamTime, void* inbuf, void* outbuf, unsigned long frames) 
        {
            AVOIDDENORMALS;
            
            float* inputs[fDsp->getNumInputs()];
            float* outputs[fDsp->getNumOutputs()];
            
            for (int i = 0; i < fDsp->getNumInputs(); i++) {
                inputs[i] = &(static_cast<float*>(inbuf))[i * frames];
            }
            for (int i = 0; i < fDsp->getNumOutputs(); i++) {
                std::cout << &(static_cast<float*>(outbuf))[i * frames] << std::endl;
                outputs[i] = &(static_cast<float*>(outbuf))[i * frames];
            }

            // process samples
            fDsp->compute(streamTime * 1000000., frames, inputs, outputs);
            return 0;
        }

        static int audioCallback(void* outputBuffer, void* inputBuffer, 
                                unsigned int nBufferFrames,
                                double streamTime, RtAudioStreamStatus status, 
                                void* drv)
        {
            if ( status )
                std::cout << "Stream underflow detected!" << std::endl;
        
            if ( streamTime >= streamTimePrintTime ) {
                std::cout << "streamTime = " << streamTime << std::endl;
                streamTimePrintTime += streamTimePrintIncrement;
            }

            return static_cast<rtaudio*>(drv)->processAudio(streamTime, inputBuffer, outputBuffer, nBufferFrames);
        }

    public:
        
        rtaudio(int srate, int bsize) : fDsp(0),
                fSampleRate(srate), fBufferSize(bsize), 
                fDevNumInChans(0), fDevNumOutChans(0) {}

        virtual ~rtaudio() 
        {   

            RtAudioErrorType err;
            err = fAudioDAC.stopStream();
            if (err != RTAUDIO_NO_ERROR) {
                // std::cout << '\n' << "rtaudio: cannot stop stream" << '\n' << std::endl;
                std::cout << '\n' << fAudioDAC.getErrorText() << '\n' << std::endl;
            }
            fAudioDAC.closeStream();
        }
        
        virtual bool init(const char* name, dsp* DSP)
        {
            if (init(name, DSP->getNumInputs(), DSP->getNumOutputs())) {
                setDsp(DSP);
                return true;
            } else {
                return false;
            }
        }
        
        bool init(const char* /*name*/, int numInputs, int numOutputs)
        {

            fAudioDAC.showWarnings(true);

            std::vector<unsigned int> deviceIds = fAudioDAC.getDeviceIds();
            if ( deviceIds.size() < 1 ) {
                std::cout << "\nNo audio devices found!\n";
                return false;
            }
            std::cout << "\nn devices found: " << deviceIds.size() << std::endl;

            std::vector<std::string> deviceNames = fAudioDAC.getDeviceNames();
            for (std::vector<std::string>::iterator t=deviceNames.begin(); t!=deviceNames.end(); ++t) 
            {
                std::cout<< *t << std::endl;
            }

            std::vector<RtAudio::Api> apis;
            RtAudio::getCompiledApi(apis);

            // ensure the known APIs return valid names
            std::cout << "API names by identifier (C++):" << std::endl;
            for ( size_t i = 0; i < apis.size() ; ++i ) {
                const std::string name = RtAudio::getApiName(apis[i]);
                if (name.empty()) {
                    std::cout << "Invalid name for API " << (int)apis[i] << "\n";
                    exit(1);
                }
                const std::string displayName = RtAudio::getApiDisplayName(apis[i]);
                if (displayName.empty()) {
                    std::cout << "Invalid display name for API " << (int)apis[i] << "\n";
                    exit(1);
                }
                std::cout << "    # " << (int)apis[i] << " '" << name << "': '" << displayName << "'\n";
            }

            // RtAudio::Api api = fAudioDAC.getCurrentApi();

            // std::cout << "\nAPI: " << fAudioDAC::getApiDisplayName(fAudioDAC.getCurrentApi()) << std::endl;

            // Get the list of device IDs
            std::vector< unsigned int > ids = fAudioDAC.getDeviceIds();
            if ( ids.size() == 0 ) {
                std::cout << "No devices found." << std::endl;
                return 0;
            }

            // Scan through devices for various capabilities
            RtAudio::DeviceInfo info;
            for ( unsigned int i=0; i<ids.size(); i++ ) {

                info = fAudioDAC.getDeviceInfo(ids[i]);

                // Print, for example, the name and maximum number of output channels for each device
                std::cout << "device id = " << ids[i] << std::endl;
                std::cout << "device name = " << info.name << std::endl;
                std::cout << ": preferred samplerate = " << info.preferredSampleRate << std::endl;
                std::cout << ": maximum output channels = " << info.outputChannels << std::endl;
            }
            std::cout << std::endl;

            // ---------------------------


            if (fAudioDAC.getDeviceCount() < 1) {
                std::cout << "No audio devices found!\n";
                
            }
            
            unsigned int default_in_device = fAudioDAC.getDefaultInputDevice();
            unsigned int default_out_device = fAudioDAC.getDefaultOutputDevice();

            std::cout << "Default input device number is: " << default_in_device << std::endl;
            std::cout << "Default output device number is: " << default_out_device << std::endl;

            RtAudio::DeviceInfo info_in = fAudioDAC.getDeviceInfo(default_in_device);
            RtAudio::DeviceInfo info_out = fAudioDAC.getDeviceInfo(default_out_device);
            RtAudio::StreamParameters iParams, oParams;
            
            iParams.deviceId = default_in_device;
            fDevNumInChans = info_in.inputChannels;
            iParams.nChannels = fDevNumInChans;
            iParams.firstChannel = 0;
            
            oParams.deviceId = default_out_device;
            fDevNumOutChans = info_out.outputChannels;
            oParams.nChannels = fDevNumOutChans;
            oParams.firstChannel = 0;
            
            RtAudio::StreamOptions options;

            // options.flags = RTAUDIO_HOG_DEVICE;
            // options.flags |= RTAUDIO_SCHEDULE_REALTIME;
            
            options.flags |= RTAUDIO_NONINTERLEAVED;
         
            RtAudioErrorType err = fAudioDAC.openStream(((numOutputs > 0) ? &oParams : NULL), 
                    ((numInputs > 0) ? &iParams : NULL), FORMAT, 
                    fSampleRate, &fBufferSize, audioCallback, this, &options);
            if (err != RTAUDIO_NO_ERROR) {
                std::cout << '\n' << fAudioDAC.getErrorText() << '\n' << std::endl;
                return false;
            }
            
            std::cout << "rtaudio::init OK" << std::endl;

            return true;
        }
        
        void setDsp(dsp* DSP)
        {
            fDsp = DSP;
            
            if (fDsp->getNumInputs() > fDevNumInChans || fDsp->getNumOutputs() > fDevNumOutChans) {
                printf("DSP has %d inputs and %d outputs, physical inputs = %d physical outputs = %d \n", 
                       fDsp->getNumInputs(), fDsp->getNumOutputs(), 
                       fDevNumInChans, fDevNumOutChans);
                fDsp = new dsp_adapter(fDsp, fDevNumInChans, fDevNumOutChans, fBufferSize);
            }
            
            fDsp->init(fSampleRate);

            std::cout << "rtaudio::setDsp OK" << std::endl;
        }
        
        virtual bool start() 
        {
            RtAudioErrorType err = fAudioDAC.startStream();
            if (err != RTAUDIO_NO_ERROR) {
                std::cout << '\n' << fAudioDAC.getErrorText() << '\n' << std::endl;
                // std::cout << '\n' << "rtaudio: cannot start stream" << '\n' << std::endl;
                return false;                
            }
            std::cout << "rtaudio::start OK" << std::endl;
            return true;
        }
        
        virtual void stop() 
        {
            RtAudioErrorType err = fAudioDAC.stopStream();
            if (err != RTAUDIO_NO_ERROR) {
                std::cout << '\n' << fAudioDAC.getErrorText() << '\n' << std::endl;
                return;
            }
            std::cout << "rtaudio::stop OK" << std::endl;
        }
        
        virtual int getBufferSize() 
        { 
            return fBufferSize; 
        }
        
        virtual int getSampleRate()
        { 
            return fSampleRate; 
        }
        
        virtual int getNumInputs()
        {
            return fDevNumInChans;
        }
        
        virtual int getNumOutputs()
        {
            return fDevNumOutChans;
        }
};

#endif
/**************************  END  rtaudio-dsp.h **************************/
