# distutils: language = c++

from libc.stdlib cimport malloc, free
from libcpp.string cimport string

from . cimport faust_box as fb
from . cimport faust_signal as fs

from .signal cimport SignalVector
from .signal import SignalVector

from .common cimport ParamArray
from .common import ParamArray

## ---------------------------------------------------------------------------
## faust/dsp/libfaust-box

def box_or_int(var: Box | int) -> Box:
    if isinstance(var, int):
        return Box.from_int(var)
    if isinstance(var, Box):
        assert is_box_int(var), "box is not an int box"
        return var
    raise TypeError("argument must be an int or a boxInt")

def box_or_float(var: Box | float) -> Box:
    if isinstance(var, float):
        return Box.from_real(var)
    elif isinstance(var, Box):
        assert is_box_real(var), "box is not a float box"
        return var
    raise TypeError("argument must be an float or a boxReal")

def box_or_number(var: Box | float | int) -> Box:
    if isinstance(var, int):
        return Box.from_int(var)
    if isinstance(var, float):
        return Box.from_real(var)
    elif isinstance(var, Box):
        assert is_box_real(var) or is_box_int(var), "box is not a float or int box"
        return var
    raise TypeError("argument must be of type float or int or boxReal or boxInt")


class box_context:
    """box context manager

    required for box operations
    """
    def __enter__(self):
        fb.createLibContext()
    def __exit__(self, type, value, traceback):
        fb.destroyLibContext()


cdef class BoxVector:
    """wraps tvec: a std::vector<CTree*>"""
    # cdef vector[fb.Box] ptr
    # cdef bint ptr_owner

    def __cinit__(self):
        self.ptr_owner = False

    def __iter__(self):
        for i in self.ptr:
            yield Box.from_ptr(i)

    @staticmethod
    cdef BoxVector from_ptr(fb.tvec ptr):
        """Wrap a fs.tvec instance."""
        cdef BoxVector bv = BoxVector.__new__(BoxVector)
        bv.ptr = ptr
        return bv

    cdef add_ptr(self, fb.Box b):
        """add pointer to unwrapped Box"""
        self.ptr.push_back(b)

    def add(self, Box b):
        """add wrapped Box"""
        self.ptr.push_back(b.ptr)

    def create_source(self, name_app: str, lang, *args) -> str:
        """Create source code in a target language from a box expression."""
        return create_source_from_boxes(name_app, self, lang, *args)



cdef class Box:
    """faust Box wrapper.
    """
    # cdef fb.Box ptr
    # cdef public int inputs
    # cdef public int outputs

    def __cinit__(self):
        self.ptr = NULL
        self.inputs = 0
        self.outputs = 0

    def __init__(self, value = None):
        if not value:
            self.ptr = fb.boxWire()
        elif isinstance(value, int):
            self.ptr = fb.boxInt(value)
        elif isinstance(value, float):
            self.ptr = fb.boxReal(value)

    @staticmethod
    cdef Box from_ptr(fb.Box ptr, bint ptr_owner=False):
        """Wrap external factory from pointer"""
        cdef Box box = Box.__new__(Box)
        box.ptr = ptr
        return box

    @staticmethod
    def from_int(int value) -> Box:
        """Create box from int"""
        return box_int(value)

    @staticmethod
    def from_float(float value) -> Box:
        """Create box from float"""
        return box_float(value)

    from_real = from_float

    @staticmethod
    def from_wire() -> Box:
        """Create box from wire box, copies its input to its output"""
        return box_wire()

    @staticmethod
    def from_cut() -> Box:
        """Create box from a cut box, to stop/terminate a signal"""
        return box_cut()

    @staticmethod
    def from_soundfile(str label, chan: Box | int, part: Box | None, ridx: Box | int | None) -> Box:
        """Create a soundfile block.

        label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
        chan - the number of outputs channels, a constant numerical expression
        part - in the [0..255] range to select a given sound number, a constant numerical expression
        ridx - the read index (an integer between 0 and the selected sound length)

        returns the soundfile box.
        """
        return box_soundfile(label, chan, part, ridx)

    @staticmethod
    def from_readonly_table(n: Box | int, Box init, ridx: Box | int) -> Box:
        """Create a read only table.

        n    - the table size, a constant numerical expression
        init - the table content
        ridx - the read index (an int between 0 and n-1)

        returns the table box.
        """
        _n = box_or_int(n)
        _ridx = box_or_int(ridx)
        return box_readonly_table(_n, init, _ridx)

    @staticmethod
    def from_write_read_table(n: Box | int, Box init, widx: Box | int, Box wsig, ridx: Box | int) -> Box:
        """Create a read/write table.

        n    - the table size, a constant numerical expression
        init - the table content
        widx - the write index (an integer between 0 and n-1)
        wsig - the input of the table
        ridx - the read index (an integer between 0 and n-1)

        returns the table box.
        """
        _n = box_or_int(n)
        _ridx = box_or_int(ridx)
        _widx = box_or_int(widx)
        return box_write_read_table(_n, init, _widx, wsig, _ridx)

    @staticmethod
    def from_waveform(BoxVector wf) -> Box:
        """Create a waveform.

        wf - the content of the waveform as a vector of boxInt or boxDouble boxes

        returns the waveform box.
        """
        return box_waveform(wf)
 
    @staticmethod
    def from_fconst(fb.SType type, str name, str file) -> Box:
        """Create a foreign constant box.

        type - the foreign constant type of SType {kSInt, kSReal}
        name - the foreign constant name
        file - the include file where the foreign constant is defined

        returns the foreign constant box.
        """
        return box_fconst(type, name, file)

    @staticmethod
    def from_fvar(fb.SType type, str name, str file) -> Box:
        """Create a foreign variable box.

        type - the foreign variable type of SType {kSInt, kSReal}
        name - the foreign variable name
        file - the include file where the foreign variable is defined

        returns the foreign variable box.
        """
        return box_fvar(type, name, file)

    def is_valid(self) -> bool:
        """Return true if box is defined, false otherwise

        sets number of inputs and outputs as a side-effect
        """
        return fb.getBoxType(self.ptr, &self.inputs, &self.outputs)

    def to_string(self, shared: bool = False, max_size: int = 256) -> str:
        """Convert the box to a string via printBox mechanism

        box - the box to be converted
        shared - whether the identical sub boxes are converted as identifiers
        max_size - the maximum number of characters to be converted (possibly 
                   needed for big expressions in non shared mode)

        returns the box as a string
        """
        return to_string(self, shared, max_size).decode()

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this box."""
        print_box(self, shared, max_size)

    def create_source(self, str name_app, str lang, *args) -> str:
        """Create source code in a target language from a box expression.

        name_app - the name of the Faust program
        lang - the target source code's language which can be one of 
            'c', 'cpp', 'cmajor', 'codebox', 'csharp', 'dlang', 'fir', 
            'interp', 'java', 'jax','jsfx', 'julia', 'ocpp', 'rust' or 'wast'
            (depending of which of the corresponding backends are compiled in libfaust)
        args - tuple of parameters if any

        returns a string of source code on success, printing error_msg if error.
        """
        return create_source_from_boxes(name_app, self, lang, *args)

    def __add__(self, Box other):
        """Add this box to another."""
        return box_add(self, other)

    def __radd__(self, Box other):
        """Reverse add this box to another."""
        return box_add(self, other)

    def __sub__(self, Box other):
        """Subtract this box from another."""
        return box_sub(self, other)

    def __rsub__(self, Box other):
        """Subtract this box from another."""
        return box_sub(self, other)

    def __mul__(self, Box other):
        """Multiply this box with another."""
        return box_mul(self, other)

    def __rmul__(self, Box other):
        """Reverse multiply this box with another."""
        return box_mul(self, other)

    def __div__(self, Box other):
        """Divide this box with another."""
        return box_div(self, other)

    def __rdiv__(self, Box other):
        """Reverse divide this box with another."""
        return box_div(self, other)

    def __eq__(self, Box other):
        """Compare for equality with another box."""
        return box_eq(self, other)

    def __ne__(self, Box other):
        """Assert this box is not equal with another box."""
        return box_ne(self, other)

    def __gt__(self, Box other):
        """Is this box greater than another box."""
        return box_gt(self, other)

    def __ge__(self, Box other):
        """Is this box greater than or equal from another box."""
        return box_ge(self, other)

    def __lt__(self, Box other):
        """Is this box lesser than another box."""
        return box_lt(self, other)

    def __le__(self, Box other):
        """Is this box lesser than or equal from another box."""
        return box_le(self, other)

    def __and__(self, Box other):
        """logical and with another box"""
        return box_and(self, other)

    def __or__(self, Box other):
        """logical or with another box"""
        return box_or(self, other)

    def __xor__(self, Box other):
        """logical xor with another box"""
        return box_xor(self, other)

    def __lshift__(self, Box other):
        """bitwise left-shift"""
        return box_leftshift(self, other)

    def __rshift__(self, Box other):
        """bitwise right-shift"""
        return box_lrightshift(self, other)

    def arightshift(self, Box other) -> Box:
        """bitwise arithmetic right shift"""
        return box_arightshift(self, other)

    def tree2str(self):
        """Convert this box tree (such as the label of a UI) to a string."""
        return fb.tree2str(self.ptr).decode()

    def tree2int(self):
        """If this box tree has a node of type int, return it, otherwise error."""
        return fb.tree2int(self.ptr).decode()

    def abs(self) -> Box:
        """returns an absolute value box of this instance."""
        return box_abs(self)

    def acos(self) -> Box:
        """returns an arccosine box of this instance."""
        return box_acos(self)

    def tan(self) -> Box:
        """returns a tangent box of this instance."""
        return box_tan(self)

    def sqrt(self) -> Box:
        """returns a sqrt box of this instance."""
        return box_sqrt(self)

    def sin(self) -> Box:
        """returns a sin box of this instance."""
        return box_sin(self)

    def rint(self) -> Box:
        """returns a round to nearest int box of this instance."""
        return box_rint(self)

    def round(self) -> Box:
        """returns a round box of this instance."""
        return box_round(self)

    def log(self) -> Box:
        """returns a log box of this instance."""
        return box_log(self)

    def log10(self) -> Box:
        """returns a log10 box of this instance."""        
        return box_log10(self)

    def floor(self) -> Box:
        """returns a floor box of this instance."""
        return box_floor(self)

    def exp(self) -> Box:
        """returns an exp box of this instance."""
        return box_exp(self)

    def exp10(self) -> Box:
        """returns an exp10 box of this instance."""
        return box_exp10(self)

    def cos(self) -> Box:
        """returns an cosine box of this instance."""
        return box_cos(self)

    def ceil(self) -> Box:
        """returns an ceiling box of this instance."""
        return box_ceil(self)

    def atan(self) -> Box:
        """returns an arc tangent box of this instance."""
        return box_atan(self)

    def asin(self) -> Box:
        """returns an arc sine box of this instance."""
        return box_asin(self)

    # boolean methods ----------------

    def is_nil(self) -> bool:
        """Test if a box is nil."""
        return box_is_nil(self)

    def is_abstr(self) -> bool:
        """Test if a box is an abstraction.
        
        see: https://faustdoc.grame.fr/manual/syntax
        """
        return is_box_abstr(self)

    def is_appl(self) -> bool:
        """Test if a box is an application."""
        return is_box_appl(self)

    def is_button(self) -> bool:
        """Test if a box is a button."""
        return is_box_button(self)

    def is_case(self) -> bool:
        return is_box_case(self)

    def is_checkbox(self) -> bool:
        """Test if a box is an checkbox."""
        return is_box_checkbox(self)

    def is_cut(self) -> bool:
        """Test if a box is a cut."""
        return is_box_cut(self)

    def is_environment(self) -> bool:
        """Test if a box is an environmnent."""
        return is_box_environment(self)

    def is_error(self) -> bool:
        """Test if a box is an error."""
        return is_box_error(self)

    def is_fconst(self) -> bool:
        """Test if a box is an fconst."""
        return is_box_fconst(self)

    def is_ffun(self) -> bool:
        """Test if a box is an ffun."""    
        return is_box_ffun(self)

    def is_fvar(self) -> bool:
        """Test if a box is an fvar."""    
        return is_box_fvar(self)

    def is_hbargraph(self) -> bool:
        """Test if a box is an hbargraph."""
        return is_box_hbargraph(self)

    def is_hgroup(self) -> bool:
        """Test if a box is an hgroup."""
        return is_box_hgroup(self)

    def is_hslider(self) -> bool:
        """Test if a box is an hslider."""
        return is_box_hslider(self)

    def is_ident(self) -> bool:
        """Test if a box is an indentifier."""
        return is_box_ident(self)

    def is_int(self) -> bool:
        """Test if a box is an int."""    
        return is_box_int(self)

    def is_numentry(self) -> bool:
        """Test if a box is an numentry."""
        return is_box_numentry(self)

    def is_prim0(self) -> bool:
        """Test if a box is a nullary function."""    
        return is_box_prim0(self)

    def is_prim1(self) -> bool:
        """Test if a box is a unitary function."""
        return is_box_prim1(self)

    def is_prim2(self) -> bool:
        """Test if a box is a binary function."""
        return is_box_prim2(self)

    def is_prim3(self) -> bool:
        """Test if a box is a ternary function."""
        return is_box_prim3(self)

    def is_prim4(self) -> bool:
        """Test if a box is a 4 param function."""
        return is_box_prim4(self)

    def is_prim5(self) -> bool:
        """Test if a box is a 5 param function."""
        return is_box_prim5(self)

    def is_real(self) -> bool:
        """Test if a box is a real or floot box."""
        return is_box_real(self)

    def is_slot(self) -> bool:
        """Test if a box is a slot."""
        return is_box_slot(self)

    def is_soundfile(self) -> bool:
        """Test if a box is a soundfile."""
        return is_box_soundfile(self)

    def is_symbolic(self) -> bool:
        """Test if a box is symbolic."""
        return is_box_symbolic(self)

    def is_tgroup(self) -> bool:
        """Test if a box is a tab group."""
        return is_box_tgroup(self)

    def is_vgroup(self) -> bool:
        """Test if a box is a vertical group."""
        return is_box_vgroup(self)

    def is_vslider(self) -> bool:
        """Test if a box is a vertical slider."""
        return is_box_vslider(self)

    def is_hslider(self) -> bool:
        """Test if a box is a horizontal slider."""
        return is_box_hslider(self)

    def is_waveform(self) -> bool:
        """Test if a box is a waveform."""
        return is_box_waveform(self)

    def is_wire(self) -> bool:
        """Test if a box is a wire (pass-through) box."""
        return is_box_wire(self)


    def int_cast(self) -> Box:
        """return an int casted box."""
        return box_int_cast(self)


    def float_cast(self) -> Box:
        """return a float/double casted box.""

        s - the signal to be casted as float/double value 
            (depends of -single or -double compilation parameter)

        returns the casted box.
        """
        return box_float_cast(self)


    def seq(self, Box y) -> Box:
        """The sequential composition of two blocks (e.g., A:B)

        expects: outputs(A)=inputs(B)

        returns the seq box.
        """
        return box_seq(self, y)

    def par(self, Box y) -> Box:
        """The parallel composition of two blocks (e.g., A,B).

        Creates a two block-diagram with one block on top of the other,
        without connections.

        returns the par box.
        """
        return box_par(self, y)


    def par3(self, Box y, Box z) -> Box:
        """The parallel composition of three blocks (e.g., A,B,C).
        
        Creates a three block-diagram with one block on top of the other,
        without connections.

        returns the par box.    
        """
        return box_par3(self, y, z)


    def par4(self, Box b, Box c, Box d) -> Box:
        """The parallel composition of four blocks (e.g., A,B,C,D).

        Creates a four block-diagram with one block on top of the other,
        without connections.

        returns the par box.
        """
        return box_par4(self, b, c, d)


    def par5(self, Box b, Box c, Box d, Box e) -> Box:
        """The parallel composition of five blocks (e.g., A,B,C,D,E).

        Creates a five block-diagram with one block on top of the other,
        without connections.

        returns the par box.
        """
        return box_par4(self, b, c, d, e)


    def split(self, Box y) -> Box:
        """The split composition (e.g., A<:B) operator is used to distribute
        the outputs of A to the inputs of B.

        For the operation to be valid, the number of inputs of B
        must be a multiple of the number of outputs of A: outputs(A).k=inputs(B)

        returns the split box.
        """
        return box_split(self, y)


    def merge(self, Box y) -> Box:
        """The merge composition (e.g., A:>B) is the dual of the split composition.

        The number of outputs of A must be a multiple of the number of inputs of B:
        outputs(A)=k.inputs(B)

        returns the merge box.
        """
        return box_merge(self, y)


    def rec(self, Box y) -> Box:
        """The recursive composition (e.g., A~B) is used to create cycles in the
        block-diagram in order to express recursive computations.

        It is the most complex operation in terms of connections:
        outputs(A)≥inputs(B) and inputs(A)≥outputs(B)

        returns the rec box.
        """
        return box_rec(self, y)


    def get_def_name_property(self) -> Box | None:
        """Returns the identifier (if any) the expression was a definition of.

        b the expression
        id reference to the identifier

        returns the identifier if the expression b was a definition of id
        else returns None
        """
        cdef fb.Box id = NULL
        if fb.getDefNameProperty(self.ptr, id):
            return Box.from_ptr(id)

    def extract_name(self) -> str:
        """Extract the name from a label.

        full_label the label to be analyzed

        returns the extracted name
        """
        return extract_name(self)

    def delay(self, d: int | Box) -> Box:
        """Create a delayed box.

        s - the box to be delayed
        d - the delay box that doesn't have to be fixed but must be bounded
            and cannot be negative

        returns the delayed box.
        """
        if isinstance(d, int):
            return box_delay(self, Box.from_int(d))
        else:
            return box_delay(self, d.ptr)

    def select2(self, Box b1, Box b2) -> Box:
        """return a selector between two boxes.

        selector - when 0 at time t returns s1[t], otherwise returns s2[t]
        s1 - first box to be selected
        s2 - second box to be selected

        returns the selected box depending of the selector value at each time t.
        """
        return box_select2(self, b1, b2)


    def select3(self, Box b1, Box b2, Box b3) -> Box:
        """return a selector between three boxes.

        selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t],
                   otherwise returns s3[t]
        s1 - first box to be selected
        s2 - second box to be selected
        s3 - third box to be selected

        returns the selected box depending of the selector value at each time t.
        """
        return box_select3(self, b1, b2, b3)


def to_string(Box box, bint shared, int max_size) -> str:
    """Convert the box to a string

    box - the box to be converted
    shared - whether the identical sub boxes are converted as identifiers
    max_size - the maximum number of characters to be converted (possibly 
               needed for big expressions in non shared mode)

    returns the box as a string
    """
    return fb.printBox(box.ptr, shared, max_size).decode()


def print_box(Box box, bint shared, int max_size) -> str:
    """Print the box.

    box - the box to be printed
    shared - whether the identical sub boxes are printed as identifiers
    max_size - the maximum number of characters to be printed (possibly 
               needed for big expressions in non shared mode)

    returns the printed box as a string
    """
    return print(fb.printBox(box.ptr, shared, max_size).decode())


def get_def_name_property(Box b) -> Box | None:
    """Returns the identifier (if any) the expression was a definition of.

    b the expression
    id reference to the identifier

    returns the identifier if the expression b was a definition of id
    else returns None
    """
    cdef fb.Box id = NULL
    if fb.getDefNameProperty(b.ptr, id):
        return Box.from_ptr(id)

def extract_name(Box full_label) -> str:
    """Extract the name from a label.

    full_label the label to be analyzed

    returns the extracted name
    """
    return fb.extractName(full_label.ptr).decode()

def create_lib_context():
    """Create global compilation context, has to be done first."""
    fb.createLibContext()

def destroy_lib_context():
    """Destroy global compilation context, has to be done last."""
    fb.destroyLibContext()


# cdef void* get_user_data(Box b):
#     """Return the xtended type of a box.

#     b - the box whose xtended type to return

#     returns a pointer to xtended type if it exists, otherwise nullptr.
#     """
#     return fb.getUserData(b.ptr)


def box_is_nil(Box b) -> bool:
    """Check if a box is nil.

    b - the box

    returns true if the box is nil, otherwise false.
    """
    return fb.isNil(b.ptr)


def tree2str(Box b) -> str:
    """Convert a box (such as the label of a UI) to a string.

    b - the box to convert

    returns a string representation of a box.
    """
    return fb.tree2str(b.ptr).decode()


def tree2int(Box b) -> int:
    """If t has a node of type int, return it. Otherwise error

    b - the box to convert

    returns the int value of the box.
    """
    return fb.tree2int(b.ptr)



def box_int(int n) -> Box:
    """Constant integer : for all t, x(t) = n.

    n - the integer

    returns the integer box.
    """
    cdef fb.Box b = fb.boxInt(n)
    return Box.from_ptr(b)


def box_float(float n) -> Box:
    """Constant real : for all t, x(t) = n.

    n - the float/double value (depends of -single or -double compilation parameter)

    returns the float/double box.
    """
    cdef fb.Box b = fb.boxReal(n)
    return Box.from_ptr(b)

box_real = box_float


def box_wire() -> Box:
    """The identity box, copy its input to its output.

    returns the identity box.
    """
    cdef fb.Box b = fb.boxWire()
    return Box.from_ptr(b)


def box_cut() -> Box:
    """The cut box, to stop/terminate a signal.

    returns the cut box.
    """
    cdef fb.Box b = fb.boxCut()
    return Box.from_ptr(b)


def box_seq(Box x, Box y) -> Box:
    """The sequential composition of two blocks (e.g., A:B)
    expects: outputs(A)=inputs(B)

    returns the seq box.
    """
    cdef fb.Box b = fb.boxSeq(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_par(Box x, Box y) -> Box:
    """The parallel composition of two blocks (e.g., A,B).

    It places the two block-diagrams one on top of the other,
    without connections.

    returns the par box.
    """
    cdef fb.Box b = fb.boxPar(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_par3(Box x, Box y, Box z) -> Box:
    """The parallel composition of three blocks (e.g., A,B,C).
    
    It places the three block-diagrams one on top of the other,
    without connections.

    returns the par box.    
    """
    cdef fb.Box b = fb.boxPar3(x.ptr, y.ptr, z.ptr)
    return Box.from_ptr(b)


def box_par4(Box a, Box b, Box c, Box d) -> Box:
    """The parallel composition of four blocks (e.g., A,B,C,D).

    It places the four block-diagrams one on top of the other,
    without connections.

    returns the par box.
    """
    cdef fb.Box p = fb.boxPar4(a.ptr, b.ptr, c.ptr, d.ptr)
    return Box.from_ptr(p)


def box_par5(Box a, Box b, Box c, Box d, Box e) -> Box:
    """The parallel composition of five blocks (e.g., A,B,C,D,E).

    It places the five block-diagrams one on top of the other,
    without connections.

    returns the par box.
    """
    cdef fb.Box p = fb.boxPar5(a.ptr, b.ptr, c.ptr, d.ptr, e.ptr)
    return Box.from_ptr(p)

def box_split(Box x, Box y) -> Box:
    """The split composition (e.g., A<:B) operator is used to distribute
    the outputs of A to the inputs of B.

    For the operation to be valid, the number of inputs of B
    must be a multiple of the number of outputs of A:
    outputs(A).k=inputs(B)

    returns the split box.
    """
    cdef fb.Box b = fb.boxSplit(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_merge(Box x, Box y) -> Box:
    """The merge composition (e.g., A:>B) is the dual of the split composition.

    The number of outputs of A must be a multiple of the number of inputs of B:
    outputs(A)=k.inputs(B)

    returns the merge box.
    """
    cdef fb.Box b = fb.boxMerge(x.ptr, y.ptr)
    return Box.from_ptr(b)


def box_rec(Box x, Box y) -> Box:
    """The recursive composition (e.g., A~B) is used to create cycles
    in the block-diagram in order to express recursive computations.

    It is the most complex operation in terms of connections:
    outputs(A)≥inputs(B) and inputs(A)≥outputs(B)

    returns the rec box.
    """
    cdef fb.Box b = fb.boxRec(x.ptr, y.ptr)
    return Box.from_ptr(b)

def box_route(Box n, Box m, Box r) -> Box:
    """The route primitive facilitates the routing of signals in Faust.

    It has the following syntax:
    route(A,B,a,b,c,d,...) or route(A,B,(a,b),(c,d),...)

    n - the number of input signals
    m - the number of output signals
    r - the routing description, a 'par' expression of
        a,b / (a,b) input/output pairs

    returns the route box.
    """
    cdef fb.Box b = fb.boxRoute(n.ptr, m.ptr, r.ptr)
    return Box.from_ptr(b)


def box_delay_op() -> Box:
    """Create a delayed box.

    returns the delayed box.
    """
    cdef fb.Box b = fb.boxDelay()
    return Box.from_ptr(b)


def box_delay(Box b, Box d) -> Box:
    """Create a delayed box.

    s - the box to be delayed
    d - the delay box that doesn't have to be fixed but must be bounded
        and cannot be negative

    returns the delayed box.
    """
    cdef fb.Box _b = fb.boxDelay(b.ptr, d.ptr)
    return Box.from_ptr(_b)


def box_int_cast_op() -> Box:
    """Create a casted box.

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxIntCast()
    return Box.from_ptr(_b)


def box_int_cast(Box b) -> Box:
    """Create a casted box.

    s - the box to be casted in integer

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxIntCast(b.ptr)
    return Box.from_ptr(_b)


def box_float_cast_op() -> Box:
    """Create a casted box."""
    cdef fb.Box _b = fb.boxFloatCast()
    return Box.from_ptr(_b)


def box_float_cast(Box b) -> Box:
    """Create a casted box.

    s - the signal to be casted as float/double value (depends of 
        -single or -double compilation parameter)

    returns the casted box.
    """
    cdef fb.Box _b = fb.boxFloatCast(b.ptr)
    return Box.from_ptr(_b)


def box_readonly_table_op() -> Box:
    """Create a read only table.

    returns the table box.
    """
    cdef fb.Box b = fb.boxReadOnlyTable()
    return Box.from_ptr(b)


def box_readonly_table(Box n, Box init, Box ridx) -> Box:
    """Create a read only table.

    n - the table size, a constant numerical expression
    init - the table content
    ridx - the read index (an int between 0 and n-1)

    returns the table box.
    """
    cdef fb.Box b = fb.boxReadOnlyTable(n.ptr, init.ptr, ridx.ptr)
    return Box.from_ptr(b)

def box_write_read_table_op() -> Box:
    """Create a read/write table.
    
    returns the table box.
    """
    cdef fb.Box b = fb.boxWriteReadTable()
    return Box.from_ptr(b)

def box_write_read_table(Box n, Box init, Box widx, Box wsig, Box ridx) -> Box:
    """Create a read/write table.

    n - the table size, a constant numerical expression
    init - the table content
    widx - the write index (an integer between 0 and n-1)
    wsig - the input of the table
    ridx - the read index (an integer between 0 and n-1)

    returns the table box.
    """
    cdef fb.Box b = fb.boxWriteReadTable(n.ptr, init.ptr, widx.ptr, wsig.ptr, ridx.ptr)
    return Box.from_ptr(b)


def box_waveform(BoxVector wf):
    """Create a waveform.

    wf - the content of the waveform as a vector of boxInt or boxDouble boxes

    returns the waveform box.
    """
    cdef fb.Box b = fb.boxWaveform(<const fs.tvec>wf.ptr)
    return Box.from_ptr(b)


def box_soundfile(str label, chan: Box | int, part: Box | None, ridx: Box | int | None) -> Box:
    """Create a soundfile block.

    label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
    chan - the number of outputs channels, a constant numerical expression

    (box_soundfile2 parameters)
    part - in the [0..255] range to select a given sound number, a constant numerical expression
    ridx - the read index (an integer between 0 and the selected sound length)

    returns the soundfile box.
    """
    _chan = box_or_int(chan)
    if part and ridx:
        _ridx = box_or_int(ridx)
        return __box_soundfile2(label, _chan, part, _ridx)
    else:
        return __box_soundfile1(label, _chan)


cdef Box __box_soundfile1(str label, Box chan):
    """Create a soundfile block.

    label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
    chan - the number of outputs channels, a constant numerical expression

    returns the soundfile box.
    """
    cdef fb.Box b = fb.boxSoundfile(label.encode('utf8'), chan.ptr)
    return Box.from_ptr(b)


cdef Box __box_soundfile2(str label, Box chan, Box part, Box ridx):
    """Create a soundfile block.

    label - of form "label[url:{'path1';'path2';'path3'}]" to describe a list of soundfiles
    chan - the number of outputs channels, a constant numerical expression
    part - in the [0..255] range to select a given sound number, a constant numerical expression
    ridx - the read index (an integer between 0 and the selected sound length)

    returns the soundfile box.
    """
    cdef fb.Box b = fb.boxSoundfile(label.encode('utf8'), chan.ptr, part.ptr, ridx.ptr)
    return Box.from_ptr(b)


def box_select2(Box selector, Box b1, Box b2) -> Box:
    """Create a selector between two boxes.

    selector - when 0 at time t returns s1[t], otherwise returns s2[t]
    s1 - first box to be selected
    s2 - second box to be selected

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect2(selector.ptr, b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_select2_op() -> Box:
    """Create a selector between two boxes.

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect2()
    return Box.from_ptr(b)


def box_select3(Box selector, Box b1, Box b2, Box b3) -> Box:
    """Create a selector between three boxes.

    selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t], 
               otherwise returns s3[t]
    s1 - first box to be selected
    s2 - second box to be selected
    s3 - third box to be selected

    returns the selected box depending of the selector value at each time t.
    """
    cdef fb.Box b = fb.boxSelect3(selector.ptr, b1.ptr, b2.ptr, b3.ptr)
    return Box.from_ptr(b)

def box_fconst(fb.SType type, str name, str file) -> Box:
    """Create a foreign constant box.

    type - the foreign constant type of SType
    name - the foreign constant name
    file - the include file where the foreign constant is defined

    returns the foreign constant box.
    """
    cdef fb.Box b = fb.boxFConst(type, name.encode('utf8'), file.encode('utf8'))
    return Box.from_ptr(b)

def box_fvar(fb.SType type, str name, str file) -> Box:
    """Create a foreign variable box.

    type - the foreign variable type of SType
    name - the foreign variable name
    file - the include file where the foreign variable is defined

    returns the foreign variable box.
    """
    cdef fb.Box b = fb.boxFVar(type, name.encode('utf8'), file.encode('utf8'))
    return Box.from_ptr(b)

def box_bin_op0(fb.SOperator op) -> Box:
    """Generic binary mathematical functions.

    op - the operator in SOperator set

    returns the result box of op(x,y).
    """
    cdef fb.Box b = fb.boxBinOp(op)
    return Box.from_ptr(b)

def box_bin_op(fb.SOperator op, Box b1, Box b2) -> Box:
    """Generic binary mathematical functions.

    op - the operator in SOperator set

    returns the result box of op(x,y).
    """
    cdef fb.Box b = fb.boxBinOp(op, b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_add_op() -> Box:
    """nullary box add operation."""
    cdef fb.Box b = fb.boxAdd()
    return Box.from_ptr(b)

def box_add(Box b1, Box b2) -> Box:
    """binary box add operation."""
    cdef fb.Box b = fb.boxAdd(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_sub_op() -> Box:
    """nullary box substract operation."""
    cdef fb.Box b = fb.boxSub()
    return Box.from_ptr(b)

def box_sub(Box b1, Box b2) -> Box:
    """binary box substract operation."""
    cdef fb.Box b = fb.boxSub(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_mul_op() -> Box:
    """nullary box multipy operation."""
    cdef fb.Box b = fb.boxMul()
    return Box.from_ptr(b)

def box_mul(Box b1, Box b2) -> Box:
    """binary box multiply operation."""
    cdef fb.Box b = fb.boxMul(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_div_op() -> Box:
    """nullary box divide operation."""
    cdef fb.Box b = fb.boxDiv()
    return Box.from_ptr(b)

def box_div(Box b1, Box b2) -> Box:
    """binary box divide operation."""
    cdef fb.Box b = fb.boxDiv(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_rem_op() -> Box:
    """nullary box modulo operation."""
    cdef fb.Box b = fb.boxRem()
    return Box.from_ptr(b)

def box_rem(Box b1, Box b2) -> Box:
    """binary box modulo operation."""
    cdef fb.Box b = fb.boxRem(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_leftshift_op() -> Box:
    """nullary box left bitshift operation."""
    cdef fb.Box b = fb.boxLeftShift()
    return Box.from_ptr(b)

def box_leftshift(Box b1, Box b2) -> Box:
    """binary box left bit shift operation."""
    cdef fb.Box b = fb.boxLeftShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_lrightshift_op() -> Box:
    """nullary box logical right bit shift operation."""
    cdef fb.Box b = fb.boxLRightShift()
    return Box.from_ptr(b)

def box_lrightshift(Box b1, Box b2) -> Box:
    """binary box logical right bit shift operation."""
    cdef fb.Box b = fb.boxLRightShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_arightshift_op() -> Box:
    """bitwise arithmetic right bit shift op"""
    cdef fb.Box b = fb.boxARightShift()
    return Box.from_ptr(b)

def box_arightshift(Box b1, Box b2) -> Box:
    """bitwise arithmetic right shift"""
    cdef fb.Box b = fb.boxARightShift(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_gt_op() -> Box:
    """nullary greater than operation."""
    cdef fb.Box b = fb.boxGT()
    return Box.from_ptr(b)

def box_gt(Box b1, Box b2) -> Box:
    """binary box greater than operation."""
    cdef fb.Box b = fb.boxGT(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_lt_op() -> Box:
    """nullary less than operation."""
    cdef fb.Box b = fb.boxLT()
    return Box.from_ptr(b)

def box_lt(Box b1, Box b2) -> Box:
    """binary box lesser than operation."""
    cdef fb.Box b = fb.boxLT(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_ge_op() -> Box:
    """nullary greater than or equal operation."""
    cdef fb.Box b = fb.boxGE()
    return Box.from_ptr(b)

def box_ge(Box b1, Box b2) -> Box:
    """binary box greater than or equal operation."""
    cdef fb.Box b = fb.boxGE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_le_op() -> Box:
    """nullary less than than equal operation."""
    cdef fb.Box b = fb.boxLE()
    return Box.from_ptr(b)

def box_le(Box b1, Box b2) -> Box:
    """binary box lesser than or equaloperation."""
    cdef fb.Box b = fb.boxLE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_eq_op() -> Box:
    """nullary equal operation."""
    cdef fb.Box b = fb.boxEQ()
    return Box.from_ptr(b)

def box_eq(Box b1, Box b2) -> Box:
    """binary box equals operation."""
    cdef fb.Box b = fb.boxEQ(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_ne_op() -> Box:
    """nullary not equal than operation."""
    cdef fb.Box b = fb.boxNE()
    return Box.from_ptr(b)

def box_ne(Box b1, Box b2) -> Box:
    """binary box not equals than operation."""
    cdef fb.Box b = fb.boxNE(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_and_op() -> Box:
    """nullary AND operation."""
    cdef fb.Box b = fb.boxAND()
    return Box.from_ptr(b)

def box_and(Box b1, Box b2) -> Box:
    """binary box AND operation."""
    cdef fb.Box b = fb.boxAND(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_or_op() -> Box:
    """nullary OR operation."""
    cdef fb.Box b = fb.boxOR()
    return Box.from_ptr(b)

def box_or(Box b1, Box b2) -> Box:
    """binary box OR operation."""
    cdef fb.Box b = fb.boxOR(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_xor_op() -> Box:
    """nullary XOR operation."""
    cdef fb.Box b = fb.boxXOR()
    return Box.from_ptr(b)

def box_xor(Box b1, Box b2) -> Box:
    """binary box XOR operation."""
    cdef fb.Box b = fb.boxXOR(b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_abs_op() -> Box:
    """nullary absolute operation."""
    cdef fb.Box b = fb.boxAbs()
    return Box.from_ptr(b)

def box_abs(Box x) -> Box:
    """unitary box absolute operation."""
    cdef fb.Box b = fb.boxAbs(x.ptr)
    return Box.from_ptr(b)

def box_acos_op() -> Box:
    """nullary arccosine than operation."""
    cdef fb.Box b = fb.boxAcos()
    return Box.from_ptr(b)

def box_acos(Box x) -> Box:
    """unitary box arccosine operation."""
    cdef fb.Box b = fb.boxAcos(x.ptr)
    return Box.from_ptr(b)

def box_tan_op() -> Box:
    """nullary tangent operation."""
    cdef fb.Box b = fb.boxTan()
    return Box.from_ptr(b)

def box_tan(Box x) -> Box:
    """unitary box tangent operation."""
    cdef fb.Box b = fb.boxTan(x.ptr)
    return Box.from_ptr(b)

def box_sqrt_op() -> Box:
    """nullary square root than operation."""
    cdef fb.Box b = fb.boxSqrt()
    return Box.from_ptr(b)

def box_sqrt(Box x) -> Box:
    """unitary box sqrt operation."""
    cdef fb.Box b = fb.boxSqrt(x.ptr)
    return Box.from_ptr(b)

def box_sin_op() -> Box:
    """nullary sine op than operation."""
    cdef fb.Box b = fb.boxSin()
    return Box.from_ptr(b)

def box_sin(Box x) -> Box:
    """unitary box sine operation."""
    cdef fb.Box b = fb.boxSin(x.ptr)
    return Box.from_ptr(b)

def box_rint_op() -> Box:
    """nullary round int operation."""
    cdef fb.Box b = fb.boxRint()
    return Box.from_ptr(b)

def box_rint(Box x) -> Box:
    """unitary box round int operation."""
    cdef fb.Box b = fb.boxRint(x.ptr)
    return Box.from_ptr(b)

def box_round_op() -> Box:
    """nullary round float operation."""
    cdef fb.Box b = fb.boxRound()
    return Box.from_ptr(b)

def box_round(Box x) -> Box:
    """unitary box round operation."""
    cdef fb.Box b = fb.boxRound(x.ptr)
    return Box.from_ptr(b)

def box_log_op() -> Box:
    """nullary log operation."""
    cdef fb.Box b = fb.boxLog()
    return Box.from_ptr(b)

def box_log(Box x) -> Box:
    """unitary box log operation."""
    cdef fb.Box b = fb.boxLog(x.ptr)
    return Box.from_ptr(b)

def box_log10_op() -> Box:
    """nullary log10 operation."""
    cdef fb.Box b = fb.boxLog10()
    return Box.from_ptr(b)

def box_log10(Box x) -> Box:
    """unitary box log10 operation."""
    cdef fb.Box b = fb.boxLog10(x.ptr)
    return Box.from_ptr(b)

def box_floor_op() -> Box:
    """nullary floor operation."""
    cdef fb.Box b = fb.boxFloor()
    return Box.from_ptr(b)

def box_floor(Box x) -> Box:
    """unitary box floor operation."""
    cdef fb.Box b = fb.boxFloor(x.ptr)
    return Box.from_ptr(b)

def box_exp_op() -> Box:
    """nullary exp operation."""
    cdef fb.Box b = fb.boxExp()
    return Box.from_ptr(b)

def box_exp(Box x) -> Box:
    """unitary box exp operation."""
    cdef fb.Box b = fb.boxExp(x.ptr)
    return Box.from_ptr(b)

def box_exp10_op() -> Box:
    """nullary exp10 operation."""
    cdef fb.Box b = fb.boxExp10()
    return Box.from_ptr(b)

def box_exp10(Box x) -> Box:
    """unitary box exp10 operation."""
    cdef fb.Box b = fb.boxExp10(x.ptr)
    return Box.from_ptr(b)

def box_cos_op() -> Box:
    """nullary cosine operation."""
    cdef fb.Box b = fb.boxCos()
    return Box.from_ptr(b)

def box_cos(Box x) -> Box:
    """unitary box cosine operation."""
    cdef fb.Box b = fb.boxCos(x.ptr)
    return Box.from_ptr(b)

def box_ceil_op() -> Box:
    """nullary ceiling operation."""
    cdef fb.Box b = fb.boxCeil()
    return Box.from_ptr(b)

def box_ceil(Box x) -> Box:
    """unitary box ceiling operation."""
    cdef fb.Box b = fb.boxCeil(x.ptr)
    return Box.from_ptr(b)

def box_atan_op() -> Box:
    """nullary arc tangent operation."""
    cdef fb.Box b = fb.boxAtan()
    return Box.from_ptr(b)

def box_atan(Box x) -> Box:
    """unitary box arctangent operation."""
    cdef fb.Box b = fb.boxAtan(x.ptr)
    return Box.from_ptr(b)

def box_asin_op() -> Box:
    """nullary arcsine operation."""
    cdef fb.Box b = fb.boxAsin()
    return Box.from_ptr(b)

def box_asin(Box x) -> Box:
    """unitary box arcsine operation."""
    cdef fb.Box b = fb.boxAsin(x.ptr)
    return Box.from_ptr(b)

def box_remainder_op() -> Box:
    """nullary remainder operation."""
    cdef fb.Box b = fb.boxRemainder()
    return Box.from_ptr(b)

def box_remainder(Box b1, Box b2) -> Box:
    """binary box remainder operation."""
    cdef fb.Box b = fb.boxRemainder(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_pow_op() -> Box:
    """nullary power operation."""
    cdef fb.Box b = fb.boxPow()
    return Box.from_ptr(b)

def box_pow(Box b1, Box b2) -> Box:
    """binary box power operation."""
    cdef fb.Box b = fb.boxPow(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_min_op() -> Box:
    """nullary minimum operation."""
    cdef fb.Box b = fb.boxMin()
    return Box.from_ptr(b)

def box_min(Box b1, Box b2) -> Box:
    """binary box minimum operation."""
    cdef fb.Box b = fb.boxMin(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_max_op() -> Box:
    """nullary maximum operation."""
    cdef fb.Box b = fb.boxMax()
    return Box.from_ptr(b)

def box_max(Box b1, Box b2) -> Box:
    """binary box maximum operation."""
    cdef fb.Box b = fb.boxMax(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_fmod_op() -> Box:
    """nullary fmod operation."""
    cdef fb.Box b = fb.boxFmod()
    return Box.from_ptr(b)

def box_fmod(Box b1, Box b2) -> Box:
    """binary box fmod operation."""
    cdef fb.Box b = fb.boxFmod(b1.ptr, b2.ptr)
    return Box.from_ptr(b)

def box_atan2_op() -> Box:
    """nullary arctangent2 operation."""
    cdef fb.Box b = fb.boxAtan2()
    return Box.from_ptr(b)

def box_atan2(Box b1, Box b2) -> Box:
    """binary box arctan2 operation."""
    cdef fb.Box b = fb.boxAtan2(b1.ptr, b2.ptr)
    return Box.from_ptr(b)


def box_button(str label) -> Box:
    """Create a button box.

    label - the label definition (see [2])

    returns the button box.
    """
    cdef fb.Box b = fb.boxButton(label.encode('utf8'))
    return Box.from_ptr(b)


def box_checkbox(str label) -> Box:
    """Create a checkbox box.

    label - the label definition (see [2])

    returns the checkbox box.
    """
    cdef fb.Box b = fb.boxCheckbox(label.encode('utf8'))
    return Box.from_ptr(b)


def box_vslider(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create a vertical slider box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression
    min - the min box, a constant numerical expression
    max - the max box, a constant numerical expression
    step - the step box, a constant numerical expression

    returns the vertical slider box.
    """
    cdef fb.Box b = fb.boxVSlider(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)

def box_hslider(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create an horizontal slider box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression
    min - the min box, a constant numerical expression
    max - the max box, a constant numerical expression
    step - the step box, a constant numerical expression

    returns the horizontal slider box.
    """
    cdef fb.Box b = fb.boxHSlider(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)

def box_numentry(str label, Box init, Box min, Box max, Box step) -> Box:
    """Create a num entry box.

    label - the label definition (see [2])
    init - the init box, a constant numerical expression
    min - the min box, a constant numerical expression
    max - the max box, a constant numerical expression
    step - the step box, a constant numerical expression

    returns the num entry box.
    """
    cdef fb.Box b = fb.boxNumEntry(label.encode('utf8'), init.ptr, min.ptr, max.ptr, step.ptr)
    return Box.from_ptr(b)


def box_vbargraph(str label, Box min, Box max) -> Box:
    """Create a vertical bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression
    max - the max box, a constant numerical expression
    x - the input box

    returns the vertical bargraph box.
    """
    cdef fb.Box b = fb.boxVBargraph(label.encode('utf8'), min.ptr, max.ptr)
    return Box.from_ptr(b)

def box_vbargraph2(str label, Box min, Box max, Box x) -> Box:
    """Create a vertical bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression
    max - the max box, a constant numerical expression
    x - the input box

    returns the vertical bargraph box.
    """
    cdef fb.Box b = fb.boxVBargraph(label.encode('utf8'), min.ptr, max.ptr, x.ptr)
    return Box.from_ptr(b)

def box_hbargraph(str label, Box min, Box max) -> Box:
    """Create a horizontal bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression
    max - the max box, a constant numerical expression
    x - the input box

    returns the horizontal bargraph box.
    """
    cdef fb.Box b = fb.boxHBargraph(label.encode('utf8'), min.ptr, max.ptr)
    return Box.from_ptr(b)

def box_hbargraph2(str label, Box min, Box max, Box x) -> Box:
    """Create a horizontal bargraph box.

    label - the label definition (see [2])
    min - the min box, a constant numerical expression
    max - the max box, a constant numerical expression
    x - the input box

    returns the horizontal bargraph box.
    """
    cdef fb.Box b = fb.boxHBargraph(label.encode('utf8'), min.ptr, max.ptr, x.ptr)
    return Box.from_ptr(b)


def box_vgroup(str label, Box group) -> Box:
    """Create a vertical group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the vertical group box.
    """
    cdef fb.Box b = fb.boxVGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)


def box_hgroup(str label, Box group) -> Box:
    """Create a horizontal group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the horizontal group box.
    """
    cdef fb.Box b = fb.boxHGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)

def box_tgroup(str label, Box group) -> Box:
    """Create a tab group box.

    label - the label definition (see [2])
    group - the group to be added

    returns the tab group box.
    """
    cdef fb.Box b = fb.boxTGroup(label.encode('utf8'), group.ptr)
    return Box.from_ptr(b)

def box_attach_op() -> Box:
    """Create an attach box.

    returns the attach box.
    """
    cdef fb.Box b = fb.boxAttach()
    return Box.from_ptr(b)


def box_attach(Box b1, Box b2) -> Box:
    """Create an attach box.

    The attach primitive takes two input boxes and produces one output box
    which is a copy of the first input. The role of attach is to force
    its second input boxes to be compiled with the first one.

    returns the attach box.
    """
    cdef fb.Box b = fb.boxAttach(b1.ptr, b2.ptr)
    return Box.from_ptr(b)


# cdef fb.Box box_prim2(fb.prim2 foo):
#     return fb.boxPrim2(foo)

def is_box_abstr(Box t) -> bool:
    """test if box is an abtraction."""
    return fb.isBoxAbstr(t.ptr)

def getparams_box_abstr(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxAbstr(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def getparams_box_access(Box t) -> dict:
    cdef fb.Box exp = NULL
    cdef fb.Box id = NULL
    if fb.isBoxAccess(t.ptr, exp, id):
        return dict(
            exp=Box.from_ptr(exp),
            id=Box.from_ptr(id),
        )
    else:
        return {}

def is_box_appl(Box t) -> bool:
    """test if box is an application."""
    return fb.isBoxAppl(t.ptr)

def getparams_box_appl(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxAppl(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def is_box_button(Box b) -> bool:
    """test if box is a button."""
    return fb.isBoxButton(b.ptr)

def getparams_box_button(Box b) -> dict:
    cdef fb.Box lbl = NULL
    if fb.isBoxButton(b.ptr, lbl):
        return dict(
            lbl=Box.from_ptr(lbl),
        )
    else:
        return {}

def is_box_case(Box b) -> bool:
    """test if box is a case."""
    return fb.isBoxCase(b.ptr)

def getparams_box_case(Box b) -> dict:
    cdef fb.Box rules = NULL
    if fb.isBoxCase(b.ptr, rules):
        return dict(
            rules=Box.from_ptr(rules),
        )
    else:
        return {}

def is_box_checkbox(Box b) -> bool:
    """test if box is a checkbox."""
    return fb.isBoxCheckbox(b.ptr)

def getparams_box_checkbox(Box b) -> dict:
    cdef fb.Box lbl = NULL
    if fb.isBoxCheckbox(b.ptr, lbl):
        return dict(
            lbl=Box.from_ptr(lbl),
        )
    else:
        return {}

def getparams_box_component(Box b) -> dict:
    cdef fb.Box filename = NULL
    if fb.isBoxComponent(b.ptr, filename):
        return dict(
            filename=Box.from_ptr(filename),
        )
    else:
        return {}

def is_box_cut(Box t) -> bool:
    """test if box is a cut."""
    return fb.isBoxCut(t.ptr)

def is_box_environment(Box b) -> bool:
    return fb.isBoxEnvironment(b.ptr)

def is_box_error(Box t) -> bool:
    """test if box is an error."""
    return fb.isBoxError(t.ptr)

def is_box_fconst(Box b) -> bool:
    """test if box is an fconst."""
    return fb.isBoxFConst(b.ptr)

def getparams_box_fconst(Box b) -> dict:
    cdef fb.Box type = NULL
    cdef fb.Box name = NULL
    cdef fb.Box file = NULL
    if fb.isBoxFConst(b.ptr, type, name, file):
        return dict(
            type=Box.from_ptr(type),
            name=Box.from_ptr(name),
            file=Box.from_ptr(file),
        )
    else:
        return {}

def is_box_ffun(Box b) -> bool:
    """test if box is an ffun."""
    return fb.isBoxFFun(b.ptr)

def getparams_box_ffun(Box b) -> dict:
    cdef fb.Box ff = NULL
    if fb.isBoxFFun(b.ptr, ff):
        return dict(
            ff=Box.from_ptr(ff),
        )
    else:
        return {}

def is_box_fvar(Box b) -> bool:
    """test if box is an fvar."""
    return fb.isBoxFVar(b.ptr)

def getparams_box_fvar(Box b) -> dict:
    cdef fb.Box type = NULL
    cdef fb.Box name = NULL
    cdef fb.Box file = NULL
    if fb.isBoxFVar(b.ptr, type, name, file):
        return dict(
            type=Box.from_ptr(type),
            name=Box.from_ptr(name),
            file=Box.from_ptr(file),
        )
    else:
        return {}

def is_box_hbargraph(Box b) -> bool:
    """test if box is a hbargraph."""
    return fb.isBoxHBargraph(b.ptr)

def getparams_box_hbargraph(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    if fb.isBoxHBargraph(b.ptr, lbl, min, max):
        return dict(
            lbl=Box.from_ptr(lbl),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
        )
    else:
        return {}

def is_box_hgroup(Box b) -> bool:
    """test if box is an horizontal group."""
    return fb.isBoxHGroup(b.ptr)

def getparams_box_hgroup(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box x = NULL
    if fb.isBoxHGroup(b.ptr, lbl, x):
        return dict(
            lbl=Box.from_ptr(lbl),
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_hslider(Box b) -> bool:
    """test if box is an horizontal slider."""
    return fb.isBoxHSlider(b.ptr)

def getparams_box_hslider(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box cur = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    cdef fb.Box step = NULL
    if fb.isBoxHSlider(b.ptr, lbl, cur, min, max, step):
        return dict(
            lbl=Box.from_ptr(lbl),
            cur=Box.from_ptr(cur),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
            step=Box.from_ptr(step),
        )
    else:
        return {}

def is_box_ident(Box t) -> bool:
    """test if box is an indentifier."""
    return fb.isBoxIdent(t.ptr)

def get_box_id(Box t) -> str | None:
    cdef const char** cstr = <const char**> malloc(1024 * sizeof(char*))
    if fb.isBoxIdent(t.ptr, cstr):
        return cstr[0].decode()


def getparams_box_inputs(Box t) -> dict:
    cdef fb.Box x = NULL
    if fb.isBoxInputs(t.ptr, x):
        return dict(
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_int(Box t) -> bool:
    """test if box is an int."""
    return fb.isBoxInt(t.ptr)

def getparams_box_int(Box t) -> dict:
    cdef int i = 0
    if fb.isBoxInt(t.ptr, &i):
        return dict(
            i=i,
        )
    else:
        return {}

def getparams_box_ipar(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxIPar(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_iprod(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxIProd(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_iseq(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxISeq(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_isum(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    cdef fb.Box z = NULL
    if fb.isBoxISum(t.ptr, x, y, z):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
            z=Box.from_ptr(z),
        )
    else:
        return {}

def getparams_box_library(Box b) -> dict:
    cdef fb.Box filename = NULL
    if fb.isBoxLibrary(b.ptr, filename):
        return dict(
            filename=Box.from_ptr(filename),
        )
    else:
        return {}

def getparams_box_merge(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxMerge(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def getparams_box_metadata(Box b) -> dict:
    cdef fb.Box exp = NULL
    cdef fb.Box mdlist = NULL
    if fb.isBoxMetadata(b.ptr, exp, mdlist):
        return dict(
            exp=Box.from_ptr(exp),
            mdlist=Box.from_ptr(mdlist),
        )
    else:
        return {}

def is_box_numentry(Box b) -> bool:
    """test if box is a numentry."""
    return fb.isBoxNumEntry(b.ptr)

def getparams_box_num_entry(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box cur = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    cdef fb.Box step = NULL
    if fb.isBoxNumEntry(b.ptr, lbl, cur, min, max, step):
        return dict(
            lbl=Box.from_ptr(lbl),
            cur=Box.from_ptr(cur),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
            step=Box.from_ptr(step),
        )
    else:
        return {}

def getparams_box_outputs(Box t) -> dict:
    cdef fb.Box x = NULL
    if fb.isBoxOutputs(t.ptr, x):
        return dict(
            x=Box.from_ptr(x),
        )
    else:
        return {}

def getparams_box_par(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxPar(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}




def is_box_prim0_(Box b) -> bool:
    cdef fb.prim0 p
    return fb.isBoxPrim0(b.ptr, &p)

def is_box_prim1_(Box b) -> bool:
    cdef fb.prim1 p
    return fb.isBoxPrim1(b.ptr, &p)

def is_box_prim2_(Box b) -> bool:
    cdef fb.prim2 p
    return fb.isBoxPrim2(b.ptr, &p)

def is_box_prim3_(Box b) -> bool:
    cdef fb.prim3 p
    return fb.isBoxPrim3(b.ptr, &p)

def is_box_prim4_(Box b) -> bool:
    cdef fb.prim4 p
    return fb.isBoxPrim4(b.ptr, &p)

def is_box_prim5_(Box b) -> bool:
    cdef fb.prim5 p
    return fb.isBoxPrim5(b.ptr, &p)


def is_box_prim0(Box b) -> bool:
    return fb.isBoxPrim0(b.ptr)

def is_box_prim1(Box b) -> bool:
    return fb.isBoxPrim1(b.ptr)

def is_box_prim2(Box b) -> bool:
    return fb.isBoxPrim2(b.ptr)

def is_box_prim3(Box b) -> bool:
    return fb.isBoxPrim3(b.ptr)

def is_box_prim4(Box b) -> bool:
    return fb.isBoxPrim4(b.ptr)

def is_box_prim5(Box b) -> bool:
    return fb.isBoxPrim5(b.ptr)


def is_box_real(Box t) -> bool:
    """test if box is a real or float."""
    return fb.isBoxReal(t.ptr)

def getparams_box_real(Box t) -> dict:
    cdef double r
    if fb.isBoxReal(t.ptr, &r):
        return dict(
            r=r,
        )
    else:
        return {}

def getparams_box_rec(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxRec(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def getparams_box_route(Box b) -> dict:
    cdef fb.Box n = NULL
    cdef fb.Box m = NULL
    cdef fb.Box r = NULL
    if fb.isBoxRoute(b.ptr, n, m, r):
        return dict(
            n=Box.from_ptr(n),
            m=Box.from_ptr(m),
            r=Box.from_ptr(r),
        )
    else:
        return {}

def getparams_box_seq(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxSeq(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def is_box_slot(Box t) -> bool:
    """test if box is a slot."""
    return fb.isBoxSlot(t.ptr)

def getparams_box_slot(Box t) -> dict:
    cdef int id = 0
    if fb.isBoxSlot(t.ptr, &id):
        return dict(
            id=id,
        )
    else:
        return {}

def is_box_soundfile(Box b) -> bool:
    """test if box is a soundfile."""
    return fb.isBoxSoundfile(b.ptr)

def getparams_box_soundfile(Box b) -> dict:
    cdef fb.Box label = NULL
    cdef fb.Box chan = NULL
    if fb.isBoxSoundfile(b.ptr, label, chan):
        return dict(
            label=Box.from_ptr(label),
            chan=Box.from_ptr(chan),
        )
    else:
        return {}

def getparams_box_split(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxSplit(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}

def is_box_symbolic(Box t) -> bool:
    """test if box is symbolic."""
    return fb.isBoxSymbolic(t.ptr)

def getparams_box_symbolic(Box t) -> dict:
    cdef fb.Box slot = NULL
    cdef fb.Box body = NULL
    if fb.isBoxSymbolic(t.ptr, slot, body):
        return dict(
            slot=Box.from_ptr(slot),
            body=Box.from_ptr(body),
        )
    else:
        return {}

def is_box_tgroup(Box b) -> bool:
    """test if box is a tab group."""
    return fb.isBoxTGroup(b.ptr)

def getparams_box_tgroup(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box x = NULL
    if fb.isBoxTGroup(b.ptr, lbl, x):
        return dict(
            lbl=Box.from_ptr(lbl),
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_vbargraph(Box b) -> bool:
    """test if box is a vertical bargraph."""
    return fb.isBoxVBargraph(b.ptr)

def getparams_box_vbargraph(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    if fb.isBoxVBargraph(b.ptr, lbl, min, max):
        return dict(
            lbl=Box.from_ptr(lbl),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
        )
    else:
        return {}

def is_box_vgroup(Box b) -> bool:
    """test if box is a vertical group."""
    return fb.isBoxVGroup(b.ptr)

def getparams_box_vgroup(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box x = NULL
    if fb.isBoxVGroup(b.ptr, lbl, x):
        return dict(
            lbl=Box.from_ptr(lbl),
            x=Box.from_ptr(x),
        )
    else:
        return {}

def is_box_vslider(Box b) -> bool:
    return fb.isBoxVSlider(b.ptr)

def getparams_box_vslider(Box b) -> dict:
    cdef fb.Box lbl = NULL
    cdef fb.Box cur = NULL
    cdef fb.Box min = NULL
    cdef fb.Box max = NULL
    cdef fb.Box step = NULL
    if fb.isBoxVSlider(b.ptr, lbl, cur, min, max, step):
        return dict(
            lbl=Box.from_ptr(lbl),
            cur=Box.from_ptr(cur),
            min=Box.from_ptr(min),
            max=Box.from_ptr(max),
            step=Box.from_ptr(step),
        )
    else:
        return {}

def is_box_waveform(Box b) -> bool:
    """test if box is a waveform."""
    return fb.isBoxWaveform(b.ptr)

def is_box_wire(Box t) -> bool:
    """test if box is a wire."""
    return fb.isBoxWire(t.ptr)

def getparams_box_with_local_def(Box t) -> dict:
    cdef fb.Box body = NULL
    cdef fb.Box ldef = NULL
    if fb.isBoxWithLocalDef(t.ptr, body, ldef):
        return dict(
            body=Box.from_ptr(body),
            ldef=Box.from_ptr(ldef),
        )
    else:
        return {}


def dsp_to_boxes(str name_app, str dsp_content, *args) -> Box:
    """Compile a DSP source code as a string in a flattened box

    name_app - the name of the Faust program
    dsp_content - the Faust program as a string
    argc - the number of parameters in argv array
    argv - the array of parameters
    inputs - the place to return the number of inputs of the resulting box
    outputs - the place to return the number of outputs of the resulting box
    error_msg - the error string to be filled

    returns a flattened box on success, otherwise a null pointer.
    """
    cdef ParamArray params = ParamArray(args)
    cdef int inputs, outputs
    cdef string error_msg
    error_msg.reserve(4096)
    cdef fb.Box b = fb.DSPToBoxes(
        name_app.encode('utf8'),
        dsp_content.encode('utf8'),
        params.argc,
        params.argv,
        &inputs,
        &outputs,
        error_msg,
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return Box.from_ptr(b)


def get_box_type(Box b) -> tuple[int, int] | None:
    """Return the number of inputs and outputs of a box

    box - the box we want to know the number of inputs and outputs
    inputs - the place to return the number of inputs
    outputs - the place to return the number of outputs

    returns true if type is defined, false if undefined.
    """
    cdef int inputs, outputs
    if fb.getBoxType(b.ptr, &inputs, &outputs):
        return (inputs, outputs)

def boxes_to_signals(Box b) -> SignalVector | None:
    """Compile a box expression in a list of signals in normal form
    (see simplifyToNormalForm in libfaust-signal.h)

    box - the box expression
    error_msg - the error string to be filled

    returns a list of signals in normal form on success, otherwise an empty list.
    """
    cdef string error_msg
    error_msg.reserve(4096)
    cdef fs.tvec vec = fb.boxesToSignals(b.ptr, error_msg)
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return SignalVector.from_ptr(vec)


def create_source_from_boxes(str name_app, Box box, str lang, *args) -> str:
    """Create source code in a target language from a box expression.

    name_app - the name of the Faust program
    box - the box expression
    lang - the target source code's language which can be one of 
        'c', 'cpp', 'cmajor', 'codebox', 'csharp', 'dlang', 'fir', 
        'interp', 'java', 'jax','jsfx', 'julia', 'ocpp', 'rust' or 'wast'
        (depending of which of the corresponding backends are compiled in libfaust)
    argc - the number of parameters in argv array
    argv - the array of parameters
    error_msg - the error string to be filled

    returns a string of source code on success, setting error_msg on error.
    """
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    cdef string code = fb.createSourceFromBoxes(
        name_app.encode('utf8'),
        box.ptr,
        lang.encode('utf8'),
        params.argc,
        params.argv, 
        error_msg)
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return code.decode()

