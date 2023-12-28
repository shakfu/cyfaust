CWD=`pwd`
ROOT=build/faust/root
FAUST_STDLIB="${ROOT}/share/faust/*.lib"
FAUST_VERSION="2.69.3"


get_faust() {
	echo "update from faust main repo"
	mkdir -p build && \
		cd build && \
		git clone --depth 1 --branch ${FAUST_VERSION} https://github.com/grame-cncm/faust.git && \
		mkdir -p faust/build/faustdir && \
		cp ../scripts/faust.mk ./faust/Makefile && \
		cp ../scripts/interp_plus_backend.cmake ./faust/build/backends/interp_plus.cmake && \
		cp ../scripts/interp_plus_target.cmake ./faust/build/targets/interp_plus.cmake && \
		cd faust && \
		make interp && \
		PREFIX=`pwd`/root make install
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

copy_sharedlib() {
	echo "copy_sharedlib"
	mkdir -p lib && \
	cp "${ROOT}/lib/libfaust.2.dylib" ./lib/libfaust.2.dylib
}

copy_staticlib() {
	echo "copy staticlib"
	mkdir -p lib && \
	cp "${ROOT}/lib/libfaust.a" ./lib/libfaust.a
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
	copy_staticlib && \
	copy_sharedlib	&& \
	copy_stdlib && \
	copy_examples
}

main

