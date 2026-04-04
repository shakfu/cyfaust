# Resource Cleanup of Factory-Created DSP Instances

## The Problem

`interpreter_dsp` objects are allocated via `interpreter_dsp_factory::createDSPInstance()`:

```c++
/* Create a new DSP instance, to be deleted with C++ 'delete' */
interpreter_dsp* interpreter_dsp_factory::createDSPInstance();
```

Factories are created using functions like `createInterpreterDSPFactoryFromString(..)`.
The library keeps an internal cache of all allocated factories so that the
compilation of the same DSP code (same source and same normalized compilation
options) returns the same reference-counted factory pointer. You must explicitly
call `deleteDSPFactory` to decrement the reference counter when the factory is no
longer needed.

An `interpreter_dsp` instance depends on the factory that created it. If the
factory is deleted (or garbage collected) before a DSP instance is deallocated,
the result is a segfault.

Note: `interpreter_dsp_factory` does track its `interpreter_dsp` pointers and
cleans them up when `deleteInterpreterDSPFactory` is called, but the solution
below provides explicit Cython-level lifecycle management as well.

## Solution

`InterpreterDspFactory` keeps track of created `InterpreterDsp` instances in a
set and ensures they are cleaned up before the factory is deallocated:

```python
cdef class InterpreterDspFactory:
    """Interpreter DSP factory class."""

    cdef fi.interpreter_dsp_factory* ptr
    cdef bint ptr_owner
    cdef set instances

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False
        self.instances = set()

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            instances = self.instances.copy()
            while instances:
                i = instances.pop()
                i.delete()
            fi.deleteInterpreterDSPFactory(self.ptr)
            self.ptr = NULL

    def create_dsp_instance(self) -> InterpreterDsp:
        """Create a new DSP instance, to be deleted with C++ 'delete'"""
        cdef fi.interpreter_dsp* dsp = self.ptr.createDSPInstance()
        instance = InterpreterDsp.from_ptr(dsp)
        self.instances.add(instance)
        return instance


cdef class InterpreterDsp:
    """DSP instance class with methods."""

    cdef fi.interpreter_dsp* ptr
    cdef bint ptr_owner

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            del self.ptr
            self.ptr = NULL

    def delete(self):
        del self.ptr

    @staticmethod
    cdef InterpreterDsp from_ptr(fi.interpreter_dsp* ptr, bint owner=False):
        """Wrap the dsp instance and manage its lifetime."""
        cdef InterpreterDsp dsp = InterpreterDsp.__new__(InterpreterDsp)
        dsp.ptr_owner = owner
        dsp.ptr = ptr
        return dsp
```
