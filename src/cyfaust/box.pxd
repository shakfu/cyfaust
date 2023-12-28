from . cimport faust_box as fb


cdef class Box:
    cdef fb.Box ptr
    cdef public int inputs
    cdef public int outputs

    @staticmethod
    cdef Box from_ptr(fb.Box ptr, bint ptr_owner=?)

