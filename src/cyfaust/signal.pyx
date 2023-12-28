# distutils: language = c++

from libcpp.string cimport string
# from libcpp.vector cimport vector

from . cimport faust_signal as fs

from .common cimport ParamArray
from .common import ParamArray


def sig_or_float(var):
    if isinstance(var, float):
        return Signal.from_real(var)
    elif isinstance(var, Signal):
        assert is_sig_real(var), "signal is not a float Signal"
        return var
    raise TypeError("argument must be an float or a sigReal")

def sig_or_int(var):
    if isinstance(var, int):
        return Signal.from_int(var)
    elif isinstance(var, Signal):
        assert is_sig_int(var), "signal is not an int Signal"
        return var
    raise TypeError("argument must be an int")


class signal_context:
    def __enter__(self):
        # Create global compilation context, has to be done first.
        fs.createLibContext()
    def __exit__(self, type, value, traceback):
        # Destroy global compilation context, has to be done last.
        fs.destroyLibContext()


cdef class SignalVector:
    """wraps tvec: a std::vector<CTree*>"""
    # cdef vector[fs.Signal] ptr
    # cdef bint ptr_owner

    def __cinit__(self):
        self.ptr_owner = False

    def __iter__(self):
        for i in self.ptr:
            yield Signal.from_ptr(i)

    @staticmethod
    cdef SignalVector from_ptr(fs.tvec ptr):
        """Wrap a fs.tvec instance."""
        cdef SignalVector sv = SignalVector.__new__(SignalVector)
        sv.ptr = ptr
        return sv

    cdef add_ptr(self, fs.Signal sig):
        self.ptr.push_back(sig)

    def add(self, Signal sig):
        self.ptr.push_back(sig.ptr)

    def create_source(self, name_app: str, lang, *args) -> str:
        """Create source code in a target language from a signal expression."""
        return create_source_from_signals(name_app, self, lang, *args)

    def simplify_to_normal_form(self) -> SignalVector:
        """Simplify a signal list to its normal form.

        returns the signal vector in normal form.
        """
        return simplify_to_normal_form2(self)



cdef class Interval:
    """wraps fs.Interval struct/class"""
    cdef fs.Interval *ptr

    def __dealloc__(self):
        if self.ptr:
            del self.ptr

    def __cinit__(self, double lo, double hi, int lsb):
        self.ptr = new fs.Interval(lo, hi, lsb)

    @staticmethod
    cdef Interval from_ptr(fs.Interval* ptr):
        """Wrap Interval from pointer"""
        cdef Interval ival = Interval.__new__(Interval)
        ival.ptr = ptr
        return ival

    @property
    def low(self) -> float:
        return self.ptr.fLo

    @property
    def high(self) -> float:
        return self.ptr.fHi

    @property
    def lsb(self) -> float:
        return self.ptr.fLSB


cdef class Signal:
    """faust Signal wrapper.
    """
    # cdef fs.Signal ptr

    def __cinit__(self):
        self.ptr = NULL

    @staticmethod
    cdef Signal from_ptr(fs.Signal ptr, bint ptr_owner=False):
        """Wrap Signal from pointer"""
        cdef Signal sig = Signal.__new__(Signal)
        sig.ptr = ptr
        return sig

    @staticmethod
    def from_input(int idx) -> Signal:
        """Create signal from int"""
        return sig_input(idx)

    @staticmethod
    def from_int(int value) -> Signal:
        """Create signal from int"""
        return sig_int(value)

    @staticmethod
    def from_float(float value) -> Signal:
        """Create signal from float"""
        return sig_real(value)

    from_real = from_float

    @staticmethod
    def from_soundfile(str label) -> Signal:
        """Create signal from soundfile."""
        return sig_soundfile(label)

    @staticmethod
    def from_button(str label) -> Signal:
        """Create a button signal."""
        return sig_button(label)

    @staticmethod
    def from_checkbox(str label) -> Signal:
        """Create a checkbox signal."""
        return sig_checkbox(label)

    @staticmethod
    def from_vslider(str label, init: float | Signal, min: float | Signal, 
                                max: float | Signal, step: float | Signal) -> Signal:
        """Create a vertical slider signal."""
        _init = sig_or_float(init)
        _min = sig_or_float(min)
        _max = sig_or_float(max)
        _step = sig_or_float(step)
        return sig_vslider(label, _init, _min, _max, _step)

    @staticmethod
    def from_hslider(str label, init: float | Signal, min: float | Signal, 
                                max: float | Signal, step: float | Signal) -> Signal:
        """Create a horizontal slider signal."""
        _init = sig_or_float(init)
        _min = sig_or_float(min)
        _max = sig_or_float(max)
        _step = sig_or_float(step)
        return sig_hslider(label, _init, _min, _max, _step)

    @staticmethod
    def from_numentry(str label, init: float | Signal, min: float | Signal, 
                                max: float | Signal, step: float | Signal) -> Signal:
        """Create a num entry signal."""
        _init = sig_or_float(init)
        _min = sig_or_float(min)
        _max = sig_or_float(max)
        _step = sig_or_float(step)
        return sig_numentry(label, _init, _min, _max, _step)

    @staticmethod
    def from_read_only_table(n: int | Signal, Signal init, ridx: int | Signal):
        """Create a read-only table.

        n - the table size, a constant numerical expression (see [1])
        init - the table content
        ridx - the read index (an int between 0 and n-1)
     
        returns the table signal.
        """
        _n = sig_or_int(n)
        _ridx = sig_or_int(ridx)
        return sig_readonly_table(_n, init, _ridx)

    @staticmethod
    def from_write_read_table(int n, Signal init, int widx, Signal wsig, int ridx):
        """Create a read-write-only table.

        n - the table size, a constant numerical expression (see [1])
        init - the table content
        widx - the write index (an integer between 0 and n-1)
        wsig - the input of the table
        ridx - the read index (an int between 0 and n-1)
     
        returns the table signal.
        """
        _n = sig_or_int(n)
        _widx = sig_or_int(widx)
        _ridx = sig_or_int(ridx)
        return sig_write_read_table(_n, init, _widx, wsig, _ridx)


    def create_source(self, name_app: str, lang, *args) -> str:
        """Create source code in a target language from a signal expression."""
        return create_source_from_signals(name_app, lang, *args)

    def simplify_to_normal_form(self) -> Signal:
        """Simplify a signal to its normal form."""
        cdef fs.Signal s = fs.simplifyToNormalForm(self.ptr)
        return Signal.from_ptr(s)

    def to_string(self, shared: bool = False, max_size: int = 256) -> str:
        """retur this signal printed as a string."""
        return print_signal(self, shared, max_size)

    def print(self, shared: bool = False, max_size: int = 256):
        """Print this signal."""
        print(print_signal(self, shared, max_size))

    def ffname(self) -> str:
        """Return the name parameter of a foreign function."""
        return ffname(self)

    def ffarity(self) -> int:
        """Return the arity of a foreign function."""
        return ffarity(self)

    # def get_interval(self) -> Interval:
    #     """Get the signal interval."""
    #     cdef fs.Interval *ival = <fs.Interval*>fs.getSigInterval(self.ptr)
    #     return Interval.from_ptr(ival)

    # def set_interval(self, Interval iv):
    #     """Set the signal interval."""
    #     fs.setSigInterval(self.ptr, iv.ptr)

    def attach(self, Signal other) -> Signal:
        """Create an attached signal from another signal
        
        The attach primitive takes two input signals and produces 
        one output signal which is a copy of the first input.

        The role of attach is to force the other input signal to be 
        compiled with this one.
        """
        return sig_attach(self, other)

    def vbargraph(self, str label, min: float | Signal, max: float | Signal) -> Signal:
        """Create a vertical bargraph signal from this signal"""
        _min = sig_or_float(min)
        _max = sig_or_float(max)
        return sig_vbargraph(label, _min, _max, self)

    def hbargraph(self, str label, min: float | Signal, max: float | Signal) -> Signal:
        """Create a horizontal bargraph signal from this signal"""
        _min = sig_or_float(min)
        _max = sig_or_float(max)
        return sig_hbargraph(label, _min, _max, self)

    def int_cast(self) -> Signal:
        """Create a casted signal.

        s - the signal to be casted in integer

        returns the casted signal.
        """
        return sig_int_cast(self)


    def float_cast(self) -> Signal:
        """Create a casted signal.

        s - the signal to be casted as float/double value (depends of -single or -double compilation parameter)

        returns the casted signal.
        """
        return sig_float_cast(self)


    def select2(self, Signal s1, Signal s2) -> Signal:
        """Create a selector between two signals.

        selector - when 0 at time t returns s1[t], otherwise returns s2[t]
        (selector is automatically wrapped with sigIntCast)
        s1 - first signal to be selected
        s2 - second signal to be selected

        returns the selected signal depending of the selector value at each time t.
        """
        return sig_select2(self, s1, s2)


    def select3(self, Signal s1, Signal s2, Signal s3) -> Signal:
        """Create a selector between three signals.

        selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t], otherwise returns s3[t]
        (selector is automatically wrapped with sigIntCast)
        s1 - first signal to be selected
        s2 - second signal to be selected
        s3 - third signal to be selected

        returns the selected signal depending of the selector value at each time t.
        """
        return sig_select3(self, s1, s2, s3)


    def recursion(self) -> Signal:
        """Create a recursive signal. 

        Use sigSelf() to refer to the recursive signal inside 
        the sigRecursion expression.
        
        s - the signal to recurse on.
        
        returns the signal with a recursion.
        """
        return sig_recursion(self)


    def self_rec(self) -> Signal:
        """Create a recursive signal inside the sigRecursion expression.

        returns the recursive signal.
        """
        return sig_self()

    def self_n(self, int id) -> Signal:
        """Create a recursive signal inside the sigRecursionN expression.

        id - the recursive signal index (starting from 0, up to the number of outputs signals in the recursive block)

        returns the recursive signal.
        """
        return sig_self_n(id)

    def recursion_n(self, SignalVector rf) -> SignalVector:
        """Create a recursive block of signals. 

        Use sigSelfN() to refer to the recursive signal inside 
        the sigRecursionN expression.

        rf - the list of signals to recurse on.

        returns the list of signals with recursions.
        """
        return sig_self_n(rf)


    def __add__(self, Signal other) -> Signal:
        """Add this signal to another."""
        return sig_add(self, other)

    def __radd__(self, Signal other) -> Signal:
        """Reverse add this signal to another."""
        return sig_add(self, other)

    def __sub__(self, Signal other) -> Signal:
        """Subtract this box from another."""
        return sig_sub(self, other)

    def __rsub__(self, Signal other) -> Signal:
        """Subtract this box from another."""
        return sig_sub(self, other)

    def __mul__(self, Signal other) -> Signal:
        """Multiply this box with another."""
        return sig_mul(self, other)

    def __rmul__(self, Signal other) -> Signal:
        """Reverse multiply this box with another."""
        return sig_mul(self, other)

    def __div__(self, Signal other) -> Signal:
        """Divide this box with another."""
        return sig_div(self, other)

    def __rdiv__(self, Signal other) -> Signal:
        """Reverse divide this box with another."""
        return sig_div(self, other)

    def __eq__(self, Signal other):
        """Compare for equality with another signal."""
        return sig_eq(self, other)

    def __ne__(self, Signal other):
        """Assert this box is not equal with another signal."""
        return sig_ne(self, other)

    def __gt__(self, Signal other):
        """Is this box greater than another signal."""
        return sig_gt(self, other)

    def __ge__(self, Signal other):
        """Is this box greater than or equal from another signal."""
        return sig_ge(self, other)

    def __lt__(self, Signal other):
        """Is this box lesser than another signal."""
        return sig_lt(self, other)

    def __le__(self, Signal other):
        """Is this box lesser than or equal from another signal."""
        return sig_le(self, other)

    def __and__(self, Signal other):
        """logical and with another signal."""
        return sig_and(self, other)

    def __or__(self, Signal other):
        """logical or with another signal."""
        return sig_or(self, other)

    def __xor__(self, Signal other):
        """logical xor with another signal."""
        return sig_xor(self, other)

    # TODO: check sigRem = modulo if this is correct
    def __mod__(self, Signal other):
        """modulo of other Signal"""
        return sig_rem(self, other)

    def __lshift__(self, Signal other):
        """bitwise left-shift"""
        return sig_leftshift(self, other)

    def __rshift__(self, Signal other):
        """bitwise right-shift"""
        return sig_lrightshift(self, other)

    # nullary funcs

    def abs(self) -> Signal:
        return sig_abs(self)

    def acos(self) -> Signal:
        return sig_acos(self)

    def tan(self) -> Signal:
        return sig_tan(self)

    def sqrt(self) -> Signal:
        return sig_sqrt(self)

    def sin(self) -> Signal:
        return sig_sin(self)

    def rint(self) -> Signal:
        return sig_rint(self)

    def log(self) -> Signal:
        return sig_log(self)

    def log10(self) -> Signal:
        return sig_log10(self)

    def floor(self) -> Signal:
        return sig_floor(self)

    def exp(self) -> Signal:
        return sig_exp(self)

    def exp10(self) -> Signal:
        return sig_exp10(self)

    def cos(self) -> Signal:
        return sig_cos(self)

    def ceil(self) -> Signal:
        return sig_ceil(self)

    def atan(self) -> Signal:
        return sig_atan(self)

    def asin(self) -> Signal:
        return sig_asin(self)


    # binary funcs

    def delay(self, d: Signal | int) -> Signal:
        _d = sig_or_int(d)
        return sig_delay(self, _d)

    def remainder(self, Signal y) -> Signal:
        return sig_remainder(self, y)

    def pow(self, Signal y) -> Signal:
        return sig_pow(self, y)

    def min(self, Signal y) -> Signal:
        return sig_min(self, y)

    def max(self, Signal y) -> Signal:
        return sig_max(self, y)

    def fmod(self, Signal y) -> Signal:
        return sig_fmod(self, y)



    # boolean funcs ---------------------


    def is_int(self) -> bool:
        cdef int i
        return fs.isSigInt(self.ptr, &i)

    def is_float(self) -> bool:
        cdef double f
        return fs.isSigReal(self.ptr, &f)

    def is_input(self) -> bool:
        cdef int i
        return fs.isSigInput(self.ptr, &i)

    def is_output(self) -> bool:
        cdef int i
        cdef fs.Signal t0 = NULL
        return fs.isSigOutput(self.ptr, &i, t0)

    def is_delay1(self) -> bool:
        cdef fs.Signal t0 = NULL
        return fs.isSigDelay1(self.ptr, t0)

    def is_delay(self) -> bool:
        cdef fs.Signal t0 = NULL
        cdef fs.Signal t1 = NULL
        return fs.isSigDelay(self.ptr, t0, t1)

    def is_prefix(self) -> bool:
        cdef fs.Signal t0 = NULL
        cdef fs.Signal t1 = NULL
        return fs.isSigPrefix(self.ptr, t0, t1)

    def is_read_table(self) -> bool:
        cdef fs.Signal t = NULL
        cdef fs.Signal i = NULL
        return fs.isSigRDTbl(self.ptr, t, t)

    def is_write_table(self) -> bool:
        cdef fs.Signal id = NULL
        cdef fs.Signal t = NULL
        cdef fs.Signal i = NULL
        cdef fs.Signal s = NULL
        return fs.isSigWRTbl(self.ptr, id, t, i, s)

    def is_gen(self) -> bool:
        cdef fs.Signal x = NULL
        return fs.isSigGen(self.ptr, x)

    def is_doc_constant_tbl(self) -> bool:
        cdef fs.Signal n = NULL
        cdef fs.Signal sig = NULL
        return fs.isSigDocConstantTbl(self.ptr, n, sig)

    def is_doc_write_tbl(self) -> bool:
        cdef fs.Signal n = NULL
        cdef fs.Signal sig = NULL
        cdef fs.Signal widx = NULL
        cdef fs.Signal wsig = NULL
        return fs.isSigDocWriteTbl(self.ptr, n, sig, widx, wsig)

    def is_doc_access_tbl(self) -> bool:
        cdef fs.Signal tbl = NULL
        cdef fs.Signal ridx = NULL
        return fs.isSigDocAccessTbl(self.ptr, tbl, ridx)

    def is_select2(self) -> bool:
        cdef fs.Signal selector = NULL
        cdef fs.Signal s1 = NULL
        cdef fs.Signal s2 = NULL
        return fs.isSigSelect2(self.ptr, selector, s1, s2)

    def is_assert_bounds(self) -> bool:
        cdef fs.Signal s1 = NULL
        cdef fs.Signal s2 = NULL
        cdef fs.Signal s3 = NULL
        return fs.isSigAssertBounds(self.ptr, s1, s2, s3)

    def is_highest(self) -> bool:
        cdef fs.Signal s = NULL
        return fs.isSigHighest(self.ptr, s)

    def is_lowest(self) -> bool:
        cdef fs.Signal s = NULL
        return fs.isSigLowest(self.ptr, s)

    def is_bin_op(self) -> bool:
        cdef int op = 0
        cdef fs.Signal x = NULL
        cdef fs.Signal y = NULL
        return fs.isSigBinOp(self.ptr, &op, x, y)

    def is_ffun(self) -> bool:
        cdef fs.Signal ff = NULL
        cdef fs.Signal largs = NULL
        return fs.isSigFFun(self.ptr, ff, largs)

    def is_fconst(self) -> bool:
        cdef fs.Signal type = NULL
        cdef fs.Signal name = NULL
        cdef fs.Signal file = NULL
        return fs.isSigFConst(self.ptr, type, name, file)

    def is_fvar(self) -> bool:
        cdef fs.Signal type = NULL
        cdef fs.Signal name = NULL
        cdef fs.Signal file = NULL
        return fs.isSigFVar(self.ptr, type, name, file)

    def is_proj(self) -> bool:
        cdef int i = 0
        cdef fs.Signal rgroup = NULL
        return fs.isProj(self.ptr, &i, rgroup)

    def is_rec(self) -> bool:
        cdef fs.Signal var = NULL
        cdef fs.Signal body = NULL
        return fs.isRec(self.ptr, var, body)

    def is_int_cast(self) -> bool:
        cdef fs.Signal x = NULL
        return fs.isSigIntCast(self.ptr, x)

    def is_float_cast(self) -> bool:
        cdef fs.Signal x = NULL
        return fs.isSigFloatCast(self.ptr, x)

    def is_button(self) -> bool:
        cdef fs.Signal lbl = NULL
        return fs.isSigButton(self.ptr, lbl)

    def is_checkbox(self) -> bool:
        cdef fs.Signal lbl = NULL
        return fs.isSigCheckbox(self.ptr, lbl)

    def is_waveform(self) -> bool:
        return fs.isSigWaveform(self.ptr)

    def is_hslider(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal init = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal step = NULL
        return fs.isSigHSlider(self.ptr, lbl, init, min, max, step)

    def is_vslider(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal init = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal step = NULL
        return fs.isSigVSlider(self.ptr, lbl, init, min, max, step)

    def is_num_entry(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal init = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal step = NULL
        return fs.isSigNumEntry(self.ptr, lbl, init, min, max, step)

    def is_hbargraph(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal x = NULL
        return fs.isSigHBargraph(self.ptr, lbl, min, max, x)

    def is_vbargraph(self) -> bool:
        cdef fs.Signal lbl = NULL
        cdef fs.Signal min = NULL
        cdef fs.Signal max = NULL
        cdef fs.Signal x = NULL
        return fs.isSigVBargraph(self.ptr, lbl, min, max, x)

    def is_attach(self) -> bool:
        cdef fs.Signal s0 = NULL
        cdef fs.Signal s1 = NULL
        return fs.isSigAttach(self.ptr, s0, s1)

    def is_enable(self) -> bool:
        cdef fs.Signal s0 = NULL
        cdef fs.Signal s1 = NULL
        return fs.isSigEnable(self.ptr, s0, s1)

    def is_control(self) -> bool:
        cdef fs.Signal s0 = NULL
        cdef fs.Signal s1 = NULL
        return fs.isSigControl(self.ptr, s0, s1)

    def is_soundfile(self) -> bool:
        cdef fs.Signal label = NULL
        return fs.isSigSoundfile(self.ptr, label)

    def is_soundfile_length(self) -> bool:
        cdef fs.Signal sf = NULL
        cdef fs.Signal part = NULL
        return fs.isSigSoundfileLength(self.ptr, sf, part)

    def is_soundfile_rate(self) -> bool:
        cdef fs.Signal sf = NULL
        cdef fs.Signal part = NULL
        return fs.isSigSoundfileLength(self.ptr, sf, part)

    def is_soundfile_buffer(self) -> bool:
        cdef fs.Signal sf = NULL
        cdef fs.Signal chan = NULL
        cdef fs.Signal part = NULL
        cdef fs.Signal ridx = NULL
        return fs.isSigSoundfileBuffer(self.ptr, sf, chan, part, ridx)




def ffname(Signal s) -> str:
    """Return the name parameter of a foreign function.

    s - the signal
    returns the name
    """
    return fs.ffname(s.ptr).decode()


def ffarity(Signal s) -> int:
    """Return the arity of a foreign function.

    s - the signal
    returns the name
    """
    return fs.ffarity(s.ptr)


def print_signal(Signal sig, bint shared, int max_size) -> str:
    """Print the signal.

    sig - the signal to be printed
    shared - whether the identical sub signals are printed as identifiers
    max_size - the maximum number of characters to be printed (possibly needed for big expressions in non shared mode)

    returns the printed signal as a string
    """
    return fs.printSignal(sig.ptr, shared, max_size).decode()

def create_lib_context():
    """Create global compilation context, has to be done first.
    """
    fs.createLibContext()

def destroy_lib_context():
    """Destroy global compilation context, has to be done last.
    """
    fs.destroyLibContext()

# def get_sig_interval(Signal s) -> Interval:
#     """Get the signal interval.

#     s - the signal

#     returns the signal interval
#     """
#     cdef fs.Interval ival = fs.getSigInterval(s.ptr)
#     return Interval.from_ptr(ival)

# def set_sig_interval(Signal s, Interval inter):
#     """Set the signal interval.

#     s - the signal

#     inter - the signal interval
#     """
#     fs.setSigInterval(s.ptr, inter.ptr)

def is_nil(Signal s) -> bool:
    """Check if a signal is nil.

    s - the signal

    returns true if the signal is nil, otherwise false.
    """
    return fs.isNil(s.ptr)


def tree2str(Signal s):
    """Convert a signal (such as the label of a UI) to a string.

    s - the signal to convert

    returns a string representation of a signal.
    """
    return fs.tree2str(s.ptr).decode()


# cdef void* getUserData(fs.Signal s):
#     """Return the xtended type of a signal.

#     s - the signal whose xtended type to return

#     returns a pointer to xtended type if it exists, otherwise nullptr.
#     """
#     return <void*>fs.getUserData(s)


def xtended_arity(Signal s) -> int:
    """Return the arity of the xtended signal.

    s - the xtended signal

    returns the arity of the xtended signal.
    """
    return fs.xtendedArity(s.ptr)


def xtended_name(Signal s):
    """Return the name of the xtended signal.

    s - the xtended signal

    returns the name of the xtended signal.
    """
    return fs.xtendedName(s.ptr).decode()


def sig_int(int n) -> Signal:
    """Constant integer : for all t, x(t) = n.

    n - the integer

    returns the integer signal.
    """
    cdef fs.Signal s = fs.sigInt(n)
    return Signal.from_ptr(s)


def sig_real(float n) -> Signal:
    """Constant real : for all t, x(t) = n.

    n - the float/double value (depends of -single or -double compilation parameter)

    returns the float/double signal.
    """
    cdef fs.Signal s = fs.sigReal(n)
    return Signal.from_ptr(s)


def sig_input(int idx) -> Signal:
    """
    Create an input.

    idx - the input index

    returns the input signal.
    """
    cdef fs.Signal s = fs.sigInput(idx)
    return Signal.from_ptr(s)


def sig_delay(Signal s, Signal d) -> Signal:
    """
    Create a delayed signal.

    s - the signal to be delayed
    d - the delay signal that doesn't have to be fixed but must be bounded and cannot be negative

    returns the delayed signal.
    """
    cdef fs.Signal _s = fs.sigDelay(s.ptr, d.ptr)
    return Signal.from_ptr(_s)


def sig_delay1(Signal s) -> Signal:
    """Create a one sample delayed signal.

    s - the signal to be delayed

    returns the delayed signal.
    """
    cdef fs.Signal _s = fs.sigDelay1(s.ptr)
    return Signal.from_ptr(_s)


def sig_int_cast(Signal s) -> Signal:
    """Create a casted signal.

    s - the signal to be casted in integer

    returns the casted signal.
    """
    cdef fs.Signal _s = fs.sigIntCast(s.ptr)
    return Signal.from_ptr(_s)


def sig_float_cast(Signal s) -> Signal:
    """Create a casted signal.

    s - the signal to be casted as float/double value (depends of -single or -double compilation parameter)

    returns the casted signal.
    """
    cdef fs.Signal _s = fs.sigFloatCast(s.ptr)
    return Signal.from_ptr(_s)


def sig_readonly_table(Signal n, Signal init, Signal ridx) -> Signal:
    """Create a read only table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    ridx - the read index (an int between 0 and n-1)

    returns the table signal.
    """
    cdef fs.Signal s = fs.sigReadOnlyTable(n.ptr, init.ptr, ridx.ptr)
    return Signal.from_ptr(s)


def sig_write_read_table(Signal n, Signal init, Signal widx, Signal wsig, Signal ridx) -> Signal:
    """Create a read/write table.

    n - the table size, a constant numerical expression (see [1])
    init - the table content
    widx - the write index (an integer between 0 and n-1)
    wsig - the input of the table
    ridx - the read index (an integer between 0 and n-1)

    returns the table signal.
    """
    cdef fs.Signal s = fs.sigWriteReadTable(
        n.ptr, init.ptr, widx.ptr, wsig.ptr, ridx.ptr)
    return Signal.from_ptr(s)


def sig_waveform_int(int[:] view not None) -> Signal:
    """Create a waveform from a memoryview of ints

    view - memorview of ints

    returns the waveform signal.
    """
    cdef size_t i, n
    cdef fs.tvec wfv
    n = view.shape[0]
    for i in range(n):
        wfv.push_back(fs.sigInt(view[i]))
    cdef fs.Signal wf = fs.sigWaveform(wfv)
    return Signal.from_ptr(wf)

def sig_waveform_float(float[:] view not None) -> Signal:
    """Create a waveform from a memoryview of floats

    view - memorview of floats

    returns the waveform signal.
    """
    cdef size_t i, n
    cdef fs.tvec wfv
    n = view.shape[0]
    for i in range(n):
        wfv.push_back(fs.sigReal(view[i]))
    cdef fs.Signal wf = fs.sigWaveform(wfv)
    return Signal.from_ptr(wf)


def sig_soundfile(*paths) -> Signal:
    """Create a soundfile block.

    label - of form "label[url:{'path1''path2''path3'}]" 
            to describe a list of soundfiles

    returns the soundfile block.
    """
    ps = "".join(repr(p) for p in paths)
    label = f"label[url:{ps}]"
    cdef fs.Signal s = fs.sigSoundfile(label.encode('utf8'))
    return Signal.from_ptr(s)

def sig_soundfile_length(Signal sf, Signal part) -> Signal:
    """Create the length signal of a given soundfile in frames.

    sf - the soundfile
    part - in the [0..255] range to select a given sound number, 
           a constant numerical expression (see [1])

    returns the soundfile length signal.
    """
    cdef fs.Signal s = fs.sigSoundfileLength(sf.ptr, part.ptr)
    return Signal.from_ptr(s)

def sig_soundfile_rate(Signal sf, Signal part) -> Signal:
    """Create the rate signal of a given soundfile in Hz.

    sf - the soundfile
    part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])

    returns the soundfile rate signal.
    """
    cdef fs.Signal s = fs.sigSoundfileRate(sf.ptr, part.ptr)
    return Signal.from_ptr(s)


def sig_soundfile_buffer(Signal sf, Signal chan, Signal part, Signal ridx) -> Signal:
    """Create the buffer signal of a given soundfile.

    sf - the soundfile
    chan - an integer to select a given channel, a constant numerical expression (see [1])
    part - in the [0..255] range to select a given sound number, a constant numerical expression (see [1])
    ridx - the read index (an integer between 0 and the selected sound length)

    returns the soundfile buffer signal.
    """
    cdef fs.Signal s = fs.sigSoundfileBuffer(sf.ptr, chan.ptr, part.ptr, ridx.ptr)
    return Signal.from_ptr(s)

def sig_select2(Signal selector, Signal s1, Signal s2) -> Signal:
    """Create a selector between two signals.

    selector - when 0 at time t returns s1[t], otherwise returns s2[t]
    (selector is automatically wrapped with sigIntCast)
    s1 - first signal to be selected
    s2 - second signal to be selected

    returns the selected signal depending of the selector value at each time t.
    """
    cdef fs.Signal s = fs.sigSelect2(selector.ptr, s1.ptr, s2.ptr)
    return Signal.from_ptr(s)


def sig_select3(Signal selector, Signal s1, Signal s2, Signal s3) -> Signal:
    """Create a selector between three signals.

    selector - when 0 at time t returns s1[t], when 1 at time t returns s2[t], otherwise returns s3[t]
    (selector is automatically wrapped with sigIntCast)
    s1 - first signal to be selected
    s2 - second signal to be selected
    s3 - third signal to be selected

    returns the selected signal depending of the selector value at each time t.
    """
    cdef fs.Signal s = fs.sigSelect3(selector.ptr, s1.ptr, s2.ptr, s3.ptr)
    return Signal.from_ptr(s)


def sig_fconst(fs.SType type, str name, str file) -> Signal:
    """Create a foreign constant signal.

    type - the foreign constant type of SType
    name - the foreign constant name
    file - the include file where the foreign constant is defined

    returns the foreign constant signal.
    """
    cdef fs.Signal s = fs.sigFConst(
        type, 
        name.encode('utf8'), 
        file.encode('utf8'))
    return Signal.from_ptr(s)


def sig_fvar(fs.SType type, str name, str file) -> Signal:
    """Create a foreign variable signal.

    type - the foreign variable type of SType
    name - the foreign variable name
    file - the include file where the foreign variable is defined

    returns the foreign variable signal.
    """
    cdef fs.Signal s = fs.sigFVar(
        type, 
        name.encode('utf8'), 
        file.encode('utf8'))
    return Signal.from_ptr(s)


def sig_bin_op(fs.SOperator op, Signal x, Signal y) -> Signal:
    """Generic binary mathematical functions.

    op - the operator in SOperator set
    x - first signal
    y - second signal

    returns the result signal of op(x, y).
    """
    cdef fs.Signal s = fs.sigBinOp(op, x.ptr, y.ptr)
    return Signal.from_ptr(s)


# -----------------------------------------------
# Specific binary mathematical functions.
# x - first signal
# y - second signal
# returns the result signal of fun(x,y).

def sig_add(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigAdd(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_sub(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigSub(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_mul(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigMul(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_div(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigDiv(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_rem(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigRem(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_leftshift(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigLeftShift(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_lrightshift(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigLRightShift(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_arightshift(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigARightShift(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_gt(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigGT(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_lt(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigLT(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_ge(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigGE(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_le(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigLE(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_eq(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigEQ(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_ne(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigNE(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_and(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigAND(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_or(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigOR(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_xor(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigXOR(x.ptr, y.ptr)
    return Signal.from_ptr(s)


# -----------------------------------------------
# Extended unary mathematical functions

def sig_abs(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigAbs(x.ptr)
    return Signal.from_ptr(s)

def sig_acos(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigAcos(x.ptr)
    return Signal.from_ptr(s)

def sig_tan(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigTan(x.ptr)
    return Signal.from_ptr(s)

def sig_sqrt(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigSqrt(x.ptr)
    return Signal.from_ptr(s)

def sig_sin(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigSin(x.ptr)
    return Signal.from_ptr(s)

def sig_rint(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigRint(x.ptr)
    return Signal.from_ptr(s)

def sig_log(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigLog(x.ptr)
    return Signal.from_ptr(s)

def sig_log10(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigLog10(x.ptr)
    return Signal.from_ptr(s)

def sig_floor(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigFloor(x.ptr)
    return Signal.from_ptr(s)

def sig_exp(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigExp(x.ptr)
    return Signal.from_ptr(s)

def sig_exp10(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigExp10(x.ptr)
    return Signal.from_ptr(s)

def sig_cos(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigCos(x.ptr)
    return Signal.from_ptr(s)

def sig_ceil(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigCeil(x.ptr)
    return Signal.from_ptr(s)

def sig_atan(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigAtan(x.ptr)
    return Signal.from_ptr(s)

def sig_asin(Signal x) -> Signal:
    cdef fs.Signal s = fs.sigAsin(x.ptr)
    return Signal.from_ptr(s)

# -----------------------------------------------
# Extended binary mathematical functions.

def sig_remainder(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigRemainder(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_pow(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigPow(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_min(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigMin(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_max(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigMax(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_fmod(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigFmod(x.ptr, y.ptr)
    return Signal.from_ptr(s)

def sig_atan2(Signal x, Signal y) -> Signal:
    cdef fs.Signal s = fs.sigAtan2(x.ptr, y.ptr)
    return Signal.from_ptr(s)


# -----------------------------------------------

def sig_self() -> Signal:
    """Create a recursive signal inside the sigRecursion expression.

    returns the recursive signal.
    """
    cdef fs.Signal s = fs.sigSelf()
    return Signal.from_ptr(s)

def sig_recursion(Signal s) -> Signal:
    """Create a recursive signal. Use sigSelf() to refer to the
    recursive signal inside the sigRecursion expression.

    s - the signal to recurse on.

    returns the signal with a recursion.
    """
    cdef fs.Signal _s = fs.sigRecursion(s.ptr)
    return Signal.from_ptr(_s)

def sig_self_n(int id) -> Signal:
    """Create a recursive signal inside the sigRecursionN expression.

    id - the recursive signal index (starting from 0, up to the number of outputs signals in the recursive block)

    returns the recursive signal.
    """
    cdef fs.Signal s = fs.sigSelfN(id)
    return Signal.from_ptr(s)

def sig_recursion_n(SignalVector rf) -> SignalVector:
    """Create a recursive block of signals. 

    Use sigSelfN() to refer to the recursive signal inside 
    the sigRecursionN expression.

    rf - the list of signals to recurse on.

    returns the list of signals with recursions.
    """
    cdef fs.tvec rv = fs.sigRecursionN(rf.ptr)
    return SignalVector.from_ptr(rv)


def sig_button(str label) -> Signal:
    """Create a button signal.

    label - the label definition (see [2])

    returns the button signal.
    """
    cdef fs.Signal s = fs.sigButton(label.encode('utf8'))
    return Signal.from_ptr(s)


def sig_checkbox(str label) -> Signal:
    """Create a checkbox signal.

    label - the label definition (see [2])

    returns the checkbox signal.
    """
    cdef fs.Signal s = fs.sigCheckbox(label.encode('utf8'))
    return Signal.from_ptr(s)


def sig_vslider(str label, Signal init, Signal min, Signal max, Signal step) -> Signal:
    """Create a vertical slider signal.

    label - the label definition (see [2])
    init - the init signal, a constant numerical expression (see [1])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    step - the step signal, a constant numerical expression (see [1])

    returns the vertical slider signal.
    """
    cdef fs.Signal s = fs.sigVSlider(
        label.encode('utf8'),
        init.ptr,
        min.ptr,
        max.ptr,
        step.ptr,
    )
    return Signal.from_ptr(s)


def sig_hslider(str label, Signal init, Signal min, Signal max, Signal step) -> Signal:
    """Create an horizontal slider signal.

    label - the label definition (see [2])
    init - the init signal, a constant numerical expression (see [1])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    step - the step signal, a constant numerical expression (see [1])

    returns the horizontal slider signal.
    """
    cdef fs.Signal s = fs.sigHSlider(
        label.encode('utf8'),
        init.ptr,
        min.ptr,
        max.ptr,
        step.ptr,
    )
    return Signal.from_ptr(s)


def sig_numentry(str label, Signal init, Signal min, Signal max, Signal step) -> Signal:
    """Create a num entry signal.

    label - the label definition (see [2])
    init - the init signal, a constant numerical expression (see [1])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    step - the step signal, a constant numerical expression (see [1])

    returns the num entry signal.
    """
    cdef fs.Signal s = fs.sigNumEntry(
        label.encode('utf8'),
        init.ptr,
        min.ptr,
        max.ptr,
        step.ptr,
    )
    return Signal.from_ptr(s)


def sig_vbargraph(str label, Signal min, Signal max, Signal s):
    """Create a vertical bargraph signal.

    label - the label definition (see [2])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    s - the input signal

    returns the vertical bargraph signal.
    """
    cdef fs.Signal _s = fs.sigVBargraph(
        label.encode('utf8'),
        min.ptr,
        max.ptr,
        s.ptr,
    )
    return Signal.from_ptr(_s)


def sig_hbargraph(str label, Signal min, Signal max, Signal s):
    """Create an horizontal bargraph signal.

    label - the label definition (see [2])
    min - the min signal, a constant numerical expression (see [1])
    max - the max signal, a constant numerical expression (see [1])
    s - the input signal

    returns the horizontal bargraph signal.
    """
    cdef fs.Signal _s = fs.sigHBargraph(
        label.encode('utf8'),
        min.ptr,
        max.ptr,
        s.ptr,
    )
    return Signal.from_ptr(_s)



def sig_attach(Signal s1, Signal s2) -> Signal:
    """Create an attach signal.

    The attach primitive takes two input signals and produces one output signal
    which is a copy of the first input. The role of attach is to force
    its second input signal to be compiled with the first one.

    s1 - the first signal
    s2 - the second signal

    returns the attach signal.
    """
    cdef fs.Signal s = fs.sigAttach(s1.ptr, s2.ptr)
    return Signal.from_ptr(s)




# Test each signal and fill additional signal specific parameters.
# returns true and fill the specific parameters if the signal is of a given type, false otherwise

def is_sig_int(Signal t) -> dict:
    cdef int i = 0
    if fs.isSigInt(t.ptr, &i):
        return dict(i=i)
    else:
        return {}

def is_sig_float(Signal t) -> dict:
    cdef double r = 0.0
    if fs.isSigReal(t.ptr, &r):
        return dict(r=r)
    else:
        return {}

is_sig_real = is_sig_float

def is_sig_input(Signal t) -> dict:
    cdef int i = 0
    if fs.isSigInput(t.ptr, &i):
        return dict(i=i)
    else:
        return {}

def is_sig_output(Signal t) -> dict:
    cdef int i = 0
    cdef fs.Signal t0 = NULL
    if fs.isSigOutput(t.ptr, &i, t0):
        return dict(i=i, t0=Signal.from_ptr(t0))
    else:
        return {}

def is_sig_delay1(Signal t) -> dict:
    cdef fs.Signal t0 = NULL
    if fs.isSigDelay1(t.ptr, t0):
        return dict(t0=Signal.from_ptr(t0))
    else:
        return {}

def is_sig_delay(Signal t) -> dict:
    cdef fs.Signal t0 = NULL
    cdef fs.Signal t1 = NULL
    if fs.isSigDelay(t.ptr, t0, t1):
        return dict(
            t0=Signal.from_ptr(t0),
            t1=Signal.from_ptr(t1),
        )
    else:
        return {}


def is_sig_prefix(Signal t) -> dict:
    cdef fs.Signal t0 = NULL
    cdef fs.Signal t1 = NULL
    if fs.isSigPrefix(t.ptr, t0, t1):
        return dict(
            t0=Signal.from_ptr(t0),
            t1=Signal.from_ptr(t1),
        )
    else:
        return {}


def is_sig_readonly_table(Signal s) -> dict:
    cdef fs.Signal t = NULL
    cdef fs.Signal i = NULL
    if fs.isSigRDTbl(s.ptr, t, i):
        return dict(
            t=Signal.from_ptr(t),
            i=Signal.from_ptr(i),
        )
    else:
        return {}


def is_sig_read_write_table(Signal u) -> dict:
    cdef fs.Signal id = NULL
    cdef fs.Signal t = NULL
    cdef fs.Signal i = NULL
    cdef fs.Signal s = NULL
    if fs.isSigWRTbl(u.ptr, id, t, i, s):
        return dict(
            id=Signal.from_ptr(id),
            t=Signal.from_ptr(t),
            i=Signal.from_ptr(i),
            s=Signal.from_ptr(s),
        )
    else:
        return {}


def is_sig_gen(Signal t) -> dict:
    cdef fs.Signal x = NULL
    if fs.isSigGen(t.ptr, x):
        return dict(x=Signal.from_ptr(x))
    else:
        return {}


def is_sig_doc_constant_tbl(Signal t) -> dict:
    cdef fs.Signal n = NULL
    cdef fs.Signal sig = NULL
    if fs.isSigDocConstantTbl(t.ptr, n, sig):
        return dict(
            n=Signal.from_ptr(n),
            sig=Signal.from_ptr(sig),
        )
    else:
        return {}


def is_sig_doc_write_tbl(Signal t) -> dict:
    cdef fs.Signal n = NULL
    cdef fs.Signal sig = NULL
    cdef fs.Signal widx = NULL
    cdef fs.Signal wsig = NULL
    if fs.isSigDocWriteTbl(t.ptr, n, sig, widx, wsig):
        return dict(
            n=Signal.from_ptr(n),
            sig=Signal.from_ptr(sig),
            widx=Signal.from_ptr(widx),
            wsig=Signal.from_ptr(wsig),
        )
    else:
        return {}


def is_sig_doc_access_tbl(Signal t) -> dict:
    cdef fs.Signal tbl = NULL
    cdef fs.Signal ridx = NULL
    if fs.isSigDocAccessTbl(t.ptr, tbl, ridx):
        return dict(
            n=Signal.from_ptr(tbl),
            widx=Signal.from_ptr(ridx),
        )
    else:
        return {}


def is_sig_select2(Signal t) -> dict:
    cdef fs.Signal selector = NULL
    cdef fs.Signal s1 = NULL
    cdef fs.Signal s2 = NULL
    if fs.isSigSelect2(t.ptr, selector, s1, s2):
        return dict(
            selector=Signal.from_ptr(selector),
            s1=Signal.from_ptr(s1),
            s2=Signal.from_ptr(s2),
        )
    else:
        return {}


def is_sig_assert_bounds(Signal t) -> dict:
    cdef fs.Signal s1 = NULL
    cdef fs.Signal s2 = NULL
    cdef fs.Signal s3 = NULL
    if fs.isSigAssertBounds(t.ptr, s1, s2, s3):
        return dict(
            s1=Signal.from_ptr(s1),
            s2=Signal.from_ptr(s2),
            s3=Signal.from_ptr(s3),
        )
    else:
        return {}


def is_sig_highest(Signal t) -> dict:
    cdef fs.Signal s = NULL
    if fs.isSigHighest(t.ptr, s):
        return dict(s=Signal.from_ptr(s))
    else:
        return {}

def is_sig_lowest(Signal t) -> dict:
    cdef fs.Signal s = NULL
    if fs.isSigLowest(t.ptr, s):
        return dict(s=Signal.from_ptr(s))
    else:
        return {}


def is_sig_bin_op(Signal s) -> dict:
    cdef int op = 0
    cdef fs.Signal x = NULL
    cdef fs.Signal y = NULL
    if fs.isSigBinOp(s.ptr, &op, x, y):
        return dict(
            op=op,
            x=Signal.from_ptr(x),
            y=Signal.from_ptr(y),
        )
    else:
        return {}


def is_sig_ffun(Signal s) -> dict:
    cdef fs.Signal ff = NULL
    cdef fs.Signal largs = NULL
    if fs.isSigFFun(s.ptr, ff, largs):
        return dict(
            ff=Signal.from_ptr(ff),
            largs=Signal.from_ptr(largs),
        )
    else:
        return {}


def is_sig_fconst(Signal s) -> dict:
    cdef fs.Signal type = NULL
    cdef fs.Signal name = NULL
    cdef fs.Signal file = NULL
    if fs.isSigFConst(s.ptr, type, name, file):
        return dict(
            type=Signal.from_ptr(type),
            name=Signal.from_ptr(name),
            file=Signal.from_ptr(file),
        )
    else:
        return {}


def is_sig_fvar(Signal s) -> dict:
    cdef fs.Signal type = NULL
    cdef fs.Signal name = NULL
    cdef fs.Signal file = NULL
    if fs.isSigFVar(s.ptr, type, name, file):
        return dict(
            type=Signal.from_ptr(type),
            name=Signal.from_ptr(name),
            file=Signal.from_ptr(file),
        )
    else:
        return {}


def is_proj(Signal s) -> dict:
    cdef int i = 0
    cdef fs.Signal rgroup = NULL
    if fs.isProj(s.ptr, &i, rgroup):
        return dict(
            i=i,
            rgroup=Signal.from_ptr(rgroup),
        )
    else:
        return {}



def is_rec(Signal s) -> dict:
    cdef fs.Signal var = NULL
    cdef fs.Signal body = NULL
    if fs.isRec(s.ptr, var, body):
        return dict(
            var=Signal.from_ptr(var),
            body=Signal.from_ptr(body),
        )
    else:
        return {}


def is_sig_int_cast(Signal s) -> dict:
    cdef fs.Signal x = NULL
    if fs.isSigIntCast(s.ptr, x):
        return dict(
            x=Signal.from_ptr(x),
        )
    else:
        return {}


def is_sig_float_cast(Signal s) -> dict:
    cdef fs.Signal x = NULL
    if fs.isSigFloatCast(s.ptr, x):
        return dict(
            x=Signal.from_ptr(x),
        )
    else:
        return {}


def is_sig_button(Signal s) -> dict:
    cdef fs.Signal lbl = NULL
    if fs.isSigButton(s.ptr, lbl):
        return dict(
            lbl=Signal.from_ptr(lbl),
        )
    else:
        return {}

def is_sig_checkbox(Signal s) -> dict:
    cdef fs.Signal lbl = NULL
    if fs.isSigCheckbox(s.ptr, lbl):
        return dict(
            lbl=Signal.from_ptr(lbl),
        )
    else:
        return {}


def is_sig_waveform(Signal s) -> bool:
    return fs.isSigWaveform(s.ptr)


def is_sig_hslider(Signal u) -> dict:
    cdef fs.Signal lbl = NULL
    cdef fs.Signal init = NULL
    cdef fs.Signal min = NULL
    cdef fs.Signal max = NULL
    cdef fs.Signal step = NULL
    if fs.isSigHSlider(u.ptr, lbl, init, min, max, step):
        return dict(
            lbl=Signal.from_ptr(lbl),
            init=Signal.from_ptr(init),
            min=Signal.from_ptr(min),
            max=Signal.from_ptr(max),
            step=Signal.from_ptr(step),
        )
    else:
        return {}

def is_sig_vslider(Signal u) -> dict:
    cdef fs.Signal lbl = NULL
    cdef fs.Signal init = NULL
    cdef fs.Signal min = NULL
    cdef fs.Signal max = NULL
    cdef fs.Signal step = NULL
    if fs.isSigVSlider(u.ptr, lbl, init, min, max, step):
        return dict(
            lbl=Signal.from_ptr(lbl),
            init=Signal.from_ptr(init),
            min=Signal.from_ptr(min),
            max=Signal.from_ptr(max),
            step=Signal.from_ptr(step),
        )
    else:
        return {}

def is_sig_numentry(Signal u) -> dict:
    cdef fs.Signal lbl = NULL
    cdef fs.Signal init = NULL
    cdef fs.Signal min = NULL
    cdef fs.Signal max = NULL
    cdef fs.Signal step = NULL
    if fs.isSigNumEntry(u.ptr, lbl, init, min, max, step):
        return dict(
            lbl=Signal.from_ptr(lbl),
            init=Signal.from_ptr(init),
            min=Signal.from_ptr(min),
            max=Signal.from_ptr(max),
            step=Signal.from_ptr(step),
        )
    else:
        return {}


def is_sig_hbargraph(Signal s) -> dict:
    cdef fs.Signal lbl = NULL
    cdef fs.Signal min = NULL
    cdef fs.Signal max = NULL
    cdef fs.Signal x = NULL
    if fs.isSigHBargraph(s.ptr, lbl, min, max, x):
        return dict(
            lbl=Signal.from_ptr(lbl),
            min=Signal.from_ptr(min),
            max=Signal.from_ptr(max),
            x=Signal.from_ptr(x),
        )
    else:
        return {}

def is_sig_vbargraph(Signal s) -> dict:
    cdef fs.Signal lbl = NULL
    cdef fs.Signal min = NULL
    cdef fs.Signal max = NULL
    cdef fs.Signal x = NULL
    if fs.isSigVBargraph(s.ptr, lbl, min, max, x):
        return dict(
            lbl=Signal.from_ptr(lbl),
            min=Signal.from_ptr(min),
            max=Signal.from_ptr(max),
            x=Signal.from_ptr(x),
        )
    else:
        return {}


def is_sig_attach(Signal s) -> dict:
    cdef fs.Signal s0 = NULL
    cdef fs.Signal s1 = NULL
    if fs.isSigAttach(s.ptr, s0, s1):
        return dict(
            s0=Signal.from_ptr(s0),
            s1=Signal.from_ptr(s1),
        )
    else:
        return {}

def is_sig_enable(Signal s) -> dict:
    cdef fs.Signal s0 = NULL
    cdef fs.Signal s1 = NULL
    if fs.isSigEnable(s.ptr, s0, s1):
        return dict(
            s0=Signal.from_ptr(s0),
            s1=Signal.from_ptr(s1),
        )
    else:
        return {}

def is_sig_control(Signal s) -> dict:
    cdef fs.Signal s0 = NULL
    cdef fs.Signal s1 = NULL
    if fs.isSigControl(s.ptr, s0, s1):
        return dict(
            s0=Signal.from_ptr(s0),
            s1=Signal.from_ptr(s1),
        )
    else:
        return {}


def is_sig_soundfile(Signal s) -> dict:
    cdef fs.Signal label = NULL
    if fs.isSigSoundfile(s.ptr, label):
        return dict(
            label=Signal.from_ptr(label),
        )
    else:
        return {}


def is_sig_soundfile_length(Signal s) -> dict:
    cdef fs.Signal sf = NULL
    cdef fs.Signal part = NULL
    if fs.isSigSoundfileLength(s.ptr, sf, part):
        return dict(
            sf=Signal.from_ptr(sf),
            part=Signal.from_ptr(part),
        )
    else:
        return {}

def is_sig_soundfile_rate(Signal s) -> dict:
    cdef fs.Signal sf = NULL
    cdef fs.Signal part = NULL
    if fs.isSigSoundfileRate(s.ptr, sf, part):
        return dict(
            sf=Signal.from_ptr(sf),
            part=Signal.from_ptr(part),
        )
    else:
        return {}


def is_sig_soundfile_buffer(Signal s) -> dict:
    cdef fs.Signal sf = NULL
    cdef fs.Signal chan = NULL
    cdef fs.Signal part = NULL
    cdef fs.Signal ridx = NULL
    if fs.isSigSoundfileBuffer(s.ptr, sf, chan, part, ridx):
        return dict(
            sf=Signal.from_ptr(sf),
            chan=Signal.from_ptr(chan),
            part=Signal.from_ptr(part),
            ridx=Signal.from_ptr(ridx),
        )
    else:
        return {}


def simplify_to_normal_form(Signal s) -> Signal:
    """Simplify a signal to its normal form, where:
     
     - all possible optimisations, simplications, and compile time computations have been done
     - the mathematical functions (primitives and binary functions), delay, select2, soundfile primitive...
     are properly typed (arguments and result)
     - signal cast are properly done when needed

    sig - the signal to be processed

    returns the signal in normal form.
    """
    cdef fs.Signal _s = fs.simplifyToNormalForm(s.ptr)
    return Signal.from_ptr(_s)





def simplify_to_normal_form2(SignalVector vec) -> SignalVector:
    """Simplify a signal list to its normal form, where:
     
     - all possible optimisations, simplications, and compile time computations have been done
     - the mathematical functions (primitives and binary functions), delay, select2, soundfile primitive...
     are properly typed (arguments and result)
     - signal cast are properly done when needed

    siglist - the signal list to be processed

    returns the signal vector in normal form.
    """
    cdef fs.tvec sv = fs.simplifyToNormalForm2(vec.ptr)
    return SignalVector.from_ptr(sv)



def create_source_from_signals(str name_app, SignalVector osigs, str lang, *args) -> str:
    """Create source code in a target language from a vector of output signals.

    name_app - the name of the Faust program
    osigs - the vector of output signals (that will internally be converted 
            in normal form (see simplifyToNormalForm)
    lang -  the target source code's language which can be one of 'c',
            'cpp', 'cmajor', 'codebox', 'csharp', 'dlang', 'fir', 'interp', 'java', 'jax',
            'jsfx', 'julia', 'ocpp', 'rust' or 'wast'
    (depending of which of the corresponding backends are compiled in libfaust)
    argc - the number of parameters in argv array
    argv - the array of parameters
    error_msg - the error string to be filled

    returns a string of source code on success, setting error_msg on error.
    """
    cdef ParamArray params = ParamArray(args)
    cdef string error_msg
    error_msg.reserve(4096)
    cdef string code = fs.createSourceFromSignals(
        name_app.encode('utf8'),
        osigs.ptr,
        lang.encode('utf8'),
        params.argc,
        params.argv,
        error_msg,
    )
    if not error_msg.empty():
        print(error_msg.decode())
        return
    return code.decode()


