from libcpp.string cimport string
from libcpp.vector cimport vector

cdef extern from "faust/dsp/libfaust-signal.h":
    cdef cppclass CTree
    ctypedef vector[CTree*] tvec
    ctypedef CTree* Signal
    ctypedef CTree* Box
    ctypedef CTree* Tree

    ctypedef Tree (*prim0)()
    ctypedef Tree (*prim1)(Tree x)
    ctypedef Tree (*prim2)(Tree x, Tree y)
    ctypedef Tree (*prim3)(Tree x, Tree y, Tree z)
    ctypedef Tree (*prim4)(Tree w, Tree x, Tree y, Tree z)
    ctypedef Tree (*prim5)(Tree v, Tree w, Tree x, Tree y, Tree z)

    const char* prim0name(prim0)
    const char* prim1name(prim1)
    const char* prim2name(prim2)
    const char* prim3name(prim3)
    const char* prim4name(prim4)
    const char* prim5name(prim5)

    # Return the name parameter of a foreign function
    const char* ffname(Signal s)

    # Return the arity of a foreign function.
    int ffarity(Signal s)

    ctypedef enum SType: 
        kSInt
        kSReal

    ctypedef enum SOperator:
        kAdd
        kSub
        kMul
        kDiv
        kRem
        kLsh
        kARsh
        kLRsh
        kGT
        kLT
        kGE
        kLE
        kEQ
        kNE
        kAND
        kOR
        kXOR

    cdef cppclass dsp_factory_base

    # Print the box
    string printBox(Box box, bint shared, int max_size)

    # Print the signal
    string printSignal(Signal sig, bint shared, int max_size)


    cdef cppclass Interval:
        double fLo
        double fHi
        int fLSB
        Interval(double lo, double hi, int lsb)
        Interval(int lsb)

    void createLibContext()
    void destroyLibContext()

    Interval getSigInterval(Signal s)

    void setSigInterval(Signal s, Interval& inter)

    bint isNil(Signal s)

    const char* tree2str(Signal s)

    void* getUserData(Signal s)

    unsigned int xtendedArity(Signal s)

    const char* xtendedName(Signal s)

    Signal sigInt(int n)

    Signal sigReal(double n)

    Signal sigInput(int idx)

    Signal sigDelay(Signal s, Signal delay)

    Signal sigDelay1(Signal s)

    Signal sigIntCast(Signal s)

    Signal sigFloatCast(Signal s)

    Signal sigReadOnlyTable(Signal n, Signal init, Signal ridx)

    Signal sigWriteReadTable(Signal n, Signal init, Signal widx, Signal wsig, Signal ridx)

    Signal sigWaveform(const tvec& wf)

    Signal sigSoundfile(const string& label)

    Signal sigSoundfileLength(Signal sf, Signal part)

    Signal sigSoundfileRate(Signal sf, Signal part)

    Signal sigSoundfileBuffer(Signal sf, Signal chan, Signal part, Signal ridx)

    Signal sigSelect2(Signal selector, Signal s1, Signal s2)

    Signal sigSelect3(Signal selector, Signal s1, Signal s2, Signal s3)

    Signal sigFConst(SType type, const string& name, const string& file)

    Signal sigFVar(SType type, const string& name, const string& file)

    Signal sigBinOp(SOperator op, Signal x, Signal y)

    Signal sigAdd(Signal x, Signal y)
    Signal sigSub(Signal x, Signal y)
    Signal sigMul(Signal x, Signal y)
    Signal sigDiv(Signal x, Signal y)
    Signal sigRem(Signal x, Signal y)

    Signal sigLeftShift(Signal x, Signal y)
    Signal sigLRightShift(Signal x, Signal y)
    Signal sigARightShift(Signal x, Signal y)

    Signal sigGT(Signal x, Signal y)
    Signal sigLT(Signal x, Signal y)
    Signal sigGE(Signal x, Signal y)
    Signal sigLE(Signal x, Signal y)
    Signal sigEQ(Signal x, Signal y)
    Signal sigNE(Signal x, Signal y)

    Signal sigAND(Signal x, Signal y)
    Signal sigOR(Signal x, Signal y)
    Signal sigXOR(Signal x, Signal y)

    Signal sigAbs(Signal x)
    Signal sigAcos(Signal x)
    Signal sigTan(Signal x)
    Signal sigSqrt(Signal x)
    Signal sigSin(Signal x)
    Signal sigRint(Signal x)
    Signal sigLog(Signal x)
    Signal sigLog10(Signal x)
    Signal sigFloor(Signal x)
    Signal sigExp(Signal x)
    Signal sigExp10(Signal x)
    Signal sigCos(Signal x)
    Signal sigCeil(Signal x)
    Signal sigAtan(Signal x)
    Signal sigAsin(Signal x)

    Signal sigRemainder(Signal x, Signal y)
    Signal sigPow(Signal x, Signal y)
    Signal sigMin(Signal x, Signal y)
    Signal sigMax(Signal x, Signal y)
    Signal sigFmod(Signal x, Signal y)
    Signal sigAtan2(Signal x, Signal y)

    Signal sigSelf()

    Signal sigRecursion(Signal s)

    Signal sigSelfN(int id)

    tvec sigRecursionN(const tvec& rf)

    Signal sigButton(const string& label)

    Signal sigCheckbox(const string& label)

    Signal sigVSlider(const string& label, Signal init, Signal min, Signal max, Signal step)

    Signal sigHSlider(const string& label, Signal init, Signal min, Signal max, Signal step)

    Signal sigNumEntry(const string& label, Signal init, Signal min, Signal max, Signal step)

    Signal sigVBargraph(const string& label, Signal min, Signal max, Signal s)

    Signal sigHBargraph(const string& label, Signal min, Signal max, Signal s)

    Signal sigAttach(Signal s1, Signal s2)

    bint isSigInt(Signal t, int* i)
    bint isSigReal(Signal t, double* r)
    bint isSigInput(Signal t, int* i)
    bint isSigOutput(Signal t, int* i, Signal& t0)
    bint isSigDelay1(Signal t, Signal& t0)
    bint isSigDelay(Signal t, Signal& t0, Signal& t1)
    bint isSigPrefix(Signal t, Signal& t0, Signal& t1)
    bint isSigRDTbl(Signal s, Signal& t, Signal& i)
    bint isSigWRTbl(Signal u, Signal& id, Signal& t, Signal& i, Signal& s)
    bint isSigGen(Signal t, Signal& x)
    bint isSigDocConstantTbl(Signal t, Signal& n, Signal& sig)
    bint isSigDocWriteTbl(Signal t, Signal& n, Signal& sig, Signal& widx, Signal& wsig)
    bint isSigDocAccessTbl(Signal t, Signal& tbl, Signal& ridx)
    bint isSigSelect2(Signal t, Signal& selector, Signal& s1, Signal& s2)
    bint isSigAssertBounds(Signal t, Signal& s1, Signal& s2, Signal& s3)
    bint isSigHighest(Signal t, Signal& s)
    bint isSigLowest(Signal t, Signal& s)

    bint isSigBinOp(Signal s, int* op, Signal& x, Signal& y)
    bint isSigFFun(Signal s, Signal& ff, Signal& largs)
    bint isSigFConst(Signal s, Signal& type, Signal& name, Signal& file)
    bint isSigFVar(Signal s, Signal& type, Signal& name, Signal& file)

    bint isProj(Signal s, int* i, Signal& rgroup)
    bint isRec(Signal s, Signal& var, Signal& body)

    bint isSigIntCast(Signal s, Signal& x)
    bint isSigFloatCast(Signal s, Signal& x)

    bint isSigButton(Signal s, Signal& lbl)
    bint isSigCheckbox(Signal s, Signal& lbl)

    bint isSigWaveform(Signal s)

    bint isSigHSlider(Signal s, Signal& lbl, Signal& init, Signal& min, Signal& max, Signal& step)
    bint isSigVSlider(Signal s, Signal& lbl, Signal& init, Signal& min, Signal& max, Signal& step)
    bint isSigNumEntry(Signal s, Signal& lbl, Signal& init, Signal& min, Signal& max, Signal& step)

    bint isSigHBargraph(Signal s, Signal& lbl, Signal& min, Signal& max, Signal& x)
    bint isSigVBargraph(Signal s, Signal& lbl, Signal& min, Signal& max, Signal& x)

    bint isSigAttach(Signal s, Signal& s0, Signal& s1)

    bint isSigEnable(Signal s, Signal& s0, Signal& s1)
    bint isSigControl(Signal s, Signal& s0, Signal& s1)

    bint isSigSoundfile(Signal s, Signal& label)
    bint isSigSoundfileLength(Signal s, Signal& sf, Signal& part)
    bint isSigSoundfileRate(Signal s, Signal& sf, Signal& part)
    bint isSigSoundfileBuffer(Signal s, Signal& sf, Signal& chan, Signal& part, Signal& ridx)

    Signal simplifyToNormalForm(Signal s)

    tvec simplifyToNormalForm2(tvec siglist)

    string createSourceFromSignals(const string& name_app, tvec osigs, const string& lang, int argc, const char* argv[], string& error_msg)
