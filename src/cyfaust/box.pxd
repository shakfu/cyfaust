from . cimport faust_box as fb

cpdef enum SType:
    kSInt
    kSReal

cpdef enum SOperator:
    kAdd
    kSub
    kMul
    kDiv
    kRem
    kLsh
    kARsh
    kLRsh
    kGT
    kLT
    kGE
    kLE
    kEQ
    kNE
    kAND
    kOR
    kXOR

cdef class Box:
    cdef fb.Box ptr
    cdef public int inputs
    cdef public int outputs

    @staticmethod
    cdef Box from_ptr(fb.Box ptr, bint ptr_owner=?)

