   
class CTree
typedef std::vector<CTree*> tvec

typedef CTree* Signal
typedef CTree* Box
typedef CTree* Tree

typedef Tree (*prim0)()
typedef Tree (*prim1)(Tree x)
typedef Tree (*prim2)(Tree x, Tree y)
typedef Tree (*prim3)(Tree x, Tree y, Tree z)
typedef Tree (*prim4)(Tree w, Tree x, Tree y, Tree z)
typedef Tree (*prim5)(Tree v, Tree w, Tree x, Tree y, Tree z)

const char* prim0name(prim0)
const char* prim1name(prim1)
const char* prim2name(prim2)
const char* prim3name(prim3)
const char* prim4name(prim4)
const char* prim5name(prim5)   
const char* ffname(Signal s)   
int ffarity(Signal s)

enum SType { kSInt, kSReal }

enum SOperator { kAdd, kSub, kMul, kDiv, kRem, kLsh, kARsh, kLRsh, kGT, kLT, kGE, kLE, kEQ, kNE, kAND, kOR, kXOR }

struct dsp_factory_base {
    virtual ~dsp_factory_base() {}    
    virtual void write(std::ostream* , bool  = false, bool  = false) {}
}

string printBox(Box box, bool shared, int max_size)
string printSignal(Signal sig, bool shared, int max_size)// To be used with getSigInterval/setSigInterval

// see: https://stackoverflow.com/questions/27442885/syntax-error-with-stdnumeric-limitsmax
struct Interval {
    double fLo = std::numeric_limits<double>::lowest()    //< minimal value
    double fHi = (std::numeric_limits<double>::max)()     //< maximal value
    int    fLSB = -24                                     //< lsb in bits
    
    // To be used to set a full interval
    Interval(double lo, double hi, int lsb):fLo(lo), fHi(hi), fLSB(lsb)
    {}
    
    // To be used to only set the LSB, with fLo and fHi taking default values
    Interval(int lsb):fLSB(lsb)
    {}
}

inline static std::ostream& operator<<(std::ostream& dst, const Interval& it)
{
    dst << "Interval [" << it.fLo << ", " << it.fHi << ", " << it.fLSB << "]"
    return dst
}

void createLibContext()
void destroyLibContext()
   
Interval getSigInterval(Signal s)   
void setSigInterval(Signal s, Interval& inter)
   
bool isNil(Signal s)
   
const char* tree2str(Signal s)
   
void* getUserData(Signal s)
   
unsigned int xtendedArity(Signal s)
   
const char* xtendedName(Signal s)
   
Signal sigInt(int n)
Signal sigReal(double n)
Signal sigInput(int idx)
Signal sigDelay(Signal s, Signal del)
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

bool isSigInt(Signal t, int* i)
bool isSigReal(Signal t, double* r)
bool isSigInput(Signal t, int* i)
bool isSigOutput(Signal t, int* i, Signal& t0)
bool isSigDelay1(Signal t, Signal& t0)
bool isSigDelay(Signal t, Signal& t0, Signal& t1)
bool isSigPrefix(Signal t, Signal& t0, Signal& t1)
bool isSigRDTbl(Signal s, Signal& t, Signal& i)
bool isSigWRTbl(Signal u, Signal& id, Signal& t, Signal& i, Signal& s)
bool isSigGen(Signal t, Signal& x)
bool isSigDocConstantTbl(Signal t, Signal& n, Signal& sig)
bool isSigDocWriteTbl(Signal t, Signal& n, Signal& sig, Signal& widx, Signal& wsig)
bool isSigDocAccessTbl(Signal t, Signal& tbl, Signal& ridx)
bool isSigSelect2(Signal t, Signal& selector, Signal& s1, Signal& s2)
bool isSigAssertBounds(Signal t, Signal& s1, Signal& s2, Signal& s3)
bool isSigHighest(Signal t, Signal& s)
bool isSigLowest(Signal t, Signal& s)

bool isSigBinOp(Signal s, int* op, Signal& x, Signal& y)
bool isSigFFun(Signal s, Signal& ff, Signal& largs)
bool isSigFConst(Signal s, Signal& type, Signal& name, Signal& file)
bool isSigFVar(Signal s, Signal& type, Signal& name, Signal& file)

bool isProj(Signal s, int* i, Signal& rgroup)
bool isRec(Signal s, Signal& var, Signal& body)

bool isSigIntCast(Signal s, Signal& x)
bool isSigFloatCast(Signal s, Signal& x)

bool isSigButton(Signal s, Signal& lbl)
bool isSigCheckbox(Signal s, Signal& lbl)

bool isSigWaveform(Signal s)

bool isSigHSlider(Signal s, Signal& lbl, Signal& init, Signal& min, Signal& max, Signal& step)
bool isSigVSlider(Signal s, Signal& lbl, Signal& init, Signal& min, Signal& max, Signal& step)
bool isSigNumEntry(Signal s, Signal& lbl, Signal& init, Signal& min, Signal& max, Signal& step)

bool isSigHBargraph(Signal s, Signal& lbl, Signal& min, Signal& max, Signal& x)
bool isSigVBargraph(Signal s, Signal& lbl, Signal& min, Signal& max, Signal& x)

bool isSigAttach(Signal s, Signal& s0, Signal& s1)

bool isSigEnable(Signal s, Signal& s0, Signal& s1)
bool isSigControl(Signal s, Signal& s0, Signal& s1)

bool isSigSoundfile(Signal s, Signal& label)
bool isSigSoundfileLength(Signal s, Signal& sf, Signal& part)
bool isSigSoundfileRate(Signal s, Signal& sf, Signal& part)
bool isSigSoundfileBuffer(Signal s, Signal& sf, Signal& chan, Signal& part, Signal& ridx)

Signal simplifyToNormalForm(Signal s)
tvec simplifyToNormalForm2(tvec siglist)
string createSourceFromSignals(const string& name_app, tvec osigs, const string& lang, int argc, const char* argv[], string& error_msg)
