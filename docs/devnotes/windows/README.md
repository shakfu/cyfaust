# faust on windows

Currently exploring how it is done on the faust project itself. Initial result of this is the `winplus.yml` workflow which builds `libfaust.(dll|a)` from a modified faust workflow.



## Building faust on windows 

```shell
git clone --depth=1 --recursive --branch '2.69.3' https://github.com/grame-cncm/faust.git
cd faust
Invoke-WebRequest https://raw.githubusercontent.com/shakfu/cyfaust/main/scripts/patch/interp_plus_backend.cmake -OutFile ./build/backends/interp.cmake
Invoke-WebRequest https://raw.githubusercontent.com/shakfu/cyfaust/main/scripts/patch/interp_plus_target.cmake -OutFile ./build/targets/interp.cmake
mkdir -p build/faustdir
cd build/faustdir
cmake.exe -C ../backends/interp.cmake -C ../targets/interp.cmake -DCMAKE_BUILD_TYPE=Release "-DWORKLET=off" -DINCLUDE_LLVM=OFF -DUSE_LLVM_CONFIG=OFF -DLLVM_PACKAGE_VERSION="" -DLLVM_LIBS="" -DLLVM_LIB_DIR="" -DLLVM_INCLUDE_DIRS="" -DLLVM_DEFINITIONS="" -DLLVM_LD_FLAGS="" -DLIBSDIR=lib -DBUILD_HTTP_STATIC=OFF -G 'Visual Studio 17 2022' ..
cmake.exe --build . --config Release
```

cmake options in more ordered form:

```shell
cmake.exe -C ../backends/interp.cmake -C ../targets/interp.cmake \
	-DCMAKE_BUILD_TYPE=Release \ 
	"-DWORKLET=off" \
	-DINCLUDE_LLVM=OFF \
	-DUSE_LLVM_CONFIG=OFF \
	-DLLVM_PACKAGE_VERSION="" \
	-DLLVM_LIBS="" \
	-DLLVM_LIB_DIR="" \
	-DLLVM_INCLUDE_DIRS="" \
	-DLLVM_DEFINITIONS="" \
	-DLLVM_LD_FLAGS=""  \
	-DLIBSDIR=lib \
	-DBUILD_HTTP_STATIC=OFF \
	-G 'Visual Studio 17 2022' ..
```

