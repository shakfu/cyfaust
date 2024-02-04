
"""
special case osx
    # "universal":            (0, "Compiles and combines i386 and x86_64 architectures"),
    # "deployment_target":    (0, "Control MacOS deployment target settings"),
    # "deployment_target_version": (10.11,"Sets deployment target version (unused when DEPLOYMENT_TARGET is off)"),
"""

class FaustConfig:

    BACKENDS = [
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
    ]



    TARGETS = [
        ("include_executable",   "Include Faust compiler"),
        ("include_static",       "Include static Faust library"),
        ("include_dynamic",      "Include dynamic Faust library"),
        ("include_osc",          "Include Faust OSC static library"),
        ("oscdynamic",           "Include Faust OSC dynamic library"),
        ("include_http",         "Include Faust HTTPD static library"),
        ("httpdynamic",          "Include Faust HTTP dynamic library"),
        ("include_itp",          "Include Faust Machine library"),
        ("itpdynamic",           "Include Faust Machine library"),
    ]


    TARGET_CONFIGS = {
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

    BACKEND_CONFIGS = {
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

    def __init__(self, backend_config: str, target_config: str):
        assert backend_config in self.BACKEND_CONFIGS, "backend config does not exist"
        self.backend_config = backend_config
        assert target_config in self.TARGET_CONFIGS, "target config does not exist"
        self.target_config = target_config

    def backend_options(self, backend, idx):
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

    def write_backend(self, to_file: str):
        lines = []
        cfg = self.BACKEND_CONFIGS[self.backend_config]
        for i, row in enumerate(self.BACKENDS):
            _name, desc = row
            _name = _name.upper() + "_BACKEND"
            options = self.backend_options(cfg, i)
            lines.append(f'set ( {_name:19s} {options} CACHE STRING "{desc}" FORCE )')
        with open(to_file, 'w') as f:
            f.write("\n".join(lines))

    def write_target(self, to_file: str):
        onoff = lambda x: "ON" if x else "OFF"
        lines = []
        cfg = self.TARGET_CONFIGS[self.target_config]
        for i, row in enumerate(self.TARGETS):
            _name, desc = row
            _name = _name.upper()
            val = onoff(cfg[i])
            lines.append(f'set ( {_name:19s} {val:3s} CACHE STRING "{desc}" FORCE )')
        with open(to_file, 'w') as f:
            f.write("\n".join(lines))


if __name__ == '__main__':
    cfg = FaustConfig(backend_config='cyfaust', target_config='cyfaust')
    cfg.write_backend('scripts/patch/interp_plus_backend.cmake')
    cfg.write_target('scripts/patch/interp_plus_target.cmake')
