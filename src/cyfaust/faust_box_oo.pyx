
cdef class Button(Box):
    cdef string label

    def __cinit__(self, str lbl):
        self.ptr = <fb.Box>fb.boxButton(lbl.encode('utf8'))

    @staticmethod
    cdef Button from_ptr(fb.Box ptr, bint ptr_owner=False):
        """Wrap external button from pointer"""
        cdef Button box = Button.__new__(Button)
        box.ptr = ptr
        return box

    @property
    def name(self):
        return self.label.decode()

    def is_button(self) -> bool:
        return fb.isBoxButton(self.ptr)

    def update(self):
        cdef fb.Box lbl = NULL
        if fb.isBoxButton(self.ptr, lbl):
            self.label = fb.extractName(lbl)


cdef class Int(Box):

    def __cinit__(self, int value):
        self.ptr = <fb.Box>fb.boxInt(value)

    @staticmethod
    cdef Int from_ptr(fb.Box ptr, bint ptr_owner=False):
        """Wrap external factory from pointer"""
        cdef Int box = Int.__new__(Int)
        box.ptr = ptr
        return box


cdef class Int:
    cdef fb.Box ptr

    def __cinit__(self, int value):
        self.ptr = <fb.Box>fb.boxInt(value)

    @staticmethod
    cdef Int from_ptr(fb.Box ptr, bint ptr_owner=False):
        """Wrap external factory from pointer"""
        cdef Int box = Int.__new__(Int)
        box.ptr = ptr
        return box

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this box."""
        print(fb.printBox(self.ptr, shared, max_size).decode())

    def __add__(self, Box other):
        """Add this box to another."""
        cdef fb.Box b = fb.boxAdd(self.ptr, other.ptr)
        return Box.from_ptr(b)

    def __radd__(self, Box other):
        """Reverse add this box to another."""
        cdef fb.Box b = fb.boxAdd(self.ptr, other.ptr)
        return Box.from_ptr(b)