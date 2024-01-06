func = """\
def box_{lower}(Box x) -> Box:
    cdef fb.Box b = fb.box{name}(x.ptr)
    return Box.from_ptr(b)
"""

func_op = """\
def box_{lower}_op() -> Box:
    cdef fb.Box b = fb.box{name}()
    return Box.from_ptr(b)
"""

method = """\
    def {lower}(self) -> Box: 
        return box_{lower}(self.ptr)
"""

names = [
    'Abs',
    'Acos',
    'Tan',
    'Sqrt',
    'Sin',
    'Rint',
    'Round',
    'Log',
    'Log10',
    'Floor',
    'Exp',
    'Exp10',
    'Cos',
    'Ceil',
    'Atan',
    'Asin',
]

for name in names:
    lower = name.lower()
    # print(func_op.format(name=name, lower=lower))
    # print(func.format(name=name, lower=lower))
    print(method.format(name=name, lower=lower))

