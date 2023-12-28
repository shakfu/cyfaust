from libcpp.string cimport string
from libcpp.vector cimport vector

from . cimport faust_signal as fs


cdef class SignalVector:
    cdef vector[fs.Signal] ptr
    cdef bint ptr_owner

    @staticmethod
    cdef SignalVector from_ptr(fs.tvec ptr)

    cdef add_ptr(self, fs.Signal sig)




cdef class Signal:
    cdef fs.Signal ptr

    @staticmethod
    cdef Signal from_ptr(fs.Signal ptr, bint ptr_owner=?)
