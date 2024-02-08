
from . cimport faust_gui as fg

# cdef class UIReal:
#     cdef fg.UIReal* uireal_ptr
#     cdef bint uireal_ptr_owner


# cdef class UI(UIReal):
# cdef class UI:
#     cdef fg.UI* ui_ptr
#     cdef bint ui_ptr_owner



# cdef class PrintUI(UI):
cdef class PrintUI:
    """Faust Print UI."""

    cdef fg.PrintUI* ptr
    cdef bint ptr_owner

    cdef void openTabBox(self, const char* label)
    cdef void openHorizontalBox(self, const char* label)
    cdef void openVerticalBox(self, const char* label)
    cdef void closeBox(self)
    cdef void addButton(self, const char* label, fg.FAUSTFLOAT* zone)
    cdef void addCheckButton(self, const char* label, fg.FAUSTFLOAT* zone)
    cdef void addVerticalSlider(self, const char* label, fg.FAUSTFLOAT* zone, fg.FAUSTFLOAT init, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max, fg.FAUSTFLOAT step)
    cdef void addHorizontalSlider(self, const char* label, fg.FAUSTFLOAT* zone, fg.FAUSTFLOAT init, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max, fg.FAUSTFLOAT step)
    cdef void addNumEntry(self, const char* label, fg.FAUSTFLOAT* zone, fg.FAUSTFLOAT init, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max, fg.FAUSTFLOAT step)
    cdef void addHorizontalBargraph(self, const char* label, fg.FAUSTFLOAT* zone, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max)
    cdef void addVerticalBargraph(self, const char* label, fg.FAUSTFLOAT* zone, fg.FAUSTFLOAT min, fg.FAUSTFLOAT max)
    # cdef void addSoundfile(self, const char* label, const char* filename,  fg.Soundfile** sf_zone)
    cdef void declare(self, fg.FAUSTFLOAT* zone,  const char* key,  const char* val)
