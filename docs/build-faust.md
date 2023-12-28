# Faust Build Scenarios


## Key Links

- [CCRMA Faust Tutorials](https://ccrma.stanford.edu/~rmichon/faustTutorials/)
- [Embedding the Faust Compiler Using libfaust](https://faustdoc.grame.fr/manual/embedding/)
- 


## Building faust libs with LLVM

```bash
git clone --recursive https://github.com/grame-cncm/faust.git
cd faust
# to test llvm@14 as well
PATH=`brew --prefix llvm@16`/bin:$PATH make most
# if it builds successfully
PATH=`brew --prefix llvm@16`/bin:$PATH PREFIX=`pwd`/prefix make install
```

## Building libfaust.a with interp backend and interp target

This requires the following custom backend config which I called `interp_plus.cmake` so that I could build the `faust` executable and set the path to the lib folder correctly for both interp tests:

The custom backend: `faust/build/backends/interp_plus.cmake`

```make
# this file may be used to select different backends
# it's always read by the default makefile target
# values are among: 
#    OFF       don't include the backend
#    COMPILER  embed the backend in the faust compiler
#    STATIC    embed the backend in the faust static library
#    DYNAMIC   embed the backend in the faust dynamic library
#    WASM      embed the backend in the faust wasm library

set ( C_BACKEND      STATIC DYNAMIC    CACHE STRING  "Include C backend" FORCE )
set ( CPP_BACKEND    STATIC DYNAMIC    CACHE STRING  "Include CPP backend" FORCE )
set ( CMAJOR_BACKEND OFF    CACHE STRING  "Include Cmajor backend" FORCE )
set ( CSHARP_BACKEND OFF    CACHE STRING  "Include CSharp backend" FORCE )
set ( DLANG_BACKEND  OFF    CACHE STRING  "Include Dlang backend" FORCE )
set ( FIR_BACKEND    OFF    CACHE STRING  "Include FIR backend" FORCE )
set ( INTERP_BACKEND OFF CACHE STRING  "Include Interpreter backend" FORCE )
set ( INTERP_COMP_BACKEND STATIC DYNAMIC CACHE STRING "Include Interpreter/Cmmpiler backend" FORCE )
set ( JAVA_BACKEND   OFF    CACHE STRING  "Include JAVA backend" FORCE )
set ( JAX_BACKEND    OFF    CACHE STRING  "Include JAX backend"  FORCE )
set ( JULIA_BACKEND  OFF    CACHE STRING  "Include Julia backend" FORCE )
set ( JSFX_BACKEND  OFF    CACHE STRING  "Include JSFX backend" FORCE )
set ( LLVM_BACKEND   OFF    CACHE STRING  "Include LLVM backend" FORCE )
set ( OLDCPP_BACKEND OFF    CACHE STRING  "Include old CPP backend" FORCE )
set ( RUST_BACKEND   OFF    CACHE STRING  "Include Rust backend" FORCE )
# Template is deactivated 
set ( TEMPLATE_BACKEND   OFF    CACHE STRING  "Include Template backend" FORCE )
set ( WASM_BACKEND   OFF    CACHE STRING  "Include WASM backend" FORCE )
```

and also a custom target: `faust/build/targets/interp_plus.cmake`:

```cmake
# this file may be used to select different target
# values are among ON or OFF 

set ( INCLUDE_EXECUTABLE  ON  CACHE STRING  "Include Faust compiler" FORCE )
set ( INCLUDE_STATIC      ON CACHE STRING  "Include static Faust library" FORCE )
set ( INCLUDE_DYNAMIC     ON CACHE STRING  "Include dynamic Faust library" FORCE )

set ( INCLUDE_OSC         OFF  CACHE STRING  "Include Faust OSC static library" FORCE )
set ( INCLUDE_HTTP        OFF  CACHE STRING  "Include Faust HTTPD static library" FORCE )

set ( INCLUDE_ITP         OFF  CACHE STRING  "Include Faust Machine library" FORCE )
set ( ITPDYNAMIC          OFF  CACHE STRING  "Include Faust Machine library" FORCE )

set ( OSCDYNAMIC          OFF CACHE STRING  "Include Faust OSC dynamic library" FORCE )
set ( HTTPDYNAMIC         OFF CACHE STRING  "Include Faust HTTP dynamic library" FORCE )
```

Then was called in a custom target in the main `Makefile` as follows:

```make
interp : updatesubmodules
	$(MAKE) -C $(BUILDLOCATION) cmake BACKENDS=interp_plus.cmake TARGETS=interp_plus.cmake
	$(MAKE) -C $(BUILDLOCATION)
```

Then in the root of faust:

```
git clone --recursive https://github.com/grame-cncm/faust.git
cd faust
# add custom backend and target as above
make interp
# if it builds successfully
PREFIX=`pwd`/prefix make install
cp tests/interp-tests ./prefix/tests
cd prefix
```
`prefix` is effectively the root of this project.
