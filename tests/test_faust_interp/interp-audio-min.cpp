#include <iostream>
#include <fstream>
#include <sstream>

#include <unistd.h>

#include "faust/dsp/interpreter-dsp.h"
#include "faust/dsp/libfaust.h"
#include "faust/audio/rtaudio-dsp.h"
#include "faust/gui/DecoratorUI.h"
#include "faust/gui/PrintUI.h"
#include "faust/misc.h"


#define SAMPLE_RATE 48000
#define BUFFER_SIZE 256

using namespace std;


static void printList(const vector<string>& list)
{
    for (int i = 0; i < list.size(); i++) {
        cout << "item: " << list[i] << "\n";
    }
}

int main(int argc, const char** argv)
{
    if (isopt((char**)argv, "-h") || isopt((char**)argv, "-help") || argc < 2) {
        cout << "interp-test foo.dsp" << endl;
        exit(EXIT_FAILURE);
    }
    
    string error_msg;
    cout << "Libfaust version : " << getCLibFaustVersion() << endl;
    string dspFile = argv[1];
   
    cout << "=============================\n";
    cout << "Test createInterpreterDSPFactoryFromFile\n";
    {
        interpreter_dsp_factory* factory = createInterpreterDSPFactoryFromFile(dspFile, 0, NULL, error_msg);
        
        if (!factory) {
            cerr << "Cannot create factory : " << error_msg;
            exit(EXIT_FAILURE);
        }
        
        cout << "getCompileOptions " << factory->getCompileOptions() << endl;
        printList(factory->getLibraryList());
        printList(factory->getIncludePathnames());    
        
        cout << "getName " << factory->getName() << endl;
        cout << "getSHAKey " << factory->getSHAKey() << endl;
        
        dsp* DSP = factory->createDSPInstance();
        if (!DSP) {
            cerr << "Cannot create instance " << endl;
            exit(EXIT_FAILURE);
        }
        
        cout << "Print UI parameters" << endl;
        PrintUI print_ui;
        DSP->buildUserInterface(&print_ui);
        
        rtaudio audio(SAMPLE_RATE, BUFFER_SIZE);
        if (!audio.init("FaustDSP", DSP)) {
            return 0;
        }
        
        audio.start();
        usleep(1000000);
        audio.stop();
    
        /*
        // Test generateAuxFilesFromFile
        string tempDir = "/private/var/tmp/";
        int argc2 = 0;
        const char* argv2[16];
        argv2[argc2++] = "-o";
        argv2[argc2++] = (dspFile+".cpp").c_str();
        argv2[argc2++] = "-O";
        argv2[argc2++] = tempDir.c_str();
        argv2[argc2] = nullptr;  // NULL terminated argv
        cout << "=============================\n";
        cout << "Test generateAuxFilesFromFile\n";
        if (!generateAuxFilesFromFile(dspFile, argc2, argv2, error_msg)) {
            cout << "ERROR in generateAuxFilesFromFile : " << error_msg;
        }
        */
        
        delete DSP;
        deleteInterpreterDSPFactory(factory);
    }

    return 0;
}

