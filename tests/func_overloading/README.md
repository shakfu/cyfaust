
The issue here is how to use overloaded c++ functions as function pointers
in cython.

In the below example, the nullary_op_func version does not work for some
reason.

```cython
# functions of type ()->fb.Box
ctypedef fb.Box(*nullary_op_func)()
ctypedef fb.Box(*unary_op_func)(fb.Box)
ctypedef fb.Box(*binary_op_func)(fb.Box, fb.Box)

cdef Box box_from_nullary_op(nullary_op_func func):
    cdef fb.Box b = func()
    return Box.from_ptr(b)

cdef Box box_from_binary_op(binary_op_func func, Box x, Box y):
    cdef fb.Box b = func(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_add_op() -> Box:
    return box_from_nullary_op(fb.boxAdd)

def box_add(Box b1, Box b2) -> Box:
    return box_from_binary_op(fb.boxAdd, b1, b2)
```

