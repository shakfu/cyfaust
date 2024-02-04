
"""
special case osx
    # "universal":            (0, "Compiles and combines i386 and x86_64 architectures"),
    # "deployment_target":    (0, "Control MacOS deployment target settings"),
    # "deployment_target_version": (10.11,"Sets deployment target version (unused when DEPLOYMENT_TARGET is off)"),
"""

NAMES = {
    'backends': [
        ("c",            "Include C backend"),
        ("cpp",          "Include CPP backend"),
        ("codebox",      "Include Codebox backend"),
        ("cmajor",       "Include Cmajor backend"),
        ("csharp",       "Include CSharp backend"),
        ("dlang",        "Include Dlang backend"),
        ("fir",          "Include FIR backend"),
        ("interp",       "Include Interpreter backend"),
        ("interp_comp",  "Include Interpreter/Cmmpiler backend"),
        ("java",         "Include JAVA backend"),
        ("jax",          "Include JAX backend"),
        ("julia",        "Include Julia backend"),
        ("jsfx",         "Include JSFX backend"),
        ("llvm",         "Include LLVM backend"),
        ("oldcpp",       "Include old CPP backend"),
        ("rust",         "Include Rust backend"),
        ("template",     "Include Template backend"),
        ("wasm",         "Include WASM backend"),
    ],


    'targets' : [
        ("include_executable",   "Include Faust compiler"),
        ("include_static",       "Include static Faust library"),
        ("include_dynamic",      "Include dynamic Faust library"),
        ("include_osc",          "Include Faust OSC static library"),
        ("oscdynamic",           "Include Faust OSC dynamic library"),
        ("include_http",         "Include Faust HTTPD static library"),
        ("httpdynamic",          "Include Faust HTTP dynamic library"),
        ("include_itp",          "Include Faust Machine library"),
        ("itpdynamic",           "Include Faust Machine library"),
    ],
}


TARGETS = {
    #               ex st dy os od hs hd is im
    'all-win64':    [1, 1, 1, 1, 1, 1, 1, 0, 0],
    'all':          [1, 1, 1, 1, 1, 1, 1, 1, 1],
    'developer':    [1, 1, 0, 1, 0, 1, 0, 1, 0],
    'interp':       [0, 1, 1, 0, 0, 0, 0, 0, 0],
    'most':         [1, 1, 0, 1, 0, 1, 0, 0, 0],
    'osx':          [1, 0, 0, 1, 0, 1, 0, 0, 0],
    'regular':      [1, 0, 0, 1, 0, 1, 0, 0, 0],
    'win-ci':       [1, 0, 0, 1, 0, 0, 0, 0, 0],
    'windows':      [1, 1, 1, 1, 0, 1, 0, 0, 0],
    'cyfaust':      [1, 1, 1, 0, 0, 0, 0, 0, 0],
}

BACKENDS = {
    'all': {
    #                c c+ cb cm cs dl fi in ic jv jx ju fx ll oc rt te wa 
        'compiler': [1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1],
        'static':   [1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1],
        'dynamic':  [1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1],
        'wasm':     [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],

    },
    'backends': {
    #                c c+ cb cm cs dl fi in ic jv jx ju fx ll oc rt te wa 
        'compiler': [1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1],
        'static':   [1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1],
        'dynamic':  [1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1],
        'wasm':     [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],

    },
    'interp': {
    #                c c+ cb cm cs dl fi in ic jv jx ju fx ll oc rt te wa 
        'compiler': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        'static':   [0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        'dynamic':  [0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        'wasm':     [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],

    },
    'light': {
    #                c c+ cb cm cs dl fi in ic jv jx ju fx ll oc rt te wa 
        'compiler': [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
        'static':   [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
        'dynamic':  [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
        'wasm':     [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],

    },
    'regular': {
    #                c c+ cb cm cs dl fi in ic jv jx ju fx ll oc rt te wa 
        'compiler': [1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1],
        'static':   [1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1],
        'dynamic':  [1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1],
        'wasm':     [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],

    },
    'cyfaust': {
    #                c c+ cb cm cs dl fi in ic jv jx ju fx ll oc rt te wa 
        'compiler': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        'static':   [1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0],
        'dynamic':  [1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0],
        'wasm':     [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    },
}


def backend_options(backend, idx):
    xs = []
    if backend['compiler'][idx]:
        xs.append("COMPILER")
    if backend['static'][idx]:
        xs.append("STATIC")
    if backend['dynamic'][idx]:
        xs.append("DYNAMIC")
    if backend['wasm'][idx]:
        xs.append("WASM")
    if not xs:
        xs.append("OFF")
    options = " ".join(xs)
    return options


def write_backend(name: str, fileout: str):
    backend = BACKENDS[name]
    lines = []
    for i, obj in enumerate(NAMES['backends']):
        _name, desc = obj
        _name = _name.upper() + "_BACKEND"
        options = backend_options(backend, i)
        lines.append(f'set ( {_name:19s} {options} CACHE STRING "{desc}" FORCE )')
    with open(fileout, 'w') as f:
        f.write("\n".join(lines))

def write_target(name: str, fileout: str):
    onoff = lambda x: "ON" if x else "OFF"
    lines = []
    target = TARGETS[name]
    for i, obj in enumerate(NAMES['targets']):
        _name, desc = obj
        _name = _name.upper()
        val = onoff(target[i])
        lines.append(f'set ( {_name:19s} {val:3s} CACHE STRING "{desc}" FORCE )')
    with open(fileout, 'w') as f:
        f.write("\n".join(lines))




if __name__ == '__main__':
    write_target('cyfaust', 'scripts/patch/targets.cmake')
    write_backend('cyfaust', 'scripts/patch/backends.cmake')


