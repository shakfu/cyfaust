# distutils: language = c++

import os

from libc.stdlib cimport malloc, free

from . cimport faust_gui as fg



cdef class UIReal:
    
    # cdef fg.UIReal[fg.FAUSTFLOAT] *uireal_ptr

    def __cinit__(self):
        pass

    def openTabBox(self, str label):
        """documentation here"""
        raise NotImplementedError

    # def openHorizontalBox(self, str label):
    #     raise NotImplementedError

    # def openVerticalBox(self, str label):
    #     raise NotImplementedError

    # def closeBox(self):
    #     raise NotImplementedError
    
    # # -- active widgets
    
    # def addButton(self, str label, fg.FAUSTFLOAT[:] zone):
    #     raise NotImplementedError

    # def addCheckButton(self, str label, fg.FAUSTFLOAT[:] zone):
    #     raise NotImplementedError

    # def addVerticalSlider(self, str label, fg.FAUSTFLOAT[:] zone, fg.FAUSTFLOAT init, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max, fg.FAUSTFLOAT step):
    #     raise NotImplementedError

    # def addHorizontalSlider(self, str label, fg.FAUSTFLOAT[:] zone, fg.FAUSTFLOAT init, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max, fg.FAUSTFLOAT step):
    #     raise NotImplementedError

    # def addNumEntry(self, str label, fg.FAUSTFLOAT[:] zone, fg.FAUSTFLOAT init, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max, fg.FAUSTFLOAT step):
    #     raise NotImplementedError

    
    # # -- passive widgets
    
    # def addHorizontalBargraph(self, str label, fg.FAUSTFLOAT[:] zone, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max):
    #     raise NotImplementedError

    # def addVerticalBargraph(self, str label, fg.FAUSTFLOAT[:] zone, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max):
    #     raise NotImplementedError

    
    # # -- soundfiles
    
    # # def addSoundfile(self, str label, str filename, fg.Soundfile** sf_zone):
    # #     raise NotImplementedError

    
    # # -- metadata declarations
    
    # def declare(self, fg.FAUSTFLOAT[:] zone, str key, str val):
    #     raise NotImplementedError

    # def sizeOfFAUSTFLOAT(self):
    #     raise NotImplementedError



cdef class UI(UIReal):
    # cdef fg.UI* ui_ptr

    def __cinit__(self):
        pass



## ---------------------------------------------------------------------------
## faust/gui/PrintUI.h

cdef class PrintUI(UI):
    """Faust Print UI."""

    # cdef fg.PrintUI* ptr
    # cdef bint ptr_owner


    def __cinit__(self):
        self.ptr = new fg.PrintUI()
        self.ui_ptr = self.ptr

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            del self.ptr
            self.ptr = NULL

    def openTabBox(self, str label):
        self.ptr.openTabBox(label.encode('utf8'))

    def openHorizontalBox(self, str label):
        self.ptr.openHorizontalBox(label.encode('utf8'))

    def openVerticalBox(self, str label):
        self.ptr.openVerticalBox(label.encode('utf8'))

    def closeBox(self):
        self.ptr.closeBox()

    def addButton(self, str label, float zone):
        self.ptr.addButton(label.encode('utf8'), &zone)

    def addCheckButton(self, str label, float zone):
        self.ptr.addCheckButton(label.encode('utf8'), &zone)

    def addVerticalSlider(self, str label, float zone, float init, float min, float max, float step):
        self.ptr.addVerticalSlider(label.encode('utf8'), &zone, init, min, max, step)

    def addHorizontalSlider(self, str label, float zone, float init, float min, float max, float step):
        self.ptr.addHorizontalSlider(label.encode('utf8'), &zone, init, min, max, step)

    def addNumEntry(self, str label, float zone, float init, float min, float max, float step):
        self.ptr.addNumEntry(label.encode('utf8'), &zone, init, min, max, step)

    def addHorizontalBargraph(self, str label, float zone, float min, float max):
        self.ptr.addHorizontalBargraph(label.encode('utf8'), &zone, min, max)

    def addVerticalBargraph(self, str label, float zone, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max):
        self.ptr.addVerticalBargraph(label.encode('utf8'), &zone, min, max)

    # def addSoundfile(self, str label, str filename,  fg.Soundfile** sf_zone):
    #     self.ptr.addSoundfile(label.encode('utf8'), filename.encode('utf8'), sf_zone)

    def declare(self, float zone,  str key,  str val):
        self.ptr.declare(&zone, key.encode('utf8'), val.encode('utf8'))

    def sizeOfFAUSTFLOAT(self) -> int:
        return self.ptr.sizeOfFAUSTFLOAT()
