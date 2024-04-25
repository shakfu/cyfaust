# distutils: language = c++
# cython: language_level = 3


cdef extern from "demo.h":
    cdef cppclass Abstract[T]:
        Abstract() except +
        # void open(const char* label)
        # void inc(T num)
        # void add(T* zone, int size)
        # void close()

    cdef cppclass UI(Abstract[int]):
        UI() except +


    cdef cppclass Concrete(UI):
        Concrete() except +
        # void open(const char* label)
        # void inc(int num)
        # void add(int* zone, int size)
        # void close()

    void run(UI* instance)




cdef class PyAbstract:
    cdef Abstract[int] *abstract_ptr
    
    def __cinit__(self):
        pass

    # def open(self, str label):
    #     raise NotImplementedError

    # def inc(self, int num):
    #     raise NotImplementedError

    # def add(self, int[:] zone, int size):
    #     raise NotImplementedError

    # def close(self):
    #     raise NotImplementedError


cdef class PyUI(PyAbstract):
    cdef UI* ui_ptr

    def __cinit__(self):
        pass



cdef class PyConcrete(PyUI):
    cdef Concrete* ptr

    def __cinit__(self):
        self.ptr = new Concrete()
        self.ui_ptr = self.ptr

    def open(self, str label):
        print("open:", label)

    def inc(self, int num):
        print(num + 100)

    def add(self, int[:] zone, int size):
        print("add-start")
        for i in range(size):
            print(zone[i])
        print("add-end")

    def close(self):
        print("closed()")


def test_run(PyUI instance):
    run(instance.ui_ptr)


