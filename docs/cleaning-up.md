# Cleanup

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


## Current Solution:

The solution below keeps has an `InterpreterDspFactory` instance track of created `InterpreterDsp` and cleans up them before a factory instance is deallocated. This seems to work, but further checks are ncessary using a python debug build.

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

## Solutution B: del dsp instances in factory's __deallocate__ (FAILED)

- tracks the dsp instances at InterpreterDspFactory and deallocate them in the factory's `__deallocate__` method

```cython
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
        dsp.ptr_owner = False
        dsp.ptr = ptr
        return dsp

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
            for i in instances:
                i.delete()
            fi.deleteInterpreterDSPFactory(self.ptr)
            self.ptr = NULL
```


## Another Possible Solution

- from [this post](https://groups.google.com/g/cython-users/c/FU_RyQrFaow/m/Kn2XJkOAk00J)

- The problam was defined in the below code:

```cython
cdef class B:
    cdef cppB *ptr

    def __init__(self):
        self.ptr = new cppB()

    def __dealloc__(self):
        del self.ptr


cdef class A:
    cdef cppA *ptr

    def __init__(self, B b):
        self.ptr = new cppA()
        self.ptr.storeB(b.ptr)

    def __dealloc__(self):
        del self.ptr

# Example usage
b = B()
a = A(b)
```

> The destructor `~cppA` does some cleanup on the `cppB` instances that were passed to it via `storeB()` method.

> If `b.__dealloc__()` is called before `a.__dealloc()` (for example when the application exits), `~cppA` will operate on already deleted instances and throw a SIGSEGV.

> How should I handle this situation ? I thought about storing a reference to 'b' in 'a' to let the GC sort things out, but that didn't change anything.

- Solution by Robert:

```cython
cdef class B:
    cdef cppB *ptr
    cdef bint owned

    def __init__(self):
        self.ptr = new cppB()
        owned = True

    def __dealloc__(self):
        if owned:
            del self.ptr


cdef class A:
    cdef cppA *ptr
    cdef B b

    def __init__(self, B b):
        self.ptr = new cppA()
        self.ptr.storeB(b.ptr)
        b.owned = False
        self.b = b

    def __dealloc__(self):
        del self.ptr
        del self.b.ptr

# Example usage
b = B()
a = A(b)

```

- Solution by Stefan Behnel

  > It can't. The GC has to figure out reference cycles anyway, so it's just
  another reference that it determines unreachable.

  > What you can do (and yes, this is a bit of a hack), is manually increase
  the reference count to the B instance in A with a call to Py_INCREF(), and
  then Py_DECREF() it from A.__dealloc__(). That way, the GC will think that
  the B instance is still in use and will leave it alone, until
  A.__dealloc__() is run and explicitly tells it that B is now unreferenced,
  too. Note that B.__dealloc__() may (or may not) run directly during the
  Py_DECREF() call.

  > You can also try to free both cppA and cppB from the same __dealloc__
  method if there's a true 1->1 relation between them. Robert gave you a
  somewhat more generic approach here.

  > Stefan

This could look like this:

```cython
from cpython.ref cimport Py_INCREF, Py_DECREF

cdef class B:
    cdef cppB *ptr

    def __init__(self):
        self.ptr = new cppB()

    def __dealloc__(self):
        del self.ptr


cdef class A:
    cdef cppA *ptr
    cdef B b

    def __init__(self, B b):
        self.ptr = new cppA()
        self.ptr.storeB(b.ptr)
        self.b = b
        Py_INCREF(self.b)

    def __dealloc__(self):
        Py_DECREF(self.b)
        del self.b.ptr

# Example usage
b = B()
a = A(b)

```




## Embedding the Compiler

For LLVM

```c++
// the Faust code to compile as a string (could be in a file too)
string theCode = "import(\"stdfaust.lib\"); process = no.noise;";

// compiling in memory (createDSPFactoryFromFile could be used alternatively)
llvm_dsp_factory* m_factory = createDSPFactoryFromString( 
  "faust", theCode, argc, argv, "", m_errorString, optimize);
// creating the DSP instance for interfacing
dsp* m_dsp = m_factory->createDSPInstance();

// creating a generic UI to interact with the DSP
my_ui* m_ui = new MyUI();
// linking the interface to the DSP instance 
m_dsp->buildUserInterface(m_ui);

// initializing the DSP instance with the SR
m_dsp->init(44100);

// hypothetical audio callback, assuming m_input/m_output are previously allocated 
while (...) {
  m_dsp->compute(128, m_input, m_output);
}

// cleaning
delete m_dsp;
delete m_ui;
deleteDSPFactory(m_factory);
```

