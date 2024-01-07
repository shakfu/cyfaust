# distutils: language = c++

import os

from libc.stdlib cimport malloc, free

## ---------------------------------------------------------------------------
## python c-api functions
##

cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)

## ---------------------------------------------------------------------------
## common utility functions
##

def get_package_resources() -> tuple[str, str, str, str]:
    """provides the paths of package architecture and library files."""
    resources = os.path.join(os.path.dirname(__file__), "resources")
    archs = os.path.join(resources, "architecture")
    libs = os.path.join(resources, "libraries")
    return ("-A", archs, "-I", libs)

PACKAGE_RESOURCES = get_package_resources()

## ---------------------------------------------------------------------------
## common utility classes
##

cdef class ParamArray:
    """wrapper classs around a faust parameter array.
    
    Automatically adds `PACKAGE_RESOURCES` paths (faust stdlibs and architecture) 
    to the params.
    """
    # cdef const char ** argv
    # cdef int argc

    def __cinit__(self, tuple ptuple):
        ptuple = ptuple + PACKAGE_RESOURCES
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

