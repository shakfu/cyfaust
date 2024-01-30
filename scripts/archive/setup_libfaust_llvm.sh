CWD=`pwd`
ROOT=build/faust/root
FAUST_STDLIB="${ROOT}/share/faust/*.lib"
LLVM_VERSION=16
LLVM_BIN=`brew --prefix llvm@${LLVM_VERSION}`/bin

get_faust() {
	echo "update from faust main repo"
	mkdir -p build && \
		cd build && \
		git clone --recursive https://github.com/grame-cncm/faust.git && \
		cd faust && \
		mkdir -p build/faustdir && \
		PATH=${LLVM_BIN}:$PATH make most && \
		PATH=${LLVM_BIN}:$PATH PREFIX=`pwd`/prefix make install && \
}

remove_current() {
	echo "remove current faust libs"
	rm -f ./bin/faust && \
	rm -f ./bin/faust-config && \
	rm -f ./bin/faust && \
	rm -rf ./include/faust && \
	rm -f ./lib/libfaust.a && \
	rm -rf ./share/faust
}

copy_executables() {
	echo "copy executables"
	mkdir -p bin && \
	for e in faust faust-config faustpath
	do
		cp -f "${ROOT}/bin/${e}" ./bin/${e}
	done
}

copy_headers() {
	echo "update headers"
	mkdir -p include && \
	cp -rf "${ROOT}/include/faust" ./include/faust	
}

copy_staticlibs() {
	echo "copy staticlibs"
	mkdir -p lib && \
	cp "${ROOT}/lib/libfaustwithllvm.a" ./lib/libfaust.a
}

copy_stdlib() {
	echo "copy stdlib"
	mkdir -p ./share/faust && \
	for f in ${FAUST_STDLIB}
	do
	  name=`basename ${f}`
	  cp "${ROOT}/share/faust/${name}" ./share/faust/${name}
	done
}

copy_examples() {
	echo "copy examples" && \
	cp -rf "${ROOT}/share/faust/examples" ./share/faust/examples && \
	rm -rf ./share/faust/examples/SAM && \
	rm -rf ./share/faust/examples/bela
}


main() {
	get_faust && \
	cd ${CWD} && \
	remove_current && \
	copy_executables && \
	copy_headers && \
	copy_staticlibs && \
	copy_stdlib && \
	copy_examples
}


main
