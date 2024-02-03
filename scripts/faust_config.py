
BACKENDS = [ #       c, s, d 
    ("c",            0, 1, 1,  "Include C backend"),
    ("cpp",          0, 1, 1,  "Include CPP backend"),
    ("codebox",      0, 1, 1,  "Include Codebox backend"),
    ("cmajor",       0, 0, 0,  "Include Cmajor backend"),
    ("csharp",       0, 0, 0,  "Include CSharp backend"),
    ("dlang",        0, 0, 0,  "Include Dlang backend"),
    ("fir",          0, 0, 0,  "Include FIR backend"),
    ("interp",       0, 0, 0,  "Include Interpreter backend"),
    ("interp_comp",  0, 1, 1,  "Include Interpreter/Cmmpiler backend"),
    ("java",         0, 0, 0,  "Include JAVA backend"),
    ("jax",          0, 0, 0,  "Include JAX backend"),
    ("julia",        0, 0, 0,  "Include Julia backend"),
    ("jsfx",         0, 0, 0,  "Include JSFX backend"),
    ("llvm",         0, 0, 0,  "Include LLVM backend"),
    ("oldcpp",       0, 0, 0,  "Include old CPP backend"),
    ("rust",         0, 1, 1,  "Include Rust backend"),
    ("template",     0, 0, 0,  "Include Template backend"),
    ("wasm",         0, 0, 0,  "Include WASM backend"),
]


TARGETS = {
    "include_executable":   (1, "Include Faust compiler"),
    "include_static":       (1, "Include static Faust library"),
    "include_dynamic":      (1, "Include dynamic Faust library"),
    "include_osc":          (1, "Include Faust OSC static library"),
    "include_http":         (0, "Include Faust HTTPD static library"),
    "oscdynamic":           (1, "Include Faust OSC dynamic library"),
    "httpdynamic":          (0, "Include Faust HTTP dynamic library"),
    "include_itp":          (0, "Include Faust Machine library"),
    "itpdynamic":           (0, "Include Faust Machine library"),
    # "universal":            (0, "Compiles and combines i386 and x86_64 architectures"),
    # "deployment_target":    (0, "Control MacOS deployment target settings"),
    # "deployment_target_version": (10.11,"Sets deployment target version (unused when DEPLOYMENT_TARGET is off)"),
}

onoff = lambda x: "ON" if x else "OFF"

def write_backends(fileout):
    lines = []
    for row in BACKENDS:
        name, compiler, static, dynamic, doc = row
        name = name.upper() + "_BACKEND"
        xs = []
        if compiler:
            xs.append("COMPILER")
        if static:
            xs.append("STATIC")
        if dynamic:
            xs.append("DYNAMIC")
        if not xs:
            xs.append("OFF")
        options = " ".join(xs)
        lines.append(f'set ( {name:19s} {options} CACHE STRING "{doc}" FORCE )')
    with open(fileout, 'w') as f:
        f.write("\n".join(lines))


def write_targets(fileout):
    lines = []
    for t in TARGETS:
        name = t.upper()
        (val, doc) = TARGETS[t]
        val = onoff(val)
        lines.append(f'set ( {name:19s} {val:3s} CACHE STRING "{doc}" FORCE )')
    with open(fileout, 'w') as f:
        f.write("\n".join(lines))


if __name__ == '__main__':
    write_targets('scripts/patch/targets.cmake')
    write_backends('scripts/patch/backends.cmake')


