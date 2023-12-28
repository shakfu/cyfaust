# distutils: language = c++

from libc.stdlib cimport malloc, free

## ---------------------------------------------------------------------------
## python c-api functions
##

cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)

## ---------------------------------------------------------------------------
## common utility classes / functions
##

cdef class ParamArray:
    """wrapper classs around faust paramater array"""
    # cdef const char ** argv
    # cdef int argc

    def __cinit__(self, tuple ptuple):
        self.argc = len(ptuple)
        self.argv = <const char **>malloc(self.argc * sizeof(char *))
        for i in range(self.argc):
            self.argv[i] = PyUnicode_AsUTF8(ptuple[i])

    def __iter__(self):
        for i in range(self.argc):
            yield self.argv[i].decode()

    def dump(self):
        for i in self:
            print(i)

    def as_list(self):
        return list(self)

    def __dealloc__(self):
        if self.argv:
            free(self.argv)

