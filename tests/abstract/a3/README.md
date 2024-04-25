# Problem Description

After further testing, I found that I am unable to use even the concrete instance's methods via its pointer, and I keep getting an "ambiguous overloaded method" error.

To illustrate an even more simplified case than the original post consisting of an abstract class of just two classes: an abstract class and a concrete class.


```cpp
// demo.h
#ifndef DEMO_H
#define DEMO_H

#include <string>
#include <iostream>



struct Abstract {
    
    Abstract() {}
    virtual ~Abstract() {}
    
    virtual void inc(int num) = 0;
};


class Concrete : public Abstract {
public:
    Concrete() {}
    virtual ~Concrete() {}

    virtual void inc(int num)
    {
        std::cout << num + 1 << std::endl;
    }
};

void run(Abstract* instance) {
    instance->inc(100);
}


#endif /* DEMO_H */
```

It works fine when compiled in c++ with the main.cpp below and produces the expected '101' result


```cpp
// main.cpp
// g++ -std=c++11 -o main main.cpp
#include "demo.h"

int main() {
    Concrete* instance = new Concrete();
    run(instance);
}
```


Now wrapping the header in cython as below 


```cython
# demo.pyx
# distutils: language = c++
# cython: language_level = 3


cdef extern from "demo.h":
    cdef cppclass Abstract:
        Abstract() except +
        void inc(int num)

    cdef cppclass Concrete(Abstract):
        Concrete() except +
        void inc(int num)

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
```

with the following setup.py file

```python
#setup.py
from distutils.core import setup
from Cython.Build import cythonize

setup(
    name = 'demo',
    ext_modules = cythonize('*.pyx'),
)
```

produces


```text
Compiling demo.pyx because it changed.
[1/1] Cythonizing demo.pyx

Error compiling Cython file:
------------------------------------------------------------
...
    def __cinit__(self):
        self.ptr = new Concrete()
        self.abstract_ptr = self.ptr

    def inc(self, int num):
        self.ptr.inc(num)
                    ^
------------------------------------------------------------

demo.pyx:36:20: ambiguous overloaded method
Traceback (most recent call last):
  File "$HOME/a3/setup.py", line 6, in <module>
    ext_modules = cythonize('*.pyx'),
                  ^^^^^^^^^^^^^^^^^^
  File "/opt/homebrew/lib/python3.11/site-packages/Cython/Build/Dependencies.py", line 1154, in cythonize
    cythonize_one(*args)
  File "/opt/homebrew/lib/python3.11/site-packages/Cython/Build/Dependencies.py", line 1321, in cythonize_one
    raise CompileError(None, pyx_file)
Cython.Compiler.Errors.CompileError: demo.pyx
```
