
import hashlib
import re
from pathlib import Path




header = """\
bool isBoxAbstr(Box t);
bool isBoxAbstr(Box t, Box& x, Box& y);
bool isBoxAccess(Box t, Box& exp, Box& id);
bool isBoxAppl(Box t);
bool isBoxAppl(Box t, Box& x, Box& y);
bool isBoxButton(Box b);
bool isBoxButton(Box b, Box& lbl);
bool isBoxCase(Box b);
bool isBoxCase(Box b, Box& rules);
bool isBoxCheckbox(Box b);
bool isBoxCheckbox(Box b, Box& lbl);
bool isBoxComponent(Box b, Box& filename);
bool isBoxCut(Box t);
bool isBoxEnvironment(Box b);
bool isBoxError(Box t);
bool isBoxFConst(Box b);
bool isBoxFConst(Box b, Box& type, Box& name, Box& file);
bool isBoxFFun(Box b);
bool isBoxFFun(Box b, Box& ff);
bool isBoxFVar(Box b);
bool isBoxFVar(Box b, Box& type, Box& name, Box& file);
bool isBoxHBargraph(Box b);
bool isBoxHBargraph(Box b, Box& lbl, Box& min, Box& max);
bool isBoxHGroup(Box b);
bool isBoxHGroup(Box b, Box& lbl, Box& x);
bool isBoxHSlider(Box b);
bool isBoxHSlider(Box b, Box& lbl, Box& cur, Box& min, Box& max, Box& step);
bool isBoxIdent(Box t);
bool isBoxIdent(Box t, const char** str);
bool isBoxInputs(Box t, Box& x);
bool isBoxInt(Box t);
bool isBoxInt(Box t, int* i);
bool isBoxIPar(Box t, Box& x, Box& y, Box& z);
bool isBoxIProd(Box t, Box& x, Box& y, Box& z);
bool isBoxISeq(Box t, Box& x, Box& y, Box& z);
bool isBoxISum(Box t, Box& x, Box& y, Box& z);
bool isBoxLibrary(Box b, Box& filename);
bool isBoxMerge(Box t, Box& x, Box& y);
bool isBoxMetadata(Box b, Box& exp, Box& mdlist);
bool isBoxNumEntry(Box b);
bool isBoxNumEntry(Box b, Box& lbl, Box& cur, Box& min, Box& max, Box& step);
bool isBoxOutputs(Box t, Box& x);
bool isBoxPar(Box t, Box& x, Box& y);
bool isBoxPrim0(Box b);
bool isBoxPrim1(Box b);
bool isBoxPrim2(Box b);
bool isBoxPrim3(Box b);
bool isBoxPrim4(Box b);
bool isBoxPrim5(Box b);
bool isBoxPrim0(Box b, prim0* p);
bool isBoxPrim1(Box b, prim1* p);
bool isBoxPrim2(Box b, prim2* p);
bool isBoxPrim3(Box b, prim3* p);
bool isBoxPrim4(Box b, prim4* p);
bool isBoxPrim5(Box b, prim5* p);
bool isBoxReal(Box t);
bool isBoxReal(Box t, double* r);
bool isBoxRec(Box t, Box& x, Box& y);
bool isBoxRoute(Box b, Box& n, Box& m, Box& r);
bool isBoxSeq(Box t, Box& x, Box& y);
bool isBoxSlot(Box t);
bool isBoxSlot(Box t, int* id);
bool isBoxSoundfile(Box b);
bool isBoxSoundfile(Box b, Box& label, Box& chan);
bool isBoxSplit(Box t, Box& x, Box& y);
bool isBoxSymbolic(Box t);
bool isBoxSymbolic(Box t, Box& slot, Box& body);
bool isBoxTGroup(Box b);
bool isBoxTGroup(Box b, Box& lbl, Box& x);
bool isBoxVBargraph(Box b);
bool isBoxVBargraph(Box b, Box& lbl, Box& min, Box& max);
bool isBoxVGroup(Box b);
bool isBoxVGroup(Box b, Box& lbl, Box& x);
bool isBoxVSlider(Box b);
bool isBoxVSlider(Box b, Box& lbl, Box& cur, Box& min, Box& max, Box& step);
bool isBoxWaveform(Box b);
bool isBoxWire(Box t);
bool isBoxWithLocalDef(Box t, Box& body, Box& ldef);
"""

f0 = """\
def is_box_abstr(Box t) -> bool
	return fb.isBoxAbstr(t.ptr)
"""

f1 = """\
def is_box_abstr(Box t) -> dict:
    cdef fb.Box x = NULL
    cdef fb.Box y = NULL
    if fb.isBoxAbstr(t.ptr, x, y):
        return dict(
            x=Box.from_ptr(x),
            y=Box.from_ptr(y),
        )
    else:
        return {}
"""




def to_snake_case(name):
    name = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    name = re.sub('__([A-Z])', r'_\1', name)
    name = re.sub('([a-z0-9])([A-Z])', r'\1_\2', name)
    return name.lower()

def to_camel_case(name):
	return ''.join(word.title() for word in name.split('_'))


def clean(txt, reps):
	for k, v in reps.items():
		txt = txt.replace(k, v)
	return txt

def gen(p):
	name, params = p
	sname = to_snake_case(name)
	# get = "get" + sname[2:] + "_params"
	get = "getparams" + sname[2:]
	head, *to_fill = params
	iface = " ".join(head)
	ident = " "*4
	# print(name, sname, iface, to_fill)
	if len(to_fill) == 0:
		out = [f"def {sname}({iface}) -> bool:"]
		out.append(f"{ident}return fb.{name}({head[1]}.ptr)")
	else:
		out = [f"def {get}({iface}) -> dict:"]
		for p in to_fill:
			typ, pname = p
			if 'Box' in typ:
				out.append(f"{ident}cdef fb.Box {pname} = NULL")
			elif 'int' in typ:
				out.append(f"{ident}cdef int {pname} = 0")
			else:
				out.append(f"{ident}cdef {typ} {pname}")

		ps = ", ".join(i[1] for i in to_fill)
		out.append(f"{ident}if fb.{name}({head[1]}.ptr, {ps}):")
		out.append(f"{ident*2}return dict(")
		for p in to_fill:
			out.append(f"{ident*3}{p[1]}=Box.from_ptr({p[1]}),")
		out.append(f"{ident*2})")
		out.append(f"{ident}else:")
		out.append(f"{ident*2}return {{}}")
	print("\n".join(out))
	print()





FUNC = re.compile(r"^bint\s+(\w+)\((.+)\)")
header = clean(header, {';':'', 'bool':'bint'})
lines = header.splitlines()
parsed = []
for line in lines:
	m = FUNC.match(line)
	if m:
		name = m.group(1)
		params = [(p.split()[0], p.split()[1]) for p in m.group(2).split(', ')]
		parsed.append((name, params))
for p in parsed:
	gen(p)
	# break





