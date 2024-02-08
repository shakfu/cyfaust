# distutils: language = c++

import os

from libc.stdlib cimport malloc, free

from . cimport faust_gui as fg


# cdef class UIReal:
    
#     # cdef fg.UIReal* uireal_ptr
#     # cdef bint uireal_ptr_owner

#     def __cinit__(self):
#         self.uireal_ptr = new fg.UIReal()
#         self.uireal_ptr_owner = False

#     def __dealloc__(self):
#         if self.uireal_ptr and self.uireal_ptr_owner:
#             del self.uireal_ptr


# cdef class UI:
    
#     # cdef fg.UI* ui_ptr
#     # cdef bint ui_ptr_owner

#     def __cinit__(self):
#         self.ui_ptr = new fg.UI()
#         self.ui_ptr_owner = False

#     def __dealloc__(self):
#         if self.ui_ptr and self.ui_ptr_owner:
#             del self.ui_ptr
#             # self.ui_ptr = NULL


## ---------------------------------------------------------------------------
## faust/gui/PrintUI.h


# cdef class PrintUI(UI):
cdef class PrintUI:
    """Faust Print UI."""

    # cdef fg.PrintUI* ptr
    # cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = new fg.PrintUI()
        self.ptr_owner = False

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            del self.ptr
            self.ptr = NULL

    cdef void openTabBox(self, const char* label):
        self.ptr.openTabBox(label)

    cdef void openHorizontalBox(self, const char* label):
        self.ptr.openHorizontalBox(label)

    cdef void openVerticalBox(self, const char* label):
        self.ptr.openVerticalBox(label)

    cdef void closeBox(self):
        self.ptr.closeBox()

    cdef void addButton(self, const char* label, fg.FAUSTFLOAT* zone):
        self.ptr.addButton(label, zone)

    cdef void addCheckButton(self, const char* label, fg.FAUSTFLOAT* zone):
        self.ptr.addCheckButton(label, zone)

    cdef void addVerticalSlider(self, const char* label, fg.FAUSTFLOAT* zone, fg.FAUSTFLOAT init, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max, fg.FAUSTFLOAT step):
        self.ptr.addVerticalSlider(label, zone, init, min, max, step)

    cdef void addHorizontalSlider(self, const char* label, fg.FAUSTFLOAT* zone, fg.FAUSTFLOAT init, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max, fg.FAUSTFLOAT step):
        self.ptr.addHorizontalSlider(label, zone, init, min, max, step)

    cdef void addNumEntry(self, const char* label, fg.FAUSTFLOAT* zone, fg.FAUSTFLOAT init, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max, fg.FAUSTFLOAT step):
        self.ptr.addNumEntry(label, zone, init, min, max, step)

    cdef void addHorizontalBargraph(self, const char* label, fg.FAUSTFLOAT* zone, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max):
        self.ptr.addHorizontalBargraph(label, zone, min, max)

    cdef void addVerticalBargraph(self, const char* label, fg.FAUSTFLOAT* zone, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max):
        self.ptr.addVerticalBargraph(label, zone, min, max)

    # cdef void addSoundfile(self, const char* label, const char* filename,  fg.Soundfile** sf_zone):
    #     self.ptr.addSoundfile(label, filename, sf_zone)

    cdef void declare(self, fg.FAUSTFLOAT* zone,  const char* key,  const char* val):
        self.ptr.declare(zone, key, val)


