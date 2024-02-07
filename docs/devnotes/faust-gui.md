#  Faust GUI API


## faust/gui/CGlue.h

```cython
cdef extern from "faust/gui/CGlue.h":
    cdef cppclass UIFloat:
        UIFloat() except +
        void openTabBox(const char* label)
        void openHorizontalBox(const char* label)
        void openVerticalBox(const char* label)
        void closeBox()
        # -- active widgets
        void addButton(const char* label, float* zone)
        void addCheckButton(const char* label, float* zone)
        void addVerticalSlider(const char* label, float* zone, float init, float min, float max, float step)
        void addHorizontalSlider(const char* label, float* zone, float init, float min, float max, float step)
        void addNumEntry(const char* label, float* zone, float init, float min, float max, float step)
        # -- passive widgets
        void addHorizontalBargraph(const char* label, float* zone, float min, float max)
        void addVerticalBargraph(const char* label, float* zone, float min, float max)
        # -- soundfiles
        # void addSoundfile(const char* label, const char* filename, Soundfile** sf_zone)
        # -- metadata declarations
        void declare(float* zone, const char* key, const char* val)

        @staticmethod
        void openTabBoxGlueFloat(void* cpp_interface, const char* label)

        @staticmethod
        void openHorizontalBoxGlueFloat(void* cpp_interface, const char* label)

        @staticmethod
        void openVerticalBoxGlueFloat(void* cpp_interface, const char* label)

        @staticmethod
        void closeBoxGlueFloat(void* cpp_interface)

        @staticmethod
        void addButtonGlueFloat(void* cpp_interface, const char* label, float* zone)

        @staticmethod
        void addCheckButtonGlueFloat(void* cpp_interface, const char* label, float* zone)

        @staticmethod
        void addVerticalSliderGlueFloat(void* cpp_interface, const char* label, float* zone, float init, float min, float max, float step)

        @staticmethod
        void addHorizontalSliderGlueFloat(void* cpp_interface, const char* label, float* zone, float init, float min, float max, float step)

        @staticmethod
        void addNumEntryGlueFloat(void* cpp_interface, const char* label, float* zone, float init, float min, float max, float step)

        @staticmethod
        void addHorizontalBargraphGlueFloat(void* cpp_interface, const char* label, float* zone, float min, float max)

        @staticmethod
        void addVerticalBargraphGlueFloat(void* cpp_interface, const char* label, float* zone, float min, float max)

        # @staticmethod
        # void addSoundfileGlueFloat(void* cpp_interface, const char* label, const char* url, Soundfile** sf_zone)

        @staticmethod
        void declareGlueFloat(void* cpp_interface, float* zone, const char* key, const char* value)
 ```

