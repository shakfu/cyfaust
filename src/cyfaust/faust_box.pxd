# distutils: language = c++

from libcpp.string cimport string
from libcpp.vector cimport vector

cdef extern from "faust/dsp/libfaust-box.h":
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
    int ffarity(Signal s);

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


    bint getDefNameProperty(Box b, Box& id)
    string extractName(Box full_label)
    void createLibContext()
    void destroyLibContext()

    bint isNil(Box b)
    const char* tree2str(Box b)
    int tree2int(Box b)
    void* getUserData(Box b)
    Box boxInt(int n)
    Box boxReal(double n)
    Box boxWire()
    Box boxCut()
    Box boxSeq(Box x, Box y)
    Box boxPar(Box x, Box y)
    Box boxPar3(Box x, Box y, Box z)
    Box boxPar4(Box a, Box b, Box c, Box d)
    Box boxPar5(Box a, Box b, Box c, Box d, Box e)
    Box boxSplit(Box x, Box y)
    Box boxMerge(Box x, Box y)
    Box boxRec(Box x, Box y)
    Box boxRoute(Box n, Box m, Box r)
    Box boxDelay()
    Box boxDelay(Box b, Box del_)
    Box boxIntCast()
    Box boxIntCast(Box b)
    Box boxFloatCast()
    Box boxFloatCast(Box b)
    Box boxReadOnlyTable()
    Box boxReadOnlyTable(Box n, Box init, Box ridx)
    Box boxWriteReadTable()
    Box boxWriteReadTable(Box n, Box init, Box widx, Box wsig, Box ridx)

    Box boxWaveform(const tvec& wf)
    Box boxSoundfile(const string& label, Box chan)
    Box boxSoundfile(const string& label, Box chan, Box part, Box ridx)
    Box boxSelect2()
    Box boxSelect2(Box selector, Box b1, Box b2)
    Box boxSelect3()
    Box boxSelect3(Box selector, Box b1, Box b2, Box b3)
    Box boxFConst(SType type, const string& name, const string& file)
    Box boxFVar(SType type, const string& name, const string& file)
    Box boxBinOp(SOperator op)
    Box boxBinOp(SOperator op, Box b1, Box b2)
    Box boxAdd()
    Box boxAdd(Box b1, Box b2)
    Box boxSub()
    Box boxSub(Box b1, Box b2)
    Box boxMul()
    Box boxMul(Box b1, Box b2)
    Box boxDiv()
    Box boxDiv(Box b1, Box b2)
    Box boxRem()
    Box boxRem(Box b1, Box b2)

    Box boxLeftShift()
    Box boxLeftShift(Box b1, Box b2)
    Box boxLRightShift()
    Box boxLRightShift(Box b1, Box b2)
    Box boxARightShift()
    Box boxARightShift(Box b1, Box b2)

    Box boxGT()
    Box boxGT(Box b1, Box b2)
    Box boxLT()
    Box boxLT(Box b1, Box b2)
    Box boxGE()
    Box boxGE(Box b1, Box b2)
    Box boxLE()
    Box boxLE(Box b1, Box b2)
    Box boxEQ()
    Box boxEQ(Box b1, Box b2)
    Box boxNE()
    Box boxNE(Box b1, Box b2)

    Box boxAND()
    Box boxAND(Box b1, Box b2)
    Box boxOR()
    Box boxOR(Box b1, Box b2)
    Box boxXOR()
    Box boxXOR(Box b1, Box b2)

    Box boxAbs()
    Box boxAbs(Box x)
    Box boxAcos()
    Box boxAcos(Box x)
    Box boxTan()
    Box boxTan(Box x)
    Box boxSqrt()
    Box boxSqrt(Box x)
    Box boxSin()
    Box boxSin(Box x)
    Box boxRint()
    Box boxRint(Box x)
    Box boxRound()
    Box boxRound(Box x)
    Box boxLog()
    Box boxLog(Box x)
    Box boxLog10()
    Box boxLog10(Box x)
    Box boxFloor()
    Box boxFloor(Box x)
    Box boxExp()
    Box boxExp(Box x)
    Box boxExp10()
    Box boxExp10(Box x)
    Box boxCos()
    Box boxCos(Box x)
    Box boxCeil()
    Box boxCeil(Box x)
    Box boxAtan()
    Box boxAtan(Box x)
    Box boxAsin()
    Box boxAsin(Box x)

    Box boxRemainder()
    Box boxRemainder(Box b1, Box b2)
    Box boxPow()
    Box boxPow(Box b1, Box b2)
    Box boxMin()
    Box boxMin(Box b1, Box b2)
    Box boxMax()
    Box boxMax(Box b1, Box b2)
    Box boxFmod()
    Box boxFmod(Box b1, Box b2)
    Box boxAtan2()
    Box boxAtan2(Box b1, Box b2)

    Box boxButton(const string& label)
    Box boxCheckbox(const string& label)
    Box boxVSlider(const string& label, Box init, Box min, Box max, Box step)
    Box boxHSlider(const string& label, Box init, Box min, Box max, Box step)
    Box boxNumEntry(const string& label, Box init, Box min, Box max, Box step)
    Box boxVBargraph(const string& label, Box min, Box max)
    Box boxVBargraph(const string& label, Box min, Box max, Box x)
    Box boxHBargraph(const string& label, Box min, Box max)
    Box boxHBargraph(const string& label, Box min, Box max, Box x)
    Box boxVGroup(const string& label, Box group)
    Box boxHGroup(const string& label, Box group)
    Box boxTGroup(const string& label, Box group)
    Box boxAttach()
    Box boxAttach(Box b1, Box b2)
    Box boxPrim2(prim2 foo)

    bint isBoxAbstr(Box t)
    bint isBoxAbstr(Box t, Box& x, Box& y)
    bint isBoxAccess(Box t, Box& exp, Box& id)
    bint isBoxAppl(Box t)
    bint isBoxAppl(Box t, Box& x, Box& y)
    bint isBoxButton(Box b)
    bint isBoxButton(Box b, Box& lbl)
    bint isBoxCase(Box b)
    bint isBoxCase(Box b, Box& rules)
    bint isBoxCheckbox(Box b)
    bint isBoxCheckbox(Box b, Box& lbl)
    bint isBoxComponent(Box b, Box& filename)
    bint isBoxCut(Box t)
    bint isBoxEnvironment(Box b)
    bint isBoxError(Box t)
    bint isBoxFConst(Box b)
    bint isBoxFConst(Box b, Box& type, Box& name, Box& file)
    bint isBoxFFun(Box b)
    bint isBoxFFun(Box b, Box& ff)
    bint isBoxFVar(Box b)
    bint isBoxFVar(Box b, Box& type, Box& name, Box& file)
    bint isBoxHBargraph(Box b)
    bint isBoxHBargraph(Box b, Box& lbl, Box& min, Box& max)
    bint isBoxHGroup(Box b)
    bint isBoxHGroup(Box b, Box& lbl, Box& x)
    bint isBoxHSlider(Box b)
    bint isBoxHSlider(Box b, Box& lbl, Box& cur, Box& min, Box& max, Box& step)
    bint isBoxIdent(Box t)
    bint isBoxIdent(Box t, const char** str)
    bint isBoxInputs(Box t, Box& x)
    bint isBoxInt(Box t)
    bint isBoxInt(Box t, int* i)
    bint isBoxIPar(Box t, Box& x, Box& y, Box& z)
    bint isBoxIProd(Box t, Box& x, Box& y, Box& z)
    bint isBoxISeq(Box t, Box& x, Box& y, Box& z)
    bint isBoxISum(Box t, Box& x, Box& y, Box& z)
    bint isBoxLibrary(Box b, Box& filename)
    bint isBoxMerge(Box t, Box& x, Box& y)
    bint isBoxMetadata(Box b, Box& exp, Box& mdlist)
    bint isBoxNumEntry(Box b)
    bint isBoxNumEntry(Box b, Box& lbl, Box& cur, Box& min, Box& max, Box& step)
    bint isBoxOutputs(Box t, Box& x)
    bint isBoxPar(Box t, Box& x, Box& y)
    bint isBoxPrim0(Box b)
    bint isBoxPrim1(Box b)
    bint isBoxPrim2(Box b)
    bint isBoxPrim3(Box b)
    bint isBoxPrim4(Box b)
    bint isBoxPrim5(Box b)
    bint isBoxPrim0(Box b, prim0* p)
    bint isBoxPrim1(Box b, prim1* p)
    bint isBoxPrim2(Box b, prim2* p)
    bint isBoxPrim3(Box b, prim3* p)
    bint isBoxPrim4(Box b, prim4* p)
    bint isBoxPrim5(Box b, prim5* p)
    bint isBoxReal(Box t)
    bint isBoxReal(Box t, double* r)
    bint isBoxRec(Box t, Box& x, Box& y)
    bint isBoxRoute(Box b, Box& n, Box& m, Box& r)
    bint isBoxSeq(Box t, Box& x, Box& y)
    bint isBoxSlot(Box t)
    bint isBoxSlot(Box t, int* id)
    bint isBoxSoundfile(Box b)
    bint isBoxSoundfile(Box b, Box& label, Box& chan)
    bint isBoxSplit(Box t, Box& x, Box& y)
    bint isBoxSymbolic(Box t)
    bint isBoxSymbolic(Box t, Box& slot, Box& body)
    bint isBoxTGroup(Box b)
    bint isBoxTGroup(Box b, Box& lbl, Box& x)
    bint isBoxVBargraph(Box b)
    bint isBoxVBargraph(Box b, Box& lbl, Box& min, Box& max)
    bint isBoxVGroup(Box b)
    bint isBoxVGroup(Box b, Box& lbl, Box& x)
    bint isBoxVSlider(Box b)
    bint isBoxVSlider(Box b, Box& lbl, Box& cur, Box& min, Box& max, Box& step)
    bint isBoxWaveform(Box b)
    bint isBoxWire(Box t)
    bint isBoxWithLocalDef(Box t, Box& body, Box& ldef)

    Box DSPToBoxes(const string& name_app, const string& dsp_content, int argc, const char* argv[], int* inputs, int* outputs, string& error_msg)
    bint getBoxType(Box box, int* inputs, int* outputs)
    tvec boxesToSignals(Box box, string& error_msg)
    string createSourceFromBoxes(const string& name_app, Box box, const string& lang, int argc, const char* argv[], string& error_msg)



