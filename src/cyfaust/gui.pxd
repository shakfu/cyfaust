
from . cimport faust_gui as fg

cdef class UIReal:
    cdef fg.UIReal[fg.FAUSTFLOAT] *uireal_ptr


cdef class UI(UIReal):
    cdef fg.UI* ui_ptr


cdef class PrintUI(UI):
    """Faust Print UI."""

    cdef fg.PrintUI* ptr
    cdef bint ptr_owner

