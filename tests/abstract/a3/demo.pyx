# distutils: language = c++
# cython: language_level = 3


cdef extern from "demo.h":
    cdef cppclass Abstract:
        Abstract() except +
        void inc(int num)

    cdef cppclass Concrete(Abstract):
        Concrete() except +
        # void inc(int num)

    void run(Abstract* instance)



cdef class PyAbstract:
    cdef Abstract *abstract_ptr
    
    def __cinit__(self):
        pass

    def inc(self, int num):
        raise NotImplementedError


cdef class PyConcrete(PyAbstract):
    cdef Concrete* ptr

    def __cinit__(self):
        self.ptr = new Concrete()
        self.abstract_ptr = self.ptr

    def inc(self, int num):
        self.ptr.inc(num)


def test_run(PyAbstract instance):
    run(instance.abstract_ptr)

