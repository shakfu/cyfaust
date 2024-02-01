# Resource cleanup of factory created dsp instances

## The Problem

- `interpreter_dsp` objects are allocated using `interpreter_dsp_factory::createDSPInstance()`:

```c++
/* Create a new DSP instance, to be deleted with C++ 'delete' */
interpreter_dsp* interpreter_dsp_factory::createDSPInstance();
```

- To create an `interpreter_dsp_factory`, for example, using `createInterpreterDSPFactoryFromString(..)`

  Create a Faust DSP factory from a DSP source code as a string.

  Note that the library keeps an internal cache of all allocated factories so that the compilation of same DSP code (that is same source code and same set of 'normalized' compilations options) will return the same (reference counted) factory pointer.

  You will have to explicitly use `deleteDSPFactory` to properly decrement reference counter when the factory is no more needed.

- Therefore, a `interpreter_dsp` instance depends on the factory instance `interpreter_dsp_factory` which created it.

- If the factory is deleted (or garbage collected) before a dsp instance is deallocated, you have a segfault.

- It was not known at the time that the above was written that an `interpreter_dsp_factory` keeps track of `interpreter_dsp` pointers and cleans them up when `deleteInterpreterDSPFactory` is called (docs have been updated since to make this point clearer).

## Current Solution

The solution below makes an `InterpreterDspFactory` instance keep track of created `InterpreterDsp` instances and ensures that they are cleaned up before the factory instance is deallocated. This works well and resolves this issue.

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
    # ...

    def create_dsp_instance(self) -> InterpreterDsp:
        """Create a new DSP instance, to be deleted with C++ 'delete'"""
        cdef fi.interpreter_dsp* dsp = self.ptr.createDSPInstance()
        instance = InterpreterDsp.from_ptr(dsp)
        self.instances.add(instance)
        return instance

    # ...

cdef class InterpreterDsp:
    """DSP instance class with methods."""

    cdef fi.interpreter_dsp* ptr
    cdef bint ptr_owner

    def __dealloc__(self):
        if self.ptr and self.ptr_owner:
            del self.ptr
            self.ptr = NULL

    def __cinit__(self):
        self.ptr = NULL
        self.ptr_owner = False

    def delete(self):
        del self.ptr

    @staticmethod
    cdef InterpreterDsp from_ptr(fi.interpreter_dsp* ptr, bint owner=False):
        """Wrap the dsp instance and manage its lifetime."""
        cdef InterpreterDsp dsp = InterpreterDsp.__new__(InterpreterDsp)
        dsp.ptr_owner = owner
        dsp.ptr = ptr
        return dsp

    # ...
```
