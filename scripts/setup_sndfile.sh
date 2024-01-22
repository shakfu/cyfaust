CWD=`pwd`
LIB=${CWD}/lib
INCLUDE=${CWD}/include
DOWNLOADS=${CWD}/build/downloads
PREFIX=${CWD}/build/prefix
PREFIX_LIB=${PREFIX}/lib
PREFIX_INCLUDE=${PREFIX}/include


function setup_libsamplerate() {
	build_dir=${DOWNLOADS}/libsamplerate/build
	mkdir -p ${DOWNLOADS} ${PREFIX} && \
	cd ${DOWNLOADS} && \
	git clone --depth=1 https://github.com/libsndfile/libsamplerate.git && \
	mkdir -p ${build_dir} && \
	cd ${build_dir} && \
	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DLIBSAMPLERATE_EXAMPLES=OFF \
		-DBUILD_TESTING=OFF \
		-DLIBSAMPLERATE_INSTALL=ON \
		-DBUILD_SHARED_LIBS=OFF && \
	cmake --build . && \
	cmake --install . --prefix ${PREFIX}
}

function setup_libsndfile() {
	build_dir=${DOWNLOADS}/libsndfile/build
	mkdir -p ${DOWNLOADS} ${PREFIX} && \
	cd ${DOWNLOADS} && \
	git clone --depth=1 https://github.com/libsndfile/libsndfile.git && \
	mkdir -p ${build_dir} && \
	cd ${build_dir} && \
	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_PROGRAMS=OFF \
		-DBUILD_EXAMPLES=OFF \
		-DBUILD_TESTING=OFF \
		-DENABLE_EXTERNAL_LIBS=OFF \
		-DENABLE_MPEG=OFF \
		-DENABLE_CPACK=OFF \
		-DENABLE_PACKAGE_CONFIG=OFF \
		-DINSTALL_PKGCONFIG_MODULE=OFF \
		-DINSTALL_MANPAGES=OFF && \
	cmake --build . && \
	cmake --install . --prefix ${PREFIX}
}

function main() {
	setup_libsamplerate && \
	setup_libsndfile && \
	echo "installing libsndfile and libsamplerate .." && \
	cp ${PREFIX_LIB}/*.a ${LIB}/static && \
	cp ${PREFIX_INCLUDE}/*.h  ${INCLUDE} && \
	cp ${PREFIX_INCLUDE}/*.hh ${INCLUDE}
}

main
